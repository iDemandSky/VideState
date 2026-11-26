const Lest = require("@Lest")
const Vide = require("@packages/Vide")
const VideState = require("@VideState")

local describe, it, expect = Lest.describe, Lest.it, Lest.expect

const function createHandler(name: string)
    return VideState.rule({
        opacity = VideState.float(),
    }, { name = name }).new({
        Idle = { opacity = Vide.source(0) },
        Hovered = { opacity = Vide.source(0.5) },
        Pressed = { opacity = Vide.source(1) },
        Disabled = { opacity = Vide.source(0.2) },
    }, "Idle")
end

-- Runs a function and returns the error message it raised, or an empty string.
const function messageOf(callback: () -> ()): string
    local ok, message = pcall(callback)

    if ok then
        return ""
    end

    return tostring(message)
end

describe("tween overrides", function()
    it("uses the override for the state change it matches and the default for the others", function()
        local handler = createHandler("OverrideMatchPanel")
        local lastAlpha = -1

        handler.onTransition(function(_, _, _, alpha)
            lastAlpha = alpha
        end, {
            tweenDefault = {
                duration = 5,
            },
            tweenOverrides = {
                {
                    from = {
                        "Idle",
                    },
                    to = {
                        "Hovered",
                    },
                    tween = {
                        duration = 0,
                    },
                },
            },
        })

        handler.setState("Hovered")

        expect(lastAlpha).toBe(1)

        handler.setState("Pressed")

        expect(lastAlpha < 1).toBe(true)
    end)

    it("matches every state in a list, and every state when a side is left out", function()
        local handler = createHandler("OverrideListPanel")
        local lastAlpha = -1

        handler.onTransition(function(_, _, _, alpha)
            lastAlpha = alpha
        end, {
            tweenDefault = {
                duration = 5,
            },
            tweenOverrides = {
                {
                    from = {
                        "Idle",
                        "Hovered",
                    },
                    to = {
                        "Pressed",
                    },
                    tween = {
                        duration = 0,
                    },
                },
                {
                    to = {
                        "Disabled",
                    },
                    tween = {
                        duration = 0,
                    },
                },
            },
        })

        handler.setState("Hovered")

        expect(lastAlpha < 1).toBe(true)

        handler.setState("Pressed")

        expect(lastAlpha).toBe(1)

        handler.setState("Disabled")

        expect(lastAlpha).toBe(1)

        handler.setState("Idle")

        expect(lastAlpha < 1).toBe(true)
    end)

    it("keeps the settings of tweenDefault that an override leaves out", function()
        local handler = createHandler("OverrideInheritPanel")
        local lastAlpha = -1

        handler.onTransition(function(_, _, _, alpha)
            lastAlpha = alpha
        end, {
            tweenDefault = {
                duration = 3,
            },
            tweenOverrides = {
                {
                    to = {
                        "Hovered",
                    },
                    tween = {
                        easing = "linear",
                    },
                },
            },
        })

        handler.setState("Hovered")
        task.wait(0.3)

        expect(lastAlpha > 0 and lastAlpha < 1).toBe(true)
    end)

    it("works for animate and follows the speed of the connection", function()
        local handler = createHandler("OverrideAnimatePanel")
        local animated = handler.animate({
            tweenOverrides = {
                {
                    from = {
                        "Idle",
                    },
                    to = {
                        "Hovered",
                    },
                    tween = {
                        duration = 3,
                    },
                },
            },
        })

        handler.setState("Hovered")
        handler.scaleSpeed({
            speed = 100,
        })
        task.wait(0.2)

        expect(animated.opacity()).toBe(0.5)
    end)

    it("picks the override for the state the handler was heading to when a transition is interrupted", function()
        local handler = createHandler("OverrideInterruptPanel")
        local animated = handler.animate({
            tweenDefault = {
                duration = 3,
            },
            tweenOverrides = {
                {
                    from = {
                        "Hovered",
                    },
                    to = {
                        "Pressed",
                    },
                    tween = {
                        duration = 0,
                    },
                },
            },
        })

        handler.setState("Hovered")
        task.wait(0.2)

        local reached = animated.opacity()

        expect(reached > 0 and reached < 0.5).toBe(true)

        handler.setState("Pressed")

        expect(animated.opacity()).toBe(1)
    end)

    it("reports every problem in one error", function()
        local handler = createHandler("OverrideErrorPanel")

        local message = messageOf(function()
            handler.onTransition(function() end, {
                tweenOverrides = {
                    {
                        from = {
                            "Idle",
                            "Hovered",
                        },
                        to = {
                            "Pressed",
                        },
                        tween = {
                            duration = 1,
                        },
                    },
                    {
                        from = {
                            "Hovered",
                        },
                        to = {
                            "Pressed",
                            "Disabled",
                        },
                        tween = {
                            duration = 1,
                        },
                    },
                    {
                        from = {
                            "Nowhere",
                        },
                        to = {
                            "Idle",
                        },
                        tween = {
                            duration = 1,
                        },
                    },
                    {
                        from = {},
                        to = {
                            "Idle",
                        },
                        tween = {
                            duration = 1,
                        },
                    },
                    {
                        tween = {
                            duration = 1,
                        },
                    },
                    {
                        from = {
                            "Idle",
                        },
                        to = {
                            "Idle",
                        },
                        tween = {
                            duration = 1,
                        },
                    },
                    {
                        to = {
                            "Disabled",
                        },
                    },
                    {
                        to = {
                            "Disabled",
                        },
                        tween = {
                            duration = -1,
                        },
                    },
                    {
                        to = {
                            "Disabled",
                        },
                        tween = {
                            duration = 1,
                        },
                        extra = true,
                    },
                } :: any,
            })
        end)

        expect(message ~= "").toBe(true)
        expect(string.find(message, "tweenOverrides has", 1, true) ~= nil).toBe(true)
        expect(string.find(message, "entries 1 and 2 both match Hovered to Pressed", 1, true) ~= nil).toBe(true)
        expect(string.find(message, 'entry 3 from has an unknown state "Nowhere"', 1, true) ~= nil).toBe(true)
        expect(string.find(message, "entry 4 from is empty, so it matches nothing", 1, true) ~= nil).toBe(true)
        expect(string.find(message, "entry 5 leaves out both from and to", 1, true) ~= nil).toBe(true)
        expect(string.find(message, "entry 6 only matches Idle to Idle", 1, true) ~= nil).toBe(true)
        expect(string.find(message, "entry 7 needs a tween table", 1, true) ~= nil).toBe(true)
        expect(string.find(message, "entry 8: onTransition duration must be a finite non-negative number", 1, true) ~= nil).toBe(true)
        expect(string.find(message, "entry 9 has an unknown key extra", 1, true) ~= nil).toBe(true)
    end)

    it("rejects overrides that are not an array", function()
        local handler = createHandler("OverrideArrayPanel")

        expect(function()
            handler.onTransition(function() end, {
                tweenOverrides = {
                    Idle = "Hovered",
                } :: any,
            })
        end).toThrow("onTransition tweenOverrides must be an array")

        expect(function()
            handler.onTransition(function() end, {
                tweenOverrides = {
                    "Idle",
                } :: any,
            })
        end).toThrow("entry 1 must be a table")
    end)

    it("does not change a connection that has no overrides", function()
        local handler = createHandler("OverrideNonePanel")
        local lastAlpha = -1

        handler.onTransition(function(_, _, _, alpha)
            lastAlpha = alpha
        end, {
            tweenDefault = {
                duration = 5,
            },
            tweenOverrides = {},
        })

        handler.setState("Hovered")

        expect(lastAlpha < 1).toBe(true)
    end)
end)
