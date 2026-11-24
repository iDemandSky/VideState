---
title: Every
description: Control every handler at once, such as pausing them or scaling their speed.
outline: [2, 3]
---

# Every

`VideState.every` acts on many handlers with one call. Each scope is a table on `every`, and `every.handler`
acts on every [handler](/guide/handlers) that exists. Use it for settings and effects that belong to the whole
game, such as a pause menu, a game-wide animation speed, or skipping every animation on screen.

```luau
VideState.every.handler.scaleSpeed({ speed = 0.5 }) -- slow motion for everything
VideState.every.handler.pause() -- pause every handler
VideState.every.handler.finish() -- end every running transition
```

Each function calls the handler's own function of the same name, so every handler fires its own
events, such as [`onPause`](/guide/handlers#onpause) and [`onFinish`](/guide/handlers#onfinish). A handler
that has been [destroyed](/guide/handlers#destroy) does nothing, as it does when you call it directly.

If a callback of one handler raises an error, the other handlers still run, and the first error is raised
once all of them have run.

## Functions

### scaleSpeed <Badge type="tip" text="Added in 0.3.0" />

```luau
VideState.every.handler.scaleSpeed(
    options: ScaleSpeedOptions -- How much to scale the speed of every handler
) -> ()
```

Speeds up or slows down every handler. It multiplies with the scale of each handler (see the handler's
[`scaleSpeed`](/guide/handlers#scalespeed)) and with each connection's own `speed`, so the speed of a
connection is `every scale × handler scale × connection speed`.

By default the scale applies to the transitions that are running now and to every transition that starts
later, including those of handlers created later, until you call `scaleSpeed` again. A `speed` of `1`
removes it. With `once = true` it scales only the transitions that are running now: each handler goes back
to normal speed at its next `setState`, and handlers created later are not affected.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `options` | [`ScaleSpeedOptions`](/guide/handlers#scalespeedoptions) | Required. The speed scale, and whether it applies once. |

**Errors**

| | Cause | Message |
| --- | --- | --- |
| <Badge type="danger" text="Error" /> | `options` is not a table | `every.handler.scaleSpeed options must be a table` |
| <Badge type="danger" text="Error" /> | `options` has an unknown key | `every.handler.scaleSpeed options has an unknown key <key>` |
| <Badge type="danger" text="Error" /> | `options.speed` is not a finite number above 0 | `every.handler.scaleSpeed speed must be a finite number above 0` |
| <Badge type="danger" text="Error" /> | `options.once` is not a boolean | `every.handler.scaleSpeed once must be a boolean` |

### pause <Badge type="tip" text="Added in 0.3.0" />

```luau
VideState.every.handler.pause() -> ()
```

Calls [`pause`](/guide/handlers#pause) on every handler. It reaches the handlers that exist when you call
it, so a handler created while everything is paused is not paused.

### resume <Badge type="tip" text="Added in 0.3.0" />

```luau
VideState.every.handler.resume() -> ()
```

Calls [`resume`](/guide/handlers#resume) on every handler.

### finish <Badge type="tip" text="Added in 0.3.0" />

```luau
VideState.every.handler.finish() -> ()
```

Calls [`finish`](/guide/handlers#finish) on every handler: each one sends its last frame before
`finish` returns, and then fires its own `onFinish`.
