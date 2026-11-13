const Vide = require("@packages/Vide")

const Validation = require("../Validation")

return function <T>(
    validatedStates: { [string]: T },
    mutableSources: { [string]: unknown },
    currentState: Vide.Source<string>,
    emitChange: (from: T, to: T) -> (),
    emitTransition: (from: T, to: T) -> ()
)
    return function(stateName: string)
        Validation.stateName(stateName, "state name")

        local nextValues = Validation.state(validatedStates, stateName, "selected") :: T
        local currentStateName = currentState()

        if currentStateName == stateName then
            return
        end

        local currentValues = Validation.state(
            validatedStates,
            currentStateName,
            "current"
        ) :: T

        Vide.batch(function()
            local nextFields = nextValues :: { [string]: unknown }

            for fieldName, value in nextFields do
                local writableSource = Validation.source(mutableSources, fieldName)
                writableSource(value)
            end

            currentState(stateName)
        end)

        local from = table.freeze(table.clone(currentValues :: { [string]: unknown })) :: T
        local to = table.freeze(table.clone(nextValues :: { [string]: unknown })) :: T

        emitChange(from, to)
        emitTransition(from, to)
    end
end
