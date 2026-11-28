const Types = require("../../../Types")

-- The easings that a game makes itself, with `VideState.bezier` and `VideState.easing`. A custom easing is a frozen
-- table, and only the tables made here are accepted, so a setting cannot hold a function that was never checked.
const custom: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any

const function isFiniteNumber(value: unknown): boolean
    if type(value) ~= "number" then
        return false
    end

    local isNotNaN = value == value
    local isNotInfinite = math.abs(value) ~= math.huge

    return isNotNaN and isNotInfinite
end

const function make(fn: (number) -> number): Types.CustomEasing
    const easing = table.freeze({
        fn = fn,
    })

    custom[easing] = true

    return easing :: any
end

const function isCustom(value: unknown): boolean
    return custom[value] == true
end

-- A cubic bezier like CSS `cubic-bezier(x1, y1, x2, y2)`. The curve starts at (0, 0) and ends at (1, 1), and the
-- horizontal controls must stay inside 0 to 1, so every progress has exactly one eased value. The vertical controls
-- can leave 0 to 1, which overshoots like the `back` easings.
const function bezier(x1: number, y1: number, x2: number, y2: number): Types.CustomEasing
    local areFinite = isFiniteNumber(x1) and isFiniteNumber(y1) and isFiniteNumber(x2) and isFiniteNumber(y2)

    if not areFinite then
        error("bezier expects four finite numbers", 2)
    end

    local isX1InRange = x1 >= 0 and x1 <= 1
    local isX2InRange = x2 >= 0 and x2 <= 1

    if not (isX1InRange and isX2InRange) then
        error("bezier x1 and x2 must be between 0 and 1", 2)
    end

    const cx = 3 * x1
    const bx = 3 * (x2 - x1) - cx
    const ax = 1 - cx - bx
    const cy = 3 * y1
    const by = 3 * (y2 - y1) - cy
    const ay = 1 - cy - by

    const function sampleX(t: number): number
        return ((ax * t + bx) * t + cx) * t
    end

    const function sampleY(t: number): number
        return ((ay * t + by) * t + cy) * t
    end

    const function slopeX(t: number): number
        return (3 * ax * t + 2 * bx) * t + cx
    end

    -- Finds the t whose x is the progress. Newton's method is fast, and bisection covers a flat slope.
    const function solve(x: number): number
        local t = x

        for _ = 1, 8 do
            const offset = sampleX(t) - x

            if math.abs(offset) < 1e-6 then
                return t
            end

            const slope = slopeX(t)

            if math.abs(slope) < 1e-6 then
                break
            end

            t -= offset / slope
        end

        local low = 0
        local high = 1

        t = x

        for _ = 1, 24 do
            const offset = sampleX(t) - x

            if math.abs(offset) < 1e-6 then
                return t
            end

            if offset > 0 then
                high = t
            else
                low = t
            end

            t = (low + high) / 2
        end

        return t
    end

    return make(function(progress: number): number
        if progress <= 0 then
            return 0
        end

        if progress >= 1 then
            return 1
        end

        return sampleY(solve(progress))
    end)
end

-- The last bounce of a spring is about this fraction of the first, so every bounce can be seen.
const LAST_BOUNCE = 0.15

-- The highest first bounce a spring can have, as a fraction past the target.
const MAX_HEIGHT = 0.5

-- The most bounces a spring can have.
const MAX_BOUNCES = 10

const DEFAULT_HEIGHT = 0.15
const DEFAULT_BOUNCES = 2

const SPRING_KEYS: { [string]: boolean } = {
    height = true,
    bounces = true,
}

-- A smooth curve through the points that never turns around between two points that rise (Fritsch and Butland).
-- `evaluate` reads it, and `startSlope` is its slope at the first point.
type MonotoneCurve = {
    evaluate: (x: number) -> number,
    startSlope: number,
}

-- The slope at an end point from the three nearest points, kept in the direction of the curve.
const function endSlope(h0: number, h1: number, d0: number, d1: number): number
    const slope = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1)
    const isSameDirection = slope * d0 > 0

    if not isSameDirection then
        return 0
    end

    const turns = d0 * d1 <= 0
    const isSteep = math.abs(slope) > 3 * math.abs(d0)

    if turns and isSteep then
        return 3 * d0
    end

    return slope
end

-- Needs at least three points, with `xs` rising.
const function monotoneCurve(xs: { number }, ys: { number }): MonotoneCurve
    const count = #xs
    const widths: { number } = {}
    const secants: { number } = {}
    const slopes: { number } = {}

    for index = 1, count - 1 do
        widths[index] = xs[index + 1] - xs[index]
        secants[index] = (ys[index + 1] - ys[index]) / widths[index]
    end

    for index = 2, count - 1 do
        const before = secants[index - 1]
        const after = secants[index]
        const turns = before * after <= 0

        if turns then
            slopes[index] = 0

            continue
        end

        const weightBefore = 2 * widths[index] + widths[index - 1]
        const weightAfter = widths[index] + 2 * widths[index - 1]

        slopes[index] = (weightBefore + weightAfter) / (weightBefore / before + weightAfter / after)
    end

    slopes[1] = endSlope(widths[1], widths[2], secants[1], secants[2])
    slopes[count] = endSlope(widths[count - 1], widths[count - 2], secants[count - 1], secants[count - 2])

    const function evaluate(x: number): number
        local segment = count - 1

        for index = 1, count - 1 do
            if x < xs[index + 1] then
                segment = index

                break
            end
        end

        const width = widths[segment]
        const along = (x - xs[segment]) / width
        const rest = 1 - along
        const startWeight = (1 + 2 * along) * rest * rest
        const startSlopeWeight = along * rest * rest
        const endWeight = along * along * (3 - 2 * along)
        const endSlopeWeight = along * along * (along - 1)

        return startWeight * ys[segment]
            + startSlopeWeight * width * slopes[segment]
            + endWeight * ys[segment + 1]
            + endSlopeWeight * width * slopes[segment + 1]
    end

    return {
        evaluate = evaluate,
        startSlope = slopes[1],
    }
end

-- The curve of a spring with `bounces` bounces. The wobble is a cosine that fits `bounces` bounces in the duration.
-- Its size starts at 1 and falls to `firstDecay` worth of decay at the first bounce, and then by the same amount for
-- every bounce after it, so each bounce is lower than the last. It reaches 0 at the end, so the curve ends on 1.
const function buildSpring(firstDecay: number, bounces: number): (number) -> number
    const lastRatio = LAST_BOUNCE ^ (1 / math.max(bounces - 1, 1))
    const step = -math.log(lastRatio)
    const times: { number } = {
        0,
    }
    const decays: { number } = {
        0,
    }

    for bounce = 1, bounces do
        table.insert(times, (2 * bounce - 1) / (2 * bounces))
        table.insert(decays, firstDecay + (bounce - 1) * step)
    end

    table.insert(times, 1)
    table.insert(decays, firstDecay + bounces * step)

    const decay = monotoneCurve(times, decays)
    const endSize = math.exp(-decays[#decays])
    const scale = 1 / (1 - endSize)
    const frequency = 2 * math.pi * bounces
    -- A start slope of 0 makes the curve start without a jump, like a spring that is let go.
    const sineWeight = decay.startSlope * scale / frequency

    return function(progress: number): number
        if progress <= 0 then
            return 0
        end

        if progress >= 1 then
            return 1
        end

        const size = (math.exp(-decay.evaluate(progress)) - endSize) * scale
        const angle = frequency * progress

        return 1 - size * (math.cos(angle) + sineWeight * math.sin(angle))
    end
end

-- How far the first bounce of the curve passes 1.
const function firstPeak(curve: (number) -> number, bounces: number): number
    const golden = (math.sqrt(5) - 1) / 2
    local low = 0
    local high = 1 / bounces
    local left = high - golden * (high - low)
    local right = low + golden * (high - low)

    for _ = 1, 45 do
        if curve(left) > curve(right) then
            high = right
        else
            low = left
        end

        left = high - golden * (high - low)
        right = low + golden * (high - low)
    end

    return curve((low + high) / 2) - 1
end

-- The decay that gives the first bounce its height. A faster decay lowers the bounce, so bisection finds it. The
-- answers are kept, because a game makes the same few springs again and again.
const solved: { [string]: number } = {}

const function solveDecay(height: number, bounces: number): number
    const key = `{height}:{bounces}`
    const known = solved[key]

    if known ~= nil then
        return known
    end

    local low = 0.01
    local high = 40

    for _ = 1, 50 do
        const middle = (low + high) / 2
        const peak = firstPeak(buildSpring(middle, bounces), bounces)

        if peak > height then
            low = middle
        else
            high = middle
        end
    end

    const decay = (low + high) / 2

    solved[key] = decay

    return decay
end

-- Reads the options of `spring`. The error level of 3 points at the user's call.
const function readSpringOptions(options: unknown): (number, number)
    if options == nil then
        return DEFAULT_HEIGHT, DEFAULT_BOUNCES
    end

    if type(options) ~= "table" then
        error("spring options must be a table", 3)
    end

    const fields = options :: { [any]: unknown }

    for key in fields do
        local isKnownKey = SPRING_KEYS[key :: any] == true

        if not isKnownKey then
            error(`spring options has an unknown key {tostring(key)}`, 3)
        end
    end

    const height = fields.height
    const bounces = fields.bounces
    local heightValue = DEFAULT_HEIGHT
    local bouncesValue = DEFAULT_BOUNCES

    if height ~= nil then
        const heightMessage = `spring height must be a number above 0 and at most {MAX_HEIGHT}`

        -- The type check comes first, because the range check compares the value as a number.
        if type(height) ~= "number" then
            error(heightMessage, 3)
        end

        local isAboveZero = height > 0
        local isAtMost = height <= MAX_HEIGHT

        if not (isAboveZero and isAtMost) then
            error(heightMessage, 3)
        end

        heightValue = height
    end

    if bounces ~= nil then
        const bouncesMessage = `spring bounces must be a whole number from 1 to {MAX_BOUNCES}`

        if type(bounces) ~= "number" then
            error(bouncesMessage, 3)
        end

        local isWhole = bounces % 1 == 0
        local isAtLeastOne = bounces >= 1
        local isAtMost = bounces <= MAX_BOUNCES

        if not (isWhole and isAtLeastOne and isAtMost) then
            error(bouncesMessage, 3)
        end

        bouncesValue = bounces
    end

    return heightValue, bouncesValue
end

-- A curve that looks like a damped spring: it starts at 0 without a jump, passes 1 by `height`, comes back and goes
-- past it again, `bounces` times, each bounce lower than the last, and ends on 1 when the duration ends. It is a
-- curve over the duration of the transition, not a simulated spring: it takes no speed from an earlier transition.
const function spring(options: { height: number?, bounces: number? }?): Types.CustomEasing
    const height, bounces = readSpringOptions(options)

    return make(buildSpring(solveDecay(height, bounces), bounces))
end

-- Wraps a function of the progress from 0 to 1 that returns the eased progress. It is called with 0 and 1 once, to
-- check that it returns finite numbers. It can overshoot, and it should return 0 at 0 and 1 at 1.
const function fromFunction(fn: (number) -> number): Types.CustomEasing
    if type(fn) ~= "function" then
        error(`easing expects a function, got {typeof(fn)}`, 2)
    end

    const ok, first = pcall(fn, 0)
    const okEnd, last = pcall(fn, 1)
    local areNumbers = ok and okEnd and isFiniteNumber(first) and isFiniteNumber(last)

    if not areNumbers then
        error("easing must return a finite number for a progress of 0 and 1", 2)
    end

    -- A bad value in the middle of a transition ends it with the error, so the result is checked as it is used.
    return make(function(progress: number): number
        const eased = fn(progress)

        if not isFiniteNumber(eased) then
            error("a custom easing returned a value that is not a finite number", 0)
        end

        return eased
    end)
end

return table.freeze({
    bezier = bezier,
    spring = spring,
    fromFunction = fromFunction,
    isCustom = isCustom,
})
