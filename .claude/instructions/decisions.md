# Design decisions

Settled decisions and why they were made. Do not reopen one unless the user brings it up. Add a line here when the
user settles a new one.

## Transitions

- **Each `onTransition` connection has its own tween.** The settings go in the connection's `tweenDefault`, and a handler
  takes no options. 0.2.0 had handler options as the defaults, and 0.4.0 removed them. The user wanted different settings
  per animated component, and found defaults on the handler confusing and extra lines to write.
- **An interrupted transition continues from its current value.** When `setState` runs before a transition ends, the new
  tween starts from the last value that connection sent, not from the previous state's values. It builds a new tween
  from that value instead of retargeting the old Ripple tweens, because the animatable fields can differ between
  transitions. The callback's `from` is still the previous state's values.
- **`pause` acts on the whole handler.** `setState` while paused sends the first frame and holds it until `resume`. A
  connection's own `speed` source of `0` pauses only that connection and does not fire `onPause`.
- **`resume` and `onResume` exist** because a `pause` with no way back would leave transitions stuck.
- **The events pass `startedAt`,** the `os.clock()` time the most recent transition started. Before any transition, it
  is the time of the call.
- **Tween settings are chosen per state pair, and a handler takes no options (agreed, not built).** `rule.new(states,
  initialState)` has no third argument. The tween options go to `onTransition` and `animate`: `tweenDefault = {
  duration, easing, speed, delay }`, and `tweenOverrides`, an array of entries `{ from = { names }, to = { names },
  tween = { ... } }`. A side that is left out means every state. Any overlap between entries raises one batched error
  when the call is made, so the array order never matters. The order for a setting is the matching entry, then
  `tweenDefault`, then the built-in default (0.25 s, linear). The speed is `(duration / localSpeed) / globalSpeed`, as
  now. A third argument to `new` raises an error that says where the settings moved. The user chose it over handler
  defaults because it is simpler to read and cheaper. A sketch is in the artifact the user was shown.
- **No per-field tween settings.** A source cannot be tweened on its own, and one `alpha` would have no meaning with
  several durations. A different tween for one field is another `animate` call.
- **`scaleSpeed` keeps its scale for every following transition by default.** `once = true` limits it to the running transition, and the next `setState` resets it. The kept scale is a separate base scale that multiplies with the once scale. The user chose `once` as the option name and `false` as its default. It multiplies each
  connection's own speed. It was called `fastForward` in 0.2.0 and renamed because a scale below 1 slows it down. It is not called `snapTransition`, because "snap" suggests an instant jump.
- **`finish` is the instant jump.** It sends the last frame before it returns, and works while paused.
- **`onFinish` fires once per transition,** when the last connection ends and at least one reached its end. A
  transition that a newer `setState` replaces never finishes.
- **`handler.animate` returns the animatable sources of a transition.** An earlier decision dropped derived sources because `onTransition` already covers it. The user reopened it: `animate` is `onTransition` in the form Vide expects, a source for every field instead of a callback, so a property binds to it directly. It is a thin layer over one `onTransition` connection, so it takes the same options and has no tween code of its own. It returns `(sources, disconnect)`, and the sources are independent of `handler.sources`.
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

## Every handler

- **`VideState.everyHandler` acts on all handlers.** The user first chose a `VideState.every` namespace with `handler`
  as its first scope, then dropped the namespace for the flat `VideState.everyHandler`, because no other scope is
  planned (`withRule` and `withTags` cover rules, and a transition always belongs to a handler). It has `scaleSpeed`, `pause`, `resume`, `finish`, `setState`, and `destroy`, the reads `count`, `isAnyRunning`, and
  `isAnyPaused`, and no `waitForFinish`. The user asked for `destroy` after first leaving it out, and a destroyed
  handler leaves the registry.
- **Its `scaleSpeed` has the same options as a handler's.** Without `once` it sets a global scale that also reaches
  handlers created later. With `once = true` it scales only the transitions running now. The speed is
  `global scale × handler scale × connection speed`.
- **A filter returns a group with the same functions, so filters chain with "and".** They are `withTags(...)`,
  `withRule(name)`, and `withStates(...)`, each with a `without` exclusion. `withTags` matches the rules that
  have all the tags, as `Info.getAllRulesWithTags` does, and `withoutTags` drops a handler whose rule has any of them.
  `withStates` keeps a handler in any of the names. The user chose these names to match each other, and
  `withStates` replaced `inState`. The handlers are looked up on every call, so the states are current.
  The registry holds each handler's rule name, an inspect function, and a `hasState` function, and no entry may hold
  its handler, because the keys are weak.
- **A filter that cannot match anything raises one batched error when the chain is built.** The user asked for
  conflicts between nested filters to be checked. The scope is kept as plain data (sets of tags, rules, and
  states), not as functions, so filters can be compared. Repeating a value is allowed, and the rule's own tags are not
  read, because only what the user wrote is compared.
- **`everyHandler.setState` checks every handler first.** The user asked for the handlers that lack the state to be
  batched into one error instead of one by one. It lists the rules with their handler counts, and changes no handler.
- **No function returns the handlers themselves, and there is no snapshot list.** Handles would keep handlers alive
  and the analyzer cannot type `Handler<any>`. `debug` stays the opt-in way to list handlers.
- **A filtered group's `scaleSpeed` is not the global one.** Without `once` it
  calls each matching handler's own `scaleSpeed`, so it does not reach handlers created later and it replaces the
  scale the handler set itself. Only the unfiltered one sets the global scale.
- **One handler failing does not stop the rest.** The first error is raised after every handler has run.

## Debug tools

- **Tracking is opt-in.** Only handlers passed to `debug.track` are listed. Every handler still adds its inspect
  function to a weak table when created, because that is the only way the debug tools can read its internals.
- **The view ships in the package** as `debug.view()`, a Vide component, so users can mount it in their own stories
  or debug screens. The repository story in `stories/` uses it.

## Schemas

- **No 3D schemas,** such as `Vector3`. VideState is for 2D UI. The 2D types `NumberRange`, `NumberSequence`, and `ColorSequence` were added.
- **Sequences are tweened only when their keypoint counts match.** The user accepted this: with different counts there
  is no pairing, so the value switches at the start like a string. A `NumberRange` tweens its minimum and maximum and is
  clamped so the minimum never passes the maximum, because an overshooting easing could break it. A sequence keeps its
  first time at 0 and its last at 1 and keeps the others in order. Each is a composite of Ripple tweens in
  `Transition/Tween/Composite.luau`.

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
