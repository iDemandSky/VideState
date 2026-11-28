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

-- After its last bounce, the size of the wobble of a spring falls by this much more decay, so the curve settles on 1 in
-- the last half of a wobble. It is large enough that the last bounce is not cut short.
const END_TAPER = 6

-- The highest first bounce a spring can have, as a fraction past the target.
const MAX_HEIGHT = 0.5

-- The most bounces a spring can have.
const MAX_BOUNCES = 10

-- The longest `arrive` and `settle` a spring can have, as fractions of the duration, and how much of the duration
-- the two can take together. The rest is left for the bounces.
const MAX_ARRIVE = 0.8
const MAX_SETTLE = 0.8
const MAX_ARRIVE_AND_SETTLE = 0.9

-- The most that each bounce can be shorter than the one before.
const MAX_TIGHTENING = 0.6

-- The deepest dip backwards before the spring moves, as a fraction of the distance.
const MAX_ANTICIPATION = 0.3

const DEFAULT_HEIGHT = 0.15
const DEFAULT_BOUNCES = 2
const DEFAULT_LOSS = 0.5

const SPRING_KEYS: { [string]: boolean } = {
    height = true,
    bounces = true,
    loss = true,
    arrive = true,
    settle = true,
    tightening = true,
    anticipation = true,
}

-- Everything that shapes a spring. `arrive` and `settle` are nil when the curve picks them.
type SpringShape = {
    height: number,
    bounces: number,
    loss: number,
    arrive: number?,
    settle: number?,
    tightening: number,
    anticipation: number,
}

-- A smooth curve through the points that never turns around between two points that rise (Fritsch and Butland).
-- `evaluate` reads it, and `startSlope` is its slope at the first point. With `startsFromSecant`, the slope at the
-- first point is the average slope of the first segment, which is always above 0 for a rising curve.
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
const function monotoneCurve(xs: { number }, ys: { number }, startsFromSecant: boolean): MonotoneCurve
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

    slopes[1] = if startsFromSecant then secants[1] else endSlope(widths[1], widths[2], secants[1], secants[2])
    slopes[count] = endSlope(widths[count - 1], widths[count - 2], secants[count - 1], secants[count - 2])

    const function evaluate(x: number): number
        -- The last segment that starts at or before x, found by halving.
        local low = 1
        local high = count - 1

        while low < high do
            const middle = (low + high + 1) // 2

            if x >= xs[middle] then
                low = middle
            else
                high = middle - 1
            end
        end

        const width = widths[low]
        const along = (x - xs[low]) / width
        const rest = 1 - along
        const startWeight = (1 + 2 * along) * rest * rest
        const startSlopeWeight = along * rest * rest
        const endWeight = along * along * (3 - 2 * along)
        const endSlopeWeight = along * along * (along - 1)

        return startWeight * ys[low]
            + startSlopeWeight * width * slopes[low]
            + endWeight * ys[low + 1]
            + endSlopeWeight * width * slopes[low + 1]
    end

    return {
        evaluate = evaluate,
        startSlope = slopes[1],
    }
end

-- When each quarter of a wobble ends, as fractions of the duration. A spring has four quarters for each bounce: it
-- reaches the target, reaches the top of the bounce, comes back to the target, and reaches the bottom. `arrive` is the
-- length of the first quarter, and `settle` is the length of the last two. The other quarters share the rest of the
-- time, and each bounce takes `1 - tightening` of the time of the one before. The first entry is 0, and the entry
-- after quarter `n` is `times[n + 1]`.
const function quarterTimes(bounces: number, arrive: number?, settle: number?, tightening: number): { number }
    const quarters = 4 * bounces
    const keep = 1 - tightening
    const lengths: { number } = {}
    const weights: { number } = {}
    local fixed = 0
    local weightTotal = 0

    for quarter = 1, quarters do
        const isArrival = quarter == 1 and arrive ~= nil
        const isSettle = settle ~= nil and quarter >= quarters - 1

        if isArrival then
            lengths[quarter] = arrive :: number
            fixed += arrive :: number
        elseif isSettle then
            lengths[quarter] = (settle :: number) / 2
            fixed += (settle :: number) / 2
        else
            weights[quarter] = keep ^ (math.ceil(quarter / 4) - 1)
            weightTotal += weights[quarter]
        end
    end

    const share = (1 - fixed) / weightTotal
    const times: { number } = {
        0,
    }

    for quarter = 1, quarters do
        const length = lengths[quarter] or share * weights[quarter]

        table.insert(times, times[quarter] + length)
    end

    -- Rounding must not leave the end short of the duration.
    times[quarters + 1] = 1

    return times
end

type BuiltSpring = {
    curve: (number) -> number,
    -- When the curve first reaches the target.
    arrival: number,
    -- When the first bounce is over, which is where the curve is at its lowest after the first peak.
    trough: number,
}

-- The curve of a spring. The wobble is a cosine, and the phase of the cosine is a smooth curve through the quarters, so
-- the bounces fall where `quarterTimes` puts them. The size of the wobble starts at 1, falls to `firstDecay` worth of
-- decay at the first bounce, and then by the decay of `loss` for every bounce after it, so each bounce keeps `1 - loss`
-- of the one before. It reaches 0 at the end, so the curve ends on 1. `dipSize` is how deep the dip before the move is.
const function buildSpring(shape: SpringShape, firstDecay: number, dipSize: number): BuiltSpring
    const bounces = shape.bounces
    const step = -math.log(1 - shape.loss)
    const times = quarterTimes(bounces, shape.arrive, shape.settle, shape.tightening)
    const decayTimes: { number } = {
        0,
    }
    const decays: { number } = {
        0,
    }

    for bounce = 1, bounces do
        -- The top of bounce n is the end of quarter 4n - 2.
        table.insert(decayTimes, times[4 * bounce - 1])
        table.insert(decays, firstDecay + (bounce - 1) * step)
    end

    table.insert(decayTimes, 1)
    table.insert(decays, firstDecay + (bounces - 1) * step + END_TAPER)

    const decay = monotoneCurve(decayTimes, decays, false)
    const endSize = math.exp(-decays[#decays])
    const scale = 1 / (1 - endSize)
    const phases: { number } = {}

    for quarter = 0, 4 * bounces do
        table.insert(phases, quarter * math.pi / 2)
    end

    -- The curve is on the target where cos(phase) + weight * sin(phase) is 0, and the weight depends on the phase
    -- curve, so the phase at the end of the first quarter is found by repeating the two steps.
    local phase = monotoneCurve(times, phases, true)
    local sineWeight = decay.startSlope * scale / phase.startSlope

    for _ = 1, 4 do
        phases[2] = math.pi / 2 + math.atan(sineWeight)
        phase = monotoneCurve(times, phases, true)
        sineWeight = decay.startSlope * scale / phase.startSlope
    end

    const arrival = times[2]
    const phaseAt = phase.evaluate

    return {
        curve = function(progress: number): number
            if progress <= 0 then
                return 0
            end

            if progress >= 1 then
                return 1
            end

            const size = (math.exp(-decay.evaluate(progress)) - endSize) * scale
            const angle = phaseAt(progress)
            local value = 1 - size * (math.cos(angle) + sineWeight * math.sin(angle))

            -- The dip: a smooth bump that pulls the curve below 0 before it reaches the target.
            if dipSize > 0 and progress < arrival then
                const along = math.sin(math.pi * progress / arrival)

                value -= dipSize * along * along
            end

            return value
        end,
        arrival = arrival,
        trough = times[5],
    }
end

-- How far the first bounce of the curve passes 1.
const function firstPeak(built: BuiltSpring): number
    const golden = (math.sqrt(5) - 1) / 2
    local low = 0
    local high = built.trough
    local left = high - golden * (high - low)
    local right = low + golden * (high - low)

    for _ = 1, 32 do
        if built.curve(left) > built.curve(right) then
            high = right
        else
            low = left
        end

        left = high - golden * (high - low)
        right = low + golden * (high - low)
    end

    return built.curve((low + high) / 2) - 1
end

-- The size of the dip that goes as deep as `depth` below 0. The dip is a bump that is subtracted, so the lowest point
-- is the largest value of `size * bump - curve` over the first quarter, and bisection finds the size.
const function solveDip(shape: SpringShape, firstDecay: number): number
    if shape.anticipation <= 0 then
        return 0
    end

    const built = buildSpring(shape, firstDecay, 0)
    const samples = 200
    const curveValues: { number } = {}
    const bumpValues: { number } = {}

    for sample = 1, samples do
        const progress = built.arrival * sample / samples
        const along = math.sin(math.pi * progress / built.arrival)

        table.insert(curveValues, built.curve(progress))
        table.insert(bumpValues, along * along)
    end

    local low = 0
    local high = 20

    for _ = 1, 40 do
        const middle = (low + high) / 2
        local deepest = 0

        for sample = 1, samples do
            deepest = math.max(deepest, middle * bumpValues[sample] - curveValues[sample])
        end

        if deepest < shape.anticipation then
            low = middle
        else
            high = middle
        end
    end

    return (low + high) / 2
end

type SolvedSpring = {
    firstDecay: number,
    dipSize: number,
}

-- The decay that gives the first bounce its height. A faster decay lowers the bounce, so bisection finds it. The
-- answers are kept, because a game makes the same few springs again and again.
const solved: { [string]: SolvedSpring } = {}

const function solveSpring(shape: SpringShape): SolvedSpring
    const key = `{shape.height}:{shape.bounces}:{shape.loss}:{shape.arrive}:{shape.settle}:{shape.tightening}:{shape.anticipation}`
    const known = solved[key]

    if known ~= nil then
        return known
    end

    local low = 0.01
    local high = 60

    for _ = 1, 34 do
        const middle = (low + high) / 2
        const peak = firstPeak(buildSpring(shape, middle, 0))

        if peak > shape.height then
            low = middle
        else
            high = middle
        end
    end

    const firstDecay = (low + high) / 2
    const result: SolvedSpring = {
        firstDecay = firstDecay,
        dipSize = solveDip(shape, firstDecay),
    }

    solved[key] = result

    return result
end

-- The limits of an option that is a number. A limit is only allowed as a value when its `includes` is true.
type Range = {
    minimum: number,
    includesMinimum: boolean,
    maximum: number,
    includesMaximum: boolean,
}

-- Reads one option that is a number inside a range, and returns nil when the option is left out. The error level of 4
-- points at the user's call.
const function readNumber(value: unknown, message: string, range: Range): number?
    if value == nil then
        return nil
    end

    -- The type check comes first, because the range checks compare the value as a number.
    if type(value) ~= "number" then
        error(message, 4)
    end

    const isAboveMinimum = if range.includesMinimum then value >= range.minimum else value > range.minimum
    const isBelowMaximum = if range.includesMaximum then value <= range.maximum else value < range.maximum

    if not (isAboveMinimum and isBelowMaximum) then
        error(message, 4)
    end

    return value
end

-- Reads the options of `spring`. The error level of 3 points at the user's call.
const function readSpringOptions(options: unknown): SpringShape
    if options == nil then
        return {
            height = DEFAULT_HEIGHT,
            bounces = DEFAULT_BOUNCES,
            loss = DEFAULT_LOSS,
            arrive = nil,
            settle = nil,
            tightening = 0,
            anticipation = 0,
        }
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

    const height = readNumber(fields.height, `spring height must be a number above 0 and at most {MAX_HEIGHT}`, {
        minimum = 0,
        includesMinimum = false,
        maximum = MAX_HEIGHT,
        includesMaximum = true,
    })
    -- Whole numbers only, so the bounces are read here with an extra check.
    const bouncesValue = fields.bounces
    local bounces = DEFAULT_BOUNCES

    if bouncesValue ~= nil then
        const bouncesMessage = `spring bounces must be a whole number from 1 to {MAX_BOUNCES}`

        if type(bouncesValue) ~= "number" then
            error(bouncesMessage, 3)
        end

        local isWhole = bouncesValue % 1 == 0
        local isAtLeastOne = bouncesValue >= 1
        local isAtMost = bouncesValue <= MAX_BOUNCES

        if not (isWhole and isAtLeastOne and isAtMost) then
            error(bouncesMessage, 3)
        end

        bounces = bouncesValue
    end

    const loss = readNumber(fields.loss, "spring loss must be a number above 0 and below 1", {
        minimum = 0,
        includesMinimum = false,
        maximum = 1,
        includesMaximum = false,
    })
    const arrive = readNumber(fields.arrive, `spring arrive must be a number above 0 and at most {MAX_ARRIVE}`, {
        minimum = 0,
        includesMinimum = false,
        maximum = MAX_ARRIVE,
        includesMaximum = true,
    })
    const settle = readNumber(fields.settle, `spring settle must be a number above 0 and at most {MAX_SETTLE}`, {
        minimum = 0,
        includesMinimum = false,
        maximum = MAX_SETTLE,
        includesMaximum = true,
    })
    const tightening = readNumber(fields.tightening, `spring tightening must be a number from 0 to {MAX_TIGHTENING}`, {
        minimum = 0,
        includesMinimum = true,
        maximum = MAX_TIGHTENING,
        includesMaximum = true,
    })
    const anticipation = readNumber(
        fields.anticipation,
        `spring anticipation must be a number from 0 to {MAX_ANTICIPATION}`,
        {
            minimum = 0,
            includesMinimum = true,
            maximum = MAX_ANTICIPATION,
            includesMaximum = true,
        }
    )

    if arrive ~= nil and settle ~= nil then
        const total = arrive + settle

        if total > MAX_ARRIVE_AND_SETTLE then
            error(`spring arrive and settle must add up to at most {MAX_ARRIVE_AND_SETTLE}, to leave room for the bounces`, 3)
        end
    end

    return {
        height = height or DEFAULT_HEIGHT,
        bounces = bounces,
        loss = loss or DEFAULT_LOSS,
        arrive = arrive,
        settle = settle,
        tightening = tightening or 0,
        anticipation = anticipation or 0,
    }
end

-- A curve that looks like a damped spring: it starts at 0 without a jump, reaches the target, passes it by `height`,
-- comes back and goes past it again, `bounces` times, each bounce keeping `1 - loss` of the one before, and ends on 1
-- when the duration ends. It is a curve over the duration of the transition, not a simulated spring: it takes no
-- speed from an earlier transition.
const function spring(options: {
    height: number?,
    bounces: number?,
    loss: number?,
    arrive: number?,
    settle: number?,
    tightening: number?,
    anticipation: number?,
}?): Types.CustomEasing
    const shape = readSpringOptions(options)
    const solution = solveSpring(shape)

    return make(buildSpring(shape, solution.firstDecay, solution.dipSize).curve)
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
