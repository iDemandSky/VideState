---
title: Transitions
description: Animate between states with onTransition and animate, tween settings for each connection, and alpha.
outline: [2, 3]
---

# Transitions

[`onChange`](/guide/handlers#onchange) runs once when the state changes. [`onTransition`](/guide/handlers#ontransition)
runs repeatedly with a `current` value that moves from the previous state to the next one, and an
`alpha` that shows the progress. This page covers how transitions behave and the settings that control them.

Every `onTransition` connection has its own tween, so each one can animate with its own settings.
Pass them as the second argument of [`onTransition`](/guide/handlers#ontransition), inside `tweenDefault`. A setting a
connection leaves out takes the built-in default. A handler has no tween options of its own, so the settings belong to
the connection that uses them.

```luau
handler.onTransition(fade, {
    tweenDefault = {
        duration = 0.2,
        easing = "quadOut",
    },
})

handler.onTransition(slide, {
    tweenDefault = {
        duration = 0.5,
        easing = "backOut",
    },
})
```

[`animate`](/guide/handlers#animate) is the same transition with Vide sources instead of a callback. It takes
the same options, so everything on this page applies to it too. Use `onTransition` when you want to run your
own code on each frame, and `animate` when you only need to bind the values to properties.

Connections with the same settings still start together and stay in step. Each connection costs its own
set of tweens, so connect only the listeners that need to animate.

::: warning Strings cannot be transitioned
Only numbers, vectors and the other [animatable types](#animatable-fields) are tweened. A `string`
field cannot be, so it does not change gradually. It switches to its next value at the **start** of the
transition, and the same is true for booleans, enums, and any other value that is not animatable. For
example, a label's text changes immediately while its transparency fades.

If you need a gradual effect on text, such as a typewriter reveal, build it yourself from `alpha`.
:::

## Behavior

- Each animatable field is tweened from its previous value to its next value.
- Fields that cannot be tweened, such as booleans, strings, and enums, switch to their next value at the start of the transition.
- A duration of `0` calls the callback once with `current` equal to the next value and an `alpha` of `1`.
- `setState(name, { instant = true })` does the same for one change, whatever the duration is. See [`setState`](/guide/handlers#setstate).
- Calling `setState` again before a transition finishes stops the earlier animation and starts a new one. The new one starts from the value the earlier animation had reached, so `current` does not jump. The `from` argument of the callback is still the previous state's values.
- No animation runs while there are no `onTransition` listeners, and a transition stops once every listener has disconnected.
- A listener added during a transition receives updates from the next transition.
- Every easing starts at the previous value and ends at the next one. `back` and `elastic` easings overshoot, so numeric values can go below the start or above the end. Clamp them in your callback if your UI needs a fixed range.

### Animatable fields

These types are tweened:

- Numbers and vectors, including `Vector2` and `Vector3`.
- `CFrame`, `Color3`, `UDim`, `UDim2`, and `Rect`.
- `NumberRange`. Its minimum and its maximum are tweened separately.
- `NumberSequence` and `ColorSequence`, keypoint by keypoint. Both values need the same number of keypoints.
- Tables whose values are numbers, vectors, or `Vector3`s with the same keys.

These are not tweened. They switch to their next value at the start of the transition:

- `string`, `boolean`, `enum`, and `optional` fields.
- A `NumberSequence` or `ColorSequence` whose keypoint count changes.
- Every other type.

A few things to know:

- An easing that overshoots, such as `back`, can push the minimum of a `NumberRange` above its maximum. The range is
  clamped to keep the minimum at or below the maximum.
- A sequence keeps its first keypoint at time `0` and its last at `1`, and its other times stay in order.
- `current` is not validated against the schema again. A tweened `integer` field can hold a fractional value in the
  middle of a transition, so round it in your callback if you need a whole number.

## alpha

`alpha` is the progress of the transition, from `0` at the start to `1` at the end. It follows the
same easing and duration as the tweened fields, so it matches how far the transition has moved. Use
it to drive values that cannot be tweened.

`back` and `elastic` easings overshoot. With them, `alpha` goes below `0` or above `1` during the
transition and settles at exactly `1` when it ends. This is expected, because the same curve moves
the tweened fields past their start or end. Clamp it with `math.clamp(alpha, 0, 1)` if you need a
fixed range.

## Overrides for state changes <Badge type="tip" text="Added in 0.4.0" />

A connection can use other tween settings for particular state changes. A state change is the state the handler
leaves and the state it enters. `tweenOverrides` is an array of entries, and each entry names those states and the
settings to use for them:

```luau
handler.animate({
    tweenDefault = {
        duration = 0.15,
        easing = "quadOut",
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
                duration = 0.05,
                easing = "linear",
            },
        },
        {
            -- from is left out, so it means every state
            to = {
                "Disabled",
            },
            tween = {
                duration = 0.5,
                easing = "sineInOut",
            },
        },
    },
})
```

- `from` and `to` are arrays of state names. A side that is left out means every state.
- `tween` takes the same settings as `tweenDefault`. A setting it leaves out keeps the one of `tweenDefault`.
- A state change that no entry matches uses `tweenDefault`.
- To keep `tweenDefault` and `tweenOverrides` in one module that many components share, see [Tween config](/examples/tween-config).
- At most one entry may match a state change, so the order of the array does not matter. An overlap raises an error
  when `onTransition` or `animate` is called. The error lists every problem together: overlaps, a state the handler does
  not have, an empty array, an entry that leaves out both sides, an entry that only matches a state to itself, and an
  entry with no `tween`.
- The settings are picked when `setState` starts the transition, once for each connection. A connection with no
  overrides does no extra work. A source inside the settings is still read every frame.
- When a transition is interrupted, the entry is picked for the state the handler was heading to and the new state. The
  value still continues from where it is.
- The speed works as it does without overrides: the duration is divided by the speed of the connection, then by the
  global speed, as `(duration / localSpeed) / globalSpeed`.
- A different tween for one field is another connection. Call `animate` or `onTransition` again with the settings that
  field needs.

## Delays

A connection with a `delay` waits before its tween starts. Give each connection a larger delay to stagger them,
such as list items that appear one after another:

```luau
for index, item in items do
    handler.onTransition(function(_, _, current)
        item.Transparency = current.transparency
    end, {
        tweenDefault = {
            delay = (index - 1) * 0.05,
        },
    })
end
```

- The connection sends nothing while it waits. Its first frame starts from the beginning of the tween.
- The wait is scaled time: [`pause`](/guide/handlers#pause), a `speed` of `0`, and `scaleSpeed` apply to it too.
- `setState(name, { instant = true })` skips the delay, and [`finish`](/guide/handlers#finish) ends a connection that
  is still waiting.
- The transition finishes, and [`onFinish`](/guide/handlers#onfinish) runs, only after the most delayed connection ends.

### Delaying a state change <Badge type="tip" text="Added in 0.5.0" />

`setState(name, { delay = seconds })` delays one state change. The state changes at once, so `currentState` and the
events update, but every connection waits that long before its first frame, on top of its own `delay`.

### Staggering handlers <Badge type="tip" text="Added in 0.5.0" />

To stagger separate handlers, such as one handler per list item, pass `stagger` to
[`everyHandler.setState`](/guide/every-handler#setstate). The handlers start one after another, in the order they were
created:

```luau
-- The first item starts at once, the second after 0.05 seconds, the third after 0.1 seconds, and so on.
VideState.everyHandler.withRule("ListItem").setState("Shown", { stagger = 0.05 })
```

Each handler receives a `delay` of `stagger × its position`, added to any `delay` you pass. Create the handlers in the
order they should appear.

## Pausing

[`pause`](/guide/handlers#pause) freezes every transition of a handler, and [`resume`](/guide/handlers#resume)
continues them from the same values. [`onPause`](/guide/handlers#onpause) and
[`onResume`](/guide/handlers#onresume) report the `os.clock()` time at which the most recent transition
started, so you can work out how long it has been running.

```luau
handler.onPause(function(startedAt)
    print("paused after", os.clock() - startedAt, "seconds")
end)

handler.pause()
handler.resume()
```

- A paused transition keeps its values and its listeners are not called again.
- `setState` while paused starts the new transition, sends its first frame, and holds it there until `resume`.
- Pausing applies to the whole handler. To pause or slow a single connection, use a `speed` source in that connection's options. A `speed` of `0` pauses only that connection and does not fire `onPause`.
- If `speed` is also `0`, the transition stays frozen after `resume` until the speed is above `0`.

## Scaling the speed and finishing

[`scaleSpeed`](/guide/handlers#scalespeed) plays transitions faster or slower, and
[`finish`](/guide/handlers#finish) ends it at once. Use them to let a player skip an animation.

```luau
handler.onFinish(function(startedAt)
    print("took", os.clock() - startedAt, "seconds")
end)

handler.scaleSpeed({ speed = 4, once = true })
handler.finish()
```

- `scaleSpeed` multiplies each connection's own `speed`. By default it stays for every following transition, until you call `scaleSpeed` again. Pass `once = true` to apply it only to the transition that is running, so the next `setState` plays at normal speed. To scale, pause, or finish every handler at once, use [`VideState.everyHandler`](/guide/every-handler).
- `finish` sends every connection its last frame, with `current` equal to the next state's values and an `alpha` of `1`, before it returns. It works while the handler is paused.
- [`onFinish`](/guide/handlers#onfinish) runs once per transition, when the last connection that was playing it ends. A transition that a newer `setState` replaces does not finish.
- Connections with different durations finish at different times, so the event waits for the slowest one.
- [`waitForFinish`](/guide/handlers#waitforfinish) yields until the handler has no running transition, for code that runs in sequence.

## Custom easing <Badge type="tip" text="Added in 0.5.0" />

The built-in easings are names. For a curve of your own, make one and pass it as `easing`:

```luau
handler.animate({
    tweenDefault = {
        duration = 0.3,
        -- The same curve as CSS cubic-bezier(0.34, 1.56, 0.64, 1).
        easing = VideState.bezier(0.34, 1.56, 0.64, 1),
    },
})
```

Both functions below return a value that `easing` accepts in place of a name, including from a Vide source. A plain
function does not work in `easing`, because a function there is read as a source. A table that was not made by these
two is rejected.

### bezier <Badge type="tip" text="Added in 0.5.0" />

```luau
VideState.bezier(
    x1: number, -- The horizontal position of the first control point
    y1: number, -- The vertical position of the first control point
    x2: number, -- The horizontal position of the second control point
    y2: number -- The vertical position of the second control point
) -> CustomEasing
```

Makes a cubic bezier easing, like CSS `cubic-bezier`, so a curve from a design tool works as it is. The curve starts at
0 and ends at 1.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `x1` | `number` | Must be between `0` and `1`. |
| `y1` | `number` | Any finite number. A value outside 0 to 1 overshoots like the `back` easings. |
| `x2` | `number` | Must be between `0` and `1`. |
| `y2` | `number` | Any finite number. A value outside 0 to 1 overshoots like the `back` easings. |

**Returns**

| Type | Description |
| --- | --- |
| [`CustomEasing`](#customeasing) | An easing for the `easing` setting. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | A number is not finite | `bezier expects four finite numbers` |
| <Badge type="danger" text="Error" /> | `x1` or `x2` is outside 0 to 1 | `bezier x1 and x2 must be between 0 and 1` |

### easing <Badge type="tip" text="Added in 0.5.0" />

```luau
VideState.easing(
    fn: (number) -> number -- Takes the progress from 0 to 1 and returns the eased progress
) -> CustomEasing
```

Wraps your own easing function:

```luau
easing = VideState.easing(function(progress)
    return progress * progress
end)
```

The function is called with `0` and `1` when it is made, and it must return finite numbers for both. It should return
`0` at `0` and `1` at `1`, so a transition starts at the old value and ends at the new one. A later result that is not a
finite number ends the transition with an error.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `fn` | `(number) -> number` | The easing curve. It may overshoot. |

**Returns**

| Type | Description |
| --- | --- |
| [`CustomEasing`](#customeasing) | An easing for the `easing` setting. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `fn` is not a function | `easing expects a function, got <type>` |
| <Badge type="danger" text="Error" /> | `fn` does not return a finite number for `0` or `1` | `easing must return a finite number for a progress of 0 and 1` |
| <Badge type="danger" text="Error" /> | During a transition, `fn` returns a value that is not a finite number | `a custom easing returned a value that is not a finite number` |

## Reduced motion <Badge type="tip" text="Added in 0.5.0" />

Some players turn animations off. [`setReducedMotion`](#setreducedmotion) makes every following `setState` instant, so
each [`onTransition`](/guide/handlers#ontransition) connection receives one frame with the next values and an alpha of
`1`, and [`onFinish`](/guide/handlers#onfinish) still runs. Call it from your game's settings, and set it back to
`false` to animate again.

```luau
VideState.setReducedMotion(true)

handler.setState("Open") -- plays as one frame, whatever the duration is
```

It affects every handler, including ones created later, and only the state changes that start after it is called. A
transition that is already running keeps playing, and `finish` ends it at once. A connection cannot opt out, so it also
applies to a spinner or a progress bar that you animate with `onTransition`.

### setReducedMotion <Badge type="tip" text="Added in 0.5.0" />

```luau
VideState.setReducedMotion(
    enabled: boolean -- Whether every state change is instant
) -> ()
```

Turns reduced motion on or off. It is off by default.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `enabled` | `boolean` | `true` makes every following `setState` instant. `false` animates again. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `enabled` is not a boolean | `setReducedMotion expects a boolean, got <type>` |

### isReducedMotion <Badge type="tip" text="Added in 0.5.0" />

```luau
VideState.isReducedMotion() -> boolean
```

Returns whether reduced motion is on.

**Returns**

| Type | Description |
| --- | --- |
| `boolean` | `true` while every state change is instant. Defaults to `false`. |

## Performance

Every running transition of every handler is stepped by one shared loop, which runs only while a transition
is running. The first frame of a transition is sent inside `setState`, and later frames are sent by the loop.

- `onTransition` callbacks must not yield. A yield holds up the loop, and with it every running transition.
- A callback that raises an error stops only its own connection. The error is still reported in the output, and
  the other connections keep running.

A benchmark in Roblox Studio started a transition on many handlers at once, each with one connection and two
tweened fields. The frame times include Studio's frame cap, which was about 30 frames per second during the
run, so only a frame time well above 33 ms shows real cost.

| Handlers | `setState` on all of them | Average frame | Worst frame |
| --- | --- | --- | --- |
| 1,000 | about 25 ms | about 25 ms | under 120 ms (the first frame) |
| 5,000 | about 150 ms | about 27 ms | about 32 ms |
| 10,000 | about 300 ms | about 55 ms | about 64 ms |

`animate` and `onTransition` cost about the same. In one Studio run of 10,000 handlers, with one connection each:

- Creating the handlers and connecting took about 450 ms for both, which is about 45 microseconds for each handler.
- `setState` on all of them took about 270 ms for both.
- `tweenOverrides` with six entries, where the matching entry was the last one, added about 20 microseconds to
  connecting each handler and about 5 microseconds to its `setState`. A connection with no overrides pays nothing.

Measure your own use. The numbers depend on the device, the number of fields, and the work your callbacks do.

## Changing settings during a transition

When a setting is a Vide source, it is read every frame. Changing it affects the running transition,
and each tween restarts from its current position. The remaining distance is covered with the new
settings, so values do not jump, but the easing curve starts again from that point. Plain values are
read once and never change.

## Types

### TransitionOptions <Badge type="tip" text="Added in 0.1.0" /> <Badge type="warning" text="Changed in 0.2.0" /> <Badge type="warning" text="Changed in 0.4.0" />

```luau
type TransitionOptions = {
    tweenDefault: TweenSettings?, -- The tween settings of the connection
    tweenOverrides: { TweenOverride }?, -- Tween settings for particular state changes
}
```

Changed in 0.2.0: added `delay`, and the options can also be passed to one connection.

Changed in 0.4.0: the settings moved into `tweenDefault`, and a handler no longer takes them.

The options of one [`onTransition`](/guide/handlers#ontransition) or [`animate`](/guide/handlers#animate) connection.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `tweenDefault` | [`TweenSettings`](#tweensettings) | No | The tween settings of the connection. A setting left out takes the built-in default. |
| `tweenOverrides` | `{ `[`TweenOverride`](#tweenoverride)` }` | No | Tween settings for particular state changes. See [Overrides for state changes](#overrides-for-state-changes). |

An unknown key, a non-table value, or a setting at the top level raises an error when the connection is made. A top-level
setting such as `duration` gets the message `onTransition options has an unknown key duration. Put duration inside tweenDefault`.

### TweenSettings <Badge type="tip" text="Added in 0.4.0" /> <Badge type="warning" text="Changed in 0.5.0" />

```luau
type TweenSettings = {
    easing: (Easing | Source<Easing>)?, -- The easing curve applied to animatable fields and alpha
    duration: (number | Source<number>)?, -- The duration in seconds
    speed: Source<number>?, -- How fast the transition advances
    delay: (number | Source<number>)?, -- How long a connection waits before its tween starts
}
```

Changed in 0.5.0: `easing` also takes a [`CustomEasing`](#customeasing) made with [`bezier`](#bezier) or [`easing`](#easing).

The tween settings of a connection. The easing curves are the standard equations that [easings.net](https://easings.net) lists.

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `easing` | [`Easing`](#easing) or `Source<Easing>` | No | `"linear"` | The easing curve: a name, or one made with [`bezier`](#bezier) or [`easing`](#easing). An unknown name raises an error. |
| `duration` | `number` or `Source<number>` | No | `0.25` | The duration in seconds. Must be finite and non-negative. |
| `speed` | `Source<number>` | No | `1` | A Vide source read every frame. `1` is normal speed, `0` pauses, and larger values play faster. It must never be negative, so a transition never moves backwards. |
| `delay` | `number` or `Source<number>` | No | `0` | How long a connection waits, in seconds, before it sends its first frame. Read when a transition starts. Must be finite and non-negative. See [Delays](#delays). |

Invalid values raise an error when `onTransition` or `animate` is called. This includes an unknown key, a
non-table value, a negative `speed`, and a `speed` that is not a source. A source is also checked on
creation, using its current value.

If a source later returns an invalid value, the transition keeps running instead of raising an
error: `easing` falls back to `"linear"`, `duration` to `0.25`, and `delay` to `0`. A negative `speed` is treated as `0`,
which pauses the transition, and any other invalid `speed` is treated as `1`. A paused transition keeps
its values and does not call listeners again until the speed is above `0`.

### TweenOverride <Badge type="tip" text="Added in 0.4.0" />

```luau
type TweenOverride = {
    from: { string }?, -- The states the handler leaves
    to: { string }?, -- The states the handler enters
    tween: TweenSettings, -- The settings for the state changes that match
}
```

One entry of `tweenOverrides`.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `from` | `{ string }` | No | The states the handler leaves. Every name must be a state of the handler. Left out means every state. |
| `to` | `{ string }` | No | The states the handler enters. Every name must be a state of the handler. Left out means every state. |
| `tween` | [`TweenSettings`](#tweensettings) | Yes | The settings for the matching state changes. A setting left out keeps the one of `tweenDefault`. |

`onTransition` and `animate` raise one error that starts with `onTransition tweenOverrides has <n> problems:` and lists
each problem on its own line:

- `entry <n> must be a table`
- `entry <n> has an unknown key <key>`
- `entry <n> from has an unknown state "<state>"`, and the same for `to`
- `entry <n> from is empty, so it matches nothing`, and the same for `to`
- `entry <n> leaves out both from and to, so it matches every state change. Use tweenDefault for that`
- `entry <n> only matches <state> to <state>, which is not a state change`
- `entry <n> needs a tween table`
- `entry <n>: <message>` for an invalid setting, such as `onTransition duration must be a finite non-negative number`
- `entries <a> and <b> both match <state> to <state>`

### Easing <Badge type="tip" text="Added in 0.5.0" />

```luau
type Easing = TweenName | CustomEasing
```

The easing of a connection: the name of a built-in curve, or a [`CustomEasing`](#customeasing).

### CustomEasing <Badge type="tip" text="Added in 0.5.0" />

```luau
type CustomEasing = {
    read fn: (number) -> number,
}
```

A curve made with [`VideState.bezier`](#bezier) or [`VideState.easing`](#easing). `fn` takes the progress
and returns the eased progress. Only these two functions make one.

### TweenName <Badge type="tip" text="Added in 0.1.0" />

```luau
type TweenName =
    "linear"
    | "quadIn" | "quadOut" | "quadInOut"
    | "cubicIn" | "cubicOut" | "cubicInOut"
    | "sineIn" | "sineOut" | "sineInOut"
    | "expoIn" | "expoOut" | "expoInOut"
    | "backIn" | "backOut" | "backInOut"
    | "elasticIn" | "elasticOut" | "elasticInOut"
```

The valid easing names. Editors suggest them from this type.
