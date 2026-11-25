# Changelog

All notable changes to VideState are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). While the version is below 1.0.0, a minor
version can contain breaking changes.

## [Unreleased]

### Changed

- `handler.fastForward` is now `handler.scaleSpeed`, and `FastForwardOptions` is now `ScaleSpeedOptions`. The name is neutral because a `speed` below `1` slows the running transition down. Breaking: rename the calls.

### Added

- `VideState.everyHandler` with `scaleSpeed`, `pause`, `resume`, `finish`, `setState`, and `destroy`, which act on every handler at once, and `count`, `isAnyRunning`, and `isAnyPaused`, which read them. The filters `withTags`, `withRule`, and `withStates`, and their exclusions `withoutTags`, `withoutRule`, and `withoutStates`, narrow the scope and can be chained. A filter that cannot match any handler together with the earlier ones raises one error that lists every conflict. `setState` raises one error that lists every handler without the state, and changes none. The `EveryHandlerGroup` type. `scaleSpeed` takes the same options as the handler's, so `once = true` scales only the transitions that are running now. Without `once` the scale also applies to later transitions and to handlers created later.
- A `once` option for `handler.scaleSpeed`. It defaults to `false`, so the scale stays for every following transition. With `once = true` the scale applies only to the running transition. Breaking: `fastForward` applied only to the running transition, so pass `once = true` to keep that.

## [0.2.1] - 2026-11-24

### Changed

- The README lists the features and has a quick start, so the Ember page is detailed.

## [0.2.0] - 2026-11-24

### Added

- `handler.pause()` and `handler.resume()` pause and continue every transition of a handler.
- `handler.onPause(callback)` and `handler.onResume(callback)` report those events and pass the `os.clock()` time at which the most recent transition started.
- The `OnPauseCallback` and `OnResumeCallback` types.
- `handler.fastForward({ speed })` plays the running transition faster, and `handler.finish()` ends every running transition at once with its last frame.
- `handler.onFinish(callback)` runs once when a transition has finished, and passes the `os.clock()` time at which it started.
- The `OnFinishCallback` and `FastForwardOptions` types.
- `handler.setState(name, { instant = true })` changes the state without an animation. The `SetStateOptions` type.
- `handler.onEnter(state, callback)` and `handler.onExit(state, callback)` run when the handler enters or leaves one state. The `OnEnterCallback` and `OnExitCallback` types.
- `handler.waitForFinish()` yields until the handler has no running transition.
- `handler.destroy()` stops every transition and removes every listener. `setState` raises an error afterwards.
- A `delay` transition option makes a connection wait before its tween starts, for staggered animations.
- `VideState.debug` with `track`, `snapshot`, `list`, and `view`: an opt-in list of handlers with their state and transitions, and a Vide component that shows it. The `DebugSnapshot` type.

### Fixed

- A transition that is interrupted by another `setState` now continues from the value it had reached. Before, the new transition started from the previous state's values, so `current` jumped.

### Changed

- `handler.onTransition(callback, options)` takes optional `TransitionOptions`, so each connection can have its own easing, duration, and speed. Settings it leaves out are inherited from the handler's `onTransition` option. Every connection now tweens on its own instead of sharing one tween per handler.
- Every running transition is stepped by one shared loop instead of one loop per connection. In a Studio benchmark with 10,000 handlers, the average frame went from about 64 ms to about 55 ms. A callback that raises an error now stops only its own connection, and `onTransition` callbacks must not yield.
- The README and the docs now say VideState has only been benchmarked in Roblox Studio.

## [0.1.2] - 2026-11-24

### Changed

- Added a warning to the README that VideState has not been benchmarked or tested in production.

## [0.1.1] - 2026-11-24

### Changed

- Rewrote the README as an introduction for users, with the documentation link, install command, and a quick start. Development notes moved to `CONTRIBUTING.md`, which is not published.

## [0.1.0] - 2026-11-24

### Added

- Initial release.
- Rules with `VideState.rule`, which describe the properties and states of a UI component.
- Handlers created with `new`, which are the instances of a component. They provide `sources`, `currentState`, `setState`, `onChange`, and `onTransition`.
- `onTransition` tweens animatable fields with Ripple and passes the eased `current` value and `alpha` to listeners. Easing, duration, and speed are set per handler and can be Vide sources.
- Schema builders: `boolean`, `integer`, `float`, `string`, `enum`, `optional`, `table`, `record`, `color3`, `udim`, `udim2`, and `vector2`.
- `VideState.Infer` and `VideState.InferRule` to read the Luau type of a schema or a rule.
- `VideState.info` for debugging: `get`, `getAllRulesWithTags`, `getAllTags`, and `ruleHasTag`.

### Known limitations

- `onTransition` cannot transition strings. A `string` field switches to its next value at the start of the transition, as do booleans, enums, and any other value that is not animatable. Support for transitioning strings is planned for a later release.
