---
title: Rules and handlers
description: Define reusable rules and create independent handlers with reactive sources.
---

# Rules and handlers

A rule captures one record schema and its shared definitions. Each handler
created from a rule owns its own sources, current state, and cleanup.

```luau
const VideState = require("@VideState")

local PanelRule = VideState.rule(VideState.table({
    visible = VideState.boolean(),
    order = VideState.integer({ min = 0 }),
}))

type PanelValues = VideState.Infer<typeof(PanelRule.schema)>
type PanelSources = VideState.Sources<PanelValues>

local panel = PanelRule.new({
    Idle = { visible = false, order = 0 },
    Active = { visible = true, order = 1 },
}, "Idle")

local sources: PanelSources = panel.sources
panel.setState("Active")
```

## Creating a handler

`PanelRule.new(states, initialState, options?)` validates every state, including
the initial one, before creating sources. A rule needs at least two states.

Each call to `new` creates a separate handler. Handlers do not share state, so
changing one does not affect another.

## Handler fields

| Field | Description |
| --- | --- |
| `sources` | Vide sources for each field in the schema. Pass them to Vide properties. |
| `currentState()` | Returns the name of the active state. |
| `setState(name)` | Switches to a state and updates the sources. |
| `onChange(callback)` | Runs when the state changes. See [Transitions](/guide/transitions). |
| `onTransition(callback)` | Runs with an alpha value over time. See [Transitions](/guide/transitions). |

`currentState` is a function, so call it to read the state name:

```luau
print(panel.currentState()) -- "Active"
```

## Errors

Unknown state names and invalid state values raise errors before any source is
written, so a failed `setState` leaves the handler unchanged.

Each state's values are checked against the rule's schema when `new` runs.
