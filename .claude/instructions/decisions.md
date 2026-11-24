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
- **`scaleSpeed` scales only the running transition by default,** and the next `setState` resets it. `permanent = true` keeps the scale for every following transition, as a separate base scale that multiplies with the once scale. It multiplies each
  connection's own speed. It was called `fastForward` in 0.2.0 and renamed because a scale below 1 slows it down. It is not called `snapTransition`, because "snap" suggests an instant jump.
- **`finish` is the instant jump.** It sends the last frame before it returns, and works while paused.
- **`onFinish` fires once per transition,** when the last connection ends and at least one reached its end. A
  transition that a newer `setState` replaces never finishes.
- **No `animated` sources.** Derived sources that follow the tween were proposed and dropped, because `onTransition`
  already covers it.
- **`setState` takes `{ instant = true }`,** which runs the transition with a duration of 0: one frame with the next
  values and an alpha of 1, and `onFinish` still runs.
- **`onExit` runs first, then `onEnter`, `onChange`, and the transition.** The callbacks receive the other state's name.
  They do not run for the initial state or for a `setState` to the active state.
- **`waitForFinish` waits until the handler is idle,** not for one transition: a replaced transition keeps the wait
  going until the newer one ends.
- **`destroy` stops transitions silently** (no last frame, no `onFinish`), removes every listener, releases waiting
  threads, and makes `setState` raise an error. The other functions do nothing afterwards.
- **One shared loop steps every transition,** measured with `lest bench` before and after. Each step runs in a
  `pcall`, so a failing callback stops only its own connection. Callbacks must not yield.

## Debug tools

- **Tracking is opt-in.** Only handlers passed to `debug.track` are listed. Every handler still adds its inspect
  function to a weak table when created, because that is the only way the debug tools can read its internals.
- **The view ships in the package** as `debug.view()`, a Vide component, so users can mount it in their own stories
  or debug screens. The repository story in `stories/` uses it.

## Schemas

- **No 3D schemas,** such as `Vector3`. VideState is for 2D UI. 2D types such as `NumberSequence` or `ColorSequence`
  are still open.

## Code and tooling

- **Dependencies are required with relative paths in `src/`,** such as `../packages/roblox/Vide`. The `@packages` aliases
  were tried and broke the installed package, because a package cannot ship its aliases and `embr` does not rewrite them.
  The relative paths resolve to the link files `embr` puts inside the installed package. See [requires.md](requires.md).
- **`.luaurc` stays.** `embr` supports `.config.luau` and writes into its `luau.aliases` table when the file exists. But
  with the aliases at the top level, Lest cannot resolve them, and with them under `luau`, Larvae cannot either. Never
  keep both files, because `embr` then writes no aliases.
- **Each handler feature has its own module** under `src/Handler/`, so a developer can look a function up by feature
  name. A folder is used only when the feature has children.
- **Every combined condition is named.** See the code style rules in `~/.claude/CLAUDE.md`.
