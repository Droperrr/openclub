#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
WF="$ROOT/.opencode/workflow"
LOG="$WF/daemon.log"
STATE="$WF/.pm_request_hash"

mkdir -p "$WF"
touch "$LOG" "$STATE"

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

echo "[daemon] start project=$ROOT pid=$$" >> "$LOG"

while true; do
  if [[ -f "$WF/00_PM_REQUEST.md" ]]; then
    H="$(hash_file "$WF/00_PM_REQUEST.md")"
    PREV="$(cat "$STATE" 2>/dev/null || true)"

    if [[ -n "$H" && "$H" != "$PREV" ]]; then
      echo "$H" > "$STATE"
      echo "[daemon] change detected -> trigger pipeline $(date -Is)" >> "$LOG"
      
      # Run pipeline in background. 
      # pipeline.sh manages its own logging to $LOG. 
      # We redirect stdout/stderr of the shell wrapper to /dev/null to avoid lock contention on the log file descriptor from the parent shell.
      ( cd "$ROOT" && "$WF/pipeline.sh" ) >/dev/null 2>&1 &
    fi
  fi
  sleep 2
done