---
description: Drive a goal or set of issues to done with the autonomous-delivery loop (dispatch → review gate → merge) until reached or a guard trips.
argument-hint: <goal or #issues>
---

Invoke the `autonomous-delivery` skill for: $ARGUMENTS

Run the loop until 0 open issues + CI green, or until a guard trips (max iterations, K consecutive empty rounds, or budget exhausted). Report final status: issues closed, PRs merged, any blockers or open items remaining.

The `autonomous-delivery` skill holds the full loop definition, all guards, and execution mode options (Workflow tool vs. `/loop`).
