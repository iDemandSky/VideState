# VideState

Project rules and design notes live in `.claude/instructions/`, not here. Keep them there; this file only loads them. When a rule changes, edit the file in `.claude/instructions/`. Do not copy it into this file.

## Always loaded

@instructions/overview.md
@instructions/status.md
@instructions/decisions.md
@instructions/dependencies.md
@instructions/handlers.md
@instructions/schemas.md
@instructions/git.md
@instructions/documentation.md
@instructions/readme-and-docs-site.md
@instructions/release.md
@instructions/testing.md
@instructions/larvae-checks.md
@instructions/cross-platform-paths.md
@instructions/requires.md

## Layout

- `src/`: the package. `Handler/` has one module per handler feature, `Rule/` and `Schemas/` hold the rest.
- `tests/`: `schemas/` has the `lest` specs, `types/` has the files the type analyzer checks.
- `docs/`: the VitePress site (`guide/` and `examples/`).
- `.claude/instructions/`: the rules above.
