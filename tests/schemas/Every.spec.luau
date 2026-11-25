const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const function createHandler(name: string, tags: { string }?)
    return VideState.rule({
        opacity = VideState.float(),
    }, {
        name = name,
        tags = tags,
    }).new({
        Idle = { opacity = Vide.source(0) },
        Active = { opacity = Vide.source(1) },
    }, "Idle", {
        onTransition = {
            duration = 1,
        },
    })
end

-- A handler whose rule has the states Idle and Closed, instead of Idle and Active.
const function createClosableHandler(name: string, tags: { string }?)
    return VideState.rule({
        opacity = VideState.float(),
    }, {
        name = name,
        tags = tags,
    }).new({
        Idle = { opacity = Vide.source(0) },
        Closed = { opacity = Vide.source(1) },
    }, "Idle")
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
        VideState.everyHandler.scaleSpeed({ speed = 20 })
        task.wait(0.3)

        local runningFinished = firstAlpha

        -- A transition that starts after the call is scaled too.
        second.setState("Active")
        task.wait(0.3)

        local futureFinished = secondAlpha

        VideState.everyHandler.scaleSpeed({ speed = 1 })
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

        VideState.everyHandler.scaleSpeed({ speed = 0.5 })
        handler.scaleSpeed({ speed = 0.5 })
        handler.setState("Active")
        task.wait(0.5)

        VideState.everyHandler.scaleSpeed({ speed = 1 })

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
        VideState.everyHandler.scaleSpeed({
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
        VideState.everyHandler.pause()
        task.wait(0.2)

        local heldAlpha = secondAlpha

        task.wait(0.2)

        local stillHeld = secondAlpha == heldAlpha

        VideState.everyHandler.resume()
        VideState.everyHandler.finish()

        local pausedCount = paused
        local resumedCount = resumed

        expect(stillHeld).toBe(true)
        expect(pausedCount >= 2).toBe(true)
        expect(resumedCount >= 2).toBe(true)
        expect(finished).toBe(2)
        expect(secondAlpha).toBe(1)
    end)

    it("scopes the functions to handlers whose rule has all the tags", function()
        local menu = createHandler("EveryTagMenuPanel", { "EveryTagMenu", "EveryTagShared" })
        local hud = createHandler("EveryTagHudPanel", { "EveryTagHud", "EveryTagShared" })
        local menuAlpha = 0
        local hudAlpha = 0

        menu.onTransition(function(_, _, _, frameAlpha)
            menuAlpha = frameAlpha
        end)

        hud.onTransition(function(_, _, _, frameAlpha)
            hudAlpha = frameAlpha
        end)

        menu.setState("Active")
        hud.setState("Active")
        task.wait(0.1)
        VideState.everyHandler.withTags("EveryTagMenu").scaleSpeed({ speed = 20 })
        task.wait(0.3)

        local menuFinished = menuAlpha
        local hudHeld = hudAlpha

        -- Both tags are required, so no handler matches this group.
        VideState.everyHandler.withTags("EveryTagMenu", "EveryTagHud").finish()

        local hudAfterNoMatch = hudAlpha

        VideState.everyHandler.withTags("EveryTagShared").finish()

        expect(menuFinished).toBe(1)
        expect(hudHeld < 0.9).toBe(true)
        expect(hudAfterNoMatch < 1).toBe(true)
        expect(hudAlpha).toBe(1)
    end)

    it("destroys the handlers in scope and leaves the others alone", function()
        local doomed = createHandler("EveryDestroyDoomedPanel", { "EveryDestroyTag" })
        local safe = createHandler("EveryDestroySafePanel")

        VideState.everyHandler.withTags("EveryDestroyTag").destroy()

        expect(function()
            doomed.setState("Active")
        end).toThrow()

        safe.setState("Active")

        expect(safe.currentState()).toBe("Active")

        -- Destroying again does nothing, because a destroyed handler has left the list.
        VideState.everyHandler.withTags("EveryDestroyTag").destroy()
    end)

    it("destroys every handler", function()
        local first = createHandler("EveryDestroyAllFirstPanel")
        local second = createHandler("EveryDestroyAllSecondPanel")

        VideState.everyHandler.destroy()

        expect(function()
            first.setState("Active")
        end).toThrow()

        expect(function()
            second.setState("Active")
        end).toThrow()
    end)

    it("rejects invalid tags", function()
        expect(function()
            VideState.everyHandler.withTags()
        end).toThrow("everyHandler.withTags requires at least one tag")

        expect(function()
            VideState.everyHandler.withTags("EveryTagMenu", 2 :: any)
        end).toThrow("everyHandler.withTags tag 2 must be a string, got number")

        expect(function()
            VideState.everyHandler.withTags("EveryTagMenu").scaleSpeed({ speed = 0 })
        end).toThrow("everyHandler.scaleSpeed speed must be a finite number above 0")
    end)

    it("narrows the scope by rule and by state, and chains the filters", function()
        local first = createHandler("EveryFilterFirstPanel", { "EveryFilterTag" })
        local second = createHandler("EveryFilterSecondPanel", { "EveryFilterTag" })
        local third = createHandler("EveryFilterThirdPanel", { "EveryFilterTag", "EveryFilterOther" })

        second.setState("Active")
        third.setState("Active")

        const tagged = VideState.everyHandler.withTags("EveryFilterTag")

        expect(tagged.count()).toBe(3)
        expect(tagged.inState("Active").count()).toBe(2)
        expect(tagged.inState("Idle").count()).toBe(1)
        expect(tagged.withRule("EveryFilterFirstPanel").count()).toBe(1)
        expect(tagged.withRule("EveryFilterFirstPanel").inState("Active").count()).toBe(0)
        expect(tagged.withTags("EveryFilterOther").inState("Active").count()).toBe(1)
        expect(VideState.everyHandler.withRule("EveryFilterMissingRule").count()).toBe(0)

        -- The filters are read each time, so a state change moves a handler in or out of the scope.
        first.setState("Active")

        expect(tagged.inState("Active").count()).toBe(3)
    end)

    it("reports whether any handler in scope is running or paused", function()
        local running = createHandler("EveryReadRunningPanel", { "EveryReadTag" })
        local idle = createHandler("EveryReadIdlePanel", { "EveryReadTag", "EveryReadIdle" })

        running.onTransition(function() end)
        idle.onTransition(function() end)

        const tagged = VideState.everyHandler.withTags("EveryReadTag")

        expect(tagged.isAnyRunning()).toBe(false)
        expect(tagged.isAnyPaused()).toBe(false)

        running.setState("Active")

        expect(tagged.isAnyRunning()).toBe(true)
        expect(tagged.withTags("EveryReadIdle").isAnyRunning()).toBe(false)

        idle.pause()

        expect(tagged.isAnyPaused()).toBe(true)
        expect(tagged.withRule("EveryReadRunningPanel").isAnyPaused()).toBe(false)

        idle.resume()
        tagged.finish()

        expect(tagged.isAnyRunning()).toBe(false)
        expect(VideState.everyHandler.withTags("EveryReadNobody").isAnyRunning()).toBe(false)
    end)

    it("changes the state of every handler in scope", function()
        local first = createHandler("EverySetStateFirstPanel", { "EverySetStateTag" })
        local second = createHandler("EverySetStateSecondPanel", { "EverySetStateTag" })
        local firstChanges = 0

        first.onChange(function()
            firstChanges += 1
        end)

        VideState.everyHandler.withTags("EverySetStateTag").setState("Active")

        expect(first.currentState()).toBe("Active")
        expect(second.currentState()).toBe("Active")
        expect(firstChanges).toBe(1)

        VideState.everyHandler.withTags("EverySetStateTag").inState("Active").setState("Idle", { instant = true })

        expect(first.currentState()).toBe("Idle")
        expect(second.currentState()).toBe("Idle")
    end)

    it("lists every handler without the state in one error and changes none", function()
        local first = createHandler("EveryMissingFirstPanel", { "EveryMissingTag" })
        local second = createHandler("EveryMissingSecondPanel", { "EveryMissingTag" })
        local third = createHandler("EveryMissingThirdPanel", { "EveryMissingTag" })
        local closable = createClosableHandler("EveryMissingClosablePanel", { "EveryMissingTag" })
        local another = createClosableHandler("EveryMissingAnotherPanel", { "EveryMissingTag" })

        expect(function()
            VideState.everyHandler.withTags("EveryMissingTag").setState("Closed")
        end).toThrow(
            "is missing in 3 handlers: EveryMissingFirstPanel (1), EveryMissingSecondPanel (1), EveryMissingThirdPanel (1)"
        )

        const ok, message = pcall(function()
            VideState.everyHandler.withTags("EveryMissingTag").setState("Active")
        end)

        expect(ok).toBe(false)
        expect(message).toBe(
            'everyHandler.setState state "Active" is missing in 2 handlers: EveryMissingAnotherPanel (1), EveryMissingClosablePanel (1). No handler changed state'
        )

        -- Nothing changed, not even the handlers that have the state.
        expect(first.currentState()).toBe("Idle")
        expect(second.currentState()).toBe("Idle")
        expect(third.currentState()).toBe("Idle")
        expect(closable.currentState()).toBe("Idle")
        expect(another.currentState()).toBe("Idle")

        -- A scope that only has handlers with the state works.
        VideState.everyHandler.withTags("EveryMissingTag").withRule("EveryMissingClosablePanel").setState("Closed")

        expect(closable.currentState()).toBe("Closed")
        expect(another.currentState()).toBe("Idle")

        expect(function()
            VideState.everyHandler.setState(2 :: any)
        end).toThrow("everyHandler.setState state name must be a string, got number")
    end)

    it("rejects invalid filters", function()
        expect(function()
            VideState.everyHandler.withRule(2 :: any)
        end).toThrow("everyHandler.withRule rule name must be a string, got number")

        expect(function()
            VideState.everyHandler.inState(2 :: any)
        end).toThrow("everyHandler.inState state name must be a string, got number")
    end)

    it("rejects invalid options", function()
        expect(function()
            VideState.everyHandler.scaleSpeed({ speed = 0 })
        end).toThrow("everyHandler.scaleSpeed speed must be a finite number above 0")

        expect(function()
            VideState.everyHandler.scaleSpeed({ speed = 2, scale = 2 } :: any)
        end).toThrow("everyHandler.scaleSpeed options has an unknown key scale")

        expect(function()
            VideState.everyHandler.scaleSpeed({ speed = 2, once = "yes" :: any })
        end).toThrow("everyHandler.scaleSpeed once must be a boolean")

        expect(function()
            VideState.everyHandler.scaleSpeed(2 :: any)
        end).toThrow("everyHandler.scaleSpeed options must be a table")
    end)
end)
