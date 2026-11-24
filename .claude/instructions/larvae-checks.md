# Larvae checks

After every code change, run Larvae before testing and fix what it reports:

```sh
larvae check          # syntax and require errors
larvae lint src tests # lints only the project code, not dist/, packages/ or .lest/
```

- Larvae does not infer types. Its language server only offers formatting and code actions, so a clean `larvae check` is not proof that the types are right.
- For type inference, use the analyzer bundled with the Luau LSP VS Code extension (`bin/server` inside `~/.vscode/extensions/johnnymorganz.luau-lsp-*`, `server.exe` on Windows). It needs the new type solver, the Roblox definitions, and a fresh sourcemap. The command and the per-OS location of `<globalStorage>` are in the "Type checks" section of `CONTRIBUTING.md`. Keep the sourcemap out of the repo. `src` and the type tests must report no errors. Without `LuauSolverV2` the analyzer reports false errors, such as `read keyword is illegal here`.
- Regenerate the sourcemap after adding, moving, or removing a file. A stale one makes the analyzer report `Unknown require` for the new files. The editor reads the ignored `sourcemap.json` in the repo root, so refresh that one as well.
- The Rojo project names the packages folder `packages` in lowercase, to match the relative requires such as `../packages/luau/TypedCore`. The analyzer matches instance names case-sensitively, so do not rename it back to `Packages`.
- Treat new lint warnings in `src/` and `tests/` as problems. Warnings in vendored or generated code can be ignored.
- `larvae fmt --check` currently flags some test files. Do not reformat files you are not otherwise changing.
