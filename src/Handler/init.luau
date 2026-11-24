const Vide = require("../packages/roblox/Vide")
const TypedCore = require("../packages/luau/TypedCore")

const Types = require("./Types")
const Validation = require("./Validation")
const Change = require("@self/Change")
const StateEvents = require("@self/StateEvents")
const Transition = require("@self/Transition")
const TransitionState = require("@self/Transition/State")
const Pause = require("@self/Pause")
const FastForward = require("@self/FastForward")
const Finish = require("@self/Finish")
const SetState = require("@self/SetState")

type Sources<T> = Types.Sources<T>
type Handler<T> = Types.Handler<T>

-- Creates a handler. Each feature lives in its own module and provides the functions listed here:
--   Change      onChange
--   StateEvents onEnter, onExit
--   Transition  onTransition
--   Pause       pause, resume, onPause, onResume
--   FastForward fastForward
--   Finish      finish, onFinish
--   SetState    setState
return function <S>(
    schema: S,
    states: { [string]: Sources<TypedCore.infer<S>> },
    initialState: string,
    options: Types.HandlerOptions?,
    allowedStateNames: { string }?
)
    type Values = TypedCore.infer<S>

    local validatedStates = Validation.states(schema, states, initialState, allowedStateNames)
    local initialSources =
        Validation.state(validatedStates, initialState, "initial") :: { [string]: unknown }

    local currentState = Vide.source(initialState)
    local derivedSources: { [string]: unknown } = {}

    for fieldName in initialSources do
        derivedSources[fieldName] = function(...)
            local activeSources = Validation.state(validatedStates, currentState(), "current")
            -- A Vide source reads with no arguments and writes with one, so the call is forwarded as is.
            local source = Validation.source(activeSources :: { [string]: unknown }, fieldName) :: (...unknown) -> unknown

            return source(...)
        end
    end

    local sources = table.freeze(derivedSources) :: Sources<Values>
    local transitionOptions = if options == nil then nil else options.onTransition

    -- The transitions of the handler share this state, and the features below act on it.
    local state = TransitionState.create<<Values>>()

    local change = Change<<Values>>()
    local stateEvents = StateEvents(function(stateName: string): boolean
        return validatedStates[stateName] ~= nil
    end)
    local pause = Pause(function(): number
        return TransitionState.getStartedAt<<Values>>(state)
    end)
    local fastForward = FastForward<<Values>>(state)
    local finish = Finish<<Values>>(state)

    -- 0 holds every transition while the handler is paused.
    const function getRate(): number
        if pause.isPaused() then
            return 0
        end

        return state.scale
    end

    local transition = Transition<<Values>>(state, transitionOptions, getRate, finish.settle)
    local setState = SetState<<Values>>(
        function(stateName: string): Values
            local stateSources = Validation.state(validatedStates, stateName, "selected")
            return Validation.parseState(schema, stateName, stateSources :: Sources<Values>)
        end,
        currentState,
        stateEvents.emit,
        change.emit,
        transition.emit
    )

    return table.freeze({
        sources = sources,
        currentState = function()
            return currentState()
        end,
        setState = setState,
        onChange = change.onChange,
        onEnter = stateEvents.onEnter,
        onExit = stateEvents.onExit,
        onTransition = transition.onTransition,
        pause = pause.pause,
        resume = pause.resume,
        onPause = pause.onPause,
        onResume = pause.onResume,
        fastForward = fastForward.fastForward,
        finish = finish.finish,
        onFinish = finish.onFinish,
    })
end
