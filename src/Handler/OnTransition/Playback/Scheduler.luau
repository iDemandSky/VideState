const Options = require("../Config/Options")
const Group = require("../Tween/Group")

-- Calls `emit` with the first frame, then steps the group every frame until it is done.
-- `emit` returns how many listeners are still connected, and the loop stops when none are.
-- Stops as soon as `isStale` reports that a newer transition replaced this one.
return function <T>(
    group: Group.Group<T>,
    settings: Options.Settings,
    emit: (current: T, alpha: number) -> number,
    isStale: () -> boolean
)
    local current, alpha = Group.step(group, 0)
    local remaining = emit(current, alpha)

    if isStale() or remaining == 0 or Group.isDone(group) then
        return
    end

    task.spawn(function()
        while not Group.isDone(group) do
            local deltaTime = task.wait()

            if isStale() then
                return
            end

            local scaledDelta = deltaTime * settings.getSpeed()

            -- A paused transition keeps its values, so the listeners are not called again.
            if scaledDelta > 0 then
                Group.configure(group, settings.getEasing(), settings.getDuration())

                local frameCurrent, frameAlpha = Group.step(group, scaledDelta)

                if emit(frameCurrent, frameAlpha) == 0 then
                    return
                end
            end
        end
    end)
end
