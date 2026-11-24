const TypedCore = require("@luau-packages/TypedCore")
const Helper = require("../Helper")

return function(...: string): TypedCore.Schema<string>
    local enumValues = table.pack(...)

    Helper.assertMinimumCount(enumValues.n, 1, "Enum requires at least one string value")

    local allowedValues: { [string]: boolean } = {}
    local allowedValueList = {}

    for index = 1, enumValues.n do
        local value = enumValues[index]
        Helper.assertType(value, "string", "String", `Enum argument {index}`)

        allowedValues[value] = true
        table.insert(allowedValueList, string.format("%q", value))
    end

    return Helper.createSchemaWithSource(
        "Enum",
        function(value: unknown): TypedCore.ParseResult<string>
            local result = Helper.parseType<<string>>(value, "string", "String")

            if not result.ok then
                return result
            end

            if not allowedValues[result.value] then
                return Helper.invalidValue(
                    `expected one of {table.concat(allowedValueList, ", ")}, got {string.format("%q", result.value)}`
                )
            end

            return result
        end,
        nil,
        nil
    )
end

