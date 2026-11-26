--!nocheck

const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local rule = VideState.rule({ visible = VideState.boolean() }, { name = "InferenceInvalidCheckPanel" })

local invalidValue: VideState.Infer<typeof(rule._schema)> = { visible = "not a boolean" }
local invalidHandler = rule.new({
    Idle = { visible = Vide.source(true) },
    Active = { visible = Vide.source(false) },
}, "Idle")
local invalidSource: Vide.Source<string> = invalidHandler.sources.visible
local invalidAnimated: Vide.Source<string> = invalidHandler.animate().visible
local invalidTag: boolean = rule.hasTag(5)

return { invalidValue, invalidSource, invalidAnimated, invalidTag }
