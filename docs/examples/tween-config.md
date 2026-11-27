---
title: Tween config
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

```luau
-- ReplicatedStorage.TweenConfig
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

The state names in `from` and `to` must be states of the handler that uses the config. Use this one with the handlers of
rules that have them, such as the `Button` rule in [Components](/examples/components), which has `Idle`, `Hovered`,
`Pressed`, and `Disabled`.

## Use it in a component

A component requires the module and passes it to `animate`. It has no tween numbers of its own.

```luau
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const TweenConfig = require(ReplicatedStorage.TweenConfig)

const handler = ButtonRule.new(createStates(design), "Idle")

local animated = handler.animate(TweenConfig)
```

This is the button from [Components](/examples/components). Only the `handler.animate` line changes: the options come from
`TweenConfig` instead of an inline `tweenDefault`. Every other button made from `ButtonRule` makes the same call, so
`handler.setState("Pressed")` fades over 0.05 seconds and `handler.setState("Disabled")` over 0.5 seconds, for all of them.

## What to notice

- **The module is named `TweenConfig`.** Every component requires it by that name, so renaming it means updating every `require`.
- **You edit one file.** Change `tweenDefault` or an entry of `tweenOverrides` and every handler that uses it follows.
- **Overrides cannot overlap.** Two entries that match the same state change raise one batched error when the connection is made, whatever their order.
- **Each connection builds its own tween** from the shared settings, so sharing the module does not link the handlers.
