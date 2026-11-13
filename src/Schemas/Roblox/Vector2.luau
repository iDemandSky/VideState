const TypedCore = require("@luau-packages/TypedCore")
const Helper = require("../Helper")

const function vector2(): TypedCore.Schema<Vector2>
    return Helper.createSchemaWithSource(
        "Vector2",
        function(value: unknown): TypedCore.ParseResult<Vector2>
            return Helper.parseType<<Vector2>>(value, "Vector2", "Vector2")
        end,
        nil,
        nil
    )
end

return vector2
