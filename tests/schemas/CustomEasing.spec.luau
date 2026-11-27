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
