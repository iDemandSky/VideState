---
title: Transitions
description: Animate between states with onTransition, shared tween settings, and alpha.
outline: [2, 3]
---

# Transitions

[`onChange`](/guide/handlers#onchange) runs once when the state changes. [`onTransition`](/guide/handlers#ontransition)
runs repeatedly with a `current` value that moves from the previous state to the next one, and an
`alpha` that shows the progress. This page covers how transitions behave and the settings that control them.

The tween settings belong to the handler, not to each listener. A handler tweens its fields once per
transition and sends the same `current` and `alpha` to every listener, so all listeners stay in step.
Set them with the `onTransition` key of the handler's [`HandlerOptions`](/guide/handlers#handleroptions).

## Behavior

- Each animatable field is tweened from its previous value to its next value.
- Fields that cannot be tweened, such as booleans, strings, and enums, switch to their next value at the start of the transition.
- A duration of `0` calls the callback once with `current` equal to the next value and an `alpha` of `1`.
- Calling `setState` again before a transition finishes stops the earlier animation and starts a new one.
- No animation runs while there are no `onTransition` listeners, and a transition stops once every listener has disconnected.
- A listener added during a transition receives updates from the next transition.
- Every easing starts at the previous value and ends at the next one. `back` and `elastic` easings overshoot, so numeric values can go below the start or above the end. Clamp them in your callback if your UI needs a fixed range.

Animatable fields are numbers, vectors, `Vector2`, `Vector3`, `CFrame`, `Color3`, `UDim`, `UDim2`,
`Rect`, and tables whose values are numbers, vectors, or `Vector3`s with the same keys.

## alpha

`alpha` is the progress of the transition, from `0` at the start to `1` at the end. It follows the
same easing and duration as the tweened fields, so it matches how far the transition has moved. Use
it to drive values that Ripple cannot tween.

`back` and `elastic` easings overshoot. With them, `alpha` goes below `0` or above `1` during the
transition and settles at exactly `1` when it ends. This is expected, because the same curve moves
the tweened fields past their start or end. Clamp it with `math.clamp(alpha, 0, 1)` if you need a
fixed range.

## Changing settings during a transition

When a setting is a Vide source, it is read every frame. Changing it affects the running transition,
and Ripple restarts each tween from its current position. The remaining distance is covered with the new
settings, so values do not jump, but the easing curve starts again from that point. Plain values are
read once and never change.

## Types

### TransitionOptions

```luau
type TransitionOptions = {
    easing: (TweenName | Source<TweenName>)?, -- The easing curve applied to animatable fields and alpha
    duration: (number | Source<number>)?, -- The duration in seconds
    speed: Source<number>?, -- How fast the transition advances
}
```

Settings for the transitions of one handler. The tween is created by [Ripple](https://github.com/littensy/ripple).

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `easing` | [`TweenName`](#tweenname) or `Source<TweenName>` | No | `"linear"` | The easing curve. An unknown name raises an error. |
| `duration` | `number` or `Source<number>` | No | `0.25` | The duration in seconds. Must be finite and non-negative. |
| `speed` | `Source<number>` | No | `1` | A Vide source read every frame. `1` is normal speed, `0` pauses, and larger values play faster. It must never be negative, so a transition never moves backwards. |

Invalid values raise an error when the handler is created. This includes an unknown key, a
non-table value, a negative `speed`, and a `speed` that is not a source. A source is also checked on
creation, using its current value.

If a source later returns an invalid value, the transition keeps running instead of raising an
error: `easing` falls back to `"linear"` and `duration` to `0.25`. A negative `speed` is treated as `0`,
which pauses the transition, and any other invalid `speed` is treated as `1`. A paused transition keeps
its values and does not call listeners again until the speed is above `0`.

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
