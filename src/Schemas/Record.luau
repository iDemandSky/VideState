const Typed = require("../../packages/luau/Typed")
const TypedCore = require("../../packages/luau/TypedCore")

return function <Fields>(fields: Fields)
    assert(type(fields) == "table", "expected a table of field schemas")

    local definitions = fields :: { [string]: TypedCore.UnknownSchema }

    for name, schema in definitions do
        assert(type(name) == "string", `expected a string field name, got {typeof(name)}`)
        local message = `expected a schema for field "{name}"`

        -- The table check comes first, because the other checks read fields of the schema.
        assert(type(schema) == "table", message)

        local hasType = type(schema.type) == "string"
        local hasParse = type(schema.parse) == "function"
        local hasUnwrapParse = type(schema.unwrapParse) == "function"
        local hasCast = type(schema.cast) == "function"

        assert(hasType and hasParse and hasUnwrapParse and hasCast, message)
    end

    return Typed.table(table.clone(definitions) :: Fields, { strict = true })
end

