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
- Lest stops a spec file after 15 seconds of tests in total and reports `spec exceeded its deadline`. That is not a hang. Keep each file well under it, and split a file by topic when it grows (`Rule`, `Transition`, `TransitionControls`).
- Studio's first frame can take over a second. A test that runs first can see a short transition finish early, so use durations of a few seconds where a test needs the transition to still be running, and `scaleSpeed` to end it quickly.
- `lest bench` runs the benchmark in `tests/bench/`. See `CONTRIBUTING.md`.
