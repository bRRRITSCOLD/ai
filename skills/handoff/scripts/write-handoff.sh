#!/usr/bin/env bash
# Usage: write-handoff.sh <body-file>
# Prints the path of the handoff file it created.
set -euo pipefail
slug="$(pwd | sed 's#^/##; s#/#-#g')"
dir="${TMPDIR:-/tmp}/claude-handoffs/${slug}"
mkdir -p "$dir"
ts="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
out="${dir}/${ts}.md"
cp "${1:?body file required}" "$out"
echo "$out"
