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
}

-- How a transition ends: when its last connection ends, or when `finish` ends it early.
return function <T>(state: State.State<T>): Finish
    local onFinish, emitFinish = CreateEvent("onFinish")

    -- The finish event fires once, when the last connection ends, if at least one of them reached its end
    -- and no newer transition replaced this one.
    const function settle(transition: Types.Transition, completed: boolean)
        transition.pending -= 1

        if completed then
            transition.completed = true
        end

        local isLast = transition.pending == 0
        local isCurrent = transition.generation == state.generation
        local shouldFire = isLast and isCurrent and transition.completed and not transition.fired

        if shouldFire then
            transition.fired = true
            emitFinish(State.getStartedAt(state))
        end
    end

    const function finish()
        local transition = state.currentTransition

        if transition == nil then
            return
        end

        local ids: { number } = {}

        for id, connection in state.connections do
            local run = connection.run

            if run ~= nil and run.transition == transition and not run.ended then
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
            local run = if connection == nil then nil else connection.run

            if connection ~= nil and run ~= nil and run.transition == transition and not run.ended then
                run.ended = true
                connection.current = run.to
                connection.callback(run.from, run.to, run.to, 1)
                settle(transition, true)
            end
        end
    end

    local controls: Finish = {
        settle = settle,
        finish = finish,
        onFinish = onFinish,
    }

    return table.freeze(controls)
end
