const Types = require("../Types")
const SpeedScale = require("../Utils/SpeedScale")
const Registry = require("./Registry")
const Scale = require("./Scale")

-- Calls `action` on a snapshot of the handlers, filtered by `tags` when given. A handler that raises does not
-- stop the others, and the first error is raised once every handler has run.
const function forEach(tags: { string }?, action: (handler: Registry.Controls) -> ())
    local firstError: unknown = nil
    local hasError = false

    for _, handler in Registry.list(tags) do
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

-- Builds the functions of one scope: every handler, or the handlers whose rule has all of `tags`. The handlers
-- are looked up each time a function is called, so a handler created later is included.
const function createGroup(tags: { string }?, name: string): Types.EveryHandlerGroup
    const function pause()
        forEach(tags, function(handler)
            handler.pause()
        end)
    end

    const function resume()
        forEach(tags, function(handler)
            handler.resume()
        end)
    end

    const function finish()
        forEach(tags, function(handler)
            handler.finish()
        end)
    end

    const function destroy()
        forEach(tags, function(handler)
            handler.destroy()
        end)
    end

    -- Without tags and without `once`, this sets the scale that every handler multiplies by, now and for handlers
    -- created later. Otherwise it calls the `scaleSpeed` of each handler in scope, so a handler created later is
    -- not affected by a scale without `once`.
    const function scaleSpeed(options: Types.ScaleSpeedOptions)
        const speed, once = SpeedScale.parse(options, name .. ".scaleSpeed")

        if tags == nil and not once then
            Scale.set(speed)

            return
        end

        forEach(tags, function(handler)
            handler.scaleSpeed({
                speed = speed,
                once = once,
            })
        end)
    end

    return table.freeze({
        scaleSpeed = scaleSpeed,
        pause = pause,
        resume = resume,
        finish = finish,
        destroy = destroy,
    })
end

-- Scopes the functions to the handlers whose rule has all of the tags.
const function withTags(...: string): Types.EveryHandlerGroup
    const tags = { ... }

    if #tags == 0 then
        error("every.handler.withTags requires at least one tag", 2)
    end

    for index, tag in tags do
        if type(tag) ~= "string" then
            error(`every.handler.withTags tag {index} must be a string, got {typeof(tag)}`, 2)
        end
    end

    return createGroup(tags, "every.handler.withTags")
end

const everyHandler = createGroup(nil, "every.handler")

return table.freeze({
    scaleSpeed = everyHandler.scaleSpeed,
    pause = everyHandler.pause,
    resume = everyHandler.resume,
    finish = everyHandler.finish,
    destroy = everyHandler.destroy,
    withTags = withTags,
})
