---
title: Handlers
description: Create independent handlers from a rule, with reactive sources and cleanup.
---

# Handlers

A handler is created from a [rule](/guide/rules) with `new`. Each handler owns its own current state,
sources, and cleanup.

```luau
const VideState = require("@VideState")
const Vide = require("@Vide")

local PanelRule = VideState.rule({
    visible = VideState.boolean(),
    order = VideState.integer({ min = 0 }),
}, { name = "Panel", allowedStateNames = { "Idle", "Active" } })

local panel = PanelRule.new({
    Idle = { visible = Vide.source(false), order = Vide.source(0) },
    Active = { visible = Vide.source(true), order = Vide.source(1) },
}, "Idle")

panel.setState("Active")
```

## Creating a handler

`PanelRule.new(states, initialState, options?)` takes a dictionary of Vide sources for each state,
keyed by state name. Every state must provide a source for each field in the schema, and each
state's values are validated when `new` runs. A rule needs at least two states.

Each call to `new` creates a separate handler. Handlers do not share state, so changing one does not
affect another. Different handlers may use different state names.

## Handler fields

| Field | Description |
| --- | --- |
| `sources` | Sources for each field in the schema. They read and write the active state's source, so pass them to Vide properties. |
| `currentState()` | Returns the name of the active state. |
| `setState(name)` | Switches to a state. Later reads and writes use that state's sources. |
| `onChange(callback)` | Runs when the state changes. See [Transitions](/guide/transitions). |
| `onTransition(callback, metadata?)` | Runs with the current value over time, with fields eased by an optional Ripple easing in `metadata.ripple`. See [Transitions](/guide/transitions). |

`currentState` is a function, so call it to read the state name:

```luau
print(panel.currentState()) -- "Active"
```

Writing to `sources` updates the source of the active state, so write to a state's own source to
change its values before switching to it.

## Typing a handler

`VideState.Handler<T>` types a handler. Pass it the value type from
[InferRule](/guide/rules#typing-a-rule) so the handler matches its rule.

```luau
type PanelHandler = VideState.Handler<VideState.InferRule<typeof(PanelRule)>>

local panel: PanelHandler = PanelRule.new(states, "Idle")
```

## Errors

`new` raises an error when a state is not a table of Vide sources, a field is missing, or a state's
values do not match the schema. The message names the state and field.

`setState` raises an error for an unknown state name or for a state whose values no longer match the
schema. A failed `setState` leaves the handler unchanged.
