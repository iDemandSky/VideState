const Types = require("@VideState/Types")
const Constants = require("@VideState/Handler/OnTransition/Config/Constants")
const Metadata = require("@VideState/Handler/OnTransition/Config/Metadata")
const FieldTweens = require("@VideState/Handler/OnTransition/Tween/FieldTweens")
const Run = require("@VideState/Handler/OnTransition/Playback/Run")
const Scheduler = require("@VideState/Handler/OnTransition/Playback/Scheduler")

type Callback<T> = Types.OnTransitionCallback<T>
type Disconnect = Types.Disconnect

return function <T>(duration: number?)
    local transitionDuration = if duration == nil then Constants.DEFAULT_DURATION else duration

    if not Metadata.isValidDuration(transitionDuration) then
        error("transition duration must be a finite non-negative number", 2)
    end

    local listeners: { [number]: Run.Listener<T> } = {}
    local nextId = 0
    local generation = 0

    return function(callback: Callback<T>, tweenMetadata: Types.TweenMetadata?): Disconnect
        if typeof(callback) ~= "function" then
            error("onTransition callback must be a function", 2)
        end

        local settings = Metadata.parse(tweenMetadata, transitionDuration)

        nextId += 1
        local id = nextId
        listeners[id] = {
            callback = callback,
            easing = settings.easing,
            duration = settings.duration,
            speed = settings.speed,
        }

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

        local runs: { Run.Run<T> } = {}
        for id, listener in listeners do
            table.insert(runs, Run(id, listener, from, to))
        end
        if #runs == 0 then
            return
        end

        Scheduler(runs, function(run, deltaTime)
            if listeners[run.id] ~= nil then
                run.callback(from, to, FieldTweens.frame(to, run.tweens, deltaTime))
            end
        end, function()
            return generation ~= currentGeneration
        end)
    end
end
