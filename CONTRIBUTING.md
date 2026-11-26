# Contributing

Notes for working on VideState itself. This file is not part of the published package.

## Setup

Run `embr install` first if the pinned tools (Larvae, Lest, and Argon) are not installed.

Sync to Studio with [Argon](https://argon.wiki/) by running `serve.cmd` from the repository root (Windows only). It rebuilds `dist/`, starts
`larvae process --watch` in the same window, waits for `.larvae/build.project.json`, and then runs
`argon serve .larvae/build.project.json`. Connect from the Argon plugin in Studio. If the plugin shows
"Failed to connect" while the console prints `invalid Header provided`, turn on **Allow HTTP Requests** for the
place (Game Settings, Security). Close the window to stop the watcher. Every command in this file uses forward slashes. Argon is pinned in `ember.toml`.

Preview the docs site with `docs.cmd` from the repository root (Windows only). It runs `npm install` when `node_modules/`
is missing, then starts the VitePress dev server with `npm run docs:dev` and opens the browser. Close the window to stop it.

## Stories

`stories/` has [UI Labs](https://ui-labs.luau.page/) stories, such as `DebugView.story.luau`, which previews the
debug view with demo handlers. The `ui-labs` package is a dev dependency, so it is not published. To open the
stories, install the UI Labs plugin in Roblox Studio, serve the project, and open the plugin. It runs in Studio's
edit mode, so no playtest is needed.

Larvae only processes `src/`, so stories require VideState and the packages with Instance paths, such as
`require(ReplicatedStorage:WaitForChild("VideState"))`. Do not run `larvae init` to add `stories/` as an input: with
two inputs, Larvae writes `dist/src/` and `dist/stories/`, but the derived Rojo project still points at `dist/`.

## Checks

After every change, run:

```sh
larvae check                  # syntax and require errors
larvae lint src tests stories # lints only the project code, not dist/, packages/, or .lest/
```

Warnings in `.lest/`, `dist/`, and `packages/` come from generated or vendored code and can be ignored.

## Tests

`lest` does not rebuild its test place, so rebuild it before every run:

```sh
larvae process
rojo build .larvae/build.project.json -o .lest/schema-tests.rbxlx
lest schemas
```

The suite needs Roblox Studio, because Vide and Ripple only load inside Roblox. It covers the schema
builders, rules, handlers, `onTransition`, and `info`.

Lest stops a spec file once its tests have run for 15 seconds in total, and reports it as a timeout. Keep
each spec file well under that, and split a file by topic when it grows, as `Rule`, `Transition`, and
`TransitionControls` are split.

## Benchmark

`tests/bench/` measures many handlers transitioning at once. It is a separate suite that never runs by
default:

```sh
larvae process
rojo build .larvae/build.project.json -o .lest/schema-tests.rbxlx
lest bench
```

It prints one `[bench]` line per round, with the time `setState` took on every handler and the average and
worst frame time while they animate. Studio caps the frame rate, so compare runs on the same machine.

## Type checks

`tests/types/RuleInferenceCheck.luau` and `tests/types/SchemaExports.luau` must pass strict Luau analysis
with the new type solver and the Roblox definitions. `tests/types/RuleInferenceInvalidCheck.luau` contains
intentionally invalid assignments and uses `--!nocheck` so they do not show up as normal diagnostics.

The Luau LSP extension ships an analyzer that can run them:

```sh
rojo sourcemap default.project.json -o <scratch>/sourcemap.json
<server> analyze --flag:LuauSolverV2=true \
    --definitions=@roblox=<globalStorage>/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau \
    --sourcemap <scratch>/sourcemap.json --platform roblox \
    src tests/types/RuleInferenceCheck.luau tests/types/SchemaExports.luau
```

- `<server>` is `~/.vscode/extensions/johnnymorganz.luau-lsp-<version>-<platform>/bin/server`, or `server.exe` on Windows.
- `<globalStorage>` is `~/Library/Application Support/Code/User/globalStorage` on macOS, `~/.config/Code/User/globalStorage` on Linux, and `%APPDATA%/Code/User/globalStorage` on Windows.
- `<scratch>` is any folder outside the repository, so the sourcemap stays out of it.

Without `LuauSolverV2` the analyzer reports false errors.

## Handler layout

Each feature of a handler has its own module under `src/Handler/`, with the functions and events it provides.
`src/Handler/init.luau` only creates them and wires them together.

| Module | Provides | Notes |
| --- | --- | --- |
| `Change.luau` | `onChange` | Runs once when the state changes. |
| `StateEvents.luau` | `onEnter`, `onExit` | Runs when the handler enters or leaves one state. |
| `Transition/` | `onTransition` | Tweens between states. `State` holds what the transition features share, `Connect` makes connections, `Start` starts a transition, `Scheduler` runs the frames, `Config/` validates options, and `Tween/` wraps Ripple. |
| `Pause.luau` | `pause`, `resume`, `onPause`, `onResume` | Pause state for every transition of the handler. |
| `ScaleSpeed.luau` | `scaleSpeed` | Speed scale for the running transition. |
| `Finish.luau` | `finish`, `onFinish`, `waitForFinish` | How a transition ends. |
| `SetState.luau` | `setState` | Changes the state and starts the change and transition events. |

Shared types go in `src/Types.luau`, and `src/Utils/StartTimeEvent.luau` is the event that `Pause` and `Finish` use.
`destroy` and the debug inspect function live in `src/Handler/init.luau`, because they read every feature.

`src/Every/` holds `VideState.everyHandler`. Every handler adds itself to `Every/Registry.luau`, a weak table, when it is
created and leaves it on `destroy`. `Every/Handler.luau` builds a group of filters over a snapshot of it, and `Every/Scale.luau` holds the global speed scale that every
handler multiplies its rate by.

`src/Debug/` holds `VideState.debug`. Every handler adds its inspect function to `Debug/Registry.luau`, a weak table,
when it is created. `Debug/init.luau` tracks the handlers passed to `track`, and `Debug/View.luau` is the Vide
component.

## Conventions

- Modules inside `src/` require each other relatively, never through the `@VideState` alias.
- Dependencies are required relatively too, such as `require("../packages/roblox/Vide")`, never through the `@packages` or `@luau-packages` aliases. An installed package gets its own `packages/` link files, so these paths resolve after `embr install`, while an alias would not. The aliases in `.luaurc` are only for `tests/` and the tools.
- The Rojo project names the packages folder `packages` in lowercase, to match those relative requires. Do not rename it to `Packages`.
- Schema helpers and individual schema modules are internal. Users should use the builders on `VideState`.
- Update the docs and `CHANGELOG.md` with every API change.
