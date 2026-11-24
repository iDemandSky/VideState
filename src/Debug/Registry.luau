const Types = require("../Types")

-- How the debug tools read a handler. Every handler adds its inspect function here when it is created. The keys
-- are weak, so an entry goes away with its handler, and nothing is listed until a handler is tracked.
const inspectors: { [any]: () -> Types.DebugSnapshot } = setmetatable({}, {
    __mode = "k",
}) :: any

const function register(handler: unknown, inspect: () -> Types.DebugSnapshot)
    inspectors[handler] = inspect
end

-- The inspect function of a handler, or nil when the value is not a handler.
const function get(handler: unknown): (() -> Types.DebugSnapshot)?
    return inspectors[handler]
end

return table.freeze({
    register = register,
    get = get,
})
