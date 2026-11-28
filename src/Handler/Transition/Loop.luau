const insert = table.insert

-- One running tween. `step` advances it by one frame and returns whether it keeps running.
export type Job = {
    step: (deltaTime: number) -> boolean,
    stop: () -> (),
}

-- Every running tween of every handler, stepped by one shared loop. A job added during a frame starts on the
-- next one.
local jobs: { Job } = {}
local isLooping = false
-- With the manual clock, the loop does not run, and `advance` steps the jobs instead. Tests use it to check values at
-- exact times.
local isManual = false

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

-- Steps every job once. A job added while they are stepped waits for the next step.
const function stepAll(deltaTime: number)
    local current = jobs

    jobs = {}

    for _, job in current do
        local keepsRunning = stepJob(job, deltaTime)

        if keepsRunning then
            insert(jobs, job)
        end
    end
end

-- Runs while any job is left, then stops until the next job is added. It also stops when the manual clock is turned
-- on while it waits for a frame.
const function loop()
    while #jobs > 0 do
        local deltaTime = task.wait()

        if isManual then
            break
        end

        stepAll(deltaTime)
    end

    isLooping = false
end

const function startLoop()
    local hasJobs = #jobs > 0
    local canStart = hasJobs and not isLooping and not isManual

    if not canStart then
        return
    end

    isLooping = true
    task.spawn(loop)
end

const function add(job: Job)
    insert(jobs, job)
    startLoop()
end

const function setManual(enabled: boolean)
    isManual = enabled
    startLoop()
end

const function getManual(): boolean
    return isManual
end

-- Steps every running tween by `seconds`, as one frame. Only with the manual clock.
const function advance(seconds: number)
    stepAll(seconds)
end

return table.freeze({
    add = add,
    setManual = setManual,
    getManual = getManual,
    advance = advance,
})
