const Info = require("../Info")
const Types = require("../Types")
const Validation = require("../Validation")
const SpeedScale = require("../Utils/SpeedScale")
const Registry = require("./Registry")
const Scale = require("./Scale")

type Set = { [string]: boolean }

-- Which handlers a group acts on. It is plain data, so the filters can be checked against each other.
type Scope = {
    -- Whether any filter was applied. A group with no filter is every handler.
    filtered: boolean,
    -- Tags the rule must have, all of them.
    tags: Set,
    -- Tags the rule must not have, none of them.
    withoutTags: Set,
    -- The rule the handler must come from. More than one name can never match.
    rules: Set,
    withoutRules: Set,
    -- The states the handler may be in, or nil when `withStates` was never called.
    states: Set?,
    withoutStates: Set,
}

const EMPTY_SCOPE: Scope = {
    filtered = false,
    tags = {},
    withoutTags = {},
    rules = {},
    withoutRules = {},
    states = nil,
    withoutStates = {},
}

const function toSet(names: { string }): Set
    local set: Set = {}

    for _, name in names do
        set[name] = true
    end

    return set
end

const function union(first: Set, second: Set): Set
    local merged = table.clone(first)

    for name in second do
        merged[name] = true
    end

    return merged
end

const function intersect(first: Set, second: Set): Set
    local common: Set = {}

    for name in first do
        if second[name] then
            common[name] = true
        end
    end

    return common
end

const function without(first: Set, removed: Set): Set
    local remaining: Set = {}

    for name in first do
        if not removed[name] then
            remaining[name] = true
        end
    end

    return remaining
end

const function isEmpty(set: Set): boolean
    return next(set) == nil
end

-- The names of a set in alphabetical order, so a message does not depend on the order of the table.
const function sorted(set: Set): { string }
    local names: { string } = {}

    for name in set do
        table.insert(names, name)
    end

    table.sort(names)

    return names
end

-- Reads the names that a filter was given. The error level of 3 points at the user's call to the filter.
const function readNames(filterName: string, noun: string, ...: string): Set
    const names = { ... }

    if #names == 0 then
        error(`everyHandler.{filterName} requires at least one {noun}`, 3)
    end

    for index, name in names do
        if type(name) ~= "string" then
            error(`everyHandler.{filterName} {noun} {index} must be a string, got {typeof(name)}`, 3)
        end
    end

    return toSet(names)
end

-- Raises one error that lists every conflict between a filter and the filters before it. The error level of 3
-- points at the user's call to the filter.
const function failOnConflicts(filterName: string, conflicts: { string })
    if #conflicts == 0 then
        return
    end

    error(
        `everyHandler.{filterName} conflicts with an earlier filter: {table.concat(conflicts, "; ")}. No handler could match`,
        3
    )
end

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

-- Counts the handlers whose rule does not let them change to the state, and lists their rules with how many handlers
-- each has. A handler that lacks the state is not counted here, because it is reported on its own.
const function describeBlocked(members: { Registry.Member }, stateName: string): (number, string)
    local counts: { [string]: number } = {}
    local ruleNames: { string } = {}
    local total = 0

    for _, member in members do
        const entry = member.entry
        const isBlocked = entry.hasState(stateName) and not entry.canChangeTo(stateName)

        if isBlocked then
            if counts[entry.ruleName] == nil then
                counts[entry.ruleName] = 0
                table.insert(ruleNames, entry.ruleName)
            end

            counts[entry.ruleName] += 1
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

-- Whether a handler is in scope. The state is read from the handler only when a state filter needs it.
const function isInScope(scope: Scope, entry: Registry.Entry): boolean
    for tag in scope.tags do
        if not Info.ruleHasTag(entry.ruleName, tag) then
            return false
        end
    end

    for tag in scope.withoutTags do
        if Info.ruleHasTag(entry.ruleName, tag) then
            return false
        end
    end

    for ruleName in scope.rules do
        if entry.ruleName ~= ruleName then
            return false
        end
    end

    if scope.withoutRules[entry.ruleName] then
        return false
    end

    const states = scope.states
    const hasStateFilter = states ~= nil or not isEmpty(scope.withoutStates)

    if not hasStateFilter then
        return true
    end

    const currentState = entry.inspect().state

    if states ~= nil and not states[currentState] then
        return false
    end

    return not scope.withoutStates[currentState]
end

-- Builds the functions of one scope. The handlers are looked up each time a function is called, so a handler created
-- later is included, and a handler that changed state is matched by its new state.
const function createGroup(scope: Scope): Types.EveryHandlerGroup
    const function members(): { Registry.Member }
        return Registry.list(function(entry)
            return isInScope(scope, entry)
        end)
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
        const speed, once = SpeedScale.parse(options, "everyHandler.scaleSpeed")

        if not scope.filtered and not once then
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
        Validation.stateName(stateName, "everyHandler.setState state name")

        const found = members()
        const missing, description = describeMissing(found, stateName)

        if missing > 0 then
            error(
                `everyHandler.setState state "{stateName}" is missing in {missing} handlers: {description}. No handler changed state`,
                0
            )
        end

        const blocked, blockedDescription = describeBlocked(found, stateName)

        if blocked > 0 then
            error(
                `everyHandler.setState cannot change to state "{stateName}" in {blocked} handlers: {blockedDescription}. No handler changed state`,
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

    -- Returns the group of this scope with some of its fields replaced.
    const function narrow(changes: { [string]: unknown }): Types.EveryHandlerGroup
        local changed = table.clone(scope) :: any

        for key, value in changes do
            changed[key] = value
        end

        changed.filtered = true

        return createGroup(changed :: Scope)
    end

    -- Narrows the scope to the handlers whose rule has all of the tags. Tags are compared exactly as written.
    const function withTags(...: string): Types.EveryHandlerGroup
        const given = readNames("withTags", "tag", ...)
        local conflicts: { string } = {}

        for _, tag in sorted(intersect(given, scope.withoutTags)) do
            table.insert(conflicts, `tag "{tag}" is excluded by withoutTags`)
        end

        failOnConflicts("withTags", conflicts)

        return narrow({
            tags = union(scope.tags, given),
        })
    end

    -- Narrows the scope to the handlers whose rule has none of the tags.
    const function withoutTags(...: string): Types.EveryHandlerGroup
        const given = readNames("withoutTags", "tag", ...)
        local conflicts: { string } = {}

        for _, tag in sorted(intersect(given, scope.tags)) do
            table.insert(conflicts, `tag "{tag}" is required by withTags`)
        end

        failOnConflicts("withoutTags", conflicts)

        return narrow({
            withoutTags = union(scope.withoutTags, given),
        })
    end

    -- Narrows the scope to the handlers of one rule.
    const function withRule(ruleName: string): Types.EveryHandlerGroup
        if type(ruleName) ~= "string" then
            error(`everyHandler.withRule rule name must be a string, got {typeof(ruleName)}`, 2)
        end

        const required = union(scope.rules, { [ruleName] = true })
        local conflicts: { string } = {}

        if scope.withoutRules[ruleName] then
            table.insert(conflicts, `rule "{ruleName}" is excluded by withoutRule`)
        end

        if #sorted(required) > 1 then
            table.insert(conflicts, `a handler has one rule, but withRule asks for {table.concat(sorted(required), ", ")}`)
        end

        failOnConflicts("withRule", conflicts)

        return narrow({
            rules = required,
        })
    end

    -- Narrows the scope to the handlers that are not of the rule.
    const function withoutRule(ruleName: string): Types.EveryHandlerGroup
        if type(ruleName) ~= "string" then
            error(`everyHandler.withoutRule rule name must be a string, got {typeof(ruleName)}`, 2)
        end

        local conflicts: { string } = {}

        if scope.rules[ruleName] then
            table.insert(conflicts, `rule "{ruleName}" is required by withRule`)
        end

        failOnConflicts("withoutRule", conflicts)

        return narrow({
            withoutRules = union(scope.withoutRules, { [ruleName] = true }),
        })
    end

    -- Narrows the scope to the handlers whose current state is one of the names. A second call narrows it further,
    -- to the states that both calls allow.
    const function withStates(...: string): Types.EveryHandlerGroup
        const given = readNames("withStates", "state name", ...)
        const allowedBefore = scope.states
        const allowed = if allowedBefore == nil then given else intersect(allowedBefore, given)
        local conflicts: { string } = {}

        if isEmpty(allowed) then
            table.insert(
                conflicts,
                `none of the states {table.concat(sorted(given), ", ")} is among the states already required by withStates`
            )
        elseif isEmpty(without(allowed, scope.withoutStates)) then
            for _, stateName in sorted(allowed) do
                table.insert(conflicts, `state "{stateName}" is excluded by withoutStates`)
            end
        end

        failOnConflicts("withStates", conflicts)

        return narrow({
            states = allowed,
        })
    end

    -- Narrows the scope to the handlers whose current state is none of the names.
    const function withoutStates(...: string): Types.EveryHandlerGroup
        const given = readNames("withoutStates", "state name", ...)
        const excluded = union(scope.withoutStates, given)
        const allowedBefore = scope.states
        local conflicts: { string } = {}

        if allowedBefore ~= nil and isEmpty(without(allowedBefore, excluded)) then
            for _, stateName in sorted(allowedBefore) do
                table.insert(conflicts, `state "{stateName}" is required by withStates`)
            end
        end

        failOnConflicts("withoutStates", conflicts)

        return narrow({
            withoutStates = excluded,
        })
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
        withoutTags = withoutTags,
        withRule = withRule,
        withoutRule = withoutRule,
        withStates = withStates,
        withoutStates = withoutStates,
    })
end

return createGroup(EMPTY_SCOPE)
