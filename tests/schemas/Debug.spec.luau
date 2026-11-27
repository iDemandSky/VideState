const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

-- A long transition, so a test can see it while it is still running.
const SLOW = {
    tweenDefault = {
        duration = 3,
    },
}

const function createPanel(name: string)
    return VideState.rule({
        opacity = VideState.float(),
    }, { name = name }).new({
        Idle = { opacity = Vide.source(0) },
        Active = { opacity = Vide.source(1) },
    }, "Idle")
end

-- The snapshot listed under `label`, or nil.
const function find(label: string): VideState.DebugSnapshot?
    for _, snapshot in VideState.debug.list() do
        if snapshot.label == label then
            return snapshot
        end
    end

    return nil
end

describe("debug tools", function()
    it("lists tracked handlers with their state and transitions", function()
        local handler = createPanel("DebugListPanel")

        -- A handler is not listed until it is tracked.
        expect(find("DebugListPanel")).toBe(nil)

        local untrack = VideState.debug.track(handler)
        local idle = find("DebugListPanel")

        expect(idle ~= nil).toBe(true)

        if idle == nil then
            return
        end

        expect(idle.rule).toBe("DebugListPanel")
        expect(idle.state).toBe("Idle")
        expect(idle.connections).toBe(0)
        expect(idle.isRunning).toBe(false)
        expect(idle.startedAt).toBe(nil)

        handler.onTransition(function() end, SLOW)
        handler.setState("Active")
        handler.pause()

        local running = VideState.debug.snapshot(handler)

        expect(running.state).toBe("Active")
        expect(running.connections).toBe(1)
        expect(running.isRunning).toBe(true)
        expect(running.isPaused).toBe(true)
        expect(running.startedAt ~= nil).toBe(true)

        -- Tracking again changes the label.
        VideState.debug.track(handler, "Main panel")

        expect(find("DebugListPanel")).toBe(nil)
        expect(find("Main panel") ~= nil).toBe(true)

        untrack()

        expect(find("Main panel")).toBe(nil)

        -- A destroyed handler is removed from the list.
        VideState.debug.track(handler)
        handler.destroy()

        expect(find("DebugListPanel")).toBe(nil)
        expect(VideState.debug.snapshot(handler).isDestroyed).toBe(true)

        expect(function()
            VideState.debug.snapshot({} :: any)
        end).toThrow("debug.snapshot expects a handler")

        expect(function()
            VideState.debug.track(createPanel("DebugLabelPanel"), 1 :: any)
        end).toThrow("debug.track label must be a string")
    end)

    it("shows the tracked handlers in the debug view", function()
        local handler = createPanel("DebugViewPanel")
        local untrack = VideState.debug.track(handler, "View panel")

        local destroyView, frame = Vide.root(function()
            return VideState.debug.view()
        end)

        expect(frame.ClassName).toBe("Frame")

        handler.onTransition(function() end, SLOW)
        handler.setState("Active")
        task.wait(0.3)

        local rowText: string? = nil

        for _, child in frame:GetChildren() do
            local isRow = child.Name == "Row" and child:IsA("TextLabel")

            if isRow and string.find((child :: TextLabel).Text, "View panel", 1, true) then
                rowText = (child :: TextLabel).Text
            end
        end

        expect(rowText ~= nil).toBe(true)

        if rowText ~= nil then
            local showsState = string.find(rowText, "Active", 1, true) ~= nil
            local showsRunning = string.find(rowText, "running", 1, true) ~= nil

            expect(showsState).toBe(true)
            expect(showsRunning).toBe(true)
        end

        destroyView()
        untrack()
        handler.destroy()
    end)
end)
