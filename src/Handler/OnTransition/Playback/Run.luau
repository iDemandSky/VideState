const Types = require("@VideState/Types")
const FieldTweens = require("@VideState/Handler/OnTransition/Tween/FieldTweens")

export type Listener<T> = {
    callback: Types.OnTransitionCallback<T>,
    easing: Types.TweenName?,
    duration: number,
    speed: Types.Source<number>?,
}

export type Run<T> = {
    id: number,
    callback: Types.OnTransitionCallback<T>,
    duration: number,
    speed: Types.Source<number>?,
    elapsed: number,
    tweens: FieldTweens.FieldTweens,
}

-- One listener's playback of a single transition.
return function <T>(id: number, listener: Listener<T>, from: T, to: T): Run<T>
    local tweens: FieldTweens.FieldTweens = {}

    if listener.duration > 0 then
        tweens = FieldTweens.create(from, to, listener.easing, listener.duration)
    end
    return {
        id = id,
        callback = listener.callback,
        duration = listener.duration,
        speed = listener.speed,
        elapsed = 0,
        tweens = tweens,
    }
end
