const TypedCore = require("../packages/luau/TypedCore")
const Vide = require("../packages/roblox/Vide")
const Validation = require("./Validation")
const EventEmitter = require("./Utils/EventEmitter")

--- The Luau type that a schema accepts.
export type Infer<S> = TypedCore.infer<S>
--- A reactive Vide source that holds a value of type T.
export type Source<T> = Vide.Source<T>
--- A record of Vide sources, one per field of the value record T.
export type Sources<T> = Validation.Sources<T>

type function ruleData(rule: type)
    assert(rule:is("table"), "InferRule expects a rule table")

    const schema = rule:readproperty(types.singleton("_schema"))
    assert(schema, "InferRule expects a rule with a _schema field")

    const data = schema:readproperty(types.singleton("infer"))
    assert(data, "InferRule expects a schema with an infer type")

    return data
end

--- The value type of a rule created with `VideState.rule`. Returns the schema data type.
export type InferRule<R> = ruleData<R>

--- Removes a listener when called.
export type Disconnect = () -> ()
--- A function that takes any arguments and returns nothing.
export type Callback<Args...> = (Args...) -> ()
--- Called when the state changes, with the previous and the new value.
export type OnChangeCallback<T> = (from: T, to: T) -> ()
--- The easing applied to tweened fields during a transition. Back and Elastic easings overshoot, so a tweened value can go past its start or end.
export type TweenName =
    "linear"
    | "quadIn" | "quadOut" | "quadInOut"
    | "cubicIn" | "cubicOut" | "cubicInOut"
    | "sineIn" | "sineOut" | "sineInOut"
    | "expoIn" | "expoOut" | "expoInOut"
    | "backIn" | "backOut" | "backInOut"
    | "elasticIn" | "elasticOut" | "elasticInOut"
--- An easing made with `VideState.bezier` or `VideState.easing`.
export type CustomEasing = {
    --- Takes the progress from 0 to 1 and returns the eased progress.
    read fn: (number) -> number,
}
--- An easing: the name of a built-in one, or one the game made.
export type Easing = TweenName | CustomEasing
--- The tween settings of one connection. A setting left out takes the built-in default. Each setting accepts a plain value or a Vide source, except `speed`, which is a source. A source is read every frame, so changing it affects the running transition and later ones.
export type TweenSettings = {
    --- The easing curve applied to animatable fields and to `alpha`. Defaults to linear.
    easing: (Easing | Source<Easing>)?,
    --- The duration in seconds. Must be finite and non-negative. Defaults to 0.25.
    duration: (number | Source<number>)?,
    --- How fast the transition advances. Must never be negative, so a transition never moves backwards. Defaults to 1, and 0 pauses.
    speed: Source<number>?,
    --- How long a connection waits before its tween starts, in seconds. Read when a transition starts. The wait is scaled by the speed, so pausing holds it. Defaults to 0.
    delay: (number | Source<number>)?,
}
--- Tween settings for some of the state changes of a handler. A state change is a state the handler leaves and a state it enters. At most one override of a connection may match a state change.
export type TweenOverride = {
    --- The states the handler leaves. Left out means every state.
    from: { string }?,
    --- The states the handler enters. Left out means every state.
    to: { string }?,
    --- The tween settings for the state changes that match. A setting left out keeps the one of `tweenDefault`.
    tween: TweenSettings,
}
--- Options for `onTransition` and `animate`.
export type TransitionOptions = {
    --- The tween settings of the connection.
    tweenDefault: TweenSettings?,
    --- Tween settings for particular state changes. An override replaces the settings of `tweenDefault` for the state changes it matches.
    tweenOverrides: { TweenOverride }?,
}
--- Called during a transition with the previous value, the new value, the current value, and the alpha. The current value tweens numeric and vector fields toward the new value and switches other fields to the new value at the start. The alpha is the eased progress from 0 to 1. Back and elastic easings overshoot, so it can go below 0 or above 1.
export type OnTransitionCallback<T> = (from: T, to: T, current: T, alpha: number) -> ()
--- Starts listening for transitions. A connection can pass options to override the tween settings of its handler. Returns a function that removes the listener.
export type ConnectTransition<T> = (callback: OnTransitionCallback<T>, options: TransitionOptions?) -> Disconnect
--- Creates a Vide source for every field that follows one `onTransition` connection. A connection can pass options to override the tween settings of its handler. Returns the sources and a function that removes the connection.
export type Animate<T> = (options: TransitionOptions?) -> (Sources<T>, Disconnect)
--- Creates a Vide source for the alpha of one `onTransition` connection. It starts at 1 and goes from 0 to 1 during each transition. A connection can pass options to override the tween settings of its handler. Returns the source and a function that removes the connection.
export type Progress<T> = (options: TransitionOptions?) -> (Source<number>, Disconnect)
--- One step of `playSequence`.
export type SequenceStep = {
    --- The state to change to. It must be a state of the handler.
    state: string,
    --- Seconds to wait after the step's transition has finished, before the next step. Scaled time, so a pause holds it. Defaults to 0.
    hold: number?,
    --- Skips the animation of this step. Defaults to false.
    instant: boolean?,
    --- Seconds every connection waits before this step starts, as in `SetStateOptions`. Defaults to 0.
    delay: number?,
}
--- Options for `playSequence`.
export type SequenceOptions = {
    --- Starts over after the last step, until the sequence is stopped. Defaults to false.
    loop: boolean?,
}
--- Changes the state step by step, waiting for each transition to finish. Returns a function that stops the sequence.
export type PlaySequence = (steps: { SequenceStep }, options: SequenceOptions?) -> Disconnect
--- Sends a state change to the listeners, with the previous and the new value.
export type StateEmitter<T> = (from: T, to: T) -> ()
--- Starts a transition on every `onTransition` connection. An instant transition ends on its first frame. The state names pick the tween settings of an override.
export type StartTransition<T> = (
    from: T,
    to: T,
    instant: boolean,
    fromState: string,
    toState: string,
    delay: number
) -> ()
--- Options for one `setState` call.
export type SetStateOptions = {
    --- Skips the animation. Every `onTransition` connection receives the next state's values at once, with an alpha of 1. Defaults to false.
    instant: boolean?,
    --- Seconds every connection waits before it starts, added to its own `delay`. Scaled like that delay, so a pause holds it. An instant change ignores it. Defaults to 0.
    delay: number?,
}
--- Options for `everyHandler.setState`.
export type EverySetStateOptions = {
    --- The same as in `SetStateOptions`.
    instant: boolean?,
    --- The same as in `SetStateOptions`, for every handler.
    delay: number?,
    --- Seconds between the handlers, in the order they were created: the first waits 0, the second this much, and so on. Added to `delay`. Defaults to 0.
    stagger: number?,
}
--- One `setState` that has listeners. It is finished when every connection that was playing it has ended.
export type Transition = {
    generation: number,
    pending: number,
    completed: boolean,
    fired: boolean,
}
--- Counts one connection of a transition as ended. `completed` is true when it reached its end.
export type SettleTransition = (transition: Transition, completed: boolean) -> ()
--- Called when a handler enters a state, with the name of the state it left.
export type OnEnterCallback = (previousState: string) -> ()
--- Called when a handler leaves a state, with the name of the state it enters.
export type OnExitCallback = (nextState: string) -> ()
--- Called when a handler is paused, with the `os.clock()` time at which its most recent transition started. If no transition has started yet, it is the time of the call.
export type OnPauseCallback = (startedAt: number) -> ()
--- Called when a handler is resumed, with the `os.clock()` time at which its most recent transition started.
export type OnResumeCallback = (startedAt: number) -> ()
--- Called when every running transition of a handler has reached its end, with the `os.clock()` time at which the transition started. It also runs after `finish`.
export type OnFinishCallback = (startedAt: number) -> ()
--- Options for `scaleSpeed`.
export type ScaleSpeedOptions = {
    --- How many times the speed is multiplied. Must be a finite number above 0. It multiplies each connection's own speed. Above 1 plays faster and below 1 plays slower.
    speed: number,
    --- When true, the scale applies only to the running transition, and the next `setState` plays at normal speed. When false, it also applies to every following transition, until `scaleSpeed` is called again. Defaults to false.
    once: boolean?,
}
--- The functions of `everyHandler`, and of every group that a filter returns.
export type EveryHandlerGroup = {
    --- Scales the speed of the handlers in scope. See `ScaleSpeedOptions`.
    read scaleSpeed: (options: ScaleSpeedOptions) -> (),
    --- Calls `pause` on every handler in scope.
    read pause: () -> (),
    --- Calls `resume` on every handler in scope.
    read resume: () -> (),
    --- Calls `finish` on every handler in scope.
    read finish: () -> (),
    --- Calls `destroy` on every handler in scope.
    read destroy: () -> (),
    --- Changes the state of every handler in scope. If any lacks the state, or its rule does not let it change to the state, one error lists them and none changes.
    read setState: (stateName: string, options: EverySetStateOptions?) -> (),
    --- How many handlers are in scope.
    read count: () -> number,
    --- Whether any handler in scope has a running transition.
    read isAnyRunning: () -> boolean,
    --- Whether any handler in scope is paused.
    read isAnyPaused: () -> boolean,
    --- Narrows the scope to the handlers whose rule has all of the tags.
    read withTags: (...string) -> EveryHandlerGroup,
    --- Narrows the scope to the handlers whose rule has none of the tags.
    read withoutTags: (...string) -> EveryHandlerGroup,
    --- Narrows the scope to the handlers of one rule.
    read withRule: (ruleName: string) -> EveryHandlerGroup,
    --- Narrows the scope to the handlers that are not of the rule.
    read withoutRule: (ruleName: string) -> EveryHandlerGroup,
    --- Narrows the scope to the handlers whose current state is one of the names.
    read withStates: (...string) -> EveryHandlerGroup,
    --- Narrows the scope to the handlers whose current state is none of the names.
    read withoutStates: (...string) -> EveryHandlerGroup,
}
--- What the debug tools report about one handler at one moment.
export type DebugSnapshot = {
    --- The label passed to `debug.track`, or the rule name.
    read label: string,
    --- The name of the rule that created the handler.
    read rule: string,
    --- The active state.
    read state: string,
    --- How many `onTransition` connections the handler has.
    read connections: number,
    --- Whether a transition is running.
    read isRunning: boolean,
    --- Whether the handler is paused.
    read isPaused: boolean,
    --- Whether the handler was destroyed.
    read isDestroyed: boolean,
    --- The `os.clock()` time at which the most recent transition started, or nil before the first one.
    read startedAt: number?,
}
--- The type of the EventEmitter utility module.
export type EventEmitter = typeof(EventEmitter)
--- A handler created from a rule. Each handler owns its state, sources, and cleanup.
export type Handler<T> = {
    read sources: Sources<T>,
    read currentState: () -> string,
    read setState: (stateName: string, options: SetStateOptions?) -> (),
    read onChange: (callback: OnChangeCallback<T>) -> Disconnect,
    read onEnter: (stateName: string, callback: OnEnterCallback) -> Disconnect,
    read onExit: (stateName: string, callback: OnExitCallback) -> Disconnect,
    read onTransition: ConnectTransition<T>,
    read animate: Animate<T>,
    read progress: Progress<T>,
    read playSequence: PlaySequence,
    read pause: () -> (),
    read resume: () -> (),
    read onPause: (callback: OnPauseCallback) -> Disconnect,
    read onResume: (callback: OnResumeCallback) -> Disconnect,
    read scaleSpeed: (options: ScaleSpeedOptions) -> (),
    read finish: () -> (),
    read onFinish: (callback: OnFinishCallback) -> Disconnect,
    read waitForFinish: () -> (),
    read destroy: () -> (),
}
--- Metadata passed to `VideState.rule`. `name` must be unique across all rules.
export type RuleMetadata<S> = {
    name: string,
    description: string?,
    --- Used for categorising the rules
    tags: { string }?,
    --- If none, then all state names are allowed
    allowedStateNames: { S }?,
    --- For a state, the only states it can change to. A state that is not listed can change to any state. `setState` raises an error for a change that is not listed.
    allowedTransitions: { [S]: { S } }?,
}

return table.freeze({})