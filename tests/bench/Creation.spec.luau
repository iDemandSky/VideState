const Lest = require("@Lest")
const Operations = require("./Operations")
const VideState = require("@VideState")

local describe, it = Lest.describe, Lest.it

const GROUP = "creation"

describe("creation benchmark", function()
    it("measures the schemas and the rules", function()
        Operations.measure(GROUP, "schema float", 2000, function()
            VideState.float({ min = 0, max = 10 })
        end)
        Operations.measure(GROUP, "schema record with 3 fields", 2000, function()
            VideState.record({
                position = VideState.udim2(),
                color = VideState.color3(),
                visible = VideState.boolean(),
            })
        end)
        Operations.measure(GROUP, "schema union", 2000, function()
            VideState.union(VideState.float(), VideState.enum("Auto"))
        end)
        Operations.measure(GROUP, "rule with 2 fields", 1000, function()
            Operations.createRule()
        end)
        Operations.measure(GROUP, "rule with 20 fields", 500, function()
            Operations.createWideRule()
        end)
        Operations.measure(GROUP, "rule with tags and allowedTransitions", 1000, function()
            VideState.rule({
                opacity = VideState.float(),
            }, {
                name = Operations.uniqueName("BenchMeta"),
                tags = { "A", "B" },
                allowedStateNames = { "Idle", "A", "B", "C" },
                allowedTransitions = { Idle = { "A" }, A = { "B" } },
            })
        end)

        local base = Operations.createRule()

        Operations.measure(GROUP, "extend a rule", 1000, function()
            VideState.extend(base, {
                extra = VideState.float(),
            }, {
                name = Operations.uniqueName("BenchExtend"),
            })
        end)
    end)

    it("measures creating and destroying a handler", function()
        local rule = Operations.createRule()
        local wide = Operations.createWideRule()
        local kept = {}

        Operations.measure(GROUP, "rule.new, 4 states of 2 fields", 1000, function(index)
            kept[index] = rule.new(Operations.createStates(), "Idle")
        end)
        Operations.destroyAll(kept)

        local wideKept = {}

        Operations.measure(GROUP, "rule.new, 4 states of 20 fields", 300, function(index)
            wideKept[index] = wide.new(Operations.createWideStates(), "Idle")
        end)
        Operations.destroyAll(wideKept)

        Operations.measure(GROUP, "rule.new and destroy", 1000, function()
            rule.new(Operations.createStates(), "Idle").destroy()
        end)
    end)

    it("measures connecting to a handler", function()
        local rule = Operations.createRule()
        local handlers = {}

        for index = 1, 1000 do
            handlers[index] = rule.new(Operations.createStates(), "Idle")
        end

        const function perHandler(name: string, connect: (handler: any) -> ())
            Operations.measure(GROUP, name, #handlers, function(index)
                connect(handlers[index])
            end)
        end

        perHandler("onChange", function(handler)
            handler.onChange(function() end)
        end)
        perHandler("onEnter", function(handler)
            handler.onEnter("A", function() end)
        end)
        perHandler("onTransition", function(handler)
            handler.onTransition(function() end, { tweenDefault = { duration = 1 } })
        end)
        perHandler("animate", function(handler)
            handler.animate({ tweenDefault = { duration = 1 } })
        end)
        perHandler("progress", function(handler)
            handler.progress({ tweenDefault = { duration = 1 } })
        end)
        perHandler("onTransition with 6 tweenOverrides", function(handler)
            local overrides = {}

            for _, pair in { { "B", "C" }, { "C", "B" }, { "B", "A" }, { "A", "B" }, { "A", "Idle" }, { "Idle", "A" } } do
                table.insert(overrides, { from = { pair[1] }, to = { pair[2] }, tween = { duration = 1 } })
            end

            handler.onTransition(function() end, { tweenOverrides = overrides })
        end)

        Operations.destroyAll(handlers)
    end)

    it("measures the easings", function()
        Operations.measure(GROUP, "bezier", 5000, function()
            VideState.bezier(0.25, 0.1, 0.25, 1)
        end)
        local fresh = 0

        Operations.measure(GROUP, "spring, a new set of options", 100, function()
            -- A height that was never used, so the solver runs and the cache does not answer.
            fresh += 1

            VideState.spring({ height = 0.01 + fresh * 0.0007, bounces = 2 + fresh % 4 })
        end)
        Operations.measure(GROUP, "spring, a set of options that is cached", 5000, function()
            VideState.spring({ height = 0.2, bounces = 3, loss = 0.5 })
        end)

        local spring = VideState.spring({ height = 0.2, bounces = 3, loss = 0.5 })
        local curve = VideState.bezier(0.25, 0.1, 0.25, 1)
        local total = 0

        Operations.measure(GROUP, "evaluate a spring at one point", 20000, function(index)
            total += spring.fn((index % 1000) / 1000)
        end)
        Operations.measure(GROUP, "evaluate a bezier at one point", 20000, function(index)
            total += curve.fn((index % 1000) / 1000)
        end)

        -- The values are read, so the evaluations cannot be skipped.
        assert(total > 0, "the easings returned nothing")
    end)
end)
