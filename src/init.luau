const Types = require("@self/Types")

export type Infer<S> = Types.Infer<S>
export type InferRule<R> = Types.InferRule<R>
export type Source<T> = Types.Source<T>
export type Sources<T> = Types.Sources<T>
export type Disconnect = Types.Disconnect
export type OnChangeCallback<T> = Types.OnChangeCallback<T>
export type OnTransitionCallback<T> = Types.OnTransitionCallback<T>
export type OnPauseCallback = Types.OnPauseCallback
export type OnResumeCallback = Types.OnResumeCallback
export type OnFinishCallback = Types.OnFinishCallback
export type FastForwardOptions = Types.FastForwardOptions
export type SetStateOptions = Types.SetStateOptions
export type HandlerOptions = Types.HandlerOptions
export type Handler<T> = Types.Handler<T>
export type TweenName = Types.TweenName
export type TransitionOptions = Types.TransitionOptions

return table.freeze({
    -- PRIMITIVE SCHEMAS --
    boolean = require("@self/Schemas/Primitives/Boolean"),
    enum = require("@self/Schemas/Primitives/Enum"),
    float = require("@self/Schemas/Primitives/Float"),
    integer = require("@self/Schemas/Primitives/Integer"),
    optional = require("@self/Schemas/Primitives/Optional"),
    string = require("@self/Schemas/Primitives/String"),
    table = require("@self/Schemas/Primitives/Table"),
    record = require("@self/Schemas/Record"),
    color3 = require("@self/Schemas/Roblox/Color3"),
    udim = require("@self/Schemas/Roblox/Udim"),
    udim2 = require("@self/Schemas/Roblox/Udim2"),
    vector2 = require("@self/Schemas/Roblox/Vector2"),

    -- METHODS --
    rule = require("@self/Rule"),

    -- INFO --
    info = require("@self/Info"),
})
