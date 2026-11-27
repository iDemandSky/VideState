---
title: Handlers
description: Create independent handlers from a rule, with reactive sources and cleanup.
outline: [2, 3]
---

# Handlers

A handler is created by calling [`new`](/guide/rules#creating-handlers-from-a-rule) on a [rule](/guide/rules#creating-a-rule), so create the rule first. Each handler owns its
own current state, sources, and cleanup. Handlers do not share state, so changing one does not affect
another, and different handlers may use different state names.

## Properties

### sources <Badge type="tip" text="Added in 0.1.0" />

```luau
Handler.sources: Sources<T>
```

A frozen record with one Vide source per field in the rule. Each source reads and writes the active
state's source, so pass them to Vide properties to bind them. When the state changes, the
bindings update automatically.

Writing to a source updates the source of the active state. To change another state's values before
switching to it, write to that state's own source.

## Functions

### currentState <Badge type="tip" text="Added in 0.1.0" />

```luau
Handler.currentState() -> string
```

Returns the name of the active state. It is a function, so call it to read the name.

**Returns**

| Type | Description |
| --- | --- |
| `string` | The name of the active state. |

### setState <Badge type="tip" text="Added in 0.1.0" /> <Badge type="warning" text="Changed in 0.2.0" /> <Badge type="warning" text="Changed in 0.5.0" />

```luau
Handler.setState(
    stateName: string, -- The state to switch to
    options: SetStateOptions? -- Options for this call only
) -> ()
```

Changed in 0.2.0: takes an optional `options` argument, so one change can skip its animation.

Changed in 0.5.0: the options take `delay`, and a change that the rule's
[`allowedTransitions`](/guide/rules#allowed-state-changes) do not list raises an error.

Switches to a state. Later reads and writes of [`sources`](#sources) use that state's sources, and
[`onChange`](#onchange) and [`onTransition`](#ontransition) listeners are called.

With `instant = true`, the change is not animated. Every `onTransition` connection receives one frame with
the next state's values and an `alpha` of `1` before `setState` returns, and [`onFinish`](#onfinish) runs. Use
it to set the first layout of a component, or to snap it back without an animation.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `stateName` | `string` | The name of a state passed to `new`. |
| `options` | [`SetStateOptions`](#setstateoptions)`?` | Optional. Options for this call only. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | The handler was destroyed | `setState cannot be called after destroy` |
| <Badge type="danger" text="Error" /> | `options` is not a table | `setState options must be a table` |
| <Badge type="danger" text="Error" /> | `options` has an unknown key | `setState options has an unknown key <key>` |
| <Badge type="danger" text="Error" /> | `options.instant` is not a boolean | `setState instant must be a boolean` |
| <Badge type="danger" text="Error" /> | `options.delay` is not a finite non-negative number | `setState delay must be a finite non-negative number` |
| <Badge type="danger" text="Error" /> | `stateName` is not a string | `state name must be a string, got <type>` |
| <Badge type="danger" text="Error" /> | The state name is unknown | `unknown state "<state>"` |
| <Badge type="danger" text="Error" /> | The rule's [`allowedTransitions`](/guide/rules#allowed-state-changes) do not let the active state change to it | `cannot change state from "<state>" to "<state>". Allowed: "<state>", ...` |
| <Badge type="danger" text="Error" /> | The state's values no longer match the schema | `Invalid state "<state>":` followed by the schema issues |

A failed `setState` leaves the handler unchanged.

### onChange <Badge type="tip" text="Added in 0.1.0" />

```luau
Handler.onChange(
    callback: (
        from: T, -- A frozen copy of the previous state's values
        to: T -- A frozen copy of the next state's values
    ) -> ()
) -> Disconnect
```

Runs `callback` once each time the state changes. A listener only receives changes made after it
is registered.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | `(from: T, to: T) -> ()` | Called with the values of the previous and the next state. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving changes. |

### onEnter <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.onEnter(
    stateName: string, -- The state to listen for
    callback: (
        previousState: string -- The state the handler left
    ) -> ()
) -> Disconnect
```

Runs `callback` each time the handler switches into `stateName`. It does not run for the initial state, or when
[`setState`](#setstate) is called with the state that is already active.

On a state change, the listeners run in this order: [`onExit`](#onexit) of the old state, `onEnter` of the new
state, [`onChange`](#onchange), then the [`onTransition`](#ontransition) connections.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `stateName` | `string` | The name of a state passed to `new`. |
| `callback` | [`OnEnterCallback`](#onentercallback) | Called with the name of the state the handler left. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop listening. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `stateName` is not a string | `onEnter state name must be a string, got <type>` |
| <Badge type="danger" text="Error" /> | `stateName` is not a state of the handler | `onEnter state "<state>" is not a state of this handler` |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onEnter callback must be a function` |

### onExit <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.onExit(
    stateName: string, -- The state to listen for
    callback: (
        nextState: string -- The state the handler enters
    ) -> ()
) -> Disconnect
```

Runs `callback` each time the handler switches out of `stateName`, before any [`onEnter`](#onenter) listener of
the next state.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `stateName` | `string` | The name of a state passed to `new`. |
| `callback` | [`OnExitCallback`](#onexitcallback) | Called with the name of the state the handler enters. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop listening. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `stateName` is not a string | `onExit state name must be a string, got <type>` |
| <Badge type="danger" text="Error" /> | `stateName` is not a state of the handler | `onExit state "<state>" is not a state of this handler` |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onExit callback must be a function` |

### onTransition <Badge type="tip" text="Added in 0.1.0" /> <Badge type="warning" text="Changed in 0.2.0" /> <Badge type="warning" text="Changed in 0.4.0" /> <Badge type="warning" text="Changed in 0.5.0" />

```luau
Handler.onTransition(
    callback: (
        from: T, -- The previous state's values
        to: T, -- The next state's values
        current: T, -- The values to render on this frame
        alpha: number, -- The eased progress, from 0 to 1
        round: number -- The round of the sequence that started the transition, or 0
    ) -> (),
    options: TransitionOptions? -- Tween settings for this connection only
) -> Disconnect
```

Changed in 0.2.0: takes an optional `options` argument, and every connection tweens on its own.

Changed in 0.4.0: the settings go inside `tweenDefault`, and a handler has no tween options of its own.

Changed in 0.5.0: the callback receives a fifth argument, `round`. It is the round of the
[`playSequence`](#playsequence) that started the transition, counted from `1`, and `0` for a transition that no sequence
started. A callback that does not declare it works as before.

Runs `callback` with a `current` value that moves from the previous state to the next one, and the
`alpha` that shows how far along it is. Each animatable field is tweened. Fields that cannot be tweened, such as strings,
booleans, and enums, are not transitioned: they switch to their next value at the start of the transition. Each connection has its own tween. Its
settings come from the `tweenDefault` of `options`, and any setting it leaves out takes the built-in default. See
[Transitions](/guide/transitions) for the full behavior.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | `(from: T, to: T, current: T, alpha: number, round: number) -> ()` | Called at the start of a transition and on every frame until the transition ends. |
| `options` | [`TransitionOptions`](/guide/transitions#transitionoptions)`?` | Optional. The tween settings of this connection, inside `tweenDefault`, and `tweenOverrides` for particular state changes. Each setting left out takes the built-in default. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving updates. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onTransition callback must be a function` |
| <Badge type="danger" text="Error" /> | `options` is invalid | See [`TransitionOptions`](/guide/transitions#transitionoptions), such as `onTransition easing must be a known easing name` |

### animate <Badge type="tip" text="Added in 0.4.0" />

```luau
Handler.animate(
    options: TransitionOptions? -- Tween settings for this connection only
) -> (Sources<T>, Disconnect)
```

Returns a Vide source for every field, and the sources follow the transition. It is
[`onTransition`](#ontransition) in the form Vide expects: `onTransition` pushes each frame into a callback
that you write, while `animate` gives you sources to bind to properties, so Vide updates them for you. Both are
the same transition underneath, with the same tween, the same options, and the same behavior for
non-animatable fields. They differ only in how you receive the value.

```luau
const animated = handler.animate({
    tweenDefault = {
        duration = 0.2,
        easing = "quadOut",
    },
})

create "Frame" {
    BackgroundTransparency = animated.transparency,
}
```

The sources start at the values of the current state. They are separate from [`sources`](#sources), which
switch to the next state at once and are not animated, and writing to them does nothing to the handler. Every
call opens its own connection with its own tween, so call it once for each animation you need, not once for each
property. Pause, [`scaleSpeed`](#scalespeed), and [`finish`](#finish) act on it like on any other connection. After
[`destroy`](#destroy) the sources keep their last value.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `options` | [`TransitionOptions`](/guide/transitions#transitionoptions)`?` | Optional. The tween settings of this connection, inside `tweenDefault`, and `tweenOverrides` for particular state changes. Each setting left out takes the built-in default. |

**Returns**

| Type | Description |
| --- | --- |
| [`Sources`](#sources)`<T>` | One animated source for each field, with the same keys as the handler's `sources`. |
| [`Disconnect`](#disconnect) | Call it to stop the sources from following. They keep their last value. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `options` is invalid | The same messages as [`onTransition`](#ontransition), such as `onTransition easing must be a known easing name` |

### progress <Badge type="tip" text="Added in 0.5.0" />

```luau
Handler.progress(
    options: TransitionOptions? -- Tween settings for this connection
) -> (Source<number>, Disconnect)
```

Returns a Vide source that holds the progress of the transition, so a progress bar or a ring can bind to it without a
callback. It is [`onTransition`](#ontransition) in the form Vide expects, like [`animate`](#animate), but it follows only
the [`alpha`](/guide/transitions#alpha). The source is `1` when no transition is running, goes from `0` to `1` during
each state change, and stays at `1` when the transition ends.

```luau
const progress = handler.progress({
    tweenDefault = {
        duration = 2,
    },
})

Vide.create "Frame" {
    Size = function()
        return UDim2.fromScale(progress(), 1)
    end,
}
```

It is a thin layer over one `onTransition` connection, so it takes the same options and has its own tween. An easing
that overshoots, such as `back`, takes the alpha below `0` or above `1` in between, so clamp it with
`math.clamp(progress(), 0, 1)` when a bar must stay inside its frame. [`finish`](#finish), [`pause`](#pause), and
[`scaleSpeed`](#scalespeed) act on it like on any other connection. After [`destroy`](#destroy) the source keeps its last
value.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `options` | [`TransitionOptions`](/guide/transitions#transitionoptions)`?` | Optional. The tween settings of this connection, inside `tweenDefault`, and `tweenOverrides` for particular state changes. Each setting left out takes the built-in default. |

**Returns**

| Type | Description |
| --- | --- |
| `Source<number>` | The progress of the transition, from `0` to `1`. |
| [`Disconnect`](#disconnect) | Call it to stop the source from following. It keeps its last value. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `options` is invalid | The same messages as [`onTransition`](#ontransition) |

### playSequence <Badge type="tip" text="Added in 0.5.0" />

```luau
Handler.playSequence(
    steps: { SequenceStep }, -- The states to play, in order
    options: SequenceOptions? -- Options for this sequence
) -> (Source<number>, Disconnect)
```

Changes the state step by step. Each step calls [`setState`](#setstate), waits until its transition has finished, then
waits for the step's `hold` before the next one. Use it for a notification that slides in, stays, and slides out, or a
button that flashes and settles.

```luau
handler.playSequence({
    { state = "Shown", hold = 3 }, -- slides in, then stays for 3 seconds
    { state = "Hidden" },
})
```

The first step starts before `playSequence` returns. The sequence ends after the last step's transition, or goes on
from the first step again with `loop`. One pass over the steps is a round.

```luau
-- Flashes three times, then stops.
local round = handler.playSequence({
    { state = "Flash", hold = 0.2 },
    { state = "Idle", hold = 0.2 },
}, {
    loop = 3,
    onLoop = function(rounds)
        print("rounds completed:", rounds)
    end,
})
```

The returned source holds the round that is being played, counted from `1`, so a label or a bar can bind to it. It stays
at the last round when the sequence ends or is stopped. [`onTransition`](#ontransition) callbacks also receive the round
of the sequence that started their transition, in their fifth argument.

- **Anything else that changes the state stops it.** A `setState` from your code, or a sequence started later, ends the
  running one, so a sequence never fights your own state changes. A newer `playSequence` replaces the running one.
- **A hold is scaled time.** [`pause`](#pause) holds it, and [`scaleSpeed`](#scalespeed) shortens it. The hold after the
  last step only counts when another round follows.
- **`loop` counts the rounds.** `loop = true` plays until the sequence is stopped, and a whole number plays the steps that
  many times in total, so `loop = 3` is three rounds and `loop = 1` is the same as no loop.
- **`onLoop` runs at the end of every round**, including the last one, with the number of rounds completed. It must not
  yield, because the sequence waits for it. A stopped sequence does not call it.
- **Between rounds** the sequence waits one frame, so a loop of instant steps cannot hold up the game.
- **A step that is already the current state** has no transition, so it goes straight to its hold.
- **Reduced motion** makes each step instant, but the holds still apply.
- **The states are checked first.** Every state must exist, and the rule's
  [`allowedTransitions`](/guide/rules#allowed-state-changes) must allow each change from one step to the next. With
  more than one round, they must also allow the change from the last step back to the first. If not, `playSequence` raises an error
  before anything changes.
- [`finish`](#finish) ends the step's transition at once, and the sequence moves on to the hold.
- [`destroy`](#destroy) stops the sequence. A step that raises an error ends it, and the error is reported in the output.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `steps` | `{ `[`SequenceStep`](#sequencestep)` }` | The states to play, in order. Must have at least one step. |
| `options` | [`SequenceOptions`](#sequenceoptions)`?` | Optional. Options for this sequence. |

**Returns**

| Type | Description |
| --- | --- |
| `Source<number>` | The round that is being played, counted from `1`. |
| [`Disconnect`](#disconnect) | Call it to stop the sequence. The handler keeps the state it is in. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | The handler was destroyed | `playSequence cannot be called after destroy` |
| <Badge type="danger" text="Error" /> | `steps` is not a list, or is empty | `playSequence steps must be a non-empty list of steps` |
| <Badge type="danger" text="Error" /> | A step is not a table | `playSequence step <n> must be a table` |
| <Badge type="danger" text="Error" /> | A step has an unknown key | `playSequence step <n> has an unknown key <key>` |
| <Badge type="danger" text="Error" /> | A step has no state name | `playSequence step <n> needs a state name` |
| <Badge type="danger" text="Error" /> | A step's state is not a state of the handler | `playSequence step <n> has an unknown state "<state>"` |
| <Badge type="danger" text="Error" /> | A step's `hold` or `delay` is not a finite non-negative number | `playSequence step <n> hold must be a finite non-negative number`, and the same for `delay` |
| <Badge type="danger" text="Error" /> | A step's `instant` is not a boolean | `playSequence step <n> instant must be a boolean` |
| <Badge type="danger" text="Error" /> | The rule does not allow a change between two steps | `playSequence step <n> cannot change state from "<state>" to "<state>". Allowed: "<state>", ...` |
| <Badge type="danger" text="Error" /> | With `loop`, the rule does not allow the change from the last step to the first | `playSequence cannot loop: cannot change state from "<state>" to "<state>". Allowed: "<state>", ...` |
| <Badge type="danger" text="Error" /> | `options` is not a table, or has an unknown key | `playSequence options must be a table`, `playSequence options has an unknown key <key>` |
| <Badge type="danger" text="Error" /> | `options.loop` is not a boolean or a whole number of at least 1 | `playSequence loop must be a boolean or a whole number of rounds, at least 1` |
| <Badge type="danger" text="Error" /> | `options.onLoop` is not a function | `playSequence onLoop must be a function` |

### pause <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.pause() -> ()
```

Pauses every transition of the handler at once, across all of its [`onTransition`](#ontransition)
connections. Each transition keeps its current values and its listeners are not called again until
[`resume`](#resume). Calling it while the handler is already paused does nothing.

A transition that starts while the handler is paused sends its first frame, then waits for `resume`.
See [Pausing](/guide/transitions#pausing) for how this differs from a `speed` of `0`.

### resume <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.resume() -> ()
```

Continues the transitions that [`pause`](#pause) stopped, from the values they had reached. Calling it
while the handler is not paused does nothing.

### onPause <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.onPause(
    callback: (
        startedAt: number -- The os.clock() time at which the most recent transition started
    ) -> ()
) -> Disconnect
```

Runs `callback` each time the handler goes from running to paused. A repeated [`pause`](#pause) call
does not run it again.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | [`OnPauseCallback`](#onpausecallback) | Called with the `os.clock()` time at which the most recent transition started. If no transition has started yet, it is the time of the `pause` call. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving pause events. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onPause callback must be a function` |

### onResume <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.onResume(
    callback: (
        startedAt: number -- The os.clock() time at which the most recent transition started
    ) -> ()
) -> Disconnect
```

Runs `callback` each time the handler goes from paused to running. A repeated [`resume`](#resume) call
does not run it again.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | [`OnResumeCallback`](#onresumecallback) | Called with the `os.clock()` time at which the most recent transition started. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving resume events. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onResume callback must be a function` |

### scaleSpeed <Badge type="warning" text="Changed in 0.3.0" />

Renamed from `fastForward`, because a scale below `1` slows the transition down. The `once` option is new. To scale every handler at once, use [`everyHandler.scaleSpeed`](/guide/every-handler#scalespeed).

```luau
Handler.scaleSpeed(
    options: ScaleSpeedOptions -- How much to scale the speed of the running transition
) -> ()
```

Speeds up or slows down the transitions of the handler. It affects every [`onTransition`](#ontransition)
connection of the handler, and it multiplies each connection's own `speed`. A connection with a `speed`
of `0.5` scaled by `4` plays at `2`, and scaled by `0.5` plays at `0.25`.

By default the scale stays for every following transition, until you call `scaleSpeed` again. A `speed` of
`1` removes it. With `once = true` the scale applies only to the running transition, and the next `setState`
starts a transition at normal speed again. A kept scale and a once scale multiply.

To jump straight to the end, use [`finish`](#finish).

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `options` | [`ScaleSpeedOptions`](#scalespeedoptions) | Required. The speed scale. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `options` is not a table | `scaleSpeed options must be a table` |
| <Badge type="danger" text="Error" /> | `options` has an unknown key | `scaleSpeed options has an unknown key <key>` |
| <Badge type="danger" text="Error" /> | `options.speed` is not a finite number above 0 | `scaleSpeed speed must be a finite number above 0` |
| <Badge type="danger" text="Error" /> | `options.once` is not a boolean | `scaleSpeed once must be a boolean` |

### finish <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.finish() -> ()
```

Ends every running transition at once. Each connection receives its last frame, with `current` equal to
the next state's values and an `alpha` of `1`, before `finish` returns. Then [`onFinish`](#onfinish) runs.
It works while the handler is paused. It does nothing when no transition is running.

### onFinish <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.onFinish(
    callback: (
        startedAt: number -- The os.clock() time at which the transition started
    ) -> ()
) -> Disconnect
```

Runs `callback` once per transition, when every connection that was playing it has ended and at least
one of them reached its end. This includes a transition that [`finish`](#finish) ended. A transition that
another `setState` replaces does not finish. A transition with no [`onTransition`](#ontransition)
connection does not run, so it does not finish either.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `callback` | [`OnFinishCallback`](#onfinishcallback) | Called with the `os.clock()` time at which the transition started. |

**Returns**

| Type | Description |
| --- | --- |
| [`Disconnect`](#disconnect) | Call it to stop receiving finish events. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `callback` is not a function | `onFinish callback must be a function` |

### waitForFinish <Badge type="warning" text="Yields" /> <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.waitForFinish() -> ()
```

Yields the calling thread until the handler has no running transition, then returns. It returns at once when
nothing is running. Use it in sequential code instead of an [`onFinish`](#onfinish) connection.

The wait ends when the transition reaches its end, when [`finish`](#finish) ends it, or when every
[`onTransition`](#ontransition) connection has disconnected. If a newer `setState` replaces the transition, the wait
goes on until the newer one ends. While the handler is [paused](#pause), it keeps waiting.

### destroy <Badge type="tip" text="Added in 0.2.0" />

```luau
Handler.destroy() -> ()
```

Stops the handler for good. Every running transition stops without sending another frame, and
[`onFinish`](#onfinish) does not run. Every listener is removed, including `onChange`, `onEnter`, `onExit`,
`onTransition`, `onPause`, `onResume`, and `onFinish`. Threads waiting in [`waitForFinish`](#waitforfinish)
continue.

Afterwards, [`setState`](#setstate) raises an error, and [`pause`](#pause), [`resume`](#resume), and
[`finish`](#finish) do nothing. [`sources`](#sources) and [`currentState`](#currentstate) can still be read.
Calling `destroy` again does nothing.

To destroy a handler together with the Vide component that uses it, pass it to Vide's cleanup inside the
component: `Vide.cleanup(handler.destroy)`.

## Types

### HandlerOptions <Badge type="tip" text="Added in 0.1.0" /> <Badge type="danger" text="Removed in 0.4.0" />

A handler no longer takes options, so the type is gone. `rule.new` has only the states and the initial state, and the
tween settings are passed to [`onTransition`](#ontransition) and [`animate`](#animate) instead, inside `tweenDefault`.
Move `onTransition = { duration = 0.2 }` from the handler options to
`handler.onTransition(callback, { tweenDefault = { duration = 0.2 } })`.

### Handler <Badge type="tip" text="Added in 0.1.0" /> <Badge type="warning" text="Changed in 0.5.0" />

```luau
type Handler<T> = {
    sources: Sources<T>,
    currentState: () -> string,
    setState: (stateName: string, options: SetStateOptions?) -> (),
    onChange: (callback: OnChangeCallback<T>) -> Disconnect,
    onEnter: (stateName: string, callback: OnEnterCallback) -> Disconnect,
    onExit: (stateName: string, callback: OnExitCallback) -> Disconnect,
    onTransition: (callback: OnTransitionCallback<T>, options: TransitionOptions?) -> Disconnect,
    animate: (options: TransitionOptions?) -> (Sources<T>, Disconnect),
    progress: (options: TransitionOptions?) -> (Source<number>, Disconnect),
    playSequence: (steps: { SequenceStep }, options: SequenceOptions?) -> (Source<number>, Disconnect),
    pause: () -> (),
    resume: () -> (),
    onPause: (callback: OnPauseCallback) -> Disconnect,
    onResume: (callback: OnResumeCallback) -> Disconnect,
    scaleSpeed: (options: ScaleSpeedOptions) -> (),
    finish: () -> (),
    onFinish: (callback: OnFinishCallback) -> Disconnect,
    waitForFinish: () -> (),
    destroy: () -> (),
}
```

Changed in 0.5.0: added [`progress`](#progress) and [`playSequence`](#playsequence).

The type of a handler. Pass it the value type from [`InferRule`](/guide/rules#inferrule) so the
handler matches its rule.

| Name | Type | Description |
| --- | --- | --- |
| `T` | `InferRule<typeof(rule)>` | The value type of the rule that created the handler. |

### Sources <Badge type="tip" text="Added in 0.1.0" />

```luau
type Sources<T> = -- A record of Vide sources, one per field of T
```

| Name | Type | Description |
| --- | --- | --- |
| `T` | `{ [string]: any }` | The value record. Each field becomes a `Source` of that field's type. |

### OnChangeCallback <Badge type="tip" text="Added in 0.1.0" />

```luau
type OnChangeCallback<T> = (from: T, to: T) -> ()
```

### OnEnterCallback <Badge type="tip" text="Added in 0.2.0" />

```luau
type OnEnterCallback = (previousState: string) -> ()
```

| Name | Type | Description |
| --- | --- | --- |
| `previousState` | `string` | The name of the state the handler left. |

### OnExitCallback <Badge type="tip" text="Added in 0.2.0" />

```luau
type OnExitCallback = (nextState: string) -> ()
```

| Name | Type | Description |
| --- | --- | --- |
| `nextState` | `string` | The name of the state the handler enters. |

### OnTransitionCallback <Badge type="tip" text="Added in 0.1.0" /> <Badge type="warning" text="Changed in 0.5.0" />

```luau
type OnTransitionCallback<T> = (from: T, to: T, current: T, alpha: number, round: number) -> ()
```

Changed in 0.5.0: added `round`.

| Name | Type | Description |
| --- | --- | --- |
| `from` | `T` | The previous state's values. |
| `to` | `T` | The next state's values. |
| `current` | `T` | The values to render on this frame. |
| `alpha` | `number` | The eased progress, from 0 to 1. With `back` and `elastic` easings it can go below 0 or above 1. See [alpha](/guide/transitions#alpha). |
| `round` | `number` | The round of the [`playSequence`](#playsequence) that started the transition, counted from `1`. `0` when no sequence started it. |

### OnPauseCallback <Badge type="tip" text="Added in 0.2.0" />

```luau
type OnPauseCallback = (startedAt: number) -> ()
```

| Name | Type | Description |
| --- | --- | --- |
| `startedAt` | `number` | The `os.clock()` time at which the handler's most recent transition started. If no transition has started yet, it is the time of the `pause` call. |

### OnResumeCallback <Badge type="tip" text="Added in 0.2.0" />

```luau
type OnResumeCallback = (startedAt: number) -> ()
```

| Name | Type | Description |
| --- | --- | --- |
| `startedAt` | `number` | The `os.clock()` time at which the handler's most recent transition started. |

### OnFinishCallback <Badge type="tip" text="Added in 0.2.0" />

```luau
type OnFinishCallback = (startedAt: number) -> ()
```

| Name | Type | Description |
| --- | --- | --- |
| `startedAt` | `number` | The `os.clock()` time at which the transition that finished started. |

### SetStateOptions <Badge type="tip" text="Added in 0.2.0" /> <Badge type="warning" text="Changed in 0.5.0" />

```luau
type SetStateOptions = {
    instant: boolean?, -- Skips the animation of this change
    delay: number?, -- Seconds every connection waits before it starts
}
```

Changed in 0.5.0: added `delay`.

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `instant` | `boolean` | No | `false` | When `true`, every `onTransition` connection receives the next state's values at once, with an `alpha` of `1`. |
| `delay` | `number` | No | `0` | Seconds every connection of this change waits before its first frame, added to the connection's own `delay`. It is scaled time, so `pause` holds it. An instant change ignores it. Must be finite and non-negative. |

### SequenceStep <Badge type="tip" text="Added in 0.5.0" />

```luau
type SequenceStep = {
    state: string, -- The state to change to
    hold: number?, -- Seconds to wait after the transition has finished
    instant: boolean?, -- Skips the animation of this step
    delay: number?, -- Seconds every connection waits before this step starts
}
```

One step of [`playSequence`](#playsequence).

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `state` | `string` | Yes | | The state to change to. It must be a state of the handler. |
| `hold` | `number` | No | `0` | Seconds to wait after the step's transition has finished, before the next step. It is scaled time, so `pause` holds it. Must be finite and non-negative. |
| `instant` | `boolean` | No | `false` | The same as in [`SetStateOptions`](#setstateoptions). |
| `delay` | `number` | No | `0` | The same as in [`SetStateOptions`](#setstateoptions). |

### SequenceOptions <Badge type="tip" text="Added in 0.5.0" />

```luau
type SequenceOptions = {
    loop: (boolean | number)?, -- How many rounds to play
    onLoop: ((round: number) -> ())?, -- Called at the end of every round
}
```

The options of [`playSequence`](#playsequence).

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `loop` | `boolean` or `number` | No | `false` | How many times the steps play. `true` plays them until the sequence is stopped, a whole number of at least `1` plays them that many times in total, and `false` plays them once. |
| `onLoop` | `(round: number) -> ()` | No | | Called when a round ends, with how many rounds have been completed, including after the last round. It must not yield. |

### ScaleSpeedOptions <Badge type="warning" text="Changed in 0.3.0" />

Renamed from `FastForwardOptions`.

```luau
type ScaleSpeedOptions = {
    speed: number, -- How many times the speed of the running transition is multiplied
    once: boolean?, -- Apply the scale only to the running transition, and not to the next ones
}
```

| Field | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `speed` | `number` | Yes | None | The speed scale. Must be a finite number above `0`. Above `1` plays faster, `1` is normal speed, and below `1` plays slower. |
| `once` | `boolean` | No | `false` | When `true`, the scale applies only to the running transition. When `false`, it stays for every following transition. |

### Disconnect <Badge type="tip" text="Added in 0.1.0" />

```luau
type Disconnect = () -> ()
```

Removes the listener it was returned for. Calling it more than once has no effect.
