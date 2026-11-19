const Info = require("@VideState/Info")
const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

describe("rule handlers", function()
    it("updates sources and current state when switching states", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "SwitchPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle")

        expect(handler.sources.visible()).toBe(false)
        expect(handler.currentState()).toBe("Idle")

        handler.setState("Active")

        expect(handler.sources.visible()).toBe(true)
        expect(handler.currentState()).toBe("Active")
    end)

    it("notifies change listeners with state values and disconnects them", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "ChangePanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle")

        local changes = {}
        local disconnect = handler.onChange(function(from, to)
            table.insert(changes, { from = from.visible, to = to.visible })
        end)

        handler.setState("Active")
        disconnect()
        disconnect()
        handler.setState("Idle")

        expect(#changes).toBe(1)
        expect(changes[1].from).toBe(false)
        expect(changes[1].to).toBe(true)
    end)

    it("provides transition alpha and disconnects transition listeners", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "AlphaPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle", { transitionDuration = 0.05 })

        local alphas = {}
        local secondAlphas = {}
        local disconnect = handler.onTransition(function(from, to, alpha)
            expect(from.visible).toBe(false)
            expect(to.visible).toBe(true)
            table.insert(alphas, alpha)
        end)
        local disconnectSecond = handler.onTransition(function(_, _, alpha)
            table.insert(secondAlphas, alpha)
        end)

        handler.setState("Active")
        expect(alphas[1]).toBe(0)
        expect(secondAlphas[1]).toBe(0)

        task.wait(0.1)
        expect(alphas[#alphas]).toBe(1)
        expect(secondAlphas[#secondAlphas]).toBe(1)
        expect(#secondAlphas).toBe(#alphas)

        disconnect()
        disconnectSecond()
        local countAfterDisconnect = #alphas
        handler.setState("Idle")
        task.wait(0.1)

        expect(#alphas).toBe(countAfterDisconnect)
        expect(#secondAlphas).toBe(countAfterDisconnect)
    end)

    it("stops a running transition when disconnected", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "StopPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle", { transitionDuration = 0.25 })

        local alphas = {}
        local disconnect = handler.onTransition(function(_, _, alpha)
            table.insert(alphas, alpha)
        end)

        handler.setState("Active")
        expect(alphas[1]).toBe(0)

        disconnect()
        local countAfterDisconnect = #alphas
        task.wait(0.05)
        handler.setState("Idle")
        task.wait(0.05)

        expect(#alphas).toBe(countAfterDisconnect)
    end)

    it("keeps state unchanged when switching to an unknown state", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "UnknownPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle")

        expect(function()
            handler.setState("Missing")
        end).toThrow("unknown state")

        expect(handler.sources.visible()).toBe(false)
        expect(handler.currentState()).toBe("Idle")
    end)

    it("routes sources to the active state", function()
        local idleVisible = Vide.source(false)
        local activeVisible = Vide.source(false)
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "RoutePanel" }).new({
            Idle = { visible = idleVisible },
            Active = { visible = activeVisible },
        }, "Idle")

        handler.sources.visible(true)

        expect(idleVisible()).toBe(true)
        expect(activeVisible()).toBe(false)

        handler.setState("Active")

        expect(handler.sources.visible()).toBe(false)
    end)

    it("rejects a state field that is not a Vide source", function()
        expect(function()
            VideState.rule({
                visible = VideState.boolean(),
            }, { name = "NonSourcePanel" }).new({
                Idle = { visible = Vide.source(false) },
                Active = { visible = true },
            }, "Idle")
        end).toThrow('state "Active" field "visible" must be a Vide source')
    end)

    it("names the state whose source does not match the schema", function()
        expect(function()
            VideState.rule({
                visible = VideState.boolean(),
            }, { name = "InvalidPanel" }).new({
                Idle = { visible = Vide.source(false) },
                Active = { visible = Vide.source("yes") },
            }, "Idle")
        end).toThrow('Invalid state "Active"')
    end)

    it("requires every state to provide each field source", function()
        expect(function()
            VideState.rule({
                visible = VideState.boolean(),
            }, { name = "MissingPanel" }).new({
                Idle = { visible = Vide.source(false) },
                Active = {},
            }, "Idle")
        end).toThrow('state "Active" is missing source for field "visible"')
    end)

    it("rejects a rule name that is already registered", function()
        VideState.rule({ visible = VideState.boolean() }, { name = "DuplicatePanel" })

        expect(function()
            VideState.rule({ visible = VideState.boolean() }, { name = "DuplicatePanel" })
        end).toThrow("Duplicate rule name: DuplicatePanel")
    end)

    it("stores rule metadata for lookup by name", function()
        VideState.rule({ visible = VideState.boolean() }, {
            name = "LookupPanel",
            description = "Shows a panel",
            tags = { "ui" },
        })

        local info = Info.get("LookupPanel")
        if not info then
            error("LookupPanel metadata was not registered")
        end
        expect(info.description or nil).toBe("Shows a panel")
        expect(info.tags and info.tags[1]).toBe("ui")
        expect(Info.get("UnregisteredPanel")).toBe(nil)
    end)

    it("rejects states outside allowedStateNames", function()
        local handler = VideState.rule({ visible = VideState.boolean() }, {
            name = "AllowedPanel",
            allowedStateNames = { "Idle", "Active" },
        })

        expect(function()
            handler.new({
                Idle = { visible = Vide.source(false) },
                Missing = { visible = Vide.source(true) },
            }, "Idle")
        end).toThrow('state "Missing" is not in allowedStateNames')
    end)
end)

return nil
