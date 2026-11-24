const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

describe("transition controls", function()
    it("pauses and resumes every running transition of the handler", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "PauseAllPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.5,
            },
        })

        local first: { number } = {}
        local second: { number } = {}
        local pauseTimes: { number } = {}
        local resumeTimes: { number } = {}

        handler.onTransition(function(_, _, current)
            table.insert(first, current.opacity)
        end)
        handler.onTransition(function(_, _, current)
            table.insert(second, current.opacity)
        end, {
            duration = 0.4,
        })

        local disconnectPause = handler.onPause(function(startedAt)
            table.insert(pauseTimes, startedAt)
        end)

        handler.onResume(function(startedAt)
            table.insert(resumeTimes, startedAt)
        end)

        local before = os.clock()

        handler.setState("Active")
        task.wait(0.15)
        handler.pause()
        handler.pause()

        local after = os.clock()
        local firstCount = #first
        local secondCount = #second

        task.wait(0.3)

        -- Nothing moved while paused, and a second pause call did not fire the event again.
        expect(#first).toBe(firstCount)
        expect(#second).toBe(secondCount)
        expect(#pauseTimes).toBe(1)

        local isNotBeforeCall = pauseTimes[1] >= before
        local isNotAfterCall = pauseTimes[1] <= after
        local isStartInRange = isNotBeforeCall and isNotAfterCall

        expect(isStartInRange).toBe(true)

        handler.resume()
        handler.resume()
        task.wait(0.8)

        expect(first[#first]).toBe(1)
        expect(second[#second]).toBe(1)
        expect(#resumeTimes).toBe(1)
        expect(resumeTimes[1]).toBe(pauseTimes[1])

        disconnectPause()
        handler.pause()
        handler.resume()

        expect(#pauseTimes).toBe(1)

        expect(function()
            handler.onPause(1 :: any)
        end).toThrow("onPause callback must be a function")

        expect(function()
            handler.onResume(1 :: any)
        end).toThrow("onResume callback must be a function")
    end)

    it("keeps a new transition at its first frame while the handler is paused", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "PausedStartPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.2,
            },
        })

        local values: { number } = {}

        handler.onTransition(function(_, _, current)
            table.insert(values, current.opacity)
        end)

        handler.pause()
        handler.setState("Active")
        task.wait(0.4)

        expect(#values).toBe(1)
        expect(values[1]).toBe(0)

        handler.resume()
        task.wait(0.4)

        expect(values[#values]).toBe(1)
    end)

    it("starts a delayed connection late, and staggers connections", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "DelayPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.2,
            },
        })

        local first: { number } = {}
        local delayed: { number } = {}
        local finishes = 0

        handler.onTransition(function(_, _, current)
            table.insert(first, current.opacity)
        end)
        handler.onTransition(function(_, _, current)
            table.insert(delayed, current.opacity)
        end, {
            delay = 0.6,
        })
        handler.onFinish(function()
            finishes += 1
        end)

        handler.setState("Active")

        -- The first connection starts at once, and the delayed one sends nothing yet.
        expect(#first).toBe(1)
        expect(#delayed).toBe(0)

        task.wait(0.35)

        expect(first[#first]).toBe(1)
        expect(#delayed).toBe(0)
        expect(finishes).toBe(0)

        task.wait(0.8)

        -- It starts from the beginning after the delay, and the transition finishes once it ends.
        expect(delayed[1]).toBe(0)
        expect(delayed[#delayed]).toBe(1)
        expect(finishes).toBe(1)

        -- An instant change skips the delay.
        handler.setState("Idle", { instant = true })

        expect(delayed[#delayed]).toBe(0)

        expect(function()
            handler.onTransition(function() end, { delay = -1 })
        end).toThrow("onTransition delay must be a finite non-negative number")
    end)

    it("holds a delay while paused, and finish ends a delayed connection", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "DelayPausePanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.2,
                delay = 0.3,
            },
        })

        local values: { number } = {}

        handler.onTransition(function(_, _, current)
            table.insert(values, current.opacity)
        end)

        handler.pause()
        handler.setState("Active")
        task.wait(0.6)

        -- The paused delay did not run out.
        expect(#values).toBe(0)

        handler.finish()

        expect(values[#values]).toBe(1)
    end)

    it("changes the state instantly when setState is told to", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "InstantPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 1,
            },
        })

        local values: { number } = {}
        local alphas: { number } = {}
        local finishes = 0

        handler.onTransition(function(_, _, current, alpha)
            table.insert(values, current.opacity)
            table.insert(alphas, alpha)
        end)
        handler.onFinish(function()
            finishes += 1
        end)

        handler.setState("Active", { instant = true })

        -- One frame with the next values, sent before setState returns.
        expect(#values).toBe(1)
        expect(values[1]).toBe(1)
        expect(alphas[1]).toBe(1)
        expect(finishes).toBe(1)
        expect(handler.currentState()).toBe("Active")

        task.wait(0.2)

        expect(#values).toBe(1)

        -- Without the option, the next change animates again.
        handler.setState("Idle")
        task.wait(0.2)

        local isAnimating = values[#values] > 0

        expect(isAnimating).toBe(true)

        expect(function()
            handler.setState("Active", { instant = "yes" } :: any)
        end).toThrow("setState instant must be a boolean")

        expect(function()
            handler.setState("Active", { skip = true } :: any)
        end).toThrow("setState options has an unknown key skip")

        expect(function()
            handler.setState("Active", true :: any)
        end).toThrow("setState options must be a table")
    end)

    it("scales only the running transition", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "ScaleSpeedPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 1,
            },
        })

        local alpha = 0

        handler.onTransition(function(_, _, _, frameAlpha)
            alpha = frameAlpha
        end)

        handler.setState("Active")
        task.wait(0.1)
        handler.scaleSpeed({ speed = 20, once = true })
        task.wait(0.3)

        -- Without the scale, 0.4 of the 1 second would have played.
        expect(alpha).toBe(1)

        handler.setState("Idle")
        task.wait(0.3)

        -- The next transition plays at normal speed again.
        expect(alpha < 0.9).toBe(true)

        expect(function()
            handler.scaleSpeed({ speed = 0 })
        end).toThrow("scaleSpeed speed must be a finite number above 0")

        expect(function()
            handler.scaleSpeed({ speed = 2, scale = 2 } :: any)
        end).toThrow("scaleSpeed options has an unknown key scale")

        expect(function()
            handler.scaleSpeed(2 :: any)
        end).toThrow("scaleSpeed options must be a table")
    end)

    it("keeps the scale for every following transition by default for every following transition", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "KeptScalePanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 1,
            },
        })

        local alpha = 0

        handler.onTransition(function(_, _, _, frameAlpha)
            alpha = frameAlpha
        end)

        handler.scaleSpeed({ speed = 20 })
        handler.setState("Active")
        task.wait(0.3)

        expect(alpha).toBe(1)

        handler.setState("Idle")
        task.wait(0.3)

        -- The scale is still in place for the second transition.
        expect(alpha).toBe(1)

        handler.scaleSpeed({ speed = 1 })
        handler.setState("Active")
        task.wait(0.3)

        expect(alpha < 0.9).toBe(true)

        expect(function()
            handler.scaleSpeed({ speed = 2, once = "yes" :: any })
        end).toThrow("scaleSpeed once must be a boolean")
    end)

    it("finishes every running transition at once", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "FinishPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 5,
            },
        })

        local first: { number } = {}
        local second: { number } = {}
        local finishes: { number } = {}

        handler.onTransition(function(_, _, current, alpha)
            table.insert(first, alpha)
            expect(current.opacity).toBe(alpha)
        end)
        handler.onTransition(function(_, _, current)
            table.insert(second, current.opacity)
        end, {
            duration = 3,
        })
        handler.onFinish(function(startedAt)
            table.insert(finishes, startedAt)
        end)

        local before = os.clock()

        handler.setState("Active")
        task.wait(0.1)
        handler.finish()

        -- The last frame arrived before finish returned.
        expect(first[#first]).toBe(1)
        expect(second[#second]).toBe(1)
        expect(#finishes).toBe(1)

        local isNotBeforeCall = finishes[1] >= before
        local isNotAfterCall = finishes[1] <= os.clock()
        local isStartInRange = isNotBeforeCall and isNotAfterCall

        expect(isStartInRange).toBe(true)

        local firstCount = #first

        task.wait(0.2)
        handler.finish()

        -- Nothing runs after it, and a second call does not fire the event again.
        expect(#first).toBe(firstCount)
        expect(#finishes).toBe(1)
    end)

    it("fires the finish event once when the last connection reaches its end", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "FinishEventPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.1,
            },
        })

        local finishes = 0
        local disconnectFinish = handler.onFinish(function()
            finishes += 1
        end)

        handler.onTransition(function() end)
        handler.onTransition(function() end, {
            duration = 0.5,
        })

        handler.setState("Active")
        task.wait(0.3)

        -- The short connection ended, but the long one is still playing.
        expect(finishes).toBe(0)

        task.wait(0.5)

        expect(finishes).toBe(1)

        -- A transition that another one replaces never finishes.
        handler.setState("Idle")
        task.wait(0.05)
        handler.setState("Active")
        task.wait(0.8)

        expect(finishes).toBe(2)

        disconnectFinish()
        handler.setState("Idle")
        task.wait(0.8)

        expect(finishes).toBe(2)

        expect(function()
            handler.onFinish(1 :: any)
        end).toThrow("onFinish callback must be a function")
    end)

    it("waits until the running transition has finished", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "WaitPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.3,
            },
        })

        -- With nothing running, it returns at once.
        local startedAt = os.clock()

        handler.waitForFinish()

        expect(os.clock() - startedAt < 0.01).toBe(true)

        -- A state change with no connections does not run, so there is nothing to wait for.
        handler.setState("Active")
        handler.waitForFinish()

        local lastAlpha = 0

        handler.onTransition(function(_, _, _, alpha)
            lastAlpha = alpha
        end)

        handler.setState("Idle")
        handler.waitForFinish()

        expect(lastAlpha).toBe(1)

        -- A transition that another one replaces keeps the wait going until the new one ends.
        local released = false

        handler.setState("Active")

        task.spawn(function()
            handler.waitForFinish()
            released = true
        end)

        task.wait(0.1)
        handler.setState("Idle")
        task.wait(0.25)

        expect(released).toBe(false)

        task.wait(0.3)

        expect(released).toBe(true)
        expect(handler.currentState()).toBe("Idle")

        -- finish ends the wait as well.
        local releasedByFinish = false

        handler.setState("Active")

        task.spawn(function()
            handler.waitForFinish()
            releasedByFinish = true
        end)

        handler.finish()

        expect(releasedByFinish).toBe(true)
    end)

    it("stops everything when destroyed", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "DestroyPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.5,
            },
        })

        local frames = 0
        local pauses = 0
        local finishes = 0
        local released = false

        handler.onTransition(function()
            frames += 1
        end)
        handler.onPause(function()
            pauses += 1
        end)
        handler.onFinish(function()
            finishes += 1
        end)

        handler.setState("Active")

        task.spawn(function()
            handler.waitForFinish()
            released = true
        end)

        task.wait(0.1)

        local framesBeforeDestroy = frames

        handler.destroy()
        handler.destroy()

        -- Waiting threads continue, and the running transition sends no other frame.
        expect(released).toBe(true)

        task.wait(0.6)

        expect(frames).toBe(framesBeforeDestroy)
        expect(finishes).toBe(0)

        -- Listeners were removed, and the controls do nothing.
        handler.pause()
        handler.resume()
        handler.finish()
        handler.waitForFinish()

        expect(pauses).toBe(0)
        expect(handler.currentState()).toBe("Active")

        expect(function()
            handler.setState("Idle")
        end).toThrow("setState cannot be called after destroy")
    end)

    it("finishes a paused transition", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "PausedFinishPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 1,
            },
        })

        local lastAlpha = 0
        local finishes = 0

        handler.onTransition(function(_, _, _, alpha)
            lastAlpha = alpha
        end)
        handler.onFinish(function()
            finishes += 1
        end)

        handler.setState("Active")
        handler.pause()
        handler.finish()

        expect(lastAlpha).toBe(1)
        expect(finishes).toBe(1)
    end)
end)
