const TypedCore = require("../../../packages/luau/TypedCore")
const Helper = require("../Helper")

return function(): TypedCore.Schema<Vector2>
    return Helper.createSchemaWithSource(
        "Vector2",
        function(value: unknown): TypedCore.ParseResult<Vector2>
            return Helper.parseType<<Vector2>>(value, "Vector2", "Vector2")
        end,
        nil,
        nil
    )
end

