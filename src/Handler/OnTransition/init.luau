const Types = require("../Types")
const Options = require("@self/Config/Options")
const Group = require("@self/Tween/Group")
const Scheduler = require("@self/Playback/Scheduler")

type Callback<T> = Types.OnTransitionCallback<T>
type Disconnect = Types.Disconnect

type Connection<T> = {
    callback: Callback<T>,
    settings: Options.Settings,
}

-- Every connection tweens on its own, with its own settings. A setting the connection leaves out is read from
-- the handler options, which are the defaults for all of its connections.
return function <T>(options: Types.TransitionOptions?)
    local handlerSettings = Options.parse(options)

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

            local group = Group.create(
                from,
                to,
                connection.settings.getEasing(),
                connection.settings.getDuration()
            )

            Scheduler(group, connection.settings, function(current: T, alpha: number): number
                -- A connection that was disconnected is no longer in the table, so its loop stops.
                if connections[id] ~= connection then
                    return 0
                end

                connection.callback(from, to, current, alpha)

                return 1
            end, function()
                return generation ~= currentGeneration
            end)
        end
    end
end
