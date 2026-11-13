---
title: Transitions
description: Listen for state changes and animate between states with onChange and onTransition.
---

# Transitions

Handlers provide two ways to respond to state changes: `onChange` runs once when
the state changes, and `onTransition` runs repeatedly with an `alpha` value from
`0` to `1`.

## onChange

`onChange` receives the previous and next state values. Both are frozen copies.

```luau
local disconnect = panel.onChange(function(from, to)
    print(from.order, "->", to.order)
end)
```

Listeners only receive changes made after they are registered.

## onTransition

`onTransition` receives the previous and next values along with `alpha`, which
moves from `0` to `1` over the transition duration.

```luau
local stop = panel.onTransition(function(from, to, alpha)
    print(alpha)
end)
```

The default duration is 0.25 seconds. Set it per handler with the optional
third argument to `new`:

```luau
local panel = PanelRule.new(states, "Idle", { transitionDuration = 0.4 })
```

Behavior to know:

- A duration of `0` sends `alpha = 1` immediately.
- Calling `setState` again before a transition finishes stops the earlier
  animation and starts a new one.
- No animation runs while there are no `onTransition` listeners.

## Disconnecting

Both methods return a function. Call it to stop receiving updates:

```luau
stop()
disconnect()
```
