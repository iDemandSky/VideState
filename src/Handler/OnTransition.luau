const Types = require("../Types")
const Ripple = require("@packages/Ripple")

const DEFAULT_DURATION = 0.25

const TWEEN_NAMES: { [string]: boolean } = {
    linear = true,
    quadIn = true,
    quadOut = true,
    quadInOut = true,
    cubicIn = true,
    cubicOut = true,
    cubicInOut = true,
    sineIn = true,
    sineOut = true,
    sineInOut = true,
    expoIn = true,
    expoOut = true,
    expoInOut = true,
    backIn = true,
    backOut = true,
    backInOut = true,
    elasticIn = true,
    elasticOut = true,
    elasticInOut = true,
}

const METADATA_KEYS: { [string]: boolean } = { ripple = true }
const RIPPLE_KEYS: { [string]: boolean } = { easing = true, duration = true }

const ANIMATABLE_TYPES: { [string]: boolean } = {
    number = true,
    vector = true,
    Vector2 = true,
    Vector3 = true,
    CFrame = true,
    Color3 = true,
    UDim = true,
    UDim2 = true,
    Rect = true,
}

type Callback<T> = Types.OnTransitionCallback<T>
type Disconnect = Types.Disconnect
type Listener<T> = {
    callback: Callback<T>,
    easing: Types.TweenName?,
    duration: number,
}
type Run<T> = {
    id: number,
    callback: Callback<T>,
    duration: number,
    elapsed: number,
    tweens: { [string]: Ripple.Tween<any> },
}

const function isAnimatablePrimitive(value: unknown): boolean
    local valueType = typeof(value)
    return valueType == "number" or valueType == "vector" or valueType == "Vector3"
end

-- Tables are only tweened when every component is a number or vector with the same key set.
const function canTween(from: unknown, to: unknown): boolean
    local valueType = typeof(from)
    if valueType ~= typeof(to) then
        return false
    end
    if valueType ~= "table" then
        return ANIMATABLE_TYPES[valueType] == true
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

const function createFieldTweens<T>(
    from: T,
    to: T,
    easing: Types.TweenName?,
    duration: number
): { [string]: Ripple.Tween<any> }
    local tweens: { [string]: Ripple.Tween<any> } = {}
    local fromFields = from :: any
    local toFields = to :: any

    for key, toValue in toFields do
        local fromValue = fromFields[key]
        if canTween(fromValue, toValue) then
            local tween = Ripple.createTween(fromValue, { easing = easing, duration = duration })
            tween:setGoal(toValue)
            tweens[key] = tween
        end
    end

    return tweens
end

-- Fields that can't be tweened keep their target value, so they switch at the start of the transition.
const function frameValue<T>(to: T, tweens: { [string]: Ripple.Tween<any> }, deltaTime: number): T
    local current = table.clone(to :: any)
    for key, tween in tweens do
        current[key] = tween:step(deltaTime)
    end
    return table.freeze(current)
end

-- Rejects metadata with keys outside the allowed set, so a misspelled or outdated key fails instead of being ignored.
const function checkKeys(value: unknown, allowedKeys: { [string]: boolean }, name: string)
    if typeof(value) ~= "table" then
        error("onTransition " .. name .. " must be a table", 3)
    end
    local fields = value :: { [any]: unknown }
    for key in fields do
        if allowedKeys[key :: any] ~= true then
            error("onTransition " .. name .. " has an unknown key " .. tostring(key), 3)
        end
    end
end

const function isValidDuration(value: unknown): boolean
    return type(value) == "number" and value == value and value >= 0 and value ~= math.huge
end

return function <T>(duration: number?)
    local transitionDuration = if duration == nil then DEFAULT_DURATION else duration
    if not isValidDuration(transitionDuration) then
        error("transition duration must be a finite non-negative number", 2)
    end

    local listeners: { [number]: Listener<T> } = {}
    local nextId = 0
    local generation = 0

    return function(callback: Callback<T>, tweenMetadata: Types.TweenMetadata?): Disconnect
        if typeof(callback) ~= "function" then
            error("onTransition callback must be a function", 2)
        end

        local easing: Types.TweenName? = nil
        local listenerDuration = transitionDuration
        if tweenMetadata ~= nil then
            checkKeys(tweenMetadata, METADATA_KEYS, "metadata")
            local ripple = (tweenMetadata :: Types.TweenMetadata).ripple
            if ripple ~= nil then
                checkKeys(ripple, RIPPLE_KEYS, "ripple metadata")
                easing = ripple.easing
                if easing ~= nil and TWEEN_NAMES[easing] ~= true then
                    error("onTransition ripple easing must be a known easing name", 2)
                end
                if ripple.duration ~= nil then
                    if not isValidDuration(ripple.duration) then
                        error("onTransition ripple duration must be a finite non-negative number", 2)
                    end
                    listenerDuration = ripple.duration
                end
            end
        end

        nextId += 1
        local id = nextId
        listeners[id] = { callback = callback, easing = easing, duration = listenerDuration }

        local connected = true
        return function()
            if not connected then
                return
            end

            connected = false
            listeners[id] = nil
        end
    end, function(from: T, to: T)
        generation += 1
        local currentGeneration = generation

        local runs: { Run<T> } = {}
        for id, listener in listeners do
            local tweens: { [string]: Ripple.Tween<any> } = {}
            if listener.duration > 0 then
                tweens = createFieldTweens(from, to, listener.easing, listener.duration)
            end
            table.insert(runs, {
                id = id,
                callback = listener.callback,
                duration = listener.duration,
                elapsed = 0,
                tweens = tweens,
            })
        end
        if #runs == 0 then
            return
        end

        const function fire(run: Run<T>, deltaTime: number)
            if listeners[run.id] ~= nil then
                run.callback(from, to, frameValue(to, run.tweens, deltaTime))
            end
        end

        for _, run in runs do
            fire(run, 0)
        end
        if generation ~= currentGeneration then
            return
        end

        local pending: { Run<T> } = {}
        for _, run in runs do
            if run.duration > 0 then
                table.insert(pending, run)
            end
        end
        if #pending == 0 then
            return
        end

        task.spawn(function()
            while #pending > 0 do
                local deltaTime = task.wait()
                if generation ~= currentGeneration then
                    return
                end

                local stillRunning: { Run<T> } = {}
                for _, run in pending do
                    run.elapsed += deltaTime
                    fire(run, deltaTime)
                    if run.elapsed < run.duration then
                        table.insert(stillRunning, run)
                    end
                end
                pending = stillRunning
            end
        end)
    end
end
