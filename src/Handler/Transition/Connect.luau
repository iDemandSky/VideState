const Types = require("../../Types")
const Options = require("./Config/Options")
const State = require("./State")

type Disconnect = Types.Disconnect

-- Creates `onTransition`. A connection keeps its own settings, and a setting it leaves out takes the built-in
-- default.
return function<T>(
    state: State.State<T>,
    settle: Types.SettleTransition
): Types.ConnectTransition<T>
    return function(callback: Types.OnTransitionCallback<T>, connectionOptions: Types.TransitionOptions?): Disconnect
        if typeof(callback) ~= "function" then
            error("onTransition callback must be a function", 2)
        end

        local settings = Options.parse(connectionOptions)

        state.nextId += 1

        local id = state.nextId

        state.connections[id] = {
            callback = callback,
            settings = settings,
            run = nil,
            current = nil,
        }

        local connected = true

        return function()
            if not connected then
                return
            end

            connected = false

            local connection = state.connections[id]

            state.connections[id] = nil

            local run = if connection == nil then nil else connection.run

            if run == nil then
                return
            end

            local isPlaying = not run.ended

            -- A connection that leaves in the middle of a transition no longer counts toward its end.
            if isPlaying then
                run.ended = true
                settle(run.transition, false)
            end
        end
    end
end
