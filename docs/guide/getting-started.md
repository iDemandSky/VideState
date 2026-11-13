---
title: Getting started
description: Install VideState and create your first rule and handler.
---

# Getting started

VideState validates source values and manages their state changes. Vide creates
the UI Instances; VideState owns the values those Instances bind to.

## Require the library

```luau
const VideState = require("@VideState")
```

## Create a rule and handler

A rule describes the shape of each state. A handler is created from a rule and
owns its own sources.

```luau
const VideState = require("@VideState")

local PanelRule = VideState.rule(VideState.table({
    visible = VideState.boolean(),
    order = VideState.integer({ min = 0 }),
}))

local panel = PanelRule.new({
    Idle = { visible = false, order = 0 },
    Active = { visible = true, order = 1 },
}, "Idle")

panel.setState("Active")
```

Pass `panel.sources.visible` to any Vide property to bind it. Setting a new
state updates the same sources, so those bindings update automatically.

## Next steps

- [Schemas](/guide/schemas) lists every builder and its options.
- [Rules and handlers](/guide/rules-and-handlers) covers states, sources, and errors.
- [Transitions](/guide/transitions) covers `onChange` and `onTransition`.
