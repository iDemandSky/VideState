const Types = require("@self/Types")
const ReducedMotion = require("@self/ReducedMotion")
const Custom = require("@self/Handler/Transition/Tween/Custom")

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
export type ScaleSpeedOptions = Types.ScaleSpeedOptions
export type EveryHandlerGroup = Types.EveryHandlerGroup
export type SetStateOptions = Types.SetStateOptions
export type EverySetStateOptions = Types.EverySetStateOptions
export type OnEnterCallback = Types.OnEnterCallback
export type OnExitCallback = Types.OnExitCallback
export type TweenSettings = Types.TweenSettings
export type TweenOverride = Types.TweenOverride
export type Progress<T> = Types.Progress<T>
export type Handler<T> = Types.Handler<T>
export type TweenName = Types.TweenName
export type CustomEasing = Types.CustomEasing
export type Easing = Types.Easing
export type TransitionOptions = Types.TransitionOptions
export type DebugSnapshot = Types.DebugSnapshot

return table.freeze({
    -- PRIMITIVE SCHEMAS --
    boolean = require("@self/Schemas/Primitives/Boolean"),
    enum = require("@self/Schemas/Primitives/Enum"),
    float = require("@self/Schemas/Primitives/Float"),
    integer = require("@self/Schemas/Primitives/Integer"),
    optional = require("@self/Schemas/Primitives/Optional"),
    union = require("@self/Schemas/Primitives/Union"),
    string = require("@self/Schemas/Primitives/String"),
    table = require("@self/Schemas/Primitives/Table"),
    record = require("@self/Schemas/Record"),
    color3 = require("@self/Schemas/Roblox/Color3"),
    numberRange = require("@self/Schemas/Roblox/NumberRange"),
    numberSequence = require("@self/Schemas/Roblox/NumberSequence"),
    colorSequence = require("@self/Schemas/Roblox/ColorSequence"),
    udim = require("@self/Schemas/Roblox/Udim"),
    udim2 = require("@self/Schemas/Roblox/Udim2"),
    vector2 = require("@self/Schemas/Roblox/Vector2"),

    -- METHODS --
    rule = require("@self/Rule"),

    -- EASING --
    bezier = Custom.bezier,
    easing = Custom.fromFunction,

    -- REDUCED MOTION --
    setReducedMotion = ReducedMotion.set,
    isReducedMotion = ReducedMotion.get,

    -- EVERY HANDLER --
    everyHandler = require("@self/Every"),

    -- INFO --
    info = require("@self/Info"),

    -- DEBUG --
    debug = require("@self/Debug"),
})
