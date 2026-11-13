const VideState = require("@VideState")
const Vide = require("@packages/Vide")

local schema = VideState.table({
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
})

type Values = VideState.Infer<typeof(schema)>
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

local rule = VideState.rule(schema)
local panel = rule.new({
    Idle = values,
    Active = {
        visible = false,
        mode = "Active",
        transparency = 1,
        order = 2,
        title = "Open",
        color = Color3.new(1, 1, 1),
        offset = UDim.new(1, 0),
        size = UDim2.fromOffset(100, 50),
        position = Vector2.new(1, 2),
        nested = { enabled = true },
    },
}, "Idle")

local visibleSource: Vide.Source<boolean> = panel.sources.visible
local sizeSource: Vide.Source<UDim2> = panel.sources.size

return { values, panel, visibleSource, sizeSource }
