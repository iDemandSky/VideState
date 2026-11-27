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

## Creating a rule <Badge type="tip" text="Added in 0.1.0" />

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

## Creating handlers from a rule <Badge type="tip" text="Added in 0.1.0" /> <Badge type="warning" text="Changed in 0.4.0" />

Call `new` on a rule that [`rule`](#creating-a-rule) has already returned. It is not a function of `VideState`.

```luau
Rule.new(
    states: { [string]: Sources<T> }, -- Vide sources for each state, keyed by state name
    initialState: string -- The state the handler starts in
) -> Handler<T>
```

Changed in 0.4.0: a handler takes no options, so `new` has only the states and the initial state. The tween
settings moved to [`onTransition`](/guide/handlers#ontransition) and [`animate`](/guide/handlers#animate).

Creates a [handler](/guide/handlers) from the rule. Every state must provide a Vide source for each
field in the rule, and each state's values are validated when `new` runs. A rule needs at least
two states.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `states` | `{ [string]: `[`Sources`](/guide/handlers#sources-1)`<T> }` | A dictionary of states. Each value is a record of Vide sources with one source per field. When `metadata.allowedStateNames` is set, every key must be in that list. |
| `initialState` | `string` | The name of the state the handler starts in. Must be a key of `states`. |

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
| <Badge type="danger" text="Error" /> | `allowedTransitions` names a state that is not one of the handler's states | `allowedTransitions "<state>" lists "<state>", which is not a state of the handler` |
| <Badge type="danger" text="Error" /> | `initialState` is not one of the states | `unknown initial state "<state>"` |
| <Badge type="danger" text="Error" /> | A third argument is given | `new takes only the states and the initial state. Pass tweenDefault to onTransition or animate instead` |

## Tags

Tags group rules, and are set in the [`tags`](#rulemetadata) field of the metadata. These methods
read and change a rule's tags after it was created. Tags are compared exactly as written, so they are
never trimmed or lowercased. [`info`](/guide/info) and the [`everyHandler`](/guide/every-handler)
filters read the tags each time they run, so a change reaches them at once.

### getTags <Badge type="tip" text="Added in 0.4.0" />

```luau
rule.getTags() -> { string }
```

Returns the rule's tags.

**Returns**

| Type | Description |
| --- | --- |
| `{ string }` | A frozen copy of the tags in the order they were added. It is empty when the rule has none. Later changes do not affect it, so call `getTags` again to read them. |

### hasTag <Badge type="tip" text="Added in 0.4.0" />

```luau
rule.hasTag(tag: string) -> boolean
```

Checks whether the rule has the tag.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `tag` | `string` | The tag to look for. |

**Returns**

| Type | Description |
| --- | --- |
| `boolean` | `true` when the rule has the exact tag, `false` when it does not. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `tag` is not a string | `Tag must be a string, got <type>` |

### addTags <Badge type="tip" text="Added in 0.4.0" />

```luau
rule.addTags(...: string) -> boolean
```

Adds tags to the rule.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `...` | `string` | The tags to add. At least one is required. A tag that is repeated in one call counts once. |

**Returns**

| Type | Description |
| --- | --- |
| `boolean` | `true` when at least one tag was new. `false` when the rule already had every tag. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | No tags are given | `addTags requires at least one tag` |
| <Badge type="danger" text="Error" /> | A tag is not a string | `Tag <index> must be a string, got <type>` |

### removeTags <Badge type="tip" text="Added in 0.4.0" />

```luau
rule.removeTags(...: string) -> boolean
```

Removes tags from the rule.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `...` | `string` | The tags to remove. At least one is required. |

**Returns**

| Type | Description |
| --- | --- |
| `boolean` | `true` when at least one tag was removed. `false` when the rule had none of them. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | No tags are given | `removeTags requires at least one tag` |
| <Badge type="danger" text="Error" /> | A tag is not a string | `Tag <index> must be a string, got <type>` |

## Types

### RuleMetadata <Badge type="tip" text="Added in 0.1.0" />

```luau
type RuleMetadata = {
    name: string, -- Unique name of the rule
    description: string?, -- Describes what the rule is for
    tags: { string }?, -- Groups rules together
    allowedStateNames: { string }?, -- Restricts the state names handlers may use
    allowedTransitions: { [string]: { string } }?, -- For a state, the only states it can change to
}
```

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | `string` | Yes | Must be unique across all rules. A duplicate raises an error. |
| `description` | `string` | No | Text describing the rule. |
| `tags` | `{ string }` | No | Strings for grouping rules. Tags are never formatted, so keep them consistent. Look them up with [`info`](/guide/info). |
| `allowedStateNames` | `{ string }` | No | When set, [handlers](/guide/handlers) reject any other state name. When omitted, every state name is allowed. |
| `allowedTransitions` | `{ [string]: { string } }` | No | <Badge type="tip" text="Added in 0.5.0" /> For a state, the only states it can change to. A state that is not listed can change to any state. See [Allowed state changes](#allowed-state-changes). |

#### Allowed state changes <Badge type="tip" text="Added in 0.5.0" />

By default a handler can change from any state to any state. `allowedTransitions` limits that. Each key is a state, and its
list holds the only states it can change to:

```luau
const ButtonRule = VideState.rule({
    backgroundColor = VideState.color3(),
}, {
    name = "Button",
    allowedStateNames = { "Idle", "Hovered", "Pressed", "Disabled" },
    allowedTransitions = {
        -- A disabled button can only become idle again.
        Disabled = { "Idle" },
    },
})
```

A [`setState`](/guide/handlers#setstate) to a state that the current state does not list raises an error, and the handler
stays where it was. No event runs and no transition starts.

```luau
handler.setState("Disabled")
handler.setState("Pressed")
-- Raises: cannot change state from "Disabled" to "Pressed". Allowed: "Idle"
```

- A state that is not a key can change to any state.
- Changing to the state the handler is already in does nothing, as before.
- The initial state is not checked, and the rule applies to every following change.
- The names must be states. With `allowedStateNames`, the rule checks them when it is made. Without it, each handler
  checks them against its own states when it is created.
- [`everyHandler.setState`](/guide/every-handler#setstate) checks every handler first, and none changes state if one is blocked.

### InferRule <Badge type="tip" text="Added in 0.1.0" />

```luau
type InferRule<R> = -- The value type of the rule R
```

Gives the value type of a rule. Use it instead of reading `_schema` directly, and pass the result to
[`VideState.Handler`](/guide/handlers#handler) to type a handler.

| Name | Type | Description |
| --- | --- | --- |
| `R` | `typeof(rule)` | The rule to read the value type from. |

### Rule <Badge type="tip" text="Added in 0.1.0" />

```luau
type Rule<Fields> = {
    _schema: Schema<Fields>, -- The schema built from the fields
    new: (states: { [string]: Sources<T> }, initialState: string) -> Handler<T>,
    getTags: () -> { string },
    hasTag: (tag: string) -> boolean,
    addTags: (...string) -> boolean,
    removeTags: (...string) -> boolean,
}
```

A rule returned by [`rule`](#creating-a-rule). It is frozen, so it cannot be changed after creation.

| Field | Type | Description |
| --- | --- | --- |
| `_schema` | [`Schema`](/guide/schemas#schema)`<Fields>` | The schema that validates each state. Pass the rule to [`InferRule`](#inferrule) instead of reading this directly. |
| `new` | `function` | Creates a [handler](/guide/handlers). See [`new`](#creating-handlers-from-a-rule). |
| `getTags` | `function` | Returns the rule's tags. See [`getTags`](#gettags). |
| `hasTag` | `function` | Checks whether the rule has a tag. See [`hasTag`](#hastag). |
| `addTags` | `function` | Adds tags to the rule. See [`addTags`](#addtags). |
| `removeTags` | `function` | Removes tags from the rule. See [`removeTags`](#removetags). |
