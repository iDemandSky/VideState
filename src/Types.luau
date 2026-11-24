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
}
--- Called during a transition with the previous value, the new value, the current value, and the alpha. The current value tweens numeric and vector fields toward the new value and switches other fields to the new value at the start. The alpha is the eased progress from 0 to 1. Back and elastic easings overshoot, so it can go below 0 or above 1.
export type OnTransitionCallback<T> = (from: T, to: T, current: T, alpha: number) -> ()
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
    read setState: (stateName: string) -> (),
    read onChange: (callback: OnChangeCallback<T>) -> Disconnect,
    read onTransition: (callback: OnTransitionCallback<T>, options: TransitionOptions?) -> Disconnect,
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