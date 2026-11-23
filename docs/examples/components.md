---
title: Components
description: Build a UI component the way you would in Vue.js, with a rule as its blueprint and a handler for each instance.
---

# Components

VideState lets you build UI components. A [rule](/guide/rules) is the component's blueprint: the properties
it has and the states it can be in. A [handler](/guide/handlers) is one instance of that component, with its
own state and values. Vide creates the Instances, and the handler decides what their properties are.

This button has four states. Mouse events move it between them, and each state sets the button's properties.

```luau
const Players = game:GetService("Players")
-- Point @Vide at the Vide package in your project.
const Vide = require("@Vide")
const VideState = require("@VideState")

-- The blueprint: which properties a button has and which states it can be in.
const ButtonRule = VideState.rule({
    backgroundColor = VideState.color3(),
    textColor = VideState.color3(),
    textSize = VideState.integer({ min = 1 }),
}, {
    name = "Button",
    allowedStateNames = { "Idle", "Hovered", "Pressed", "Disabled" },
})

export type Look = {
    backgroundColor: Color3,
    textColor: Color3,
    textSize: number,
}

-- A design gives every state its look. It is plain data, so it is easy to swap.
export type Design = {
    Idle: Look,
    Hovered: Look,
    Pressed: Look,
    Disabled: Look,
}

const DefaultDesign: Design = {
    Idle = {
        backgroundColor = Color3.fromRGB(60, 60, 70),
        textColor = Color3.fromRGB(255, 255, 255),
        textSize = 18,
    },
    Hovered = {
        backgroundColor = Color3.fromRGB(80, 80, 95),
        textColor = Color3.fromRGB(255, 255, 255),
        textSize = 20,
    },
    Pressed = {
        backgroundColor = Color3.fromRGB(40, 40, 50),
        textColor = Color3.fromRGB(255, 255, 255),
        textSize = 18,
    },
    Disabled = {
        backgroundColor = Color3.fromRGB(35, 35, 35),
        textColor = Color3.fromRGB(120, 120, 120),
        textSize = 18,
    },
}

-- Every state needs one Vide source for each property in the rule.
const function createStates(design: Design)
    local states = {}

    for stateName, look in design do
        states[stateName] = {
            backgroundColor = Vide.source(look.backgroundColor),
            textColor = Vide.source(look.textColor),
            textSize = Vide.source(look.textSize),
        }
    end

    return states
end

const function createButton(label: string, design: Design, enabled: boolean)
    -- The handler is this button's component instance.
    local handler = ButtonRule.new(createStates(design), if enabled then "Idle" else "Disabled", {
        onTransition = {
            duration = 0.15,
        },
    })

    -- The state sources change instantly, so the fade comes from onTransition.
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
        TextColor3 = handler.sources.textColor,
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
    return Vide.create "ScreenGui" {
        Name = "Components",
        ResetOnSpawn = false,
        [1] = createButton("Play", DefaultDesign, true),
    }
end, player:WaitForChild("PlayerGui"))
```

## What to notice

- The rule is written once. Every button is a new handler made with `ButtonRule.new`, and each handler keeps its own state.
- The component's states and properties live in the rule, so a state name outside `allowedStateNames` is rejected.
- `createButton` only reads from `handler.sources`. It never decides colors itself, so changing a design needs no change to the component.
- To make another button, call `createButton` again. To make a different looking button, pass another design. See [Inheritance](/examples/inheritance).
