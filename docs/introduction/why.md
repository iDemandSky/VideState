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
