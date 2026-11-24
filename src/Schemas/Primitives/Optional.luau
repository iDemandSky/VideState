const Typed = require("../../../packages/luau/Typed")
const TypedCore = require("../../../packages/luau/TypedCore")
const Helper = require("../Helper")

return function <T>(schema: TypedCore.Schema<T>): TypedCore.Schema<T?>
    assert(type(schema) == "table" and type(schema.parse) == "function", "expected a schema to make optional")

    const optionalSchema = Typed.optional(schema)

    -- Helper tracks Vide sources, so a source that reads nil is accepted here.
    return Helper.createSchemaWithSource(
        "Optional",
        function(value: unknown): TypedCore.ParseResult<T?>
            return optionalSchema.parse(value)
        end,
        nil,
        nil
    )
end

