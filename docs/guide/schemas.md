---
title: Schemas
description: Build and validate values with VideState schema builders.
outline: [2, 3]
---

# Schemas

Schema builders describe the shape of a value. Every builder returns a [`Schema<T>`](#schema) for a
Luau type `T`. Schemas are the field definitions that a [rule](/guide/rules) combines. Builders
validate their options when they are called, and an invalid option raises an error.

## Primitives

### boolean

```luau
VideState.boolean() -> Schema<boolean>
```

Accepts `true` or `false`, and rejects every other type.

**Returns**

| Type | Description |
| --- | --- |
| `Schema<boolean>` | A schema for booleans. |

### integer

```luau
VideState.integer(
    options: {
        min: number?, -- Smallest allowed value, inclusive
        max: number? -- Largest allowed value, inclusive
    }?
) -> Schema<number>
```

Accepts finite whole numbers.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `options` | `IntegerOptions?` | Optional. Bounds for the value. |
| `options.min` | `number?` | Optional. The smallest allowed value, inclusive. Must be an integer. No lower bound by default. |
| `options.max` | `number?` | Optional. The largest allowed value, inclusive. Must be an integer. No upper bound by default. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema<number>` | A schema for whole numbers within the bounds. |

**Errors**

- `min` or `max` is not an integer, or `min` is greater than `max`.

### float

```luau
VideState.float(
    options: {
        min: number?, -- Smallest allowed value, inclusive
        max: number?, -- Largest allowed value, inclusive
        step: number? -- Sets how many decimal places a value may have
    }?
) -> Schema<number>
```

Accepts finite numbers, including whole numbers.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `options` | `FloatOptions?` | Optional. Bounds and precision for the value. |
| `options.min` | `number?` | Optional. The smallest allowed value, inclusive. No lower bound by default. |
| `options.max` | `number?` | Optional. The largest allowed value, inclusive. No upper bound by default. |
| `options.step` | `number?` | Optional. A positive, finite number. Its decimal places set how many decimal places a value may have, so `0.01` allows up to two. No limit by default. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema<number>` | A schema for finite numbers within the bounds and precision. |

**Errors**

- `step` is not a positive, finite number, or `min` is greater than `max`.

### string

```luau
VideState.string(
    options: {
        maxLength: number?, -- Maximum length in Unicode code points
        truncate: boolean? -- Cut longer strings instead of rejecting them
    }?
) -> Schema<string>
```

Accepts strings.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `options` | `StringOptions?` | Optional. Length limits for the value. |
| `options.maxLength` | `number?` | Optional. The maximum length, counted in Unicode code points rather than bytes. When set, strings with invalid UTF-8 are rejected. No limit by default. |
| `options.truncate` | `boolean?` | Optional. When `true`, longer strings are cut down to `maxLength` instead of rejected. Defaults to `false`. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema<string>` | A schema for strings. |

### enum

```luau
VideState.enum(
    ...: string -- The accepted values
) -> Schema<string>
```

Accepts only the strings passed as arguments. Matching is case-sensitive.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `...` | `string` | The accepted values. At least one is required. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema<string>` | A schema that accepts one of the given strings. |

**Errors**

- No values are given, or an argument is not a string.

### optional

```luau
VideState.optional(
    schema: Schema<T> -- The schema for the value when it is not nil
) -> Schema<T?>
```

Accepts `nil` and any value the inner schema accepts. A Vide source that holds `nil` is also accepted.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `schema` | `Schema<T>` | The schema to apply when the value is not `nil`. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema<T?>` | A schema that accepts `nil` or a value accepted by `schema`. |

### table

```luau
VideState.table(
    fields: { [string]: Schema<any> } -- One schema per field name
) -> Schema<{ [string]: any }>
```

Accepts a table with exactly the listed fields, each checked by its own schema. A missing field is
rejected unless its schema is [`optional`](#optional). Extra keys are rejected. The accepted type is
inferred from the field schemas, so [`Infer`](#infer) returns a table with the same field types.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `fields` | `{ [string]: Schema<any> }` | The schema for each field, keyed by field name. Keys must be strings, so arrays are rejected. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema<{ [string]: any }>` | A schema for tables with exactly these fields. |

### record

```luau
VideState.record(
    fields: { [string]: Schema<any> } -- One schema per field name
) -> Schema<{ [string]: any }>
```

Accepts the same values as [`table`](#table), and its type is inferred from the field schemas. Each
field is checked when the record is created, so a field that is not a schema fails early. Fields
can be any schema, including another record.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `fields` | `{ [string]: Schema<any> }` | The schema for each field, keyed by field name. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema<{ [string]: any }>` | A schema for records with exactly these fields. |

**Errors**

- A field is not a schema.

## Roblox datatypes

Each of these builders takes no parameters and rejects every other type.

### color3

```luau
VideState.color3() -> Schema<Color3>
```

Accepts a `Color3`.

### udim

```luau
VideState.udim() -> Schema<UDim>
```

Accepts a `UDim`.

### udim2

```luau
VideState.udim2() -> Schema<UDim2>
```

Accepts a `UDim2`.

### vector2

```luau
VideState.vector2() -> Schema<Vector2>
```

Accepts a `Vector2`.

## Schema

### parse

```luau
Schema.parse(
    value: unknown -- The value to check
) -> ParseResult<T>
```

Checks a value against the schema without raising an error.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `value` | `unknown` | The value to validate. |

**Returns**

| Type | Description |
| --- | --- |
| `{ ok: true, value: T }` | The value is valid. `value` is the accepted value, which can differ from the input, for example when a string is truncated. |
| `{ ok: false, issues: { ParseIssue } }` | The value is invalid. `issues` lists what was wrong. |

## Types

### Infer

```luau
type Infer<S> = -- The Luau type that the schema S accepts
```

Gives the Luau type that a schema accepts.

| Name | Type | Description |
| --- | --- | --- |
| `S` | `typeof(schema)` | The schema to read the accepted type from. |
