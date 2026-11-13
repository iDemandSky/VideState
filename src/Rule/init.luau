const Types = require("@VideState/Types")
const Validation = require("@VideState/Validation")
const Handler = require("@VideState/Handler")

type Infer<S> = Types.Infer<S>
type States<S> = { [string]: Infer<S> }

return function <S>(schema: S)
    Validation.schema(schema)

    return table.freeze({
        schema = schema,
        new = function(
            states: States<S>,
            initialState: string,
            options: Types.HandlerOptions?
        )
            return Handler(schema, states, initialState, options)
        end,
    })
end