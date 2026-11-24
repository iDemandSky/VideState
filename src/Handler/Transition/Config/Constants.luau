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

-- Keys allowed in the `onTransition` handler options.
const OPTION_KEYS: { [string]: boolean } = {
    easing = true,
    duration = true,
    speed = true,
    delay = true,
}

-- Value types that Ripple can interpolate directly.
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

return table.freeze({
    DEFAULT_DURATION = 0.25,
    DEFAULT_EASING = "linear",
    DEFAULT_SPEED = 1,
    DEFAULT_DELAY = 0,
    TWEEN_NAMES = table.freeze(TWEEN_NAMES),
    OPTION_KEYS = table.freeze(OPTION_KEYS),
    ANIMATABLE_TYPES = table.freeze(ANIMATABLE_TYPES),
})
