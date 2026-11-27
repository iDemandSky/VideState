---
title: Tween config
description: Keep every tween setting in one ModuleScript named TweenConfig, so most components share it and you only edit one file.
---

# Tween config

[`tweenDefault`](/guide/transitions#tweensettings) and [`tweenOverrides`](/guide/transitions#overrides-for-state-changes)
are passed to every `animate` and `onTransition` connection. If each component writes its own, changing how your UI
feels means editing every component. Keep them in one ModuleScript instead. Components require it, and you only edit
that file.

## The module

Create a ModuleScript named **`TweenConfig`** in `ReplicatedStorage`, so components load it with
`require(ReplicatedStorage.TweenConfig)`. Everything you tune is in the two tables at the top.

```luau
-- ReplicatedStorage.TweenConfig
const VideState = require("@VideState")

-- The tween settings of every state change that no override matches.
const tweenDefault: VideState.TweenSettings = {
    duration = 0.15,
    easing = "quadOut",
}

-- Tween settings for particular state changes. Edit these.
-- `from` and `to` name states. A side that is left out means every state.
-- No two entries may match the same state change.
const tweenOverrides: { VideState.TweenOverride } = {
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
}

-- The names that the component has. `nil` means every state, so it stays `nil`.
const function filterNames(
    names: { string }?,
    states: { [string]: any }
): { string }?
    if names == nil then
        return nil
    end

    local kept = {}

    for _, name in names do
        if states[name] ~= nil then
            table.insert(kept, name)
        end
    end

    return kept
end

-- Whether the entry can match a state change: some state in `from` and a
-- different state in `to`. A side that is `nil` stands for every state.
const function matchesChange(
    from: { string }?,
    to: { string }?,
    states: { [string]: any }
): boolean
    local fromNames = from or {}
    local toNames = to or {}

    if from == nil then
        for name in states do
            table.insert(fromNames, name)
        end
    end

    if to == nil then
        for name in states do
            table.insert(toNames, name)
        end
    end

    for _, fromName in fromNames do
        for _, toName in toNames do
            if fromName ~= toName then
                return true
            end
        end
    end

    return false
end

-- Builds the options for one component. Pass it the states you give to `rule.new`.
-- A handler only accepts the states it has, so this drops the override names
-- the component does not use, and the entries that no longer match a state
-- change. That lets one module serve components with different states.
const function forStates(states: { [string]: any }): VideState.TransitionOptions
    local kept: { VideState.TweenOverride } = {}

    for _, override in tweenOverrides do
        local from = filterNames(override.from, states)
        local to = filterNames(override.to, states)

        local isEmpty = (from ~= nil and #from == 0) or (to ~= nil and #to == 0)

        if isEmpty or not matchesChange(from, to, states) then
            continue
        end

        table.insert(kept, { from = from, to = to, tween = override.tween })
    end

    return {
        tweenDefault = tweenDefault,
        tweenOverrides = kept,
    }
end

return table.freeze({
    tweenDefault = tweenDefault,
    tweenOverrides = tweenOverrides,
    forStates = forStates,
})
```

## Use it in a component

A component requires the module and passes `forStates` the same states it gives to `rule.new`. It has no tween
numbers of its own.

```luau
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const TweenConfig = require(ReplicatedStorage.TweenConfig)

const states = createStates(design)
const handler = ButtonRule.new(states, "Idle")

local animated = handler.animate(TweenConfig.forStates(states))
```

This is the button from [Components](/examples/components). Only the `handler.animate` line changes: the options come from
`TweenConfig` instead of an inline `tweenDefault`. A second component, such as a toggle with the states `Off` and `On`,
makes the same call. The `Pressed` and `Disabled` overrides name states it does not have, so `forStates` drops them and
the toggle uses `tweenDefault`.

## A component that differs

To change one setting for a single component, take the shared options and replace that part. `forStates` returns a new table each call, so this changes only this component:

```luau
const options = TweenConfig.forStates(states)

options.tweenDefault = { duration = 0.4, easing = "backOut" }

local animated = handler.animate(options)
```

This keeps the shared overrides and gives the component its own default.

## What to notice

- **The module is named `TweenConfig`.** Every component requires it by that name, so renaming it means updating every `require`.
- **You edit one file.** Change `tweenDefault` or an entry of `tweenOverrides` and every component that uses `forStates` follows.
- **Overrides cannot overlap.** Two entries that match the same state change raise one batched error when the connection is made, whatever their order.
- **Unknown states raise an error.** [`tweenOverrides`](/guide/transitions#tweenoverride) rejects a state the handler does not have, which is why `forStates` filters.
- **Keep the module a plain table.** It holds data, so a component can still replace a setting, and each connection builds its own tween from it.
