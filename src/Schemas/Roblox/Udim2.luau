const TypedCore = require("@luau-packages/TypedCore")
const Helper = require("../Helper")

const function udim2(): TypedCore.Schema<UDim2>
    return Helper.createSchemaWithSource(
        "UDim2",
        function(value: unknown): TypedCore.ParseResult<UDim2>
            return Helper.parseType<<UDim2>>(value, "UDim2", "UDim2")
        end,
        nil,
        nil
    )
end

return udim2
