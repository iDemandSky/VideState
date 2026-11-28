const Lest = require("@Lest")
const Operations = require("../bench/Operations")

local describe, it = Lest.describe, Lest.it

const GROUP = "memory"
const COUNT = 2000

describe("memory benchmark of running transitions", function()
    it("measures a running transition", function()
        local rule = Operations.createRule()

        -- The connection is made first, so only what a running transition holds is counted.
        const function connected()
            local handler = rule.new(Operations.createStates(), "Idle")

            handler.animate({ tweenDefault = { duration = 1000 } })

            return handler
        end

        Operations.measureMemory(GROUP, "running transition, 1 animate connection", COUNT, connected, function(handler)
            handler.setState("A")

            return handler
        end)
    end)

    it("lets go of what the suite made", function()
        Operations.releaseMemory()
    end)
end)
