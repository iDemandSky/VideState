# VideState

Project background and API notes: see [instructions/README.md](instructions/README.md).

Git workflow follows the global rules in `~/.claude/CLAUDE.md` (commit to `dev` after each feature change, Conventional Commits).

## Documentation

Whenever you add, edit, or delete a feature, update the documentation in the same change. Scope it by class:

| Class | Source | Docs to update |
|---|---|---|
| `Rule` | `src/Rule/` | `docs/guide/rules.md` |
| `Handler` | `src/Handler/` | `docs/guide/handlers.md`, and `docs/guide/transitions.md` for `onTransition` |
| `Schemas` | `src/Schemas/` | `docs/guide/schemas.md` |

- Also update any `docs/examples/` page and the README section that uses the changed API.
- Public type changes in `src/Types.luau` go in the doc of the class they belong to.
- Removed features must be removed from the docs too, not left as stale references.
- Every API entry has a version badge under its heading, such as `<Badge type="tip" text="Added in 0.1.0" />`. When you change an API, add a `Changed in <version>` warning badge with a one-line note, and a `Removed in` or `Deprecated in` danger badge when it goes away. Use the version in `ember.toml` that the change will ship in, and add the matching entry to `CHANGELOG.md`.
- Commit the docs together with the code they describe.

## Testing

- `lest` does not rebuild its test place, so it can silently run stale code. Always rebuild first, then run:
  ```sh
  larvae process
  rojo build .larvae/build.project.json -o .lest/schema-tests.rbxlx
  lest schemas
  ```
  Use `lest schemas -t "<text>"` to run only tests whose name contains the text.
- Building the place from `default.project.json` fails, because the `@VideState` aliases are only rewritten by `larvae process`.
- The suite needs the `studio` backend because Vide and Ripple only load inside Roblox. The `native` backend fails at `require` of Vide.
- If Studio fails to launch, report the change as unverified.

## Larvae checks

After every code change, run Larvae before testing and fix what it reports:

```sh
larvae check          # syntax and require errors
larvae lint src tests # lints only the project code, not dist/, packages/ or .lest/
```

- Larvae does not infer types. Its language server only offers formatting and code actions, so a clean `larvae check` is not proof that the types are right.
- For type inference, use the analyzer bundled with the Luau LSP VS Code extension (`bin/server.exe` inside `~/.vscode/extensions/johnnymorganz.luau-lsp-*`). It needs the new type solver, the Roblox definitions, and a fresh sourcemap:

  ```sh
  rojo sourcemap default.project.json -o <scratch>/sourcemap.json
  server.exe analyze --flag:LuauSolverV2=true       --definitions=@roblox=<globalStorage>/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau       --sourcemap <scratch>/sourcemap.json --platform roblox       src tests/types/RuleInferenceCheck.luau tests/types/SchemaExports.luau
  ```

  `<globalStorage>` is `~/AppData/Roaming/Code/User/globalStorage`. Keep the sourcemap out of the repo. `src` and the type tests must report no errors. Without `LuauSolverV2` the analyzer reports false errors, such as `read keyword is illegal here`.
- The Rojo project names the packages folder `packages` in lowercase, to match the relative requires such as `../packages/luau/TypedCore`. The analyzer matches instance names case-sensitively, so do not rename it back to `Packages`.
- Treat new lint warnings in `src/` and `tests/` as problems. Warnings in vendored or generated code can be ignored.

## Requires

- Modules inside `src/` require each other relatively, never through the `@VideState` alias. In a normal file use `./Sibling` and `../Parent`. In an `init.luau`, `./` and `../` are relative to the folder's own parent, so reach its children with `@self/Child`.
- Aliases are only for dependencies, such as `@packages/Vide` and `@luau-packages/TypedCore`.
