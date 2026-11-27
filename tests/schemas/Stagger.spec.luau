const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const function createRule(name: string)
    return VideState.rule({
        opacity = VideState.float(),
    }, { name = name, tags = { "StaggerTag" } })
end

const function createStates()
    return {
        Idle = { opacity = Vide.source(0) },
        Active = { opacity = Vide.source(1) },
    }
end

describe("stagger", function()
    it("waits for the delay of setState before the first frame", function()
        local handler = createRule("SetStateDelayPanel").new(createStates(), "Idle")
        local frames = 0

        handler.onTransition(function()
            frames += 1
        end, {
            tweenDefault = {
                duration = 0.1,
            },
        })

        handler.setState("Active", { delay = 0.3 })

        expect(frames).toBe(0)

        task.wait(0.6)

        expect(frames > 0).toBe(true)
        expect(handler.sources.opacity()).toBe(1)
    end)

    it("ignores the delay of an instant setState", function()
        local handler = createRule("InstantDelayPanel").new(createStates(), "Idle")
        local frames = 0

        handler.onTransition(function()
            frames += 1
        end)

        handler.setState("Active", { instant = true, delay = 5 })

        expect(frames).toBe(1)
    end)

    it("rejects a delay that is not a finite non-negative number", function()
        local handler = createRule("BadDelayPanel").new(createStates(), "Idle")

        expect(function()
            handler.setState("Active", { delay = -1 })
        end).toThrow("setState delay must be a finite non-negative number")
        expect(function()
            handler.setState("Active", { delay = "1" :: any })
        end).toThrow("setState delay must be a finite non-negative number")
        expect(function()
            handler.setState("Active", { stagger = 1 } :: any)
        end).toThrow("unknown key stagger")
    end)

    it("starts each handler later than the one created before it", function()
        local rule = createRule("StaggerOrderPanel")
        local startedAt: { number } = {}

        for index = 1, 3 do
            local handler = rule.new(createStates(), "Idle")

            handler.onTransition(function()
                if startedAt[index] == nil then
                    startedAt[index] = os.clock()
                end
            end, {
                tweenDefault = {
                    duration = 0.05,
                },
            })
        end

        local before = os.clock()

        VideState.everyHandler.withRule("StaggerOrderPanel").setState("Active", { stagger = 0.25 })

        -- The first handler waits 0, so it sends its first frame at once.
        expect(startedAt[1] ~= nil).toBe(true)
        expect(startedAt[2]).toBe(nil)

        task.wait(0.9)

        expect(startedAt[2] - before >= 0.2).toBe(true)
        expect(startedAt[3] - before >= 0.45).toBe(true)
        expect(startedAt[3] > startedAt[2]).toBe(true)
    end)

    it("adds the stagger to the delay", function()
        local rule = createRule("StaggerDelayPanel")
        local first = rule.new(createStates(), "Idle")
        local second = rule.new(createStates(), "Idle")
        local firstFrames = 0
        local secondFrames = 0

        first.onTransition(function()
            firstFrames += 1
        end)
        second.onTransition(function()
            secondFrames += 1
        end)

        VideState.everyHandler.withRule("StaggerDelayPanel").setState("Active", { delay = 0.2, stagger = 0.3 })

        expect(firstFrames).toBe(0)

        task.wait(0.35)

        expect(firstFrames > 0).toBe(true)
        expect(secondFrames).toBe(0)

        task.wait(0.4)

        expect(secondFrames > 0).toBe(true)
    end)

    it("rejects a stagger that is not a finite non-negative number", function()
        createRule("BadStaggerPanel").new(createStates(), "Idle")

        expect(function()
            VideState.everyHandler.withRule("BadStaggerPanel").setState("Active", { stagger = -0.1 })
        end).toThrow("everyHandler.setState stagger must be a finite non-negative number")
        expect(function()
            VideState.everyHandler.withRule("BadStaggerPanel").setState("Active", { stagger = 0 / 0 })
        end).toThrow("everyHandler.setState stagger must be a finite non-negative number")
    end)
end)

return nil
