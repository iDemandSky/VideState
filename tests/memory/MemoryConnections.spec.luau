const Lest = require("@Lest")
const Operations = require("../bench/Operations")

local describe, it = Lest.describe, Lest.it

const GROUP = "memory"
const COUNT = 2000

describe("memory benchmark of connections", function()
    it("measures one connection on a handler", function()
        local rule = Operations.createRule()

        const function handlers()
            return rule.new(Operations.createStates(), "Idle")
        end

        Operations.measureMemory(GROUP, "onChange connection", COUNT, handlers, function(handler)
            return handler.onChange(function() end)
        end)
        Operations.measureMemory(GROUP, "onEnter connection", COUNT, handlers, function(handler)
            return handler.onEnter("A", function() end)
        end)
        Operations.measureMemory(GROUP, "onTransition connection", COUNT, handlers, function(handler)
            return handler.onTransition(function() end, { tweenDefault = { duration = 1 } })
        end)
        Operations.measureMemory(GROUP, "animate connection, 2 sources", COUNT, handlers, function(handler)
            local animated, disconnect = handler.animate({ tweenDefault = { duration = 1 } })

            return { animated, disconnect }
        end)
        Operations.measureMemory(GROUP, "progress connection", COUNT, handlers, function(handler)
            local progress, disconnect = handler.progress({ tweenDefault = { duration = 1 } })

            return { progress, disconnect }
        end)
        Operations.measureMemory(
            GROUP,
            "onTransition connection with 6 tweenOverrides",
            COUNT,
            handlers,
            function(handler)
                local overrides = {}

                for _, pair in { { "B", "C" }, { "C", "B" }, { "B", "A" }, { "A", "B" }, { "A", "Idle" }, { "Idle", "A" } } do
                    table.insert(overrides, { from = { pair[1] }, to = { pair[2] }, tween = { duration = 1 } })
                end

                return handler.onTransition(function() end, { tweenOverrides = overrides })
            end
        )
    end)

end)
