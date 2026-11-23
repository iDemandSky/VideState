const Run = require("@VideState/Handler/OnTransition/Playback/Run")

type Run<T> = Run.Run<T>

-- A source that returns something other than a finite non-negative number plays at normal speed.
const function readSpeed<T>(run: Run<T>): number
    local source = run.speed
    if source == nil then
        return 1
    end
    local value = source()
    if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
        return 1
    end
    return value
end

-- Fires every run once at the start, then steps the runs with a duration every frame until they finish.
-- Stops as soon as `isStale` reports that a newer transition replaced this one.
return function <T>(runs: { Run<T> }, fire: (run: Run<T>, deltaTime: number) -> (), isStale: () -> boolean)
    for _, run in runs do
        fire(run, 0)
    end
    if isStale() then
        return
    end

    local pending: { Run<T> } = {}
    for _, run in runs do
        if run.duration > 0 then
            table.insert(pending, run)
        end
    end
    if #pending == 0 then
        return
    end

    task.spawn(function()
        while #pending > 0 do
            local deltaTime = task.wait()
            if isStale() then
                return
            end

            local stillRunning: { Run<T> } = {}
            for _, run in pending do
                local scaled = deltaTime * readSpeed(run)
                run.elapsed += scaled
                fire(run, scaled)
                if run.elapsed < run.duration then
                    table.insert(stillRunning, run)
                end
            end
            pending = stillRunning
        end
    end)
end
