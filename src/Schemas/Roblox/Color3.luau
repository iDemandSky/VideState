const TypedCore = require("@luau-packages/TypedCore")
const Helper = require("../Helper")

const function color3(): TypedCore.Schema<Color3>
    return Helper.createSchemaWithSource(
        "Color3",
        function(value: unknown): TypedCore.ParseResult<Color3>
            return Helper.parseType<<Color3>>(value, "Color3", "Color3")
        end,
        nil,
        nil
    )
end

return color3
