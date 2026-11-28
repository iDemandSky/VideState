const Vide = require("../../packages/roblox/Vide")

const Types = require("../Types")

-- The `progress` function of a handler: `onTransition` with one Vide source for the alpha, so a progress bar or a ring
-- can bind to it directly. The source starts at 1, because no transition is running, and follows the alpha of one
-- `onTransition` connection, which takes the same options.
return function <T>(onTransition: Types.ConnectTransition<T>): Types.Progress<T>
    return function(options: Types.TransitionOptions?): (Types.Source<number>, Types.Disconnect)
        const progress = Vide.source(1)

        const disconnect = onTransition(function(_from, _to, _current, alpha)
            progress(alpha)
        end, options)

        return progress, disconnect
    end
end
