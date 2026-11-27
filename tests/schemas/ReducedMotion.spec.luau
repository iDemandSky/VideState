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

describe("reduced motion", function()
    it("is off by default and can be turned on and off", function()
        expect(VideState.isReducedMotion()).toBe(false)

        VideState.setReducedMotion(true)
        expect(VideState.isReducedMotion()).toBe(true)

        VideState.setReducedMotion(false)
        expect(VideState.isReducedMotion()).toBe(false)
    end)

    it("plays every state change as one frame with an alpha of 1", function()
        local handler = createHandler("ReducedMotionPanel")
        local alphas: { number } = {}
        local finishes = 0

        handler.onTransition(function(_, _, _, alpha)
            table.insert(alphas, alpha)
        end, {
            tweenDefault = {
                duration = 5,
            },
        })
        handler.onFinish(function()
            finishes += 1
        end)

        VideState.setReducedMotion(true)
        handler.setState("Active")
        VideState.setReducedMotion(false)

        expect(#alphas).toBe(1)
        expect(alphas[1]).toBe(1)
        expect(finishes).toBe(1)
    end)

    it("does not change a transition that already started", function()
        local handler = createHandler("ReducedMotionRunningPanel")
        local alphas: { number } = {}

        handler.onTransition(function(_, _, _, alpha)
            table.insert(alphas, alpha)
        end, {
            tweenDefault = {
                duration = 5,
            },
        })

        handler.setState("Active")
        VideState.setReducedMotion(true)

        task.wait(0.1)

        VideState.setReducedMotion(false)
        handler.finish()

        -- The first frame was sent at the start, and the transition kept playing until finish.
        expect(alphas[1] < 1).toBe(true)
    end)

    it("rejects a value that is not a boolean", function()
        expect(function()
            VideState.setReducedMotion("yes" :: any)
        end).toThrow("boolean")
    end)
end)

return nil
