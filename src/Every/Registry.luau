const Types = require("../Types")

-- The functions of a handler that `every.handler` calls. A handler of any rule has them.
export type Controls = {
    read pause: () -> (),
    read resume: () -> (),
    read finish: () -> (),
    read scaleSpeed: (options: Types.ScaleSpeedOptions) -> (),
}

-- Every live handler, with the name of its rule. The keys are weak, so a handler that nothing else holds is
-- collected. The rule name is kept so a later filter, such as by the tags of the rule, needs no new bookkeeping.
const entries: { [Controls]: string } = setmetatable({}, { __mode = "k" }) :: any

const function add(handler: Controls, ruleName: string)
    entries[handler] = ruleName
end

-- A snapshot, so a callback that creates a handler cannot change the list while it is walked.
const function list(): { Controls }
    local handlers: { Controls } = {}

    for handler in entries do
        table.insert(handlers, handler)
    end

    return handlers
end

return table.freeze({
    add = add,
    list = list,
})
