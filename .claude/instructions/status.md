# Current status

Update this file when a release ships, a limit is found or fixed, or an idea is accepted or dropped.

## Released

The latest release is 0.3.0 (2026-11-25). It renamed `fastForward` to `scaleSpeed` (breaking), added the `once` option
(default `false`, so the scale stays), and added `VideState.everyHandler` with its filters, exclusions, conflict checks,
`setState`, `destroy`, and the `count`, `isAnyRunning`, and `isAnyPaused` reads. 0.2.1 only changed the README. Versions
0.1.0 to 0.1.2 are deprecated on Ember. 0.2.0 added per-connection `onTransition` options, pause and resume, `finish`,
`onFinish`, `setState(name, { instant = true })`, `onEnter` and `onExit`, `waitForFinish`, `destroy`, the `delay` option,
the shared frame loop with its benchmark (`lest bench`), and `VideState.debug` with its UI Labs story in `stories/`. See
`CHANGELOG.md`.

## Unreleased on `dev` (0.4.0)

`rule.hasTag`, `rule.addTags`, `rule.removeTags`, and `handler.animate` (Vide sources for a transition), and the schemas `numberRange`, `numberSequence`, and `colorSequence`. The tooling moved from Rojo to Argon, and `serve.cmd` and `docs.cmd` replaced the old launchers.

`main` is synced by the user, never by Claude. The docs site deploys from `main`, so it shows 0.3.0 only once the user
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
- More 2D schemas, such as a `union`. Not `Vector3`; see
  [decisions.md](decisions.md).
