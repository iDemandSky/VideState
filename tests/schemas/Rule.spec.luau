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

    it("provides transition values and disconnects transition listeners", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
            opacity = VideState.float(),
        }, { name = "ValuePanel" }).new({
            Idle = { visible = Vide.source(false), opacity = Vide.source(0) },
            Active = { visible = Vide.source(true), opacity = Vide.source(1) },
        }, "Idle", { transitionDuration = 0.05 })

        local currents = {}
        local secondCurrents = {}
        local disconnect = handler.onTransition(function(from, to, current)
            expect(from.visible).toBe(false)
            expect(to.visible).toBe(true)
            table.insert(currents, current)
        end)
        local disconnectSecond = handler.onTransition(function(_, _, current)
            table.insert(secondCurrents, current)
        end)

        handler.setState("Active")
        expect(currents[1].opacity).toBe(0)
        expect(secondCurrents[1].opacity).toBe(0)

        task.wait(0.1)
        expect(currents[#currents].opacity).toBe(1)
        expect(secondCurrents[#secondCurrents].opacity).toBe(1)
        expect(#secondCurrents).toBe(#currents)

        disconnect()
        disconnectSecond()
        local countAfterDisconnect = #currents
        handler.setState("Idle")
        task.wait(0.1)

        expect(#currents).toBe(countAfterDisconnect)
        expect(#secondCurrents).toBe(countAfterDisconnect)
    end)

    it("tweens numeric fields and snaps other fields at the start of a transition", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
            opacity = VideState.float(),
        }, { name = "TweenValuePanel" }).new({
            Idle = { visible = Vide.source(false), opacity = Vide.source(0) },
            Active = { visible = Vide.source(true), opacity = Vide.source(1) },
        }, "Idle", { transitionDuration = 0.1 })

        local currents: { { visible: boolean, opacity: number } } = {}
        handler.onTransition(function(_, _, current)
            table.insert(currents, current)
        end, { easing = "quadIn" })

        handler.setState("Active")
        task.wait(0.2)

        expect(currents[1].visible).toBe(true)
        expect(currents[1].opacity).toBe(0)
        expect(currents[#currents].opacity).toBe(1)

        local hasIntermediate = false
        for _, current in currents do
            if current.opacity > 0 and current.opacity < 1 then
                hasIntermediate = true
            end
        end
        expect(hasIntermediate).toBe(true)
    end)

    it("stops a running transition when disconnected", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "StopPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle", { transitionDuration = 0.25 })

        local currents = {}
        local disconnect = handler.onTransition(function(_, _, current)
            table.insert(currents, current)
        end)

        handler.setState("Active")
        expect(currents[1].visible).toBe(true)

        disconnect()
        local countAfterDisconnect = #currents
        task.wait(0.05)
        handler.setState("Idle")
        task.wait(0.05)

        expect(#currents).toBe(countAfterDisconnect)
    end)

    it("stops applying a tween after disconnecting", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "DisconnectedTweenPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle", { transitionDuration = 0.25 })

        local currents = {}
        local disconnect = handler.onTransition(function(_, _, current)
            table.insert(currents, current)
        end, { easing = "cubicOut" })

        handler.setState("Active")
        expect(currents[1].visible).toBe(true)

        disconnect()
        local countAfterDisconnect = #currents
        handler.setState("Idle")
        task.wait(0.05)

        expect(#currents).toBe(countAfterDisconnect)
    end)

    it("runs each listener for its own duration", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "PerListenerDurationPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", { transitionDuration = 0.5 })

        local shortCurrents: { { opacity: number } } = {}
        local longCurrents: { { opacity: number } } = {}
        handler.onTransition(function(_, _, current)
            table.insert(shortCurrents, current)
        end, { duration = 0.05 })
        handler.onTransition(function(_, _, current)
            table.insert(longCurrents, current)
        end)

        handler.setState("Active")
        task.wait(0.2)
        local shortCountAfterFinish = #shortCurrents
        local longCountBeforeWait = #longCurrents
        task.wait(0.2)

        expect(shortCurrents[#shortCurrents].opacity).toBe(1)
        expect(#shortCurrents).toBe(shortCountAfterFinish)
        expect(#longCurrents > longCountBeforeWait).toBe(true)
    end)

    it("rejects invalid transition metadata", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "BadTweenPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle")

        expect(function()
            handler.onTransition(function() end, { easing = "bounce" } :: any)
        end).toThrow("onTransition easing must be a known easing name")

        expect(function()
            handler.onTransition(function() end, { duration = -1 } :: any)
        end).toThrow("onTransition duration must be a finite non-negative number")

        expect(function()
            handler.onTransition(function() end, { tween = "quadIn" } :: any)
        end).toThrow("onTransition metadata has an unknown key tween")

        expect(function()
            handler.onTransition(function() end, { tween = { easing = "quadIn" } } :: any)
        end).toThrow("onTransition metadata has an unknown key tween")

        expect(function()
            handler.onTransition(function() end, "quadIn" :: any)
        end).toThrow("onTransition metadata must be a table")
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
