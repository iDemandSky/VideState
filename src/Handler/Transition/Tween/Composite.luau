const Ripple = require("../../../../packages/roblox/Ripple")
const Types = require("../../../Types")

-- Values that are built from several numbers: `NumberRange`, `NumberSequence`, and `ColorSequence`. Each part is
-- tweened by Ripple on its own and the value is put back together on every frame. A composite has the same `step`
-- and `configure` as a Ripple tween, so a transition steps it like any other field.
export type Composite = {
    step: (self: Composite, deltaTime: number) -> any,
    configure: (self: Composite, options: any) -> (),
}

-- Keypoint times of a sequence must start at 0, end at 1, and rise, so a time that an overshooting easing pushed
-- out of order is moved back in between its neighbours.
const TIME_GAP = 0.0001

const function createTween(from: any, to: any, easing: Types.TweenName?, duration: number): Ripple.Tween<any>
    local tween = Ripple.createTween(from, {
        easing = easing,
        duration = duration,
    })

    tween:setGoal(to)

    return tween
end

const function configureAll(tweens: { Ripple.Tween<any> }, options: any)
    for _, tween in tweens do
        tween:configure(options)
    end
end

const function fixTimes(times: { number })
    const count = #times

    times[1] = 0
    times[count] = 1

    for index = 2, count - 1 do
        const lowest = times[index - 1] + TIME_GAP
        const highest = 1 - (count - index) * TIME_GAP

        times[index] = math.clamp(times[index], lowest, highest)
    end
end

const function canTweenRange(from: unknown, to: unknown): boolean
    local isFromRange = typeof(from) == "NumberRange"
    local isToRange = typeof(to) == "NumberRange"

    return isFromRange and isToRange
end

const function canTweenNumberSequence(from: unknown, to: unknown): boolean
    local isFromSequence = typeof(from) == "NumberSequence"
    local isToSequence = typeof(to) == "NumberSequence"

    if not isFromSequence or not isToSequence then
        return false
    end

    return #(from :: NumberSequence).Keypoints == #(to :: NumberSequence).Keypoints
end

const function canTweenColorSequence(from: unknown, to: unknown): boolean
    local isFromSequence = typeof(from) == "ColorSequence"
    local isToSequence = typeof(to) == "ColorSequence"

    if not isFromSequence or not isToSequence then
        return false
    end

    return #(from :: ColorSequence).Keypoints == #(to :: ColorSequence).Keypoints
end

-- A sequence is only tweened when both values have the same number of keypoints. Otherwise there is no way to pair
-- the keypoints, so the value switches at the start like any other field that cannot be tweened.
const function canTween(from: unknown, to: unknown): boolean
    const isRange = canTweenRange(from, to)
    const isNumberSequence = canTweenNumberSequence(from, to)
    const isColorSequence = canTweenColorSequence(from, to)

    return isRange or isNumberSequence or isColorSequence
end

const function createRange(from: NumberRange, to: NumberRange, easing: Types.TweenName?, duration: number): Composite
    const tween = createTween({
        min = from.Min,
        max = from.Max,
    }, {
        min = to.Min,
        max = to.Max,
    }, easing, duration)

    return {
        step = function(_, deltaTime: number)
            const value = tween:step(deltaTime)

            -- An overshooting easing can push the minimum above the maximum, which a NumberRange rejects.
            return NumberRange.new(value.min, math.max(value.min, value.max))
        end,
        configure = function(_, options: any)
            tween:configure(options)
        end,
    }
end

const function createNumberSequence(
    from: NumberSequence,
    to: NumberSequence,
    easing: Types.TweenName?,
    duration: number
): Composite
    local tweens: { Ripple.Tween<any> } = {}

    for index, fromKeypoint in from.Keypoints do
        const toKeypoint = to.Keypoints[index]

        tweens[index] = createTween({
            time = fromKeypoint.Time,
            value = fromKeypoint.Value,
            envelope = fromKeypoint.Envelope,
        }, {
            time = toKeypoint.Time,
            value = toKeypoint.Value,
            envelope = toKeypoint.Envelope,
        }, easing, duration)
    end

    return {
        step = function(_, deltaTime: number)
            local times: { number } = {}
            local values: { any } = {}

            for index, tween in tweens do
                const value = tween:step(deltaTime)

                times[index] = value.time
                values[index] = value
            end

            fixTimes(times)

            local keypoints: { NumberSequenceKeypoint } = {}

            for index, value in values do
                keypoints[index] = NumberSequenceKeypoint.new(times[index], value.value, math.max(0, value.envelope))
            end

            return NumberSequence.new(keypoints)
        end,
        configure = function(_, options: any)
            configureAll(tweens, options)
        end,
    }
end

const function createColorSequence(
    from: ColorSequence,
    to: ColorSequence,
    easing: Types.TweenName?,
    duration: number
): Composite
    local timeTweens: { Ripple.Tween<any> } = {}
    local colorTweens: { Ripple.Tween<any> } = {}
    local allTweens: { Ripple.Tween<any> } = {}

    for index, fromKeypoint in from.Keypoints do
        const toKeypoint = to.Keypoints[index]

        timeTweens[index] = createTween(fromKeypoint.Time, toKeypoint.Time, easing, duration)
        colorTweens[index] = createTween(fromKeypoint.Value, toKeypoint.Value, easing, duration)

        table.insert(allTweens, timeTweens[index])
        table.insert(allTweens, colorTweens[index])
    end

    return {
        step = function(_, deltaTime: number)
            local times: { number } = {}
            local colors: { Color3 } = {}

            for index, tween in timeTweens do
                times[index] = tween:step(deltaTime)
                colors[index] = colorTweens[index]:step(deltaTime)
            end

            fixTimes(times)

            local keypoints: { ColorSequenceKeypoint } = {}

            for index, color in colors do
                keypoints[index] = ColorSequenceKeypoint.new(times[index], color)
            end

            return ColorSequence.new(keypoints)
        end,
        configure = function(_, options: any)
            configureAll(allTweens, options)
        end,
    }
end

const function create(from: unknown, to: unknown, easing: Types.TweenName?, duration: number): Composite
    if typeof(from) == "NumberRange" then
        return createRange(from :: NumberRange, to :: NumberRange, easing, duration)
    end

    if typeof(from) == "NumberSequence" then
        return createNumberSequence(from :: NumberSequence, to :: NumberSequence, easing, duration)
    end

    return createColorSequence(from :: ColorSequence, to :: ColorSequence, easing, duration)
end

return table.freeze({
    canTween = canTween,
    create = create,
})
