---
title: Transitions
description: Listen for state changes and animate between states with onChange and onTransition.
---

# Transitions

Handlers provide two ways to respond to state changes: `onChange` runs once when
the state changes, and `onTransition` runs repeatedly with a `current` value that
moves from the previous state to the next one.

## onChange

`onChange` receives the previous and next state values. Both are frozen copies.

```luau
local disconnect = panel.onChange(function(from, to)
    print(from.order, "->", to.order)
end)
```

Listeners only receive changes made after they are registered.

## onTransition

`onTransition` receives the previous value, the next value, and `current`, the value
to render on this frame. Each animatable field is tweened from its previous value
to its next value. Fields that can't be tweened, such as booleans, strings, and
enums, switch to their next value at the start of the transition.

```luau
local stop = panel.onTransition(function(from, to, current)
    print(current.order)
end)
```

The default duration is 0.25 seconds. Set it per handler with the optional
third argument to `new`:

```luau
local panel = PanelRule.new(states, "Idle", { transitionDuration = 0.4 })
```

Behavior to know:

- A duration of `0` calls the callback once with `current` equal to the next value.
- Calling `setState` again before a transition finishes stops the earlier
  animation and starts a new one.
- No animation runs while there are no `onTransition` listeners.
- A listener added during a transition receives updates from the next transition.

## Tweens

`onTransition` takes an optional second argument, `TweenMetadata`. The `ripple` field
sets the [Ripple](https://github.com/littensy/ripple) easing and, optionally, the duration
used to tween each animatable field, so the value your callback receives is already eased.
Without it, fields are tweened linearly over the handler's `transitionDuration`. Metadata
applies per listener, so two listeners on the same handler can use different easings and
durations.

```luau
local stop = panel.onTransition(function(from, to, current)
    -- current.backgroundColor already follows the quadOut curve
end, {
    ripple = { easing = "quadOut", duration = 0.1 },
})
```

`ripple.duration` is in seconds and must be finite and non-negative. A listener with its
own duration stops receiving updates once that duration ends, while listeners on the
default duration keep going. Each listener creates one tween per animatable field, so
its duration doesn't change how many tweens run.

Animatable fields are numbers, vectors, `Vector2`, `Vector3`, `CFrame`, `Color3`,
`UDim`, `UDim2`, `Rect`, and tables whose values are numbers, vectors, or `Vector3`s
with the same keys.

The easing name is typed as `VideState.TweenName`, so editors suggest the valid names:

- `linear`
- `quadIn`, `quadOut`, `quadInOut`
- `cubicIn`, `cubicOut`, `cubicInOut`
- `sineIn`, `sineOut`, `sineInOut`
- `expoIn`, `expoOut`, `expoInOut`
- `backIn`, `backOut`, `backInOut`
- `elasticIn`, `elasticOut`, `elasticInOut`

Every easing starts at the previous value and ends at the next one. `back` and
`elastic` overshoot: during the transition, numeric values can go below the start or
above the end. If your UI needs values in a fixed range, clamp them in your callback.
An unknown easing name, an unknown metadata key, a negative or non-finite duration, or
metadata that isn't a table raises an error.

## Disconnecting

Both methods return a function. Call it to stop receiving updates:

```luau
stop()
disconnect()
```
