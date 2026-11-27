# Schema design

A rule describes its properties with VideState's data type schemas. They are exposed as builders on `VideState`:
`boolean`, `integer`, `float`, `string`, `enum`, `optional`, `table`, `record`, `color3`, `numberRange`, `numberSequence`, `colorSequence`, `udim`, `udim2`, and
`vector2`. The API is documented in `docs/guide/schemas.md`.

## Design rules

- A schema builder returns a mapped table, like the builders in Typed. Arrays are never accepted, because the purpose
  of VideState is to allow seamless property changes by name.
- `record` has fixed string field names, each with its own schema, with no arrays and no extra fields.
- `integer` requires whole numbers. `float` accepts all finite numbers.
- Instance schemas are excluded. `AdReward` and `Collection` are deferred until there are concrete Luau types for them.
- The internal source helper (`src/Schemas/Helper.luau`) wraps a value schema so that a Vide source is accepted. It
  validates the source's current contents and returns the same source. Checking a getter does not prove the setter's
  behavior, and it does not enforce future writes.
- Schema helpers and individual schema modules are internal. Users use the builders on `VideState`.
