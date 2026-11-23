const Types = require("@VideState/Types")
const Constants = require("@VideState/Handler/OnTransition/Config/Constants")

-- The settings of one handler, read when a transition starts and again every frame.
export type Settings = {
    getEasing: () -> Types.TweenName,
    getDuration: () -> number,
    getSpeed: () -> number,
}

const function isValidEasing(value: unknown): boolean
    return type(value) == "string" and Constants.TWEEN_NAMES[value] == true
end

const function isValidDuration(value: unknown): boolean
    return type(value) == "number" and value == value and value >= 0 and value ~= math.huge
end

const function isValidSpeed(value: unknown): boolean
    return type(value) == "number" and value == value and value >= 0 and value ~= math.huge
end

-- Rejects options with keys outside the allowed set, so a misspelled or outdated key fails instead of being ignored.
const function checkKeys(options: unknown)
    if typeof(options) ~= "table" then
        error("onTransition options must be a table", 0)
    end

    local fields = options :: { [any]: unknown }

    for key in fields do
        if Constants.OPTION_KEYS[key :: any] ~= true then
            error("onTransition options has an unknown key " .. tostring(key), 0)
        end
    end
end

-- Reads a plain value or a source. A source that later returns an invalid value falls back to `fallback`,
-- because an error inside the frame loop would stop the transition.
const function createReader<V>(value: unknown, isValid: (unknown) -> boolean, fallback: (unknown) -> V): () -> V
    if typeof(value) == "function" then
        local source = value :: () -> unknown

        return function(): V
            local current = source()

            if isValid(current) then
                return current :: V
            end

            return fallback(current)
        end
    end

    return function(): V
        return value :: V
    end
end

const function validateEasing(value: unknown)
    local current = if typeof(value) == "function" then (value :: () -> unknown)() else value

    if not isValidEasing(current) then
        error("onTransition easing must be a known easing name", 0)
    end
end

const function validateDuration(value: unknown)
    local current = if typeof(value) == "function" then (value :: () -> unknown)() else value

    if not isValidDuration(current) then
        error("onTransition duration must be a finite non-negative number", 0)
    end
end

const function validateSpeed(value: unknown)
    if typeof(value) ~= "function" then
        error("onTransition speed must be a source", 0)
    end

    local current = (value :: () -> unknown)()

    if type(current) == "number" and current < 0 then
        error("onTransition speed must not be negative", 0)
    end

    if not isValidSpeed(current) then
        error("onTransition speed must be a finite non-negative number", 0)
    end
end

-- A negative speed is clamped to 0 so a transition never moves backwards. Any other invalid speed plays at normal speed.
const function fallbackSpeed(value: unknown): number
    if type(value) == "number" and value < 0 then
        return 0
    end

    return Constants.DEFAULT_SPEED
end

-- Validates the `onTransition` handler options and returns readers for each setting.
const function parse(options: Types.TransitionOptions?): Settings
    local easing: unknown = Constants.DEFAULT_EASING
    local duration: unknown = Constants.DEFAULT_DURATION
    local speed: unknown = nil

    if options ~= nil then
        checkKeys(options)

        if options.easing ~= nil then
            validateEasing(options.easing)
            easing = options.easing
        end

        if options.duration ~= nil then
            validateDuration(options.duration)
            duration = options.duration
        end

        if options.speed ~= nil then
            validateSpeed(options.speed)
            speed = options.speed
        end
    end

    local getSpeed: () -> number = if speed == nil
        then function(): number
            return Constants.DEFAULT_SPEED
        end
        else createReader(speed, isValidSpeed, fallbackSpeed)

    return table.freeze({
        getEasing = createReader(easing, isValidEasing, function(): Types.TweenName
            return Constants.DEFAULT_EASING
        end),
        getDuration = createReader(duration, isValidDuration, function(): number
            return Constants.DEFAULT_DURATION
        end),
        getSpeed = getSpeed,
    })
end

return table.freeze({
    parse = parse,
})
