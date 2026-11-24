const Options = require("./Config/Options")
const Group = require("./Tween/Group")

-- One running tween. `step` advances it by one frame and returns whether it keeps running.
type Job = {
    step: (deltaTime: number) -> boolean,
    stop: () -> (),
}

-- Every running tween of every handler, stepped by one shared loop. A job added during a frame starts on the
-- next one.
local jobs: { Job } = {}
local isLooping = false

-- Steps one job. A listener that raises an error ends only its own job, and the error is still reported.
const function stepJob(job: Job, deltaTime: number): boolean
    local ok, result = pcall(job.step, deltaTime)

    if ok then
        return result
    end

    job.stop()
    task.spawn(error, result, 0)

    return false
end

-- Runs while any job is left, then stops until the next job is added.
const function loop()
    while #jobs > 0 do
        local deltaTime = task.wait()
        local current = jobs

        jobs = {}

        for _, job in current do
            local keepsRunning = stepJob(job, deltaTime)

            if keepsRunning then
                table.insert(jobs, job)
            end
        end
    end

    isLooping = false
end

const function add(job: Job)
    table.insert(jobs, job)

    if isLooping then
        return
    end

    isLooping = true
    task.spawn(loop)
end

-- Calls `emit` with the first frame at once, then steps the group on the shared loop until it is done.
-- `emit` returns how many listeners are still connected, and the tween stops when none are.
-- Stops silently as soon as `isStale` reports that a newer transition replaced this one, or that it was ended.
-- `getRate` scales the time that passes: 0 holds the group, and the first frame is still sent.
-- `onEnd` is called once when the tween ends on its own, with true if the group reached its end.
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

    add({
        step = function(deltaTime: number): boolean
            if isStale() then
                return false
            end

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
        end,
        -- A listener raised an error. The tween ends without reaching its end.
        stop = function()
            if not isStale() then
                onEnd(false)
            end
        end,
    })
end
