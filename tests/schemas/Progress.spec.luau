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

describe("progress", function()
    it("starts at 1 and follows the alpha of a transition", function()
        local handler = createHandler("ProgressPanel")
        local progress, disconnect = handler.progress({
            tweenDefault = {
                duration = 5,
            },
        })

        expect(progress()).toBe(1)

        handler.setState("Active")

        -- The first frame of a transition has an alpha of 0.
        expect(progress()).toBe(0)

        task.wait(0.2)

        expect(progress() > 0).toBe(true)
        expect(progress() < 1).toBe(true)

        handler.finish()

        expect(progress()).toBe(1)

        disconnect()
    end)

    it("is a Vide source that bindings can read", function()
        local handler = createHandler("ProgressBindingPanel")
        local progress, disconnect = handler.progress({
            tweenDefault = {
                duration = 5,
            },
        })
        local seen: { number } = {}

        local destroy = Vide.root(function()
            Vide.effect(function()
                table.insert(seen, progress())
            end)
        end)

        handler.setState("Active")
        handler.finish()

        expect(seen[1]).toBe(1)
        expect(seen[#seen]).toBe(1)
        expect(#seen > 1).toBe(true)

        destroy()
        disconnect()
    end)

    it("keeps its last value after it is disconnected", function()
        local handler = createHandler("ProgressDisconnectPanel")
        local progress, disconnect = handler.progress({
            tweenDefault = {
                duration = 5,
            },
        })

        handler.setState("Active")
        disconnect()
        handler.setState("Idle")

        expect(progress()).toBe(0)
    end)

    it("takes the same options as onTransition", function()
        local handler = createHandler("ProgressOptionsPanel")

        expect(function()
            handler.progress({ duration = 1 } :: any)
        end).toThrow("tweenDefault")
    end)
end)

return nil
