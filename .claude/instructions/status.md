# Current status

Update this file when a release ships, a limit is found or fixed, or an idea is accepted or dropped.

## Released

The latest release is 0.1.2.

## Unreleased on `dev`

`ember.toml` is already set to 0.2.0, so the package can be tested locally with `embr publish --local`. It is not
released: `CHANGELOG.md` still lists these changes under `## [Unreleased]`, and the doc badges call it 0.2.0.

- Per-connection `onTransition` options.
- `pause`, `resume`, `onPause`, `onResume`.
- `fastForward`, `finish`, `onFinish`.
- An interrupted transition continues from its current value.
- Refactors: handler features as separate modules, shared types in `src/Types.luau`, and every combined condition
  named.

`main` has not been updated since 0.1.2, because the user asked not to push to `main` for this work. The docs site
deploys from `main`, so it does not show these features yet.

Also unreleased: `setState(name, { instant = true })`, `onEnter` and `onExit`, `waitForFinish`, `destroy`, the
`delay` transition option, and the shared frame loop with its benchmark (`lest bench`).

## In progress

The user accepted this. Build it with tests and docs:

- A debug view: a UI Labs story that lists handlers, their states, and their running transitions.

## Known limits

- Benchmarked only in Roblox Studio, and not tested in production. The README and the docs say so.
- Strings, booleans, enums, and other non-animatable fields cannot be transitioned. They switch at the start.
- `onTransition` callbacks must not yield, because one shared loop steps every transition.
- A paused transition stays on the shared loop and is stepped without moving.
- `ember.toml` ships raw `src/`. That works because `src/` requires its dependencies with relative paths. A local
  install of 0.2.0 resolved every require on disk, but it has not been run in Studio yet.

## Ideas not started

- Tween settings per state pair (such as `Idle -> Active`) and per field.
- A spring option, using Ripple's springs.
- More 2D schemas: `NumberRange`, `NumberSequence`, `ColorSequence`, and a `union`. Not `Vector3`; see
  [decisions.md](decisions.md).
