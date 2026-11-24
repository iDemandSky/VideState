const Types = require("../Types")
const State = require("./Transition/State")

export type ScaleSpeed = {
    -- Scales the speed of every transition, or only of the running one with `once = true`.
    read scaleSpeed: (options: Types.ScaleSpeedOptions) -> (),
}

const function isValidScale(value: unknown): boolean
    if type(value) ~= "number" then
        return false
    end

    local isNotNaN = value == value
    local isPositive = value > 0
    local isNotInfinite = value ~= math.huge

    return isNotNaN and isPositive and isNotInfinite
end

-- Validates the options of `scaleSpeed` and returns the speed scale and whether it applies once.
const function parse(options: unknown): (number, boolean)
    if typeof(options) ~= "table" then
        error("scaleSpeed options must be a table", 0)
    end

    local fields = options :: { [any]: unknown }

    for key in fields do
        local isSpeed = key == "speed"
        local isOnce = key == "once"

        if not isSpeed and not isOnce then
            error("scaleSpeed options has an unknown key " .. tostring(key), 0)
        end
    end

    local speed = fields.speed

    if not isValidScale(speed) then
        error("scaleSpeed speed must be a finite number above 0", 0)
    end

    local once = fields.once

    if once ~= nil and type(once) ~= "boolean" then
        error("scaleSpeed once must be a boolean", 0)
    end

    return speed :: number, once == true
end

-- The `scaleSpeed` function of a handler. It sets the scale that every connection of the running transition
-- multiplies its own speed by. A scale with `once = true` is reset by the next transition, and any other stays.
return function <T>(state: State.State<T>): ScaleSpeed
    local controls: ScaleSpeed = {
        scaleSpeed = function(options: Types.ScaleSpeedOptions)
            local speed, once = parse(options)

            if once then
                state.scale = speed
            else
                state.baseScale = speed
            end
        end,
    }

    return table.freeze(controls)
end
