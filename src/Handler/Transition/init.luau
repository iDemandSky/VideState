const Types = require("../Types")
const State = require("@self/State")
const Connect = require("@self/Connect")
const Start = require("@self/Start")

export type Transition<T> = {
    -- Listens for transitions. Each connection can override the tween settings of the handler.
    read onTransition: Types.ConnectTransition<T>,
    -- Starts a transition on every connection. `setState` calls it.
    read emit: Types.StartTransition<T>,
    -- Stops every running transition without another frame, and removes every connection. `destroy` calls it.
    read stop: () -> (),
}

-- The `onTransition` event of a handler: it tweens between the states, and one connection plays its own tween.
-- `getRate` scales the time that passes, and `settle` counts a connection of a transition as ended.
return function <T>(
    state: State.State<T>,
    getRate: () -> number,
    settle: Types.SettleTransition
): Transition<T>
    local transition: Transition<T> = {
        onTransition = Connect(state, settle),
        emit = Start(state, getRate, settle),
        stop = function()
            -- A new generation makes every running loop stale, so each one stops on its next frame.
            state.generation += 1
            state.currentTransition = nil
            table.clear(state.connections)
        end,
    }

    return table.freeze(transition)
end
