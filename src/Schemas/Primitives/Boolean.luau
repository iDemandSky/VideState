const TypedCore = require("../../../packages/luau/TypedCore")
const Helper = require("../Helper")

return function(): TypedCore.Schema<boolean>
    return Helper.createSchemaWithSource(
        "Boolean",
        function(value: unknown): TypedCore.ParseResult<boolean>
            return Helper.parseType<<boolean>>(value, "boolean", "Boolean")
        end,
        nil,
        nil
    )
end

