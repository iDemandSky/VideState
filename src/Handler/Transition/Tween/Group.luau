const Types = require("../../../Types")
const Easing = require("./Easing")
const Interpolate = require("./Interpolate")

-- The tweens of one transition. Every tween of a transition has the same duration and easing and is stepped with the
-- same delta time, so they all share one eased progress. It is worked out once for each frame, and each field and the
-- alpha only blend from their start to their end with it. A field that cannot be tweened is not listed: it keeps the
-- target value, so it switches at the start of the transition.
export type Group<T> = {
    to: T,
    -- The fields that are tweened, with where each one starts and ends and the last value it had.
    keys: { string },
    froms: { [string]: any },
    goals: { [string]: any },
    positions: { [string]: any },
    blends: { [string]: (number) -> any },
    -- The alpha goes from where it started to 1 with the same progress.
    alphaFrom: number,
    alphaPosition: number,
    elapsed: number,
    easing: Types.Easing,
    easingFunction: (number) -> number,
    duration: number,
    complete: boolean,
}

-- The function of an easing: a built-in name, or the function of a custom easing.
const function resolve(easing: Types.Easing): (number) -> number
    if type(easing) == "string" then
        return Easing[easing]
    end

    return (easing :: Types.CustomEasing).fn
end

const function create<T>(from: T, to: T, easing: Types.Easing, duration: number): Group<T>
    local keys: { string } = {}
    local froms: { [string]: any } = {}
    local goals: { [string]: any } = {}
    local positions: { [string]: any } = {}
    local blends: { [string]: (number) -> any } = {}

    for key, toValue in to :: any do
        const fromValue = (from :: any)[key]

        if not Interpolate.isTweenable(fromValue, toValue) then
            continue
        end

        -- A field that already has its target value has nothing to move.
        local isTable = typeof(fromValue) == "table"
        local isUnchanged = fromValue == toValue

        if isUnchanged and not isTable then
            continue
        end

        table.insert(keys, key)

        froms[key] = fromValue
        goals[key] = toValue
        positions[key] = fromValue
        blends[key] = Interpolate.make(fromValue, toValue)
    end

    return {
        to = to,
        keys = keys,
        froms = froms,
        goals = goals,
        positions = positions,
        blends = blends,
        alphaFrom = 0,
        alphaPosition = 0,
        elapsed = 0,
        easing = easing,
        easingFunction = resolve(easing),
        duration = duration,
        complete = false,
    }
end

-- Applies changed settings to a running group. Every tween restarts from its current position, so the remaining
-- distance is covered with the new settings and the values do not jump, but the easing curve starts again from that
-- point.
const function configure<T>(group: Group<T>, easing: Types.Easing, duration: number)
    local isSameEasing = group.easing == easing
    local isSameDuration = group.duration == duration
    local isSame = isSameEasing and isSameDuration

    if isSame then
        return
    end

    group.easing = easing
    group.easingFunction = resolve(easing) or group.easingFunction
    group.duration = duration

    if group.complete or group.elapsed == 0 then
        return
    end

    group.elapsed = 0
    group.alphaFrom = group.alphaPosition

    for _, key in group.keys do
        group.froms[key] = group.positions[key]
        group.blends[key] = Interpolate.make(group.froms[key], group.goals[key])
    end
end

-- Returns the current value and the eased alpha. Back and elastic easings overshoot, so the alpha can leave 0 to 1.
const function step<T>(group: Group<T>, deltaTime: number): (T, number)
    if not group.complete then
        group.elapsed += deltaTime

        local progress = math.clamp(group.elapsed / group.duration, 0, 1)

        if progress ~= progress then
            progress = 1
        end

        local isMoving = progress > 0 and progress < 1
        local eased = if isMoving then group.easingFunction(progress) else progress

        group.alphaPosition = group.alphaFrom + (1 - group.alphaFrom) * eased

        for _, key in group.keys do
            group.positions[key] = group.blends[key](eased)
        end

        if progress == 1 then
            group.complete = true
        end
    end

    -- Fields that cannot be tweened keep their target value.
    local current = table.clone(group.to :: any)

    for _, key in group.keys do
        current[key] = group.positions[key]
    end

    return table.freeze(current), group.alphaPosition
end

const function isDone<T>(group: Group<T>): boolean
    return group.complete
end

return table.freeze({
    create = create,
    configure = configure,
    step = step,
    isDone = isDone,
})
