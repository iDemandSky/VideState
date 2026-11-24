const Types = require("../Types")

type Disconnect = Types.Disconnect

export type StateEvents = {
    -- Listens for the handler entering one state.
    read onEnter: (stateName: string, callback: Types.OnEnterCallback) -> Disconnect,
    -- Listens for the handler leaving one state.
    read onExit: (stateName: string, callback: Types.OnExitCallback) -> Disconnect,
    -- Runs the exit listeners of the previous state, then the enter listeners of the next one. `setState` calls it.
    read emit: (previousState: string, nextState: string) -> (),
    -- Removes every listener. `destroy` calls it.
    read clear: () -> (),
}

type Listeners = { [string]: { [number]: (stateName: string) -> () } }

-- Runs every listener of one state, with the name of the other state. A listener that disconnects another one
-- during the call stops it from running.
const function run(listeners: Listeners, stateName: string, otherState: string)
    local stateListeners = listeners[stateName]

    if stateListeners == nil then
        return
    end

    local ids: { number } = {}

    for id in stateListeners do
        table.insert(ids, id)
    end

    table.sort(ids)

    for _, id in ids do
        local listener = stateListeners[id]

        if listener ~= nil then
            listener(otherState)
        end
    end
end

-- The `onEnter` and `onExit` events of a handler. `isState` reports whether a name is one of the handler's states.
return function(isState: (stateName: string) -> boolean): StateEvents
    local enterListeners: Listeners = {}
    local exitListeners: Listeners = {}
    local nextId = 0

    -- The error level of 3 points at the user's call to `onEnter` or `onExit`.
    const function connect(
        name: string,
        listeners: Listeners,
        stateName: string,
        callback: (stateName: string) -> ()
    ): Disconnect
        if type(stateName) ~= "string" then
            error(`{name} state name must be a string, got {typeof(stateName)}`, 3)
        end

        if not isState(stateName) then
            error(`{name} state "{stateName}" is not a state of this handler`, 3)
        end

        if typeof(callback) ~= "function" then
            error(`{name} callback must be a function`, 3)
        end

        nextId += 1

        local id = nextId
        local stateListeners = listeners[stateName]

        if stateListeners == nil then
            stateListeners = {}
            listeners[stateName] = stateListeners
        end

        stateListeners[id] = callback

        return function()
            stateListeners[id] = nil
        end
    end

    local events: StateEvents = {
        onEnter = function(stateName: string, callback: Types.OnEnterCallback): Disconnect
            return connect("onEnter", enterListeners, stateName, callback)
        end,
        onExit = function(stateName: string, callback: Types.OnExitCallback): Disconnect
            return connect("onExit", exitListeners, stateName, callback)
        end,
        emit = function(previousState: string, nextState: string)
            run(exitListeners, previousState, nextState)
            run(enterListeners, nextState, previousState)
        end,
        clear = function()
            table.clear(enterListeners)
            table.clear(exitListeners)
        end,
    }

    return table.freeze(events)
end
