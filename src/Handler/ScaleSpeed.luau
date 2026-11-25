const Types = require("../Types")
const State = require("./Transition/State")
const SpeedScale = require("../Utils/SpeedScale")

export type ScaleSpeed = {
    -- Scales the speed of every transition, or only of the running one with `once = true`.
    read scaleSpeed: (options: Types.ScaleSpeedOptions) -> (),
}

-- The `scaleSpeed` function of a handler. It sets the scale that every connection of the running transition
-- multiplies its own speed by. A scale with `once = true` is reset by the next transition, and any other stays.
return function <T>(state: State.State<T>): ScaleSpeed
    local controls: ScaleSpeed = {
        scaleSpeed = function(options: Types.ScaleSpeedOptions)
            local speed, once = SpeedScale.parse(options, "scaleSpeed")

            if once then
                state.scale = speed
            else
                state.baseScale = speed
            end
        end,
    }

    return table.freeze(controls)
end
