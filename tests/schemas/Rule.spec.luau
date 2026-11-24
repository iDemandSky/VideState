const Info = require("@VideState/Info")
const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

describe("rule handlers", function()
    it("updates sources and current state when switching states", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "SwitchPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle")

        expect(handler.sources.visible()).toBe(false)
        expect(handler.currentState()).toBe("Idle")

        handler.setState("Active")

        expect(handler.sources.visible()).toBe(true)
        expect(handler.currentState()).toBe("Active")
    end)

    it("notifies change listeners with state values and disconnects them", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "ChangePanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle")

        local changes = {}
        local disconnect = handler.onChange(function(from, to)
            table.insert(changes, { from = from.visible, to = to.visible })
        end)

        handler.setState("Active")
        disconnect()
        disconnect()
        handler.setState("Idle")

        expect(#changes).toBe(1)
        expect(changes[1].from).toBe(false)
        expect(changes[1].to).toBe(true)
    end)

    it("provides transition values and alpha, and disconnects transition listeners", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
            opacity = VideState.float(),
        }, { name = "ValuePanel" }).new({
            Idle = { visible = Vide.source(false), opacity = Vide.source(0) },
            Active = { visible = Vide.source(true), opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.05,
            },
        })

        local currents = {}
        local alphas = {}
        local secondCurrents = {}
        local disconnect = handler.onTransition(function(from, to, current, alpha)
            expect(from.visible).toBe(false)
            expect(to.visible).toBe(true)
            table.insert(currents, current)
            table.insert(alphas, alpha)
        end)
        local disconnectSecond = handler.onTransition(function(_, _, current)
            table.insert(secondCurrents, current)
        end)

        handler.setState("Active")
        expect(currents[1].opacity).toBe(0)
        expect(alphas[1]).toBe(0)
        expect(secondCurrents[1].opacity).toBe(0)

        task.wait(0.15)
        expect(currents[#currents].opacity).toBe(1)
        expect(alphas[#alphas]).toBe(1)
        expect(secondCurrents[#secondCurrents].opacity).toBe(1)
        expect(#secondCurrents).toBe(#currents)

        disconnect()
        disconnectSecond()

        local countAfterDisconnect = #currents

        handler.setState("Idle")
        task.wait(0.1)

        expect(#currents).toBe(countAfterDisconnect)
    end)

    it("gives each transition connection its own settings", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "PerConnectionPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.6,
            },
        })

        local inheritedAlphas: { number } = {}
        local overriddenAlphas: { number } = {}

        handler.onTransition(function(_, _, _, alpha)
            table.insert(inheritedAlphas, alpha)
        end)
        handler.onTransition(function(_, _, _, alpha)
            table.insert(overriddenAlphas, alpha)
        end, {
            duration = 0.05,
        })

        handler.setState("Active")
        task.wait(0.3)

        -- The override finished, and the connection with no options still runs on the handler's duration.
        expect(overriddenAlphas[#overriddenAlphas]).toBe(1)
        expect(inheritedAlphas[#inheritedAlphas] < 1).toBe(true)

        task.wait(0.6)

        expect(inheritedAlphas[#inheritedAlphas]).toBe(1)

        expect(function()
            handler.onTransition(function() end, { easing = "bounce" } :: any)
        end).toThrow("onTransition easing must be a known easing name")
    end)

    it("tweens numeric fields and snaps other fields at the start of a transition", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
            opacity = VideState.float(),
        }, { name = "TweenValuePanel" }).new({
            Idle = { visible = Vide.source(false), opacity = Vide.source(0) },
            Active = { visible = Vide.source(true), opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                easing = "quadIn",
                -- A long transition spans many frames, so a slow frame cannot skip every intermediate value.
                duration = 0.4,
            },
        })

        local currents: { { visible: boolean, opacity: number } } = {}
        local alphas: { number } = {}

        handler.onTransition(function(_, _, current, alpha)
            table.insert(currents, current)
            table.insert(alphas, alpha)
        end)

        handler.setState("Active")
        task.wait(0.9)

        expect(currents[1].visible).toBe(true)
        expect(currents[1].opacity).toBe(0)
        expect(currents[#currents].opacity).toBe(1)

        local hasIntermediate = false

        for index, current in currents do
            local isAboveStart = current.opacity > 0
            local isBelowEnd = current.opacity < 1
            local isBetween = isAboveStart and isBelowEnd

            if isBetween then
                hasIntermediate = true
            end

            -- With a single numeric field, the eased alpha matches the field's own progress.
            expect(math.abs(alphas[index] - current.opacity) < 0.0001).toBe(true)
        end

        expect(hasIntermediate).toBe(true)
    end)

    it("lets the alpha overshoot with back easing", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "OvershootPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                easing = "backOut",
                duration = 0.5,
            },
        })

        local highestAlpha = 0
        local lastAlpha = 0

        handler.onTransition(function(_, _, _, alpha)
            highestAlpha = math.max(highestAlpha, alpha)
            lastAlpha = alpha
        end)

        handler.setState("Active")
        task.wait(1)

        expect(highestAlpha > 1).toBe(true)
        expect(lastAlpha).toBe(1)
    end)

    it("stops a running transition when disconnected", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "StopPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle", {
            onTransition = {
                duration = 0.25,
            },
        })

        local calls = 0
        local disconnect = handler.onTransition(function()
            calls += 1
        end)

        handler.setState("Active")
        task.wait(0.05)
        disconnect()

        local callsAfterDisconnect = calls

        task.wait(0.1)

        expect(calls).toBe(callsAfterDisconnect)
    end)

    it("replaces a running transition when the state changes again", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "ReplacePanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.2,
            },
        })

        local lastTo = nil

        handler.onTransition(function(_, to)
            lastTo = to.opacity
        end)

        handler.setState("Active")
        task.wait(0.05)
        handler.setState("Idle")
        task.wait(0.3)

        expect(lastTo).toBe(0)
    end)

    it("continues from the current value when a transition is interrupted", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "InterruptPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.6,
            },
        })

        local values: { number } = {}

        handler.onTransition(function(_, _, current)
            table.insert(values, current.opacity)
        end)

        handler.setState("Active")
        task.wait(0.25)

        local valueBeforeInterrupt = values[#values]
        local countBeforeInterrupt = #values

        handler.setState("Idle")

        -- The new transition starts at the value the first one reached, not at the previous state's 1.
        local firstValue = values[countBeforeInterrupt + 1]
        local isAboveStart = valueBeforeInterrupt > 0.05
        local isBelowEnd = valueBeforeInterrupt < 0.95
        local isBetween = isAboveStart and isBelowEnd

        expect(isBetween).toBe(true)
        expect(math.abs(firstValue - valueBeforeInterrupt) < 0.0001).toBe(true)

        task.wait(0.9)

        expect(values[#values]).toBe(0)
    end)

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

    it("runs exit and enter listeners for the states involved, in order", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "EnterExitPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
            Hidden = { opacity = Vide.source(0) },
        }, "Idle")

        local events: { string } = {}

        handler.onExit("Idle", function(nextState)
            table.insert(events, "exit Idle to " .. nextState)
        end)

        local disconnectEnter = handler.onEnter("Active", function(previousState)
            table.insert(events, "enter Active from " .. previousState)
        end)

        handler.onChange(function()
            table.insert(events, "change")
        end)
        handler.onEnter("Hidden", function()
            table.insert(events, "enter Hidden")
        end)

        handler.setState("Active")

        expect(#events).toBe(3)
        expect(events[1]).toBe("exit Idle to Active")
        expect(events[2]).toBe("enter Active from Idle")
        expect(events[3]).toBe("change")

        -- The same state does not count as entering it again.
        handler.setState("Active")

        expect(#events).toBe(3)

        disconnectEnter()
        handler.setState("Idle")
        handler.setState("Active")

        local hasEnterAfterDisconnect = table.find(events, "enter Active from Idle", 3) ~= nil

        expect(hasEnterAfterDisconnect).toBe(false)

        expect(function()
            handler.onEnter("Missing", function() end)
        end).toThrow(`onEnter state "Missing" is not a state of this handler`)

        expect(function()
            handler.onExit("Idle", 1 :: any)
        end).toThrow("onExit callback must be a function")

        expect(function()
            handler.onEnter(1 :: any, function() end)
        end).toThrow("onEnter state name must be a string, got number")
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

    it("fast-forwards only the running transition", function()
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "FastForwardPanel" }).new({
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
        handler.fastForward({ speed = 20 })
        task.wait(0.3)

        -- Without the fast-forward, 0.4 of the 1 second would have played.
        expect(alpha).toBe(1)

        handler.setState("Idle")
        task.wait(0.3)

        -- The next transition plays at normal speed again.
        expect(alpha < 0.9).toBe(true)

        expect(function()
            handler.fastForward({ speed = 0 })
        end).toThrow("fastForward speed must be a finite number above 0")

        expect(function()
            handler.fastForward({ speed = 2, scale = 2 } :: any)
        end).toThrow("fastForward options has an unknown key scale")

        expect(function()
            handler.fastForward(2 :: any)
        end).toThrow("fastForward options must be a table")
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

    it("pauses a transition when the speed is 0", function()
        local speed = Vide.source(1)
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "PausedPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.4,
                speed = speed,
            },
        })

        local calls = 0
        local lastAlpha = 0

        handler.onTransition(function(_, _, _, alpha)
            calls += 1
            lastAlpha = alpha
        end)

        handler.setState("Active")
        task.wait(0.1)
        speed(0)
        task.wait(0.05)

        local callsWhenPaused = calls
        local alphaWhenPaused = lastAlpha

        task.wait(0.1)

        expect(calls).toBe(callsWhenPaused)
        expect(lastAlpha).toBe(alphaWhenPaused)
        expect(lastAlpha < 1).toBe(true)

        speed(1)
        task.wait(0.6)

        expect(lastAlpha).toBe(1)
    end)

    it("clamps a negative speed to 0 so the transition never moves backwards", function()
        local speed = Vide.source(1)
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "BackwardsPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = 0.4,
                speed = speed,
            },
        })

        local alphas: { number } = {}

        handler.onTransition(function(_, _, _, alpha)
            table.insert(alphas, alpha)
        end)

        handler.setState("Active")
        task.wait(0.1)
        speed(-1)
        task.wait(0.1)

        for index = 2, #alphas do
            expect(alphas[index] >= alphas[index - 1]).toBe(true)
        end
    end)

    it("applies a duration source that changes during a transition", function()
        local duration = Vide.source(5)
        local handler = VideState.rule({
            opacity = VideState.float(),
        }, { name = "DynamicDurationPanel" }).new({
            Idle = { opacity = Vide.source(0) },
            Active = { opacity = Vide.source(1) },
        }, "Idle", {
            onTransition = {
                duration = duration,
            },
        })

        local lastCurrent = nil

        handler.onTransition(function(_, _, current)
            lastCurrent = current.opacity
        end)

        handler.setState("Active")
        task.wait(0.1)

        expect(lastCurrent < 1).toBe(true)

        duration(0.05)
        task.wait(0.3)

        expect(lastCurrent).toBe(1)
    end)

    it("rejects invalid onTransition options", function()
        local rule = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "BadOptionsPanel" })
        local states = {
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }

        expect(function()
            rule.new(states, "Idle", { onTransition = { easing = "bounce" } :: any })
        end).toThrow("onTransition easing must be a known easing name")

        expect(function()
            rule.new(states, "Idle", { onTransition = { duration = -1 } })
        end).toThrow("onTransition duration must be a finite non-negative number")

        expect(function()
            rule.new(states, "Idle", { onTransition = { speed = Vide.source(-1) } })
        end).toThrow("onTransition speed must not be negative")

        expect(function()
            rule.new(states, "Idle", { onTransition = { speed = 1 :: any } })
        end).toThrow("onTransition speed must be a source")

        expect(function()
            rule.new(states, "Idle", { onTransition = { tween = "quadIn" } :: any })
        end).toThrow("onTransition options has an unknown key tween")

        expect(function()
            rule.new(states, "Idle", { onTransition = "quadIn" :: any })
        end).toThrow("onTransition options must be a table")
    end)

    it("keeps state unchanged when switching to an unknown state", function()
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "UnknownPanel" }).new({
            Idle = { visible = Vide.source(false) },
            Active = { visible = Vide.source(true) },
        }, "Idle")

        expect(function()
            handler.setState("Missing")
        end).toThrow("unknown state")

        expect(handler.sources.visible()).toBe(false)
        expect(handler.currentState()).toBe("Idle")
    end)

    it("routes sources to the active state", function()
        local idleVisible = Vide.source(false)
        local activeVisible = Vide.source(false)
        local handler = VideState.rule({
            visible = VideState.boolean(),
        }, { name = "RoutePanel" }).new({
            Idle = { visible = idleVisible },
            Active = { visible = activeVisible },
        }, "Idle")

        handler.sources.visible(true)

        expect(idleVisible()).toBe(true)
        expect(activeVisible()).toBe(false)

        handler.setState("Active")

        expect(handler.sources.visible()).toBe(false)
    end)

    it("rejects a state field that is not a Vide source", function()
        expect(function()
            VideState.rule({
                visible = VideState.boolean(),
            }, { name = "NonSourcePanel" }).new({
                Idle = { visible = Vide.source(false) },
                Active = { visible = true },
            }, "Idle")
        end).toThrow('state "Active" field "visible" must be a Vide source')
    end)

    it("names the state whose source does not match the schema", function()
        expect(function()
            VideState.rule({
                visible = VideState.boolean(),
            }, { name = "InvalidPanel" }).new({
                Idle = { visible = Vide.source(false) },
                Active = { visible = Vide.source("yes") },
            }, "Idle")
        end).toThrow('Invalid state "Active"')
    end)

    it("requires every state to provide each field source", function()
        expect(function()
            VideState.rule({
                visible = VideState.boolean(),
            }, { name = "MissingPanel" }).new({
                Idle = { visible = Vide.source(false) },
                Active = {},
            }, "Idle")
        end).toThrow('state "Active" is missing source for field "visible"')
    end)

    it("rejects a rule name that is already registered", function()
        VideState.rule({ visible = VideState.boolean() }, { name = "DuplicatePanel" })

        expect(function()
            VideState.rule({ visible = VideState.boolean() }, { name = "DuplicatePanel" })
        end).toThrow("Duplicate rule name: DuplicatePanel")
    end)

    it("stores rule metadata for lookup by name", function()
        VideState.rule({ visible = VideState.boolean() }, {
            name = "LookupPanel",
            description = "Shows a panel",
            tags = { "ui" },
        })

        local info = Info.get("LookupPanel")
        if not info then
            error("LookupPanel metadata was not registered")
        end
        expect(info.description or nil).toBe("Shows a panel")
        expect(info.tags and info.tags[1]).toBe("ui")
        expect(Info.get("UnregisteredPanel")).toBe(nil)
    end)

    it("finds rules by tags, lists tags, and checks a rule's tags", function()
        VideState.rule({ visible = VideState.boolean() }, {
            name = "TagPanelA",
            tags = { "infoTagMenu", "infoTagShared" },
        })
        VideState.rule({ visible = VideState.boolean() }, {
            name = "TagPanelB",
            tags = { "infoTagHud", "infoTagShared" },
        })
        VideState.rule({ visible = VideState.boolean() }, {
            name = "TagPanelC",
        })

        local shared = Info.getAllRulesWithTags("infoTagShared")
        local sharedNames = {}

        for _, rule in shared do
            table.insert(sharedNames, rule.name)
        end

        expect(table.concat(sharedNames, ",")).toBe("TagPanelA,TagPanelB")

        local both = Info.getAllRulesWithTags("infoTagShared", "infoTagMenu")

        expect(#both).toBe(1)
        expect(both[1].name).toBe("TagPanelA")
        expect(#Info.getAllRulesWithTags("infoTagMissing")).toBe(0)

        local tags = Info.getAllTags()

        expect(table.find(tags, "infoTagMenu") ~= nil).toBe(true)
        expect(table.find(tags, "infoTagHud") ~= nil).toBe(true)
        expect(table.find(tags, "infoTagShared") ~= nil).toBe(true)

        local sharedCount = 0

        for _, tag in tags do
            if tag == "infoTagShared" then
                sharedCount += 1
            end
        end

        expect(sharedCount).toBe(1)

        expect(Info.ruleHasTag("TagPanelA", "infoTagMenu")).toBe(true)
        expect(Info.ruleHasTag("TagPanelA", "infoTagHud")).toBe(false)
        expect(Info.ruleHasTag("TagPanelC", "infoTagMenu")).toBe(false)
        expect(Info.ruleHasTag("UnregisteredTagPanel", "infoTagMenu")).toBe(false)
    end)

    it("compares tags exactly without formatting them", function()
        VideState.rule({ visible = VideState.boolean() }, {
            name = "ExactTagPanel",
            tags = { "ExactTag", " spaced " },
        })

        expect(Info.ruleHasTag("ExactTagPanel", "ExactTag")).toBe(true)
        expect(Info.ruleHasTag("ExactTagPanel", "exacttag")).toBe(false)
        expect(Info.ruleHasTag("ExactTagPanel", "spaced")).toBe(false)
        expect(Info.ruleHasTag("ExactTagPanel", " spaced ")).toBe(true)
    end)

    it("rejects invalid arguments for tag lookups", function()
        expect(function()
            Info.getAllRulesWithTags()
        end).toThrow("requires at least one tag")

        expect(function()
            Info.getAllRulesWithTags(1 :: any)
        end).toThrow("must be a string")

        expect(function()
            Info.ruleHasTag(1 :: any, "tag")
        end).toThrow("Rule name must be a string")

        expect(function()
            Info.ruleHasTag("TagPanelA", nil :: any)
        end).toThrow("Tag must be a string")
    end)

    it("rejects states outside allowedStateNames", function()
        local handler = VideState.rule({ visible = VideState.boolean() }, {
            name = "AllowedPanel",
            allowedStateNames = { "Idle", "Active" },
        })

        expect(function()
            handler.new({
                Idle = { visible = Vide.source(false) },
                Missing = { visible = Vide.source(true) },
            }, "Idle")
        end).toThrow('state "Missing" is not in allowedStateNames')
    end)
end)

return nil
