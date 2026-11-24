const Typed = require("@luau-packages/Typed")
const TypedCore = require("@luau-packages/TypedCore")
const Helper = require("../Helper")

return function <T>(schema: TypedCore.Schema<T>): TypedCore.Schema<T?>
    local message = "expected a schema to make optional"

    -- The table check comes first, because the parse check reads a field of the schema.
    assert(type(schema) == "table", message)

    local hasParse = type(schema.parse) == "function"

    assert(hasParse, message)

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

