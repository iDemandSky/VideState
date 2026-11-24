const Types = require("../Types")
const State = require("./Transition/State")

export type FastForward = {
    -- Plays the running transition faster. The next transition plays at normal speed.
    read fastForward: (options: Types.FastForwardOptions) -> (),
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

-- Validates the options of `fastForward` and returns the speed scale.
const function parse(options: unknown): number
    if typeof(options) ~= "table" then
        error("fastForward options must be a table", 0)
    end

    local fields = options :: { [any]: unknown }

    for key in fields do
        if key ~= "speed" then
            error("fastForward options has an unknown key " .. tostring(key), 0)
        end
    end

    local speed = fields.speed

    if not isValidScale(speed) then
        error("fastForward speed must be a finite number above 0", 0)
    end

    return speed :: number
end

-- The `fastForward` function of a handler. It sets the scale that every connection of the running transition
-- multiplies its own speed by, and the next transition resets it.
return function <T>(state: State.State<T>): FastForward
    local controls: FastForward = {
        fastForward = function(options: Types.FastForwardOptions)
            state.scale = parse(options)
        end,
    }

    return table.freeze(controls)
end
