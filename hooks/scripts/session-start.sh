#!/usr/bin/env bash
set -euo pipefail
slug="$(pwd | sed 's#^/##; s#/#-#g')"
dir="${TMPDIR:-/tmp}/claude-handoffs/${slug}"
nudge="Session hygiene: between chunks of work, run the handoff skill and start a FRESH session. Small context = sharp Claude."
recent=""
if [ -d "$dir" ]; then
  latest="$(ls -1t "$dir" 2>/dev/null | head -1 || true)"
  [ -n "$latest" ] && recent="A recent handoff exists at ${dir}/${latest} — offer to read it before continuing."
fi
ctx="$nudge"
[ -n "$recent" ] && ctx="$ctx"$'\n'"$recent"
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' \
  "$(printf '%s' "$ctx" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')"
