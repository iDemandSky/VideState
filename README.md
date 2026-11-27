# VideState

A state handler for [Vide](https://github.com/centau/vide). Build UI components with states, and let
VideState change their properties whenever the state changes.

**Documentation: https://idemandsky.github.io/VideState/**

> **⚠️ Warning**
>
> VideState has only been benchmarked in Roblox Studio, and it has not been tested in production. Use it
> wisely: measure it in your own project, especially with many handlers or transitions running at once,
> before you depend on it.

## Features

- **Rules** describe a component's properties with schemas (`boolean`, `integer`, `float`, `string`, `enum`,
  `optional`, `union`, `table`, `record`, `color3`, `numberRange`, `numberSequence`, `colorSequence`, `udim`, `udim2`, `vector2`), and validate every state. `allowedTransitions` limits which state can follow which.
- **Rule inheritance** with `VideState.extend`: a new rule keeps every field, state name, and tag of its base and adds
  its own.
- **Handlers** hold one component's state, with `sources` that follow the active state and bind to Vide properties.
- **Events** for state changes: `onChange`, `onEnter`, `onExit`.
- **Transitions** with `onTransition`: each connection has its own easing, duration, speed, and `delay`, and can use other
  settings for particular state changes with `tweenOverrides`. Curves of your own come from `VideState.bezier` and
  `VideState.easing`.
  An interrupted transition continues from its current value. `animate` gives the same transition as Vide sources, and `progress` gives its alpha as one source.
- **Transition controls**: `pause`, `resume`, `scaleSpeed`, `finish`, `onFinish`, `waitForFinish`, and
  `setState(name, { instant = true, delay = 0.2 })`. `everyHandler.setState` takes a `stagger` to start handlers one
  after another.
- **Every handler at once**: `VideState.everyHandler` has `scaleSpeed`, `pause`, `resume`, `finish`, `setState`, and `destroy`,
  plus `count`, `isAnyRunning`, and `isAnyPaused`. Chain `withTags`, `withRule`, and `withStates`, or their `without` forms, to pick the handlers.
- **Cleanup** with `destroy`.
- **Debug tools**: `VideState.debug` lists tracked handlers, and its `view` is a Vide component.
- **Testing**: a manual clock (`setManualClock`, `advanceClock`) steps transitions by exact times.
- **Accessibility**: `setReducedMotion(true)` makes every state change instant.

## Install

```sh
embr add idemandsky/videstate
```

## Quick start

```luau
const VideState = require("@VideState")
const Vide = require("@packages/Vide")

local PanelRule = VideState.rule({
    visible = VideState.boolean(),
    order = VideState.integer({ min = 0 }),
}, { name = "Panel" })

local panel = PanelRule.new({
    Idle = { visible = Vide.source(false), order = Vide.source(0) },
    Active = { visible = Vide.source(true), order = Vide.source(1) },
}, "Idle")

panel.setState("Active")
```

Bind `panel.sources.visible` to any Vide property, and it follows the active state. The
[documentation](https://idemandsky.github.io/VideState/) covers every API.

## License

MIT. See [LICENSE](LICENSE).
