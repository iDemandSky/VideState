---
title: Info
description: Look up registered rules while debugging.
outline: [2, 3]
---

# Info

::: warning Debugging only
`VideState.info` exists to inspect registered rules while you debug. Do not use it to drive game
logic. Build features from [rules](/guide/rules) and [handlers](/guide/handlers) instead.
:::

Every [rule](/guide/rules) registers its [`RuleMetadata`](/guide/rules#rulemetadata) under its
`name` when it is created. Info reads that registry back. It never creates, changes, or removes a
rule.

## Functions

### get

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
| [`RuleMetadata`](/guide/rules#rulemetadata)`?` | A frozen copy of the metadata, or `nil` when no rule is registered under `name`. |

## Registration

[`VideState.rule`](/guide/rules#rule) registers each rule for you. Do not call `info.register`
yourself. It raises `Duplicate rule name: <name>` when a name is already registered, which is the
same error that `rule` raises for a duplicate name.
