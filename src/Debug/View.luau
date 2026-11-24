const Vide = require("../../packages/roblox/Vide")
const Types = require("../Types")

const create = Vide.create
const source = Vide.source
const indexes = Vide.indexes
const cleanup = Vide.cleanup

-- How often the view reads the tracked handlers, in seconds.
const REFRESH_INTERVAL = 0.1
const ROW_HEIGHT = 20
const TEXT_SIZE = 14

-- One line of text for a handler, such as `Panel  Active  running 0.42 s  2 connections`.
const function describe(snapshot: Types.DebugSnapshot): string
    local status: string

    if snapshot.isPaused then
        status = "paused"
    elseif snapshot.isRunning then
        local startedAt = snapshot.startedAt or os.clock()

        status = string.format("running %.2f s", os.clock() - startedAt)
    else
        status = "idle"
    end

    local connectionWord = if snapshot.connections == 1 then "connection" else "connections"

    return string.format(
        "%s  %s  %s  %d %s",
        snapshot.label,
        snapshot.state,
        status,
        snapshot.connections,
        connectionWord
    )
end

-- Creates the debug view: a list of the tracked handlers that refreshes while it exists. Call it inside a Vide
-- scope, such as `Vide.mount` or a UI Labs story, so its refresh loop stops with the scope.
return function(list: () -> { Types.DebugSnapshot }): () -> Frame
    return function(): Frame
        local rows = source(list())
        local running = true

        task.spawn(function()
            while running do
                task.wait(REFRESH_INTERVAL)

                if running then
                    rows(list())
                end
            end
        end)

        cleanup(function()
            running = false
        end)

        -- The children are parented one by one, because a Vide table that mixes properties and children is
        -- flagged by the linter.
        local frame = create("Frame")({
            Name = "VideStateDebug",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(24, 24, 28),
        })

        create("UIListLayout")({
            Parent = frame,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        })

        create("TextLabel")({
            Parent = frame,
            Name = "Empty",
            LayoutOrder = 0,
            Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
            BackgroundTransparency = 1,
            Font = Enum.Font.Code,
            TextSize = TEXT_SIZE,
            TextColor3 = Color3.fromRGB(150, 150, 160),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "No tracked handlers. Call VideState.debug.track(handler).",
            Visible = function(): boolean
                return #rows() == 0
            end,
        })

        -- One label per tracked handler. A row that goes away destroys its label.
        indexes(rows, function(snapshot: () -> Types.DebugSnapshot, index: number): TextLabel
            local label = create("TextLabel")({
                Parent = frame,
                Name = "Row",
                LayoutOrder = index,
                Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
                BackgroundTransparency = 1,
                Font = Enum.Font.Code,
                TextSize = TEXT_SIZE,
                TextColor3 = Color3.fromRGB(230, 230, 235),
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = function(): string
                    return describe(snapshot())
                end,
            })

            cleanup(function()
                label:Destroy()
            end)

            return label
        end)

        return frame
    end
end
