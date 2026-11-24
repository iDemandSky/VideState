const Vide = require("../packages/roblox/Vide")
const TypedCore = require("../packages/luau/TypedCore")

const Types = require("./Types")
const Validation = require("./Validation")
const OnChange = require("@self/OnChange")
const OnTransition = require("@self/OnTransition")
const SetState = require("@self/SetState")

type Sources<T> = Types.Sources<T>
type Handler<T> = Types.Handler<T>

return function <S>(
    schema: S,
    states: { [string]: Sources<TypedCore.infer<S>> },
    initialState: string,
    options: Types.HandlerOptions?,
    allowedStateNames: { string }?
)
    type Values = TypedCore.infer<S>

    local validatedStates = Validation.states(schema, states, initialState, allowedStateNames)
    local initialSources =
        Validation.state(validatedStates, initialState, "initial") :: { [string]: unknown }

    local currentState = Vide.source(initialState)
    local derivedSources: { [string]: unknown } = {}

    for fieldName in initialSources do
        derivedSources[fieldName] = function(...)
            local activeSources = Validation.state(validatedStates, currentState(), "current")
            return Validation.source(activeSources :: { [string]: unknown }, fieldName)(...)
        end
    end

    local sources = table.freeze(derivedSources) :: Sources<Values>
    local onChange, emitChange = OnChange<<Values>>()
    local transitionOptions = if options == nil then nil else options.onTransition
    local onTransition, emitTransition = OnTransition<<Values>>(transitionOptions)
    local setState = SetState<<Values>>(
        function(stateName: string): Values
            local stateSources = Validation.state(validatedStates, stateName, "selected")
            return Validation.parseState(schema, stateName, stateSources :: Sources<Values>)
        end,
        currentState,
        emitChange,
        emitTransition
    )

    return table.freeze({
        sources = sources,
        currentState = function()
            return currentState()
        end,
        setState = setState,
        onChange = onChange,
        onTransition = onTransition,
    })
end
