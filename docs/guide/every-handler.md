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
VideState.everyHandler.withTags("Menu").withoutStates("Closed").setState("Closed")
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

Each kind of filter has an inclusion and an exclusion: [`withTags`](#withtags) and [`withoutTags`](#withouttags),
[`withRule`](#withrule) and [`withoutRule`](#withoutrule), and [`withStates`](#withstates) and
[`withoutStates`](#withoutstates).

### Conflicts

A chain of filters that no handler could ever pass is a mistake, such as `withTags("Menu").withoutTags("Menu")`, so
a filter checks itself against the filters before it. When it conflicts, the filter raises **one** error that lists
every conflict, and it does so when you build the chain, not when you call an action.

```luau
-- Raises: everyHandler.withoutTags conflicts with an earlier filter: tag "Hud" is required by withTags; tag "Menu" is required by withTags. No handler could match
VideState.everyHandler.withTags("Menu", "Hud").withoutTags("Hud", "Menu")
```

These are the conflicts:

| Filter | Conflicts when |
| --- | --- |
| `withTags` | A tag is already in `withoutTags`. |
| `withoutTags` | A tag is already in `withTags`. |
| `withRule` | The rule is already in `withoutRule`, or `withRule` already asked for a different rule, because a handler has one rule. |
| `withoutRule` | The rule is already in `withRule`. |
| `withStates` | None of its states is allowed by an earlier `withStates`, or every state that is left is in `withoutStates`. |
| `withoutStates` | It leaves no state that an earlier `withStates` allows. |

Repeating a value, such as `withTags("Menu").withTags("Menu")`, is not a conflict. A `withStates` that keeps some
of its states, such as `withStates("Open", "Closed").withoutStates("Open")`, is not one either. VideState compares
what you wrote and does not read the tags of a rule you named, so `withRule("Panel").withoutTags("Menu")` is not
checked against the tags that `Panel` has.

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
| <Badge type="danger" text="Error" /> | A tag is in `withoutTags` | `everyHandler.withTags conflicts with an earlier filter: tag "<tag>" is excluded by withoutTags. No handler could match` |

### withoutTags <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.withoutTags(
    ...: string -- The tags a rule must not have
) -> EveryHandlerGroup
```

Narrows the scope to the handlers whose rule has **none** of the given tags. A handler is left out when its rule
has any one of them. Tags are matched exactly as written.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `...` | `string` | Required. One or more tags. A rule that has any one of them is left out. |

**Returns**

| Type | Description |
| --- | --- |
| [`EveryHandlerGroup`](#everyhandlergroup) | A group that acts on the matching handlers. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | No tag was given | `everyHandler.withoutTags requires at least one tag` |
| <Badge type="danger" text="Error" /> | A tag is not a string | `everyHandler.withoutTags tag <index> must be a string, got <type>` |
| <Badge type="danger" text="Error" /> | A tag is in `withTags` | `everyHandler.withoutTags conflicts with an earlier filter: tag "<tag>" is required by withTags. No handler could match` |

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
| <Badge type="danger" text="Error" /> | The rule is in `withoutRule` | `everyHandler.withRule conflicts with an earlier filter: rule "<rule>" is excluded by withoutRule. No handler could match` |
| <Badge type="danger" text="Error" /> | An earlier `withRule` asked for another rule | `everyHandler.withRule conflicts with an earlier filter: a handler has one rule, but withRule asks for <rule>, <rule>. No handler could match` |

### withoutRule <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.withoutRule(
    ruleName: string -- The name of the rule
) -> EveryHandlerGroup
```

Narrows the scope to the handlers that were **not** created from the rule with this name. Call it again to leave
out more rules.

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
| <Badge type="danger" text="Error" /> | `ruleName` is not a string | `everyHandler.withoutRule rule name must be a string, got <type>` |
| <Badge type="danger" text="Error" /> | The rule is in `withRule` | `everyHandler.withoutRule conflicts with an earlier filter: rule "<rule>" is required by withRule. No handler could match` |

### withStates <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.withStates(
    ...: string -- The states a handler may be in
) -> EveryHandlerGroup
```

Narrows the scope to the handlers whose [current state](/guide/handlers#currentstate) is **one of** the given names.
The state is read each time you call a function of the group. A second `withStates` narrows it further, to the
states that both calls allow.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `...` | `string` | Required. One or more state names. A handler in any one of them stays in scope. |

**Returns**

| Type | Description |
| --- | --- |
| [`EveryHandlerGroup`](#everyhandlergroup) | A group that acts on the matching handlers. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | No state name was given | `everyHandler.withStates requires at least one state name` |
| <Badge type="danger" text="Error" /> | A state name is not a string | `everyHandler.withStates state name <index> must be a string, got <type>` |
| <Badge type="danger" text="Error" /> | No state is left | `everyHandler.withStates conflicts with an earlier filter: <conflict>. No handler could match` |

### withoutStates <Badge type="tip" text="Added in 0.3.0" />

```luau
Group.withoutStates(
    ...: string -- The states a handler must not be in
) -> EveryHandlerGroup
```

Narrows the scope to the handlers whose current state is **none of** the given names. The state is read each time
you call a function of the group.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `...` | `string` | Required. One or more state names. A handler in any one of them is left out. |

**Returns**

| Type | Description |
| --- | --- |
| [`EveryHandlerGroup`](#everyhandlergroup) | A group that acts on the matching handlers. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | No state name was given | `everyHandler.withoutStates requires at least one state name` |
| <Badge type="danger" text="Error" /> | A state name is not a string | `everyHandler.withoutStates state name <index> must be a string, got <type>` |
| <Badge type="danger" text="Error" /> | It leaves no state that `withStates` allows | `everyHandler.withoutStates conflicts with an earlier filter: state "<state>" is required by withStates. No handler could match` |

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
| <Badge type="danger" text="Error" /> | The rule of one or more handlers does not let them change to the state | `everyHandler.setState cannot change to state "<stateName>" in <count> handlers: <rule> (<handlers>), ... No handler changed state` |
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
    withTags: (...string) -> EveryHandlerGroup, -- Keeps the handlers whose rule has all of the tags
    withoutTags: (...string) -> EveryHandlerGroup, -- Drops the handlers whose rule has any of the tags
    withRule: (ruleName: string) -> EveryHandlerGroup, -- Keeps the handlers of one rule
    withoutRule: (ruleName: string) -> EveryHandlerGroup, -- Drops the handlers of one rule
    withStates: (...string) -> EveryHandlerGroup, -- Keeps the handlers in any of the states
    withoutStates: (...string) -> EveryHandlerGroup, -- Drops the handlers in any of the states
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
