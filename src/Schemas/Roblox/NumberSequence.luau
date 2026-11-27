const TypedCore = require("../../../packages/luau/TypedCore")
const Helper = require("../Helper")

return function(): TypedCore.Schema<NumberSequence>
    return Helper.createSchemaWithSource(
        "NumberSequence",
        function(value: unknown): TypedCore.ParseResult<NumberSequence>
            return Helper.parseType<<NumberSequence>>(value, "NumberSequence", "NumberSequence")
        end,
        nil,
        nil
    )
end
