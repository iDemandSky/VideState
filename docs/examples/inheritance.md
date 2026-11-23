---
title: Inheritance
description: Make a base UI component, then create many designs of it that share the same state structure.
---

# Inheritance

A base component defines the state structure once: its properties and its states. Each design of that component
uses the same structure and only changes the property values. You get many looks from one component, without
copying its logic.

This builds on the button from [Components](/examples/components). The rule, `createStates`, and `createButton`
stay exactly the same. Only the designs differ.

## The base component

The rule is the base. Every design has to follow it, so each one must provide `Idle`, `Hovered`,
`Pressed`, and `Disabled` with the same three properties.

```luau
const ButtonRule = VideState.rule({
    backgroundColor = VideState.color3(),
    textColor = VideState.color3(),
    textSize = VideState.integer({ min = 1 }),
}, {
    name = "Button",
    allowedStateNames = { "Idle", "Hovered", "Pressed", "Disabled" },
})
```

## Designs

A design is a table that follows the `Design` type from Components. It has the same states, so every design
works with the same `createButton`.

```luau
const PrimaryDesign: Design = {
    Idle = {
        backgroundColor = Color3.fromRGB(60, 120, 230),
        textColor = Color3.fromRGB(255, 255, 255),
        textSize = 18,
    },
    Hovered = {
        backgroundColor = Color3.fromRGB(80, 140, 250),
        textColor = Color3.fromRGB(255, 255, 255),
        textSize = 20,
    },
    Pressed = {
        backgroundColor = Color3.fromRGB(40, 95, 190),
        textColor = Color3.fromRGB(255, 255, 255),
        textSize = 18,
    },
    Disabled = {
        backgroundColor = Color3.fromRGB(70, 80, 100),
        textColor = Color3.fromRGB(150, 150, 150),
        textSize = 18,
    },
}

const DangerDesign: Design = {
    Idle = {
        backgroundColor = Color3.fromRGB(200, 60, 60),
        textColor = Color3.fromRGB(255, 255, 255),
        textSize = 18,
    },
    Hovered = {
        backgroundColor = Color3.fromRGB(225, 85, 85),
        textColor = Color3.fromRGB(255, 255, 255),
        textSize = 18,
    },
    Pressed = {
        backgroundColor = Color3.fromRGB(160, 40, 40),
        textColor = Color3.fromRGB(255, 255, 255),
        textSize = 18,
    },
    Disabled = {
        backgroundColor = Color3.fromRGB(90, 60, 60),
        textColor = Color3.fromRGB(150, 150, 150),
        textSize = 18,
    },
}
```

## Using the designs

Each button is a separate handler, so changing one never affects another. The designs only decide what each
state looks like.

```luau
Vide.mount(function()
    return Vide.create "ScreenGui" {
        Name = "Designs",
        ResetOnSpawn = false,
        [1] = Vide.create "Frame" {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            [1] = Vide.create "UIListLayout" {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 12),
            },
            [2] = createButton("Play", PrimaryDesign, true),
            [3] = createButton("Delete", DangerDesign, true),
            [4] = createButton("Shop", DefaultDesign, false),
        },
    }
end, player:WaitForChild("PlayerGui"))
```

## What to notice

- The state structure is defined once, in the rule. A design that leaves out a property is rejected when its handler is created, and the `Design` type flags a missing state while you write it.
- A new design is only data. The component's logic, such as the hover and press handling, is never copied.
- Designs can differ in any property, not only colors. A design could use a bigger `textSize` in every state.
- Each button owns its handler, so one button can be `Disabled` while another is `Hovered`.
