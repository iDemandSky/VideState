# Contributing

Notes for working on VideState itself. This file is not part of the published package.

## Setup

Run `embr install` first if the pinned tools (Larvae, Rojo, and Lest) are not installed.

Build the Larvae output and serve it with Rojo from the repository root:

```sh
./serve.sh   # macOS, Linux, and Windows with Git Bash
serve.bat    # Windows
```

If either process exits, the launcher refreshes the output and retries after five seconds. Press Ctrl+C to
stop serving. Every command in this file uses forward slashes, which work on all platforms.

## Checks

After every change, run:

```sh
larvae check          # syntax and require errors
larvae lint src tests # lints only the project code, not dist/, packages/, or .lest/
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
| `Transition/` | `onTransition` | Tweens between states. `State` holds what the transition features share, `Connect` makes connections, `Start` starts a transition, `Scheduler` runs the frames, `Config/` validates options, and `Tween/` wraps Ripple. |
| `Pause.luau` | `pause`, `resume`, `onPause`, `onResume` | Pause state for every transition of the handler. |
| `FastForward.luau` | `fastForward` | Speed scale for the running transition. |
| `Finish.luau` | `finish`, `onFinish` | How a transition ends. |
| `SetState.luau` | `setState` | Changes the state and starts the change and transition events. |

Shared types go in `src/Types.luau`, and `src/Utils/StartTimeEvent.luau` is the event that `Pause` and `Finish` use.

## Conventions

- Modules inside `src/` require each other relatively, never through the `@VideState` alias. Aliases are only for dependencies, such as `@packages/Vide` and `@luau-packages/TypedCore`. Larvae rewrites them when it processes the project.
- The Rojo project names the packages folder `packages` in lowercase, to match the `@packages` and `@luau-packages` aliases in `.luaurc`. Do not rename it to `Packages`.
- Schema helpers and individual schema modules are internal. Users should use the builders on `VideState`.
- Update the docs and `CHANGELOG.md` with every API change.
