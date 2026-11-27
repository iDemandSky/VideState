---
title: Inheritance
description: Make one base button component, then create a primary, a danger, and a default design that share its states.
---

# Inheritance

A base component defines the state structure once: its properties and its states. Each design of that
component follows the same structure and only changes the property values. You get many looks from one
component, without copying its logic.

## What we're building

A **main menu with three buttons**, all made from the button component in [Components](/examples/components):

| Button | Design | Purpose | Enabled |
| --- | --- | --- | --- |
| Play | `ButtonDesigns.Primary` (blue) | The main action | Yes |
| Delete | `ButtonDesigns.Danger` (red) | A destructive action | Yes |
| Shop | `ButtonDesigns.Default` (grey) | Not available yet | No |

All three buttons have the same four states (`Idle`, `Hovered`, `Pressed`, `Disabled`) and the same three
properties (`backgroundColor`, `textColor`, `textSize`). Only the values differ. For example, `Idle` is blue
for Play, red for Delete, and dark grey for Shop.

This page continues from Components. The **`ButtonRule`** and **`ButtonDesigns`** ModuleScripts in `ReplicatedStorage`,
`createStates`, and `createButton` are exactly the same, so they are not repeated here. The new designs are added to
`ButtonDesigns`.

## 1. The base component

The base is the **`ButtonRule`** ModuleScript you already wrote. It is the contract that every design has to follow:
each design provides `Idle`, `Hovered`, `Pressed`, and `Disabled`, with the same three properties. Do not change it.
Every button requires it by that name, so there is still one definition.

## 2. Add the designs

Each design is a table of type `Design`. It has the same states as the default design, with different values,
so every design works with the same `createButton`. Add the two designs below to the **`ButtonDesigns`** ModuleScript,
above its `return Designs`.

The primary design is blue. Its text grows by two points when hovered, like the default design:

::: code-group

```luau [ReplicatedStorage/ButtonDesigns.luau]
Designs.Primary = {
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
```

:::

The danger design is red. Its text does not grow on hover, which shows that designs can differ in any
property and not only in colors:

::: code-group

```luau [ReplicatedStorage/ButtonDesigns.luau]
Designs.Danger = {
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

:::

Each one is stored in `Designs` by name, so a component picks a design with `ButtonDesigns.Primary` or
`ButtonDesigns.Danger`.

## 3. Build the menu

In the LocalScript, create one button per design and place them in a list. Each button is its own handler, so changing one
never affects another.

::: code-group

```luau [StarterPlayerScripts/MainMenu.client.luau]
Vide.mount(function()
    return Vide.create "ScreenGui" {
        Name = "MainMenu",
        ResetOnSpawn = false,
        [1] = Vide.create "Frame" {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            [1] = Vide.create "UIListLayout" {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 12),
            },
            [2] = createButton("Play", ButtonDesigns.Primary, true),
            [3] = createButton("Delete", ButtonDesigns.Danger, true),
            [4] = createButton("Shop", ButtonDesigns.Default, false),
        },
    }
end, player:WaitForChild("PlayerGui"))
```

:::

You get a blue Play button, a red Delete button, and a greyed-out Shop button. They share the same hover and
press behavior, and each reacts on its own.
