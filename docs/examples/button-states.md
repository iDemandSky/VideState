---
title: Button states
description: Share one button rule across several buttons, with shared transition timing and a color that fades between states.
---

# Button states

This example uses one rule for every button. Mouse events move each button between `Idle`, `Hovered`, `Pressed`, and `Disabled`.

```luau
const Players = game:GetService("Players")
-- Point @Vide at the Vide package in your project.
const Vide = require("@Vide")
const VideState = require("@VideState")

const ButtonRule = VideState.rule({
    backgroundColor = VideState.color3(),
    textSize = VideState.integer({ min = 1 }),
}, {
    name = "Button",
    allowedStateNames = { "Idle", "Hovered", "Pressed", "Disabled" },
})

-- Every button shares these options, so all of them fade over the same duration.
const TRANSITION_OPTIONS = {
    onTransition = {
        duration = 0.15,
    },
}

const function buttonStates(backgroundColor: Color3, textSize: number)
    return {
        backgroundColor = Vide.source(backgroundColor),
        textSize = Vide.source(textSize),
    }
end

const function createButton(label: string, enabled: boolean)
    local handler = ButtonRule.new({
        Idle = buttonStates(Color3.fromRGB(60, 60, 70), 18),
        Hovered = buttonStates(Color3.fromRGB(80, 80, 95), 20),
        Pressed = buttonStates(Color3.fromRGB(40, 40, 50), 18),
        Disabled = buttonStates(Color3.fromRGB(35, 35, 35), 18),
    }, if enabled then "Idle" else "Disabled", TRANSITION_OPTIONS)

    -- The rendered color is owned by this button and is moved by the transition.
    local displayColor = Vide.source(handler.sources.backgroundColor())

    handler.onTransition(function(_, _, current)
        displayColor(current.backgroundColor)
    end)

    local button = Vide.create "TextButton" {
        Name = label,
        Text = label,
        Size = UDim2.fromOffset(200, 50),
        AutoButtonColor = false,
        BackgroundColor3 = displayColor,
        TextSize = handler.sources.textSize,
    }

    button.MouseEnter:Connect(function()
        if handler.currentState() == "Idle" then
            handler.setState("Hovered")
        end
    end)

    button.MouseLeave:Connect(function()
        local state = handler.currentState()
        if state == "Hovered" or state == "Pressed" then
            handler.setState("Idle")
        end
    end)

    button.MouseButton1Down:Connect(function()
        local state = handler.currentState()
        if state == "Idle" or state == "Hovered" then
            handler.setState("Pressed")
        end
    end)

    button.MouseButton1Up:Connect(function()
        if handler.currentState() == "Pressed" then
            handler.setState("Hovered")
        end
    end)

    return button
end

const player = Players.LocalPlayer

Vide.mount(function()
    local playButton = createButton("Play", true)
    local shopButton = createButton("Shop", false)

    return Vide.create "ScreenGui" {
        Name = "ButtonStates",
        ResetOnSpawn = false,
        [1] = Vide.create "Frame" {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            [1] = Vide.create "UIListLayout" {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 12),
            },
            [2] = playButton,
            [3] = shopButton,
        },
    }
end, player:WaitForChild("PlayerGui"))
```

## What to notice

- `allowedStateNames` limits the rule to the four button states. Any other name is rejected.
- `TRANSITION_OPTIONS` is shared, so every button fades over 0.15 seconds.
- `onTransition` moves a separate `displayColor` source. The state source changes instantly, so the fade has to come from this listener.
