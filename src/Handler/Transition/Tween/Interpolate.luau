const CanTween = require("./CanTween")
const Color = require("./Color")
const Composite = require("./Composite")

-- Returns a function that blends from one value to the other for an eased progress. The type is looked up once, when
-- the function is made, so a frame does not have to check it again.
const function make(from: any, to: any): (number) -> any
    const kind = typeof(from)

    if kind == "number" or kind == "vector" or kind == "Vector3" or kind == "Vector2" then
        const delta = to - from

        return function(alpha: number): any
            return from + delta * alpha
        end
    end

    if kind == "Color3" then
        return Color.make(from, to)
    end

    if kind == "UDim2" or kind == "CFrame" then
        return function(alpha: number): any
            return from:Lerp(to, alpha)
        end
    end

    if kind == "UDim" then
        return function(alpha: number): any
            return UDim.new(math.lerp(from.Scale, to.Scale, alpha), math.lerp(from.Offset, to.Offset, alpha))
        end
    end

    if kind == "Rect" then
        return function(alpha: number): any
            return Rect.new(
                math.lerp(from.Min.X, to.Min.X, alpha),
                math.lerp(from.Min.Y, to.Min.Y, alpha),
                math.lerp(from.Max.X, to.Max.X, alpha),
                math.lerp(from.Max.Y, to.Max.Y, alpha)
            )
        end
    end

    if kind == "table" then
        return function(alpha: number): any
            local result: { [any]: any } = from

            for key, b in to do
                const a = from[key]

                if not a then
                    continue
                end

                const value = a + (b - a) * alpha

                if result[key] ~= value then
                    if result == from then
                        result = table.clone(from)
                    end

                    result[key] = value
                end
            end

            return result
        end
    end

    return Composite.make(from, to)
end

-- Whether a field can be tweened from one value to the other.
const function isTweenable(from: unknown, to: unknown): boolean
    const isPlain = CanTween(from, to)
    const isComposite = Composite.canTween(from, to)

    return isPlain or isComposite
end

return table.freeze({
    make = make,
    isTweenable = isTweenable,
})
