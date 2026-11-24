const Types = require("./Types")
const Registry = require("@self/Registry")
const CreateView = require("@self/View")

type Disconnect = Types.Disconnect

-- One tracked handler and the label it is listed under.
type Entry = {
    handler: unknown,
    label: string?,
    order: number,
}

local entries: { [unknown]: Entry } = {}
local nextOrder = 0

-- The inspect function of a handler. The error level of 3 points at the user's call to the debug function.
const function getInspect(handler: unknown, name: string): () -> Types.DebugSnapshot
    local inspect = Registry.get(handler)

    if inspect == nil then
        error(`debug.{name} expects a handler`, 3)
    end

    return inspect
end

-- Returns the snapshot with the label of the entry instead of the rule name.
const function withLabel(snapshot: Types.DebugSnapshot, label: string?): Types.DebugSnapshot
    if label == nil then
        return snapshot
    end

    local labeled = table.clone(snapshot) :: any

    labeled.label = label

    return table.freeze(labeled)
end

-- Lists a handler in `debug.list` and the debug view, under `label` or its rule name. Tracking a handler again
-- changes its label. A destroyed handler is removed from the list.
const function track(handler: unknown, label: string?): Disconnect
    getInspect(handler, "track")

    local hasLabel = label ~= nil
    local isTextLabel = type(label) == "string"

    if hasLabel and not isTextLabel then
        error("debug.track label must be a string", 2)
    end

    local entry = entries[handler]

    if entry == nil then
        nextOrder += 1
        entry = {
            handler = handler,
            label = label,
            order = nextOrder,
        }
        entries[handler] = entry
    else
        entry.label = label
    end

    local tracked = entry

    return function()
        if entries[handler] == tracked then
            entries[handler] = nil
        end
    end
end

-- What a handler looks like right now, whether or not it is tracked.
const function snapshot(handler: unknown): Types.DebugSnapshot
    local inspect = getInspect(handler, "snapshot")
    local entry = entries[handler]
    local label = if entry == nil then nil else entry.label

    return withLabel(inspect(), label)
end

-- The tracked handlers, in the order they were first tracked. Destroyed handlers are removed on the way.
const function list(): { Types.DebugSnapshot }
    local ordered: { Entry } = {}

    for _, entry in entries do
        table.insert(ordered, entry)
    end

    table.sort(ordered, function(a: Entry, b: Entry): boolean
        return a.order < b.order
    end)

    local snapshots: { Types.DebugSnapshot } = {}

    for _, entry in ordered do
        local inspect = Registry.get(entry.handler)

        if inspect == nil then
            continue
        end

        local current = withLabel(inspect(), entry.label)

        if current.isDestroyed then
            entries[entry.handler] = nil

            continue
        end

        table.insert(snapshots, current)
    end

    return snapshots
end

return table.freeze({
    track = track,
    snapshot = snapshot,
    list = list,
    view = CreateView(list),
})
