---
title: Development
description: Build, serve, and test VideState locally.
---

# Development

## Serving

Run `serve.bat` from the repository root. It builds the Larvae output and serves
it with Rojo. If either process exits, the launcher rebuilds the output and
retries after five seconds. Press `Ctrl+C` to stop.

Run `embr install` first if the pinned tools are not installed.

## Schema tests

Run the schema suite in Studio:

```powershell
lest run schemas
```

The suite covers primitive and Roblox value checks, option validation, records,
reactive source validation, and rule handler state changes.

To refresh the local Studio test place:

```powershell
larvae process
rojo build .larvae\build.project.json -o .lest\schema-tests.rbxlx
lest run schemas
```

## Type checks

Type checks live in `tests/types/`:

- `RuleInferenceCheck.luau` must pass strict Luau analysis with the new type
  solver and Roblox definitions.
- `SchemaExports.luau` checks every public schema builder and the inferred
  handler source types.
- `RuleInferenceInvalidCheck.luau` contains intentionally invalid assignments.
  It uses `--!nocheck` so those examples don't appear as normal diagnostics.
