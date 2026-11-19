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

Create a Vide source for each field in each state. A handler then follows the
active state's sources.

```luau
const VideState = require("@VideState")
const Vide = require("@packages/Vide")

local PanelRule = VideState.rule({
    visible = VideState.boolean(),
    order = VideState.integer({ min = 0 }),
}, { name = "Panel" })

local panel = PanelRule.new({
    Idle = { visible = Vide.source(false), order = Vide.source(0) },
    Active = { visible = Vide.source(true), order = Vide.source(1) },
}, "Idle")

panel.setState("Active")
```

Pass `panel.sources.visible` to any Vide property to bind it. Setting a new
state switches which sources the handler reads, so those bindings update
automatically.

## Next steps

- [Schemas](/guide/rule-and-schemas) lists every builder and its options.
- [Rules and handlers](/guide/rules-and-handlers) covers states, sources, and errors.
- [Transitions](/guide/transitions) covers `onChange` and `onTransition`.
