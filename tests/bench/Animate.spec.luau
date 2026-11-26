const Bench = require("./Bench")
const Lest = require("@Lest")

local describe, it = Lest.describe, Lest.it

describe("animate benchmark", function()
    it("measures many handlers with an animate connection", function()
        Bench.run("animate")
    end)
end)
