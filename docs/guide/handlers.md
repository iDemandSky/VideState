---
title: Handlers
description: Create independent handlers from a rule, with reactive sources and cleanup.
outline: [2, 3]
---

# Handlers

A handler is created from a [rule](/guide/rules) with [`new`](/guide/rules#new). Each handler owns its
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

- The state name is unknown.
- The state's values no longer match the schema.

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
        current: T -- The values to render on this frame
    ) -> (),
    tweenMetadata: TweenMetadata? -- Easing, duration, and speed for this listener
) -> Disconnect
```

Runs `callback` with a `current` value that moves from the previous state to the next one. Each
animatable field is tweened with [Ripple](https://github.com/littensy/ripple). Fields that cannot be
tweened, such as booleans, strings, and enums, switch to their next value at the start of the
transition. See [Transitions](/guide/transitions) for the full behavior.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | `(from: T, to: T, current: T) -> ()` | Called at the start of a transition and on every frame until the transition ends. |
| `tweenMetadata` | [`TweenMetadata`](/guide/transitions#tweenmetadata)`?` | Optional. Settings for this listener. Without it, fields tween linearly over the handler's `transitionDuration`. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving updates. |

**Errors**

- `callback` is not a function.
- `tweenMetadata` is not a table, has an unknown key, or has an invalid `easing`, `duration`, or `speed`.

## Types

### HandlerOptions

```luau
type HandlerOptions = {
    transitionDuration: number?, -- Default tween duration in seconds
}
```

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `transitionDuration` | `number` | No | `0.25` | The tween duration in seconds for listeners that do not set their own `duration`. Must be finite and non-negative. |

### Handler

```luau
type Handler<T> = {
    sources: Sources<T>,
    currentState: () -> string,
    setState: (stateName: string) -> (),
    onChange: (callback: OnChangeCallback<T>) -> Disconnect,
    onTransition: (callback: OnTransitionCallback<T>, tweenMetadata: TweenMetadata?) -> Disconnect,
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
type OnTransitionCallback<T> = (from: T, to: T, current: T) -> ()
```

### Disconnect

```luau
type Disconnect = () -> ()
```

Removes the listener it was returned for. Calling it more than once has no effect.
