---
title: Tween Config
description: Keep every tween setting in one ModuleScript named TweenConfig, so the handlers of your rules share it and you only edit one file.
---

# Tween config

[`tweenDefault`](/guide/transitions#tweensettings) and [`tweenOverrides`](/guide/transitions#overrides-for-state-changes)
are passed to every `animate` and `onTransition` connection. If each component writes its own, changing how your UI
feels means editing every component. Keep them in one ModuleScript instead. Components require it, and you only edit
that file.

## The module

Create a ModuleScript named **`TweenConfig`** in `ReplicatedStorage`, so components load it with
`require(ReplicatedStorage.TweenConfig)`. It returns the options that `animate` and `onTransition` take.

::: code-group

```luau [ReplicatedStorage/TweenConfig (ModuleScript)]
const VideState = require("@VideState")

const config: VideState.TransitionOptions = {
    -- The tween settings of every state change that no override matches.
    tweenDefault = {
        duration = 0.15,
        easing = "quadOut",
    },

    -- Tween settings for particular state changes.
    -- `from` and `to` name states. A side that is left out means every state.
    tweenOverrides = {
        {
            -- Pressing is quick and sharp.
            from = { "Idle", "Hovered" },
            to = { "Pressed" },
            tween = { duration = 0.05, easing = "linear" },
        },
        {
            -- Disabling is slow and soft, from any state.
            to = { "Disabled" },
            tween = { duration = 0.5, easing = "sineInOut" },
        },
    },
}

return config
```

:::

The state names in `from` and `to` must be states of the handler that uses the config. Use it with the handlers of rules
that have them, such as the rule below.

## Use it in a component

A component requires the module and passes it to `animate`. It has no tween numbers of its own. This rule has the
four states the config names, and each state holds a Vide source for each property:

::: code-group

```luau [StarterPlayerScripts/Button (LocalScript)]
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Vide = require("@Vide")
const VideState = require("@VideState")
const TweenConfig = require(ReplicatedStorage.TweenConfig)

const ButtonRule = VideState.rule({
    backgroundColor = VideState.color3(),
}, {
    name = "Button",
    allowedStateNames = { "Idle", "Hovered", "Pressed", "Disabled" },
})

const handler = ButtonRule.new({
    Idle = { backgroundColor = Vide.source(Color3.fromRGB(60, 60, 70)) },
    Hovered = { backgroundColor = Vide.source(Color3.fromRGB(80, 80, 95)) },
    Pressed = { backgroundColor = Vide.source(Color3.fromRGB(40, 40, 50)) },
    Disabled = { backgroundColor = Vide.source(Color3.fromRGB(35, 35, 35)) },
}, "Idle")

const animated = handler.animate(TweenConfig)

const button = Vide.create "TextButton" {
    BackgroundColor3 = animated.backgroundColor,
}
```

:::

`handler.setState("Pressed")` now fades over 0.05 seconds and `handler.setState("Disabled")` over 0.5 seconds. Every
other handler of `ButtonRule` makes the same `animate(TweenConfig)` call and fades the same way. See
[Components](/examples/components) for a complete button.
