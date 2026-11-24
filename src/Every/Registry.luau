const Types = require("../Types")
const Info = require("../Info")

-- The functions of a handler that `every.handler` calls. A handler of any rule has them.
export type Controls = {
    read pause: () -> (),
    read resume: () -> (),
    read finish: () -> (),
    read scaleSpeed: (options: Types.ScaleSpeedOptions) -> (),
    read destroy: () -> (),
}

-- Every live handler, with the name of its rule. The keys are weak, so a handler that nothing else holds is
-- collected. The rule name is what a tag filter reads the tags of the rule from.
const entries: { [Controls]: string } = setmetatable({}, { __mode = "k" }) :: any

const function add(handler: Controls, ruleName: string)
    entries[handler] = ruleName
end

-- A destroyed handler leaves the list.
const function remove(handler: Controls)
    entries[handler] = nil
end

-- Whether the rule has every one of the tags. Tags are compared exactly as written.
const function hasAllTags(ruleName: string, tags: { string }): boolean
    for _, tag in tags do
        if not Info.ruleHasTag(ruleName, tag) then
            return false
        end
    end

    return true
end

-- A snapshot, so a callback that creates a handler cannot change the list while it is walked. With `tags`, only
-- the handlers whose rule has all of them are listed.
const function list(tags: { string }?): { Controls }
    local handlers: { Controls } = {}

    for handler, ruleName in entries do
        local isListed = tags == nil or hasAllTags(ruleName, tags)

        if isListed then
            table.insert(handlers, handler)
        end
    end

    return handlers
end

return table.freeze({
    add = add,
    remove = remove,
    list = list,
})
