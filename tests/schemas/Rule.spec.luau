const Lest = require("@Lest")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

describe("rule handlers", function()
    it("updates sources and current state when switching states", function()
        local schema = VideState.table({
            visible = VideState.boolean(),
        })
        local rule = VideState.rule(schema)
        local handler = rule.new({
            Idle = { visible = false },
            Active = { visible = true },
        }, "Idle")

        expect(handler.sources.visible()).toBe(false)
        expect(handler.currentState()).toBe("Idle")

        handler.setState("Active")

        expect(handler.sources.visible()).toBe(true)
        expect(handler.currentState()).toBe("Active")
    end)

    it("notifies change listeners with state values and disconnects them", function()
        local handler = VideState.rule(VideState.table({
            visible = VideState.boolean(),
        })).new({
            Idle = { visible = false },
            Active = { visible = true },
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
        local handler = VideState.rule(VideState.table({
            visible = VideState.boolean(),
        })).new({
            Idle = { visible = false },
            Active = { visible = true },
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
        local handler = VideState.rule(VideState.table({
            visible = VideState.boolean(),
        })).new({
            Idle = { visible = false },
            Active = { visible = true },
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
        local schema = VideState.table({
            visible = VideState.boolean(),
        })
        local handler = VideState.rule(schema).new({
            Idle = { visible = false },
            Active = { visible = true },
        }, "Idle")

        expect(function()
            handler.setState("Missing")
        end).toThrow("unknown state")

        expect(handler.sources.visible()).toBe(false)
        expect(handler.currentState()).toBe("Idle")
    end)
end)

return nil
