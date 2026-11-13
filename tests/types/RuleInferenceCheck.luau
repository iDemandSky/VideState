const Vide = require("@packages/Vide")
const VideState = require("@VideState")
const TypedCore = require("@luau-packages/TypedCore")

local schema = VideState.table({
    visible = VideState.boolean(),
    count = VideState.integer(),
})
local rule = VideState.rule(schema)

type Values = VideState.Infer<typeof(schema)>
type Sources = VideState.Sources<Values>

local values: Values = { visible = true, count = 2 }
local panel = rule.new(
    { Idle = values, Active = { visible = false, count = 0 } },
    "Idle",
    { transitionDuration = 0.25 }
)
local sources: Sources = panel.sources
local visibleSource: Vide.Source<boolean> = panel.sources.visible
local countSource: Vide.Source<number> = panel.sources.count
local inferredSchema: TypedCore.infer<typeof(rule.schema)> = values
local disconnectChange: () -> () = panel.onChange(function(from, to)
    local fromVisible: boolean = from.visible
    local toVisible: boolean = to.visible
    local fromCount: number = from.count
    local toCount: number = to.count
end)

local disconnectTransition: () -> () = panel.onTransition(function(from, to, alpha)
    local fromVisible: boolean = from.visible
    local toVisible: boolean = to.visible
    local progress: number = alpha
end)

disconnectChange()
disconnectTransition()

return {
    sources,
    visibleSource,
    countSource,
    inferredSchema,
    disconnectChange,
    disconnectTransition,
}
