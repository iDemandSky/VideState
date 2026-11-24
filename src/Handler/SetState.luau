const Vide = require("@packages/Vide")

const Validation = require("../Validation")

return function <T>(
    readState: (stateName: string) -> T,
    currentState: Vide.Source<string>,
    emitChange: (from: T, to: T) -> (),
    emitTransition: (from: T, to: T) -> ()
)
    return function(stateName: string)
        Validation.stateName(stateName, "state name")

        local nextValues = readState(stateName)
        local currentStateName = currentState()

        if currentStateName == stateName then
            return
        end

        local currentValues = readState(currentStateName)

        currentState(stateName)

        local from = table.freeze(table.clone(currentValues :: { [string]: unknown })) :: T
        local to = table.freeze(table.clone(nextValues :: { [string]: unknown })) :: T

        emitChange(from, to)
        emitTransition(from, to)
    end
end
