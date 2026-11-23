const Types = require("@VideState/Types")
const Constants = require("@VideState/Handler/OnTransition/Config/Constants")

export type Settings = {
    easing: Types.TweenName?,
    duration: number,
    speed: Types.Source<number>?,
}

const function isValidDuration(value: unknown): boolean
    return type(value) == "number" and value == value and value >= 0 and value ~= math.huge
end

-- Rejects metadata with keys outside the allowed set, so a misspelled or outdated key fails instead of being ignored.
const function checkKeys(value: unknown)
    if typeof(value) ~= "table" then
        error("onTransition metadata must be a table", 4)
    end

    local fields = value :: { [any]: unknown }

    for key in fields do
        if Constants.METADATA_KEYS[key :: any] ~= true then
            error("onTransition metadata has an unknown key " .. tostring(key), 4)
        end
    end
end

-- Validates the metadata given to `onTransition`. Errors point at the caller of `onTransition`.
const function parse(metadata: Types.TweenMetadata?, defaultDuration: number): Settings
    local settings: Settings = {
        easing = nil,
        duration = defaultDuration,
        speed = nil,
    }

    if metadata == nil then
        return settings
    end

    checkKeys(metadata)

    local easing = metadata.easing

    if easing ~= nil then
        if Constants.TWEEN_NAMES[easing] ~= true then
            error("onTransition easing must be a known easing name", 3)
        end

        settings.easing = easing
    end

    local duration = metadata.duration

    if duration ~= nil then
        if not isValidDuration(duration) then
            error("onTransition duration must be a finite non-negative number", 3)
        end

        settings.duration = duration
    end

    local speed = metadata.speed

    if speed ~= nil then
        if typeof(speed) ~= "function" then
            error("onTransition speed must be a source", 3)
        end

        settings.speed = speed
    end

    return settings
end

return table.freeze({
    isValidDuration = isValidDuration,
    parse = parse,
})
