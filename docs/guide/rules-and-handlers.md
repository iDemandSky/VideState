---
title: Rules and handlers
description: Define reusable rules and create independent handlers with reactive sources.
---

# Rules and handlers

A rule captures one record schema and its shared definitions. Each handler
created from a rule owns its own current state and cleanup.

```luau
const VideState = require("@VideState")
const Vide = require("@packages/Vide")

local PanelRule = VideState.rule({
    visible = VideState.boolean(),
    order = VideState.integer({ min = 0 }),
}, { name = "Panel", allowedStateNames = { "Idle", "Active" } })

type PanelValues = VideState.Infer<typeof(PanelRule._schema)>
type PanelSources = VideState.Sources<PanelValues>

local panel = PanelRule.new({
    Idle = { visible = Vide.source(false), order = Vide.source(0) },
    Active = { visible = Vide.source(true), order = Vide.source(1) },
}, "Idle")

local sources: PanelSources = panel.sources
panel.setState("Active")
```

## Rule metadata

`VideState.rule(fields, metaData)` takes a plain record of schema builders and a
metadata table. `name` is required and must be unique across all rules, because
a duplicate name raises an error. `description` is optional text. `tags` is an
optional array of strings for grouping rules. `allowedStateNames` is an optional
array of state names; when set, `new` and `setState` reject any other state name.

```luau
local PanelRule = VideState.rule({
    visible = VideState.boolean(),
}, {
    name = "Panel",
    description = "A panel that can be shown or hidden",
    tags = { "ui" },
    allowedStateNames = { "Idle", "Active" },
})
```

## Creating a handler

`PanelRule.new(states, initialState, options?)` takes a dictionary of Vide sources
for each state, keyed by state name. Every state must provide a source for each
field in the schema, and each state's values are validated when `new` runs. A rule
needs at least two states.

Each call to `new` creates a separate handler. Handlers do not share state, so
changing one does not affect another. Different handlers may use different state
names.

## Handler fields

| Field | Description |
| --- | --- |
| `sources` | Sources for each field in the schema. They read and write the active state's source, so pass them to Vide properties. |
| `currentState()` | Returns the name of the active state. |
| `setState(name)` | Switches to a state. Later reads and writes use that state's sources. |
| `onChange(callback)` | Runs when the state changes. See [Transitions](/guide/transitions). |
| `onTransition(callback)` | Runs with an alpha value over time. See [Transitions](/guide/transitions). |

`currentState` is a function, so call it to read the state name:

```luau
print(panel.currentState()) -- "Active"
```

Writing to `sources` updates the source of the active state, so write to a
state's own source to change its values before switching to it.

## Errors

`new` raises an error when a state is not a table of Vide sources, a field is
missing, or a state's values do not match the schema. The message names the state
and field.

`setState` raises an error for an unknown state name or for a state whose values
no longer match the schema. A failed `setState` leaves the handler unchanged.
