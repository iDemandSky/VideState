const Options = require("./Options")

-- Finds the settings for one state change: the override that matches it, or nil when none does.
export type Resolver = (fromState: string, toState: string) -> Options.Settings?

type Entry = {
    index: number,
    from: { [string]: boolean },
    to: { [string]: boolean },
    settings: Options.Settings?,
}

const ENTRY_KEYS: { [string]: boolean } = {
    from = true,
    to = true,
    tween = true,
}

-- Lists at most this many state changes when two entries overlap, so one message stays readable.
const MAX_LISTED_CHANGES = 3

const function isArray(value: unknown): boolean
    if type(value) ~= "table" then
        return false
    end

    local fields = value :: { [any]: unknown }
    local count = 0

    for key in fields do
        if type(key) ~= "number" then
            return false
        end

        count += 1
    end

    return count == #(value :: { unknown })
end

-- Reads one side of an entry into the set of states it matches. A side that is left out matches every state.
-- Every problem is added to `problems` instead of being raised, so they can be reported together.
const function readSide(
    side: unknown,
    label: string,
    knownStates: { [string]: boolean },
    problems: { string }
): { [string]: boolean }?
    if side == nil then
        return table.clone(knownStates)
    end

    if not isArray(side) then
        table.insert(problems, `{label} must be an array of state names`)

        return nil
    end

    const problemsBefore = #problems
    local matched: { [string]: boolean } = {}

    for _, name in side :: { unknown } do
        if type(name) ~= "string" then
            table.insert(problems, `{label} must hold state names, got {typeof(name)}`)

            continue
        end

        if not knownStates[name] then
            table.insert(problems, `{label} has an unknown state "{name}"`)

            continue
        end

        matched[name] = true
    end

    local isEmpty = next(matched) == nil
    local hasNoProblem = #problems == problemsBefore

    if isEmpty and hasNoProblem then
        table.insert(problems, `{label} is empty, so it matches nothing`)
    end

    return matched
end

const function sortedNames(set: { [string]: boolean }): { string }
    local names = {}

    for name in set do
        table.insert(names, name)
    end

    table.sort(names)

    return names
end

-- The state changes that two entries both match. A change from a state to itself does not count.
const function sharedChanges(first: Entry, second: Entry): { string }
    local changes = {}

    for _, fromState in sortedNames(first.from) do
        if not second.from[fromState] then
            continue
        end

        for _, toState in sortedNames(first.to) do
            local isShared = second.to[toState] == true
            local isChange = fromState ~= toState

            if isShared and isChange then
                table.insert(changes, `{fromState} to {toState}`)
            end
        end
    end

    return changes
end

const function describeChanges(changes: { string }): string
    if #changes <= MAX_LISTED_CHANGES then
        return table.concat(changes, ", ")
    end

    const listed = table.concat(table.move(changes, 1, MAX_LISTED_CHANGES, 1, {}), ", ")

    return `{listed} and {#changes - MAX_LISTED_CHANGES} more`
end

-- Validates the `tweenOverrides` of one connection and returns a function that finds the override for a state
-- change, or nil when there are no overrides. Every problem is reported in one error, so they can be fixed together.
-- An entry's `tween` leaves a setting out to keep the one of `base`, the settings of the connection.
const function parse(overrides: unknown, stateNames: { string }, base: Options.Settings): Resolver?
    if overrides == nil then
        return nil
    end

    if not isArray(overrides) then
        error("onTransition tweenOverrides must be an array", 0)
    end

    local knownStates: { [string]: boolean } = {}

    for _, name in stateNames do
        knownStates[name] = true
    end

    local problems: { string } = {}
    local entries: { Entry } = {}

    for index, entry in overrides :: { unknown } do
        const label = `entry {index}`

        if type(entry) ~= "table" then
            table.insert(problems, `{label} must be a table`)

            continue
        end

        const fields = entry :: { [any]: unknown }
        local hasUnknownKey = false

        for key in fields do
            if ENTRY_KEYS[key :: any] ~= true then
                table.insert(problems, `{label} has an unknown key {key}`)

                hasUnknownKey = true
            end
        end

        const hasNoFrom = fields.from == nil
        const hasNoTo = fields.to == nil

        if hasNoFrom and hasNoTo then
            table.insert(problems, `{label} leaves out both from and to, so it matches every state change. Use tweenDefault for that`)
        end

        const fromSet = readSide(fields.from, `{label} from`, knownStates, problems)
        const toSet = readSide(fields.to, `{label} to`, knownStates, problems)

        local settings: Options.Settings? = nil

        if type(fields.tween) ~= "table" then
            table.insert(problems, `{label} needs a tween table`)
        else
            const ok, result = pcall(Options.parseSettings, fields.tween :: any, base)

            if ok then
                settings = result :: Options.Settings
            else
                table.insert(problems, `{label}: {result}`)
            end
        end

        if fromSet == nil or toSet == nil then
            continue
        end

        if hasUnknownKey then
            continue
        end

        const fromNames = sortedNames(fromSet)
        const toNames = sortedNames(toSet)
        local hasOneFrom = #fromNames == 1
        local hasOneTo = #toNames == 1
        local isSameState = fromNames[1] == toNames[1]
        local isOnlyOneState = hasOneFrom and hasOneTo and isSameState

        if isOnlyOneState then
            table.insert(problems, `{label} only matches {fromNames[1]} to {toNames[1]}, which is not a state change`)

            continue
        end

        table.insert(entries, {
            index = index,
            from = fromSet,
            to = toSet,
            settings = settings,
        })
    end

    for first = 1, #entries do
        for second = first + 1, #entries do
            const shared = sharedChanges(entries[first], entries[second])

            if #shared > 0 then
                table.insert(
                    problems,
                    `entries {entries[first].index} and {entries[second].index} both match {describeChanges(shared)}`
                )
            end
        end
    end

    if #problems > 0 then
        const plural = if #problems == 1 then "problem" else "problems"

        error(`onTransition tweenOverrides has {#problems} {plural}:\n- {table.concat(problems, "\n- ")}`, 0)
    end

    if #entries == 0 then
        return nil
    end

    return function(fromState: string, toState: string): Options.Settings?
        for _, entry in entries do
            local isFrom = entry.from[fromState] == true
            local isTo = entry.to[toState] == true

            if isFrom and isTo then
                return entry.settings
            end
        end

        return nil
    end
end

return table.freeze({
    parse = parse,
})
