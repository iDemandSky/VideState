const VideState = require("@VideState")
const Vide = require("@packages/Vide")

local rule = VideState.rule({
    visible = VideState.boolean(),
    mode = VideState.enum("Idle", "Active"),
    transparency = VideState.float({ min = 0, max = 1, step = 0.01 }),
    order = VideState.integer({ min = 0 }),
    title = VideState.string({ maxLength = 100, truncate = true }),
    color = VideState.color3(),
    width = VideState.union(VideState.float(), VideState.string()),
    offset = VideState.udim(),
    size = VideState.udim2(),
    position = VideState.vector2(),
    range = VideState.numberRange(),
    fade = VideState.numberSequence(),
    tint = VideState.colorSequence(),
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
    width = 1,
    offset = UDim.new(),
    size = UDim2.new(),
    position = Vector2.new(),
    range = NumberRange.new(0, 1),
    fade = NumberSequence.new(0),
    tint = ColorSequence.new(Color3.new()),
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
        width = Vide.source(1 :: number | string),
        offset = Vide.source(UDim.new()),
        size = Vide.source(UDim2.new()),
        position = Vide.source(Vector2.new()),
        range = Vide.source(NumberRange.new(0, 1)),
        fade = Vide.source(NumberSequence.new(0)),
        tint = Vide.source(ColorSequence.new(Color3.new())),
        nested = Vide.source({ enabled = false }),
    },
    Active = {
        visible = Vide.source(false),
        mode = Vide.source("Active"),
        transparency = Vide.source(1),
        order = Vide.source(2),
        title = Vide.source("Open"),
        color = Vide.source(Color3.new(1, 1, 1)),
        width = Vide.source("Auto" :: number | string),
        offset = Vide.source(UDim.new(1, 0)),
        size = Vide.source(UDim2.fromOffset(100, 50)),
        position = Vide.source(Vector2.new(1, 2)),
        range = Vide.source(NumberRange.new(2, 3)),
        fade = Vide.source(NumberSequence.new(1)),
        tint = Vide.source(ColorSequence.new(Color3.new(1, 1, 1))),
        nested = Vide.source({ enabled = true }),
    },
}, "Idle")

local visibleSource: Vide.Source<boolean> = panel.sources.visible
local widthSource: Vide.Source<number | string> = panel.sources.width
local sizeSource: Vide.Source<UDim2> = panel.sources.size
local rangeSource: Vide.Source<NumberRange> = panel.sources.range
local fadeSource: Vide.Source<NumberSequence> = panel.sources.fade
local tintSource: Vide.Source<ColorSequence> = panel.sources.tint

return { values, panel, visibleSource, widthSource, sizeSource, rangeSource, fadeSource, tintSource }
