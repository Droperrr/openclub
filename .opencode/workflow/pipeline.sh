#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
WF="$ROOT/.opencode/workflow"
LOG="$WF/daemon.log"

MAX_ITERS="${MAX_ITERS:-5}"

# Ensure workflow directory exists
mkdir -p "$WF"

# 1. Lock check
exec 9>"$WF/.lock"
if ! flock -n 9; then
  echo "[pipeline] another run is active, exiting $(date -Is)" >> "$LOG"
  exit 0
fi

echo "[pipeline] start $(date -Is) max_iters=$MAX_ITERS" >> "$LOG"

# Helper: extract critic verdict
critic_verdict() {
  if [[ -f "$WF/03_CRITIC_REPORT.md" ]]; then
    grep -iE '^VERDICT:' "$WF/03_CRITIC_REPORT.md" | tail -n 1 | tr -d '\r' || true
  fi
}

# Helper: reset per-run dialogue markers
touch "$WF/DIALOGUE.md" "$WF/ISSUES.md"

# Prompts generator
write_prompts() {
  local iter="$1"

  cat > "$WF/.prompt_orch_a.txt" <<P
MODE A (Generate tasks) [iter=$iter]:
Read .opencode/workflow/00_PM_REQUEST.md and STRATEGY_KNOWLEDGE_BASE.md.
Also read .opencode/workflow/ISSUES.md and .opencode/workflow/DIALOGUE.md (latest state).
Load skills: strategy-knowledge-base, stage1-spec, orchestration-protocol.
Write TASKS+COLLECT to .opencode/workflow/01_ARCH_TASKS.md.
In chat: ACK only.
P

  cat > "$WF/.prompt_exec.txt" <<P
[iter=$iter] Executor:
Read 01_ARCH_TASKS.md + ISSUES.md + DIALOGUE.md.
Execute ONLY @executor section.
Write report to 02_EXECUTOR_REPORT.md.
If blocked or needs clarification: write question to DIALOGUE.md (to:@critic or to:@orchestrator) and log an issue in ISSUES.md, then stop.
In chat: ACK only.
P

  cat > "$WF/.prompt_critic.txt" <<P
[iter=$iter] Critic:
Read 01_ARCH_TASKS.md + 02_EXECUTOR_REPORT.md + STRATEGY_KNOWLEDGE_BASE.md + ISSUES.md + DIALOGUE.md.
Verify vs skills strategy-knowledge-base + stage1-spec.
If you need more info from Executor/Auditor: ask in DIALOGUE.md (to:@executor or to:@auditor) and set VERDICT: request changes.
Write 03_CRITIC_REPORT.md. Also append mismatches to ISSUES.md with evidence.
In chat: ACK + VERDICT only.
P

  cat > "$WF/.prompt_auditor.txt" <<P
[iter=$iter] Auditor:
Read 01_ARCH_TASKS.md + 02_EXECUTOR_REPORT.md + STRATEGY_KNOWLEDGE_BASE.md + ISSUES.md + DIALOGUE.md.
Risk audit (timezone/percent math/rounding/limits/jsonl logging/hardcode portability).
If you need action/clarification: ask in DIALOGUE.md (to:@executor or to:@critic) and log P0/P1 in ISSUES.md.
Write 04_AUDITOR_REPORT.md.
In chat: ACK + P0/P1 count only.
P

  cat > "$WF/.prompt_orch_b.txt" <<P
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
  local step_log="$WF/.step_${role}.log"
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
  
  echo "[pipeline] done role=$role $(date -Is)" >> "$LOG"
}

# Main loop
for ((iter=1; iter<=MAX_ITERS; iter++)); do
  echo "[pipeline] iter=$iter" >> "$LOG"
  write_prompts "$iter"
  
  run_step orchestrator "$WF/.prompt_orch_a.txt" || exit 2
  run_step executor     "$WF/.prompt_exec.txt"   || exit 3
  run_step critic       "$WF/.prompt_critic.txt" || exit 4
  run_step auditor      "$WF/.prompt_auditor.txt" || exit 5

  V="$(critic_verdict)"
  echo "[pipeline] iter=$iter critic_verdict='${V}'" >> "$LOG"

  if echo "$V" | grep -qi 'approve'; then
    run_step orchestrator "$WF/.prompt_orch_b.txt"
    echo "[pipeline] approved, done $(date -Is)" >> "$LOG"
    exit 0
  fi
  
  # if not approved, continue to next iteration
done

# Max iters reached
write_prompts "$MAX_ITERS"
run_step orchestrator "$WF/.prompt_orch_b.txt"
echo "[pipeline] max iters reached, final report written $(date -Is)" >> "$LOG"
exit 1