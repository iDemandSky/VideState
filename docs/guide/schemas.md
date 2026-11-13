---
title: Schemas
description: Build and validate values with VideState schema builders.
---

# Schemas

Schemas describe the values a rule accepts. Each builder returns a schema that
can parse a value and report what is wrong with it.

## Builders

| Builder | Accepts | Options |
| --- | --- | --- |
| `boolean()` | `boolean` | None |
| `integer(options?)` | Whole numbers | `min`, `max` (inclusive) |
| `float(options?)` | Finite numbers, including integers | `min`, `max` (inclusive), `step` (limits decimal places) |
| `string(options?)` | Strings | `maxLength` (Unicode code points), `truncate` |
| `enum(...)` | One of the given strings | Values are listed as arguments |
| `table(fields)` | A table with the listed fields | Field names are strings, each with its own schema |
| `record(fields)` | Same as `table`, nested records allowed | Field names are strings, each with its own schema |
| `color3()` | `Color3` | None |
| `udim()` | `UDim` | None |
| `udim2()` | `UDim2` | None |
| `vector2()` | `Vector2` | None |

```luau
const VideState = require("@VideState")

local panelSchema = VideState.table({
    size = VideState.udim2(),
    color = VideState.color3(),
    visible = VideState.boolean(),
    transparency = VideState.float({ min = 0, max = 1 }),
    order = VideState.integer(),
    text = VideState.string({ maxLength = 100 }),
    alignment = VideState.enum("Left", "Center", "Right"),
})
```

`table` and `record` reject array definitions, missing fields, invalid values,
and extra fields.

## Parsing

`parse` returns a result with `ok`. When `ok` is `false`, `issues` lists each
problem with its `context` and `message`.

```luau
local result = panelSchema.parse(values)
if not result.ok then
    for _, issue in result.issues do
        warn(issue.context, issue.message)
    end
end
```

`unwrapParse` returns the value directly and throws when the input is invalid.

## Inferred types

Use `Infer` to get the Luau type a schema accepts:

```luau
type PanelValues = VideState.Infer<typeof(panelSchema)>
```

## Behavior notes

- `integer` requires a whole number. `float` accepts any finite number.
- Numeric bounds are inclusive.
- String length counts Unicode code points, not bytes.
- With `truncate = true`, parsing returns the shortened string and leaves the
  input unchanged.
- Builder options and field maps are copied when the schema is created, so
  changing them afterwards has no effect.
