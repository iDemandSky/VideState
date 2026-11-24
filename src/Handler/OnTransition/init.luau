const Types = require("../Types")
const Options = require("@self/Config/Options")
const Group = require("@self/Tween/Group")
const Scheduler = require("@self/Playback/Scheduler")
const CreatePause = require("@self/Playback/Pause")

type Callback<T> = Types.OnTransitionCallback<T>
type Disconnect = Types.Disconnect

type Connection<T> = {
    callback: Callback<T>,
    settings: Options.Settings,
    -- The transition this connection is playing, and the last value it sent. A new transition that starts
    -- before this one finishes continues from that value instead of jumping back to the previous state.
    group: Group.Group<T>?,
    current: T?,
}

-- Every connection tweens on its own, with its own settings. A setting the connection leaves out is read from
-- the handler options, which are the defaults for all of its connections.
return function <T>(options: Types.TransitionOptions?)
    local handlerSettings = Options.parse(options)
    local pause = CreatePause()

    local connections: { [number]: Connection<T> } = {}
    local nextId = 0
    local generation = 0

    return function(callback: Callback<T>, connectionOptions: Types.TransitionOptions?): Disconnect
        if typeof(callback) ~= "function" then
            error("onTransition callback must be a function", 2)
        end

        local settings = Options.parse(connectionOptions, handlerSettings)

        nextId += 1

        local id = nextId

        connections[id] = {
            callback = callback,
            settings = settings,
            group = nil,
            current = nil,
        }

        local connected = true

        return function()
            if not connected then
                return
            end

            connected = false
            connections[id] = nil
        end
    end, function(from: T, to: T)
        generation += 1
        pause.markStarted()

        local currentGeneration = generation

        -- A connection added during a transition receives updates from the next transition.
        local ids: { number } = {}

        for id in connections do
            table.insert(ids, id)
        end

        for _, id in ids do
            local connection = connections[id]

            if connection == nil then
                continue
            end

            local previousGroup = connection.group
            local previousCurrent = connection.current
            local isInterrupted = previousGroup ~= nil and previousCurrent ~= nil and not Group.isDone(previousGroup)
            local start = if isInterrupted then previousCurrent :: T else from

            local group = Group.create(
                start,
                to,
                connection.settings.getEasing(),
                connection.settings.getDuration()
            )

            connection.group = group

            Scheduler(group, connection.settings, pause.isPaused, function(current: T, alpha: number): number
                -- A connection that was disconnected is no longer in the table, so its loop stops.
                if connections[id] ~= connection then
                    return 0
                end

                connection.current = current
                connection.callback(from, to, current, alpha)

                return 1
            end, function()
                return generation ~= currentGeneration
            end)
        end
    end, pause
end
