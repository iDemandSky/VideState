# Larvae checks

After every code change, run Larvae before testing and fix what it reports:

```sh
larvae check          # syntax and require errors
larvae lint src tests stories # lints only the project code, not dist/, packages/ or .lest/
```

- Larvae does not infer types. Its language server only offers formatting and code actions, so a clean `larvae check` is not proof that the types are right.
- For type inference, use the analyzer bundled with the Luau LSP VS Code extension (`bin/server` inside `~/.vscode/extensions/johnnymorganz.luau-lsp-*`, `server.exe` on Windows). It needs the new type solver, the Roblox definitions, and a fresh sourcemap. The command and the per-OS location of `<globalStorage>` are in the "Type checks" section of `CONTRIBUTING.md`. Keep the sourcemap out of the repo. `src` and the type tests must report no errors. Without `LuauSolverV2` the analyzer reports false errors, such as `read keyword is illegal here`.
- Regenerate the sourcemap after adding, moving, or removing a file. A stale one makes the analyzer report `Unknown require` for the new files. The editor reads the ignored `sourcemap.json` in the repo root, so refresh that one as well.
- The Rojo project names the packages folder `packages` in lowercase, to match the relative requires such as `../packages/luau/TypedCore`. The analyzer matches instance names case-sensitively, so do not rename it back to `Packages`.
- Treat new lint warnings in `src/` and `tests/` as problems. Warnings in vendored or generated code can be ignored.
- There is no `larvae.toml` on purpose, so Larvae processes only `src/`. `larvae init` was tried: it turned off Luau's lints in `.luaurc`, set tabs for formatting, and with `stories/` as a second input it wrote `dist/src/` while the derived Rojo project still pointed at `dist/`. Do not run it again unless the user asks. This overrides the global rule to create the config with `larvae init`.
- Vide's `create` takes properties and children in one table, which the `mixed_table` lint flags. Larvae has no inline allow, so create the parent with properties only and give each child `Parent = parent`. See `src/Debug/View.luau`.
- `larvae fmt --check` currently flags some test files. Do not reformat files you are not otherwise changing.
