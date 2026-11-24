-- The speed scale of every handler. Each handler multiplies its own rate by it, every frame.
local scale = 1

const function get(): number
    return scale
end

const function set(value: number)
    scale = value
end

return table.freeze({
    get = get,
    set = set,
})
