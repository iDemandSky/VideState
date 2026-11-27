const Oklab = require("./Oklab")

-- Blends two colors in Oklab. The two ends are converted once, so a frame only converts back.
const function make(from: Color3, to: Color3): (number) -> Color3
    const start = Oklab.fromSRGB(vector.create(from.R, from.G, from.B))
    const finish = Oklab.fromSRGB(vector.create(to.R, to.G, to.B))
    const delta = finish - start

    return function(alpha: number): Color3
        local blended = vector.max(Oklab.toSRGB(start + delta * alpha), vector.zero)

        return Color3.new(blended.x, blended.y, blended.z)
    end
end

return table.freeze({
    make = make,
})
