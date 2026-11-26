const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

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

        local animated, disconnect = handler.animate({ duration = 0.05 })

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

        local animated = handler.animate({ duration = 3 })

        handler.setState("Active")
        task.wait(0.3)

        local middle = animated.opacity()

        expect(middle > 0 and middle < 1).toBe(true)

        handler.finish()

        expect(animated.opacity()).toBe(1)
    end)

    it("uses its own options instead of the handler defaults", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "AnimateOptionsPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 5,
            },
        })

        local animated = handler.animate({ duration = 0 })

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
            handler.animate({ duration = -1 })
        end).toThrow("duration")
    end)
end)
