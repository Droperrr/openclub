#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
WF="$ROOT/.opencode/workflow"
LOG="$WF/daemon.log"
PROMPT_DIR="$WF/.runtime"

MAX_ITERS="${MAX_ITERS:-5}"

# Ensure workflow directory exists
mkdir -p "$WF"
mkdir -p "$PROMPT_DIR"

# 1. Lock check
exec 9>"$WF/.lock"
if ! flock -n 9; then
  echo "[pipeline] another run is active, exiting $(date -Is)" >> "$LOG"
  exit 0
fi

RUN_ID_FILE="$WF/.selftest_run_id"
RUN_ID_VALUE="${RUN_ID:-}"
if [[ -z "$RUN_ID_VALUE" && -f "$RUN_ID_FILE" ]]; then
  RUN_ID_VALUE=$(tail -n 1 "$RUN_ID_FILE" | sed 's/^SELFTEST_RUN_ID=//')
fi
if [[ -z "$RUN_ID_VALUE" || "$RUN_ID_VALUE" == "unknown" ]]; then
  RUN_ID_VALUE="$(date +%Y%m%d_%H%M%S)_${RANDOM}"
fi

# Helper: extract critic verdict
critic_verdict() {
  if [[ -f "$WF/03_CRITIC_REPORT.md" ]]; then
    grep -iE '^VERDICT:' "$WF/03_CRITIC_REPORT.md" | tail -n 1 | tr -d '\r' || true
  fi
}

# Helper: ensure dialogue files exist without touching existing content
if [[ ! -f "$WF/DIALOGUE.md" ]]; then
  : > "$WF/DIALOGUE.md"
fi
if [[ ! -f "$WF/ISSUES.md" ]]; then
  : > "$WF/ISSUES.md"
fi

CHAT_MODE=0
if [[ -f "$WF/00_PM_REQUEST.md" ]] && head -n 1 "$WF/00_PM_REQUEST.md" | grep -q "^# Chat Request"; then
  CHAT_MODE=1
fi
if [[ "${OPENCODE_CHAT_ONLY:-0}" == "1" ]]; then
  CHAT_MODE=1
fi

extract_chat_body() {
  sed -n '1,/^$/d;p' "$WF/00_PM_REQUEST.md"
}

route_brainstorm_chat() {
  local body
  body="$(extract_chat_body)"
  if [[ -z "$body" ]]; then
    return 1
  fi

  local trimmed="$body"
  trimmed="${trimmed#${trimmed%%[![:space:]]*}}"

  local brainstorm_text=""
  local prefix_seen=0
  if [[ "$trimmed" == /brainstorm* ]]; then
    brainstorm_text="${trimmed#/brainstorm}"
    prefix_seen=1
  elif [[ "$trimmed" == brainstorm:* ]]; then
    brainstorm_text="${trimmed#brainstorm:}"
    prefix_seen=1
  fi

  brainstorm_text="${brainstorm_text#${brainstorm_text%%[![:space:]]*}}"
  if [[ $prefix_seen -eq 1 && -z "$brainstorm_text" ]]; then
    echo "FAIL: brainstorm requires text" >&2
    return 2
  fi
  if [[ -z "$brainstorm_text" ]]; then
    return 1
  fi

  bash "$WF/brainstorm_chat.sh" "$brainstorm_text"
  return 0
}

if [[ $CHAT_MODE -eq 1 ]]; then
  route_brainstorm_chat
  rc=$?
  if [[ $rc -eq 0 ]]; then
    exit 0
  elif [[ $rc -eq 2 ]]; then
    exit 2
  fi
fi

echo "[pipeline] start run_id=$RUN_ID_VALUE root=$ROOT $(date -Is) max_iters=$MAX_ITERS" >> "$LOG"

# Prompts generator
write_prompts() {
  local iter="$1"

  cat > "$PROMPT_DIR/prompt_orch_a.txt" <<P
MODE A (Generate tasks) [iter=$iter]:
Read .opencode/workflow/00_PM_REQUEST.md and STRATEGY_KNOWLEDGE_BASE.md.
Also read .opencode/workflow/ISSUES.md and .opencode/workflow/DIALOGUE.md (latest state).
Load skills: strategy-knowledge-base, stage1-spec, orchestration-protocol.
Write TASKS+COLLECT to .opencode/workflow/01_ARCH_TASKS.md.
If request is chat (00_PM_REQUEST starts with # Chat Request), ensure executor instructions reflect that the executor must create root-level files described in the request.
In chat: ACK only.
P

  cat > "$PROMPT_DIR/prompt_exec.txt" <<P
[iter=$iter] Executor:
Read 01_ARCH_TASKS.md + ISSUES.md + DIALOGUE.md + 00_PM_REQUEST.md.
Execute ONLY @executor section.
Write report to 02_EXECUTOR_REPORT.md with commands, outputs, and created files.
If blocked or needs clarification: write question to DIALOGUE.md (to:@critic or to:@orchestrator) and log an issue in ISSUES.md, then stop.
In chat: ACK only.
P

  cat > "$PROMPT_DIR/prompt_critic.txt" <<P
[iter=$iter] Critic:
Read 01_ARCH_TASKS.md + 02_EXECUTOR_REPORT.md + STRATEGY_KNOWLEDGE_BASE.md + ISSUES.md + DIALOGUE.md.
Verify vs skills strategy-knowledge-base + stage1-spec.
If you need more info from Executor/Auditor: ask in DIALOGUE.md (to:@executor or to:@auditor) and set VERDICT: request changes.
Write 03_CRITIC_REPORT.md. Also append mismatches to ISSUES.md with evidence.
In chat: ACK + VERDICT only.
P

  cat > "$PROMPT_DIR/prompt_auditor.txt" <<P
[iter=$iter] Auditor:
Read 01_ARCH_TASKS.md + 02_EXECUTOR_REPORT.md + STRATEGY_KNOWLEDGE_BASE.md + ISSUES.md + DIALOGUE.md.
Risk audit (timezone/percent math/rounding/limits/jsonl logging/hardcode portability).
If you need action/clarification: ask in DIALOGUE.md (to:@executor or to:@critic) and log P0/P1 in ISSUES.md.
Write 04_AUDITOR_REPORT.md.
In chat: ACK + P0/P1 count only.
P

  cat > "$PROMPT_DIR/prompt_orch_b.txt" <<P
MODE B (Final report) [iter=$iter]:
Read 02_EXECUTOR_REPORT.md, 03_CRITIC_REPORT.md, 04_AUDITOR_REPORT.md, ISSUES.md, DIALOGUE.md.
Write RU final report to 05_ARCH_FINAL_REPORT.md with evidence and verdict.
In chat: ACK only.
P
}

run_step() {
  local role="$1"
  local prompt_file="$2"
  
  echo "[pipeline] run role=$role prompt=$(basename "$prompt_file") start $(date -Is)" >> "$LOG"
  
  # Buffer output to temp file to prevent log corruption by agents
  local step_log="$PROMPT_DIR/step_${role}.log"
  : > "$step_log"
  
  # Capture exit code explicitly without triggering set -e immediate exit
  set +e
  timeout 600 "$WF/runner.sh" "$role" "$prompt_file" > "$step_log" 2>&1
  local rc=$?
  set -e

  # Append buffered log atomically
  cat "$step_log" >> "$LOG"
  rm -f "$step_log"

  if [[ $rc -ne 0 ]]; then
    echo "[pipeline] ERROR role=$role rc=$rc $(date -Is)" >> "$LOG"
    return $rc
  fi

  if [[ "$role" == "executor" && "${OPENCODE_SELFTEST_STUB:-0}" == "1" ]]; then
    printf "# Executor Report\n\nSelftest stub report.\n" > "$WF/02_EXECUTOR_REPORT.md"
  elif [[ "$role" == "executor" && ! -s "$WF/02_EXECUTOR_REPORT.md" ]]; then
    printf "# Executor Report\n\nRun report placeholder.\n" > "$WF/02_EXECUTOR_REPORT.md"
  fi

  echo "[pipeline] done role=$role $(date -Is)" >> "$LOG"
}

# Main loop
for ((iter=1; iter<=MAX_ITERS; iter++)); do
  echo "[pipeline] iter=$iter" >> "$LOG"
  write_prompts "$iter"
  
  run_step orchestrator "$PROMPT_DIR/prompt_orch_a.txt" || exit 2

  run_step executor     "$PROMPT_DIR/prompt_exec.txt"   || exit 3
  if [[ $CHAT_MODE -eq 0 ]]; then
    run_step critic       "$PROMPT_DIR/prompt_critic.txt" || exit 4
    run_step auditor      "$PROMPT_DIR/prompt_auditor.txt" || exit 5
  fi

  if [[ $CHAT_MODE -eq 0 ]]; then
    V="$(critic_verdict)"
    echo "[pipeline] iter=$iter critic_verdict='${V}'" >> "$LOG"

    if echo "$V" | grep -qi 'approve'; then
      run_step orchestrator "$PROMPT_DIR/prompt_orch_b.txt"
      echo "[pipeline] approved, done $(date -Is)" >> "$LOG"
      exit 0
    fi
  else
    echo "[pipeline] iter=$iter critic_verdict='skipped'" >> "$LOG"
    exit 0
  fi
  
  # if not approved, continue to next iteration
done

# Max iters reached
if [[ $CHAT_MODE -eq 0 ]]; then
  write_prompts "$MAX_ITERS"
  run_step orchestrator "$PROMPT_DIR/prompt_orch_b.txt"
  echo "[pipeline] max iters reached, final report written $(date -Is)" >> "$LOG"
  exit 1
fi
exit 0
