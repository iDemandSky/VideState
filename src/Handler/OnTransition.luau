const Types = require("../Types")
const EventEmitter = require("../Utils/EventEmitter")

const DEFAULT_DURATION = 0.25

type Callback<T> = Types.OnTransitionCallback<T>
type Disconnect = Types.Disconnect

return function <T>(duration: number?)
    local transitionDuration = if duration == nil then DEFAULT_DURATION else duration
    if
        type(transitionDuration) ~= "number"
        or transitionDuration ~= transitionDuration
        or transitionDuration < 0
        or transitionDuration == math.huge
    then
        error("transition duration must be a finite non-negative number", 2)
    end

    local container = EventEmitter("onTransition")
    local generation = 0

    const function emitAlpha(from: T, to: T, alpha: number)
        container.emit(from, to, alpha)
    end

    const function emit(from: T, to: T)
        generation += 1
        local currentGeneration = generation

        if transitionDuration == 0 then
            emitAlpha(from, to, 1)
            return
        end

        if next(container.listeners) == nil then
            return
        end

        emitAlpha(from, to, 0)
        if generation ~= currentGeneration then
            return
        end

        task.spawn(function()
            local elapsed = 0

            while elapsed < transitionDuration do
                local deltaTime = task.wait()
                if generation ~= currentGeneration then
                    return
                end

                elapsed += deltaTime
                local alpha = math.clamp(elapsed / transitionDuration, 0, 1)
                if next(container.listeners) == nil then
                    return
                end
                emitAlpha(from, to, alpha)
            end
        end)
    end

    const function onTransition(callback: Callback<T>): Disconnect
        if typeof(callback) ~= "function" then
            error("onTransition callback must be a function", 2)
        end

        local listener: Callback<T> = callback
        local id = container.addListener(listener)
        local connected = true

        return function()
            if not connected then
                return
            end

            connected = false
            if container.listeners[id] == listener then
                container.removeListener(id)
            end
        end
    end

    return onTransition, emit
end