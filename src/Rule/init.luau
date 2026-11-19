const Types = require("@VideState/Types")
const Validation = require("@VideState/Validation")
const Handler = require("@VideState/Handler")
const Info = require("@VideState/Info")
const Table = require("@VideState/Schemas/Primitives/Table")

type Infer<S> = Types.Infer<S>
type States<S> = { [string]: Types.Sources<Infer<S>> }

export type RuleMetaData = Types.RuleMetaData<string>

return function <Fields>(fields: Fields, metaData: RuleMetaData)
    local schema = Table(fields)
    Validation.schema(schema)
    Info.register(metaData)

    return table.freeze({
        _schema = schema,

        new = function(
            states: States<typeof(schema)>,
            initialState: string,
            options: Types.HandlerOptions?
        )
            return Handler(schema, states, initialState, options, metaData.allowedStateNames)
        end,
    })
end
