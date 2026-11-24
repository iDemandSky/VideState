const Types = require("../Types")
const CreateEvent = require("../Utils/StartTimeEvent")
const State = require("./Transition/State")

type Disconnect = Types.Disconnect

export type Finish = {
    -- Counts one connection of a transition as ended. The transitions call it.
    read settle: Types.SettleTransition,
    -- Sends the last frame to every connection that is still playing the current transition, and ends it.
    read finish: () -> (),
    read onFinish: (callback: Types.OnFinishCallback) -> Disconnect,
    -- Yields until the handler has no running transition.
    read waitForFinish: () -> (),
    -- Removes every finish listener and releases the waiting threads. `destroy` calls it.
    read clear: () -> (),
}

-- The run of a connection when it is still playing the transition, and nil when it is not.
const function getPlayingRun<T>(connection: State.Connection<T>, transition: Types.Transition): State.Run<T>?
    local run = connection.run

    if run == nil then
        return nil
    end

    local isSameTransition = run.transition == transition
    local hasEnded = run.ended

    if isSameTransition and not hasEnded then
        return run
    end

    return nil
end

-- How a transition ends: when its last connection ends, or when `finish` ends it early.
return function <T>(state: State.State<T>): Finish
    local onFinish, emitFinish, clearFinish = CreateEvent("onFinish")
    local waiting: { thread } = {}

    const function releaseWaiting()
        local threads = waiting

        waiting = {}

        for _, thread in threads do
            task.spawn(thread)
        end
    end

    -- The finish event fires once, when the last connection ends, if at least one of them reached its end
    -- and no newer transition replaced this one. Once the current transition has no connection left, the
    -- handler is idle and the waiting threads continue, whether or not it reached its end.
    const function settle(transition: Types.Transition, completed: boolean)
        transition.pending -= 1

        if completed then
            transition.completed = true
        end

        local isLast = transition.pending == 0
        local isCurrent = transition.generation == state.generation
        local isCompleted = transition.completed
        local isNotFired = not transition.fired
        local shouldFire = isLast and isCurrent and isCompleted and isNotFired
        local isIdle = isLast and isCurrent

        if shouldFire then
            transition.fired = true
            emitFinish(State.getStartedAt(state))
        end

        if isIdle then
            releaseWaiting()
        end
    end

    const function isRunning(): boolean
        local transition = state.currentTransition

        if transition == nil then
            return false
        end

        return transition.pending > 0
    end

    const function waitForFinish()
        if not isRunning() then
            return
        end

        table.insert(waiting, coroutine.running())
        coroutine.yield()
    end

    const function finish()
        local transition = state.currentTransition

        if transition == nil then
            return
        end

        local ids: { number } = {}

        for id, connection in state.connections do
            local isPlaying = getPlayingRun(connection, transition) ~= nil

            if isPlaying then
                table.insert(ids, id)
            end
        end

        for _, id in ids do
            local isReplaced = transition.generation ~= state.generation

            -- A callback can start a new transition, which replaces the one being finished.
            if isReplaced then
                break
            end

            local connection = state.connections[id]

            if connection == nil then
                continue
            end

            local run = getPlayingRun(connection, transition)

            if run == nil then
                continue
            end

            run.ended = true
            connection.current = run.to
            connection.callback(run.from, run.to, run.to, 1)
            settle(transition, true)
        end
    end

    local controls: Finish = {
        settle = settle,
        finish = finish,
        onFinish = onFinish,
        waitForFinish = waitForFinish,
        clear = function()
            clearFinish()
            releaseWaiting()
        end,
    }

    return table.freeze(controls)
end
