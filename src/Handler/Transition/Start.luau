const Types = require("../../Types")
const Group = require("./Tween/Group")
const Scheduler = require("./Scheduler")
const State = require("./State")

-- Whether the previous run of a connection is still playing, so a new transition continues from its last value.
const function isInterrupted<T>(connection: State.Connection<T>): boolean
    local run = connection.run

    if run == nil then
        return false
    end

    if connection.current == nil then
        return false
    end

    local hasEnded = run.ended
    local isDone = Group.isDone(run.group)

    return not hasEnded and not isDone
end

-- Starts the run of one connection for a transition.
const function play<T>(
    state: State.State<T>,
    transition: Types.Transition,
    id: number,
    connection: State.Connection<T>,
    from: T,
    to: T,
    instant: boolean,
    fromState: string,
    toState: string,
    extraDelay: number,
    getRate: () -> number,
    settle: Types.SettleTransition
)
    -- The override for this state change replaces the settings of the connection. Settings are picked when the
    -- transition starts, and a source inside them is still read every frame.
    local override = if connection.overrides == nil then nil else connection.overrides(fromState, toState)
    local settings = override or connection.settings
    local start = if isInterrupted(connection) then connection.current :: T else from
    -- A duration of 0 sends one frame with the next values and an alpha of 1, then ends.
    local duration = if instant then 0 else settings.getDuration()

    local group = Group.create(
        start,
        to,
        settings.getEasing(),
        duration
    )

    local run: State.Run<T> = {
        group = group,
        from = from,
        to = to,
        ended = false,
        transition = transition,
    }

    connection.run = run

    -- An instant transition ignores the delay as well. The delay of `setState` adds to the connection's own.
    local delay = if instant then 0 else settings.getDelay() + extraDelay

    Scheduler(group, settings, delay, getRate, function(current: T, alpha: number): number
        -- A connection that was disconnected is no longer in the table, so its loop stops.
        if state.connections[id] ~= connection then
            return 0
        end

        connection.current = current
        connection.callback(from, to, current, alpha, transition.round)

        return 1
    end, function(): boolean
        local isReplaced = state.generation ~= transition.generation
        local hasEnded = run.ended

        return isReplaced or hasEnded
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
): Types.StartTransition<T>
    return function(from: T, to: T, instant: boolean, fromState: string, toState: string, extraDelay: number)
        state.generation += 1
        state.startedAt = os.clock()
        state.scale = 1

        -- A connection added during a transition receives updates from the next transition.
        local ids: { number } = {}

        for id in state.connections do
            table.insert(ids, id)
        end

        -- One extra count holds the transition open until every connection has started, so it cannot end while
        -- they are being started. A transition with no connections ends right away.
        local transition: Types.Transition = {
            generation = state.generation,
            round = state.round,
            pending = #ids + 1,
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

            play(state, transition, id, connection, from, to, instant, fromState, toState, extraDelay, getRate, settle)
        end

        settle(transition, false)
    end
end
