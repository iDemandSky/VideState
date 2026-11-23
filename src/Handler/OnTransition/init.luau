const Types = require("@VideState/Types")
const Options = require("@VideState/Handler/OnTransition/Config/Options")
const Group = require("@VideState/Handler/OnTransition/Tween/Group")
const Scheduler = require("@VideState/Handler/OnTransition/Playback/Scheduler")

type Callback<T> = Types.OnTransitionCallback<T>
type Disconnect = Types.Disconnect

return function <T>(options: Types.TransitionOptions?)
    local settings = Options.parse(options)

    local listeners: { [number]: Callback<T> } = {}
    local nextId = 0
    local generation = 0

    return function(callback: Callback<T>): Disconnect
        if typeof(callback) ~= "function" then
            error("onTransition callback must be a function", 2)
        end

        nextId += 1

        local id = nextId

        listeners[id] = callback

        local connected = true

        return function()
            if not connected then
                return
            end

            connected = false
            listeners[id] = nil
        end
    end, function(from: T, to: T)
        generation += 1

        local currentGeneration = generation

        -- A listener added during a transition receives updates from the next transition.
        local ids: { number } = {}

        for id in listeners do
            table.insert(ids, id)
        end

        if #ids == 0 then
            return
        end

        local group = Group.create(from, to, settings.getEasing(), settings.getDuration())

        Scheduler(group, settings, function(current: T, alpha: number): number
            local remaining = 0

            for _, id in ids do
                local callback = listeners[id]

                if callback ~= nil then
                    remaining += 1
                    callback(from, to, current, alpha)
                end
            end

            return remaining
        end, function()
            return generation ~= currentGeneration
        end)
    end
end
