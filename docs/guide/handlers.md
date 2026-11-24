---
title: Handlers
description: Create independent handlers from a rule, with reactive sources and cleanup.
outline: [2, 3]
---

# Handlers

A handler is created by calling [`new`](/guide/rules#creating-handlers-from-a-rule) on a [rule](/guide/rules#creating-a-rule), so create the rule first. Each handler owns its
own current state, sources, and cleanup. Handlers do not share state, so changing one does not affect
another, and different handlers may use different state names.

## Properties

### sources <Badge type="tip" text="Added in 0.1.0" />

```luau
Handler.sources: Sources<T>
```

A frozen record with one Vide source per field in the rule. Each source reads and writes the active
state's source, so pass them to Vide properties to bind them. When the state changes, the
bindings update automatically.

Writing to a source updates the source of the active state. To change another state's values before
switching to it, write to that state's own source.

## Functions

### currentState <Badge type="tip" text="Added in 0.1.0" />

```luau
Handler.currentState() -> string
```

Returns the name of the active state. It is a function, so call it to read the name.

**Returns**

| Type | Description |
| --- | --- |
| `string` | The name of the active state. |

### setState <Badge type="tip" text="Added in 0.1.0" />

```luau
Handler.setState(
    stateName: string -- The state to switch to
) -> ()
```

Switches to a state. Later reads and writes of [`sources`](#sources) use that state's sources, and
[`onChange`](#onchange) and [`onTransition`](#ontransition) listeners are called.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `stateName` | `string` | The name of a state passed to `new`. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `stateName` is not a string | `state name must be a string, got <type>` |
| <Badge type="danger" text="Error" /> | The state name is unknown | `unknown state "<state>"` |
| <Badge type="danger" text="Error" /> | The state's values no longer match the schema | `Invalid state "<state>":` followed by the schema issues |

A failed `setState` leaves the handler unchanged.

### onChange <Badge type="tip" text="Added in 0.1.0" />

```luau
Handler.onChange(
    callback: (
        from: T, -- A frozen copy of the previous state's values
        to: T -- A frozen copy of the next state's values
    ) -> ()
) -> Disconnect
```

Runs `callback` once each time the state changes. A listener only receives changes made after it
is registered.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | `(from: T, to: T) -> ()` | Called with the values of the previous and the next state. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving changes. |

### onTransition <Badge type="tip" text="Added in 0.1.0" /> <Badge type="warning" text="Changed in 0.2.0" />

```luau
Handler.onTransition(
    callback: (
        from: T, -- The previous state's values
        to: T, -- The next state's values
        current: T, -- The values to render on this frame
        alpha: number -- The eased progress, from 0 to 1
    ) -> (),
    options: TransitionOptions? -- Tween settings for this connection only
) -> Disconnect
```

Changed in 0.2.0: takes an optional `options` argument, and every connection tweens on its own.

Runs `callback` with a `current` value that moves from the previous state to the next one, and the
`alpha` that shows how far along it is. Each animatable field is tweened with
[Ripple](https://github.com/littensy/ripple). Fields that cannot be tweened, such as strings,
booleans, and enums, are not transitioned: they switch to their next value at the start of the transition. Each connection has its own tween. Its
settings come from `options`, and any setting it leaves out comes from the handler's
[`onTransition`](#handleroptions) option, then from the default. See [Transitions](/guide/transitions) for the full behavior.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | `(from: T, to: T, current: T, alpha: number) -> ()` | Called at the start of a transition and on every frame until the transition ends. |
| `options` | [`TransitionOptions`](/guide/transitions#transitionoptions)`?` | Optional. The easing, duration, and speed of this connection. Each field left out is inherited from the handler. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving updates. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onTransition callback must be a function` |
| <Badge type="danger" text="Error" /> | `options` is invalid | The same messages as the handler's [`onTransition`](/guide/rules#errors) option, such as `onTransition easing must be a known easing name` |

### pause <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.pause() -> ()
```

Pauses every transition of the handler at once, across all of its [`onTransition`](#ontransition)
connections. Each transition keeps its current values and its listeners are not called again until
[`resume`](#resume). Calling it while the handler is already paused does nothing.

A transition that starts while the handler is paused sends its first frame, then waits for `resume`.
See [Pausing](/guide/transitions#pausing) for how this differs from a `speed` of `0`.

### resume <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.resume() -> ()
```

Continues the transitions that [`pause`](#pause) stopped, from the values they had reached. Calling it
while the handler is not paused does nothing.

### onPause <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.onPause(
    callback: (
        startedAt: number -- The os.clock() time at which the most recent transition started
    ) -> ()
) -> Disconnect
```

Runs `callback` each time the handler goes from running to paused. A repeated [`pause`](#pause) call
does not run it again.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | [`OnPauseCallback`](#onpausecallback) | Called with the `os.clock()` time at which the most recent transition started. If no transition has started yet, it is the time of the `pause` call. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving pause events. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onPause callback must be a function` |

### onResume <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.onResume(
    callback: (
        startedAt: number -- The os.clock() time at which the most recent transition started
    ) -> ()
) -> Disconnect
```

Runs `callback` each time the handler goes from paused to running. A repeated [`resume`](#resume) call
does not run it again.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | [`OnResumeCallback`](#onresumecallback) | Called with the `os.clock()` time at which the most recent transition started. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving resume events. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onResume callback must be a function` |

## Types

### HandlerOptions <Badge type="tip" text="Added in 0.1.0" />

```luau
type HandlerOptions = {
    onTransition: TransitionOptions? -- Default tween settings of every onTransition connection
}
```

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `onTransition` | [`TransitionOptions`](/guide/transitions#transitionoptions) | No | Linear easing, `0.25` seconds, speed `1` | The default easing, duration, and speed of the handler's transition connections. A connection can override them. An invalid value raises an error when the handler is created. |

### Handler <Badge type="tip" text="Added in 0.1.0" />

```luau
type Handler<T> = {
    sources: Sources<T>,
    currentState: () -> string,
    setState: (stateName: string) -> (),
    onChange: (callback: OnChangeCallback<T>) -> Disconnect,
    onTransition: (callback: OnTransitionCallback<T>, options: TransitionOptions?) -> Disconnect,
    pause: () -> (),
    resume: () -> (),
    onPause: (callback: OnPauseCallback) -> Disconnect,
    onResume: (callback: OnResumeCallback) -> Disconnect,
}
```

The type of a handler. Pass it the value type from [`InferRule`](/guide/rules#inferrule) so the
handler matches its rule.

| Name | Type | Description |
| --- | --- | --- |
| `T` | `InferRule<typeof(rule)>` | The value type of the rule that created the handler. |

### Sources <Badge type="tip" text="Added in 0.1.0" />

```luau
type Sources<T> = -- A record of Vide sources, one per field of T
```

| Name | Type | Description |
| --- | --- | --- |
| `T` | `{ [string]: any }` | The value record. Each field becomes a `Source` of that field's type. |

### OnChangeCallback <Badge type="tip" text="Added in 0.1.0" />

```luau
type OnChangeCallback<T> = (from: T, to: T) -> ()
```

### OnTransitionCallback <Badge type="tip" text="Added in 0.1.0" />

```luau
type OnTransitionCallback<T> = (from: T, to: T, current: T, alpha: number) -> ()
```

| Name | Type | Description |
| --- | --- | --- |
| `from` | `T` | The previous state's values. |
| `to` | `T` | The next state's values. |
| `current` | `T` | The values to render on this frame. |
| `alpha` | `number` | The eased progress, from 0 to 1. With `back` and `elastic` easings it can go below 0 or above 1. See [alpha](/guide/transitions#alpha). |

### OnPauseCallback <Badge type="tip" text="Added in 0.2.0" />

```luau
type OnPauseCallback = (startedAt: number) -> ()
```

| Name | Type | Description |
| --- | --- | --- |
| `startedAt` | `number` | The `os.clock()` time at which the handler's most recent transition started. If no transition has started yet, it is the time of the `pause` call. |

### OnResumeCallback <Badge type="tip" text="Added in 0.2.0" />

```luau
type OnResumeCallback = (startedAt: number) -> ()
```

| Name | Type | Description |
| --- | --- | --- |
| `startedAt` | `number` | The `os.clock()` time at which the handler's most recent transition started. |

### Disconnect <Badge type="tip" text="Added in 0.1.0" />

```luau
type Disconnect = () -> ()
```

Removes the listener it was returned for. Calling it more than once has no effect.
