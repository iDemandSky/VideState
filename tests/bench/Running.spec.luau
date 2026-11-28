const Lest = require("@Lest")
const Operations = require("./Operations")
const VideState = require("@VideState")

local describe, it = Lest.describe, Lest.it

const GROUP = "running"
const COUNT = 1000
const NAMES = { "A", "B" }

-- Changes every handler to the other state on each pass, so `setState` never meets the state that is active.
const function flip(handlers: { any }, name: string, work: (handler: any, target: string) -> ())
    local turn = 0

    Operations.measure(GROUP, name, COUNT, function(index)
        turn += 1

        -- Every pass over the handlers uses the other state than the pass before.
        work(handlers[index], NAMES[((turn - 1) // COUNT) % 2 + 1])
    end)
end

describe("running benchmark", function()
    it("measures setState with different connections", function()
        local rule = Operations.createRule()

        const function measureSetState(name: string, connect: (handler: any) -> (), options: any?)
            local handlers = Operations.createHandlers(rule, COUNT, connect)

            flip(handlers, name, function(handler, target)
                handler.setState(target, options)
            end)
            Operations.destroyAll(handlers)
        end

        measureSetState("setState, nothing connected", function() end)
        measureSetState("setState, one onChange", function(handler)
            handler.onChange(function() end)
        end)
        measureSetState("setState, one onEnter and one onExit", function(handler)
            handler.onEnter("A", function() end)
            handler.onExit("A", function() end)
        end)
        measureSetState("setState, one onTransition", function(handler)
            handler.onTransition(function() end, { tweenDefault = { duration = 1 } })
        end)
        measureSetState("setState, one animate", function(handler)
            handler.animate({ tweenDefault = { duration = 1 } })
        end)
        measureSetState("setState, one progress", function(handler)
            handler.progress({ tweenDefault = { duration = 1 } })
        end)
        measureSetState("setState, one animate with a spring", function(handler)
            handler.animate({
                tweenDefault = { duration = 1, easing = VideState.spring({ height = 0.2, bounces = 3 }) },
            })
        end)
        measureSetState("setState, three animate connections", function(handler)
            for _ = 1, 3 do
                handler.animate({ tweenDefault = { duration = 1 } })
            end
        end)
        measureSetState("setState instant, one animate", function(handler)
            handler.animate({ tweenDefault = { duration = 1 } })
        end, { instant = true })
        measureSetState("setState with a delay, one animate", function(handler)
            handler.animate({ tweenDefault = { duration = 1 } })
        end, { delay = 0.5 })
    end)

    it("measures the controls", function()
        local rule = Operations.createRule()
        local handlers = Operations.createHandlers(rule, COUNT, function(handler)
            handler.animate({ tweenDefault = { duration = 100 } })
            handler.setState("A")
        end)

        Operations.measure(GROUP, "pause and resume, while running", COUNT, function(index)
            handlers[index].pause()
            handlers[index].resume()
        end)
        Operations.measure(GROUP, "scaleSpeed, while running", COUNT, function(index)
            handlers[index].scaleSpeed({ speed = 2, once = true })
        end)
        Operations.measure(GROUP, "finish, while running", COUNT, function(index)
            handlers[index].finish()
        end)
        Operations.measure(GROUP, "playSequence of 3 steps, start and stop", COUNT, function(index)
            local _, stop = handlers[index].playSequence({
                { state = "A", instant = true },
                { state = "B", instant = true },
                { state = "C", instant = true },
            })

            stop()
        end)
        Operations.destroyAll(handlers)
    end)

    it("measures everyHandler", function()
        local ruleName = Operations.uniqueName("BenchEvery")
        local rule = Operations.createRule(ruleName)
        local handlers = Operations.createHandlers(rule, COUNT, function(handler)
            handler.animate({ tweenDefault = { duration = 100 } })
        end)
        local turn = 0
        local group = VideState.everyHandler.withRule(ruleName)

        Operations.measure(GROUP, "everyHandler.setState on 1000 handlers, per call", 10, function()
            turn += 1

            group.setState(NAMES[turn % 2 + 1])
        end)
        Operations.measure(GROUP, "everyHandler.setState with stagger on 1000 handlers, per call", 10, function()
            turn += 1

            group.setState(NAMES[turn % 2 + 1], { stagger = 0.01 })
        end)
        Operations.measure(GROUP, "everyHandler.count with a filter, per call", 100, function()
            group.count()
        end)
        Operations.destroyAll(handlers)
    end)

    it("measures one frame of the shared loop", function()
        VideState.setManualClock(true)

        for _, connections in { 1, 3 } do
            local rule = Operations.createRule()
            local handlers = Operations.createHandlers(rule, COUNT, function(handler)
                for _ = 1, connections do
                    handler.animate({ tweenDefault = { duration = 1000 } })
                end
            end)

            for _, handler in handlers do
                handler.setState("A")
            end

            Operations.measure(
                GROUP,
                `one frame of 1000 handlers, {connections} animate connection each`,
                20,
                function()
                    VideState.advanceClock(1 / 60)
                end
            )
            Operations.destroyAll(handlers)
        end

        VideState.setManualClock(false)
    end)
end)
