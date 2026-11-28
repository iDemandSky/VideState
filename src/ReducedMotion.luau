-- Whether every transition is played instantly. Games set it from the player's settings.
local isEnabled = false

const function get(): boolean
    return isEnabled
end

const function set(enabled: boolean)
    if type(enabled) ~= "boolean" then
        error(`setReducedMotion expects a boolean, got {typeof(enabled)}`, 3)
    end

    isEnabled = enabled
end

return table.freeze({
    get = get,
    set = set,
})
