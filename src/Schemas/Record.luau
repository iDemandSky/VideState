const Typed = require("@luau-packages/Typed")
const TypedCore = require("@luau-packages/TypedCore")

const function record<Fields>(fields: Fields)
    assert(type(fields) == "table", "expected a table of field schemas")

    local definitions = fields :: { [string]: TypedCore.UnknownSchema }

    for name, schema in definitions do
        assert(type(name) == "string", `expected a string field name, got {typeof(name)}`)
        assert(
            type(schema) == "table"
                and type(schema.type) == "string"
                and type(schema.parse) == "function"
                and type(schema.unwrapParse) == "function"
                and type(schema.cast) == "function",
            `expected a schema for field "{name}"`
        )
    end

    return Typed.table(table.clone(definitions) :: Fields, { strict = true })
end

return record
