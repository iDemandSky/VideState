const VideState = require("@VideState")
const Vide = require("@packages/Vide")

local rule = VideState.rule({
    visible = VideState.boolean(),
    mode = VideState.enum("Idle", "Active"),
    transparency = VideState.float({ min = 0, max = 1, step = 0.01 }),
    order = VideState.integer({ min = 0 }),
    title = VideState.string({ maxLength = 100, truncate = true }),
    color = VideState.color3(),
    offset = VideState.udim(),
    size = VideState.udim2(),
    position = VideState.vector2(),
    nested = VideState.record({
        enabled = VideState.boolean(),
    }),
}, { name = "SchemaExportsPanel", allowedStateNames = { "Idle", "Active" } })

type Values = VideState.Infer<typeof(rule._schema)>
local values: Values = {
    visible = true,
    mode = "Idle",
    transparency = 0.5,
    order = 1,
    title = "Panel",
    color = Color3.new(),
    offset = UDim.new(),
    size = UDim2.new(),
    position = Vector2.new(),
    nested = { enabled = false },
}

local panel = rule.new({
    Idle = {
        visible = Vide.source(true),
        mode = Vide.source("Idle"),
        transparency = Vide.source(0.5),
        order = Vide.source(1),
        title = Vide.source("Panel"),
        color = Vide.source(Color3.new()),
        offset = Vide.source(UDim.new()),
        size = Vide.source(UDim2.new()),
        position = Vide.source(Vector2.new()),
        nested = Vide.source({ enabled = false }),
    },
    Active = {
        visible = Vide.source(false),
        mode = Vide.source("Active"),
        transparency = Vide.source(1),
        order = Vide.source(2),
        title = Vide.source("Open"),
        color = Vide.source(Color3.new(1, 1, 1)),
        offset = Vide.source(UDim.new(1, 0)),
        size = Vide.source(UDim2.fromOffset(100, 50)),
        position = Vide.source(Vector2.new(1, 2)),
        nested = Vide.source({ enabled = true }),
    },
}, "Idle")

local visibleSource: Vide.Source<boolean> = panel.sources.visible
local sizeSource: Vide.Source<UDim2> = panel.sources.size

return { values, panel, visibleSource, sizeSource }
