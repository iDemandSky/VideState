const Types = require("../Types")
const Options = require("@self/Config/Options")
const State = require("@self/Playback/State")
const Connect = require("@self/Playback/Connect")
const Start = require("@self/Playback/Start")
const Lifecycle = require("@self/Playback/Lifecycle")
const CreatePause = require("@self/Playback/Pause")

type Disconnect = Types.Disconnect

-- The functions of a handler that control its running transitions.
export type Controls = {
    read pause: () -> (),
    read resume: () -> (),
    read onPause: (callback: Types.OnPauseCallback) -> Disconnect,
    read onResume: (callback: Types.OnResumeCallback) -> Disconnect,
    read fastForward: (options: Types.FastForwardOptions) -> (),
    read finish: () -> (),
    read onFinish: (callback: Types.OnFinishCallback) -> Disconnect,
}

-- Wires the parts of one handler's transitions together. Each part lives in `Playback`:
-- `State` holds what they share, `Connect` makes `onTransition`, `Start` starts a transition,
-- `Lifecycle` ends one, and `Pause` holds and releases them all.
return function <T>(
    options: Types.TransitionOptions?
): ((callback: State.Callback<T>, options: Types.TransitionOptions?) -> Disconnect, (from: T, to: T) -> (), Controls)
    local handlerSettings = Options.parse(options)
    local state = State.create<<T>>()

    local pause = CreatePause(function(): number
        return State.getStartedAt(state)
    end)
    local lifecycle = Lifecycle(state)

    -- 0 holds every transition while the handler is paused.
    const function getRate(): number
        if pause.isPaused() then
            return 0
        end

        return state.scale
    end

    const function fastForward(fastForwardOptions: Types.FastForwardOptions)
        state.scale = Options.parseFastForward(fastForwardOptions)
    end

    local controls: Controls = {
        pause = pause.pause,
        resume = pause.resume,
        onPause = pause.onPause,
        onResume = pause.onResume,
        fastForward = fastForward,
        finish = lifecycle.finish,
        onFinish = lifecycle.onFinish,
    }

    return Connect(state, handlerSettings, lifecycle.settle),
        Start(state, getRate, lifecycle.settle),
        table.freeze(controls)
end
