const TypedCore = require("@luau-packages/TypedCore")
const Vide = require("@packages/Vide")
const Validation = require("./Validation")
const EventEmitter = require("./Utils/EventEmitter")

export type Infer<S> = TypedCore.infer<S>
export type Source<T> = Vide.Source<T>
export type Sources<T> = Validation.Sources<T>

export type Disconnect = () -> ()
export type Callback<Args...> = (Args...) -> ()
export type OnChangeCallback<T> = (from: T, to: T) -> ()
export type OnTransitionCallback<T> = (from: T, to: T, alpha: number) -> ()
export type EventEmitter = typeof(EventEmitter)
export type HandlerOptions = {
    transitionDuration: number?,
}
export type Handler<T> = {
    sources: Sources<T>,
    currentState: Vide.Source<string>,
    setState: (stateName: string) -> (),
    onChange: (callback: OnChangeCallback<T>) -> Disconnect,
    onTransition: (callback: OnTransitionCallback<T>) -> Disconnect,
}
export type RuleMetaData<S> = {
    name: string,
    description: string?,
    --- Used for categorising the rules
    tags: { string }?,
    --- If none, then all state names are allowed
    allowedStateNames: { S }?,
}

return table.freeze({})