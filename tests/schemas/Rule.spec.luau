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

    it("provides transition values and alpha, and disconnects transition listeners", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
            opacity = VideState.float(),
        }, { name = "ValuePanel" }).new({
            Idle = { visible = Vide.source(false), opacity = Vide.source(0) },
            Active = { visible = Vide.source(true), opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.05,
            },
        })

        local currents = {}
        local alphas = {}
        local secondCurrents = {}
        local disconnect = handler.onTransition(function(from, to, current, alpha)
            expect(from.visible).toBe(false)
            expect(to.visible).toBe(true)
            table.insert(currents, current)
            table.insert(alphas, alpha)
        end)
        local disconnectSecond = handler.onTransition(function(_, _, current)
            table.insert(secondCurrents, current)
        end)

        handler.setState("Active")
        expect(currents[1].opacity).toBe(0)
        expect(alphas[1]).toBe(0)
        expect(secondCurrents[1].opacity).toBe(0)

        task.wait(0.15)
        expect(currents[#currents].opacity).toBe(1)
        expect(alphas[#alphas]).toBe(1)
        expect(secondCurrents[#secondCurrents].opacity).toBe(1)
        expect(#secondCurrents).toBe(#currents)

        disconnect()
        disconnectSecond()

        local countAfterDisconnect = #currents

        handler.setState("Idle")
        task.wait(0.1)

        expect(#currents).toBe(countAfterDisconnect)
    end)

    it("gives each transition connection its own settings", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "PerConnectionPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.6,
            },
        })

        local inheritedAlphas: { number } = {}
        local overriddenAlphas: { number } = {}

        handler.onTransition(function(_, _, _, alpha)
            table.insert(inheritedAlphas, alpha)
        end)
        handler.onTransition(function(_, _, _, alpha)
            table.insert(overriddenAlphas, alpha)
        end, {
            duration = 0.05,
        })

        handler.setState("Active")
        task.wait(0.3)

        -- The override finished, and the connection with no options still runs on the handler's duration.
        expect(overriddenAlphas[#overriddenAlphas]).toBe(1)
        expect(inheritedAlphas[#inheritedAlphas] < 1).toBe(true)

        task.wait(0.6)

        expect(inheritedAlphas[#inheritedAlphas]).toBe(1)

        expect(function()
            handler.onTransition(function() end, { easing = "bounce" } :: any)
        end).toThrow("onTransition easing must be a known easing name")
    end)

    it("tweens numeric fields and snaps other fields at the start of a transition", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
            opacity = VideState.float(),
        }, { name = "TweenValuePanel" }).new({
            Idle = { visible = Vide.source(false), opacity = Vide.source(0) },
            Active = { visible = Vide.source(true), opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                easing = "quadIn",
                -- A long transition spans many frames, so a slow frame cannot skip every intermediate value.
                duration = 0.4,
            },
        })

        local currents: { { visible: boolean, opacity: number } } = {}
        local alphas: { number } = {}

        handler.onTransition(function(_, _, current, alpha)
            table.insert(currents, current)
            table.insert(alphas, alpha)
        end)

        handler.setState("Active")
        task.wait(0.9)

        expect(currents[1].visible).toBe(true)
        expect(currents[1].opacity).toBe(0)
        expect(currents[#currents].opacity).toBe(1)

        local hasIntermediate = false

        for index, current in currents do
            local isBetween = current.opacity > 0 and current.opacity < 1

            if isBetween then
                hasIntermediate = true
            end

            -- With a single numeric field, the eased alpha matches the field's own progress.
            expect(math.abs(alphas[index] - current.opacity) < 0.0001).toBe(true)
        end

        expect(hasIntermediate).toBe(true)
    end)

    it("lets the alpha overshoot with back easing", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "OvershootPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                easing = "backOut",
                duration = 0.5,
            },
        })

        local highestAlpha = 0
        local lastAlpha = 0

        handler.onTransition(function(_, _, _, alpha)
            highestAlpha = math.max(highestAlpha, alpha)
            lastAlpha = alpha
        end)

        handler.setState("Active")
        task.wait(1)

        expect(highestAlpha > 1).toBe(true)
        expect(lastAlpha).toBe(1)
    end)

    it("stops a running transition when disconnected", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "StopPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle", {
            onTransition = {
                duration = 0.25,
            },
        })

        local calls = 0
        local disconnect = handler.onTransition(function()
            calls += 1
        end)

        handler.setState("Active")
        task.wait(0.05)
        disconnect()

        local callsAfterDisconnect = calls

        task.wait(0.1)

        expect(calls).toBe(callsAfterDisconnect)
    end)

    it("replaces a running transition when the state changes again", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "ReplacePanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.2,
            },
        })

        local lastTo = nil

        handler.onTransition(function(_, to)
            lastTo = to.opacity
        end)

        handler.setState("Active")
        task.wait(0.05)
        handler.setState("Idle")
        task.wait(0.3)

        expect(lastTo).toBe(0)
    end)

    it("continues from the current value when a transition is interrupted", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "InterruptPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.6,
            },
        })

        local values: { number } = {}

        handler.onTransition(function(_, _, current)
            table.insert(values, current.opacity)
        end)

        handler.setState("Active")
        task.wait(0.25)

        local valueBeforeInterrupt = values[#values]
        local countBeforeInterrupt = #values

        handler.setState("Idle")

        -- The new transition starts at the value the first one reached, not at the previous state's 1.
        local firstValue = values[countBeforeInterrupt + 1]
        local isBetween = valueBeforeInterrupt > 0.05 and valueBeforeInterrupt < 0.95

        expect(isBetween).toBe(true)
        expect(math.abs(firstValue - valueBeforeInterrupt) < 0.0001).toBe(true)

        task.wait(0.9)

        expect(values[#values]).toBe(0)
    end)

    it("pauses a transition when the speed is 0", function()
        local speed = Vide.source(1)
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "PausedPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.4,
                speed = speed,
            },
        })

        local calls = 0
        local lastAlpha = 0

        handler.onTransition(function(_, _, _, alpha)
            calls += 1
            lastAlpha = alpha
        end)

        handler.setState("Active")
        task.wait(0.1)
        speed(0)
        task.wait(0.05)

        local callsWhenPaused = calls
        local alphaWhenPaused = lastAlpha

        task.wait(0.1)

        expect(calls).toBe(callsWhenPaused)
        expect(lastAlpha).toBe(alphaWhenPaused)
        expect(lastAlpha < 1).toBe(true)

        speed(1)
        task.wait(0.6)

        expect(lastAlpha).toBe(1)
    end)

    it("clamps a negative speed to 0 so the transition never moves backwards", function()
        local speed = Vide.source(1)
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "BackwardsPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.4,
                speed = speed,
            },
        })

        local alphas: { number } = {}

        handler.onTransition(function(_, _, _, alpha)
            table.insert(alphas, alpha)
        end)

        handler.setState("Active")
        task.wait(0.1)
        speed(-1)
        task.wait(0.1)

        for index = 2, #alphas do
            expect(alphas[index] >= alphas[index - 1]).toBe(true)
        end
    end)

    it("applies a duration source that changes during a transition", function()
        local duration = Vide.source(5)
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "DynamicDurationPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = duration,
            },
        })

        local lastCurrent = nil

        handler.onTransition(function(_, _, current)
            lastCurrent = current.opacity
        end)

        handler.setState("Active")
        task.wait(0.1)

        expect(lastCurrent < 1).toBe(true)

        duration(0.05)
        task.wait(0.3)

        expect(lastCurrent).toBe(1)
    end)

    it("rejects invalid onTransition options", function()
        local rule = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "BadOptionsPanel" })
        local states = {
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }

        expect(function()
            rule.new(states, "Idle", { onTransition = { easing = "bounce" } :: any })
        end).toThrow("onTransition easing must be a known easing name")

        expect(function()
            rule.new(states, "Idle", { onTransition = { duration = -1 } })
        end).toThrow("onTransition duration must be a finite non-negative number")

        expect(function()
            rule.new(states, "Idle", { onTransition = { speed = Vide.source(-1) } })
        end).toThrow("onTransition speed must not be negative")

        expect(function()
            rule.new(states, "Idle", { onTransition = { speed = 1 :: any } })
        end).toThrow("onTransition speed must be a source")

        expect(function()
            rule.new(states, "Idle", { onTransition = { tween = "quadIn" } :: any })
        end).toThrow("onTransition options has an unknown key tween")

        expect(function()
            rule.new(states, "Idle", { onTransition = "quadIn" :: any })
        end).toThrow("onTransition options must be a table")
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

return nil
