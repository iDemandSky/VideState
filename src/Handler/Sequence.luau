const Vide = require("../../packages/roblox/Vide")

const Types = require("../Types")
const Loop = require("./Transition/Loop")

type Disconnect = Types.Disconnect

-- What the sequence needs from its handler.
export type Controls = {
    read getState: () -> string,
    read hasState: (stateName: string) -> boolean,
    -- The reason a change is not allowed, or nil when it is.
    read checkChange: (from: string, to: string) -> string?,
    read isDestroyed: () -> boolean,
    read setState: (stateName: string, options: Types.SetStateOptions?) -> (),
    -- Yields until the handler has no running transition.
    read waitForFinish: () -> (),
    -- Counts the state changes of the handler. A sequence stops when a change it did not make moves it.
    read getGeneration: () -> number,
    -- 0 while the handler is paused, and the speed scale otherwise.
    read getRate: () -> number,
    -- Sets the round that the next transition reports to its connections. 0 means no sequence.
    read setRound: (round: number) -> (),
}

export type Sequence = {
    read playSequence: Types.PlaySequence,
    -- Stops the running sequence. `destroy` calls it.
    read clear: () -> (),
}

type Step = {
    state: string,
    hold: number,
    instant: boolean,
    delay: number,
}

-- One run of `playSequence`. `expected` is the generation of the handler after the last change the sequence made.
type Token = {
    cancelled: boolean,
    expected: number,
}

const STEP_KEYS: { [string]: boolean } = {
    state = true,
    hold = true,
    instant = true,
    delay = true,
}

const OPTION_KEYS: { [string]: boolean } = {
    loop = true,
    onLoop = true,
}

-- What the options of `playSequence` ask for. `rounds` is how many times the steps play, and `math.huge` is forever.
type SequenceSettings = {
    rounds: number,
    onLoop: ((round: number) -> ())?,
}

const function isFiniteNonNegative(value: unknown): boolean
    if type(value) ~= "number" then
        return false
    end

    local isNotNaN = value == value
    local isNotNegative = value >= 0
    local isNotInfinite = value ~= math.huge

    return isNotNaN and isNotNegative and isNotInfinite
end

-- Checks one step and returns it with its defaults. The error level of 4 points at the user's call.
const function parseStep(step: unknown, index: number, controls: Controls): Step
    if type(step) ~= "table" then
        error(`playSequence step {index} must be a table`, 4)
    end

    const fields = step :: { [any]: unknown }

    for key in fields do
        local isKnownKey = STEP_KEYS[key :: any] == true

        if not isKnownKey then
            error(`playSequence step {index} has an unknown key {tostring(key)}`, 4)
        end
    end

    const stateName = fields.state

    if type(stateName) ~= "string" then
        error(`playSequence step {index} needs a state name`, 4)
    end

    if not controls.hasState(stateName) then
        error(`playSequence step {index} has an unknown state "{stateName}"`, 4)
    end

    const hold = fields.hold
    const instant = fields.instant
    const delay = fields.delay

    if hold ~= nil and not isFiniteNonNegative(hold) then
        error(`playSequence step {index} hold must be a finite non-negative number`, 4)
    end

    if instant ~= nil and type(instant) ~= "boolean" then
        error(`playSequence step {index} instant must be a boolean`, 4)
    end

    if delay ~= nil and not isFiniteNonNegative(delay) then
        error(`playSequence step {index} delay must be a finite non-negative number`, 4)
    end

    return {
        state = stateName,
        hold = (hold :: number?) or 0,
        instant = instant == true,
        delay = (delay :: number?) or 0,
    }
end

-- Checks the steps, and that the rule's allowedTransitions let each state change to the next one.
const function parseSteps(steps: unknown, startsOver: boolean, controls: Controls): { Step }
    local isList = type(steps) == "table" and #(steps :: { unknown }) > 0

    if not isList then
        error("playSequence steps must be a non-empty list of steps", 3)
    end

    const parsed: { Step } = {}

    for index, step in steps :: { unknown } do
        table.insert(parsed, parseStep(step, index, controls))
    end

    local previous = controls.getState()

    for index, step in parsed do
        local reason = controls.checkChange(previous, step.state)

        if reason ~= nil then
            error(`playSequence step {index} {reason}`, 3)
        end

        previous = step.state
    end

    if startsOver then
        local reason = controls.checkChange(previous, parsed[1].state)

        if reason ~= nil then
            error(`playSequence cannot loop: {reason}`, 3)
        end
    end

    return parsed
end

-- Reads the options. The error level of 3 points at the user's call.
const function parseOptions(options: unknown): SequenceSettings
    if options == nil then
        return { rounds = 1, onLoop = nil }
    end

    if type(options) ~= "table" then
        error("playSequence options must be a table", 3)
    end

    const fields = options :: { [any]: unknown }

    for key in fields do
        local isKnownKey = OPTION_KEYS[key :: any] == true

        if not isKnownKey then
            error(`playSequence options has an unknown key {tostring(key)}`, 3)
        end
    end

    const loop = fields.loop
    const onLoop = fields.onLoop
    local rounds = 1

    if loop == true then
        rounds = math.huge
    elseif type(loop) == "number" then
        local isWhole = loop % 1 == 0
        local isPositive = loop >= 1
        local isFinite = loop ~= math.huge

        if not (isWhole and isPositive and isFinite) then
            error("playSequence loop must be a boolean or a whole number of rounds, at least 1", 3)
        end

        rounds = loop
    elseif loop ~= nil and loop ~= false then
        error("playSequence loop must be a boolean or a whole number of rounds, at least 1", 3)
    end

    if onLoop ~= nil and type(onLoop) ~= "function" then
        error("playSequence onLoop must be a function", 3)
    end

    return {
        rounds = rounds,
        onLoop = onLoop :: ((round: number) -> ())?,
    }
end

-- Yields the running thread for `seconds` of scaled time, so a pause holds it and the manual clock moves it. With 0
-- seconds it waits for the next frame. It continues at once when `isStale` reports that the sequence ended.
const function wait(seconds: number, getRate: () -> number, isStale: () -> boolean)
    const thread = coroutine.running()
    local elapsed = 0

    Loop.add({
        step = function(deltaTime: number): boolean
            if isStale() then
                task.spawn(thread)

                return false
            end

            elapsed += deltaTime * getRate()

            if elapsed < seconds then
                return true
            end

            task.spawn(thread)

            return false
        end,
        stop = function()
            task.spawn(thread)
        end,
    })

    coroutine.yield()
end

return function(controls: Controls): Sequence
    local active: Token? = nil

    const function cancel(token: Token)
        token.cancelled = true

        if active == token then
            active = nil
        end
    end

    const function isStale(token: Token): boolean
        local isCancelled = token.cancelled
        local isDestroyed = controls.isDestroyed()
        local isMoved = controls.getGeneration() ~= token.expected

        return isCancelled or isDestroyed or isMoved
    end

    -- Plays the steps one after another, round after round. It ends when something else changes the state of the
    -- handler.
    const function run(token: Token, steps: { Step }, settings: SequenceSettings, round: Vide.Source<number>)
        const stale = function(): boolean
            return isStale(token)
        end

        local completed = 0

        while true do
            const hasNextRound = completed + 1 < settings.rounds

            for index, step in steps do
                if stale() then
                    return
                end

                -- The transition reads the round when it starts, and the round is cleared right after, so a
                -- change from outside the sequence reports 0.
                controls.setRound(completed + 1)
                controls.setState(step.state, {
                    instant = step.instant,
                    delay = step.delay,
                })
                controls.setRound(0)

                token.expected = controls.getGeneration()
                controls.waitForFinish()

                if stale() then
                    return
                end

                -- The hold after the last step only matters when another round follows.
                local isLastStep = index == #steps
                local isHeld = step.hold > 0 and (hasNextRound or not isLastStep)

                if isHeld then
                    wait(step.hold, controls.getRate, stale)

                    if stale() then
                        return
                    end
                end
            end

            completed += 1

            if settings.onLoop ~= nil then
                settings.onLoop(completed)
            end

            if not hasNextRound then
                break
            end

            round(completed + 1)

            -- A frame between rounds, so a loop of instant steps cannot hold up the game.
            wait(0, controls.getRate, stale)
        end

        cancel(token)
    end

    const function playSequence(
        steps: { Types.SequenceStep },
        options: Types.SequenceOptions?
    ): (Types.Source<number>, Disconnect)
        if controls.isDestroyed() then
            error("playSequence cannot be called after destroy", 2)
        end

        const settings = parseOptions(options)
        const parsed = parseSteps(steps, settings.rounds > 1, controls)

        -- A newer sequence replaces the running one.
        if active ~= nil then
            cancel(active)
        end

        const token: Token = {
            cancelled = false,
            expected = controls.getGeneration(),
        }

        active = token

        const round = Vide.source(1)

        task.spawn(run, token, parsed, settings, round)

        return round, function()
            cancel(token)
        end
    end

    return table.freeze({
        playSequence = playSequence,
        clear = function()
            if active ~= nil then
                cancel(active)
            end
        end,
    })
end
