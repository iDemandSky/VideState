const Types = require("@self/Types")

export type Infer<S> = Types.Infer<S>
export type Source<T> = Types.Source<T>
export type Sources<T> = Types.Sources<T>
export type Disconnect = Types.Disconnect
export type OnChangeCallback<T> = Types.OnChangeCallback<T>
export type OnTransitionCallback<T> = Types.OnTransitionCallback<T>
export type HandlerOptions = Types.HandlerOptions
export type Handler<T> = Types.Handler<T>

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
