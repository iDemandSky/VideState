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

-- How fast the wobble of a spring dies out, so it has faded to about a third of a percent when the transition ends.
const SPRING_DECAY = 8

-- The default bounce of `VideState.spring`.
const DEFAULT_BOUNCE = 0.3

-- The least damping ratio a spring gets. A bounce of 1 is this, so the curve still settles inside its duration.
const LEAST_DAMPING = 0.2

-- A curve that looks like a damped spring: it starts at 0, passes 1, wobbles around it, and has settled at 1 by the
-- end. It is a curve over the duration of the transition, not a simulated spring: it takes no speed from an earlier
-- transition, and it always ends when the duration does. `bounce` goes from 0, which settles smoothly without passing
-- 1, to 1, which wobbles the most.
const function spring(bounce: number?): Types.CustomEasing
    local amount = DEFAULT_BOUNCE

    if bounce ~= nil then
        local isNumber = type(bounce) == "number"
        local isInRange = isNumber and bounce >= 0 and bounce <= 1

        if not isInRange then
            error("spring bounce must be a number from 0 to 1", 2)
        end

        amount = bounce :: number
    end

    const decay = SPRING_DECAY

    -- A bounce of 0 is critically damped, which has no wobble.
    if amount == 0 then
        return make(function(progress: number): number
            if progress <= 0 then
                return 0
            end

            if progress >= 1 then
                return 1
            end

            return 1 - (1 + decay * progress) * math.exp(-decay * progress)
        end)
    end

    -- The damping ratio goes down as the bounce goes up. The decay is fixed, so the frequency follows from the ratio.
    const damping = 1 - (1 - LEAST_DAMPING) * amount
    const frequency = decay * math.sqrt(1 - damping * damping) / damping
    const ratio = decay / frequency

    return make(function(progress: number): number
        if progress <= 0 then
            return 0
        end

        if progress >= 1 then
            return 1
        end

        const angle = frequency * progress

        return 1 - math.exp(-decay * progress) * (math.cos(angle) + ratio * math.sin(angle))
    end)
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
