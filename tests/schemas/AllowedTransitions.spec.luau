const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const function createStates()
    return {
        Idle = { opacity = Vide.source(0) },
        Active = { opacity = Vide.source(1) },
        Disabled = { opacity = Vide.source(0.5) },
    }
end

describe("allowed transitions", function()
    it("lets a state change to the states it lists and rejects the rest", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, {
            name = "TransitionsAllowedPanel",
            allowedTransitions = {
                Disabled = { "Idle" },
            },
        }).new(createStates(), "Idle")

        handler.setState("Disabled")

        expect(function()
            handler.setState("Active")
        end).toThrow('cannot change state from "Disabled" to "Active". Allowed: "Idle"')
        expect(handler.currentState()).toBe("Disabled")

        handler.setState("Idle")
        expect(handler.currentState()).toBe("Idle")
    end)

    it("lets a state that is not listed change to any state", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, {
            name = "UnlistedPanel",
            allowedTransitions = {
                Disabled = { "Idle" },
            },
        }).new(createStates(), "Idle")

        handler.setState("Active")
        handler.setState("Disabled")
        handler.setState("Idle")

        expect(handler.currentState()).toBe("Idle")
    end)

    it("does nothing for a change to the active state", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, {
            name = "SameStatePanel",
            allowedTransitions = {
                Disabled = { "Idle" },
            },
        }).new(createStates(), "Disabled")

        handler.setState("Disabled")

        expect(handler.currentState()).toBe("Disabled")
    end)

    it("does not run any event for a change that is rejected", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, {
            name = "RejectedEventsPanel",
            allowedTransitions = {
                Idle = { "Active" },
            },
        }).new(createStates(), "Idle")
        local changes = 0

        handler.onChange(function()
            changes += 1
        end)

        expect(function()
            handler.setState("Disabled")
        end).toThrow("cannot change state")
        expect(changes).toBe(0)
    end)

    it("lists every allowed state in the error", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, {
            name = "ListedPanel",
            allowedTransitions = {
                Idle = { "Disabled", "Active" },
            },
        }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
            Disabled = { opacity = Vide.source(0.5) },
            Hidden = { opacity = Vide.source(0) },
        }, "Idle")

        expect(function()
            handler.setState("Hidden")
        end).toThrow('Allowed: "Active", "Disabled"')
    end)

    it("checks the transitions when the rule is made", function()
        expect(function()
            VideState.rule({
                opacity = VideState.float(),
            }, {
                name = "BadTransitionsPanel",
                allowedStateNames = { "Idle", "Active" },
                allowedTransitions = {
                    Missing = { "Idle" },
                },
            })
        end).toThrow('"Missing" is not a state of the rule')
        expect(function()
            VideState.rule({
                opacity = VideState.float(),
            }, {
                name = "BadTargetPanel",
                allowedStateNames = { "Idle", "Active" },
                allowedTransitions = {
                    Idle = { "Missing" },
                },
            })
        end).toThrow('lists "Missing", which is not a state of the rule')
        expect(function()
            VideState.rule({
                opacity = VideState.float(),
            }, {
                name = "EmptyTransitionsPanel",
                allowedTransitions = {
                    Idle = {},
                },
            })
        end).toThrow("at least one state")
        expect(function()
            VideState.rule({
                opacity = VideState.float(),
            }, {
                name = "NotTablePanel",
                allowedTransitions = "Idle" :: any,
            })
        end).toThrow("must be a table")
    end)

    it("checks the transitions against the states of a handler", function()
        local rule = VideState.rule({
            opacity = VideState.float(),
        }, {
            name = "HandlerCheckPanel",
            allowedTransitions = {
                Idle = { "Gone" },
            },
        })

        expect(function()
            rule.new(createStates(), "Idle")
        end).toThrow('lists "Gone", which is not a state of the handler')
    end)

    it("checks every handler before everyHandler changes any state", function()
        local blocked = VideState.rule({
            opacity = VideState.float(),
        }, {
            name = "EveryBlockedPanel",
            allowedTransitions = {
                Disabled = { "Idle" },
            },
        }).new(createStates(), "Disabled")
        local free = VideState.rule({
            opacity = VideState.float(),
        }, { name = "EveryFreePanel" }).new(createStates(), "Idle")

        expect(function()
            VideState.everyHandler.withRule("EveryBlockedPanel").setState("Active")
        end).toThrow('cannot change to state "Active" in 1 handlers: EveryBlockedPanel (1). No handler changed state')
        expect(blocked.currentState()).toBe("Disabled")

        expect(function()
            VideState.everyHandler.withRule("EveryBlockedPanel").withRule("EveryFreePanel")
        end).toThrow()

        VideState.everyHandler.withRule("EveryFreePanel").setState("Active")
        expect(free.currentState()).toBe("Active")
    end)
end)

return nil
