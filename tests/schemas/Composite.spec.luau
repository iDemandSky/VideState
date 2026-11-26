const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const function createRangeHandler(name: string, duration: number, easing: string?)
    return VideState.rule({
        range = VideState.numberRange(),
    }, { name = name }).new({
        Idle = { range = Vide.source(NumberRange.new(10, 30)) },
        Active = { range = Vide.source(NumberRange.new(50, 90)) },
    }, "Idle", {
        onTransition = {
            duration = duration,
            easing = easing :: any,
        },
    })
end

describe("composite values", function()
    it("accepts the new schemas and rejects other types", function()
        expect(VideState.numberRange().parse(NumberRange.new(1, 2)).ok).toBe(true)
        expect(VideState.numberRange().parse(5).ok).toBe(false)
        expect(VideState.numberSequence().parse(NumberSequence.new(0.5)).ok).toBe(true)
        expect(VideState.numberSequence().parse(NumberRange.new(1, 2)).ok).toBe(false)
        expect(VideState.colorSequence().parse(ColorSequence.new(Color3.new())).ok).toBe(true)
        expect(VideState.colorSequence().parse(Color3.new()).ok).toBe(false)
    end)

    it("tweens the minimum and maximum of a NumberRange", function()
        local handler = createRangeHandler("RangeTweenPanel", 3)
        local animated = handler.animate()

        expect(animated.range().Min).toBe(10)
        expect(animated.range().Max).toBe(30)

        handler.setState("Active")
        task.wait(0.3)

        local middle = animated.range()

        expect(middle.Min > 10 and middle.Min < 50).toBe(true)
        expect(middle.Max > 30 and middle.Max < 90).toBe(true)

        handler.finish()

        expect(animated.range().Min).toBe(50)
        expect(animated.range().Max).toBe(90)
    end)

    it("keeps the minimum at or below the maximum when an easing overshoots", function()
        local handler = VideState.rule({
            range = VideState.numberRange(),
        }, { name = "RangeOvershootPanel" }).new({
            Idle = { range = Vide.source(NumberRange.new(0, 100)) },
            Active = { range = Vide.source(NumberRange.new(40, 42)) },
        }, "Idle", {
            onTransition = {
                duration = 0.3,
                easing = "elasticOut",
            },
        })

        local frames = 0
        local last = NumberRange.new(0, 100)

        handler.onTransition(function(_, _, current)
            frames += 1
            last = current.range
        end)

        handler.setState("Active")
        task.wait(0.8)

        expect(frames > 2).toBe(true)
        expect(last.Min).toBe(40)
        expect(last.Max).toBe(42)
    end)

    it("tweens the keypoints of sequences with the same keypoint count", function()
        local handler = VideState.rule({
            fade = VideState.numberSequence(),
            tint = VideState.colorSequence(),
        }, { name = "SequenceTweenPanel" }).new({
            Idle = {
                fade = Vide.source(NumberSequence.new(0, 0)),
                tint = Vide.source(ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))),
            },
            Active = {
                fade = Vide.source(NumberSequence.new(1, 1)),
                tint = Vide.source(ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))),
            },
        }, "Idle", {
            onTransition = {
                duration = 3,
            },
        })

        local animated = handler.animate()

        handler.setState("Active")
        task.wait(0.3)

        local fadeValue = animated.fade().Keypoints[1].Value
        local tintValue = animated.tint().Keypoints[1].Value.R

        expect(fadeValue > 0 and fadeValue < 1).toBe(true)
        expect(tintValue > 0 and tintValue < 1).toBe(true)
        expect(#animated.fade().Keypoints).toBe(2)

        handler.finish()

        expect(animated.fade().Keypoints[2].Value).toBe(1)
        expect(animated.tint().Keypoints[2].Value.R).toBe(1)
    end)

    it("switches a sequence at the start when the keypoint counts differ", function()
        local handler = VideState.rule({
            fade = VideState.numberSequence(),
        }, { name = "SequenceSnapPanel" }).new({
            Idle = { fade = Vide.source(NumberSequence.new(0, 0)) },
            Active = {
                fade = Vide.source(NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0.5),
                    NumberSequenceKeypoint.new(1, 1),
                })),
            },
        }, "Idle", {
            onTransition = {
                duration = 3,
            },
        })

        local animated = handler.animate()

        handler.setState("Active")

        expect(#animated.fade().Keypoints).toBe(3)
        expect(animated.fade().Keypoints[2].Value).toBe(0.5)
    end)
end)
