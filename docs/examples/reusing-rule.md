---
title: Reusing a rule
description: Build two panels from one rule, each with its own state names and transition duration.
---

# Reusing a rule

A rule holds the schema and metadata. Each handler gets its own state names and sources, so one rule can drive several panels.

## The rule

```luau
const VideState = require("@VideState")

return VideState.rule({
    visible = VideState.boolean(),
    transparency = VideState.float({ min = 0, max = 1 }),
    position = VideState.udim2(),
}, {
    name = "Panel",
    description = "A panel that slides and fades in and out",
    tags = { "ui", "panel" },
})
```

## Two panels

```luau
const Players = game:GetService("Players")
-- Point @Vide at the Vide package in your project.
const Vide = require("@Vide")
const VideState = require("@VideState")
const PanelRule = require("./PanelRule")

type PanelHandler = VideState.Handler<VideState.InferRule<typeof(PanelRule)>>

const SHOWN_Y = 0.5
const HIDDEN_Y = 1.5

-- Each call builds a new set of sources for one state, so every panel
-- can reuse the same rule with its own state names and positions.
const function panelStates(visible: boolean, x: number)
    return {
        visible = Vide.source(visible),
        transparency = Vide.source(if visible then 0.1 else 1),
        position = Vide.source(UDim2.fromScale(x, if visible then SHOWN_Y else HIDDEN_Y)),
    }
end

const function toggle(handler: PanelHandler, openState: string, closedState: string)
    if handler.currentState() == openState then
        handler.setState(closedState)
    else
        handler.setState(openState)
    end
end

-- Settings and Shop use the same rule, but their state names differ and each handler tracks its own state.
local settings = PanelRule.new({
    Hidden = panelStates(false, 0.3),
    Shown = panelStates(true, 0.3),
}, "Hidden")

local shop = PanelRule.new({
    Closed = panelStates(false, 0.7),
    Open = panelStates(true, 0.7),
}, "Closed", {
    onTransition = {
        duration = 0.4,
    },
})

const function createPanel(name: string, handler: PanelHandler)
    return Vide.create "Frame" {
        Name = name,
        Size = UDim2.fromOffset(300, 200),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        Position = handler.sources.position,
        Visible = handler.sources.visible,
        BackgroundTransparency = handler.sources.transparency,
    }
end

const player = Players.LocalPlayer

Vide.mount(function()
    return Vide.create "ScreenGui" {
        Name = "ReusingRule",
        ResetOnSpawn = false,
        [1] = createPanel("Settings", settings),
        [2] = createPanel("Shop", shop),
        [3] = Vide.create "TextButton" {
            Name = "ToggleSettings",
            Text = "Settings",
            Size = UDim2.fromOffset(160, 40),
            Position = UDim2.fromOffset(20, 20),
            Activated = function()
                toggle(settings, "Shown", "Hidden")
            end,
        },
        [4] = Vide.create "TextButton" {
            Name = "ToggleShop",
            Text = "Shop",
            Size = UDim2.fromOffset(160, 40),
            Position = UDim2.fromOffset(20, 70),
            Activated = function()
                toggle(shop, "Open", "Closed")
            end,
        },
    }
end, player:WaitForChild("PlayerGui"))
```

## What to notice

- `Settings` uses `Hidden` and `Shown`. `Shop` uses `Closed` and `Open`. The rule doesn't depend on the names.
- `Shop` sets `onTransition.duration = 0.4`. `Settings` uses the 0.25 second default.
- Each `panelStates` call creates new sources, so the two handlers don't share state.
