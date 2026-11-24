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
    }, "Idle", {
        onTransition = {
            duration = 1,
        },
    })
end

describe("every handler", function()
    it("scales running and future transitions of every handler", function()
        local first = createHandler("EveryScaleFirstPanel")
        local second = createHandler("EveryScaleSecondPanel")
        local firstAlpha = 0
        local secondAlpha = 0

        first.onTransition(function(_, _, _, frameAlpha)
            firstAlpha = frameAlpha
        end)

        second.onTransition(function(_, _, _, frameAlpha)
            secondAlpha = frameAlpha
        end)

        first.setState("Active")
        task.wait(0.1)
        VideState.every.handler.scaleSpeed({ speed = 20 })
        task.wait(0.3)

        local runningFinished = firstAlpha

        -- A transition that starts after the call is scaled too.
        second.setState("Active")
        task.wait(0.3)

        local futureFinished = secondAlpha

        VideState.every.handler.scaleSpeed({ speed = 1 })
        first.setState("Idle")
        task.wait(0.3)

        local normalSpeed = firstAlpha

        -- Without the scale, 0.4 of the 1 second would have played.
        expect(runningFinished).toBe(1)
        expect(futureFinished).toBe(1)
        expect(normalSpeed < 0.9).toBe(true)
    end)

    it("multiplies with the scale of the handler", function()
        local handler = createHandler("EveryMultiplyPanel")
        local alpha = 0

        handler.onTransition(function(_, _, _, frameAlpha)
            alpha = frameAlpha
        end)

        VideState.every.handler.scaleSpeed({ speed = 0.5 })
        handler.scaleSpeed({ speed = 0.5 })
        handler.setState("Active")
        task.wait(0.5)

        VideState.every.handler.scaleSpeed({ speed = 1 })

        -- At a combined speed of 0.25, only about 0.125 of the 1 second has played.
        expect(alpha < 0.4).toBe(true)
    end)

    it("scales only the running transitions with once", function()
        local first = createHandler("EveryOnceFirstPanel")
        local second = createHandler("EveryOnceSecondPanel")
        local firstAlpha = 0
        local secondAlpha = 0

        first.onTransition(function(_, _, _, frameAlpha)
            firstAlpha = frameAlpha
        end)

        second.onTransition(function(_, _, _, frameAlpha)
            secondAlpha = frameAlpha
        end)

        first.setState("Active")
        second.setState("Active")
        task.wait(0.1)
        VideState.every.handler.scaleSpeed({
            speed = 20,
            once = true,
        })
        task.wait(0.3)

        local runningFinished = math.min(firstAlpha, secondAlpha)

        first.setState("Idle")
        task.wait(0.3)

        -- The next transition plays at normal speed again.
        expect(runningFinished).toBe(1)
        expect(firstAlpha < 0.9).toBe(true)
    end)

    it("pauses, resumes and finishes every handler", function()
        local first = createHandler("EveryControlFirstPanel")
        local second = createHandler("EveryControlSecondPanel")
        local paused = 0
        local resumed = 0
        local finished = 0
        local secondAlpha = 0

        first.onPause(function()
            paused += 1
        end)

        second.onPause(function()
            paused += 1
        end)

        first.onResume(function()
            resumed += 1
        end)

        second.onResume(function()
            resumed += 1
        end)

        first.onFinish(function()
            finished += 1
        end)

        second.onFinish(function()
            finished += 1
        end)

        -- A handler only finishes a transition that has a connection.
        first.onTransition(function() end)

        second.onTransition(function(_, _, _, frameAlpha)
            secondAlpha = frameAlpha
        end)

        first.setState("Active")
        second.setState("Active")
        VideState.every.handler.pause()
        task.wait(0.2)

        local heldAlpha = secondAlpha

        task.wait(0.2)

        local stillHeld = secondAlpha == heldAlpha

        VideState.every.handler.resume()
        VideState.every.handler.finish()

        local pausedCount = paused
        local resumedCount = resumed

        expect(stillHeld).toBe(true)
        expect(pausedCount >= 2).toBe(true)
        expect(resumedCount >= 2).toBe(true)
        expect(finished).toBe(2)
        expect(secondAlpha).toBe(1)
    end)

    it("rejects invalid options", function()
        expect(function()
            VideState.every.handler.scaleSpeed({ speed = 0 })
        end).toThrow("every.handler.scaleSpeed speed must be a finite number above 0")

        expect(function()
            VideState.every.handler.scaleSpeed({ speed = 2, scale = 2 } :: any)
        end).toThrow("every.handler.scaleSpeed options has an unknown key scale")

        expect(function()
            VideState.every.handler.scaleSpeed({ speed = 2, once = "yes" :: any })
        end).toThrow("every.handler.scaleSpeed once must be a boolean")

        expect(function()
            VideState.every.handler.scaleSpeed(2 :: any)
        end).toThrow("every.handler.scaleSpeed options must be a table")
    end)
end)
