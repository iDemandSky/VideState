---
title: Settings toggles
description: Two on/off switches that start from a saved value and update the saved value when flipped.
---

# Settings toggles

Each toggle is a handler with `On` and `Off` states. Player attributes stand in for a real save system here. They only last for the current session, so use DataStore or another persistence layer in a real game.

```luau
const Players = game:GetService("Players")
-- Point @Vide at the Vide package in your project.
const Vide = require("@Vide")
const VideState = require("@VideState")

const ToggleRule = VideState.rule({
    enabled = VideState.boolean(),
    knobPosition = VideState.udim2(),
    trackColor = VideState.color3(),
}, {
    name = "SettingToggle",
    description = "An on/off switch that restores its saved value",
    tags = { "ui", "settings" },
})

const ON_COLOR = Color3.fromRGB(70, 180, 100)
const OFF_COLOR = Color3.fromRGB(90, 90, 90)

const function stateValues(on: boolean)
    return {
        enabled = Vide.source(on),
        knobPosition = Vide.source(UDim2.fromScale(if on then 0.55 else 0.05, 0.5)),
        trackColor = Vide.source(if on then ON_COLOR else OFF_COLOR),
    }
end

const player = Players.LocalPlayer

-- Player attributes stand in for a real save system such as DataStore, and only last for this session.
const function createToggle(label: string, saveKey: string, yOffset: number)
    local startOn = player:GetAttribute(saveKey) == true
    local handler = ToggleRule.new({
        On = stateValues(true),
        Off = stateValues(false),
    }, if startOn then "On" else "Off")

    const function flip()
        local nextState = if handler.currentState() == "On" then "Off" else "On"
        handler.setState(nextState)
        player:SetAttribute(saveKey, nextState == "On")
    end

    return Vide.create "TextButton" {
        Name = label,
        Text = "",
        Size = UDim2.fromOffset(120, 40),
        Position = UDim2.fromOffset(20, yOffset),
        BackgroundColor3 = handler.sources.trackColor,
        Activated = function()
            flip()
        end,
        [1] = Vide.create "Frame" {
            Name = "Knob",
            Size = UDim2.fromOffset(32, 32),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = handler.sources.knobPosition,
            BackgroundColor3 = Color3.new(1, 1, 1),
        },
    }
end

Vide.mount(function()
    return Vide.create "ScreenGui" {
        Name = "SettingsToggles",
        ResetOnSpawn = false,
        [1] = createToggle("Music", "MusicEnabled", 20),
        [2] = createToggle("SoundEffects", "SoundEffectsEnabled", 80),
    }
end, player:WaitForChild("PlayerGui"))
```

## What to notice

- The starting state comes from the saved value, so the toggle restores its position when the UI is created.
- `flip` changes the state and saves the new value in one place.
- The knob position and track color both come from the same handler, so they always change together.
