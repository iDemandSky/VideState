const Lest = require("@Lest")
const Group = require("@VideState/Handler/Transition/Tween/Group")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const TOLERANCE = 0.000001

const function near(a: number, b: number): boolean
    return math.abs(a - b) <= TOLERANCE
end

-- Creates a group for one field and returns it with the field read back from a step.
const function create(from: any, to: any, easing: string, duration: number)
    return Group.create({ value = from }, { value = to }, easing :: any, duration)
end

const function stepValue(group: any, deltaTime: number): (any, number)
    const current, alpha = Group.step(group, deltaTime)

    return current.value, alpha
end

describe("tween groups", function()
    it("starts at the first value and ends at the second", function()
        const group = create(2, 10, "linear", 1)
        const start = stepValue(group, 0)
        const middle = stepValue(group, 0.5)
        const finish, alpha = stepValue(group, 0.5)

        expect(start).toBe(2)
        expect(near(middle, 6)).toBe(true)
        expect(finish).toBe(10)
        expect(alpha).toBe(1)
        expect(Group.isDone(group)).toBe(true)
    end)

    it("blends vectors, UDim2 values and tables halfway", function()
        const vectorGroup = create(Vector2.new(0, 0), Vector2.new(4, 8), "linear", 1)

        Group.step(vectorGroup, 0)

        expect((stepValue(vectorGroup, 0.5))).toBe(Vector2.new(2, 4))

        const udim = create(UDim2.new(0, 0, 0, 0), UDim2.new(1, 100, 0.5, 20), "linear", 1)

        Group.step(udim, 0)

        const udimValue = stepValue(udim, 0.5)

        expect(near(udimValue.X.Scale, 0.5) and near(udimValue.X.Offset, 50)).toBe(true)
        expect(near(udimValue.Y.Scale, 0.25) and near(udimValue.Y.Offset, 10)).toBe(true)

        const record = create({ a = 0, b = 10 }, { a = 4, b = 0 }, "linear", 1)

        Group.step(record, 0)

        const recordValue = stepValue(record, 0.5)

        expect(near(recordValue.a, 2)).toBe(true)
        expect(near(recordValue.b, 5)).toBe(true)
    end)

    it("blends colors in Oklab, so black to white passes through a mid grey", function()
        const group = create(Color3.new(0, 0, 0), Color3.new(1, 1, 1), "linear", 1)

        Group.step(group, 0)

        const middle = stepValue(group, 0.5)

        -- Oklab lightness halfway is 0.5, which is 0.125 in linear light and about 0.3885 once encoded as sRGB.
        expect(math.abs(middle.R - 0.3885) < 0.002).toBe(true)
        expect(near(middle.R, middle.G) and near(middle.G, middle.B)).toBe(true)
        const finish = stepValue(group, 0.5)

        expect(near(finish.R, 1) and near(finish.G, 1) and near(finish.B, 1)).toBe(true)
    end)

    it("applies the easing to the values and the alpha together", function()
        const group = create(0, 100, "quadIn", 1)

        Group.step(group, 0)

        const value, alpha = stepValue(group, 0.5)

        expect(near(alpha, 0.25)).toBe(true)
        expect(near(value, 25)).toBe(true)
    end)

    it("finishes at once with a duration of 0", function()
        const group = create(0, 10, "linear", 0)
        const value, alpha = stepValue(group, 0)

        expect(value).toBe(10)
        expect(alpha).toBe(1)
        expect(Group.isDone(group)).toBe(true)
    end)

    it("keeps values that cannot be tweened at their target from the start", function()
        const group = Group.create({
            opacity = 0,
            label = "Idle",
        }, {
            opacity = 1,
            label = "Active",
        }, "linear", 1)
        const current = Group.step(group, 0)

        expect(current.label).toBe("Active")
        expect(current.opacity).toBe(0)
    end)

    it("leaves a field alone when it already has its target value", function()
        const group = Group.create({
            fixed = 5,
            moving = 0,
        }, {
            fixed = 5,
            moving = 10,
        }, "linear", 1)

        Group.step(group, 0)

        const current = Group.step(group, 0.5)

        expect(current.fixed).toBe(5)
        expect(near(current.moving, 5)).toBe(true)
    end)

    it("continues from the current value when the settings change during a transition", function()
        const group = create(0, 100, "linear", 1)

        Group.step(group, 0)

        const before, alphaBefore = stepValue(group, 0.4)

        Group.configure(group, "linear", 2)

        const restart, alphaRestart = stepValue(group, 0)

        -- The value does not jump, and the alpha continues from where it was.
        expect(near(restart, before)).toBe(true)
        expect(near(alphaRestart, alphaBefore)).toBe(true)

        -- The rest of the distance is covered in the new duration.
        const half = stepValue(group, 1)

        expect(near(half, before + (100 - before) / 2)).toBe(true)

        const finish, alpha = stepValue(group, 1)

        expect(finish).toBe(100)
        expect(alpha).toBe(1)
    end)

    it("ignores a settings change that does not change anything", function()
        const group = create(0, 100, "linear", 1)

        Group.step(group, 0)
        stepValue(group, 0.4)
        Group.configure(group, "linear", 1)

        expect(near(stepValue(group, 0.1), 50)).toBe(true)
    end)

    it("tweens ranges and sequences between values of the same shape", function()
        const range = create(NumberRange.new(10, 30), NumberRange.new(50, 90), "linear", 1)

        Group.step(range, 0)

        const rangeValue = stepValue(range, 0.5)

        expect(near(rangeValue.Min, 30)).toBe(true)
        expect(near(rangeValue.Max, 60)).toBe(true)

        const sequence = create(NumberSequence.new(0, 0), NumberSequence.new(1, 1), "linear", 1)

        Group.step(sequence, 0)

        const sequenceValue = stepValue(sequence, 0.5)

        expect(near(sequenceValue.Keypoints[1].Value, 0.5)).toBe(true)
        expect(#sequenceValue.Keypoints).toBe(2)
    end)
end)
