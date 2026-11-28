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

The numbers come from the benchmark in `tests/bench/`, run in Roblox Studio on one machine. A single call takes
microseconds, so a run varies by about a quarter, and a range shows that. Studio caps its frame rate, so the cost of a
frame is measured with the [manual clock](/guide/testing) instead of real frames.

## One operation at a time

Creating, once per rule, handler, or connection:

| Operation | Time |
| --- | --- |
| A schema such as `float` or `union` | ≈2 µs |
| A `record` schema with 3 fields | ≈9 µs |
| A rule with 2 fields, with or without tags and `allowedTransitions` | ≈3 µs |
| A rule with 20 fields | 30–45 µs |
| `VideState.extend` | 6–7 µs |
| `rule.new` with 4 states of 2 fields | 35–45 µs |
| `rule.new` with 4 states of 20 fields | 195–270 µs |
| `rule.new` and `destroy` | 35–50 µs |

Connecting to a handler:

| Operation | Time |
| --- | --- |
| `onChange` | ≈0.5 µs |
| `onEnter` | ≈0.7 µs |
| `progress` | ≈0.9 µs |
| `animate` | 2.5–3 µs |
| `onTransition` | ≈4 µs |
| `onTransition` with six `tweenOverrides`, where the matching one is last | 13–19 µs |

Easings:

| Operation | Time |
| --- | --- |
| `VideState.bezier` | ≈1 µs |
| `VideState.spring` with options it has not seen before | ≈1.1 ms |
| `VideState.spring` with options it has seen before | 18–24 µs |
| Evaluating a `spring` at one point | ≈0.3 µs |
| Evaluating a `bezier` at one point | ≈0.2 µs |

Make a spring once, when the module loads, and keep it. The first call with a set of options solves for it, and a later
call with the same options is answered from a cache, but it still builds the key, so it is not free.

Running:

| Operation | Time |
| --- | --- |
| `setState` with nothing connected | 11–20 µs |
| `setState` with one `onTransition`, `animate`, or `progress` connection | 14–26 µs |
| `setState` with three `animate` connections | 27–37 µs |
| `setState` with a `spring` easing, a `delay`, or `instant = true` | about the same as one connection |
| `pause` and `resume` | ≈0.5 µs |
| `scaleSpeed` and `finish` | 0.3–0.4 µs |
| `playSequence` of three instant steps, started and stopped | 65–75 µs |
| `everyHandler.setState` on 1,000 handlers, with or without `stagger` | ≈27 ms, ≈27 µs per handler |
| `everyHandler.count` with a filter, on 1,000 handlers | 0.45–0.7 ms |

`setState` takes about the same with any kind of connection, and the differences between rows are inside the noise of
a run. What the connections change is the cost of the frames that follow.

## Cost of a frame

With 1,000 handlers that are all in a transition, one step of the shared loop took 1.4–1.5 ms with one `animate`
connection on each handler, and 4.1–5.7 ms with three. That is ≈1.5–1.9 µs for each connection, for a frame. At 60
frames per second a frame has 16.7 ms, so 1,000 connections use ≈9% of it.

## Many handlers at once

A transition on many handlers at once, each with one connection and two tweened fields:

| Handlers | Connecting all of them | `setState` on all of them |
| --- | --- | --- |
| 1,000 | 33–41 ms | 13–30 ms |
| 5,000 | 160–320 ms | 130–160 ms |
| 10,000 | 480–540 ms | 205–310 ms |

`animate` and `onTransition` cost about the same. `tweenOverrides` with six entries, where the matching entry was the
last one, added ≈15 µs to connecting each handler, and a connection with no overrides pays nothing.

## Memory

The memory is read from Luau's heap after the collector has freed what was waiting, with `lest memory`. Roblox cannot
force a collection, so a reading can be off by a few percent, and the numbers below are the ones that repeated in
every run. They are what each thing keeps alive.

| What | Memory |
| --- | --- |
| A rule with 2 fields | ≈3.2 KB |
| A rule with 20 fields | ≈17.6 KB |
| A handler with 4 states of 2 fields, without the Vide sources of its states | ≈20 KB |
| `onChange` | ≈0.2 KB |
| `onEnter` | ≈0.25 KB |
| `onTransition` | ≈0.9 KB |
| `progress` | ≈1.2 KB |
| `animate`, with two sources | ≈1.5 KB |
| `onTransition` with six `tweenOverrides` | ≈10 KB |
| A running transition with one `animate` connection, while it runs | ≈12 KB |

- A rule is shared by all of its handlers, so make one rule for many components. A handler is the expensive part.
- 1,000 handlers with one `animate` connection each hold ≈22 MB, and a transition running on all of them holds ≈12 MB
  more.
- A connection with six `tweenOverrides` holds ten times what one without them does. That only matters with thousands of
  connections. The reading includes the tables that you pass in.

Measure your own use. The numbers depend on the device, the number of fields, and the work your callbacks do.
