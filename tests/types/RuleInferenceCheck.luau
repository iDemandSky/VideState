const Vide = require("@packages/Vide")
const VideState = require("@VideState")
const TypedCore = require("@luau-packages/TypedCore")

local rule = VideState.rule({
    visible = VideState.boolean(),
    count = VideState.integer(),
}, { name = "InferenceCheckPanel" })

type Values = VideState.Infer<typeof(rule._schema)>
type Sources = VideState.Sources<Values>

local panel = rule.new(
    {
        Idle = { visible = Vide.source(true), count = Vide.source(2) },
        Active = { visible = Vide.source(false), count = Vide.source(0) },
    },
    "Idle",
    {
        onTransition = {
            easing = "quadOut",
            duration = 0.25,
            speed = Vide.source(1),
        },
    }
)
local sources: Sources = panel.sources
local visibleSource: Vide.Source<boolean> = panel.sources.visible
local countSource: Vide.Source<number> = panel.sources.count
local values: Values = { visible = true, count = 2 }
local ruleValues: VideState.InferRule<typeof(rule)> = values
local typedHandler: VideState.Handler<VideState.InferRule<typeof(rule)>> = panel
local inferredSchema: TypedCore.infer<typeof(rule._schema)> = values
local disconnectChange: () -> () = panel.onChange(function(from, to)
    local _fromVisible: boolean = from.visible
    local _toVisible: boolean = to.visible
    local _fromCount: number = from.count
    local _toCount: number = to.count
end)

local disconnectTransition: () -> () = panel.onTransition(function(from, to, current, alpha)
    local _fromVisible: boolean = from.visible
    local _toVisible: boolean = to.visible
    local _currentVisible: boolean = current.visible
    local _alpha: number = alpha
end)

disconnectChange()
disconnectTransition()

return {
    sources,
    visibleSource,
    countSource,
    inferredSchema,
    ruleValues,
    typedHandler,
    disconnectChange,
    disconnectTransition,
}
