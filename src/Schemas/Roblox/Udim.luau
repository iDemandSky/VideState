const TypedCore = require("@luau-packages/TypedCore")
const Helper = require("../Helper")

return function(): TypedCore.Schema<UDim>
    return Helper.createSchemaWithSource(
        "UDim",
        function(value: unknown): TypedCore.ParseResult<UDim>
            return Helper.parseType<<UDim>>(value, "UDim", "UDim")
        end,
        nil,
        nil
    )
end

