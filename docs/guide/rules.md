---
title: Rules
description: Define reusable rules from schema builders and metadata.
outline: [2, 3]
---

# Rules

A rule describes what [handlers](/guide/handlers) receive, so every handler created from it shares
the same fields. A rule is built from [schemas](/guide/schemas) and a metadata table. One rule can
create many handlers, and the handlers do not affect each other.

Using a rule takes two steps, and the order matters:

1. Create the rule once with [`VideState.rule`](#creating-a-rule).
2. Call [`new`](#creating-handlers-from-a-rule) on the rule it returns, once for each handler you need.

`rule` is a function on `VideState`. `new` is a method of the rule that `rule` returns, so it
does not exist until a rule has been created.

## Creating a rule

<Badge type="tip" text="Added in 0.1.0" />

```luau
VideState.rule<Fields>(
    fields: Fields, -- A record of schema builders, keyed by field name
    metadata: RuleMetadata -- Describes the rule and restricts its state names
) -> Rule<Fields>
```

Creates a rule and registers its metadata under `metadata.name`.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `fields` | `{ [string]: Schema<any> }` | One [schema](/guide/schemas) per field. The rule's value type is inferred from these schemas. |
| `metadata` | [`RuleMetadata`](#rulemetadata) | The rule's name and optional details. |

**Returns**

| Type | Description |
| --- | --- |
| [`Rule`](#rule)`<Fields>` | A frozen table with the [`new`](#creating-handlers-from-a-rule) constructor and the `_schema` built from `fields`. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | A rule with the same `metadata.name` already exists | `Duplicate rule name: <name>` |
| <Badge type="danger" text="Error" /> | `fields` is not a table | `expected a table of named field schemas` |

## Creating handlers from a rule

<Badge type="tip" text="Added in 0.1.0" />

Call `new` on a rule that [`rule`](#creating-a-rule) has already returned. It is not a function of `VideState`.

```luau
Rule.new(
    states: { [string]: Sources<T> }, -- Vide sources for each state, keyed by state name
    initialState: string, -- The state the handler starts in
    options: HandlerOptions? -- Optional handler settings
) -> Handler<T>
```

Creates a [handler](/guide/handlers) from the rule. Every state must provide a Vide source for each
field in the rule, and each state's values are validated when `new` runs. A rule needs at least
two states.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `states` | `{ [string]: `[`Sources`](/guide/handlers#sources-1)`<T> }` | A dictionary of states. Each value is a record of Vide sources with one source per field. When `metadata.allowedStateNames` is set, every key must be in that list. |
| `initialState` | `string` | The name of the state the handler starts in. Must be a key of `states`. |
| `options` | [`HandlerOptions`](/guide/handlers#handleroptions)`?` | Optional. Settings for the handler. `onTransition` sets the easing, duration, and speed shared by its transition listeners. |

**Returns**

| Type | Description |
| --- | --- |
| [`Handler`](/guide/handlers#handler)`<T>` | A new handler with its own state, sources, and cleanup. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `states` is not a table | `rule states must be a table` |
| <Badge type="danger" text="Error" /> | A state is not a table of Vide sources | `state "<state>" must be a table of sources` |
| <Badge type="danger" text="Error" /> | A field of a state is not a Vide source | `state "<state>" field "<field>" must be a Vide source` |
| <Badge type="danger" text="Error" /> | A state is missing a field | `state "<state>" is missing source for field "<field>"` |
| <Badge type="danger" text="Error" /> | A state's values do not match the schema | `Invalid state "<state>":` followed by the schema issues |
| <Badge type="danger" text="Error" /> | Fewer than two states | `rule requires at least 2 states` |
| <Badge type="danger" text="Error" /> | A state name is not in `allowedStateNames` | `state "<state>" is not in allowedStateNames` |
| <Badge type="danger" text="Error" /> | `initialState` is not one of the states | `unknown initial state "<state>"` |
| <Badge type="danger" text="Error" /> | `onTransition` is not a table | `onTransition options must be a table` |
| <Badge type="danger" text="Error" /> | `onTransition` has an unknown key | `onTransition options has an unknown key <key>` |
| <Badge type="danger" text="Error" /> | `onTransition.easing` is not a known easing name | `onTransition easing must be a known easing name` |
| <Badge type="danger" text="Error" /> | `onTransition.duration` is not a finite, non-negative number | `onTransition duration must be a finite non-negative number` |
| <Badge type="danger" text="Error" /> | `onTransition.speed` is not a source | `onTransition speed must be a source` |
| <Badge type="danger" text="Error" /> | `onTransition.speed` is negative | `onTransition speed must not be negative` |
| <Badge type="danger" text="Error" /> | `onTransition.speed` is not finite | `onTransition speed must be a finite non-negative number` |

## Types

### RuleMetadata

<Badge type="tip" text="Added in 0.1.0" />

```luau
type RuleMetadata = {
    name: string, -- Unique name of the rule
    description: string?, -- Describes what the rule is for
    tags: { string }?, -- Groups rules together
    allowedStateNames: { string }?, -- Restricts the state names handlers may use
}
```

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | `string` | Yes | Must be unique across all rules. A duplicate raises an error. |
| `description` | `string` | No | Text describing the rule. |
| `tags` | `{ string }` | No | Strings for grouping rules. Tags are never formatted, so keep them consistent. Look them up with [`info`](/guide/info). |
| `allowedStateNames` | `{ string }` | No | When set, [handlers](/guide/handlers) reject any other state name. When omitted, every state name is allowed. |

### InferRule

<Badge type="tip" text="Added in 0.1.0" />

```luau
type InferRule<R> = -- The value type of the rule R
```

Gives the value type of a rule. Use it instead of reading `_schema` directly, and pass the result to
[`VideState.Handler`](/guide/handlers#handler) to type a handler.

| Name | Type | Description |
| --- | --- | --- |
| `R` | `typeof(rule)` | The rule to read the value type from. |

### Rule

<Badge type="tip" text="Added in 0.1.0" />

```luau
type Rule<Fields> = {
    _schema: Schema<Fields>, -- The schema built from the fields
    new: (states: { [string]: Sources<T> }, initialState: string, options: HandlerOptions?) -> Handler<T>,
}
```

A rule returned by [`rule`](#creating-a-rule). It is frozen, so it cannot be changed after creation.

| Field | Type | Description |
| --- | --- | --- |
| `_schema` | [`Schema`](/guide/schemas#schema)`<Fields>` | The schema that validates each state. Pass the rule to [`InferRule`](#inferrule) instead of reading this directly. |
| `new` | `function` | Creates a [handler](/guide/handlers). See [`new`](#creating-handlers-from-a-rule). |
