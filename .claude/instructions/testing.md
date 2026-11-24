# Testing

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
