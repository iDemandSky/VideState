# Requires

- Modules inside `src/` require each other relatively, never through the `@VideState` alias. In a normal file use `./Sibling` and `../Parent`. In an `init.luau`, `./` and `../` are relative to the folder's own parent, so reach its children with `@self/Child`.
- Dependencies are required relatively too, through the `packages/` folder at the repo root: `require("../packages/roblox/Vide")` and `require("../packages/luau/TypedCore")`, with one `../` per folder level. Never use the `@packages` or `@luau-packages` aliases in `src/`.
- Why: `embr` gives an installed package its own link files at `packages/roblox/<Dep>.luau` and `packages/luau/<Dep>.luau` inside the package's folder, so the relative paths resolve after install. An alias needs a `.luaurc` or `.config.luau`, which a package cannot ship, and Roblox does not read them at runtime. This overrides the global preference for alias requires.
- The aliases in `.luaurc` are still used by `tests/` and the tools, such as `@VideState`, `@packages/Vide`, and `@Lest`.
- To check what consumers get, publish with `embr publish --local`, install it with `embr add videstate` in an empty folder, and confirm that every require in the installed package points at a file that exists.
