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
    local stepMessage = "Float step must be positive and finite"

    if step ~= nil then
        assert(type(step) == "number", stepMessage)

        local isFinite = Helper.isFinite(step)
        local isPositive = step > 0

        assert(isFinite and isPositive, stepMessage)
    end

    Helper.assertOrderedBounds(min, max, "Float")

    local precision = if step then Helper.decimalPlaces(step) else nil
    local isPrecisionSupported = precision == nil or precision <= 308

    assert(isPrecisionSupported, "Float step precision is too small to validate")

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

            local isBelowMinimum = min ~= nil and numberValue < min
            local isAboveMaximum = max ~= nil and numberValue > max

            if isBelowMinimum then
                return Helper.invalidValue(`expected a number at least {min}, got {numberValue}`)
            end

            if isAboveMaximum then
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

