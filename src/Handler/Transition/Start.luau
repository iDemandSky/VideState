const Types = require("../../Types")
const Group = require("./Tween/Group")
const Scheduler = require("./Scheduler")
const State = require("./State")

-- Starts the run of one connection for a transition.
const function play<T>(
    state: State.State<T>,
    transition: Types.Transition,
    id: number,
    connection: State.Connection<T>,
    from: T,
    to: T,
    getRate: () -> number,
    settle: Types.SettleTransition
)
    local previousRun = connection.run
    local previousCurrent = connection.current
    local isRunning = previousRun ~= nil and not previousRun.ended and not Group.isDone(previousRun.group)
    local isInterrupted = isRunning and previousCurrent ~= nil
    local start = if isInterrupted then previousCurrent :: T else from

    local group = Group.create(
        start,
        to,
        connection.settings.getEasing(),
        connection.settings.getDuration()
    )

    local run: State.Run<T> = {
        group = group,
        from = from,
        to = to,
        ended = false,
        transition = transition,
    }

    connection.run = run

    Scheduler(group, connection.settings, getRate, function(current: T, alpha: number): number
        -- A connection that was disconnected is no longer in the table, so its loop stops.
        if state.connections[id] ~= connection then
            return 0
        end

        connection.current = current
        connection.callback(from, to, current, alpha)

        return 1
    end, function(): boolean
        return state.generation ~= transition.generation or run.ended
    end, function(completed: boolean)
        run.ended = true
        settle(transition, completed)
    end)
end

-- Creates the function that `setState` calls to start a transition on every connection.
return function<T>(
    state: State.State<T>,
    getRate: () -> number,
    settle: Types.SettleTransition
): Types.StateEmitter<T>
    return function(from: T, to: T)
        state.generation += 1
        state.startedAt = os.clock()
        state.scale = 1

        -- A connection added during a transition receives updates from the next transition.
        local ids: { number } = {}

        for id in state.connections do
            table.insert(ids, id)
        end

        local transition: Types.Transition = {
            generation = state.generation,
            pending = #ids,
            completed = false,
            fired = false,
        }

        state.currentTransition = transition

        for _, id in ids do
            local connection = state.connections[id]

            if connection == nil then
                settle(transition, false)

                continue
            end

            play(state, transition, id, connection, from, to, getRate, settle)
        end
    end
end
