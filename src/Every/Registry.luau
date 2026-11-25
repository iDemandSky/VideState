const Types = require("../Types")

-- The functions of a handler that `everyHandler` calls. A handler of any rule has them.
export type Controls = {
    read pause: () -> (),
    read resume: () -> (),
    read finish: () -> (),
    read scaleSpeed: (options: Types.ScaleSpeedOptions) -> (),
    read setState: (stateName: string, options: Types.SetStateOptions?) -> (),
    read destroy: () -> (),
}

-- What the filters of a group read about a handler.
export type Entry = {
    -- The name of the rule, which the tags of the rule are read from.
    ruleName: string,
    -- The same snapshot the debug tools use, read each time so it is current.
    inspect: () -> Types.DebugSnapshot,
    -- Whether the handler has a state with this name.
    hasState: (stateName: string) -> boolean,
}

-- A handler together with what the filters read about it.
export type Member = {
    handler: Controls,
    entry: Entry,
}

-- Every live handler. The keys are weak, so a handler that nothing else holds is collected. An entry must not
-- hold its handler, or the key would stay alive.
const entries: { [Controls]: Entry } = setmetatable({}, { __mode = "k" }) :: any

const function add(handler: Controls, entry: Entry)
    entries[handler] = entry
end

-- A destroyed handler leaves the list.
const function remove(handler: Controls)
    entries[handler] = nil
end

-- A snapshot, so a callback that creates a handler cannot change the list while it is walked. With `matches`,
-- only the handlers it accepts are listed.
const function list(matches: ((entry: Entry) -> boolean)?): { Member }
    local members: { Member } = {}

    for handler, entry in entries do
        local isListed = matches == nil or matches(entry)

        if isListed then
            table.insert(members, {
                handler = handler,
                entry = entry,
            })
        end
    end

    return members
end

return table.freeze({
    add = add,
    remove = remove,
    list = list,
})
