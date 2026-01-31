#!/usr/bin/env bash
set -euo pipefail

PROMPT_TEXT="${1:?prompt text required}"

ROOT="$(pwd)"
WF="$ROOT/.opencode/workflow"
LOG="$WF/daemon.log"

if [[ ! -d "$WF" ]]; then
  echo "FAIL: workflow directory not found: $WF" >&2
  exit 1
fi

SESSION_ID="$(date +%Y%m%d_%H%M%S)_${RANDOM}"
SESSION_DIR="$WF/brainstorm/sessions/$SESSION_ID"
mkdir -p "$SESSION_DIR"

printf "# Brainstorm Prompt\nsession_id=%s\nroot=%s\n\n%s\n" "$SESSION_ID" "$ROOT" "$PROMPT_TEXT" > "$SESSION_DIR/00_PROMPT.md"

echo "[brainstorm] start session_id=$SESSION_ID root=$ROOT" >> "$LOG"

if "$WF/brainstorm_runner.sh" "$SESSION_ID" "$SESSION_DIR" "$PROMPT_TEXT"; then
  :
else
  echo "FAIL: brainstorm runner failed session_id=$SESSION_ID" >&2
  exit 1
fi
