type Callback<Args...> = (Args...) -> ()


return function <Listener>(name)
    local container = {
        name = name,
        count = 1,
        listeners = {} :: { Listener }
    }

    function container.addListener(listener: Listener): number
        if typeof(listener) ~= "function" then
            error("listener must be a function", 3)
        end

        local id = container.count

        container.count += 1
        container.listeners[id] = listener

        return id
    end

    function container.removeListener(id: number)
        container.listeners[id] = nil
    end

    function container.emit<Args...>(...: Args...)
        local snapshot: { { id: number, listener: Listener } } = {}

        for id, listener in container.listeners do
            table.insert(snapshot, {
                id = id,
                listener = listener,
            })
        end

        for _, entry in snapshot do
            if container.listeners[entry.id] == entry.listener then
                local callback = entry.listener :: Callback<Args...>
                callback(...)
            end
        end
    end

    return container
end
