const Vide = require("../../packages/roblox/Vide")

const Types = require("../Types")
const Validation = require("../Validation")

-- Keys allowed in the options of `setState`.
const OPTION_KEYS: { [string]: boolean } = {
    instant = true,
}

-- Validates the options of one `setState` call and returns whether it is instant. The error level of 3 points at
-- the user's call to `setState`.
const function parseOptions(options: unknown): boolean
    if options == nil then
        return false
    end

    if typeof(options) ~= "table" then
        error("setState options must be a table", 3)
    end

    local fields = options :: { [any]: unknown }

    for key in fields do
        local isKnownKey = OPTION_KEYS[key :: any] == true

        if not isKnownKey then
            error("setState options has an unknown key " .. tostring(key), 3)
        end
    end

    local instant = fields.instant

    if instant == nil then
        return false
    end

    if type(instant) ~= "boolean" then
        error("setState instant must be a boolean", 3)
    end

    return instant
end

return function <T>(
    readState: (stateName: string) -> T,
    isDestroyed: () -> boolean,
    currentState: Vide.Source<string>,
    emitStateEvents: (previousState: string, nextState: string) -> (),
    emitChange: Types.StateEmitter<T>,
    emitTransition: Types.StartTransition<T>
)
    return function(stateName: string, options: Types.SetStateOptions?)
        if isDestroyed() then
            error("setState cannot be called after destroy", 2)
        end

        Validation.stateName(stateName, "state name")

        local instant = parseOptions(options)
        local nextValues = readState(stateName)
        local currentStateName = currentState()

        if currentStateName == stateName then
            return
        end

        local currentValues = readState(currentStateName)

        currentState(stateName)

        local from = table.freeze(table.clone(currentValues :: { [string]: unknown })) :: T
        local to = table.freeze(table.clone(nextValues :: { [string]: unknown })) :: T

        -- The order is exit, enter, change, then the transition.
        emitStateEvents(currentStateName, stateName)
        emitChange(from, to)
        emitTransition(from, to, instant)
    end
end
