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

### sources

```luau
Handler.sources: Sources<T>
```

A frozen record with one Vide source per field in the rule. Each source reads and writes the active
state's source, so pass them to Vide properties to bind them. When the state changes, the
bindings update automatically.

Writing to a source updates the source of the active state. To change another state's values before
switching to it, write to that state's own source.

## Functions

### currentState

```luau
Handler.currentState() -> string
```

Returns the name of the active state. It is a function, so call it to read the name.

**Returns**

| Type | Description |
| --- | --- |
| `string` | The name of the active state. |

### setState

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

### onChange

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

### onTransition

```luau
Handler.onTransition(
    callback: (
        from: T, -- The previous state's values
        to: T, -- The next state's values
        current: T, -- The values to render on this frame
        alpha: number -- The eased progress, from 0 to 1
    ) -> ()
) -> Disconnect
```

Runs `callback` with a `current` value that moves from the previous state to the next one, and the
`alpha` that shows how far along it is. Each animatable field is tweened with
[Ripple](https://github.com/littensy/ripple). Fields that cannot be tweened, such as booleans,
strings, and enums, switch to their next value at the start of the transition. The tween settings
come from the handler's [`onTransition` option](#handleroptions), so every listener of a handler
sees the same values at the same time. See [Transitions](/guide/transitions) for the full behavior.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | `(from: T, to: T, current: T, alpha: number) -> ()` | Called at the start of a transition and on every frame until the transition ends. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving updates. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onTransition callback must be a function` |

## Types

### HandlerOptions

```luau
type HandlerOptions = {
    onTransition: TransitionOptions? -- Tween settings shared by every onTransition listener
}
```

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `onTransition` | [`TransitionOptions`](/guide/transitions#transitionoptions) | No | Linear easing, `0.25` seconds, speed `1` | The easing, duration, and speed of the handler's transitions. An invalid value raises an error when the handler is created. |

### Handler

```luau
type Handler<T> = {
    sources: Sources<T>,
    currentState: () -> string,
    setState: (stateName: string) -> (),
    onChange: (callback: OnChangeCallback<T>) -> Disconnect,
    onTransition: (callback: OnTransitionCallback<T>) -> Disconnect,
}
```

The type of a handler. Pass it the value type from [`InferRule`](/guide/rules#inferrule) so the
handler matches its rule.

| Name | Type | Description |
| --- | --- | --- |
| `T` | `InferRule<typeof(rule)>` | The value type of the rule that created the handler. |

### Sources

```luau
type Sources<T> = -- A record of Vide sources, one per field of T
```

| Name | Type | Description |
| --- | --- | --- |
| `T` | `{ [string]: any }` | The value record. Each field becomes a `Source` of that field's type. |

### OnChangeCallback

```luau
type OnChangeCallback<T> = (from: T, to: T) -> ()
```

### OnTransitionCallback

```luau
type OnTransitionCallback<T> = (from: T, to: T, current: T, alpha: number) -> ()
```

| Name | Type | Description |
| --- | --- | --- |
| `from` | `T` | The previous state's values. |
| `to` | `T` | The next state's values. |
| `current` | `T` | The values to render on this frame. |
| `alpha` | `number` | The eased progress, from 0 to 1. With `back` and `elastic` easings it can go below 0 or above 1. See [alpha](/guide/transitions#alpha). |

### Disconnect

```luau
type Disconnect = () -> ()
```

Removes the listener it was returned for. Calling it more than once has no effect.
