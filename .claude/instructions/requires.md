# Requires

- Modules inside `src/` require each other relatively, never through the `@VideState` alias. In a normal file use `./Sibling` and `../Parent`. In an `init.luau`, `./` and `../` are relative to the folder's own parent, so reach its children with `@self/Child`.
- Aliases are only for dependencies, such as `@packages/Vide` and `@luau-packages/TypedCore`. Larvae rewrites them into the paths Roblox needs when it processes the project.
