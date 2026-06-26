---
name: handoff
description: Write a session handoff file before ending a work chunk so the next fresh session resumes instantly. Use when finishing a unit of work, when context is getting large, when the user says "handoff", "wrap up", "save state", or before suggesting a new session.
---

# Handoff Skill

Persist a structured summary of the current session to a temp file so the next fresh Claude session can resume without re-reading the full transcript.

## Checklist

Follow these steps in order:

### 1. Goal
State what the overall objective of this session was.

### 2. Done
List everything that was completed during this session.

### 3. In progress
List anything that was started but not yet finished.

### 4. Next steps
List the concrete actions the next session should take, in priority order.

### 5. Key files
List the absolute paths of all files created, modified, or read that are important for continuity.

### 6. Decisions
Record any significant choices made and the reasoning behind them.

### 7. Open questions
Note anything unresolved or uncertain that the next session should address.

---

Once you have drafted the markdown body covering all seven sections above, write it to a temporary file, then run:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/handoff/scripts/write-handoff.sh <body>
```

where `<body>` is the path to your draft markdown file.

The script will print the path where the handoff was saved. Print that path to the user and recommend they start a **fresh session** ("small context = sharp Claude") and read the handoff file there to resume instantly.

## Path convention

Handoff files are written to:

```
${TMPDIR:-/tmp}/claude-handoffs/<cwd-slug>/<UTC-ISO>.md
```

where `<cwd-slug>` is the absolute working directory with `/` replaced by `-` and the leading `-` stripped.
