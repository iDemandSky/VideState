# VideState

A state handler for Vide sources. Vide creates the UI Instances; VideState
manages state changes of their source values, not Instances themselves.

## Schemas

Schema builders are available directly on `VideState`; Typed and TypedCore remain
implementation dependencies.

```luau
const VideState = require("@VideState")

local panelSchema = VideState.table({
    size = VideState.udim2(),
    color = VideState.color3(),
    visible = VideState.boolean(),
    transparency = VideState.float({ min = 0, max = 1 }),
    order = VideState.integer(),
    text = VideState.string({ maxLength = 100 }),
    alignment = VideState.enum("Left", "Center", "Right"),
})

type PanelValues = VideState.Infer<typeof(panelSchema)>

local result = panelSchema.parse(values)
if not result.ok then
    for _, issue in result.issues do
        warn(issue.context, issue.message)
    end
end
```

`table` and `record` accept fixed string field names with individual schemas.
They reject array definitions, missing fields, invalid values, and extra fields.
Nested records are supported. A schema's shape describes child schemas, while
its parser performs validation; `unwrapParse` throws on invalid input.

`float` accepts finite numbers, including integers. `integer` also requires a
whole number. Numeric bounds are inclusive. String length is counted in Unicode
code points. With `truncate = true`, parsing returns the truncated value without
changing the original input. Builder options and field maps are copied so
changing them afterwards does not change those definitions.

### Roblox datatype builders

`color3`, `udim`, `udim2`, and `vector2` validate and infer their corresponding
Roblox datatypes. `enum(...)` checks membership in the provided strings.

There is no Instance schema builder. Schemas describe source values to be bound
to UI properties through Vide.

## Rules and handlers

A rule captures one record schema. `new` takes a dictionary of Vide sources for
each state, keyed by state name. Each handler exposes sources that follow its
active state, so existing Vide bindings remain reactive when the state changes.
At least two states are required, and every state is validated against the
schema when `new` runs.

```luau
const VideState = require("@VideState")
const Vide = require("@packages/Vide")

local PanelRule = VideState.rule({
    visible = VideState.boolean(),
    order = VideState.integer({ min = 0 }),
}, { name = "Panel", allowedStateNames = { "Idle", "Active" } })

type PanelValues = VideState.Infer<typeof(PanelRule._schema)>
type PanelSources = VideState.Sources<PanelValues>

local panel = PanelRule.new({
    Idle = { visible = Vide.source(false), order = Vide.source(0) },
    Active = { visible = Vide.source(true), order = Vide.source(1) },
}, "Idle")

local sources: PanelSources = panel.sources
panel.setState("Active")
```

Handlers expose `sources`, a reactive `currentState` source, and `setState`.
`onChange` registers a callback receiving the previous and next state values;
`onTransition` receives the previous value, the next value, `current`, the eased
value to render, and `alpha`, the eased progress from 0 to 1, over 0.25 seconds by default.
Each handler tweens its animatable fields once and broadcasts the result to every transition
listener. Set the shared easing, duration, and speed per handler with the optional third `new`
argument: `PanelRule.new(states, "Idle", { onTransition = { duration = 0.4 } })`. Both methods
return a disconnect callback, and listeners fire only for future state changes.
Unknown state names and invalid state values raise errors before the active state
changes. Runtime and compile-time rule validation is centralized in
`src/Validation.luau`. State-name typing is currently checked at runtime; field
value types are inferred from the schema. The schema type is retained by the
rule rather than widened to an any-schema.

Schema helpers and individual schema modules are internal implementation details.
Use the camelCase schema builders on `VideState` rather than requiring
submodules.

## Development

Run `serve.bat` from the repository to build the Larvae output and serve it with Rojo. If either process exits, the launcher refreshes the output and retries after five seconds. Run `embr install` first if the pinned tools are not installed. Press Ctrl+C to stop serving.

Before testing in Studio, run `larvae check` for syntax and require errors and `larvae lint` for warnings such as unused variables and shadowing. Warnings in `.lest/`, `dist/`, and `packages/` come from generated or vendored code and can be ignored.

### Schema verification

Run `lest run schemas` to validate centralized schema behavior in Studio.
The suite covers primitive and Roblox value checks, option validation, records,
reactive source validation, and rule handler state changes.

To refresh the local Studio test place, run `larvae process` and
`rojo build .larvae\build.project.json -o .lest\schema-tests.rbxlx`, then run
`lest run schemas`.

`Tests/types/RuleInferenceCheck.luau` must pass strict Luau analysis with the new
type solver and Roblox definitions. `Tests/types/SchemaExports.luau` checks all
public schema builders and the inferred handler source types.
`Tests/types/RuleInferenceInvalidCheck.luau`
contains intentionally invalid value and source assignments and uses
`--!nocheck` to keep those examples from surfacing as normal diagnostics.
