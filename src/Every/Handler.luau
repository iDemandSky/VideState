const Info = require("../Info")
const Types = require("../Types")
const Validation = require("../Validation")
const SpeedScale = require("../Utils/SpeedScale")
const Registry = require("./Registry")
const Scale = require("./Scale")

type Filter = (entry: Registry.Entry) -> boolean

-- Calls `action` on each member. A handler that raises does not stop the others, and the first error is raised
-- once every handler has run.
const function forEachMember(members: { Registry.Member }, action: (handler: Registry.Controls) -> ())
    local firstError: unknown = nil
    local hasError = false

    for _, member in members do
        const ok, err = pcall(action, member.handler)

        if not ok and not hasError then
            hasError = true
            firstError = err
        end
    end

    if hasError then
        error(firstError, 0)
    end
end

-- Counts the handlers that lack the state, and lists their rules with how many handlers each has, such as
-- `Dialog (1), Panel (2)`.
const function describeMissing(members: { Registry.Member }, stateName: string): (number, string)
    local counts: { [string]: number } = {}
    local ruleNames: { string } = {}
    local total = 0

    for _, member in members do
        if not member.entry.hasState(stateName) then
            const ruleName = member.entry.ruleName

            if counts[ruleName] == nil then
                counts[ruleName] = 0
                table.insert(ruleNames, ruleName)
            end

            counts[ruleName] += 1
            total += 1
        end
    end

    table.sort(ruleNames)

    local parts: { string } = {}

    for _, ruleName in ruleNames do
        table.insert(parts, `{ruleName} ({counts[ruleName]})`)
    end

    return total, table.concat(parts, ", ")
end

-- Builds the functions of one scope. A handler is in scope when it passes every filter, and the handlers are looked
-- up each time a function is called, so a handler created later is included. A group made with no filter is every
-- handler.
const function createGroup(filters: { Filter }): Types.EveryHandlerGroup
    const function matches(entry: Registry.Entry): boolean
        for _, filter in filters do
            if not filter(entry) then
                return false
            end
        end

        return true
    end

    const function members(): { Registry.Member }
        return Registry.list(matches)
    end

    const function extend(filter: Filter): Types.EveryHandlerGroup
        local extended = table.clone(filters)

        table.insert(extended, filter)

        return createGroup(extended)
    end

    const function pause()
        forEachMember(members(), function(handler)
            handler.pause()
        end)
    end

    const function resume()
        forEachMember(members(), function(handler)
            handler.resume()
        end)
    end

    const function finish()
        forEachMember(members(), function(handler)
            handler.finish()
        end)
    end

    const function destroy()
        forEachMember(members(), function(handler)
            handler.destroy()
        end)
    end

    -- With no filter and without `once`, this sets the scale that every handler multiplies by, now and for handlers
    -- created later. Otherwise it calls the `scaleSpeed` of each handler in scope, so a handler created later is not
    -- affected by a scale without `once`.
    const function scaleSpeed(options: Types.ScaleSpeedOptions)
        const speed, once = SpeedScale.parse(options, "every.handler.scaleSpeed")

        if #filters == 0 and not once then
            Scale.set(speed)

            return
        end

        forEachMember(members(), function(handler)
            handler.scaleSpeed({
                speed = speed,
                once = once,
            })
        end)
    end

    -- Checks every handler in scope first. If any lacks the state, one error lists all of them and no handler
    -- changes state.
    const function setState(stateName: string, options: Types.SetStateOptions?)
        Validation.stateName(stateName, "every.handler.setState state name")

        const found = members()
        const missing, description = describeMissing(found, stateName)

        if missing > 0 then
            error(
                `every.handler.setState state "{stateName}" is missing in {missing} handlers: {description}. No handler changed state`,
                0
            )
        end

        forEachMember(found, function(handler)
            handler.setState(stateName, options)
        end)
    end

    const function count(): number
        return #members()
    end

    const function isAnyRunning(): boolean
        for _, member in members() do
            if member.entry.inspect().isRunning then
                return true
            end
        end

        return false
    end

    const function isAnyPaused(): boolean
        for _, member in members() do
            if member.entry.inspect().isPaused then
                return true
            end
        end

        return false
    end

    -- Narrows the scope to the handlers whose rule has all of the tags. Tags are compared exactly as written.
    const function withTags(...: string): Types.EveryHandlerGroup
        const tags = { ... }

        if #tags == 0 then
            error("every.handler.withTags requires at least one tag", 2)
        end

        for index, tag in tags do
            if type(tag) ~= "string" then
                error(`every.handler.withTags tag {index} must be a string, got {typeof(tag)}`, 2)
            end
        end

        return extend(function(entry)
            for _, tag in tags do
                if not Info.ruleHasTag(entry.ruleName, tag) then
                    return false
                end
            end

            return true
        end)
    end

    -- Narrows the scope to the handlers of one rule.
    const function withRule(ruleName: string): Types.EveryHandlerGroup
        if type(ruleName) ~= "string" then
            error(`every.handler.withRule rule name must be a string, got {typeof(ruleName)}`, 2)
        end

        return extend(function(entry)
            return entry.ruleName == ruleName
        end)
    end

    -- Narrows the scope to the handlers whose current state has this name.
    const function inState(stateName: string): Types.EveryHandlerGroup
        if type(stateName) ~= "string" then
            error(`every.handler.inState state name must be a string, got {typeof(stateName)}`, 2)
        end

        return extend(function(entry)
            return entry.inspect().state == stateName
        end)
    end

    return table.freeze({
        scaleSpeed = scaleSpeed,
        pause = pause,
        resume = resume,
        finish = finish,
        destroy = destroy,
        setState = setState,
        count = count,
        isAnyRunning = isAnyRunning,
        isAnyPaused = isAnyPaused,
        withTags = withTags,
        withRule = withRule,
        inState = inState,
    })
end

return createGroup({})
