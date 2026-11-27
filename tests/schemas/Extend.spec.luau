const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

describe("extend", function()
    it("makes a rule with the fields of the base and the new ones", function()
        local base = VideState.rule({
            opacity = VideState.float(),
        }, { name = "ExtendBasePanel" })
        local extended = VideState.extend(base, {
            label = VideState.string(),
        }, { name = "ExtendLabelPanel" })

        local handler = extended.new({
            Idle = { opacity = Vide.source(0), label = Vide.source("Idle") },
            Active = { opacity = Vide.source(1), label = Vide.source("Active") },
        }, "Idle")

        expect(handler.sources.opacity()).toBe(0)
        expect(handler.sources.label()).toBe("Idle")

        -- A state of the extended rule must give every field, the base ones included.
        expect(function()
            extended.new({
                Idle = { opacity = Vide.source(0) },
                Active = { opacity = Vide.source(1) },
            } :: any, "Idle")
        end).toThrow("label")
    end)

    it("leaves the base rule unchanged", function()
        local base = VideState.rule({
            opacity = VideState.float(),
        }, { name = "ExtendUnchangedBase" })

        VideState.extend(base, {
            label = VideState.string(),
        }, { name = "ExtendUnchangedChild" })

        local handler = base.new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle")

        expect(handler.sources.opacity()).toBe(0)
    end)

    it("adds state names, transitions, and tags to the base ones", function()
        local base = VideState.rule({
            opacity = VideState.float(),
        }, {
            name = "ExtendStatesBase",
            tags = { "Button" },
            allowedStateNames = { "Idle", "Disabled" },
            allowedTransitions = {
                Disabled = { "Idle" },
            },
        })
        local extended = VideState.extend(base, {}, {
            name = "ExtendStatesChild",
            tags = { "Primary", "Button" },
            allowedStateNames = { "Loading" },
            allowedTransitions = {
                Loading = { "Idle" },
            },
        })

        expect(extended.getTags()[1]).toBe("Button")
        expect(extended.getTags()[2]).toBe("Primary")
        expect(#extended.getTags()).toBe(2)

        local handler = extended.new({
            Idle = { opacity = Vide.source(1) },
            Disabled = { opacity = Vide.source(0.5) },
            Loading = { opacity = Vide.source(0.8) },
        }, "Idle")

        handler.setState("Loading")

        expect(function()
            handler.setState("Disabled")
        end).toThrow('cannot change state from "Loading" to "Disabled"')

        handler.setState("Idle")
        handler.setState("Disabled")

        expect(function()
            handler.setState("Loading")
        end).toThrow('cannot change state from "Disabled" to "Loading"')
    end)

    it("lets the extension replace the transitions of a base state", function()
        local base = VideState.rule({
            opacity = VideState.float(),
        }, {
            name = "ExtendReplaceBase",
            allowedTransitions = {
                Disabled = { "Idle" },
            },
        })
        local extended = VideState.extend(base, {}, {
            name = "ExtendReplaceChild",
            allowedTransitions = {
                Disabled = { "Active" },
            },
        })
        local handler = extended.new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
            Disabled = { opacity = Vide.source(0.5) },
        }, "Disabled")

        handler.setState("Active")

        expect(handler.currentState()).toBe("Active")
    end)

    it("reads the tags the base rule has now", function()
        local base = VideState.rule({
            opacity = VideState.float(),
        }, { name = "ExtendTagsBase" })

        base.addTags("Added")

        local extended = VideState.extend(base, {}, { name = "ExtendTagsChild" })

        expect(extended.hasTag("Added")).toBe(true)
    end)

    it("rejects a field that the base rule already has", function()
        local base = VideState.rule({
            opacity = VideState.float(),
        }, { name = "ExtendRedefineBase" })

        expect(function()
            VideState.extend(base, {
                opacity = VideState.integer(),
            }, { name = "ExtendRedefineChild" })
        end).toThrow('extend cannot redefine field "opacity" of rule ExtendRedefineBase')
    end)

    it("rejects arguments that are not a rule, fields, and metadata", function()
        local base = VideState.rule({
            opacity = VideState.float(),
        }, { name = "ExtendArgumentsBase" })

        expect(function()
            VideState.extend({} :: any, {}, { name = "ExtendArgumentsBad" })
        end).toThrow("first argument")
        expect(function()
            VideState.extend(base, "label" :: any, { name = "ExtendArgumentsFields" })
        end).toThrow("table of named field schemas")
        expect(function()
            VideState.extend(base, {}, nil :: any)
        end).toThrow("metadata")
        expect(function()
            VideState.extend(base, {}, { name = "ExtendArgumentsBase" })
        end).toThrow("Duplicate rule name")
    end)
end)

return nil
