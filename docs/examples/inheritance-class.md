---
title: Inheritance
description: Use a VideState handler inside a class, then override methods in a subclass.
---

# Inheritance

A handler is a plain field on an object, so classes can own one and subclasses can reuse it. This example uses a `Toast` class and an `ErrorToast` subclass that overrides `show`.

```luau
const Players = game:GetService("Players")
-- Point @Vide at the Vide package in your project.
const Vide = require("@Vide")
const VideState = require("@VideState")

const ToastRule = VideState.rule({
    visible = VideState.boolean(),
    message = VideState.string({ maxLength = 120 }),
}, {
    name = "Toast",
    allowedStateNames = { "Hidden", "Shown" },
})

local Toast = {}
Toast.__index = Toast

function Toast.new(message: string)
    local self = setmetatable({}, Toast)

    self.handler = ToastRule.new({
        Hidden = { visible = Vide.source(false), message = Vide.source(message) },
        Shown = { visible = Vide.source(true), message = Vide.source(message) },
    }, "Hidden")

    return self
end

function Toast:show()
    self.handler.setState("Shown")
end

function Toast:hide()
    self.handler.setState("Hidden")
end

-- ErrorToast inherits the handler and state methods from Toast, and adds its own behavior.
local ErrorToast = setmetatable({}, { __index = Toast })
ErrorToast.__index = ErrorToast

function ErrorToast.new(message: string)
    local self = Toast.new("Error: " .. message)
    return setmetatable(self, ErrorToast)
end

function ErrorToast:show()
    Toast.show(self)
    task.delay(3, function()
        self:hide()
    end)
end

const player = Players.LocalPlayer
local toast = ErrorToast.new("Could not save settings")

Vide.mount(function()
    return Vide.create "ScreenGui" {
        Name = "InheritanceClass",
        ResetOnSpawn = false,
        [1] = Vide.create "TextLabel" {
            Size = UDim2.fromOffset(360, 40),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0.1),
            Visible = toast.handler.sources.visible,
            Text = toast.handler.sources.message,
        },
    }
end, player:WaitForChild("PlayerGui"))

toast:show()
```

## What to notice

- `ErrorToast` gets `hide` and the handler from `Toast` through the metatable chain.
- `ErrorToast:show` calls `Toast.show(self)` first, so the state change is shared with the base class. It then schedules a hide after three seconds.
- The label binds to `toast.handler.sources`, so it updates when the subclass changes state.
