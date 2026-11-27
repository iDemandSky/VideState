---
title: Who is this for?
description: For those wanting to find the purpose of VideState.
---

# Why?

As a Roblox developer who wants my UI to feel consistent everywhere, I wanted to be able to build different styles of UI without rewriting the transition logic for each one.

VideState keeps transitions consistent. Every handler tweens each field between states with the same timing, with a default duration of 0.25 seconds, so the motion looks the same across your interface. You can still set a different duration for a connection when it needs one.

It also lets you set a state on the UI seamlessly. Calling `setState` swaps the active state, updates the derived sources, and fires your change and transition listeners, so Vide reacts to the new values without extra wiring.

VideState is also compatible with inheritance-based programming, so you can use it in class-style code as well as in plain functional code.