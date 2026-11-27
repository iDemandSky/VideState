const Bench = require("./Bench")
const Lest = require("@Lest")

local describe, it = Lest.describe, Lest.it

describe("onTransition benchmark", function()
    it("measures many handlers with an onTransition connection", function()
        Bench.run("onTransition")
    end)
end)
