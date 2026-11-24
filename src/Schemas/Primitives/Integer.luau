const TypedCore = require("../../../packages/luau/TypedCore")
const Helper = require("../Helper")

export type IntegerOptions = {
    read min: number?,
    read max: number?,
}

return function(options: IntegerOptions?): TypedCore.Schema<number>
    Helper.assertOptionsTable(options, "Integer")

    local min = if options then options.min else nil
    local max = if options then options.max else nil

    if min ~= nil then
        Helper.assertInteger(min, "Integer minimum")
    end
    if max ~= nil then
        Helper.assertInteger(max, "Integer maximum")
    end
    Helper.assertOrderedBounds(min, max, "Integer")

    return Helper.createSchemaWithSource(
        "Integer",
        function(value: unknown): TypedCore.ParseResult<number>
            local result = Helper.parseType<<number>>(value, "number", "Integer")

            if not result.ok then
                return result
            end

            local numberValue = result.value

            if not Helper.isFinite(numberValue) or numberValue % 1 ~= 0 then
                return Helper.invalidValue(`expected a finite integer, got {numberValue}`)
            end

            if min ~= nil and numberValue < min then
                return Helper.invalidValue(`expected an integer at least {min}, got {numberValue}`)
            end

            if max ~= nil and numberValue > max then
                return Helper.invalidValue(`expected an integer at most {max}, got {numberValue}`)
            end

            return result
        end,
        nil,
        nil
    )
end

