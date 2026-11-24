const Types = require("../Types")

type Disconnect = Types.Disconnect

-- A list of listeners that receive the start time of the transition. `connect` is returned to the user as it
-- is, so the error level of 2 points at the user's call.
return function(
    name: string
): ((callback: (startedAt: number) -> ()) -> Disconnect, (startedAt: number) -> ())
    local listeners: { [number]: (startedAt: number) -> () } = {}
    local nextId = 0

    const function connect(callback: (startedAt: number) -> ()): Disconnect
        if typeof(callback) ~= "function" then
            error(name .. " callback must be a function", 2)
        end

        nextId += 1

        local id = nextId

        listeners[id] = callback

        return function()
            listeners[id] = nil
        end
    end

    const function emit(startedAt: number)
        local ids: { number } = {}

        for id in listeners do
            table.insert(ids, id)
        end

        for _, id in ids do
            local listener = listeners[id]

            if listener ~= nil then
                listener(startedAt)
            end
        end
    end

    return connect, emit
end
