const Options = require("./Config/Options")
const Group = require("./Tween/Group")

-- Calls `emit` with the first frame, then steps the group every frame until it is done.
-- `emit` returns how many listeners are still connected, and the loop stops when none are.
-- Stops silently as soon as `isStale` reports that a newer transition replaced this one, or that it was ended.
-- `getRate` scales the time that passes: 0 holds the group, and the first frame is still sent.
-- `onEnd` is called once when the loop ends on its own, with true if the group reached its end.
return function <T>(
    group: Group.Group<T>,
    settings: Options.Settings,
    getRate: () -> number,
    emit: (current: T, alpha: number) -> number,
    isStale: () -> boolean,
    onEnd: (completed: boolean) -> ()
)
    local current, alpha = Group.step(group, 0)
    local remaining = emit(current, alpha)

    if isStale() then
        return
    end

    if remaining == 0 then
        onEnd(false)

        return
    end

    if Group.isDone(group) then
        onEnd(true)

        return
    end

    task.spawn(function()
        while not Group.isDone(group) do
            local deltaTime = task.wait()

            if isStale() then
                return
            end

            local scaledDelta = deltaTime * settings.getSpeed() * getRate()

            -- A paused transition keeps its values, so the listeners are not called again.
            if scaledDelta > 0 then
                Group.configure(group, settings.getEasing(), settings.getDuration())

                local frameCurrent, frameAlpha = Group.step(group, scaledDelta)

                if emit(frameCurrent, frameAlpha) == 0 then
                    onEnd(false)

                    return
                end
            end
        end

        if not isStale() then
            onEnd(true)
        end
    end)
end
