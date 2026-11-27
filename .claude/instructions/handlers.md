# Handlers

A handler is one instance of a rule's component. `src/Handler/init.luau` creates it and only wires the features
together. Each feature has its own module under `src/Handler/`, so look up a function by the feature name:

| Module | Functions |
| --- | --- |
| `Change.luau` | `onChange` |
| `StateEvents.luau` | `onEnter`, `onExit` |
| `Transition/` | `onTransition`, and the `emit` that `setState` calls. `Config/Overrides.luau` checks `tweenOverrides` and finds the entry for a state change |
| `Animate.luau` | `animate`, built on `onTransition` |
| `Progress.luau` | `progress`, built on `onTransition` |
| `Pause.luau` | `pause`, `resume`, `onPause`, `onResume` |
| `ScaleSpeed.luau` | `scaleSpeed` |
| `Finish.luau` | `finish`, `onFinish`, `waitForFinish` |
| `SetState.luau` | `setState` |

`src/Every/` holds `VideState.everyHandler`, which acts on all handlers. Each handler adds itself to `Every/Registry.luau`
when it is created and leaves it on `destroy`, and `Every/Scale.luau` is the global speed scale that `getRate` in `init.luau` multiplies in.

The handler also has `sources` and `currentState`, which `init.luau` builds itself.

## Rules for the handler code

- A folder is used only when a feature has children. A single-file feature is a plain module, not a folder with only an
  `init.luau`.
- Each feature module returns a frozen table of its functions, such as `{ onChange, emit }`.
- Types that several modules share go in `src/Types.luau`. A type that depends on `Group` or `Options` stays in
  `Transition/State.luau`, because those modules require `Types` and moving it would create a require cycle.
- The analyzer cannot infer a generic over `TypedCore.infer<S>`. Pass the type explicitly in `Handler/init.luau`, such as
  `ScaleSpeed<<Values>>(state)`.
- `onTransition` and `animate` take optional options with a `tweenDefault`. Each connection has its own tween, and a
  setting it leaves out takes the built-in default. A handler takes no options.
- A new transition that starts before the running one ends continues from the value the earlier one reached.
- `pause`, `scaleSpeed` and `finish` act on the handler as a whole: every connection of the running transition.
