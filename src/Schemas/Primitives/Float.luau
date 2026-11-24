const TypedCore = require("../../../packages/luau/TypedCore")
const Helper = require("../Helper")

export type FloatOptions = {
    read min: number?,
    read max: number?,
    read step: number?,
}

return function(options: FloatOptions?): TypedCore.Schema<number>
    Helper.assertOptionsTable(options, "Float")

    local min = if options then options.min else nil
    local max = if options then options.max else nil
    local step = if options then options.step else nil

    Helper.assertFiniteOption(min, "Float minimum")
    Helper.assertFiniteOption(max, "Float maximum")
    assert(
        step == nil or (type(step) == "number" and Helper.isFinite(step) and step > 0),
        "Float step must be positive and finite"
    )
    Helper.assertOrderedBounds(min, max, "Float")

    local precision = if step then Helper.decimalPlaces(step) else nil
    assert(precision == nil or precision <= 308, "Float step precision is too small to validate")

    local scale = if precision then 10 ^ precision else nil

    return Helper.createSchemaWithSource(
        "Float",
        function(value: unknown): TypedCore.ParseResult<number>
            local result = Helper.parseType<<number>>(value, "number", "Float")
            if not result.ok then
                return result
            end

            local numberValue = result.value
            if not Helper.isFinite(numberValue) then
                return Helper.invalidValue("expected a finite number")
            end

            if min ~= nil and numberValue < min then
                return Helper.invalidValue(`expected a number at least {min}, got {numberValue}`)
            end

            if max ~= nil and numberValue > max then
                return Helper.invalidValue(`expected a number at most {max}, got {numberValue}`)
            end

            if precision ~= nil and scale ~= nil then
                local scaled = numberValue * scale
                if not Helper.isFinite(scaled) then
                    return Helper.invalidValue(`cannot validate decimal precision for {numberValue}`)
                end

                local rounded = math.round(scaled)
                local tolerance = math.max(1, math.abs(scaled)) * 2.220446049250313e-16 * 2
                if math.abs(scaled - rounded) > tolerance then
                    return Helper.invalidValue(
                        `expected at most {precision} decimal places (step {step}), got {numberValue}`
                    )
                end
            end

            return result
        end,
        nil,
        nil
    )
end

