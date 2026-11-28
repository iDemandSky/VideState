const Vide = require("@packages/Vide")
const Operations = require("./Operations")
const VideState = require("@VideState")

-- What each round connects to every handler:
--   onTransition  one `onTransition` connection with a callback
--   animate       one `animate` connection, which writes a Vide source for every field
--   overrides     the same `animate`, with six `tweenOverrides` entries. The entry for the state change is the
--                 last one, so the lookup scans the whole list, which is its slowest case.
export type Mode = "onTransition" | "animate" | "overrides"

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

const STATE_NAMES = {
    "Idle",
    "A",
    "B",
    "C",
}

const function createStates()
    local states = {}

    for index, name in STATE_NAMES do
        states[name] = {
            opacity = Vide.source(index - 1),
            size = Vide.source(UDim2.fromScale(index - 1, index - 1)),
        }
    end

    return states
end

const function override(from: string, to: string): VideState.TweenOverride
    return {
        from = {
            from,
        },
        to = {
            to,
        },
        tween = {
            duration = DURATION,
        },
    }
end

-- The default is far longer than the sample, so a source that has moved proves that the override was used.
const function overrideOptions(): VideState.TransitionOptions
    return {
        tweenDefault = {
            duration = 100,
        },
        tweenOverrides = {
            override("B", "C"),
            override("C", "B"),
            override("B", "A"),
            override("A", "B"),
            override("A", "Idle"),
            override("Idle", "A"),
        },
    }
end

const function animateOptions(): VideState.TransitionOptions
    return {
        tweenDefault = {
            duration = DURATION,
        },
    }
end

type Round = {
    connectTime: number,
    startTime: number,
    averageFrame: number,
    worstFrame: number,
}

-- Creates `count` handlers with one connection each, and measures the start and the frames while they animate.
const function measure(mode: Mode, count: number): Round
    local rule = VideState.rule({
        opacity = VideState.float(),
        size = VideState.udim2(),
    }, {
        name = `Bench{mode}{count}`,
    })

    local handlers = {}
    local followers = {}
    local received = 0
    local connectBegin = os.clock()

    for _ = 1, count do
        local handler = rule.new(createStates(), "Idle")

        if mode == "onTransition" then
            handler.onTransition(function()
                received += 1
            end, animateOptions())
        elseif mode == "animate" then
            local animated = handler.animate(animateOptions())

            table.insert(followers, animated.opacity)
        else
            local animated = handler.animate(overrideOptions())

            table.insert(followers, animated.opacity)
        end

        table.insert(handlers, handler)
    end

    local connectTime = (os.clock() - connectBegin) * 1000
    local startBegin = os.clock()

    for _, handler in handlers do
        handler.setState("A")
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

    -- A round is only worth reading if the transitions really ran with the settings that were asked for.
    if mode == "onTransition" then
        assert(received > count, "the transitions did not run")
    else
        local moved = followers[1]()

        assert(moved > 0.3, `the first source only moved to {moved}, so the transition did not use a 1 second duration`)
    end

    for _, handler in handlers do
        handler.destroy()
    end

    return {
        connectTime = connectTime,
        startTime = startTime,
        averageFrame = total / #frames,
        worstFrame = worst,
    }
end

-- Runs every round for one mode and prints a `[bench]` line for each.
const function run(mode: Mode)
    -- Garbage that an earlier suite left behind would slow the frames, so wait until the collector has freed it.
    Operations.memoryNow()

    -- One idle round first, so the first measured round does not pay for warming up.
    measure(mode, 100)

    for _, count in COUNTS do
        local round = measure(mode, count)

        print(
            string.format(
                "[bench] %s, %d handlers: connect %.1f ms, setState %.1f ms, average frame %.2f ms, worst frame %.2f ms",
                mode,
                count,
                round.connectTime,
                round.startTime,
                round.averageFrame,
                round.worstFrame
            )
        )
    end
end

return table.freeze({
    run = run,
})
