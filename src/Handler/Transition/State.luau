const Types = require("../../Types")
const Options = require("./Config/Options")
const Overrides = require("./Config/Overrides")
const Group = require("./Tween/Group")

-- What one connection plays for one transition. `ended` is set when it finishes, is finished early, or disconnects.
export type Run<T> = {
    group: Group.Group<T>,
    from: T,
    to: T,
    ended: boolean,
    transition: Types.Transition,
}

export type Connection<T> = {
    callback: Types.OnTransitionCallback<T>,
    settings: Options.Settings,
    -- Finds the override for a state change. Nil when the connection has no overrides, so it costs nothing then.
    overrides: Overrides.Resolver?,
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
    currentTransition: Types.Transition?,
    -- The scale that `scaleSpeed` puts on the running transition. A new transition resets it.
    scale: number,
    -- The scale that `scaleSpeed` keeps for every transition when `once` is false.
    baseScale: number,
    -- The round of the `playSequence` that is starting a transition. 0 when no sequence is.
    round: number,
}

const function create<T>(): State<T>
    return {
        connections = {},
        nextId = 0,
        generation = 0,
        startedAt = nil,
        currentTransition = nil,
        scale = 1,
        baseScale = 1,
        round = 0,
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
