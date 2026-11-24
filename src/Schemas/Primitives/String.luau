const TypedCore = require("@luau-packages/TypedCore")
const Helper = require("../Helper")

export type StringOptions = {
    read maxLength: number?,
    read truncate: boolean?,
}

return function(options: StringOptions?): TypedCore.Schema<string>
    Helper.assertOptionsTable(options, "String")

    local maxLength = if options then options.maxLength else nil
    local truncate = if options then options.truncate else nil

    if maxLength ~= nil then
        Helper.assertInteger(maxLength, "String maxLength", 0)
    end

    local isTruncateMissing = truncate == nil
    local isTruncateBoolean = type(truncate) == "boolean"

    assert(isTruncateMissing or isTruncateBoolean, "String truncate must be a boolean")

    return Helper.createSchemaWithSource(
        "String",
        function(value: unknown): TypedCore.ParseResult<string>
            local result = Helper.parseType<<string>>(value, "string", "String")
            if not result.ok then
                return result
            end

            if maxLength == nil then
                return result
            end

            local stringValue = result.value
            local length, invalidByte = utf8.len(stringValue)

            if length == nil then
                return Helper.invalidValue(`String contains invalid UTF-8 at byte {invalidByte}`)
            end

            if length <= maxLength then
                return result
            end

            if not truncate then
                return Helper.invalidValue(
                    `expected a String no longer than {maxLength} code points, got {length}`
                )
            end

            local nextCodePoint = utf8.offset(stringValue, maxLength + 1)
            local truncated = if nextCodePoint
                then string.sub(stringValue, 1, nextCodePoint - 1)
                else stringValue

            return TypedCore.parseResult.ok(truncated)
        end,
        nil,
        nil
    )
end

