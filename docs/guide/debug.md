---
title: Debug view
description: Track handlers and watch their states and transitions in a live view.
outline: [2, 3]
---

# Debug view

::: warning Debugging only
`VideState.debug` exists to inspect handlers while you develop. Do not use it to drive game logic.
:::

The debug tools show what your handlers are doing: their state, whether a transition is running or paused, and
how many `onTransition` connections they have. Tracking is opt-in, so a handler only shows up after you pass it to
[`track`](#track).

```luau
const untrack = VideState.debug.track(panel, "Main panel")
```

[`view`](#view) shows the tracked handlers in a list that refreshes while it exists. Mount it in a UI Labs story,
or in a debug screen in your game. The repository has a story in `stories/DebugView.story.luau` that you can copy.

## Functions

### track <Badge type="tip" text="Added in 0.2.0" />

```luau
VideState.debug.track(
    handler: Handler<T>, -- The handler to list
    label: string? -- The name to list it under
) -> Disconnect
```

Lists a handler in [`list`](#list) and the [`view`](#view), under `label` or the name of its rule. Tracking a
handler again changes its label. A tracked handler stays listed until you call the returned function, or until it is
[destroyed](/guide/handlers#destroy).

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `handler` | [`Handler<T>`](/guide/handlers#handler) | A handler created by a rule. |
| `label` | `string?` | Optional. The name to list it under. Defaults to the rule name. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](/guide/handlers#disconnect) | Call it to stop listing the handler. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `handler` is not a handler | `debug.track expects a handler` |
| <Badge type="danger" text="Error" /> | `label` is not a string | `debug.track label must be a string` |

### snapshot <Badge type="tip" text="Added in 0.2.0" />

```luau
VideState.debug.snapshot(
    handler: Handler<T> -- The handler to read
) -> DebugSnapshot
```

Reads what a handler looks like right now, whether or not it is tracked.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `handler` | [`Handler<T>`](/guide/handlers#handler) | A handler created by a rule. |

**Returns**

| Type | Description |
| --- | --- |
| [`DebugSnapshot`](#debugsnapshot) | The handler's state at this moment. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `handler` is not a handler | `debug.snapshot expects a handler` |

### list <Badge type="tip" text="Added in 0.2.0" />

```luau
VideState.debug.list() -> { DebugSnapshot }
```

Reads every tracked handler, in the order they were first tracked. Destroyed handlers are left out and stop being
tracked.

**Returns**

| Type | Description |
| --- | --- |
| `{ `[`DebugSnapshot`](#debugsnapshot)` }` | One snapshot per tracked handler. |

### view <Badge type="tip" text="Added in 0.2.0" />

```luau
VideState.debug.view() -> Frame
```

Creates a Vide component that lists the tracked handlers, one line each, such as
`Main panel  Active  running 0.42 s  2 connections`. It refreshes ten times a second while it exists. Call it inside a
Vide scope, such as `Vide.mount`, `Vide.root`, or a UI Labs story, so its refresh stops when the scope is destroyed.

**Returns**

| Type | Description |
| --- | --- |
| `Frame` | The list, sized to fill its parent. |

## Types

### DebugSnapshot <Badge type="tip" text="Added in 0.2.0" />

```luau
type DebugSnapshot = {
    label: string, -- The label passed to track, or the rule name
    rule: string, -- The name of the rule that created the handler
    state: string, -- The active state
    connections: number, -- How many onTransition connections the handler has
    isRunning: boolean, -- Whether a transition is running
    isPaused: boolean, -- Whether the handler is paused
    isDestroyed: boolean, -- Whether the handler was destroyed
    startedAt: number?, -- When the most recent transition started
}
```

| Field | Type | Description |
| --- | --- | --- |
| `label` | `string` | The label passed to [`track`](#track), or the rule name. |
| `rule` | `string` | The name of the rule that created the handler. |
| `state` | `string` | The active state. |
| `connections` | `number` | How many [`onTransition`](/guide/handlers#ontransition) connections the handler has. |
| `isRunning` | `boolean` | Whether a transition is running. |
| `isPaused` | `boolean` | Whether the handler is [paused](/guide/handlers#pause). |
| `isDestroyed` | `boolean` | Whether the handler was [destroyed](/guide/handlers#destroy). |
| `startedAt` | `number?` | The `os.clock()` time at which the most recent transition started, or `nil` before the first one. |
