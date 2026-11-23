---
title: Info
description: Look up registered rules and their tags while debugging.
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

## Tags

Tags come from the `tags` field of a rule's metadata. VideState never formats them: it does not
trim, lowercase, or otherwise change a tag. `"Menu"`, `"menu"`, and `" menu "` are three different
tags. Keeping tags consistent is your responsibility.

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

### getAllRulesWithTags

```luau
VideState.info.getAllRulesWithTags(
    ...: string -- The tags a rule must have
) -> { RuleMetadata }
```

Returns every registered rule that has **all** of the given tags. Tags are matched exactly as
written.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `...` | `string` | The tags to look for. At least one is required. A rule must have every tag to be included. |

**Returns**

| Type | Description |
| --- | --- |
| [`{ RuleMetadata }`](/guide/rules#rulemetadata) | A frozen array of the matching rules' metadata, sorted by rule name. It is empty when no rule matches. |

**Errors**

- No tags are given.
- An argument is not a string.

### getAllTags

```luau
VideState.info.getAllTags() -> { string }
```

Returns every tag used by a registered rule.

**Returns**

| Type | Description |
| --- | --- |
| `{ string }` | A frozen array of distinct tags, sorted alphabetically. Rules without tags add nothing. |

### ruleHasTag

```luau
VideState.info.ruleHasTag(
    ruleName: string, -- The name the rule was registered with
    tag: string -- The tag to look for
) -> boolean
```

Checks whether a rule has a tag. The tag is matched exactly as written.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `ruleName` | `string` | The `name` given in the rule's metadata. |
| `tag` | `string` | The tag to look for. |

**Returns**

| Type | Description |
| --- | --- |
| `boolean` | `true` when the rule has the tag. `false` when it does not, or when no rule is registered under `ruleName`. |

**Errors**

- `ruleName` or `tag` is not a string.

## Registration

[`VideState.rule`](/guide/rules#rule) registers each rule for you. Do not call `info.register`
yourself. It raises `Duplicate rule name: <name>` when a name is already registered, which is the
same error that `rule` raises for a duplicate name.
