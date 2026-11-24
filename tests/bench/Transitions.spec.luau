const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

-- How many handlers run a transition at the same time in each round.
const COUNTS = {
    1000,
    5000,
    10000,
}

-- How long each round samples the frames, in seconds. It is shorter than the transition, so every sample
-- is taken while all of them run.
const SAMPLE_TIME = 0.8
const DURATION = 1

-- Starts `count` handlers with one connection each, and measures the start and the frames while they animate.
const function measure(count: number): (number, number, number)
    local rule = VideState.rule({
        opacity = VideState.float(),
        size = VideState.udim2(),
    }, {
        name = `Bench{count}`,
    })

    local handlers = {}
    local received = 0

    for _ = 1, count do
        local handler = rule.new({
            Idle = {
                opacity = Vide.source(0),
                size = Vide.source(UDim2.fromScale(0, 0)),
            },
            Active = {
                opacity = Vide.source(1),
                size = Vide.source(UDim2.fromScale(1, 1)),
            },
        }, "Idle", {
            onTransition = {
                duration = DURATION,
            },
        })

        handler.onTransition(function()
            received += 1
        end)

        table.insert(handlers, handler)
    end

    local startBegin = os.clock()

    for _, handler in handlers do
        handler.setState("Active")
    end

    local startTime = (os.clock() - startBegin) * 1000
    local frames: { number } = {}
    local sampleBegin = os.clock()
    local last = sampleBegin

    while os.clock() - sampleBegin < SAMPLE_TIME do
        task.wait()

        local now = os.clock()

        table.insert(frames, (now - last) * 1000)
        last = now
    end

    local total = 0
    local worst = 0

    for _, frame in frames do
        total += frame
        worst = math.max(worst, frame)
    end

    for _, handler in handlers do
        handler.destroy()
    end

    expect(received > count).toBe(true)

    return startTime, total / #frames, worst
end

describe("transition benchmark", function()
    it("measures many handlers transitioning at once", function()
        -- One idle round first, so the first measured round does not pay for warming up.
        measure(100)

        for _, count in COUNTS do
            local startTime, averageFrame, worstFrame = measure(count)

            print(
                string.format(
                    "[bench] %d handlers: setState %.1f ms, average frame %.2f ms, worst frame %.2f ms",
                    count,
                    startTime,
                    averageFrame,
                    worstFrame
                )
            )
        end
    end)
end)
