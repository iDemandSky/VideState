# Design decisions

Settled decisions and why they were made. Do not reopen one unless the user brings it up. Add a line here when the
user settles a new one.

## Transitions

- **Each `onTransition` connection has its own tween.** Handler options are the defaults, and a connection can pass its
  own options to override each setting. The user wanted different settings per animated component.
- **An interrupted transition continues from its current value.** When `setState` runs before a transition ends, the new
  tween starts from the last value that connection sent, not from the previous state's values. It builds a new tween
  from that value instead of retargeting the old Ripple tweens, because the animatable fields can differ between
  transitions. The callback's `from` is still the previous state's values.
- **`pause` acts on the whole handler.** `setState` while paused sends the first frame and holds it until `resume`. A
  connection's own `speed` source of `0` pauses only that connection and does not fire `onPause`.
- **`resume` and `onResume` exist** because a `pause` with no way back would leave transitions stuck.
- **The events pass `startedAt`,** the `os.clock()` time the most recent transition started. Before any transition, it
  is the time of the call.
- **`fastForward` scales only the running transition,** and the next `setState` resets it. It multiplies each
  connection's own speed. It is not called `snapTransition`, because "snap" suggests an instant jump.
- **`finish` is the instant jump.** It sends the last frame before it returns, and works while paused.
- **`onFinish` fires once per transition,** when the last connection ends and at least one reached its end. A
  transition that a newer `setState` replaces never finishes.
- **No `animated` sources.** Derived sources that follow the tween were proposed and dropped, because `onTransition`
  already covers it.

## Code and tooling

- **Requires use the `@packages` and `@luau-packages` aliases** for dependencies. Larvae rewrites them, and the processed
  output is the same as with relative paths.
- **`.luaurc` stays.** `.config.luau` was tried, but Lest only reads aliases from `.luaurc`, so the tests could not
  resolve `@Lest`, `@packages`, or `@VideState`.
- **Each handler feature has its own module** under `src/Handler/`, so a developer can look a function up by feature
  name. A folder is used only when the feature has children.
- **Every combined condition is named.** See the code style rules in `~/.claude/CLAUDE.md`.
