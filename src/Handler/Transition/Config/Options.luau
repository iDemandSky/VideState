const Types = require("../../../Types")
const Constants = require("./Constants")

-- The settings of one handler, read when a transition starts and again every frame.
export type Settings = {
    read getEasing: () -> Types.TweenName,
    read getDuration: () -> number,
    read getSpeed: () -> number,
    -- Read once, when a transition starts.
    read getDelay: () -> number,
}

const function isValidEasing(value: unknown): boolean
    if type(value) ~= "string" then
        return false
    end

    return Constants.TWEEN_NAMES[value] == true
end

-- A number that is not NaN, not infinite, and not negative.
const function isFiniteNonNegative(value: unknown): boolean
    if type(value) ~= "number" then
        return false
    end

    local isNotNaN = value == value
    local isNotNegative = value >= 0
    local isNotInfinite = value ~= math.huge

    return isNotNaN and isNotNegative and isNotInfinite
end

const function isNegativeNumber(value: unknown): boolean
    if type(value) ~= "number" then
        return false
    end

    return value < 0
end

const function isValidDuration(value: unknown): boolean
    return isFiniteNonNegative(value)
end

const function isValidSpeed(value: unknown): boolean
    return isFiniteNonNegative(value)
end

const function isValidDelay(value: unknown): boolean
    return isFiniteNonNegative(value)
end

-- Rejects options with keys outside the allowed set, so a misspelled or outdated key fails instead of being ignored.
-- A setting that used to sit at the top level now belongs in `tweenDefault`, and the error says so.
const function checkOptions(options: unknown)
    if typeof(options) ~= "table" then
        error("onTransition options must be a table", 0)
    end

    local fields = options :: { [any]: unknown }

    for key in fields do
        local isOption = Constants.OPTION_KEYS[key :: any] == true
        local isSetting = Constants.SETTING_KEYS[key :: any] == true

        if isOption then
            continue
        end

        if isSetting then
            error(`onTransition options has an unknown key {key}. Put {key} inside tweenDefault`, 0)
        end

        error("onTransition options has an unknown key " .. tostring(key), 0)
    end
end

const function checkSettings(settings: unknown)
    if typeof(settings) ~= "table" then
        error("onTransition tweenDefault must be a table", 0)
    end

    local fields = settings :: { [any]: unknown }

    for key in fields do
        if Constants.SETTING_KEYS[key :: any] ~= true then
            error("onTransition tweenDefault has an unknown key " .. tostring(key), 0)
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

const function validateDelay(value: unknown)
    local current = if typeof(value) == "function" then (value :: () -> unknown)() else value

    if not isValidDelay(current) then
        error("onTransition delay must be a finite non-negative number", 0)
    end
end

const function validateSpeed(value: unknown)
    if typeof(value) ~= "function" then
        error("onTransition speed must be a source", 0)
    end

    local current = (value :: () -> unknown)()

    if isNegativeNumber(current) then
        error("onTransition speed must not be negative", 0)
    end

    if not isValidSpeed(current) then
        error("onTransition speed must be a finite non-negative number", 0)
    end
end

-- A negative speed is clamped to 0 so a transition never moves backwards. Any other invalid speed plays at normal speed.
const function fallbackSpeed(value: unknown): number
    if isNegativeNumber(value) then
        return 0
    end

    return Constants.DEFAULT_SPEED
end

-- Validates tween settings and returns readers for each one. A setting that `settings` leaves out is read from
-- `base`, which is how an override inherits the settings of its connection. With no `base`, it takes the
-- default.
const function parseSettings(settings: Types.TweenSettings?, base: Settings?): Settings
    local easing: unknown = nil
    local duration: unknown = nil
    local speed: unknown = nil
    local delay: unknown = nil

    if settings ~= nil then
        checkSettings(settings)

        if settings.easing ~= nil then
            validateEasing(settings.easing)
            easing = settings.easing
        end

        if settings.duration ~= nil then
            validateDuration(settings.duration)
            duration = settings.duration
        end

        if settings.speed ~= nil then
            validateSpeed(settings.speed)
            speed = settings.speed
        end

        if settings.delay ~= nil then
            validateDelay(settings.delay)
            delay = settings.delay
        end
    end

    local getEasing: () -> Types.TweenName
    local getDuration: () -> number
    local getSpeed: () -> number
    local getDelay: () -> number

    if easing ~= nil then
        getEasing = createReader<<Types.TweenName>>(easing, isValidEasing, function(): Types.TweenName
            return Constants.DEFAULT_EASING :: Types.TweenName
        end)
    elseif base ~= nil then
        getEasing = base.getEasing
    else
        getEasing = function(): Types.TweenName
            return Constants.DEFAULT_EASING :: Types.TweenName
        end
    end

    if duration ~= nil then
        getDuration = createReader<<number>>(duration, isValidDuration, function(): number
            return Constants.DEFAULT_DURATION
        end)
    elseif base ~= nil then
        getDuration = base.getDuration
    else
        getDuration = function(): number
            return Constants.DEFAULT_DURATION
        end
    end

    if speed ~= nil then
        getSpeed = createReader<<number>>(speed, isValidSpeed, fallbackSpeed)
    elseif base ~= nil then
        getSpeed = base.getSpeed
    else
        getSpeed = function(): number
            return Constants.DEFAULT_SPEED
        end
    end

    if delay ~= nil then
        getDelay = createReader<<number>>(delay, isValidDelay, function(): number
            return Constants.DEFAULT_DELAY
        end)
    elseif base ~= nil then
        getDelay = base.getDelay
    else
        getDelay = function(): number
            return Constants.DEFAULT_DELAY
        end
    end

    return table.freeze({
        getEasing = getEasing,
        getDuration = getDuration,
        getSpeed = getSpeed,
        getDelay = getDelay,
    })
end

-- Validates the options of `onTransition` and `animate` and returns the settings of `tweenDefault`.
const function parse(options: Types.TransitionOptions?, base: Settings?): Settings
    if options == nil then
        return parseSettings(nil, base)
    end

    checkOptions(options)

    return parseSettings(options.tweenDefault, base)
end

return table.freeze({
    parse = parse,
    parseSettings = parseSettings,
})
