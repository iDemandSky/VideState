const Types = require("../Types")
const EventEmitter = require("../Utils/EventEmitter")

type Disconnect = Types.Disconnect

export type Change<T> = {
    -- Listens for state changes. Returns a function that removes the listener.
    read onChange: (callback: Types.OnChangeCallback<T>) -> Disconnect,
    -- Sends a state change to every listener.
    read emit: Types.StateEmitter<T>,
    -- Removes every listener. `destroy` calls it.
    read clear: () -> (),
}

-- The `onChange` event of a handler: it runs once when the state changes.
return function <T>(): Change<T>
    local container = EventEmitter("onChange")

    const function onChange(callback: Types.OnChangeCallback<T>): Disconnect
        local id = container.addListener(callback)
        local connected = true

        return function()
            if not connected then
                return
            end

            connected = false

            if container.listeners[id] == callback then
                container.removeListener(id)
            end
        end
    end

    local change: Change<T> = {
        onChange = onChange,
        emit = container.emit,
        clear = function()
            table.clear(container.listeners)
        end,
    }

    return table.freeze(change)
end
