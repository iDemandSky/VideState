-- The `allowedTransitions` of a rule: for a state, the only states it can change to. A state that is not listed can
-- change to any state.
export type Rules = { [string]: { [string]: boolean } }

const function quote(names: { string }): string
    local quoted: { string } = {}

    for _, name in names do
        table.insert(quoted, `"{name}"`)
    end

    return table.concat(quoted, ", ")
end

-- Checks `allowed` and returns it as sets. With `stateNames`, every name must be one of them, and `owner` says whose
-- states they are, such as `the rule` or `the handler`. The error level of 0 keeps the message as it is written.
const function parse(allowed: unknown, stateNames: { string }?, owner: string): Rules?
    if allowed == nil then
        return nil
    end

    if type(allowed) ~= "table" then
        error("allowedTransitions must be a table of state names to lists of state names", 0)
    end

    const rules: Rules = {}

    for from, targets in allowed :: { [any]: unknown } do
        if type(from) ~= "string" then
            error(`allowedTransitions keys must be state names, got {typeof(from)}`, 0)
        end

        if stateNames ~= nil and not table.find(stateNames, from) then
            error(`allowedTransitions "{from}" is not a state of {owner}`, 0)
        end

        if type(targets) ~= "table" then
            error(`allowedTransitions "{from}" must be a list of state names`, 0)
        end

        if #(targets :: { unknown }) == 0 then
            error(`allowedTransitions "{from}" must list at least one state`, 0)
        end

        const set: { [string]: boolean } = {}

        for _, target in targets :: { unknown } do
            if type(target) ~= "string" then
                error(`allowedTransitions "{from}" must list state names, got {typeof(target)}`, 0)
            end

            if stateNames ~= nil and not table.find(stateNames, target) then
                error(`allowedTransitions "{from}" lists "{target}", which is not a state of {owner}`, 0)
            end

            set[target] = true
        end

        rules[from] = set
    end

    return rules
end

-- Whether a handler in the state `from` may change to `to`.
const function canChange(rules: Rules?, from: string, to: string): boolean
    if rules == nil then
        return true
    end

    const set = rules[from]

    if set == nil then
        return true
    end

    return set[to] == true
end

-- The names `from` may change to, in order, such as `"Idle", "Open"`.
const function describeAllowed(rules: Rules, from: string): string
    local names: { string } = {}

    for name in rules[from] or {} do
        table.insert(names, name)
    end

    table.sort(names)

    return quote(names)
end

return table.freeze({
    parse = parse,
    canChange = canChange,
    describeAllowed = describeAllowed,
})
