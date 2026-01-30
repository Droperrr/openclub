#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
ROOT="$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")"
WF=".opencode/workflow"
LOG="$WF/daemon.log"
TIMEOUT="${SELFTEST_TIMEOUT:-1800}"
DESTRUCTIVE=0
MODE="infra"

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --destructive) DESTRUCTIVE=1; shift ;;
    --mode) MODE="$2"; shift 2 ;;
    --wait) TIMEOUT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

cd "$ROOT" || exit 1

VERSION_FILE=".opencode/VERSION"
TEAM_VERSION=""
if [[ -f "$VERSION_FILE" ]]; then
  TEAM_VERSION=$(head -n 1 "$VERSION_FILE" | tr -d '\r')
fi

RUN_ID=""
OC_VERSION=""
OPENCODE_VERSION=""
RUN_ID_LINE=""
RUN_ID_FILE=""
PRE_EXEC_REPORT_EMPTY=0

LOG_WINDOW_START_BYTES=0
INFRA_START=0
INFRA_ORCH_DONE=0
INFRA_EXEC_DONE=0
APPROVED=0
DAEMON_WAS_RUNNING=0
OC_STUB_PATH=""
PRE_ISSUES_PATH=""
PRE_ISSUES_LINES=0
PRE_DIALOGUE_PATH=""
PRE_DIALOGUE_LINES=0

backup_state() {
  if [[ $DESTRUCTIVE -eq 1 ]]; then
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local bak="$WF/_selftest_backup/$ts"
    echo "[SETUP] Backing up state to $bak..."
    mkdir -p "$bak"
    [ -f "$LOG" ] && cp "$LOG" "$bak/" || true
    [ -d "$WF" ] && cp "$WF"/0{1,2,3,4,5}_*.md "$bak/" 2>/dev/null || true
  fi
}

cleanup_state() {
  if [[ $DESTRUCTIVE -eq 1 ]]; then
  echo "[SETUP] Cleaning state (DESTRUCTIVE MODE)..."
  rm -f "$WF/.lock"
  rm -f "$WF/.step_"*.log
  rm -f "$WF/.pm_request_hash"
  rm -f "$WF/.daemon.pid"
  rm -f "$WF/0"{1,2,3,4,5}_*.md
  rm -rf "$WF/_selftest_backup"
  rm -rf __pycache__ core/__pycache__ infrastructure/__pycache__
  rm -f *.pyc core/*.pyc infrastructure/*.pyc
  rm -f logs/events.jsonl
  rm -f "$LOG"

  else
    echo "[SETUP] Non-destructive mode. Keeping existing files."
  fi
}

prepare_log_window() {
  mkdir -p "$WF"
  touch "$LOG"
  LOG_WINDOW_START_BYTES=$(wc -c < "$LOG" 2>/dev/null || echo 0)
}

snapshot_issues_prefix() {
  if [[ -f "$WF/ISSUES.md" ]]; then
    PRE_ISSUES_PATH="$(mktemp)"
    cp "$WF/ISSUES.md" "$PRE_ISSUES_PATH"
    PRE_ISSUES_LINES=$(wc -l < "$WF/ISSUES.md" | tr -d ' ')
  else
    PRE_ISSUES_LINES=0
  fi
}

snapshot_dialogue_prefix() {
  if [[ -f "$WF/DIALOGUE.md" ]]; then
    PRE_DIALOGUE_PATH="$(mktemp)"
    cp "$WF/DIALOGUE.md" "$PRE_DIALOGUE_PATH"
    PRE_DIALOGUE_LINES=$(wc -l < "$WF/DIALOGUE.md" | tr -d ' ')
  else
    PRE_DIALOGUE_LINES=0
  fi
}

check_issues_prefix() {
  if [[ -z "$PRE_ISSUES_PATH" ]]; then
    return 0
  fi
  local current_lines
  current_lines=$(wc -l < "$WF/ISSUES.md" | tr -d ' ')
  if [[ "$current_lines" -lt "$PRE_ISSUES_LINES" ]]; then
    echo "FAIL: ISSUES.md line count decreased (append-only violation)."
    return 1
  fi
  if ! diff -q "$PRE_ISSUES_PATH" "$WF/ISSUES.md" >/dev/null 2>&1; then
    if ! diff -q "$PRE_ISSUES_PATH" <(head -n "$PRE_ISSUES_LINES" "$WF/ISSUES.md") >/dev/null 2>&1; then
      echo "FAIL: ISSUES.md pre-run content not preserved as prefix."
      return 1
    fi
  fi
  return 0
}

check_dialogue_prefix() {
  if [[ -z "$PRE_DIALOGUE_PATH" ]]; then
    return 0
  fi
  local current_lines
  current_lines=$(wc -l < "$WF/DIALOGUE.md" | tr -d ' ')
  if [[ "$current_lines" -lt "$PRE_DIALOGUE_LINES" ]]; then
    echo "FAIL: DIALOGUE.md line count decreased (append-only violation)."
    return 1
  fi
  if ! diff -q "$PRE_DIALOGUE_PATH" "$WF/DIALOGUE.md" >/dev/null 2>&1; then
    if ! diff -q "$PRE_DIALOGUE_PATH" <(head -n "$PRE_DIALOGUE_LINES" "$WF/DIALOGUE.md") >/dev/null 2>&1; then
      echo "FAIL: DIALOGUE.md pre-run content not preserved as prefix."
      return 1
    fi
  fi
  return 0
}

log_window() {
  if [[ ! -f "$LOG" ]]; then
    return 0
  fi
  python3 - <<PY
from pathlib import Path
import sys
start = int("${LOG_WINDOW_START_BYTES}" or 0)
path = Path(".opencode/workflow/daemon.log")
with path.open('rb') as f:
    f.seek(start)
    data = f.read().replace(b"\x00", b"")
try:
    sys.stdout.write(data.decode('utf-8'))
except Exception:
    sys.stdout.write(data.decode('utf-8', errors='ignore'))
PY
}

log_window_run() {
  if [[ ! -f "$LOG" ]]; then
    return 0
  fi
  if [[ -z "$RUN_ID" ]]; then
    return 0
  fi
  python3 - <<PY
from pathlib import Path
import sys
run_id = "${RUN_ID}"
root = "${ROOT}"
path = Path(".opencode/workflow/daemon.log")
if not path.exists():
    sys.exit(0)
with path.open('r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()
indices = [i for i, line in enumerate(lines) if f"[pipeline] start" in line and f"run_id={run_id}" in line and f"root={root}" in line]
if not indices:
    sys.exit(0)
start = indices[0]
sys.stdout.write("".join(lines[start:]))
PY
}

trigger_flood() {
  echo "[TEST] Triggering flood (10x)..."
  for i in {1..10}; do
    printf "\nSELFTEST FLOOD %s: %s\n" "$i" "$(date -Is)" >> "$WF/00_PM_REQUEST.md"
    sleep 1
  done
}

setup_oc_stub() {
  return 0
}

teardown_oc_stub() {
  return 0
}

wait_for_infra_milestones() {
  echo "[TEST] Waiting for pipeline cycle (max $TIMEOUT s)..."
  local start_ts
  start_ts=$(date +%s)

  while true; do
    local current_ts elapsed window_content
    current_ts=$(date +%s)
    elapsed=$((current_ts - start_ts))

    if [[ $elapsed -gt $TIMEOUT ]]; then
      echo "TIMEOUT reached."
      break
    fi

    window_content=$(log_window_run)

    if [[ $INFRA_START -eq 0 ]] && echo "$window_content" | grep -aq "\[pipeline\] start"; then
      INFRA_START=1
      echo "[PROG] Pipeline start detected."
    fi

    if [[ $INFRA_ORCH_DONE -eq 0 ]] && echo "$window_content" | grep -aq "done role=orchestrator"; then
      INFRA_ORCH_DONE=1
      echo "[PROG] Orchestrator done detected."
    fi

    if [[ $INFRA_EXEC_DONE -eq 0 ]] && echo "$window_content" | grep -aq "done role=executor"; then
      INFRA_EXEC_DONE=1
      echo "[PROG] Executor done detected."
    fi

    if [[ "$MODE" == "green" ]] && echo "$window_content" | grep -aq "approved, done"; then
      APPROVED=1
      echo "[PROG] 'approved, done' detected!"
      break
    fi

    if [[ "$MODE" == "infra" && $INFRA_START -eq 1 && $INFRA_ORCH_DONE -eq 1 && $INFRA_EXEC_DONE -eq 1 ]]; then
      echo "[PROG] Infra milestones met (start/orchestrator/executor). Stopping wait."
      break
    fi

    if (( elapsed % 10 == 0 )); then
      local last_m
      last_m=$(echo "$window_content" | grep -aE "\[pipeline\]" | tail -n 1 || echo "Waiting...")
      echo "Wait ${elapsed}s... Found: $last_m"
    fi

    sleep 2
  done
}

test_single_flight_deterministic() {
  echo "[TEST] Single-flight deterministic lock check..."
  local test_log
  test_log=$(mktemp)
  local start_ts
  start_ts=$(date +%s)
  (
    flock -x 9
    sleep 8
  ) 9>"$WF/.lock" &
  local lock_pid=$!
  sleep 1
  set +e
  timeout 3 bash "$WF/pipeline.sh" >"$test_log" 2>&1
  local rc=$?
  set -e
  kill "$lock_pid" 2>/dev/null || true
  wait "$lock_pid" 2>/dev/null || true
  local elapsed
  elapsed=$(( $(date +%s) - start_ts ))

  if [[ $rc -eq 124 || $elapsed -gt 3 ]]; then
    echo "FAIL: Single-flight pipeline run exceeded 3s (rc=$rc, elapsed=${elapsed}s)."
    rm -f "$test_log"
    return 1
  fi
  if grep -aq "another run is active, exiting" "$test_log" || log_window_run | grep -aq "another run is active, exiting"; then
    echo "PASS: Single-flight contention detected in log."
    rm -f "$test_log"
    return 0
  fi
  echo "FAIL: No single-flight contention detected in log/output."
  rm -f "$test_log"
  return 1

}

check_artifacts_infra() {
  local start_ts
  start_ts=$(date +%s)
  if [[ $PRE_EXEC_REPORT_EMPTY -eq 1 ]]; then
    echo "INFRA FAIL: 02_EXECUTOR_REPORT.md missing or empty"
    return 1
  fi
  while true; do
    if [[ -s "$WF/02_EXECUTOR_REPORT.md" ]]; then
      break
    fi
    if (( $(date +%s) - start_ts >= 20 )); then
      echo "INFRA FAIL: 02_EXECUTOR_REPORT.md missing or empty"
      return 1
    fi
    sleep 1
  done
  for f in 03_CRITIC_REPORT.md 04_AUDITOR_REPORT.md 05_ARCH_FINAL_REPORT.md; do
    if [[ ! -s "$WF/$f" ]]; then
      echo "[selftest] WARNING: Artifact $f missing or empty in infra mode."
    fi
  done
  return 0
}

check_artifacts_green() {
  local missing=0
  for f in 02_EXECUTOR_REPORT.md 03_CRITIC_REPORT.md 04_AUDITOR_REPORT.md 05_ARCH_FINAL_REPORT.md; do
    if [[ ! -s "$WF/$f" ]]; then
      echo "FAIL: Artifact $f missing or empty."
      missing=1
    fi
  done
  return $missing
}

check_forbidden() {
  if log_window_run | grep -aqE "Permission required|Terminated|opencode run \[message\.\.\]|ERROR.*rc=0"; then
    echo "FAIL: Forbidden patterns found in current log window."
    return 1
  fi
  return 0
}

check_single_flight() {
  if log_window_run | grep -aq "another run is active, exiting"; then
    return 0
  fi
  return 1
}

# --- Main Execution ---

backup_state
cleanup_state
snapshot_issues_prefix
snapshot_dialogue_prefix

DAEMON_WAS_RUNNING=0
if [[ $DESTRUCTIVE -eq 0 ]] && "$WF/daemon_ctl.sh" status | grep -q "running"; then
  DAEMON_WAS_RUNNING=1
  "$WF/daemon_ctl.sh" stop >/dev/null 2>&1 || true
fi

if [[ "$MODE" == "green" ]]; then
  "$WF/daemon_ctl.sh" start
  sleep 2
fi

setup_oc_stub
prepare_log_window

  RUN_ID="$(date +%Y%m%d_%H%M%S)_${RANDOM}"
  RUN_ID_FILE="$WF/.selftest_run_id"
  echo "SELFTEST_RUN_ID=$RUN_ID" > "$RUN_ID_FILE"
  RUN_ID_LINE="[pipeline] run_id=$RUN_ID"
  if [[ -f "$WF/02_EXECUTOR_REPORT.md" && ! -s "$WF/02_EXECUTOR_REPORT.md" ]]; then
    PRE_EXEC_REPORT_EMPTY=1
  fi

  echo "OPENCODE TEAM VERSION: ${TEAM_VERSION}"
  if command -v oc >/dev/null 2>&1; then
    OC_VERSION=$(oc --version 2>/dev/null | head -n 1 | tr -d '\r')
    echo "OC VERSION: ${OC_VERSION:-unknown}"
  else
    echo "FAIL: oc not found in PATH"
    if [[ "$MODE" == "infra" ]]; then
      echo "SELFTEST FAIL: INFRA"
    else
      echo "SELFTEST FAIL: GREEN"
    fi
    exit 1
  fi
  if command -v oc >/dev/null 2>&1; then
    OPENCODE_VERSION=$(oc opencode --version 2>/dev/null | head -n 1 | tr -d '\r')
    if [[ -z "$OPENCODE_VERSION" ]]; then
      OPENCODE_VERSION="$TEAM_VERSION"
    fi
  else
    OPENCODE_VERSION="$TEAM_VERSION"
  fi
  if [[ -z "$OPENCODE_VERSION" ]]; then
    OPENCODE_VERSION="unknown"
  fi
  echo "OPENCODE VERSION: ${OPENCODE_VERSION}"

  echo "=== SELFTEST v2.1 START: $(date -Is) ==="
  echo "ROOT=$ROOT"
  echo "MODE=$MODE"
  echo "DESTRUCTIVE=$DESTRUCTIVE"
  echo "WAIT=$TIMEOUT"
  echo "RUN_ID=$RUN_ID"

  EXIT_CODE=0
  if [[ "$MODE" == "infra" ]]; then
    set +e
    RUN_ID="$RUN_ID" OPENCODE_SELFTEST_STUB=1 bash "$WF/pipeline.sh" >/dev/null 2>&1
    local_rc=$?
    set -e
    if [[ $local_rc -ne 0 ]]; then
      echo "FAIL: pipeline returned rc=$local_rc"
      EXIT_CODE=1
    fi
    wait_for_infra_milestones
    if ! test_single_flight_deterministic; then EXIT_CODE=1; fi
  else
    trigger_flood
    wait_for_infra_milestones
  fi



if ! log_window_run | grep -aq "\[pipeline\] start"; then
  echo "FAIL: run_id/root start marker not found in log."
  EXIT_CODE=1
fi

if [[ "$MODE" == "green" && $APPROVED -eq 0 ]]; then
  echo "FAIL: approved, done not found."
  echo "FAIL: 05 ignored because not from current run."
  EXIT_CODE=1
fi

if ! check_forbidden; then EXIT_CODE=1; fi
if ! check_issues_prefix; then EXIT_CODE=1; fi
if ! check_dialogue_prefix; then EXIT_CODE=1; fi

  if [[ "$MODE" == "infra" ]]; then
  if [[ $INFRA_START -eq 0 || $INFRA_ORCH_DONE -eq 0 || $INFRA_EXEC_DONE -eq 0 ]]; then EXIT_CODE=1; fi
  if ! check_artifacts_infra; then EXIT_CODE=1; fi
  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "SELFTEST PASS: INFRA"
  else
    echo "SELFTEST FAIL: INFRA"
  fi

elif [[ "$MODE" == "green" ]]; then
  if [[ $APPROVED -eq 0 ]]; then EXIT_CODE=1; fi
  if [[ $APPROVED -eq 1 ]]; then
    if ! check_artifacts_green; then EXIT_CODE=1; fi
  fi
  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "SELFTEST PASS: GREEN"
  else
    echo "SELFTEST FAIL: GREEN"
  fi
else
  echo "SELFTEST FAIL: INFRA"
  EXIT_CODE=1
fi

teardown_oc_stub

if [[ $DESTRUCTIVE -eq 0 && $DAEMON_WAS_RUNNING -eq 0 ]]; then
  "$WF/daemon_ctl.sh" stop >/dev/null 2>&1 || true
fi

exit $EXIT_CODE
