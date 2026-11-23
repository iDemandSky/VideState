---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: VideState
  text: A Roblox Vide source state handler.
  tagline: Consistent transitions, seamless state changes, and inheritance-friendly Vide UI.
  actions:
    - theme: brand
      text: Get started
      link: /guide/getting-started

features:
  - title: Validated schemas
    details: Build table, record, primitive, and Roblox datatype schemas. Invalid values return issues that identify each offending field.
  - title: Reusable rules
    details: Define a rule once with named states, each holding Vide sources. Handlers follow their active state, so existing Vide bindings stay reactive.
  - title: State transitions
    details: Register onChange callbacks, or onTransition callbacks that receive the current eased value of each field over a configurable duration (0.25 seconds by default).
---

