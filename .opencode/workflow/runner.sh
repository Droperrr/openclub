#!/usr/bin/env bash
set -euo pipefail

AGENT="${1:?agent required}"
PROMPT_FILE="${2:?prompt file required}"

if ! command -v oc >/dev/null 2>&1; then
  echo "ERROR: 'oc' not found in PATH" >&2
  exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "ERROR: Prompt file '$PROMPT_FILE' not found" >&2
  exit 1
fi

# Read prompt
PROMPT="$(cat "$PROMPT_FILE")"

# Run headless
oc opencode run --agent "$AGENT" "$PROMPT"
