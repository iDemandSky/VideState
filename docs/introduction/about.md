---
title: VideState
description: Why VideState exists and how it fits with Vide.
---

# VideState

VideState is a state handler for [Vide](https://github.com/centau/vide) sources.
Vide creates the UI Instances. VideState manages the state changes of the source
values those Instances bind to, and it never creates Instances itself.

## Why it exists

- **Validated values.** Source values are checked against a schema, so invalid
  data is reported with the field that caused the problem instead of failing
  later in the UI.
- **Reusable rules.** A rule defines the shape and named states once. Any number
  of handlers can be created from it. Each handler keeps its own current state,
  and its sources follow that state.
- **Built-in schemas.** Developers define their rules with VideState's own schema
  builders, so they don't need a separate validation library.
- **Clear boundaries.** VideState handles data and state changes. Vide handles
  Instances. Each library does one job.

Continue with the [Getting started](/guide/getting-started) guide.
