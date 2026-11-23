---
title: Form validation
description: Reject invalid input with a string schema and show the result in the UI.
---

# Form validation

A username box stores its text through a `string` schema with `maxLength = 12`. Writing a value that fails the schema throws, so the example catches the error and shows a message.

```luau
const Players = game:GetService("Players")
-- Point @Vide at the Vide package in your project.
const Vide = require("@Vide")
const VideState = require("@VideState")

const UsernameRule = VideState.rule({
    username = VideState.string({ maxLength = 12 }),
    status = VideState.string(),
}, {
    name = "UsernameField",
    description = "A text field that only stores usernames passing the string schema",
    tags = { "ui", "form" },
})

const field = UsernameRule.new({
    Editing = {
        username = Vide.source(""),
        status = Vide.source("Enter a username of up to 12 characters"),
    },
}, "Editing")

-- Writing an invalid value throws, so the write is wrapped in pcall to turn it into a message.
const function submit(text: string)
    local accepted = pcall(field.sources.username, text)
    if accepted then
        field.sources.status("Saved as " .. field.sources.username())
    else
        field.sources.status("Usernames can be at most 12 characters")
    end
end

const function createUsernameBox(): TextBox
    local box: TextBox
    box = Vide.create "TextBox" {
        Name = "UsernameInput",
        PlaceholderText = "Username",
        Size = UDim2.fromOffset(300, 40),
        Position = UDim2.fromOffset(20, 20),
        ClearTextOnFocus = false,
        FocusLost = function()
            submit(box.Text)
        end,
    } :: TextBox
    return box
end

const player = Players.LocalPlayer

Vide.mount(function()
    return Vide.create "ScreenGui" {
        Name = "FormValidation",
        ResetOnSpawn = false,
        [1] = createUsernameBox(),
        [2] = Vide.create "TextLabel" {
            Name = "Status",
            Size = UDim2.fromOffset(300, 30),
            Position = UDim2.fromOffset(20, 70),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = field.sources.status,
        },
    }
end, player:WaitForChild("PlayerGui"))
```

## What to notice

- A rejected write leaves the stored value as it was. The example doesn't rely on any rollback.
- `status` is a separate source, so the label updates from the same handler that does the validation.
