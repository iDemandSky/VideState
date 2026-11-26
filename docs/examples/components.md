---
title: Components
description: Build a menu button that reacts to the mouse, with a rule as its blueprint and a handler for each button.
---

# Components

VideState lets you build UI components the way you would in Vue.js. A [rule](/guide/rules) is the
component's blueprint: the properties it has and the states it can be in. A
[handler](/guide/handlers) is one instance of that component, with its own state and values. Vide
creates the Instances, and the handler decides what their properties are.

## What we're building

A **Play button** for a game's main menu. It reacts to the mouse, and every reaction is a state:

| State | When | What the player sees |
| --- | --- | --- |
| `Idle` | Nothing is happening | The normal dark button |
| `Hovered` | The mouse is over it | A lighter background and slightly larger text |
| `Pressed` | The mouse button is held down | A darker background |
| `Disabled` | The player cannot use it yet | A greyed-out button that ignores the mouse |

Every state sets the same three properties: `backgroundColor`, `textColor`, and `textSize`. The colors
and the text size fade over 0.15 seconds when the state changes, instead of jumping.

The steps below continue one script. Put them together in order, in a LocalScript.

## 1. Describe the component

The rule lists the properties a button has and the states it can be in. `allowedStateNames` makes
VideState reject any state that is not one of the four.

```luau
const Players = game:GetService("Players")
-- Point @Vide at the Vide package in your project.
const Vide = require("@Vide")
const VideState = require("@VideState")

const ButtonRule = VideState.rule({
    backgroundColor = VideState.color3(),
    textColor = VideState.color3(),
    textSize = VideState.integer({ min = 1 }),
}, {
    name = "Button",
    allowedStateNames = { "Idle", "Hovered", "Pressed", "Disabled" },
})
```

## 2. Design how each state looks

A design says what every state looks like. It is plain data, so it is easy to change or replace. The
`Look` and `Design` types match the rule, and your editor flags a missing state or property.

```luau
export type Look = {
    backgroundColor: Color3,
    textColor: Color3,
    textSize: number,
}

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
```

## 3. Turn the design into sources

A handler needs a Vide source for each property in each state. This helper builds them from a design.

```luau
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
```

## 4. Build the button

`createButton` makes one button. Calling `ButtonRule.new` creates the handler, which is this
button's component instance. The button starts in `Idle`, or in `Disabled` when it is not enabled.

```luau
const function createButton(label: string, design: Design, enabled: boolean)
    local handler = ButtonRule.new(createStates(design), if enabled then "Idle" else "Disabled", {
        onTransition = {
            duration = 0.15,
        },
    })

    -- The state sources change instantly. `animate` returns sources that fade between the states instead.
    local animated = handler.animate()

    local button = Vide.create "TextButton" {
        Name = label,
        Text = label,
        Size = UDim2.fromOffset(200, 50),
        AutoButtonColor = false,
        BackgroundColor3 = animated.backgroundColor,
        TextColor3 = animated.textColor,
        TextSize = animated.textSize,
    }

    -- The mouse events only change the state. The handler decides what each state looks like.
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
```

## 5. Show it

Create the Play button and mount it in the player's screen.

```luau
const player = Players.LocalPlayer

Vide.mount(function()
    return Vide.create "ScreenGui" {
        Name = "Components",
        ResetOnSpawn = false,
        [1] = createButton("Play", DefaultDesign, true),
    }
end, player:WaitForChild("PlayerGui"))
```

Hover over the button and it lightens and grows. Hold the mouse down and it darkens. Pass `false`
as the last argument to `createButton` and it starts greyed out and ignores the mouse.

## What to notice

- The rule is written once. Every button is a new handler made with `ButtonRule.new`, and each handler keeps its own state.
- The component's states and properties live in the rule, so a state name outside `allowedStateNames` is rejected.
- `createButton` only reads from the handler. It never decides colors itself, so changing a design needs no change to the component.
- `handler.animate()` gives the properties as sources that fade between the states, so they bind straight to the Instance. [`onTransition`](/guide/handlers#ontransition) is the same transition with a callback, for when you need to run your own code on each frame.
- To make another button, call `createButton` again. To make a different looking button, pass another design. See [Inheritance](/examples/inheritance).
