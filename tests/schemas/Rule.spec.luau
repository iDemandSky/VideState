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

    it("runs exit and enter listeners for the states involved, in order", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "EnterExitPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
            Hidden = { opacity = Vide.source(0) },
        }, "Idle")

        local events: { string } = {}

        handler.onExit("Idle", function(nextState)
            table.insert(events, "exit Idle to " .. nextState)
        end)

        local disconnectEnter = handler.onEnter("Active", function(previousState)
            table.insert(events, "enter Active from " .. previousState)
        end)

        handler.onChange(function()
            table.insert(events, "change")
        end)
        handler.onEnter("Hidden", function()
            table.insert(events, "enter Hidden")
        end)

        handler.setState("Active")

        expect(#events).toBe(3)
        expect(events[1]).toBe("exit Idle to Active")
        expect(events[2]).toBe("enter Active from Idle")
        expect(events[3]).toBe("change")

        -- The same state does not count as entering it again.
        handler.setState("Active")

        expect(#events).toBe(3)

        disconnectEnter()
        handler.setState("Idle")
        handler.setState("Active")

        local hasEnterAfterDisconnect = table.find(events, "enter Active from Idle", 3) ~= nil

        expect(hasEnterAfterDisconnect).toBe(false)

        expect(function()
            handler.onEnter("Missing", function() end)
        end).toThrow(`onEnter state "Missing" is not a state of this handler`)

        expect(function()
            handler.onExit("Idle", 1 :: any)
        end).toThrow("onExit callback must be a function")

        expect(function()
            handler.onEnter(1 :: any, function() end)
        end).toThrow("onEnter state name must be a string, got number")
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

    it("finds rules by tags, lists tags, and checks a rule's tags", function()
        VideState.rule({ visible = VideState.boolean() }, {
            name = "TagPanelA",
            tags = { "infoTagMenu", "infoTagShared" },
        })
        VideState.rule({ visible = VideState.boolean() }, {
            name = "TagPanelB",
            tags = { "infoTagHud", "infoTagShared" },
        })
        VideState.rule({ visible = VideState.boolean() }, {
            name = "TagPanelC",
        })

        local shared = Info.getAllRulesWithTags("infoTagShared")
        local sharedNames = {}

        for _, rule in shared do
            table.insert(sharedNames, rule.name)
        end

        expect(table.concat(sharedNames, ",")).toBe("TagPanelA,TagPanelB")

        local both = Info.getAllRulesWithTags("infoTagShared", "infoTagMenu")

        expect(#both).toBe(1)
        expect(both[1].name).toBe("TagPanelA")
        expect(#Info.getAllRulesWithTags("infoTagMissing")).toBe(0)

        local tags = Info.getAllTags()

        expect(table.find(tags, "infoTagMenu") ~= nil).toBe(true)
        expect(table.find(tags, "infoTagHud") ~= nil).toBe(true)
        expect(table.find(tags, "infoTagShared") ~= nil).toBe(true)

        local sharedCount = 0

        for _, tag in tags do
            if tag == "infoTagShared" then
                sharedCount += 1
            end
        end

        expect(sharedCount).toBe(1)

        expect(Info.ruleHasTag("TagPanelA", "infoTagMenu")).toBe(true)
        expect(Info.ruleHasTag("TagPanelA", "infoTagHud")).toBe(false)
        expect(Info.ruleHasTag("TagPanelC", "infoTagMenu")).toBe(false)
        expect(Info.ruleHasTag("UnregisteredTagPanel", "infoTagMenu")).toBe(false)
    end)

    it("compares tags exactly without formatting them", function()
        VideState.rule({ visible = VideState.boolean() }, {
            name = "ExactTagPanel",
            tags = { "ExactTag", " spaced " },
        })

        expect(Info.ruleHasTag("ExactTagPanel", "ExactTag")).toBe(true)
        expect(Info.ruleHasTag("ExactTagPanel", "exacttag")).toBe(false)
        expect(Info.ruleHasTag("ExactTagPanel", "spaced")).toBe(false)
        expect(Info.ruleHasTag("ExactTagPanel", " spaced ")).toBe(true)
    end)

    it("rejects invalid arguments for tag lookups", function()
        expect(function()
            Info.getAllRulesWithTags()
        end).toThrow("requires at least one tag")

        expect(function()
            Info.getAllRulesWithTags(1 :: any)
        end).toThrow("must be a string")

        expect(function()
            Info.ruleHasTag(1 :: any, "tag")
        end).toThrow("Rule name must be a string")

        expect(function()
            Info.ruleHasTag("TagPanelA", nil :: any)
        end).toThrow("Tag must be a string")
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
