---
title: Schemas
description: Build and validate values with VideState schema builders.
outline: [2, 3]
---

# Rule

Rules describe what handlers should receive. This is to make the state sources consistent.
A rule takes a plain record of schema builders and a metadata table. `name` is required
and must be unique across all rules; `allowedStateNames` is optional.

```luau
const VideState = require("@VideState")

const rule = VideState.rule({
    visible = VideState.boolean(),
}, { name = "Panel", allowedStateNames = { "Idle", "Active" } })
```

## Usage

```luau
const VideState = require("@VideState")

local panelFields = {
    size = VideState.udim2(),
    color = VideState.color3(),
    visible = VideState.boolean(),
    transparency = VideState.float({ min = 0, max = 1 }),
    order = VideState.integer(),
    text = VideState.string({ maxLength = 100 }),
    alignment = VideState.enum("Left", "Center", "Right"),
}
local PanelRule = VideState.rule(panelFields, { name = "PanelUsage" })
```

## Schemas

Schema builders describe the shape of a value. Every builder returns a schema for a Luau type `T`.
Call `parse(value)` on any schema to check a value. The result's `ok` field is `true` when the
value is valid.

### boolean

```luau
VideState.boolean(): Schema<boolean>
```

Accepts `true` or `false`, and rejects every other type.

```luau
local schema = VideState.boolean()

schema.parse(true).ok -- true
schema.parse("true").ok -- false
```

### integer

```luau
VideState.integer(options: { min: number?, max: number? }?): Schema<number>
```

Accepts finite whole numbers.

Options:
- `min`: smallest allowed value, inclusive. Must be an integer.
- `max`: largest allowed value, inclusive. Must be an integer.

```luau
local schema = VideState.integer({ min = 0, max = 10 })

schema.parse(5).ok -- true
schema.parse(5.5).ok -- false
schema.parse(11).ok -- false
```

### float

```luau
VideState.float(options: { min: number?, max: number?, step: number? }?): Schema<number>
```

Accepts finite numbers, including whole numbers.

Options:
- `min`: smallest allowed value, inclusive.
- `max`: largest allowed value, inclusive.
- `step`: a positive, finite number. Its decimal places set how many decimal places a value may have. For example, `step = 0.01` allows up to two decimal places.

```luau
local schema = VideState.float({ min = 0, max = 1, step = 0.01 })

schema.parse(0.25).ok -- true
schema.parse(0.125).ok -- false
schema.parse(1.5).ok -- false
```

### string

```luau
VideState.string(options: { maxLength: number?, truncate: boolean? }?): Schema<string>
```

Accepts strings.

Options:
- `maxLength`: maximum length, counted in Unicode code points rather than bytes. When set, strings with invalid UTF-8 are rejected.
- `truncate`: when `true`, longer strings are cut down to `maxLength` instead of rejected.

```luau
local schema = VideState.string({ maxLength = 5 })
local truncated = VideState.string({ maxLength = 5, truncate = true })

schema.parse("hello").ok -- true
schema.parse("hello world").ok -- false
truncated.parse("hello world").value -- "hello"
```

### enum

```luau
VideState.enum(...: string): Schema<string>
```

Accepts only the strings passed as arguments. At least one string is required, and matching is case-sensitive.

```luau
local schema = VideState.enum("Left", "Center", "Right")

schema.parse("Center").ok -- true
schema.parse("center").ok -- false
```

### optional

```luau
VideState.optional(schema: Schema<T>): Schema<T?>
```

Accepts `nil` and any value the inner schema accepts. A Vide source that holds `nil` is also accepted.

```luau
local schema = VideState.optional(VideState.string())

schema.parse("hello").ok -- true
schema.parse(nil).ok -- true
schema.parse(123).ok -- false
```

### table

```luau
VideState.table(fields: { [string]: Schema<any> }): Schema<...>
```

Accepts a table with exactly the listed fields, each checked by its own schema. A missing field is
rejected unless its schema is `optional`. Extra keys are rejected. The accepted type is inferred from
the field schemas, so `Infer` returns a table with the same field types.

```luau
local schema = VideState.table({
    name = VideState.string(),
    age = VideState.optional(VideState.integer({ min = 0 })),
})

schema.parse({ name = "John" }).ok -- true
schema.parse({ name = "John", age = 30 }).ok -- true
schema.parse({ name = "John", lastName = "Doe" }).ok -- false
schema.parse({ age = 30 }).ok -- false
```

### record

```luau
VideState.record(fields: { [string]: Schema<any> }): Schema<...>
```

Accepts the same values as [table](#table), and its type is inferred from the field schemas. Each
field is checked when the record is created, so a field that is not a schema fails early. Fields can
be any schema, including another record.

```luau
local schema = VideState.record({
    position = VideState.record({
        x = VideState.float(),
        y = VideState.float(),
    }),
})

schema.parse({ position = { x = 1, y = 2 } }).ok -- true
schema.parse({ position = { x = 1 } }).ok -- false
```

### color3

```luau
VideState.color3(): Schema<Color3>
```

Accepts a `Color3`, and rejects every other type.

```luau
local schema = VideState.color3()

schema.parse(Color3.new(1, 0, 0)).ok -- true
schema.parse("red").ok -- false
```

### udim

```luau
VideState.udim(): Schema<UDim>
```

Accepts a `UDim`, and rejects every other type.

```luau
local schema = VideState.udim()

schema.parse(UDim.new(0, 10)).ok -- true
schema.parse(10).ok -- false
```

### udim2

```luau
VideState.udim2(): Schema<UDim2>
```

Accepts a `UDim2`, and rejects every other type.

```luau
local schema = VideState.udim2()

schema.parse(UDim2.fromOffset(100, 50)).ok -- true
schema.parse(Vector2.new(100, 50)).ok -- false
```

### vector2

```luau
VideState.vector2(): Schema<Vector2>
```

Accepts a `Vector2`, and rejects every other type.

```luau
local schema = VideState.vector2()

schema.parse(Vector2.new(1, 2)).ok -- true
schema.parse({ x = 1, y = 2 }).ok -- false
```

## Infer

`VideState.Infer<schema>` gives the Luau type that a schema accepts.

```luau
local panelSchema = VideState.table({
    visible = VideState.boolean(),
    order = VideState.integer(),
})

type Panel = VideState.Infer<typeof(panelSchema)>
-- { visible: boolean, order: number }
```
