--!nocheck

const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local rule = VideState.rule({ visible = VideState.boolean() }, { name = "InferenceInvalidCheckPanel" })

local invalidValue: VideState.Infer<typeof(rule._schema)> = { visible = "not a boolean" }
local invalidSource: Vide.Source<string> = rule.new({
    Idle = { visible = Vide.source(true) },
    Active = { visible = Vide.source(false) },
}, "Idle").sources.visible

return { invalidValue, invalidSource }
