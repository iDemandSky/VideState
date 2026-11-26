# VideState overview

VideState is a UI state handler specifically for Vide. It lets developers transition UI components between states.
Nothing more, nothing less.

Vide creates the UI Instances. VideState handles state changes of source values, not the creation or management of
Instances.

## Usage

1. Create a rule with `VideState.rule(schema, metadata)`. The rule is the blueprint of a component: the properties it
   has and the states it can be in. A rule validates the values of every state, and a handler created from it
   inherits that.
2. Create a handler with `rule.new(states, initialState)`. Each UI component gets its own handler, with its own
   state, sources, and cleanup. The initial state must be chosen before the UI is declared through Vide.
3. Bind `handler.sources.<field>` to Vide properties. They follow the active state.
4. Change the state with `handler.setState(name)`, and react with the handler's events and transitions.

Flow: create rule -> new handler with the states -> validate, error if invalid -> use the handler's functions.

## Where the details are

- The public API is documented in `docs/guide/` (rules, handlers, schemas, transitions) and `docs/examples/`.
- The handler functions are listed in [handlers.md](handlers.md), and the schema rules in [schemas.md](schemas.md).
- `CONTRIBUTING.md` has the setup, checks, tests, type checks, and the layout of `src/Handler/`.
