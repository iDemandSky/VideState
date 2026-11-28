const Vide = require("../../packages/roblox/Vide")

const Types = require("../Types")
const Validation = require("../Validation")
const ReducedMotion = require("../ReducedMotion")
const Transitions = require("../Transitions")

-- Keys allowed in the options of `setState`.
const OPTION_KEYS: { [string]: boolean } = {
    instant = true,
    delay = true,
}

-- Validates the options of one `setState` call and returns whether it is instant and how long it waits. The error
-- level of 3 points at the user's call to `setState`.
const function parseOptions(options: unknown): (boolean, number)
    if options == nil then
        return false, 0
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
    local delay = fields.delay

    if instant ~= nil and type(instant) ~= "boolean" then
        error("setState instant must be a boolean", 3)
    end

    if delay == nil then
        return instant == true, 0
    end

    if type(delay) ~= "number" then
        error("setState delay must be a finite non-negative number", 3)
    end

    local isNotNaN = delay == delay
    local isNotNegative = delay >= 0
    local isNotInfinite = delay ~= math.huge
    local isValid = isNotNaN and isNotNegative and isNotInfinite

    if not isValid then
        error("setState delay must be a finite non-negative number", 3)
    end

    return instant == true, delay
end

return function <T>(
    readState: (stateName: string) -> T,
    isDestroyed: () -> boolean,
    currentState: Vide.Source<string>,
    transitionRules: Transitions.Rules?,
    emitStateEvents: (previousState: string, nextState: string) -> (),
    emitChange: Types.StateEmitter<T>,
    emitTransition: Types.StartTransition<T>
)
    return function(stateName: string, options: Types.SetStateOptions?)
        if isDestroyed() then
            error("setState cannot be called after destroy", 2)
        end

        Validation.stateName(stateName, "state name")

        -- With reduced motion on, every state change is instant, whatever the options say.
        local requestedInstant, delay = parseOptions(options)
        local instant = requestedInstant or ReducedMotion.get()
        local nextValues = readState(stateName)
        local currentStateName = currentState()

        if currentStateName == stateName then
            return
        end

        if not Transitions.canChange(transitionRules, currentStateName, stateName) then
            const rules = transitionRules :: Transitions.Rules

            error(
                `cannot change state from "{currentStateName}" to "{stateName}". Allowed: {Transitions.describeAllowed(rules, currentStateName)}`,
                2
            )
        end

        local currentValues = readState(currentStateName)

        currentState(stateName)

        local from = table.freeze(table.clone(currentValues :: { [string]: unknown })) :: T
        local to = table.freeze(table.clone(nextValues :: { [string]: unknown })) :: T

        -- The order is exit, enter, change, then the transition.
        emitStateEvents(currentStateName, stateName)
        emitChange(from, to)
        emitTransition(from, to, instant, currentStateName, stateName, delay)
    end
end
