# Current status

Update this file when a release ships, a limit is found or fixed, or an idea is accepted or dropped.

## Released

The latest release is 0.2.1 (2026-11-24), which only changes the README (a feature list and a quick start). Versions 0.1.0 to 0.1.2 are deprecated on Ember, because 0.2.0 changes some
existing features. 0.2.0 added per-connection `onTransition` options, pause and resume, `fastForward` (now `scaleSpeed`), `finish`,
`onFinish`, `setState(name, { instant = true })`, `onEnter` and `onExit`, `waitForFinish`, `destroy`, the `delay`
option, the shared frame loop with its benchmark (`lest bench`), and `VideState.debug` with its UI Labs story in
`stories/`. See `CHANGELOG.md`.

## Unreleased on `dev`

`fastForward` was renamed `scaleSpeed` (breaking, so the next version is 0.3.0).
`scaleSpeed` has a `once` option (default `false`), and `VideState.every.handler` acts on all handlers with `scaleSpeed`,
`pause`, `resume`, and `finish`. `every.handler.withTags(...)` limits them to rules with all the tags, and `destroy` is included. `every` could get
more scopes later, such as `every.rule(name)`.

`main` is synced by the user, never by Claude. The docs site deploys from `main`, so it shows 0.2.0 only once the user
has pushed it there.

## Known limits

- Benchmarked only in Roblox Studio, and not tested in production. The README and the docs say so.
- Strings, booleans, enums, and other non-animatable fields cannot be transitioned. They switch at the start.
- `onTransition` callbacks must not yield, because one shared loop steps every transition.
- A paused transition stays on the shared loop and is stepped without moving.
- `ember.toml` ships raw `src/`. That works because `src/` requires its dependencies with relative paths. A local
  install of 0.2.0 resolved every require on disk and was tested by the user.

## Ideas not started

- Tween settings per state pair (such as `Idle -> Active`) and per field.
- A spring option, using Ripple's springs.
- More 2D schemas: `NumberRange`, `NumberSequence`, `ColorSequence`, and a `union`. Not `Vector3`; see
  [decisions.md](decisions.md).
