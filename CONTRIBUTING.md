# Contributing

Notes for working on VideState itself. This file is not part of the published package.

## Setup

Run `embr install` first if the pinned tools (Larvae, Rojo, and Lest) are not installed.

Run `serve.bat` from the repository to build the Larvae output and serve it with Rojo. If either process
exits, the launcher refreshes the output and retries after five seconds. Press Ctrl+C to stop serving.

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
server.exe analyze --flag:LuauSolverV2=true \
    --definitions=@roblox=<globalStorage>/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau \
    --sourcemap <scratch>/sourcemap.json --platform roblox \
    src tests/types/RuleInferenceCheck.luau tests/types/SchemaExports.luau
```

Keep the sourcemap out of the repository. Without `LuauSolverV2` the analyzer reports false errors.

## Conventions

- Modules inside `src/` require each other relatively, never through the `@VideState` alias. Aliases are only for dependencies.
- The Rojo project names the packages folder `packages` in lowercase, to match the relative requires. Do not rename it to `Packages`.
- Schema helpers and individual schema modules are internal. Users should use the builders on `VideState`.
- Update the docs and `CHANGELOG.md` with every API change.
