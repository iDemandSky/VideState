# Current status

Update this file when a release ships, a limit is found or fixed, or an idea is accepted or dropped.

## Released

The latest release is 0.5.0 (2026-11-28), described under "0.5.0" below. 0.4.0 (2026-11-26) removed the handler options (breaking): `rule.new(states, initialState)`
takes no third argument, and the tween settings go in `tweenDefault` in the options of `onTransition` and `animate`. It
added `tweenOverrides` (tween settings per state change), `handler.animate` (Vide sources for a transition), the schemas
`numberRange`, `numberSequence`, and `colorSequence`, and `rule.getTags`, `hasTag`, `addTags`, and `removeTags`. It
replaced Ripple with a built-in tween, which is 20 to 30% faster per connection, and the tooling moved from Rojo to
Argon. 0.3.0 (2026-11-25) renamed `fastForward` to `scaleSpeed` (breaking), added the `once` option
(default `false`, so the scale stays), and added `VideState.everyHandler` with its filters, exclusions, conflict checks,
`setState`, `destroy`, and the `count`, `isAnyRunning`, and `isAnyPaused` reads. 0.2.1 only changed the README. Versions
0.1.0 to 0.1.2 are deprecated on Ember. 0.2.0 added per-connection `onTransition` options, pause and resume, `finish`,
`onFinish`, `setState(name, { instant = true })`, `onEnter` and `onExit`, `waitForFinish`, `destroy`, the `delay` option,
the shared frame loop with its benchmark (`lest bench`), and `VideState.debug` with its UI Labs story in `stories/`. See
`CHANGELOG.md`.

## 0.5.0

0.5.0 added the `union` schema, `setReducedMotion`, custom easing (`bezier`, `easing`), `handler.progress`,
`allowedTransitions` in the rule metadata, a `delay` option on `setState` with `stagger` on `everyHandler.setState`,
`VideState.extend` for rule inheritance, `handler.playSequence` for state sequences, and the manual clock for tests (`setManualClock`, `advanceClock`). See
`CHANGELOG.md`.

`main` is synced by the user, never by Claude. The docs site deploys from `main`, so it shows 0.5.0 only once the user
has pushed it there.

## Known limits

- Benchmarked only in Roblox Studio, and not tested in production. The README and the docs say so.
- Strings, booleans, enums, and other non-animatable fields cannot be transitioned. They switch at the start.
- `onTransition` callbacks must not yield, because one shared loop steps every transition.
- A paused transition stays on the shared loop and is stepped without moving.
- `ember.toml` ships raw `src/`. That works because `src/` requires its dependencies with relative paths. A local
  install of 0.2.0 resolved every require on disk and was tested by the user.

## Ideas not started

- More 2D schemas. Not `Vector3`; see [decisions.md](decisions.md).
