const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const function createHandler(name: string)
    return VideState.rule({
        opacity = VideState.float(),
    }, { name = name }).new({
        Idle = { opacity = Vide.source(0) },
        Active = { opacity = Vide.source(1) },
    }, "Idle")
end

describe("manual clock", function()
    it("holds every transition until the clock is advanced", function()
        VideState.setManualClock(true)

        local handler = createHandler("ClockHoldPanel")
        local values: { number } = {}

        handler.onTransition(function(_, _, current)
            table.insert(values, current.opacity)
        end, {
            tweenDefault = {
                duration = 1,
            },
        })

        handler.setState("Active")

        -- Real frames pass, but the manual clock does not move the transition.
        task.wait(0.1)

        expect(#values).toBe(1)
        expect(values[1]).toBe(0)

        VideState.advanceClock(0.25)
        expect(values[#values]).toBe(0.25)

        VideState.advanceClock(0.5)
        expect(values[#values]).toBe(0.75)

        VideState.advanceClock(0.25)
        expect(values[#values]).toBe(1)

        VideState.setManualClock(false)
    end)

    it("applies the easing, the speed, and pause to the time it advances", function()
        VideState.setManualClock(true)

        local handler = createHandler("ClockScalePanel")
        local last = -1

        handler.onTransition(function(_, _, current)
            last = current.opacity
        end, {
            tweenDefault = {
                duration = 1,
                easing = "quadIn",
            },
        })

        handler.setState("Active")
        VideState.advanceClock(0.5)
        expect(last).toBe(0.25)

        handler.pause()
        VideState.advanceClock(0.4)
        expect(last).toBe(0.25)

        handler.resume()
        handler.scaleSpeed({ speed = 2 })
        VideState.advanceClock(0.25)
        expect(last).toBe(1)

        VideState.setManualClock(false)
    end)

    it("fires onFinish when the clock reaches the end", function()
        VideState.setManualClock(true)

        local handler = createHandler("ClockFinishPanel")
        local finishes = 0

        handler.onTransition(function() end, {
            tweenDefault = {
                duration = 0.5,
            },
        })
        handler.onFinish(function()
            finishes += 1
        end)

        handler.setState("Active")
        VideState.advanceClock(0.4)
        expect(finishes).toBe(0)

        VideState.advanceClock(0.2)
        expect(finishes).toBe(1)

        VideState.setManualClock(false)
    end)

    it("hands the running transitions back to the real clock", function()
        VideState.setManualClock(true)

        local handler = createHandler("ClockRealPanel")
        local last = -1

        handler.onTransition(function(_, _, current)
            last = current.opacity
        end, {
            tweenDefault = {
                duration = 0.2,
            },
        })

        handler.setState("Active")
        VideState.setManualClock(false)
        expect(VideState.isManualClock()).toBe(false)

        task.wait(0.5)

        expect(last).toBe(1)
    end)

    it("rejects bad arguments and an advance without the manual clock", function()
        expect(function()
            VideState.advanceClock(0.1)
        end).toThrow("needs the manual clock")
        expect(function()
            VideState.setManualClock("yes" :: any)
        end).toThrow("boolean")

        VideState.setManualClock(true)

        expect(function()
            VideState.advanceClock(-1)
        end).toThrow("finite non-negative")
        expect(function()
            VideState.advanceClock(math.huge)
        end).toThrow("finite non-negative")

        VideState.setManualClock(false)
    end)
end)

return nil
