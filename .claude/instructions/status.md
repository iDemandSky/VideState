# Current status

Update this file when a release ships, a limit is found or fixed, or an idea is accepted or dropped.

## Released

The latest release is 0.1.2, the version in `ember.toml`.

## Unreleased on `dev`

Listed under `## [Unreleased]` in `CHANGELOG.md`. The doc badges call it 0.2.0.

- Per-connection `onTransition` options.
- `pause`, `resume`, `onPause`, `onResume`.
- `fastForward`, `finish`, `onFinish`.
- An interrupted transition continues from its current value.
- Refactors: handler features as separate modules, shared types in `src/Types.luau`, and dependencies required through
  aliases.

`main` has not been updated since 0.1.2, because the user asked not to push to `main` for this work. The docs site
deploys from `main`, so it does not show these features yet.

## Known limits

- Not benchmarked, and not tested in production. The README and the docs say so.
- Strings, booleans, enums, and other non-animatable fields cannot be transitioned. They switch at the start.
- Every connection runs its own frame loop, and a paused handler's loops keep running without moving anything.
- `ember.toml` ships raw `src/`. See [release.md](release.md) before publishing.

## Ideas not started

- One shared frame loop for all running transitions, measured with a benchmark first.
- Automatic cleanup through Vide scopes, and `handler.destroy()`.
- Tween settings per state pair (such as `Idle -> Active`) and per field.
- A spring option, using Ripple's springs.
- More schemas: `Vector3`, `NumberRange`, `NumberSequence`, `ColorSequence`, and a `union`.
