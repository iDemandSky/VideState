# Documentation

Whenever you add, edit, or delete a feature, update the documentation in the same change. Scope it by class:

| Class | Source | Docs to update |
|---|---|---|
| `Rule` | `src/Rule/` | `docs/guide/rules.md` |
| `Handler` | `src/Handler/` | `docs/guide/handlers.md`, and `docs/guide/transitions.md` for `onTransition` |
| `Schemas` | `src/Schemas/` | `docs/guide/schemas.md` |
| `debug` | `src/Debug/` | `docs/guide/debug.md` |
| `info` | `src/Info.luau` | `docs/guide/info.md` |
| `everyHandler` | `src/Every/` | `docs/guide/every-handler.md` |
| Manual clock | `src/Clock.luau` | `docs/guide/testing.md` |
| Reduced motion, custom easing | `src/ReducedMotion.luau`, `Transition/Tween/Custom.luau` | `docs/guide/transitions.md` |
| `extend` | `src/Rule/Extend.luau` | `docs/guide/rules.md` |

- Also update any `docs/examples/` page and the README section that uses the changed API.
- Public type changes in `src/Types.luau` go in the doc of the class they belong to.
- Removed features must be removed from the docs too, not left as stale references.
- Every API entry has a version badge at the end of its heading line, such as `<Badge type="tip" text="Added in 0.1.0" />`. When you change an API, add a `Changed in <version>` warning badge with a one-line note, and a `Removed in` or `Deprecated in` danger badge when it goes away. Use the version in `ember.toml` that the change will ship in, and add the matching entry to `CHANGELOG.md`.
- Commit the docs together with the code they describe.
- When a release changes the API in a way that needs the user's code to change, add a page to `docs/migration/` named `to-<version>.md`, with a before and after, and add it to the Migration section of the sidebar in `docs/.vitepress/config.mts`. A release with no breaking change still gets a short page that says so.
