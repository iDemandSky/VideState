---
title: Rules
description: Define reusable rules from schema builders and metadata.
outline: [2, 3]
---

# Rules

A rule describes what [handlers](/guide/handlers) receive, so every handler created from it shares
the same fields. A rule is built from [schemas](/guide/schemas) and a metadata table. One rule can
create many handlers, and the handlers do not affect each other.

## Functions

### rule

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
| `Rule<Fields>` | A frozen table with the [`new`](#new) constructor and the `_schema` built from `fields`. |

**Errors**

- `Duplicate rule name: <name>` when a rule with the same `metadata.name` already exists.
- An error when a field is not a schema.

### new

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
| `states` | `{ [string]: Sources<T> }` | A dictionary of states. Each value is a record of Vide sources with one source per field. When `metadata.allowedStateNames` is set, every key must be in that list. |
| `initialState` | `string` | The name of the state the handler starts in. Must be a key of `states`. |
| `options` | [`HandlerOptions`](/guide/handlers#handleroptions)`?` | Optional. Settings for the handler. `onTransition` sets the easing, duration, and speed shared by its transition listeners. |

**Returns**

| Type | Description |
| --- | --- |
| `Handler<T>` | A new handler with its own state, sources, and cleanup. |

**Errors**

- A state is not a table of Vide sources.
- A field is missing from a state, or a state's values do not match the schema. The message names the state and the field.
- There are fewer than two states, or a state name is not in `allowedStateNames`.

### info.get

```luau
VideState.info.get(
    name: string -- The name the rule was registered with
) -> RuleMetadata?
```

Looks up the metadata of a registered rule. Returns `nil` when no rule has that name.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The `name` given in the rule's metadata. |

**Returns**

| Type | Description |
| --- | --- |
| `RuleMetadata?` | A frozen copy of the metadata, or `nil` when no rule is registered under `name`. |

## Types

### RuleMetadata

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
| `tags` | `{ string }` | No | Strings for grouping rules. |
| `allowedStateNames` | `{ string }` | No | When set, [handlers](/guide/handlers) reject any other state name. When omitted, every state name is allowed. |

### InferRule

```luau
type InferRule<R> = -- The value type of the rule R
```

Gives the value type of a rule. Use it instead of reading `_schema` directly, and pass the result to
[`VideState.Handler`](/guide/handlers#handler) to type a handler.

| Name | Type | Description |
| --- | --- | --- |
| `R` | `typeof(rule)` | The rule to read the value type from. |
