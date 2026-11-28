---
title: VideState
description: What VideState is, how it fits with Vide, and what it gives you.
---

# VideState

VideState is a state handler for [Vide](https://github.com/centau/vide) sources. You describe a component's states, and
VideState changes its properties whenever the state changes. Vide creates the UI Instances. VideState only manages the
values those Instances bind to, and it never creates Instances itself.

## How it works

1. **Create a rule.** A [rule](/guide/rules) is the blueprint of a component: the properties it has and the states it
   can be in. It validates the values of every state.
2. **Create a handler.** A [handler](/guide/handlers) is one instance of that component, made from the rule with its
   states and an initial state. Each handler keeps its own state.
3. **Bind its sources.** The sources of a handler follow its active state, so you bind them to Vide properties.
4. **Change the state.** Call `setState` and react with the handler's events and transitions.

## What you get

- **Schemas.** Describe properties with VideState's own schema builders, so you don't need a separate validation
  library. An invalid value is reported with the field that caused it, instead of failing later in the UI.
- **Transitions.** Fade the properties between states with an easing, a duration, a speed and a delay for each
  connection, and different settings for particular state changes.
- **Controls.** Pause, resume, scale the speed of, or finish a transition, or change state instantly.
- **Every handler.** Act on all handlers at once, filtered by tags, rule or state.
- **Debug tools.** Opt-in tools to inspect handlers, including a Vide debug view.

Continue with the [Getting started](/guide/getting-started) guide, or read [Why VideState](/introduction/why) for the
reasons behind it.
