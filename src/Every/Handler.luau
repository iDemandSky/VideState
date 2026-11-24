const Types = require("../Types")
const SpeedScale = require("../Utils/SpeedScale")
const Registry = require("./Registry")
const Scale = require("./Scale")

-- Calls `action` on a snapshot of every handler. A handler that raises does not stop the others, and the
-- first error is raised once every handler has run.
const function forEach(action: (handler: Registry.Controls) -> ())
    local firstError: unknown = nil
    local hasError = false

    for _, handler in Registry.list() do
        const ok, err = pcall(action, handler)

        if not ok and not hasError then
            hasError = true
            firstError = err
        end
    end

    if hasError then
        error(firstError, 0)
    end
end

-- Pauses every handler, so each one fires its own `onPause`.
const function pause()
    forEach(function(handler)
        handler.pause()
    end)
end

-- Resumes every handler, so each one fires its own `onResume`.
const function resume()
    forEach(function(handler)
        handler.resume()
    end)
end

-- Ends the running transition of every handler at once.
const function finish()
    forEach(function(handler)
        handler.finish()
    end)
end

-- Scales the speed of every handler. With `once = true` only the transitions that run now are scaled. Otherwise
-- it sets the scale that every handler multiplies by, now and for handlers created later, until it is called again.
const function scaleSpeed(options: Types.ScaleSpeedOptions)
    const speed, once = SpeedScale.parse(options, "every.handler.scaleSpeed")

    if not once then
        Scale.set(speed)

        return
    end

    forEach(function(handler)
        handler.scaleSpeed({
            speed = speed,
            once = true,
        })
    end)
end

return table.freeze({
    pause = pause,
    resume = resume,
    finish = finish,
    scaleSpeed = scaleSpeed,
})
