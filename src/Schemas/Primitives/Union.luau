const Typed = require("../../../packages/luau/Typed")
const TypedCore = require("../../../packages/luau/TypedCore")
const Helper = require("../Helper")

const function assertSchema(schema: unknown, name: string)
    local message = `expected {name} to be a schema`

    -- The table check comes first, because the parse check reads a field of the schema.
    assert(type(schema) == "table", message)

    local hasParse = type((schema :: { parse: unknown }).parse) == "function"

    assert(hasParse, message)
end

-- Accepts a value that either schema accepts. The first schema is tried first. More than two schemas are written by
-- nesting, such as `union(a, union(b, c))`.
return function <A, B>(first: TypedCore.Schema<A>, second: TypedCore.Schema<B>): TypedCore.Schema<A | B>
    assertSchema(first, "the first union schema")
    assertSchema(second, "the second union schema")

    const unionSchema = Typed.union(first, second)

    -- Helper tracks Vide sources, so a source that holds a value of either schema is accepted here.
    return Helper.createSchemaWithSource(
        "Union",
        function(value: unknown): TypedCore.ParseResult<A | B>
            return unionSchema.parse(value)
        end,
        nil,
        nil
    )
end
