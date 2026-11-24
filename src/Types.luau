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
--- Settings for how `onTransition` animates between states. A field left out is inherited from the handler options, then from the default. Each field accepts a plain value or a Vide source. A source is read every frame, so changing it affects the running transition and later ones.
export type TransitionOptions = {
    --- The Ripple easing applied to animatable fields and to `alpha`. Defaults to linear.
    easing: (TweenName | Source<TweenName>)?,
    --- The duration in seconds. Must be finite and non-negative. Defaults to 0.25.
    duration: (number | Source<number>)?,
    --- How fast the transition advances. Must never be negative, so a transition never moves backwards. Defaults to 1, and 0 pauses.
    speed: Source<number>?,
    --- How long a connection waits before its tween starts, in seconds. Read when a transition starts. The wait is scaled by the speed, so pausing holds it. Defaults to 0.
    delay: (number | Source<number>)?,
}
--- Called during a transition with the previous value, the new value, the current value, and the alpha. The current value tweens numeric and vector fields toward the new value and switches other fields to the new value at the start. The alpha is the eased progress from 0 to 1. Back and elastic easings overshoot, so it can go below 0 or above 1.
export type OnTransitionCallback<T> = (from: T, to: T, current: T, alpha: number) -> ()
--- Starts listening for transitions. A connection can pass options to override the tween settings of its handler. Returns a function that removes the listener.
export type ConnectTransition<T> = (callback: OnTransitionCallback<T>, options: TransitionOptions?) -> Disconnect
--- Sends a state change to the listeners, with the previous and the new value.
export type StateEmitter<T> = (from: T, to: T) -> ()
--- Starts a transition on every `onTransition` connection. An instant transition ends on its first frame.
export type StartTransition<T> = (from: T, to: T, instant: boolean) -> ()
--- Options for one `setState` call.
export type SetStateOptions = {
    --- Skips the animation. Every `onTransition` connection receives the next state's values at once, with an alpha of 1. Defaults to false.
    instant: boolean?,
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
--- Options for creating a handler. `onTransition` sets the default tween settings of its `onTransition` listeners. A listener can override them with its own options.
export type HandlerOptions = {
    onTransition: TransitionOptions?,
}
--- A handler created from a rule. Each handler owns its state, sources, and cleanup.
export type Handler<T> = {
    read sources: Sources<T>,
    read currentState: () -> string,
    read setState: (stateName: string, options: SetStateOptions?) -> (),
    read onChange: (callback: OnChangeCallback<T>) -> Disconnect,
    read onEnter: (stateName: string, callback: OnEnterCallback) -> Disconnect,
    read onExit: (stateName: string, callback: OnExitCallback) -> Disconnect,
    read onTransition: ConnectTransition<T>,
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
}

return table.freeze({})