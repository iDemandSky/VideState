const Types = require("../Types")
const Options = require("@self/Config/Options")
const Group = require("@self/Tween/Group")
const Scheduler = require("@self/Playback/Scheduler")
const CreateEvent = require("@self/Playback/Event")
const CreatePause = require("@self/Playback/Pause")

type Callback<T> = Types.OnTransitionCallback<T>
type Disconnect = Types.Disconnect

-- One `setState` that has listeners. It is finished when every connection that was playing it has ended.
type Transition = {
    generation: number,
    pending: number,
    completed: boolean,
    fired: boolean,
}

-- What one connection plays for one transition. `ended` is set when it finishes, is finished early, or disconnects.
type Run<T> = {
    group: Group.Group<T>,
    from: T,
    to: T,
    ended: boolean,
    transition: Transition,
}

type Connection<T> = {
    callback: Callback<T>,
    settings: Options.Settings,
    -- The last run and the last value it sent. A new transition that starts before this run ends
    -- continues from that value instead of jumping back to the previous state.
    run: Run<T>?,
    current: T?,
}

-- The functions of a handler that control its running transitions.
export type Controls = {
    read pause: () -> (),
    read resume: () -> (),
    read onPause: (callback: Types.OnPauseCallback) -> Disconnect,
    read onResume: (callback: Types.OnResumeCallback) -> Disconnect,
    read fastForward: (options: Types.FastForwardOptions) -> (),
    read finish: () -> (),
    read onFinish: (callback: Types.OnFinishCallback) -> Disconnect,
}

-- Every connection tweens on its own, with its own settings. A setting the connection leaves out is read from
-- the handler options, which are the defaults for all of its connections.
return function <T>(
    options: Types.TransitionOptions?
): ((callback: Callback<T>, options: Types.TransitionOptions?) -> Disconnect, (from: T, to: T) -> (), Controls)
    local handlerSettings = Options.parse(options)

    local connections: { [number]: Connection<T> } = {}
    local nextId = 0
    local generation = 0
    local startedAt: number? = nil
    local currentTransition: Transition? = nil
    -- The scale that `fastForward` puts on the running transition. A new transition resets it.
    local scale = 1

    const function getStartedAt(): number
        return startedAt or os.clock()
    end

    local pause = CreatePause(getStartedAt)
    local onFinish, emitFinish = CreateEvent("onFinish")

    -- 0 holds every transition while the handler is paused.
    const function getRate(): number
        if pause.isPaused() then
            return 0
        end

        return scale
    end

    -- Counts one connection as ended. The finish event fires once, when the last one ends, if at least one
    -- of them reached its end and no newer transition replaced this one.
    const function settle(transition: Transition, completed: boolean)
        transition.pending -= 1

        if completed then
            transition.completed = true
        end

        local isLast = transition.pending == 0
        local isCurrent = transition.generation == generation
        local shouldFire = isLast and isCurrent and transition.completed and not transition.fired

        if shouldFire then
            transition.fired = true
            emitFinish(getStartedAt())
        end
    end

    const function onTransition(callback: Callback<T>, connectionOptions: Types.TransitionOptions?): Disconnect
        if typeof(callback) ~= "function" then
            error("onTransition callback must be a function", 2)
        end

        local settings = Options.parse(connectionOptions, handlerSettings)

        nextId += 1

        local id = nextId

        connections[id] = {
            callback = callback,
            settings = settings,
            run = nil,
            current = nil,
        }

        local connected = true

        return function()
            if not connected then
                return
            end

            connected = false

            local connection = connections[id]

            connections[id] = nil

            local run = if connection == nil then nil else connection.run

            if run ~= nil and not run.ended then
                run.ended = true
                settle(run.transition, false)
            end
        end
    end

    const function emit(from: T, to: T)
        generation += 1
        startedAt = os.clock()
        scale = 1

        local currentGeneration = generation

        -- A connection added during a transition receives updates from the next transition.
        local ids: { number } = {}

        for id in connections do
            table.insert(ids, id)
        end

        local transition: Transition = {
            generation = currentGeneration,
            pending = #ids,
            completed = false,
            fired = false,
        }

        currentTransition = transition

        for _, id in ids do
            local connection = connections[id]

            if connection == nil then
                settle(transition, false)

                continue
            end

            local previousRun = connection.run
            local previousCurrent = connection.current
            local isRunning = previousRun ~= nil and not previousRun.ended and not Group.isDone(previousRun.group)
            local isInterrupted = isRunning and previousCurrent ~= nil
            local start = if isInterrupted then previousCurrent :: T else from

            local group = Group.create(
                start,
                to,
                connection.settings.getEasing(),
                connection.settings.getDuration()
            )

            local run: Run<T> = {
                group = group,
                from = from,
                to = to,
                ended = false,
                transition = transition,
            }

            connection.run = run

            Scheduler(group, connection.settings, getRate, function(current: T, alpha: number): number
                -- A connection that was disconnected is no longer in the table, so its loop stops.
                if connections[id] ~= connection then
                    return 0
                end

                connection.current = current
                connection.callback(from, to, current, alpha)

                return 1
            end, function(): boolean
                return generation ~= currentGeneration or run.ended
            end, function(completed: boolean)
                run.ended = true
                settle(transition, completed)
            end)
        end
    end

    -- Sends the last frame to every connection that is still playing the current transition, and ends it.
    const function finish()
        local transition = currentTransition

        if transition == nil then
            return
        end

        local ids: { number } = {}

        for id, connection in connections do
            local run = connection.run

            if run ~= nil and run.transition == transition and not run.ended then
                table.insert(ids, id)
            end
        end

        for _, id in ids do
            local isReplaced = transition.generation ~= generation

            -- A callback can start a new transition, which replaces the one being finished.
            if isReplaced then
                break
            end

            local connection = connections[id]
            local run = if connection == nil then nil else connection.run

            if connection ~= nil and run ~= nil and run.transition == transition and not run.ended then
                run.ended = true
                connection.current = run.to
                connection.callback(run.from, run.to, run.to, 1)
                settle(transition, true)
            end
        end
    end

    const function fastForward(fastForwardOptions: Types.FastForwardOptions)
        scale = Options.parseFastForward(fastForwardOptions)
    end

    local controls: Controls = {
        pause = pause.pause,
        resume = pause.resume,
        onPause = pause.onPause,
        onResume = pause.onResume,
        fastForward = fastForward,
        finish = finish,
        onFinish = onFinish,
    }

    return onTransition, emit, table.freeze(controls)
end
