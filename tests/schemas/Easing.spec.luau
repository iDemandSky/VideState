const Lest = require("@Lest")
const Easing = require("@VideState/Handler/Transition/Tween/Easing")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const TOLERANCE = 0.000000001

const NAMES = {
    "linear",
    "quadIn",
    "quadOut",
    "quadInOut",
    "cubicIn",
    "cubicOut",
    "cubicInOut",
    "sineIn",
    "sineOut",
    "sineInOut",
    "expoIn",
    "expoOut",
    "expoInOut",
    "backIn",
    "backOut",
    "backInOut",
    "elasticIn",
    "elasticOut",
    "elasticInOut",
}

-- Each family has an `In` curve and an `Out` curve that mirrors it, and an `InOut` curve that is symmetric.
const FAMILIES = {
    "quad",
    "cubic",
    "sine",
    "expo",
    "back",
    "elastic",
}

const SAMPLES = { 0.1, 0.25, 0.4, 0.5, 0.6, 0.75, 0.9 }

const function near(a: number, b: number): boolean
    return math.abs(a - b) <= TOLERANCE
end

describe("easing", function()
    it("has a curve for every name that a tween accepts", function()
        for _, name in NAMES do
            expect(type(Easing[name])).toBe("function")
        end
    end)

    it("starts at 0 and ends at 1 for every curve", function()
        for _, name in NAMES do
            const curve = Easing[name]

            expect(near(curve(0), 0)).toBe(true)
            expect(near(curve(1), 1)).toBe(true)
        end
    end)

    it("mirrors each In curve in its Out curve", function()
        for _, family in FAMILIES do
            const curveIn = Easing[family .. "In"]
            const curveOut = Easing[family .. "Out"]

            for _, x in SAMPLES do
                expect(near(curveOut(x), 1 - curveIn(1 - x))).toBe(true)
            end
        end
    end)

    it("makes each InOut curve symmetric around its middle", function()
        for _, family in FAMILIES do
            const curve = Easing[family .. "InOut"]

            expect(near(curve(0.5), 0.5)).toBe(true)

            for _, x in SAMPLES do
                expect(near(curve(1 - x), 1 - curve(x))).toBe(true)
            end
        end
    end)

    it("returns the known values of the standard equations", function()
        expect(Easing.linear(0.3)).toBe(0.3)
        expect(Easing.quadIn(0.5)).toBe(0.25)
        expect(Easing.quadOut(0.5)).toBe(0.75)
        expect(Easing.cubicIn(0.5)).toBe(0.125)
        expect(near(Easing.cubicOut(0.5), 0.875)).toBe(true)
        expect(near(Easing.sineIn(0.5), 1 - math.cos(math.pi / 4))).toBe(true)
        expect(near(Easing.expoIn(0.5), 2 ^ -5)).toBe(true)
        -- back uses 1.70158 and 2.70158: 2.70158 * 0.125 - 1.70158 * 0.25.
        expect(near(Easing.backIn(0.5), 2.70158 * 0.125 - 1.70158 * 0.25)).toBe(true)
    end)

    it("never moves backwards for the curves that do not overshoot", function()
        for _, family in { "quad", "cubic", "sine", "expo" } do
            for _, suffix in { "In", "Out", "InOut" } do
                const curve = Easing[family .. suffix]
                local previous = curve(0)

                for step = 1, 100 do
                    const value = curve(step / 100)

                    expect(value >= previous - TOLERANCE).toBe(true)

                    previous = value
                end
            end
        end
    end)

    it("overshoots for back and elastic, so values leave 0 to 1", function()
        expect(Easing.backIn(0.2) < 0).toBe(true)
        expect(Easing.backOut(0.8) > 1).toBe(true)
        expect(Easing.elasticOut(0.2) > 1).toBe(true)
        expect(Easing.elasticIn(0.8) < 0).toBe(true)
    end)
end)
