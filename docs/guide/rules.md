---
title: Rules
description: Define reusable rules from schema builders and metadata.
outline: [2, 3]
---

# Rules

A rule describes what handlers should receive, so every handler created from it shares the same
fields. A rule takes a plain record of [schema builders](/guide/schemas) and a metadata table.

```luau
const VideState = require("@VideState")

local PanelRule = VideState.rule({
    visible = VideState.boolean(),
    order = VideState.integer({ min = 0 }),
    text = VideState.string({ maxLength = 100 }),
    alignment = VideState.enum("Left", "Center", "Right"),
}, { name = "Panel", allowedStateNames = { "Idle", "Active" } })
```

## Metadata

`VideState.rule(fields, metadata)` accepts these fields in the metadata table:

- `name`: required. Must be unique across all rules, because a duplicate name raises an error.
- `description`: optional text describing the rule.
- `tags`: optional array of strings for grouping rules.
- `allowedStateNames`: optional array of state names. When set, [handlers](/guide/handlers) reject any other state name.

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

## Creating handlers

A rule holds shared definitions only. Call `PanelRule.new(states, initialState)` to create a
[handler](/guide/handlers). Each handler owns its own state, so one rule can create many handlers
that do not affect each other.

## Typing a rule

`VideState.InferRule<rule>` gives the value type of a rule. Use it instead of reaching into `_schema`.

```luau
type PanelValues = VideState.InferRule<typeof(PanelRule)>
-- { visible: boolean, order: number, text: string, alignment: string }
```

Pass the result to `VideState.Handler` to type a handler. See
[Typing a handler](/guide/handlers#typing-a-handler).
