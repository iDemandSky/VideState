const Types = require("./Types")
const Validation = require("./Validation")
const Handler = require("./Handler")
const Info = require("./Info")
const Table = require("./Schemas/Primitives/Table")

type Infer<S> = Types.Infer<S>
type States<S> = { [string]: Types.Sources<Infer<S>> }

export type RuleMetadata = Types.RuleMetadata<string>

return function <Fields>(fields: Fields, metadata: RuleMetadata)
    local schema = Table(fields)
    Validation.schema(schema)
    Info.register(metadata)

    return table.freeze({
        _schema = schema,

        new = function(
            states: States<typeof(schema)>,
            initialState: string,
            options: Types.HandlerOptions?
        )
            return Handler(schema, states, initialState, options, metadata.allowedStateNames, metadata.name)
        end,
    })
end
