---
title: Performance
description: How VideState runs transitions, and what a benchmark in Roblox Studio measured.
---

# Performance

Every running transition of every handler is stepped by one shared loop, which runs only while a transition
is running. The first frame of a transition is sent inside `setState`, and later frames are sent by the loop.

- `onTransition` callbacks must not yield. A yield holds up the loop, and with it every running transition.
- A callback that raises an error stops only its own connection. The error is still reported in the output, and
  the other connections keep running.

The numbers below come from the benchmark in `tests/bench/`, run in Roblox Studio on one machine. A single call takes
microseconds, so a run varies by about a quarter and the ranges show that. Studio caps its frame rate, so the cost of a
frame is measured with the [manual clock](/guide/testing) instead of real frames.

## One operation at a time

Creating things, once per rule, handler, or connection:

| Operation | Time |
| --- | --- |
| A schema such as `float` or `union` | about 2 microseconds |
| A `record` schema with 3 fields | about 9 microseconds |
| A rule with 2 fields, with or without tags and `allowedTransitions` | about 3 microseconds |
| A rule with 20 fields | 30 to 45 microseconds |
| `VideState.extend` | 6 to 7 microseconds |
| `rule.new` with 4 states of 2 fields | 35 to 45 microseconds |
| `rule.new` with 4 states of 20 fields | 195 to 270 microseconds |
| `rule.new` and `destroy` | 35 to 50 microseconds |

Connecting to a handler:

| Operation | Time |
| --- | --- |
| `onChange` | about 0.5 microseconds |
| `onEnter` | about 0.7 microseconds |
| `progress` | about 0.9 microseconds |
| `animate` | 2.5 to 3 microseconds |
| `onTransition` | about 4 microseconds |
| `onTransition` with six `tweenOverrides`, where the matching one is last | 13 to 19 microseconds |

Easings:

| Operation | Time |
| --- | --- |
| `VideState.bezier` | about 1 microsecond |
| `VideState.spring` with options it has not seen before | about 1.1 milliseconds |
| `VideState.spring` with options it has seen before | 18 to 24 microseconds |
| Evaluating a `spring` at one point | about 0.3 microseconds |
| Evaluating a `bezier` at one point | about 0.2 microseconds |

Make a spring once, when the module loads, and keep it. The first call with a set of options solves for it, and a later
call with the same options is answered from a cache, but it still builds the key, so it is not free.

Running:

| Operation | Time |
| --- | --- |
| `setState` with nothing connected | 11 to 20 microseconds |
| `setState` with one `onTransition`, `animate`, or `progress` connection | 14 to 26 microseconds |
| `setState` with three `animate` connections | 27 to 37 microseconds |
| `setState` with a `spring` easing, with a `delay`, or with `instant = true` | about the same as one connection |
| `pause` and `resume` | about 0.5 microseconds |
| `scaleSpeed` and `finish` | 0.3 to 0.4 microseconds |
| `playSequence` of three instant steps, started and stopped | 65 to 75 microseconds |
| `everyHandler.setState` on 1,000 handlers, with or without `stagger` | about 27 milliseconds, about 27 microseconds for each handler |
| `everyHandler.count` with a filter, on 1,000 handlers | 0.45 to 0.7 milliseconds |

`setState` takes about the same with any kind of connection, and the differences between rows are inside the noise of
a run. What the connections change is the cost of the frames that follow.

## Cost of a frame

With 1,000 handlers that are all in a transition, one step of the shared loop took 1.4 to 1.5 milliseconds with one
`animate` connection on each handler, and 4.1 to 5.7 milliseconds with three. That is about 1.5 to 1.9 microseconds for
each connection, for a frame. At 60 frames per second a frame has 16.7 milliseconds, so 1,000 connections use about 9%
of it.

## Many handlers at once

A transition on many handlers at once, each with one connection and two tweened fields:

| Handlers | Connecting all of them | `setState` on all of them |
| --- | --- | --- |
| 1,000 | 33 to 41 milliseconds | 13 to 30 milliseconds |
| 5,000 | 160 to 320 milliseconds | 130 to 160 milliseconds |
| 10,000 | 480 to 540 milliseconds | 205 to 310 milliseconds |

`animate` and `onTransition` cost about the same. `tweenOverrides` with six entries, where the matching entry was the
last one, added about 15 microseconds to connecting each handler, and a connection with no overrides pays nothing.

Measure your own use. The numbers depend on the device, the number of fields, and the work your callbacks do.
