const Types = require("../../../Types")
const Options = require("../Config/Options")
const Group = require("../Tween/Group")

export type Callback<T> = Types.OnTransitionCallback<T>

-- One `setState` that has listeners. It is finished when every connection that was playing it has ended.
export type Transition = {
    generation: number,
    pending: number,
    completed: boolean,
    fired: boolean,
}

-- What one connection plays for one transition. `ended` is set when it finishes, is finished early, or disconnects.
export type Run<T> = {
    group: Group.Group<T>,
    from: T,
    to: T,
    ended: boolean,
    transition: Transition,
}

export type Connection<T> = {
    callback: Callback<T>,
    settings: Options.Settings,
    -- The last run and the last value it sent. A new transition that starts before this run ends
    -- continues from that value instead of jumping back to the previous state.
    run: Run<T>?,
    current: T?,
}

-- What the parts of the transition handling share for one handler.
export type State<T> = {
    connections: { [number]: Connection<T> },
    nextId: number,
    -- Counts the transitions. A running transition is stale once this moves past its own number.
    generation: number,
    startedAt: number?,
    currentTransition: Transition?,
    -- The scale that `fastForward` puts on the running transition. A new transition resets it.
    scale: number,
}

const function create<T>(): State<T>
    return {
        connections = {},
        nextId = 0,
        generation = 0,
        startedAt = nil,
        currentTransition = nil,
        scale = 1,
    }
end

-- The time the latest transition started. Before the first one, it is the current time.
const function getStartedAt<T>(state: State<T>): number
    return state.startedAt or os.clock()
end

return table.freeze({
    create = create,
    getStartedAt = getStartedAt,
})
