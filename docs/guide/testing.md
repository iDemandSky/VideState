---
title: Testing
description: Step transitions by hand with the manual clock, so a test checks the values at exact times.
outline: [2, 3]
---

# Testing <Badge type="tip" text="Added in 0.5.0" />

Transitions move with real frames, and frames are never the same length twice. A test that waits with `task.wait`
sees slightly different values on every run. The manual clock fixes that: transitions only move when the test says so,
by an exact amount of time.

```luau
VideState.setManualClock(true)

handler.onTransition(function(_, _, current)
    lastOpacity = current.opacity
end, {
    tweenDefault = {
        duration = 1,
    },
})

handler.setState("Active")      -- the first frame: opacity is 0
VideState.advanceClock(0.25)    -- opacity is 0.25
VideState.advanceClock(0.75)    -- opacity is 1, and onFinish runs

VideState.setManualClock(false)
```

- While the manual clock is on, real frames do not move any transition. Each `advanceClock` call steps every running
  transition of every handler once, as one frame of that length.
- The time is scaled like a real frame, so [`pause`](/guide/handlers#pause), a `speed` source, and
  [`scaleSpeed`](/guide/handlers#scalespeed) still apply, and so do delays.
- `setState`, `finish`, and an instant change work as usual. `setState` still sends its first frame at once.
- Turning the clock off hands the running transitions back to real frames, from where they are.
- The clock is shared by every handler. Turn it off at the end of each test, so the next test runs with real frames.

## setManualClock

```luau
VideState.setManualClock(enabled: boolean) -> ()
```

Turns the manual clock on or off. It is off by default.

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `enabled` is not a boolean | `setManualClock expects a boolean, got <type>` |

## isManualClock

```luau
VideState.isManualClock() -> boolean
```

Returns whether the manual clock is on.

## advanceClock

```luau
VideState.advanceClock(seconds: number) -> ()
```

Steps every running transition by `seconds`, as one frame, before it returns. Listeners, `animate` and `progress`
sources, and [`onFinish`](/guide/handlers#onfinish) run during the call.

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | The manual clock is off | `advanceClock needs the manual clock. Call setManualClock(true) first` |
| <Badge type="danger" text="Error" /> | `seconds` is not a finite non-negative number | `advanceClock expects a finite non-negative number of seconds` |
