---
title: Schemas
description: Build and validate values with VideState schema builders.
outline: [2, 3]
---

# Schemas

Schema builders describe the shape of a value. Every builder returns a `Schema<T>` for a
Luau type `T`. Schemas are the field definitions that a [rule](/guide/rules) combines. Builders
validate their options when they are called, and an invalid option raises an error.

You do not call a schema yourself. Pass it as a field of a rule, and the rule checks the values of every state against
it when a handler is created and whenever the state changes. A value that does not match raises an error that names the
field and what was wrong.

## Primitives

### boolean <Badge type="tip" text="Added in 0.1.0" />

```luau
VideState.boolean() -> Schema<boolean>
```

Accepts `true` or `false`, and rejects every other type.

**Returns**

| Type | Description |
| --- | --- |
| `Schema``<boolean>` | A schema for booleans. |

### integer <Badge type="tip" text="Added in 0.1.0" />

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
| `options` | [`IntegerOptions`](#integeroptions)`?` | Optional. Bounds for the value. |
| `options.min` | `number?` | Optional. The smallest allowed value, inclusive. Must be an integer. No lower bound by default. |
| `options.max` | `number?` | Optional. The largest allowed value, inclusive. Must be an integer. No upper bound by default. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema``<number>` | A schema for whole numbers within the bounds. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `options` is not a table | `expected Integer options to be a table` |
| <Badge type="danger" text="Error" /> | `min` is not an integer | `Integer minimum must be a finite integer` |
| <Badge type="danger" text="Error" /> | `max` is not an integer | `Integer maximum must be a finite integer` |
| <Badge type="danger" text="Error" /> | `min` is greater than `max` | `Integer minimum must not exceed maximum` |

### float <Badge type="tip" text="Added in 0.1.0" />

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
| `options` | [`FloatOptions`](#floatoptions)`?` | Optional. Bounds and precision for the value. |
| `options.min` | `number?` | Optional. The smallest allowed value, inclusive. No lower bound by default. |
| `options.max` | `number?` | Optional. The largest allowed value, inclusive. No upper bound by default. |
| `options.step` | `number?` | Optional. A positive, finite number. Its decimal places set how many decimal places a value may have, so `0.01` allows up to two. No limit by default. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema``<number>` | A schema for finite numbers within the bounds and precision. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `options` is not a table | `expected Float options to be a table` |
| <Badge type="danger" text="Error" /> | `min` is not finite | `Float minimum must be finite` |
| <Badge type="danger" text="Error" /> | `max` is not finite | `Float maximum must be finite` |
| <Badge type="danger" text="Error" /> | `step` is not a positive, finite number | `Float step must be positive and finite` |
| <Badge type="danger" text="Error" /> | `step` has too many decimal places to validate | `Float step precision is too small to validate` |
| <Badge type="danger" text="Error" /> | `min` is greater than `max` | `Float minimum must not exceed maximum` |

### string <Badge type="tip" text="Added in 0.1.0" />

::: warning Strings are not transitioned
A `string` field cannot be tweened by [`onTransition`](/guide/handlers#ontransition). When the state
changes, it switches to the new text at the start of the transition. See
[Transitions](/guide/transitions).
:::

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
| `options` | [`StringOptions`](#stringoptions)`?` | Optional. Length limits for the value. |
| `options.maxLength` | `number?` | Optional. The maximum length, counted in Unicode code points rather than bytes. When set, strings with invalid UTF-8 are rejected. No limit by default. |
| `options.truncate` | `boolean?` | Optional. When `true`, longer strings are cut down to `maxLength` instead of rejected. Defaults to `false`. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema``<string>` | A schema for strings. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `options` is not a table | `expected String options to be a table` |
| <Badge type="danger" text="Error" /> | `maxLength` is not a non-negative integer | `String maxLength must be a finite integer greater than or equal to 0` |
| <Badge type="danger" text="Error" /> | `truncate` is not a boolean | `String truncate must be a boolean` |

### enum <Badge type="tip" text="Added in 0.1.0" />

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
| `Schema``<string>` | A schema that accepts one of the given strings. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | No values are given | `Enum requires at least one string value` |
| <Badge type="danger" text="Error" /> | An argument is not a string | `expected Enum argument <n> to be String, got <type>` |

### optional <Badge type="tip" text="Added in 0.1.0" />

```luau
VideState.optional(
    schema: Schema<T> -- The schema for the value when it is not nil
) -> Schema<T?>
```

Accepts `nil` and any value the inner schema accepts. A Vide source that holds `nil` is also accepted.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `schema` | `Schema``<T>` | The schema to apply when the value is not `nil`. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema``<T?>` | A schema that accepts `nil` or a value accepted by `schema`. |

### union <Badge type="tip" text="Added in 0.5.0" />

```luau
VideState.union(
    first: Schema<A>, -- The schema that is tried first
    second: Schema<B> -- The schema that is tried when the first one rejects the value
) -> Schema<A | B>
```

Accepts any value that `first` or `second` accepts. The first schema is tried first, and its result is used when it
accepts the value. A Vide source that holds a value of either schema is also accepted.

```luau
-- A width that is a number of pixels or the string "Auto".
const width = VideState.union(VideState.float({ min = 0 }), VideState.enum("Auto"))
```

To accept more than two schemas, nest the union: `VideState.union(a, VideState.union(b, c))`.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `first` | `Schema``<A>` | The schema to try first. |
| `second` | `Schema``<B>` | The schema to try when `first` rejects the value. |

**Returns**

| Type | Description |
| --- | --- |
| `Schema``<A | B>` | A schema that accepts a value accepted by either schema. |

**Errors**

| | When | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | An argument is not a schema | `expected the first union schema to be a schema`, and the same for the second |

A field of a union type tweens only when the old and new values have the same animatable type, such as two numbers. When
the types differ, such as a number and a string, the value switches at the start of the transition.

### table <Badge type="tip" text="Added in 0.1.0" />

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
| `Schema``<{ [string]: any }>` | A schema for tables with exactly these fields. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `fields` is not a table | `expected a table of named field schemas` |

### record <Badge type="tip" text="Added in 0.1.0" />

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
| `Schema``<{ [string]: any }>` | A schema for records with exactly these fields. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `fields` is not a table | `expected a table of field schemas` |
| <Badge type="danger" text="Error" /> | A field name is not a string | `expected a string field name, got <type>` |
| <Badge type="danger" text="Error" /> | A field is not a schema | `expected a schema for field "<field>"` |

## Roblox datatypes

Each of these builders takes no parameters and rejects every other type.

### color3 <Badge type="tip" text="Added in 0.1.0" />

```luau
VideState.color3() -> Schema<Color3>
```

Accepts a `Color3`.

### numberRange <Badge type="tip" text="Added in 0.4.0" />

```luau
VideState.numberRange() -> Schema<NumberRange>
```

Accepts a `NumberRange`. A [transition](/guide/transitions#animatable-fields) tweens its minimum and its
maximum, and keeps the minimum at or below the maximum when an easing overshoots.

### numberSequence <Badge type="tip" text="Added in 0.4.0" />

```luau
VideState.numberSequence() -> Schema<NumberSequence>
```

Accepts a `NumberSequence`, such as the `Transparency` of a `UIGradient`. A
[transition](/guide/transitions#animatable-fields) tweens it when both values have the same number of keypoints.
Otherwise it switches to the next value at the start.

### colorSequence <Badge type="tip" text="Added in 0.4.0" />

```luau
VideState.colorSequence() -> Schema<ColorSequence>
```

Accepts a `ColorSequence`, such as the `Color` of a `UIGradient`. A [transition](/guide/transitions#animatable-fields)
tweens it when both values have the same number of keypoints. Otherwise it switches to the next value at the start.

### udim <Badge type="tip" text="Added in 0.1.0" />

```luau
VideState.udim() -> Schema<UDim>
```

Accepts a `UDim`.

### udim2 <Badge type="tip" text="Added in 0.1.0" />

```luau
VideState.udim2() -> Schema<UDim2>
```

Accepts a `UDim2`.

### vector2 <Badge type="tip" text="Added in 0.1.0" />

```luau
VideState.vector2() -> Schema<Vector2>
```

Accepts a `Vector2`.

## Types

### Infer <Badge type="tip" text="Added in 0.1.0" />

```luau
type Infer<S> = -- The Luau type that the schema S accepts
```

Gives the Luau type that a schema accepts.

| Name | Type | Description |
| --- | --- | --- |
| `S` | `typeof(schema)` | The schema to read the accepted type from. |

### IntegerOptions <Badge type="tip" text="Added in 0.1.0" />

```luau
type IntegerOptions = {
    min: number?, -- Smallest allowed value, inclusive
    max: number?, -- Largest allowed value, inclusive
}
```

Options for [`integer`](#integer).

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `min` | `number` | No | No lower bound | The smallest allowed value, inclusive. Must be an integer. |
| `max` | `number` | No | No upper bound | The largest allowed value, inclusive. Must be an integer. |

### FloatOptions <Badge type="tip" text="Added in 0.1.0" />

```luau
type FloatOptions = {
    min: number?, -- Smallest allowed value, inclusive
    max: number?, -- Largest allowed value, inclusive
    step: number?, -- Sets how many decimal places a value may have
}
```

Options for [`float`](#float).

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `min` | `number` | No | No lower bound | The smallest allowed value, inclusive. |
| `max` | `number` | No | No upper bound | The largest allowed value, inclusive. |
| `step` | `number` | No | No limit | A positive, finite number. Its decimal places set how many decimal places a value may have, so `0.01` allows up to two. |

### StringOptions <Badge type="tip" text="Added in 0.1.0" />

```luau
type StringOptions = {
    maxLength: number?, -- Maximum length in Unicode code points
    truncate: boolean?, -- Cut longer strings instead of rejecting them
}
```

Options for [`string`](#string).

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `maxLength` | `number` | No | No limit | The maximum length, counted in Unicode code points rather than bytes. When set, strings with invalid UTF-8 are rejected. |
| `truncate` | `boolean` | No | `false` | When `true`, longer strings are cut down to `maxLength` instead of rejected. |
