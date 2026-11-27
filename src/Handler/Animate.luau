const Vide = require("../../packages/roblox/Vide")

const Types = require("../Types")

-- The `animate` function of a handler: `onTransition` with a Vide source for every field, so a property can
-- be bound to the animated value directly. The sources start at the current state's values and follow the
-- tween of one `onTransition` connection, which takes the same options.
return function <T>(onTransition: Types.ConnectTransition<T>, sources: Types.Sources<T>): Types.Animate<T>
    return function(options: Types.TransitionOptions?): (Types.Sources<T>, Types.Disconnect)
        const animated: { [string]: (...unknown) -> unknown } = {}

        for fieldName, source in sources :: { [string]: () -> unknown } do
            animated[fieldName] = Vide.source(source()) :: any
        end

        const disconnect = onTransition(function(_from, _to, current)
            const values = current :: { [string]: unknown }

            -- One batch, so a binding that reads several fields runs once per frame.
            Vide.batch(function()
                for fieldName, write in animated do
                    write(values[fieldName])
                end
            end)
        end, options)

        return table.freeze(animated) :: any, disconnect
    end
end
