const Bench = require("./Bench")
const Lest = require("@Lest")

local describe, it = Lest.describe, Lest.it

describe("overrides benchmark", function()
    it("measures many handlers with an animate connection that has tweenOverrides", function()
        Bench.run("overrides")
    end)
end)
