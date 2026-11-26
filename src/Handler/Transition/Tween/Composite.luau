const Color = require("./Color")

-- Values that are built from several numbers: `NumberRange`, `NumberSequence`, and `ColorSequence`. Each part is
-- blended on its own and the value is put back together on every frame.

-- Keypoint times of a sequence must start at 0, end at 1, and rise, so a time that an overshooting easing pushed
-- out of order is moved back in between its neighbours.
const TIME_GAP = 0.0001

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

const function makeRange(from: NumberRange, to: NumberRange): (number) -> any
    const fromMin = from.Min
    const fromMax = from.Max
    const deltaMin = to.Min - fromMin
    const deltaMax = to.Max - fromMax

    return function(alpha: number): any
        const min = fromMin + deltaMin * alpha
        const max = fromMax + deltaMax * alpha

        -- An overshooting easing can push the minimum above the maximum, which a NumberRange rejects.
        return NumberRange.new(min, math.max(min, max))
    end
end

const function makeNumberSequence(from: NumberSequence, to: NumberSequence): (number) -> any
    const count = #from.Keypoints
    local fromTimes: { number } = {}
    local fromValues: { number } = {}
    local fromEnvelopes: { number } = {}
    local deltaTimes: { number } = {}
    local deltaValues: { number } = {}
    local deltaEnvelopes: { number } = {}

    for index = 1, count do
        const fromKeypoint = from.Keypoints[index]
        const toKeypoint = to.Keypoints[index]

        fromTimes[index] = fromKeypoint.Time
        fromValues[index] = fromKeypoint.Value
        fromEnvelopes[index] = fromKeypoint.Envelope
        deltaTimes[index] = toKeypoint.Time - fromKeypoint.Time
        deltaValues[index] = toKeypoint.Value - fromKeypoint.Value
        deltaEnvelopes[index] = toKeypoint.Envelope - fromKeypoint.Envelope
    end

    return function(alpha: number): any
        local times: { number } = {}

        for index = 1, count do
            times[index] = fromTimes[index] + deltaTimes[index] * alpha
        end

        fixTimes(times)

        local keypoints: { NumberSequenceKeypoint } = {}

        for index = 1, count do
            const value = fromValues[index] + deltaValues[index] * alpha
            const envelope = fromEnvelopes[index] + deltaEnvelopes[index] * alpha

            keypoints[index] = NumberSequenceKeypoint.new(times[index], value, math.max(0, envelope))
        end

        return NumberSequence.new(keypoints)
    end
end

const function makeColorSequence(from: ColorSequence, to: ColorSequence): (number) -> any
    const count = #from.Keypoints
    local fromTimes: { number } = {}
    local deltaTimes: { number } = {}
    local colors: { (number) -> Color3 } = {}

    for index = 1, count do
        const fromKeypoint = from.Keypoints[index]
        const toKeypoint = to.Keypoints[index]

        fromTimes[index] = fromKeypoint.Time
        deltaTimes[index] = toKeypoint.Time - fromKeypoint.Time
        colors[index] = Color.make(fromKeypoint.Value, toKeypoint.Value)
    end

    return function(alpha: number): any
        local times: { number } = {}

        for index = 1, count do
            times[index] = fromTimes[index] + deltaTimes[index] * alpha
        end

        fixTimes(times)

        local keypoints: { ColorSequenceKeypoint } = {}

        for index = 1, count do
            keypoints[index] = ColorSequenceKeypoint.new(times[index], colors[index](alpha))
        end

        return ColorSequence.new(keypoints)
    end
end

-- Returns a function that blends from one value to the other for an eased progress.
const function make(from: unknown, to: unknown): (number) -> any
    if typeof(from) == "NumberRange" then
        return makeRange(from :: NumberRange, to :: NumberRange)
    end

    if typeof(from) == "NumberSequence" then
        return makeNumberSequence(from :: NumberSequence, to :: NumberSequence)
    end

    return makeColorSequence(from :: ColorSequence, to :: ColorSequence)
end

return table.freeze({
    canTween = canTween,
    make = make,
})
