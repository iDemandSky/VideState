const Constants = require("@VideState/Handler/OnTransition/Config/Constants")

const function isAnimatablePrimitive(value: unknown): boolean
    local valueType = typeof(value)
    return valueType == "number" or valueType == "vector" or valueType == "Vector3"
end

-- Tables are only tweened when every component is a number or vector with the same key set.
return function(from: unknown, to: unknown): boolean
    local valueType = typeof(from)
    if valueType ~= typeof(to) then
        return false
    end
    if valueType ~= "table" then
        return Constants.ANIMATABLE_TYPES[valueType] == true
    end

    local fromTable = from :: { [any]: unknown }
    local toTable = to :: { [any]: unknown }
    for key, value in toTable do
        if not isAnimatablePrimitive(value) or typeof(fromTable[key]) ~= typeof(value) then
            return false
        end
    end
    for key in fromTable do
        if toTable[key] == nil then
            return false
        end
    end
    return true
end
