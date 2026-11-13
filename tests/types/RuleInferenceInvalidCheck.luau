--!nocheck

const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local schema = VideState.table({ visible = VideState.boolean() })
local rule = VideState.rule(schema)

local invalidValue: VideState.Infer<typeof(schema)> = { visible = "not a boolean" }
local invalidSource: Vide.Source<string> = rule.new({
    Idle = { visible = true },
    Active = { visible = false },
}, "Idle").sources.visible

return { invalidValue, invalidSource }
