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

- Larvae does not infer types. Its language server only offers formatting and code actions, and a deliberate type error (`local x: number = "a"`) produced no diagnostic. Do not treat a clean `larvae check` as proof that the types are right.
- For inference, rely on `tests/types/RuleInferenceCheck.luau` and `tests/types/SchemaExports.luau`. They need strict Luau analysis with the new type solver, so run them with `luau-analyze` or `luau-lsp` when one is available, and otherwise report the types as unverified.
- Treat new lint warnings in `src/` and `tests/` as problems. Warnings in vendored or generated code can be ignored.
