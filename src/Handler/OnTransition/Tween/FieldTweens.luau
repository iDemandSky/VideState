const Ripple = require("@packages/Ripple")
const Types = require("@VideState/Types")
const CanTween = require("@VideState/Handler/OnTransition/Tween/CanTween")

export type FieldTweens = { [string]: Ripple.Tween<any> }

const function create<T>(from: T, to: T, easing: Types.TweenName?, duration: number): FieldTweens
    local tweens: FieldTweens = {}
    local fromFields = from :: any
    local toFields = to :: any

    for key, toValue in toFields do
        local fromValue = fromFields[key]

        if CanTween(fromValue, toValue) then
            local tween = Ripple.createTween(fromValue, {
                easing = easing,
                duration = duration,
            })
            tween:setGoal(toValue)
            tweens[key] = tween
        end
    end

    return tweens
end

-- Fields that can't be tweened keep their target value, so they switch at the start of the transition.
const function frame<T>(to: T, tweens: FieldTweens, deltaTime: number): T
    local current = table.clone(to :: any)

    for key, tween in tweens do
        current[key] = tween:step(deltaTime)
    end

    return table.freeze(current)
end

return table.freeze({
    create = create,
    frame = frame,
})
