const TypedCore = require("@luau-packages/TypedCore")
const Helper = require("../Helper")

const function boolean(): TypedCore.Schema<boolean>
    return Helper.createSchemaWithSource(
        "Boolean",
        function(value: unknown): TypedCore.ParseResult<boolean>
            return Helper.parseType<<boolean>>(value, "boolean", "Boolean")
        end,
        nil,
        nil
    )
end

return boolean
