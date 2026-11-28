const Loop = require("./Handler/Transition/Loop")

-- The clock of every transition. Tests turn on the manual clock and step it, so a transition reaches the same values
-- on every run.
const function setManualClock(enabled: boolean)
    if type(enabled) ~= "boolean" then
        error(`setManualClock expects a boolean, got {typeof(enabled)}`, 2)
    end

    Loop.setManual(enabled)
end

const function isManualClock(): boolean
    return Loop.getManual()
end

-- Steps every running transition by `seconds`, as one frame. The time is scaled like a real frame, so pause and the
-- speed still apply.
const function advanceClock(seconds: number)
    if not Loop.getManual() then
        error("advanceClock needs the manual clock. Call setManualClock(true) first", 2)
    end

    if type(seconds) ~= "number" then
        error("advanceClock expects a finite non-negative number of seconds", 2)
    end

    local isNotNaN = seconds == seconds
    local isNotNegative = seconds >= 0
    local isNotInfinite = seconds ~= math.huge
    local isValid = isNotNaN and isNotNegative and isNotInfinite

    if not isValid then
        error("advanceClock expects a finite non-negative number of seconds", 2)
    end

    Loop.advance(seconds)
end

return table.freeze({
    setManualClock = setManualClock,
    isManualClock = isManualClock,
    advanceClock = advanceClock,
})
