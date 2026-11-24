# VideState

A state handler for [Vide](https://github.com/centau/vide). Build UI components with states, and let
VideState change their properties whenever the state changes.

**Documentation: https://idemandsky.github.io/VideState/**

> [!WARNING]
> VideState has not been benchmarked, and it has not been tested in production. Use it wisely:
> measure it in your own project, especially with many handlers or transitions running at once,
> before you depend on it.

Vide creates the UI Instances. VideState owns the values those Instances bind to: it validates them,
switches them between states, and can animate the change.

## Install

```sh
embr add idemandsky/videstate
```

## Quick start

A rule is the blueprint of a component: the properties it has and the states it can be in. A handler is
one instance of that component.

```luau
const VideState = require("@VideState")
const Vide = require("@packages/Vide")

local PanelRule = VideState.rule({
    visible = VideState.boolean(),
    order = VideState.integer({ min = 0 }),
}, {
    name = "Panel",
    allowedStateNames = { "Idle", "Active" },
})

local panel = PanelRule.new({
    Idle = { visible = Vide.source(false), order = Vide.source(0) },
    Active = { visible = Vide.source(true), order = Vide.source(1) },
}, "Idle")

-- Bind panel.sources.visible to any Vide property. It follows the active state.
panel.setState("Active")
```

## What it does

- **Rules and handlers.** Define a component once, then create as many handlers from it as you need. Each handler keeps its own state.
- **Inheritance.** Make a base component, then create many designs of it that share the same states and only change the property values.
- **Validation.** Schema builders (`boolean`, `integer`, `float`, `string`, `enum`, `optional`, `table`, `record`, `color3`, `udim`, `udim2`, `vector2`) check every state's values when a handler is created.
- **Transitions.** `onTransition` tweens numbers, vectors, colors, and other animatable values between states and passes you the eased value and the progress.
- **Typed.** `VideState.Infer` and `VideState.InferRule` give you the Luau types of your schemas and rules.

## Limitations

`onTransition` cannot transition strings. String, boolean, and enum fields switch to their next value at
the start of a transition.

## Learn more

- [Getting started](https://idemandsky.github.io/VideState/guide/getting-started)
- [Rules](https://idemandsky.github.io/VideState/guide/rules), [handlers](https://idemandsky.github.io/VideState/guide/handlers), and [schemas](https://idemandsky.github.io/VideState/guide/schemas)
- [Transitions](https://idemandsky.github.io/VideState/guide/transitions)
- [Examples](https://idemandsky.github.io/VideState/examples/components)
- [Changelog](CHANGELOG.md)

## License

MIT. See [LICENSE](LICENSE).
