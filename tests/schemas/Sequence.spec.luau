const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const function createHandler(name: string, metadata: { [string]: any }?)
    const fullMetadata: { [string]: any } = { name = name }

    for key, value in metadata or {} do
        fullMetadata[key] = value
    end

    return VideState.rule({
        opacity = VideState.float(),
    }, fullMetadata :: any).new({
        Hidden = { opacity = Vide.source(0) },
        Shown = { opacity = Vide.source(1) },
        Flash = { opacity = Vide.source(0.5) },
    }, "Hidden")
end

-- Records the states the handler enters.
const function trackStates(handler: any): { string }
    const entered: { string } = {}

    handler.onEnter("Hidden", function()
        table.insert(entered, "Hidden")
    end)
    handler.onEnter("Shown", function()
        table.insert(entered, "Shown")
    end)
    handler.onEnter("Flash", function()
        table.insert(entered, "Flash")
    end)

    return entered
end

describe("playSequence", function()
    it("plays the steps in order, waiting for each transition and its hold", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequencePanel")
        local entered = trackStates(handler)

        handler.onTransition(function() end, {
            tweenDefault = {
                duration = 1,
            },
        })

        handler.playSequence({
            { state = "Shown", hold = 2 },
            { state = "Hidden" },
        })

        -- The first step starts at once.
        expect(handler.currentState()).toBe("Shown")
        expect(#entered).toBe(1)

        -- The transition takes 1 second, and then the step holds for 2.
        VideState.advanceClock(1)
        expect(handler.currentState()).toBe("Shown")

        VideState.advanceClock(1.5)
        expect(handler.currentState()).toBe("Shown")

        VideState.advanceClock(0.6)
        expect(handler.currentState()).toBe("Hidden")
        expect(entered[2]).toBe("Hidden")

        VideState.setManualClock(false)
    end)

    it("ignores the hold of the last step when it does not loop", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequenceLastHoldPanel")
        local entered = trackStates(handler)

        handler.playSequence({
            { state = "Shown" },
            { state = "Hidden", hold = 100 },
        })

        VideState.advanceClock(0.1)
        VideState.advanceClock(0.1)

        expect(handler.currentState()).toBe("Hidden")
        expect(#entered).toBe(2)

        VideState.setManualClock(false)
    end)

    it("starts over after the last step when it loops, until it is stopped", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequenceLoopPanel")
        local entered = trackStates(handler)
        local _, stop = handler.playSequence({
            { state = "Shown", hold = 1 },
            { state = "Hidden", hold = 1 },
        }, { loop = true })

        for _ = 1, 8 do
            VideState.advanceClock(1.1)
        end

        expect(#entered >= 5).toBe(true)

        stop()

        local count = #entered

        for _ = 1, 4 do
            VideState.advanceClock(1.1)
        end

        expect(#entered).toBe(count)

        VideState.setManualClock(false)
    end)

    it("plays the steps a set number of times when loop is a number", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequenceRoundsPanel")
        local entered = trackStates(handler)

        handler.playSequence({
            { state = "Shown", hold = 1 },
            { state = "Hidden", hold = 1 },
        }, { loop = 3 })

        for _ = 1, 20 do
            VideState.advanceClock(1.1)
        end

        -- Three rounds of two steps, and then it stops.
        expect(#entered).toBe(6)
        expect(handler.currentState()).toBe("Hidden")

        VideState.setManualClock(false)
    end)

    it("calls onLoop at the end of every round with the rounds completed", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequenceOnLoopPanel")
        local rounds: { number } = {}

        handler.playSequence({
            { state = "Shown", hold = 1 },
            { state = "Hidden", hold = 1 },
        }, {
            loop = 3,
            onLoop = function(round)
                table.insert(rounds, round)
            end,
        })

        for _ = 1, 20 do
            VideState.advanceClock(1.1)
        end

        expect(#rounds).toBe(3)
        expect(rounds[1]).toBe(1)
        expect(rounds[2]).toBe(2)
        expect(rounds[3]).toBe(3)

        VideState.setManualClock(false)
    end)

    it("calls onLoop once for a sequence that is not looped", function()
        local handler = createHandler("SequenceOnLoopOncePanel")
        local rounds: { number } = {}

        VideState.setManualClock(true)

        handler.playSequence({
            { state = "Shown", instant = true },
        }, {
            onLoop = function(round)
                table.insert(rounds, round)
            end,
        })

        VideState.advanceClock(0.1)

        expect(#rounds).toBe(1)
        expect(rounds[1]).toBe(1)

        VideState.setManualClock(false)
    end)

    it("returns a source that holds the round being played", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequenceSourcePanel")
        local round, stop = handler.playSequence({
            { state = "Shown", hold = 1 },
            { state = "Hidden", hold = 1 },
        }, { loop = true })

        expect(round()).toBe(1)

        for _ = 1, 3 do
            VideState.advanceClock(1.1)
        end

        local afterOne = round()

        expect(afterOne >= 2).toBe(true)

        for _ = 1, 4 do
            VideState.advanceClock(1.1)
        end

        expect(round() > afterOne).toBe(true)

        stop()

        local stopped = round()

        for _ = 1, 4 do
            VideState.advanceClock(1.1)
        end

        expect(round()).toBe(stopped)

        VideState.setManualClock(false)
    end)

    it("tells onTransition connections which round they are playing", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequenceConnectionPanel")
        local roundsSeen: { number } = {}

        handler.onTransition(function(_, _, _, alpha, round)
            if alpha == 0 then
                table.insert(roundsSeen, round)
            end
        end, {
            tweenDefault = {
                duration = 0.5,
            },
        })

        handler.playSequence({
            { state = "Shown", hold = 1 },
            { state = "Hidden", hold = 1 },
        }, { loop = 2 })

        for _ = 1, 20 do
            VideState.advanceClock(1.1)
        end

        -- Two steps in each of the two rounds.
        expect(#roundsSeen).toBe(4)
        expect(roundsSeen[1]).toBe(1)
        expect(roundsSeen[2]).toBe(1)
        expect(roundsSeen[3]).toBe(2)
        expect(roundsSeen[4]).toBe(2)

        -- A change from outside the sequence has no round.
        handler.setState("Shown")

        expect(roundsSeen[5]).toBe(0)

        VideState.setManualClock(false)
    end)

    it("stops when something else changes the state", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequenceInterruptPanel")
        local entered = trackStates(handler)

        handler.playSequence({
            { state = "Shown", hold = 1 },
            { state = "Hidden" },
        })

        VideState.advanceClock(0.5)
        handler.setState("Flash")

        VideState.advanceClock(2)
        VideState.advanceClock(2)

        expect(handler.currentState()).toBe("Flash")
        expect(entered[#entered]).toBe("Flash")

        VideState.setManualClock(false)
    end)

    it("holds while the handler is paused and follows scaleSpeed", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequenceScalePanel")

        handler.playSequence({
            { state = "Shown", hold = 1 },
            { state = "Hidden" },
        })

        handler.pause()
        VideState.advanceClock(5)
        expect(handler.currentState()).toBe("Shown")

        handler.resume()
        handler.scaleSpeed({ speed = 4 })
        VideState.advanceClock(0.3)
        VideState.advanceClock(0.1)

        expect(handler.currentState()).toBe("Hidden")

        VideState.setManualClock(false)
    end)

    it("plays an instant step in one frame, and the hold still applies", function()
        VideState.setManualClock(true)

        local handler = createHandler("SequenceInstantPanel")
        local frames: { number } = {}

        handler.onTransition(function(_, _, _, alpha)
            table.insert(frames, alpha)
        end, {
            tweenDefault = {
                duration = 5,
            },
        })

        handler.playSequence({
            { state = "Shown", instant = true, hold = 1 },
            { state = "Hidden", instant = true },
        })

        expect(#frames).toBe(1)
        expect(frames[1]).toBe(1)

        VideState.advanceClock(0.5)
        expect(handler.currentState()).toBe("Shown")

        VideState.advanceClock(0.6)
        expect(handler.currentState()).toBe("Hidden")
        expect(#frames).toBe(2)

        VideState.setManualClock(false)
    end)

    it("is stopped by destroy, and a newer sequence replaces the running one", function()
        VideState.setManualClock(true)

        local destroyed = createHandler("SequenceDestroyPanel")
        local destroyedEntered = trackStates(destroyed)

        destroyed.playSequence({
            { state = "Shown", hold = 1 },
            { state = "Hidden" },
        })
        destroyed.destroy()

        VideState.advanceClock(2)
        VideState.advanceClock(2)
        expect(#destroyedEntered).toBe(1)

        local handler = createHandler("SequenceReplacePanel")
        local entered = trackStates(handler)

        handler.playSequence({
            { state = "Shown", hold = 1 },
            { state = "Hidden" },
        })
        handler.playSequence({
            { state = "Flash" },
        })

        VideState.advanceClock(2)
        VideState.advanceClock(2)

        expect(handler.currentState()).toBe("Flash")
        expect(entered[#entered]).toBe("Flash")

        VideState.setManualClock(false)
    end)

    it("checks the steps against the rule's allowed transitions before it starts", function()
        local handler = createHandler("SequenceAllowedPanel", {
            allowedTransitions = {
                Flash = { "Hidden" },
            },
        })

        expect(function()
            handler.playSequence({
                { state = "Flash" },
                { state = "Shown" },
            })
        end).toThrow('step 2 cannot change state from "Flash" to "Shown". Allowed: "Hidden"')
        expect(handler.currentState()).toBe("Hidden")

        -- Flash can go back to Hidden, so a sequence that ends there can loop.
        local ok, _, stop = pcall(handler.playSequence, {
            { state = "Flash" },
            { state = "Hidden" },
        }, { loop = true })

        expect(ok).toBe(true)

        if ok then
            stop()
        end
    end)

    it("rejects invalid steps and options", function()
        local handler = createHandler("SequenceInvalidPanel")

        expect(function()
            handler.playSequence({})
        end).toThrow("non-empty list")
        expect(function()
            handler.playSequence("Shown" :: any)
        end).toThrow("non-empty list")
        expect(function()
            handler.playSequence({ "Shown" :: any })
        end).toThrow("step 1 must be a table")
        expect(function()
            handler.playSequence({ { hold = 1 } :: any })
        end).toThrow("step 1 needs a state name")
        expect(function()
            handler.playSequence({ { state = "Missing" } })
        end).toThrow('step 1 has an unknown state "Missing"')
        expect(function()
            handler.playSequence({ { state = "Shown", hold = -1 } })
        end).toThrow("step 1 hold must be a finite non-negative number")
        expect(function()
            handler.playSequence({ { state = "Shown", instant = "yes" :: any } })
        end).toThrow("step 1 instant must be a boolean")
        expect(function()
            handler.playSequence({ { state = "Shown", delay = -1 } })
        end).toThrow("step 1 delay must be a finite non-negative number")
        expect(function()
            handler.playSequence({ { state = "Shown", repeats = 2 } :: any })
        end).toThrow("unknown key repeats")
        expect(function()
            handler.playSequence({ { state = "Shown" } }, { loop = "yes" :: any })
        end).toThrow("loop must be a boolean or a whole number of rounds")
        expect(function()
            handler.playSequence({ { state = "Shown" } }, { loop = 0 })
        end).toThrow("whole number of rounds, at least 1")
        expect(function()
            handler.playSequence({ { state = "Shown" } }, { loop = 1.5 })
        end).toThrow("whole number of rounds, at least 1")
        expect(function()
            handler.playSequence({ { state = "Shown" } }, { onLoop = "print" :: any })
        end).toThrow("onLoop must be a function")
        expect(function()
            handler.playSequence({ { state = "Shown" } }, { times = 2 } :: any)
        end).toThrow("unknown key times")
        expect(function()
            handler.playSequence({ { state = "Shown" } }, "loop" :: any)
        end).toThrow("options must be a table")
    end)

    it("raises an error after the handler is destroyed", function()
        local handler = createHandler("SequenceAfterDestroyPanel")

        handler.destroy()

        expect(function()
            handler.playSequence({ { state = "Shown" } })
        end).toThrow("cannot be called after destroy")
    end)
end)

return nil
