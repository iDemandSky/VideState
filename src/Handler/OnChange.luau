const Types = require("../Types")
const EventEmitter = require("../Utils/EventEmitter")

type Callback<T> = Types.OnChangeCallback<T>
type Disconnect = Types.Disconnect

return function <T>()
    local container = EventEmitter("onChange")

    const function onChange(callback: Callback<T>): Disconnect
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

    return onChange, container.emit
end