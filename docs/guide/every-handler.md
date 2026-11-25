---
title: Every handler
description: Control and query every handler at once, or the handlers that match a filter.
outline: [2, 3]
---

# Every handler

`VideState.everyHandler` acts on many handlers with one call. It acts on every [handler](/guide/handlers) that
exists, or on the ones that match a [filter](#filters). Use it for settings and effects that belong to the whole
game, such as a pause menu, a game-wide animation speed, closing every menu, or skipping every animation on screen.

```luau
VideState.everyHandler.scaleSpeed({ speed = 0.5 }) -- slow motion for everything
VideState.everyHandler.pause() -- pause every handler
VideState.everyHandler.finish() -- end every running transition

-- Only some handlers: narrow the scope with filters, and chain as many as you need.
VideState.everyHandler.withTags("Menu").inState("Open").setState("Closed")
```

`everyHandler` and every filtered scope have the same functions, called a [group](#everyhandlergroup). A group
looks its handlers up each time you call a function, so a handler created later is included, and a handler that
changed state since the last call is matched by its new state.

Each action calls the handler's own function of the same name, so every handler fires its own events, such as
[`onPause`](/guide/handlers#onpause) and [`onFinish`](/guide/handlers#onfinish). A handler that has been
[destroyed](/guide/handlers#destroy) leaves the list.

If a callback of one handler raises an error, the other handlers still run, and the first error is raised
once all of them have run.

## Filters

A filter returns a new group that is narrower than the one it was called on. Filters are combined with "and":
a handler is in scope only when it passes every filter in the chain. Calling a filter does not look anything up
yet, so you can keep a group in a variable and use it later.

### withTags <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.withTags(
    ...: string -- The tags a rule must have
) -> EveryHandlerGroup
```

Narrows the scope to the handlers whose rule has **all** of the given tags. Tags come from the `tags` of the
rule's [metadata](/guide/rules#rulemetadata) and are matched exactly as written, as in
[`getAllRulesWithTags`](/guide/info#getallruleswithtags).

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `...` | `string` | Required. One or more tags. A rule must have every one of them. |

**Returns**

| Type | Description |
| --- | --- |
| [`EveryHandlerGroup`](#everyhandlergroup) | A group that acts on the matching handlers. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | No tag was given | `everyHandler.withTags requires at least one tag` |
| <Badge type="danger" text="Error" /> | A tag is not a string | `everyHandler.withTags tag <index> must be a string, got <type>` |

### withRule <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.withRule(
    ruleName: string -- The name of the rule
) -> EveryHandlerGroup
```

Narrows the scope to the handlers created from the rule with this name. A name that no rule has matches no handler.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `ruleName` | `string` | Required. The `name` given in the rule's metadata. |

**Returns**

| Type | Description |
| --- | --- |
| [`EveryHandlerGroup`](#everyhandlergroup) | A group that acts on the matching handlers. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `ruleName` is not a string | `everyHandler.withRule rule name must be a string, got <type>` |

### inState <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.inState(
    stateName: string -- The name of the state
) -> EveryHandlerGroup
```

Narrows the scope to the handlers whose [current state](/guide/handlers#currentstate) is `stateName`. The state is
read each time you call a function of the group.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `stateName` | `string` | Required. The state a handler must be in. |

**Returns**

| Type | Description |
| --- | --- |
| [`EveryHandlerGroup`](#everyhandlergroup) | A group that acts on the matching handlers. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `stateName` is not a string | `everyHandler.inState state name must be a string, got <type>` |

## Actions

### scaleSpeed <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.scaleSpeed(
    options: ScaleSpeedOptions -- How much to scale the speed of the handlers in scope
) -> ()
```

Speeds up or slows down the handlers in scope. It multiplies with the scale of each handler (see the handler's
[`scaleSpeed`](/guide/handlers#scalespeed)) and with each connection's own `speed`, so the speed of a
connection is `global scale × handler scale × connection speed`.

On `everyHandler` itself, the scale applies by default to the transitions that are running now and to every
transition that starts later, including those of handlers created later, until you call `scaleSpeed` again. A
`speed` of `1` removes it. With `once = true` it scales only the transitions that are running now: each handler goes
back to normal speed at its next `setState`, and handlers created later are not affected.

On a filtered group, `scaleSpeed` calls [`scaleSpeed`](/guide/handlers#scalespeed) on each handler in scope. A
scale without `once` then reaches only the handlers that exist now, and it replaces the scale that handler had
set itself.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `options` | [`ScaleSpeedOptions`](/guide/handlers#scalespeedoptions) | Required. The speed scale, and whether it applies once. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `options` is not a table | `everyHandler.scaleSpeed options must be a table` |
| <Badge type="danger" text="Error" /> | `options` has an unknown key | `everyHandler.scaleSpeed options has an unknown key <key>` |
| <Badge type="danger" text="Error" /> | `options.speed` is not a finite number above 0 | `everyHandler.scaleSpeed speed must be a finite number above 0` |
| <Badge type="danger" text="Error" /> | `options.once` is not a boolean | `everyHandler.scaleSpeed once must be a boolean` |

### pause <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.pause() -> ()
```

Calls [`pause`](/guide/handlers#pause) on every handler in scope. It reaches the handlers that exist when you call
it, so a handler created while everything is paused is not paused.

### resume <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.resume() -> ()
```

Calls [`resume`](/guide/handlers#resume) on every handler in scope.

### finish <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.finish() -> ()
```

Calls [`finish`](/guide/handlers#finish) on every handler in scope: each one sends its last frame before
`finish` returns, and then fires its own `onFinish`.

### setState <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.setState(
    stateName: string, -- The state to change to
    options: SetStateOptions? -- The same options as the handler's setState
) -> ()
```

Calls [`setState`](/guide/handlers#setstate) on every handler in scope.

A rule decides which state names its handlers have, so some handlers in scope can lack `stateName`. VideState
checks all of them first. If any lack it, `setState` raises **one** error that lists every rule that is missing
the state, with how many of its handlers are in scope, and **no handler changes state**. Narrow the scope with
a filter, such as [`withRule`](#withrule) or [`withTags`](#withtags), until every handler in it has the state.

```luau
-- Raises: everyHandler.setState state "Closed" is missing in 3 handlers: Dialog (1), Panel (2). No handler changed state
VideState.everyHandler.setState("Closed")
```

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `stateName` | `string` | Required. The name of the state. |
| `options` | [`SetStateOptions`](/guide/handlers#setstateoptions)`?` | Optional. The same options as the handler's `setState`, such as `instant`. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `stateName` is not a string | `everyHandler.setState state name must be a string, got <type>` |
| <Badge type="danger" text="Error" /> | One or more handlers in scope lack the state | `everyHandler.setState state "<stateName>" is missing in <count> handlers: <rule> (<handlers>), ... No handler changed state` |

An invalid `options` raises the errors of the handler's [`setState`](/guide/handlers#setstate).

### destroy <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.destroy() -> ()
```

Calls [`destroy`](/guide/handlers#destroy) on every handler in scope. Each one stops its transitions silently,
removes its listeners, and raises an error on its next `setState`. A destroyed handler leaves the list of
handlers, so a later call skips it.

On `everyHandler` itself this ends every handler in the game, so use it when you tear everything down, such as when
a test ends. To destroy only some handlers, use a filter.

## Queries

### count <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.count() -> number
```

**Returns**

| Type | Description |
| --- | --- |
| `number` | How many handlers are in scope. |

### isAnyRunning <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.isAnyRunning() -> boolean
```

**Returns**

| Type | Description |
| --- | --- |
| `boolean` | `true` when at least one handler in scope has a running transition. `false` when none does, and when the scope is empty. |

### isAnyPaused <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.isAnyPaused() -> boolean
```

**Returns**

| Type | Description |
| --- | --- |
| `boolean` | `true` when at least one handler in scope is paused. `false` when none is, and when the scope is empty. |

## Types

### EveryHandlerGroup <Badge type="tip" text="Added in 0.3.0" />

```luau
type EveryHandlerGroup = {
    withTags: (...string) -> EveryHandlerGroup, -- Narrows the scope by the tags of the rule
    withRule: (ruleName: string) -> EveryHandlerGroup, -- Narrows the scope to one rule
    inState: (stateName: string) -> EveryHandlerGroup, -- Narrows the scope by the current state
    scaleSpeed: (options: ScaleSpeedOptions) -> (), -- Scales the speed of the handlers in scope
    pause: () -> (), -- Pauses the handlers in scope
    resume: () -> (), -- Resumes the handlers in scope
    finish: () -> (), -- Finishes the transitions of the handlers in scope
    setState: (stateName: string, options: SetStateOptions?) -> (), -- Changes the state of the handlers in scope
    destroy: () -> (), -- Destroys the handlers in scope
    count: () -> number, -- How many handlers are in scope
    isAnyRunning: () -> boolean, -- Whether any handler in scope has a running transition
    isAnyPaused: () -> boolean, -- Whether any handler in scope is paused
}
```

The functions of `everyHandler`, and of every group that a filter returns. Each one is described above.
