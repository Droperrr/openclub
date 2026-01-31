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
      local run_id=""
      if [[ -f "$WF/.selftest_run_id" ]]; then
        run_id=$(tail -n 1 "$WF/.selftest_run_id" | sed 's/^SELFTEST_RUN_ID=//')
      fi
      if [[ -z "$run_id" ]]; then
        run_id="$(date +%Y%m%d_%H%M%S)_${RANDOM}"
        echo "SELFTEST_RUN_ID=$run_id" > "$WF/.selftest_run_id"
      fi
      echo "[daemon] change detected -> trigger pipeline run_id=$run_id $(date -Is)" >> "$LOG"
      
      # Run pipeline in background. 
      # pipeline.sh manages its own logging to $LOG. 
      # We redirect stdout/stderr of the shell wrapper to /dev/null to avoid lock contention on the log file descriptor from the parent shell.
      ( cd "$ROOT" && RUN_ID="$run_id" "$WF/pipeline.sh" ) >/dev/null 2>&1 &
    fi
  fi
  sleep 2
done