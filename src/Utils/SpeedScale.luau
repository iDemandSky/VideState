-- Whether a value is a valid speed scale: a finite number above 0.
const function isValid(value: unknown): boolean
    if type(value) ~= "number" then
        return false
    end

    local isNotNaN = value == value
    local isPositive = value > 0
    local isNotInfinite = value ~= math.huge

    return isNotNaN and isPositive and isNotInfinite
end

-- Validates the options of a `scaleSpeed` function and returns the speed scale and whether it applies once.
-- `name` starts every error message, such as `scaleSpeed` or `every.handler.scaleSpeed`.
const function parse(options: unknown, name: string): (number, boolean)
    if typeof(options) ~= "table" then
        error(`{name} options must be a table`, 0)
    end

    local fields = options :: { [any]: unknown }

    for key in fields do
        local isSpeed = key == "speed"
        local isOnce = key == "once"

        if not isSpeed and not isOnce then
            error(`{name} options has an unknown key {tostring(key)}`, 0)
        end
    end

    local speed = fields.speed

    if not isValid(speed) then
        error(`{name} speed must be a finite number above 0`, 0)
    end

    local once = fields.once

    if once ~= nil and type(once) ~= "boolean" then
        error(`{name} once must be a boolean`, 0)
    end

    return speed :: number, once == true
end

return table.freeze({
    isValid = isValid,
    parse = parse,
})
