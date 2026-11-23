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
