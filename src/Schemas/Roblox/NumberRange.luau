const TypedCore = require("../../../packages/luau/TypedCore")
const Helper = require("../Helper")

return function(): TypedCore.Schema<NumberRange>
    return Helper.createSchemaWithSource(
        "NumberRange",
        function(value: unknown): TypedCore.ParseResult<NumberRange>
            return Helper.parseType<<NumberRange>>(value, "NumberRange", "NumberRange")
        end,
        nil,
        nil
    )
end
