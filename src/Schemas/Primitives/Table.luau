const Typed = require("../../../packages/luau/Typed")

return function <Fields>(fields: Fields)
    assert(type(fields) == "table", "expected a table of named field schemas")

    return Typed.table(fields, {
        strict = true,
    })
end

