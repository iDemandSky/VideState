const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const function createHandler(name: string)
    return VideState.rule({
        opacity = VideState.float(),
    }, { name = name }).new({
        Idle = { opacity = Vide.source(0) },
        Active = { opacity = Vide.source(1) },
    }, "Idle")
end

describe("custom easing", function()
    it("makes a bezier that matches the CSS curves", function()
        -- cubic-bezier(0, 0, 1, 1) is a straight line.
        local linear = VideState.bezier(0, 0, 1, 1)
        expect(math.abs(linear.fn(0.25) - 0.25) < 0.001).toBe(true)
        expect(math.abs(linear.fn(0.8) - 0.8) < 0.001).toBe(true)

        -- cubic-bezier(0.25, 0.1, 0.25, 1) is CSS `ease`, which is 0.8024 at 0.5.
        local ease = VideState.bezier(0.25, 0.1, 0.25, 1)
        expect(ease.fn(0)).toBe(0)
        expect(ease.fn(1)).toBe(1)
        expect(math.abs(ease.fn(0.5) - 0.8024) < 0.002).toBe(true)
    end)

    it("overshoots when a vertical control leaves 0 to 1", function()
        local back = VideState.bezier(0.34, 1.56, 0.64, 1)
        local highest = 0

        for step = 1, 99 do
            highest = math.max(highest, back.fn(step / 100))
        end

        expect(highest > 1).toBe(true)
    end)

    it("rejects a bezier with controls that cannot be solved", function()
        expect(function()
            VideState.bezier(-0.1, 0, 0.5, 1)
        end).toThrow("between 0 and 1")
        expect(function()
            VideState.bezier(0, 0, 1.5, 1)
        end).toThrow("between 0 and 1")
        expect(function()
            VideState.bezier(0, 0, 0 / 0, 1)
        end).toThrow("finite")
    end)

    it("wraps a function and checks it", function()
        local squared = VideState.easing(function(progress: number): number
            return progress * progress
        end)
        expect(squared.fn(0.5)).toBe(0.25)

        expect(function()
            VideState.easing("quadIn" :: any)
        end).toThrow("function")
        expect(function()
            VideState.easing(function(): number
                return 0 / 0
            end)
        end).toThrow("finite")
    end)

    it("makes a spring that starts at 0, rises without a jump, and ends on 1", function()
        for _, bounces in { 1, 2, 3, 5 } do
            local spring = VideState.spring({ height = 0.2, bounces = bounces })

            expect(spring.fn(0)).toBe(0)
            expect(spring.fn(1)).toBe(1)
            expect(math.abs(spring.fn(0.99) - 1) < 0.01).toBe(true)

            -- It does not jump at the start: the first thousandth of the time moves it very little.
            expect(spring.fn(0.001) < 0.01).toBe(true)
        end
    end)

    it("sets how high the first bounce goes with height", function()
        for _, bounces in { 1, 2, 3, 5 } do
            for _, height in { 0.05, 0.1, 0.2, 0.35, 0.5 } do
                local spring = VideState.spring({ height = height, bounces = bounces })
                local top = 0

                for step = 1, 3999 do
                    top = math.max(top, spring.fn(step / 4000))
                end

                -- The highest point is the first bounce, 1 plus the height.
                expect(math.abs(top - (1 + height)) < 0.004).toBe(true)
            end
        end
    end)

    it("sets how many times it bounces with bounces, each bounce lower than the last", function()
        for _, bounces in { 1, 2, 3, 5, 8 } do
            local spring = VideState.spring({ height = 0.3, bounces = bounces })
            local peaks: { number } = {}
            local samples: { number } = {}

            for step = 0, 8000 do
                table.insert(samples, spring.fn(step / 8000))
            end

            for index = 2, #samples - 1 do
                local isAbove = samples[index] > samples[index - 1]
                local isPeak = isAbove and samples[index] >= samples[index + 1]

                if isPeak and samples[index] > 1.0001 then
                    table.insert(peaks, samples[index] - 1)
                end
            end

            expect(#peaks).toBe(bounces)

            for index = 2, #peaks do
                expect(peaks[index] < peaks[index - 1]).toBe(true)
            end
        end
    end)

    it("makes the same spring when the options are left out as with the defaults", function()
        local plain = VideState.spring()
        local explicit = VideState.spring({ height = 0.15, bounces = 2 })

        expect(plain.fn(0.3)).toBe(explicit.fn(0.3))
        expect(plain.fn(0.7)).toBe(explicit.fn(0.7))
    end)

    it("rejects spring options that are not valid", function()
        expect(function()
            VideState.spring({ height = 0 })
        end).toThrow("spring height must be a number above 0 and at most 0.5")
        expect(function()
            VideState.spring({ height = 0.6 })
        end).toThrow("spring height must be a number above 0 and at most 0.5")
        expect(function()
            VideState.spring({ height = "tall" :: any })
        end).toThrow("spring height must be a number")
        expect(function()
            VideState.spring({ bounces = 0 })
        end).toThrow("spring bounces must be a whole number from 1 to 10")
        expect(function()
            VideState.spring({ bounces = 2.5 })
        end).toThrow("spring bounces must be a whole number from 1 to 10")
        expect(function()
            VideState.spring({ bounces = 11 })
        end).toThrow("spring bounces must be a whole number from 1 to 10")
        expect(function()
            VideState.spring({ bounces = "many" :: any })
        end).toThrow("spring bounces must be a whole number")
        expect(function()
            VideState.spring({ bounce = 0.3 } :: any)
        end).toThrow("unknown key bounce")
        expect(function()
            VideState.spring(0.3 :: any)
        end).toThrow("spring options must be a table")
    end)

    it("plays a transition with a spring, and ends exactly on the next value", function()
        VideState.setManualClock(true)

        local handler = createHandler("SpringPanel")
        local values: { number } = {}

        handler.onTransition(function(_, _, current)
            table.insert(values, current.opacity)
        end, {
            tweenDefault = {
                duration = 1,
                easing = VideState.spring({ height = 0.3, bounces = 3 }),
            },
        })

        handler.setState("Active")

        local top = 0

        for _ = 1, 20 do
            VideState.advanceClock(0.05)
            top = math.max(top, values[#values])
        end

        -- The spring passed 1 on its way, and the transition ended on 1.
        expect(top > 1).toBe(true)
        expect(values[#values]).toBe(1)

        VideState.setManualClock(false)
    end)

    it("plays a transition with a custom easing", function()
        local handler = createHandler("CustomEasingPanel")
        local alphas: { number } = {}

        handler.onTransition(function(_, _, current, alpha)
            table.insert(alphas, alpha)
            expect(current.opacity).toBe(alpha)
        end, {
            tweenDefault = {
                duration = 0.3,
                easing = VideState.easing(function(progress: number): number
                    return progress * progress
                end),
            },
        })

        handler.setState("Active")
        task.wait(0.15)
        handler.finish()

        expect(alphas[#alphas]).toBe(1)

        -- The squared curve stays below the progress, so no frame before the end is ahead of a straight line.
        expect(alphas[1]).toBe(0)
    end)

    it("takes a custom easing from a source", function()
        local handler = createHandler("CustomEasingSourcePanel")
        local easing = Vide.source(VideState.bezier(0.4, 0, 0.2, 1) :: VideState.Easing)
        local last = -1

        handler.onTransition(function(_, _, _, alpha)
            last = alpha
        end, {
            tweenDefault = {
                duration = 0.2,
                easing = easing,
            },
        })

        handler.setState("Active")
        handler.finish()

        expect(last).toBe(1)
    end)

    it("rejects a table that was not made by bezier or easing", function()
        local handler = createHandler("CustomEasingForgedPanel")

        expect(function()
            handler.onTransition(function() end, {
                tweenDefault = {
                    easing = { fn = function(progress: number): number
                        return progress
                    end } :: any,
                },
            })
        end).toThrow("known easing name")
    end)
end)

return nil
