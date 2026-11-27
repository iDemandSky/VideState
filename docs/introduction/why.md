---
title: Why VideState
description: The reasons VideState was built.
---

# Why VideState

As a Roblox developer who wants my UI to feel consistent everywhere, I wanted to build different styles of UI without
rewriting the transition logic for each one.

- **Consistent motion.** Every handler tweens each field between states the same way, with a default duration of 0.25
  seconds, so the motion looks the same across your interface. A connection can still set its own settings when it
  needs them.
- **Seamless state changes.** Calling `setState` swaps the active state, updates the sources, and fires your change and
  transition listeners, so Vide reacts to the new values without extra wiring.
- **Inheritance-friendly.** One rule can serve many looks, so you can use VideState in class-style code as well as in
  plain functional code. See [Inheritance](/examples/inheritance).

## Compared to setting up animations by hand

Without VideState, each component needs its own code to move from one look to another. You write a tween or a frame loop
for every property, keep track of which state the component is in, and handle a state change that arrives while the
last one is still running. That code gets copied from component to component, and each copy drifts a little.

| By hand | With VideState |
| --- | --- |
| Write a tween or a frame loop for every property of every component | Bind `handler.animate()` sources to the properties, and VideState tweens them |
| Keep the current state in a variable and check it everywhere | The handler holds the state, and `setState` changes it |
| Work out what to do when a state change arrives mid-animation | A new transition continues from the value the earlier one reached, so nothing jumps |
| Copy the duration and easing into each component, then edit each one to change them | Set them once for a connection, or in one shared [tween config](/examples/tween-config) |
| Hard-code a different duration for pressing than for hovering | Give particular state changes their own settings with `tweenOverrides` |
| Write your own pause, skip and instant-change logic | `pause`, `resume`, `scaleSpeed`, `finish`, and `setState` with `instant` |
| Hope every state sets the same properties with valid values | A rule validates every state when the handler is created |
| Disconnect every listener and loop yourself when a component is removed | `destroy` stops the transitions and removes the listeners |
| Run one loop per animated component | One shared loop steps every transition |

Roblox's `TweenService` tweens the properties of an Instance, not Vide sources, so it does not fit a UI whose values
come from Vide. VideState tweens the sources, so the animation follows the state and the Instance stays in Vide's hands.
