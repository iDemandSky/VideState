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
