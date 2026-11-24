const Types = require("../Types")
const Options = require("@self/Config/Options")
const State = require("@self/State")
const Connect = require("@self/Connect")
const Start = require("@self/Start")

export type Transition<T> = {
    -- Listens for transitions. Each connection can override the tween settings of the handler.
    read onTransition: Types.ConnectTransition<T>,
    -- Starts a transition on every connection. `setState` calls it.
    read emit: Types.StartTransition<T>,
}

-- The `onTransition` event of a handler: it tweens between the states, and one connection plays its own tween.
-- `getRate` scales the time that passes, and `settle` counts a connection of a transition as ended.
return function <T>(
    state: State.State<T>,
    options: Types.TransitionOptions?,
    getRate: () -> number,
    settle: Types.SettleTransition
): Transition<T>
    local handlerSettings = Options.parse(options)

    local transition: Transition<T> = {
        onTransition = Connect(state, handlerSettings, settle),
        emit = Start(state, getRate, settle),
    }

    return table.freeze(transition)
end
