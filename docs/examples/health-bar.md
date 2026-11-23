---
title: Health bar
description: A health bar that animates its fill and color between preset health levels.
---

# Health bar

A health rule stores the health value, fill ratio, and fill color for each level. A transition listener moves display sources, so the bar animates between levels instead of jumping.

```luau
const Players = game:GetService("Players")
-- Point @Vide at the Vide package in your project.
const Vide = require("@Vide")
const VideState = require("@VideState")

const HealthRule = VideState.rule({
    health = VideState.integer({ min = 0, max = 100 }),
    fillRatio = VideState.float({ min = 0, max = 1 }),
    fillColor = VideState.color3(),
}, {
    name = "HealthBar",
    description = "A health bar whose fill animates between preset health levels",
    tags = { "ui", "hud" },
})

const function levelStates(health: number, color: Color3)
    return {
        health = Vide.source(health),
        fillRatio = Vide.source(health / 100),
        fillColor = Vide.source(color),
    }
end

const health = HealthRule.new({
    Full = levelStates(100, Color3.fromRGB(80, 200, 110)),
    Hurt = levelStates(60, Color3.fromRGB(230, 180, 60)),
    Critical = levelStates(20, Color3.fromRGB(220, 60, 60)),
}, "Full", {
    onTransition = {
        duration = 0.4,
    },
})

-- The bar reads these display sources, so the fill moves smoothly instead of jumping to the new state.
const shownRatio = Vide.source(1)
const shownColor = Vide.source(Color3.fromRGB(80, 200, 110))

health.onTransition(function(_, _, current)
    shownRatio(current.fillRatio)
    shownColor(current.fillColor)
end)

const player = Players.LocalPlayer

Vide.mount(function()
    return Vide.create "ScreenGui" {
        Name = "HealthBar",
        ResetOnSpawn = false,
        [1] = Vide.create "Frame" {
            Name = "Track",
            Size = UDim2.fromOffset(320, 24),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0.1),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            [1] = Vide.create "Frame" {
                Name = "Fill",
                Size = function()
                    return UDim2.fromScale(shownRatio(), 1)
                end,
                BackgroundColor3 = shownColor,
                BorderSizePixel = 0,
            },
        },
        [2] = Vide.create "TextButton" {
            Name = "SetFull",
            Text = "Full",
            Size = UDim2.fromOffset(120, 40),
            Position = UDim2.fromOffset(20, 60),
            Activated = function()
                health.setState("Full")
            end,
        },
        [3] = Vide.create "TextButton" {
            Name = "SetHurt",
            Text = "Hurt",
            Size = UDim2.fromOffset(120, 40),
            Position = UDim2.fromOffset(150, 60),
            Activated = function()
                health.setState("Hurt")
            end,
        },
        [4] = Vide.create "TextButton" {
            Name = "SetCritical",
            Text = "Critical",
            Size = UDim2.fromOffset(120, 40),
            Position = UDim2.fromOffset(280, 60),
            Activated = function()
                health.setState("Critical")
            end,
        },
    }
end, player:WaitForChild("PlayerGui"))
```

## What to notice

- `health` is an `integer` with bounds, so invalid levels are rejected.
- The `fillRatio` and `fillColor` sources hold the target values. `shownRatio` and `shownColor` hold what the bar draws.
- Use `onTransition.duration` to control how quickly the bar moves.
