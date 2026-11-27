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
const function parseSteps(steps: unknown, loop: boolean, controls: Controls): { Step }
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

    if loop then
        local reason = controls.checkChange(previous, parsed[1].state)

        if reason ~= nil then
            error(`playSequence cannot loop: {reason}`, 3)
        end
    end

    return parsed
end

-- Reads the options and returns whether the sequence loops.
const function parseOptions(options: unknown): boolean
    if options == nil then
        return false
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

    if loop ~= nil and type(loop) ~= "boolean" then
        error("playSequence loop must be a boolean", 3)
    end

    return loop == true
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

    -- Plays the steps one after another. It ends when a step is no longer the state of the handler, because
    -- something else changed it.
    const function run(token: Token, steps: { Step }, loop: boolean)
        const stale = function(): boolean
            return isStale(token)
        end

        while true do
            for index, step in steps do
                if stale() then
                    return
                end

                controls.setState(step.state, {
                    instant = step.instant,
                    delay = step.delay,
                })

                token.expected = controls.getGeneration()
                controls.waitForFinish()

                if stale() then
                    return
                end

                -- The hold after the last step only matters when the sequence starts over.
                local isLastStep = index == #steps
                local isHeld = step.hold > 0 and (loop or not isLastStep)

                if isHeld then
                    wait(step.hold, controls.getRate, stale)

                    if stale() then
                        return
                    end
                end
            end

            if not loop then
                break
            end

            -- A frame between rounds, so a loop of instant steps cannot hold up the game.
            wait(0, controls.getRate, stale)
        end

        cancel(token)
    end

    const function playSequence(steps: { Types.SequenceStep }, options: Types.SequenceOptions?): Disconnect
        if controls.isDestroyed() then
            error("playSequence cannot be called after destroy", 2)
        end

        const loop = parseOptions(options)
        const parsed = parseSteps(steps, loop, controls)

        -- A newer sequence replaces the running one.
        if active ~= nil then
            cancel(active)
        end

        const token: Token = {
            cancelled = false,
            expected = controls.getGeneration(),
        }

        active = token

        task.spawn(run, token, parsed, loop)

        return function()
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
