const Options = require("./Config/Options")
const Group = require("./Tween/Group")
const Loop = require("./Loop")

-- Sends the first frame, then steps the group on the shared loop until it is done. With a delay, the first frame
-- waits until that much scaled time has passed; without one, it is sent at once.
-- `emit` returns how many listeners are still connected, and the tween stops when none are.
-- Stops silently as soon as `isStale` reports that a newer transition replaced this one, or that it was ended.
-- `getRate` scales the time that passes: 0 holds the group, and the first frame is still sent.
-- `onEnd` is called once when the tween ends on its own, with true if the group reached its end.
return function <T>(
    group: Group.Group<T>,
    settings: Options.Settings,
    delay: number,
    getRate: () -> number,
    emit: (current: T, alpha: number) -> number,
    isStale: () -> boolean,
    onEnd: (completed: boolean) -> ()
)
    -- Sends the first frame and returns whether the group still has frames to play.
    const function start(): boolean
        local current, alpha = Group.step(group, 0)
        local remaining = emit(current, alpha)

        if isStale() then
            return false
        end

        if remaining == 0 then
            onEnd(false)

            return false
        end

        if Group.isDone(group) then
            onEnd(true)

            return false
        end

        return true
    end

    -- Plays one frame and returns whether the group still has frames to play.
    const function advance(deltaTime: number): boolean
        local scaledDelta = deltaTime * settings.getSpeed() * getRate()

        -- A paused transition keeps its values, so the listeners are not called again.
        if scaledDelta > 0 then
            Group.configure(group, settings.getEasing(), settings.getDuration())

            local frameCurrent, frameAlpha = Group.step(group, scaledDelta)

            if emit(frameCurrent, frameAlpha) == 0 then
                onEnd(false)

                return false
            end
        end

        if not Group.isDone(group) then
            return true
        end

        if not isStale() then
            onEnd(true)
        end

        return false
    end

    local hasDelay = delay > 0
    local started = not hasDelay
    local waited = 0

    if started then
        local hasFrames = start()

        if not hasFrames then
            return
        end
    end

    Loop.add({
        step = function(deltaTime: number): boolean
            if isStale() then
                return false
            end

            if started then
                return advance(deltaTime)
            end

            -- The delay counts scaled time, so a pause or a speed of 0 holds it as well.
            waited += deltaTime * settings.getSpeed() * getRate()

            if waited < delay then
                return true
            end

            started = true

            return start()
        end,
        -- A listener raised an error. The tween ends without reaching its end.
        stop = function()
            if not isStale() then
                onEnd(false)
            end
        end,
    })
end
