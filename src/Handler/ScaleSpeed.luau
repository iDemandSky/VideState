const Types = require("../Types")
const State = require("./Transition/State")

export type ScaleSpeed = {
    -- Scales the speed of the running transition, or of every transition with `permanent`.
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

-- Validates the options of `scaleSpeed` and returns the speed scale and whether it is permanent.
const function parse(options: unknown): (number, boolean)
    if typeof(options) ~= "table" then
        error("scaleSpeed options must be a table", 0)
    end

    local fields = options :: { [any]: unknown }

    for key in fields do
        local isSpeed = key == "speed"
        local isPermanent = key == "permanent"

        if not isSpeed and not isPermanent then
            error("scaleSpeed options has an unknown key " .. tostring(key), 0)
        end
    end

    local speed = fields.speed

    if not isValidScale(speed) then
        error("scaleSpeed speed must be a finite number above 0", 0)
    end

    local permanent = fields.permanent

    if permanent ~= nil and type(permanent) ~= "boolean" then
        error("scaleSpeed permanent must be a boolean", 0)
    end

    return speed :: number, permanent == true
end

-- The `scaleSpeed` function of a handler. It sets the scale that every connection of the running transition
-- multiplies its own speed by. A scale without `permanent` is reset by the next transition, and a permanent one stays.
return function <T>(state: State.State<T>): ScaleSpeed
    local controls: ScaleSpeed = {
        scaleSpeed = function(options: Types.ScaleSpeedOptions)
            local speed, permanent = parse(options)

            if permanent then
                state.baseScale = speed
            else
                state.scale = speed
            end
        end,
    }

    return table.freeze(controls)
end
