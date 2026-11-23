const TypedCore = require("@luau-packages/TypedCore")
const Vide = require("@packages/Vide")
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
--- Options for `onTransition`. `ripple` configures the Ripple tween applied to animatable fields. Without a `duration`, the listener uses the handler's transition duration.
export type TweenMetadata = {
    ripple: {
        --- The Ripple easing applied to animatable fields. Defaults to linear.
        easing: TweenName?,
        --- The duration in seconds for this listener. Must be finite and non-negative. Defaults to the handler's transition duration.
        duration: number?,
    }?,
}
--- Called during a transition with the previous value, the new value, and the current value. The current value tweens numeric and vector fields toward the new value and switches other fields to the new value at the start.
export type OnTransitionCallback<T> = (from: T, to: T, current: T) -> ()
--- The type of the EventEmitter utility module.
export type EventEmitter = typeof(EventEmitter)
--- Options for creating a handler. `transitionDuration` is in seconds and defaults to 0.25.
export type HandlerOptions = {
    transitionDuration: number?,
}
--- A handler created from a rule. Each handler owns its state, sources, and cleanup.
export type Handler<T> = {
    read sources: Sources<T>,
    read currentState: () -> string,
    read setState: (stateName: string) -> (),
    read onChange: (callback: OnChangeCallback<T>) -> Disconnect,
    read onTransition: (callback: OnTransitionCallback<T>, tweenMetadata: TweenMetadata?) -> Disconnect,
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