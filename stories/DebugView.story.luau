const HttpService = game:GetService("HttpService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Instance requires, because Larvae only processes `src/`, so a string alias here would not resolve in Studio.
const packages = ReplicatedStorage:WaitForChild("packages"):WaitForChild("roblox")
const UILabs = require(packages:WaitForChild("ui-labs"))
const Vide = require(packages:WaitForChild("Vide"))
const VideState = require(ReplicatedStorage:WaitForChild("VideState"))

-- How long each demo handler stays in a state before it switches, in seconds.
const SWITCH_INTERVAL = 1.5

-- Rule names must be unique, and a story can load more than once in the same session, so each load gets its own name.
const rule = VideState.rule({
    opacity = VideState.float(),
    size = VideState.udim2(),
}, {
    name = `DebugStoryPanel-{HttpService:GenerateGUID(false)}`,
})

-- One demo handler. `delay` makes its transitions start late, so the rows do not all change at once.
const function createDemo(duration: number, delay: number)
    local handler = rule.new({
        Idle = {
            opacity = Vide.source(0),
            size = Vide.source(UDim2.fromScale(0, 0)),
        },
        Active = {
            opacity = Vide.source(1),
            size = Vide.source(UDim2.fromScale(1, 1)),
        },
    }, "Idle", {
        onTransition = {
            duration = duration,
            delay = delay,
        },
    })

    handler.onTransition(function() end)

    return handler
end

return UILabs.CreateVideStory({
    vide = Vide,
    summary = "The VideState debug view, with three demo handlers that keep switching states.",
}, function()
    local demos = {
        {
            label = "Button",
            handler = createDemo(0.3, 0),
        },
        {
            label = "Panel",
            handler = createDemo(0.8, 0.2),
        },
        {
            label = "Toast",
            handler = createDemo(1.2, 0.4),
        },
    }

    for _, demo in demos do
        VideState.debug.track(demo.handler, demo.label)
    end

    local running = true

    task.spawn(function()
        while running do
            task.wait(SWITCH_INTERVAL)

            if not running then
                break
            end

            for _, demo in demos do
                local nextState = if demo.handler.currentState() == "Idle" then "Active" else "Idle"

                demo.handler.setState(nextState)
            end
        end
    end)

    Vide.cleanup(function()
        running = false

        for _, demo in demos do
            demo.handler.destroy()
        end
    end)

    return VideState.debug.view()
end)
