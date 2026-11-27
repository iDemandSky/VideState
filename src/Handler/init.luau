const Vide = require("../packages/roblox/Vide")
const TypedCore = require("../packages/luau/TypedCore")

const Types = require("./Types")
const Validation = require("./Validation")
const Transitions = require("./Transitions")
const DebugRegistry = require("./Debug/Registry")
const EveryRegistry = require("./Every/Registry")
const EveryScale = require("./Every/Scale")
const Change = require("@self/Change")
const StateEvents = require("@self/StateEvents")
const Animate = require("@self/Animate")
const Progress = require("@self/Progress")
const Transition = require("@self/Transition")
const TransitionState = require("@self/Transition/State")
const Pause = require("@self/Pause")
const ScaleSpeed = require("@self/ScaleSpeed")
const Finish = require("@self/Finish")
const SetState = require("@self/SetState")

type Sources<T> = Types.Sources<T>
type Handler<T> = Types.Handler<T>

-- Creates a handler. Each feature lives in its own module and provides the functions listed here:
--   Change      onChange
--   StateEvents onEnter, onExit
--   Transition  onTransition
--   Animate     animate
--   Progress    progress
--   Pause       pause, resume, onPause, onResume
--   ScaleSpeed scaleSpeed
--   Finish      finish, onFinish, waitForFinish
--   SetState    setState
-- `destroy` is defined here, because it stops every feature, and so is the inspect function for the debug tools.
return function <S>(
    schema: S,
    states: { [string]: Sources<TypedCore.infer<S>> },
    initialState: string,
    allowedStateNames: { string }?,
    ruleName: string,
    allowedTransitions: { [string]: { string } }?
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
    local stateNames: { string } = {}

    for stateName in validatedStates do
        table.insert(stateNames, stateName)
    end

    table.sort(stateNames)

    const transitionRules = Transitions.parse(allowedTransitions, stateNames, "the handler")

    -- The transitions of the handler share this state, and the features below act on it.
    local state = TransitionState.create<<Values>>()

    local change = Change<<Values>>()
    local stateEvents = StateEvents(function(stateName: string): boolean
        return validatedStates[stateName] ~= nil
    end)
    local pause = Pause(function(): number
        return TransitionState.getStartedAt<<Values>>(state)
    end)
    local scaleSpeed = ScaleSpeed<<Values>>(state)
    local finish = Finish<<Values>>(state)

    -- 0 holds every transition while the handler is paused.
    const function getRate(): number
        if pause.isPaused() then
            return 0
        end

        return state.scale * state.baseScale * EveryScale.get()
    end

    local transition = Transition<<Values>>(state, stateNames, getRate, finish.settle)
    local animate = Animate<<Values>>(transition.onTransition, sources)
    local progress = Progress<<Values>>(transition.onTransition)
    local destroyed = false
    local registered: EveryRegistry.Controls? = nil

    -- Stops every transition and removes every listener. `setState` raises an error afterwards.
    const function destroy()
        if destroyed then
            return
        end

        destroyed = true

        if registered ~= nil then
            EveryRegistry.remove(registered)
        end

        transition.stop()
        change.clear()
        stateEvents.clear()
        pause.clear()
        finish.clear()
    end

    local setState = SetState<<Values>>(
        function(stateName: string): Values
            local stateSources = Validation.state(validatedStates, stateName, "selected")
            return Validation.parseState(schema, stateName, stateSources :: Sources<Values>)
        end,
        function(): boolean
            return destroyed
        end,
        currentState,
        transitionRules,
        stateEvents.emit,
        change.emit,
        transition.emit
    )

    -- What the debug tools show about this handler. The label is filled in by `debug.track`.
    const function inspect(): Types.DebugSnapshot
        local running = state.currentTransition
        local isRunning = running ~= nil and running.pending > 0
        local connections = 0

        for _ in state.connections do
            connections += 1
        end

        return table.freeze({
            label = ruleName,
            rule = ruleName,
            state = currentState(),
            connections = connections,
            isRunning = isRunning,
            isPaused = pause.isPaused(),
            isDestroyed = destroyed,
            startedAt = state.startedAt,
        })
    end

    local handler = table.freeze({
        sources = sources,
        currentState = function()
            return currentState()
        end,
        setState = setState,
        onChange = change.onChange,
        onEnter = stateEvents.onEnter,
        onExit = stateEvents.onExit,
        onTransition = transition.onTransition,
        animate = animate,
        progress = progress,
        pause = pause.pause,
        resume = pause.resume,
        onPause = pause.onPause,
        onResume = pause.onResume,
        scaleSpeed = scaleSpeed.scaleSpeed,
        finish = finish.finish,
        onFinish = finish.onFinish,
        waitForFinish = finish.waitForFinish,
        destroy = destroy,
    })

    DebugRegistry.register(handler, inspect)
    registered = handler
    EveryRegistry.add(handler, {
        ruleName = ruleName,
        inspect = inspect,
        hasState = function(stateName: string): boolean
            return validatedStates[stateName] ~= nil
        end,
        canChangeTo = function(stateName: string): boolean
            return Transitions.canChange(transitionRules, currentState(), stateName)
        end,
    })

    return handler
end
