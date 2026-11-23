---
title: Transitions
description: Animate between states with onTransition and tween metadata.
outline: [2, 3]
---

# Transitions

[`onChange`](/guide/handlers#onchange) runs once when the state changes. [`onTransition`](/guide/handlers#ontransition)
runs repeatedly with a `current` value that moves from the previous state to the next one. This page
covers how transitions behave and the settings that control them.

## Behavior

- Each animatable field is tweened from its previous value to its next value.
- Fields that cannot be tweened, such as booleans, strings, and enums, switch to their next value at the start of the transition.
- A duration of `0` calls the callback once with `current` equal to the next value.
- Calling `setState` again before a transition finishes stops the earlier animation and starts a new one.
- No animation runs while there are no `onTransition` listeners.
- A listener added during a transition receives updates from the next transition.
- A listener with its own `duration` stops receiving updates once that duration ends, while listeners on the default duration keep going.
- Every easing starts at the previous value and ends at the next one. `back` and `elastic` easings overshoot, so numeric values can go below the start or above the end. Clamp them in your callback if your UI needs a fixed range.

Animatable fields are numbers, vectors, `Vector2`, `Vector3`, `CFrame`, `Color3`, `UDim`, `UDim2`,
`Rect`, and tables whose values are numbers, vectors, or `Vector3`s with the same keys.

## Types

### TweenMetadata

```luau
type TweenMetadata = {
    easing: TweenName?, -- The easing curve applied to animatable fields
    duration: number?, -- The duration in seconds for this listener
    speed: Source<number>?, -- Scales how fast the tween advances
}
```

Settings for one `onTransition` listener. Two listeners on the same handler can use different
settings. The tween is created by [Ripple](https://github.com/littensy/ripple).

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `easing` | [`TweenName`](#tweenname) | No | `"linear"` | The easing curve. An unknown name raises an error. |
| `duration` | `number` | No | The handler's `transitionDuration` | The duration in seconds. Must be finite and non-negative. |
| `speed` | `Source<number>` | No | `1` | A Vide source read every frame. `1` is normal speed, `0` pauses, and larger values play faster. A value that is not a finite, non-negative number is treated as `1`. |

An unknown key, a non-table value, or an invalid field raises an error.

### TweenName

```luau
type TweenName =
    "linear"
    | "quadIn" | "quadOut" | "quadInOut"
    | "cubicIn" | "cubicOut" | "cubicInOut"
    | "sineIn" | "sineOut" | "sineInOut"
    | "expoIn" | "expoOut" | "expoInOut"
    | "backIn" | "backOut" | "backInOut"
    | "elasticIn" | "elasticOut" | "elasticInOut"
```

The valid easing names. Editors suggest them from this type.
