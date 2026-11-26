const TypedCore = require("../../../packages/luau/TypedCore")
const Helper = require("../Helper")

return function(): TypedCore.Schema<ColorSequence>
    return Helper.createSchemaWithSource(
        "ColorSequence",
        function(value: unknown): TypedCore.ParseResult<ColorSequence>
            return Helper.parseType<<ColorSequence>>(value, "ColorSequence", "ColorSequence")
        end,
        nil,
        nil
    )
end
