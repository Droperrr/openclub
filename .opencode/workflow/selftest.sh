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

LOG_WINDOW_START_BYTES=0
INFRA_START=0
INFRA_ORCH_DONE=0
INFRA_EXEC_DONE=0
APPROVED=0
DAEMON_WAS_RUNNING=0
OC_STUB_PATH=""
PRE_ISSUES_PATH=""
PRE_ISSUES_LINES=0

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
  local log_window_start
  log_window_start="$(date -Is)"
  echo "[selftest] LOG_WINDOW_START=$log_window_start" >> "$LOG"
  LOG_WINDOW_START_BYTES=$(wc -c < "$LOG" 2>/dev/null || echo 0)
  echo "[selftest] START_MARKER_$(date +%s)" >> "$LOG"
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

trigger_flood() {
  echo "[TEST] Triggering flood (10x)..."
  for i in {1..10}; do
    printf "\nSELFTEST FLOOD %s: %s\n" "$i" "$(date -Is)" >> "$WF/00_PM_REQUEST.md"
    sleep 1
  done
}

setup_oc_stub() {
  if [[ "$MODE" != "infra" ]]; then
    return 0
  fi
  OC_STUB_PATH="$WF/oc_stub"
  mkdir -p "$OC_STUB_PATH"
  cat > "$OC_STUB_PATH/oc" <<'PY'
#!/usr/bin/env python3
import sys
if __name__ == "__main__":
    print("ACK")
    sys.exit(0)
PY
  chmod +x "$OC_STUB_PATH/oc"
  export PATH="$OC_STUB_PATH:$PATH"
}

teardown_oc_stub() {
  if [[ -n "$OC_STUB_PATH" ]]; then
    rm -rf "$OC_STUB_PATH"
  fi
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

    window_content=$(log_window)

    if [[ $INFRA_START -eq 0 ]] && echo "$window_content" | grep -aq "\[pipeline\] start\|\[pipeline\] run role=orchestrator"; then
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
  if log_window | grep -aq "another run is active, exiting"; then
    echo "PASS: Single-flight contention detected in log."
    rm -f "$test_log"
    return 0
  fi
  if grep -aq "another run is active, exiting" "$test_log"; then
    echo "PASS: Single-flight contention detected in pipeline output."
    rm -f "$test_log"
    return 0
  fi
  echo "FAIL: No single-flight contention detected in log/output."
  rm -f "$test_log"
  return 1
}

check_artifacts_infra() {
  if [[ ! -s "$WF/02_EXECUTOR_REPORT.md" ]]; then
    echo "FAIL: Artifact 02_EXECUTOR_REPORT.md missing or empty."
    return 1
  fi
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
  if log_window | grep -aqE "Permission required|Terminated|opencode run \[message\.\.\]|ERROR.*rc=0"; then
    echo "FAIL: Forbidden patterns found in current log window."
    return 1
  fi
  return 0
}

check_single_flight() {
  if log_window | grep -aq "another run is active, exiting"; then
    echo "PASS: Single-flight contention detected in log."
    return 0
  fi
  echo "FAIL: No single-flight contention detected in log."
  return 1
}

# --- Main Execution ---

backup_state
cleanup_state
snapshot_issues_prefix

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

echo "OPENCODE TEAM VERSION: ${TEAM_VERSION}"
echo "=== SELFTEST v2.1 START: $(date -Is) ==="
echo "ROOT=$ROOT"
echo "MODE=$MODE"
echo "DESTRUCTIVE=$DESTRUCTIVE"
echo "WAIT=$TIMEOUT"

if [[ "$MODE" == "infra" ]]; then
  set +e
  timeout "$TIMEOUT" bash "$WF/pipeline.sh" >/dev/null 2>&1
  local_rc=$?
  set -e
  if [[ $local_rc -eq 124 ]]; then
    echo "TIMEOUT reached."
  fi
  wait_for_infra_milestones
  test_single_flight_deterministic
else
  trigger_flood
  wait_for_infra_milestones
fi

if [[ "$MODE" == "green" && $APPROVED -eq 0 ]]; then
  echo "FAIL: approved, done not found."
  echo "FAIL: 05 ignored because not from current run."
fi

EXIT_CODE=0
if ! check_forbidden; then EXIT_CODE=1; fi
if ! check_issues_prefix; then EXIT_CODE=1; fi

if [[ "$MODE" == "infra" ]]; then
  if [[ $INFRA_START -eq 0 || $INFRA_ORCH_DONE -eq 0 || $INFRA_EXEC_DONE -eq 0 ]]; then EXIT_CODE=1; fi
  if ! check_single_flight; then EXIT_CODE=1; fi
  if ! check_artifacts_infra; then EXIT_CODE=1; fi
  if [[ $EXIT_CODE -eq 0 ]]; then echo "SELFTEST PASS: INFRA"; else echo "SELFTEST FAIL: INFRA"; fi
elif [[ "$MODE" == "green" ]]; then
  if [[ $APPROVED -eq 0 ]]; then EXIT_CODE=1; fi
  if [[ $APPROVED -eq 1 ]]; then
    if ! check_artifacts_green; then EXIT_CODE=1; fi
  fi
  if [[ $EXIT_CODE -eq 0 ]]; then echo "SELFTEST PASS: GREEN"; else echo "SELFTEST FAIL: GREEN"; fi
fi

teardown_oc_stub

if [[ $DESTRUCTIVE -eq 0 && $DAEMON_WAS_RUNNING -eq 0 ]]; then
  "$WF/daemon_ctl.sh" stop >/dev/null 2>&1 || true
fi

exit $EXIT_CODE
