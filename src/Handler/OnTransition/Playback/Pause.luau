const Types = require("../../../Types")

type Disconnect = Types.Disconnect

export type Pause = {
    read isPaused: () -> boolean,
    read markStarted: () -> (),
    read pause: () -> (),
    read resume: () -> (),
    read onPause: (callback: Types.OnPauseCallback) -> Disconnect,
    read onResume: (callback: Types.OnResumeCallback) -> Disconnect,
}

-- A list of listeners that receive the start time. `connect` is returned to the user as it is, so the error
-- level of 2 points at the user's call.
const function createEvent(
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

-- The pause state of one handler. Every running transition of the handler reads it, so one call pauses them all.
return function(): Pause
    local paused = false
    local startedAt: number? = nil

    local onPause, emitPause = createEvent("onPause")
    local onResume, emitResume = createEvent("onResume")

    -- With no transition started yet, the time of the call stands in for the start time.
    const function currentStart(): number
        return startedAt or os.clock()
    end

    local controls: Pause = {
        isPaused = function(): boolean
            return paused
        end,
        markStarted = function()
            startedAt = os.clock()
        end,
        pause = function()
            if paused then
                return
            end

            paused = true
            emitPause(currentStart())
        end,
        resume = function()
            if not paused then
                return
            end

            paused = false
            emitResume(currentStart())
        end,
        onPause = onPause,
        onResume = onResume,
    }

    return table.freeze(controls)
end
