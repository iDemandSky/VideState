const Types = require("../Types")
const CreateEvent = require("../Utils/StartTimeEvent")

type Disconnect = Types.Disconnect

export type Pause = {
    -- Whether the handler is paused. The transitions read it every frame.
    read isPaused: () -> boolean,
    -- Pauses every running transition of the handler.
    read pause: () -> (),
    -- Continues the transitions that were paused.
    read resume: () -> (),
    read onPause: (callback: Types.OnPauseCallback) -> Disconnect,
    read onResume: (callback: Types.OnResumeCallback) -> Disconnect,
}

-- The pause state of one handler, with its `pause`, `resume`, `onPause`, and `onResume` functions.
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
