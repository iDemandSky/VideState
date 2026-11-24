# Handlers

A handler is one instance of a rule's component. `src/Handler/init.luau` creates it and only wires the features
together. Each feature has its own module under `src/Handler/`, so look up a function by the feature name:

| Module | Functions |
| --- | --- |
| `Change.luau` | `onChange` |
| `Transition/` | `onTransition`, and the `emit` that `setState` calls |
| `Pause.luau` | `pause`, `resume`, `onPause`, `onResume` |
| `FastForward.luau` | `fastForward` |
| `Finish.luau` | `finish`, `onFinish` |
| `SetState.luau` | `setState` |

The handler also has `sources` and `currentState`, which `init.luau` builds itself.

## Rules for the handler code

- A folder is used only when a feature has children. A single-file feature is a plain module, not a folder with only an
  `init.luau`.
- Each feature module returns a frozen table of its functions, such as `{ onChange, emit }`.
- Types that several modules share go in `src/Types.luau`. A type that depends on `Group` or `Options` stays in
  `Transition/State.luau`, because those modules require `Types` and moving it would create a require cycle.
- The analyzer cannot infer a generic over `TypedCore.infer<S>`. Pass the type explicitly in `Handler/init.luau`, such as
  `FastForward<<Values>>(state)`.
- `onTransition` takes optional per-connection options. Each connection has its own tween, and a setting it leaves out is
  read from the handler options.
- A new transition that starts before the running one ends continues from the value the earlier one reached.
- `pause`, `fastForward` and `finish` act on the handler as a whole: every connection of the running transition.
