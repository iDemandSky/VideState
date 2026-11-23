const Ripple = require("@packages/Ripple")
const Types = require("@VideState/Types")
const FieldTweens = require("@VideState/Handler/OnTransition/Tween/FieldTweens")

-- The tweens of one transition: one per animatable field, plus one from 0 to 1 that reports the alpha.
-- Every tween shares the same settings and is stepped with the same delta time, so they stay in step.
export type Group<T> = {
    to: T,
    fields: FieldTweens.FieldTweens,
    alpha: Ripple.Tween<number>,
    easing: Types.TweenName,
    duration: number,
}

const function create<T>(from: T, to: T, easing: Types.TweenName, duration: number): Group<T>
    local alpha = Ripple.createTween(0, {
        easing = easing,
        duration = duration,
    })

    alpha:setGoal(1)

    return {
        to = to,
        fields = FieldTweens.create(from, to, easing, duration),
        alpha = alpha,
        easing = easing,
        duration = duration,
    }
end

-- Applies changed settings to a running group. Ripple restarts each tween from its current position, so the
-- remaining distance is covered with the new settings and the values do not jump.
const function configure<T>(group: Group<T>, easing: Types.TweenName, duration: number)
    local isSame = group.easing == easing and group.duration == duration

    if isSame then
        return
    end

    group.easing = easing
    group.duration = duration

    local options = {
        easing = easing,
        duration = duration,
    }

    group.alpha:configure(options)

    for _, tween in group.fields do
        tween:configure(options)
    end
end

-- Returns the current value and the eased alpha. Back and elastic easings overshoot, so the alpha can leave 0 to 1.
const function step<T>(group: Group<T>, deltaTime: number): (T, number)
    local alpha = group.alpha:step(deltaTime)
    local current = FieldTweens.frame(group.to, group.fields, deltaTime)

    return current, alpha
end

const function isDone<T>(group: Group<T>): boolean
    return group.alpha:idle()
end

return table.freeze({
    create = create,
    configure = configure,
    step = step,
    isDone = isDone,
})
