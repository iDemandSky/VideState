const Types = require("../../../Types")
const CreateEvent = require("./Event")

type Disconnect = Types.Disconnect

export type Pause = {
    read isPaused: () -> boolean,
    read pause: () -> (),
    read resume: () -> (),
    read onPause: (callback: Types.OnPauseCallback) -> Disconnect,
    read onResume: (callback: Types.OnResumeCallback) -> Disconnect,
}

-- The pause state of one handler. Every running transition of the handler reads it, so one call pauses them all.
-- `getStartedAt` returns the start time that the events report.
return function(getStartedAt: () -> number): Pause
    local paused = false

    local onPause, emitPause = CreateEvent("onPause")
    local onResume, emitResume = CreateEvent("onResume")

    local controls: Pause = {
        isPaused = function(): boolean
            return paused
        end,
        pause = function()
            if paused then
                return
            end

            paused = true
            emitPause(getStartedAt())
        end,
        resume = function()
            if not paused then
                return
            end

            paused = false
            emitResume(getStartedAt())
        end,
        onPause = onPause,
        onResume = onResume,
    }

    return table.freeze(controls)
end
