const Vide = require("@packages/Vide")
const TypedCore = require("@luau-packages/TypedCore")

const Types = require("@VideState/Types")
const Validation = require("@VideState/Validation")
const OnChange = require("@VideState/Handler/OnChange")
const OnTransition = require("@VideState/Handler/OnTransition")
const SetState = require("@VideState/Handler/SetState")

type Sources<T> = Types.Sources<T>
type Handler<T> = Types.Handler<T>

return function <S>(
    schema: S,
    states: { [string]: TypedCore.infer<S> },
    initialState: string,
    options: Types.HandlerOptions?
)
    type Values = TypedCore.infer<S>

    local validatedStates = Validation.states(schema, states, initialState)
    local initialValues =
        Validation.state(validatedStates, initialState, "initial") :: TypedCore.infer<S>

    local mutableSources: { [string]: unknown } = {}
    local initialFields = initialValues :: { [string]: unknown }

    for fieldName, value in initialFields do
        mutableSources[fieldName] = Vide.source(value)
    end

    local sources = table.freeze(mutableSources) :: Sources<TypedCore.infer<S>>
    local currentState = Vide.source(initialState)
    local onChange, emitChange = OnChange<<Values>>()
    local transitionDuration = if options == nil then nil else options.transitionDuration
    local onTransition, emitTransition = OnTransition<<Values>>(transitionDuration)
    local setState = SetState<<Values>>(
        validatedStates,
        mutableSources,
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
