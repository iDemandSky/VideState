const Lest = require("@Lest")
const Operations = require("../bench/Operations")

local describe, it = Lest.describe, Lest.it

const GROUP = "memory"

describe("memory benchmark of rules and handlers", function()
    it("measures rules and handlers", function()
        Operations.measureMemory(GROUP, "rule with 2 fields", 2000, function()
            return 0
        end, function()
            return Operations.createRule()
        end)
        Operations.measureMemory(GROUP, "rule with 20 fields", 500, function()
            return 0
        end, function()
            return Operations.createWideRule()
        end)

        local rule = Operations.createRule()

        -- The states are made first, so they are not part of what a handler costs.
        Operations.measureMemory(GROUP, "handler, 4 states of 2 fields", 2000, function()
            return Operations.createStates()
        end, function(prepared)
            return rule.new(prepared, "Idle")
        end)
    end)
end)
