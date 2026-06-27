---
name: autonomous-delivery
description: Drives a pre-decomposed set of GitHub issues to done with minimal human input. Invoked by the main session when someone says "autonomous loop", "run until done", "don't stop until the goal", "self-sustaining loop", "orchestrate the whole build", "drive these issues to done", "agentic loop", or "/orchestrate". Assumes the goal has already been broken into tracked GitHub issues (via feature-delivery or project-management); this skill owns the dispatch-review-merge loop and all termination guards.
---

# Autonomous Delivery Skill

Runs the main Claude Code session in a self-sustaining loop: dispatch specialist → staff-engineer review gate → squash-merge, repeating until all open issues are closed or a guard trips. Requires a goal already decomposed into GitHub issues with agent assignments and dependency links.

Apply `principles-dry-kiss`: do not add phases or coordination overhead the task does not need. This skill is about execution, not planning.

## When to use

Use this skill when:
- A goal has already been decomposed into tracked GitHub issues (via `feature-delivery` / `project-management`).
- The main session should drive those issues to done without stopping for human input at each issue.
- The goal is bounded enough that a max-iteration CAP and token budget can guard against runaway execution.

Do not use this skill for untracked or undecomposed goals — run `feature-delivery` first.

## The loop

```
until (open issues == 0) or (iterations >= CAP) or (budget exhausted):
  ready = issues whose dependencies are all closed
  if ready empty and open > 0:
    report blocker; stop
  for issue in ready (respecting parallel-safe vs serial):
    dispatch assigned specialist agent  -> branch + implement + PR (git-workflow)
    dispatch staff-engineer review      -> GATE
    if approved:
      squash-merge per git-workflow
    else:
      ONE fix pass -> re-review
      if still failing: flag + leave open
  iterations++

done when: 0 open issues AND CI/validate green AND tests pass
```

Parallel-safe issues (no shared file overlap, independent scope) may be dispatched concurrently. Serial issues (dependency edges, shared files) must run sequentially.

## Guards

| Guard | Rule |
|---|---|
| **TERMINATION** | Loop exits only when: open issues = 0 AND `node scripts/ci/validate.mjs` passes AND tests pass. Not before. |
| **VERIFICATION** | Every PR passes through the staff-engineer review gate before merge. Never merge unreviewed. If review fails, one fix pass then re-review; if it still fails, flag the issue open and continue to the next. |
| **RUNAWAY** | Hard max-iteration CAP (default 20 rounds). Also stop after K consecutive rounds (default 3) with no merged PRs — loop-until-dry. Also stop when `budget.remaining() < THRESHOLD` if running via the Workflow tool. |
| **DURABLE STATE** | GitHub issues + a progress ledger file (`.superpowers/delivery-progress.md`) are the resume map. They survive crash and context compaction. On resume, trust closed issues and `git log` over in-memory state — never reconstruct history from memory. |
| **CONTEXT-ROT** | Run the `handoff` skill before ending any session with open issues. Prefer a fresh Claude Code session between phases or large work chunks — long sessions accumulate stale reasoning. |

## Two execution modes

### (A) Workflow tool — preferred for a bounded goal

Run the reference script via the Workflow tool:

```
${CLAUDE_PLUGIN_ROOT}/scripts/workflows/deliver.workflow.mjs
```

This gives deterministic fan-out with a built-in budget guard and explicit Scout → Build → Verify phases. The Workflow tool requires explicit opt-in by the user. Review the script before first real use — it creates PRs and merges only after the staff-engineer review gate passes.

### (B) `/loop` or ScheduleWakeup — for long unattended or polling runs

Use the `loop` skill or `ScheduleWakeup` to re-check ready issues on each tick (or self-paced). Good for overnight runs or when the goal spans many sessions. Pair with the DURABLE STATE guard — write the progress ledger each tick so any session can resume.

## Honesty constraint

The loop and all dispatch run **only at the main Claude Code session level**. Subagents cannot spawn other subagents — the harness blocks agent nesting. Specialist agents produce PRs; the loop in the main session merges them per `git-workflow`. Unattended running requires pre-authorized permissions (tool allowlists and `gh` CLI auth).

## Cross-references

- `feature-delivery` — front door for full delivery including planning; run this before autonomous-delivery if the goal is not yet decomposed
- `project-management` — issue decomposition, dependency tracking, dispatch loop
- `git-workflow` — branching, commit conventions, PR sizing, squash-merge
- `staff-engineer` (agent) — review gate; invoked after every implementation PR
- `handoff` — write before ending any session with open issues
- `principles-dry-kiss` — KISS/YAGNI: only run the phases and guards the goal actually needs
