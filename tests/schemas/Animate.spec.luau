const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

-- A long transition, so a test can read values while it is still running.
const SLOW = {
    tweenDefault = {
        duration = 3,
    },
}

const function createHandler(name: string)
    return VideState.rule({
        opacity = VideState.float(),
        label = VideState.string(),
    }, { name = name }).new({
        Idle = {
            opacity = Vide.source(0),
            label = Vide.source("Idle"),
        },
        Active = {
            opacity = Vide.source(1),
            label = Vide.source("Active"),
        },
    }, "Idle")
end

describe("animate", function()
    it("returns sources that start at the current state and follow the transition", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
            opacity = VideState.float(),
        }, { name = "AnimatePanel" }).new({
            Idle = {
                visible = Vide.source(false),
                opacity = Vide.source(0),
            },
            Active = {
                visible = Vide.source(true),
                opacity = Vide.source(1),
            },
        }, "Idle")

        local animated, disconnect = handler.animate({
            tweenDefault = {
                duration = 0.05,
            },
        })

        expect(animated.opacity()).toBe(0)
        expect(animated.visible()).toBe(false)

        handler.setState("Active")
        task.wait(0.2)

        expect(animated.opacity()).toBe(1)
        expect(animated.visible()).toBe(true)

        disconnect()
        handler.setState("Idle")
        task.wait(0.1)

        expect(animated.opacity()).toBe(1)
    end)

    it("moves through the values between the states", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "AnimateMidPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle")

        local animated = handler.animate({
            tweenDefault = {
                duration = 3,
            },
        })

        handler.setState("Active")
        task.wait(0.3)

        local middle = animated.opacity()

        expect(middle > 0 and middle < 1).toBe(true)

        handler.finish()

        expect(animated.opacity()).toBe(1)
    end)

    it("uses the options it is given", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "AnimateOptionsPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle")

        local animated = handler.animate({
            tweenDefault = {
                duration = 0,
            },
        })

        handler.setState("Active")

        expect(animated.opacity()).toBe(1)
    end)

    it("rejects invalid options", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "AnimateInvalidPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle")

        expect(function()
            handler.animate({
                tweenDefault = {
                    duration = -1,
                },
            })
        end).toThrow("duration")
    end)

    it("holds the sources while paused and continues after resume", function()
        local handler = createHandler("AnimatePausePanel")
        local animated = handler.animate(SLOW)

        handler.setState("Active")
        task.wait(0.3)
        handler.pause()

        local held = animated.opacity()

        task.wait(0.3)

        expect(animated.opacity()).toBe(held)
        expect(held > 0 and held < 1).toBe(true)

        handler.resume()
        handler.finish()

        expect(animated.opacity()).toBe(1)
    end)

    it("keeps the last value after destroy and stops following", function()
        local handler = createHandler("AnimateDestroyPanel")
        local animated = handler.animate(SLOW)

        handler.setState("Active")
        task.wait(0.3)

        local beforeDestroy = animated.opacity()

        handler.destroy()
        task.wait(0.3)

        expect(animated.opacity()).toBe(beforeDestroy)
        expect(function()
            handler.setState("Idle")
        end).toThrow()
        expect(animated.opacity()).toBe(beforeDestroy)
    end)

    it("gives each call its own options and its own sources", function()
        local handler = createHandler("AnimateTwoPanel")
        local slow = handler.animate(SLOW)
        local fast = handler.animate({
            tweenDefault = {
                duration = 0,
            },
        })

        expect(slow.opacity == fast.opacity).toBe(false)

        handler.setState("Active")
        task.wait(0.3)

        expect(fast.opacity()).toBe(1)
        expect(slow.opacity() < 1).toBe(true)
    end)

    it("continues from the current value when the state changes mid-transition", function()
        local handler = createHandler("AnimateInterruptPanel")
        local animated = handler.animate(SLOW)

        handler.setState("Active")
        task.wait(0.3)

        local reached = animated.opacity()

        handler.setState("Idle")

        expect(math.abs(animated.opacity() - reached) < 0.000001).toBe(true)

        handler.finish()

        expect(animated.opacity()).toBe(0)
    end)

    it("jumps to the next values for an instant state change", function()
        local handler = createHandler("AnimateInstantPanel")
        local animated = handler.animate(SLOW)

        handler.setState("Active", { instant = true })

        expect(animated.opacity()).toBe(1)
        expect(animated.label()).toBe("Active")
    end)

    it("switches fields that cannot be tweened at the start", function()
        local handler = createHandler("AnimateStringPanel")
        local animated = handler.animate(SLOW)

        expect(animated.label()).toBe("Idle")

        handler.setState("Active")

        expect(animated.label()).toBe("Active")
        expect(animated.opacity() < 1).toBe(true)
    end)

    it("starts from the current state, not the initial one", function()
        local handler = createHandler("AnimateLateCallPanel")

        handler.setState("Active")

        local animated = handler.animate(SLOW)

        expect(animated.opacity()).toBe(1)
        expect(animated.label()).toBe("Active")
    end)

    it("leaves the handler sources alone", function()
        local handler = createHandler("AnimateSeparatePanel")
        local animated = handler.animate(SLOW)

        animated.opacity(0.5)

        expect(handler.sources.opacity()).toBe(0)

        handler.setState("Active")

        expect(handler.sources.opacity()).toBe(1)
        expect(animated.opacity() < 1).toBe(true)
    end)

    it("follows scaleSpeed like any other connection", function()
        local handler = createHandler("AnimateScalePanel")
        local animated = handler.animate(SLOW)

        handler.setState("Active")
        handler.scaleSpeed({ speed = 100 })
        task.wait(0.2)

        expect(animated.opacity()).toBe(1)
    end)
end)
