#!/usr/bin/env bash
set -euo pipefail

SESSION_ID="${1:?session id required}"
SESSION_DIR="${2:?session dir required}"
PROMPT_TEXT="${3:?prompt text required}"
PRINT_TRANSCRIPT=1
TAIL_LINES=""
NO_COLOR=0

ROOT="$(pwd)"
WF="$ROOT/.opencode/workflow"
LOG="$WF/daemon.log"
CONFIG_FILE="$ROOT/.opencode/config/brainstorm.yml"

if [[ $# -gt 3 ]]; then
  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quiet)
        PRINT_TRANSCRIPT=0
        shift
        ;;
      --tail)
        if [[ -z "${2:-}" ]]; then
          echo "FAIL: --tail requires a number" >&2
          exit 1
        fi
        if ! [[ "$2" =~ ^[0-9]+$ ]]; then
          echo "FAIL: --tail expects a number" >&2
          exit 1
        fi
        TAIL_LINES="$2"
        shift 2
        ;;
      --no-color)
        NO_COLOR=1
        shift
        ;;
      *)
        echo "FAIL: unknown option $1" >&2
        exit 1
        ;;
    esac
  done
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "FAIL: brainstorm config not found: $CONFIG_FILE" >&2
  exit 1
fi

if ! command -v oc >/dev/null 2>&1; then
  echo "FAIL: 'oc' not found in PATH" >&2
  exit 1
fi

trim_value() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  value="${value#\"}"
  value="${value%\"}"
  value="${value#\'}"
  value="${value%\'}"
  printf "%s" "$value"
}

ROLES=()
MODEL_A_CONFIG=""
MODEL_B_CONFIG=""
MIN_LENGTH_CHARS=""
SYNTHESIS_MIN_CHARS=""
MAX_ATTEMPTS=""
MODEL_TIMEOUT_SEC=""
PARSE_MODE=""

while IFS= read -r raw_line; do
  line="${raw_line%%#*}"
  if [[ -z "${line//[[:space:]]/}" ]]; then
    continue
  fi
  if [[ "$line" =~ ^roles: ]]; then
    PARSE_MODE="roles"
    continue
  fi
  if [[ "$line" =~ ^models: ]]; then
    PARSE_MODE="models"
    continue
  fi
  if [[ "$line" =~ ^min_length_chars: ]]; then
    value="${line#*:}"
    MIN_LENGTH_CHARS="$(trim_value "$value")"
    continue
  fi
  if [[ "$line" =~ ^synthesis_min_chars: ]]; then
    value="${line#*:}"
    SYNTHESIS_MIN_CHARS="$(trim_value "$value")"
    continue
  fi
  if [[ "$line" =~ ^max_attempts: ]]; then
    value="${line#*:}"
    MAX_ATTEMPTS="$(trim_value "$value")"
    continue
  fi
  if [[ "$line" =~ ^model_timeout_sec: ]]; then
    value="${line#*:}"
    MODEL_TIMEOUT_SEC="$(trim_value "$value")"
    continue
  fi
  if [[ "$PARSE_MODE" == "roles" && "$line" =~ ^[[:space:]]*-[[:space:]]* ]]; then
    role="${line#*- }"
    role="$(trim_value "$role")"
    if [[ -n "$role" ]]; then
      ROLES+=("$role")
    fi
    continue
  fi
  if [[ "$PARSE_MODE" == "models" ]]; then
    if [[ "$line" =~ ^[[:space:]]*modelA: ]]; then
      value="${line#*:}"
      MODEL_A_CONFIG="$(trim_value "$value")"
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*modelB: ]]; then
      value="${line#*:}"
      MODEL_B_CONFIG="$(trim_value "$value")"
      continue
    fi
  fi

done < "$CONFIG_FILE"

if [[ ${#ROLES[@]} -eq 0 ]]; then
  echo "FAIL: brainstorm config missing roles" >&2
  exit 1
fi
if [[ -z "$MODEL_A_CONFIG" ]]; then
  echo "FAIL: brainstorm config missing modelA" >&2
  exit 1
fi
if [[ -z "$MIN_LENGTH_CHARS" || -z "$SYNTHESIS_MIN_CHARS" ]]; then
  echo "FAIL: brainstorm config missing min_length_chars or synthesis_min_chars" >&2
  exit 1
fi
if [[ -z "$MAX_ATTEMPTS" ]]; then
  MAX_ATTEMPTS="2"
fi
if [[ -z "$MODEL_TIMEOUT_SEC" ]]; then
  MODEL_TIMEOUT_SEC="120"
fi

AVAILABLE_MODELS=()
while IFS= read -r model; do
  if [[ -n "$model" ]]; then
    AVAILABLE_MODELS+=("$model")
  fi
done < <(oc opencode models 2>/dev/null || true)

model_available() {
  local target="$1"
  for available in "${AVAILABLE_MODELS[@]}"; do
    if [[ "$available" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

MODEL_A="$MODEL_A_CONFIG"
if ! model_available "$MODEL_A"; then
  echo "FAIL: modelA not available: $MODEL_A" >&2
  exit 1
fi

MODEL_B=""
MODEL_B_REASON=""
if [[ -z "$MODEL_B_CONFIG" ]]; then
  MODEL_B_REASON="not configured"
else
  if model_available "$MODEL_B_CONFIG"; then
    MODEL_B="$MODEL_B_CONFIG"
  else
    MODEL_B_REASON="not in models list"
  fi
fi

MODEL_A_LABEL="modelA"
MODEL_B_LABEL="modelB"
MODEL_A_LABEL_ID="$MODEL_A"
MODEL_B_LABEL_ID="${MODEL_B_CONFIG:-NONE}"

mkdir -p "$SESSION_DIR"

STARTED_AT="$(date -Is)"
ROLE_LIST=$(IFS=,; printf "%s" "${ROLES[*]}")
META_FILE="$SESSION_DIR/01_META.md"
{
  printf "# Brainstorm Meta\n"
  printf "session_id=%s\n" "$SESSION_ID"
  printf "root=%s\n" "$ROOT"
  printf "started_at=%s\n" "$STARTED_AT"
  printf "roles=%s\n" "$ROLE_LIST"
  printf "modelA=%s\n" "$MODEL_A"
  if [[ -n "$MODEL_B" ]]; then
    printf "modelB=%s\n" "$MODEL_B"
  else
    printf "modelB=NONE\n"
  fi
  printf "min_length_chars=%s\n" "$MIN_LENGTH_CHARS"
  printf "synthesis_min_chars=%s\n" "$SYNTHESIS_MIN_CHARS"
} > "$META_FILE"

ROLE_PROMPT="You are participating in a brainstorm session. Provide concise, actionable ideas and risks."

run_with_prompt() {
  local model_id="$1"
  local prompt="$2"
  local output_file="$3"
  timeout "$MODEL_TIMEOUT_SEC" oc opencode run --model "$model_id" "$prompt" > "$output_file" 2>&1
}

append_for_length() {
  local model_id="$1"
  local output_file="$2"
  local min_len="$3"
  local base_prompt="$4"
  local attempts=0

  while true; do
    local current_len
    current_len=$(wc -c < "$output_file" | tr -d ' ')
    if [[ "$current_len" -ge "$min_len" ]]; then
      return 0
    fi
    if [[ $attempts -ge $((MAX_ATTEMPTS - 1)) ]]; then
      return 1
    fi
    attempts=$((attempts + 1))
    local previous
    previous="$(cat "$output_file")"
    local expand_prompt
    expand_prompt="${base_prompt}\n\nPrevious response:\n${previous}\n\nExpand with more detail, concrete steps, and risks. Add new content only. Ensure the total length is at least ${min_len} characters."
    timeout "$MODEL_TIMEOUT_SEC" oc opencode run --model "$model_id" "$expand_prompt" >> "$output_file" 2>&1 || return 1
  done
}

write_skipped() {
  local output_file="$1"
  local reason="$2"
  printf "SKIPPED: modelB not available\nreason: %s\n" "$reason" > "$output_file"
}

run_role_model() {
  local role="$1"
  local model_id="$2"
  local model_label="$3"
  local output_file="$SESSION_DIR/10_${role}_${model_label}.md"
  local min_len="$MIN_LENGTH_CHARS"

  if [[ -z "$model_id" ]]; then
    write_skipped "$output_file" "$MODEL_B_REASON"
    echo "[brainstorm] role=$role model=$model_label done" >> "$LOG"
    return 0
  fi

  local prompt
  prompt="Role: ${role}. ${ROLE_PROMPT}\nMinimum length: ${min_len} characters. Do not respond with acknowledgements. Provide 3-5 ideas, risks, and recommendations.\n\nPrompt:\n${PROMPT_TEXT}\n"

  echo "[brainstorm] role=$role model=$model_label start" >> "$LOG"
  if run_with_prompt "$model_id" "$prompt" "$output_file"; then
    if append_for_length "$model_id" "$output_file" "$min_len" "$prompt"; then
      echo "[brainstorm] role=$role model=$model_label done" >> "$LOG"
      return 0
    fi
  fi

  if [[ "$model_label" == "$MODEL_B_LABEL" ]]; then
    write_skipped "$output_file" "call failed or output too short"
    echo "[brainstorm] role=$role model=$model_label done rc=1" >> "$LOG"
    return 0
  fi

  echo "[brainstorm] ERROR role=$role model=$model_label failed" >> "$LOG"
  return 1
}

TRANSCRIPT_FILE="$SESSION_DIR/99_TRANSCRIPT.md"
: > "$TRANSCRIPT_FILE"

for role in "${ROLES[@]}"; do
  run_role_model "$role" "$MODEL_A" "$MODEL_A_LABEL" || exit 2
  run_role_model "$role" "$MODEL_B" "$MODEL_B_LABEL" || exit 2

done

for role in "${ROLES[@]}"; do
  output_file_a="$SESSION_DIR/10_${role}_${MODEL_A_LABEL}.md"
  printf "### [%s@%s:%s]\n\n" "$role" "$MODEL_A_LABEL" "$MODEL_A_LABEL_ID" >> "$TRANSCRIPT_FILE"
  cat "$output_file_a" >> "$TRANSCRIPT_FILE"
  printf "\n\n" >> "$TRANSCRIPT_FILE"

  output_file_b="$SESSION_DIR/10_${role}_${MODEL_B_LABEL}.md"
  printf "### [%s@%s:%s]\n\n" "$role" "$MODEL_B_LABEL" "$MODEL_B_LABEL_ID" >> "$TRANSCRIPT_FILE"
  cat "$output_file_b" >> "$TRANSCRIPT_FILE"
  printf "\n\n" >> "$TRANSCRIPT_FILE"

done

SYNTHESIS_FILE="$SESSION_DIR/90_SYNTHESIS.md"
SYNTH_PROMPT="Role: moderator. Summarize the brainstorm outputs across all roles and models. Provide 3 implementation variants, risks, and recommended next steps. Minimum length: ${SYNTHESIS_MIN_CHARS} characters. Use the transcript below.\n\nTranscript:\n"
SYNTH_PROMPT+="$(cat "$TRANSCRIPT_FILE")"
SYNTH_PROMPT+="\n\nWrite only the synthesis."

if run_with_prompt "$MODEL_A" "$SYNTH_PROMPT" "$SYNTHESIS_FILE"; then
  if ! append_for_length "$MODEL_A" "$SYNTHESIS_FILE" "$SYNTHESIS_MIN_CHARS" "$SYNTH_PROMPT"; then
    echo "[brainstorm] ERROR synthesis output too short" >> "$LOG"
    exit 3
  fi
else
  echo "[brainstorm] ERROR synthesis runner failed" >> "$LOG"
  exit 3
fi

printf "### [moderator]\n\n" >> "$TRANSCRIPT_FILE"
cat "$SYNTHESIS_FILE" >> "$TRANSCRIPT_FILE"
printf "\n" >> "$TRANSCRIPT_FILE"

if [[ $PRINT_TRANSCRIPT -eq 1 ]]; then
  echo "----- BEGIN BRAINSTORM session_id=$SESSION_ID -----"
  if [[ -n "$TAIL_LINES" ]]; then
    tail -n "$TAIL_LINES" "$TRANSCRIPT_FILE"
  else
    cat "$TRANSCRIPT_FILE"
  fi
  echo "----- END BRAINSTORM -----"
fi

BRAINSTORM_ROOT="$WF/brainstorm"
mkdir -p "$BRAINSTORM_ROOT"
echo "$SESSION_ID" > "$BRAINSTORM_ROOT/LAST_SESSION"

echo "[brainstorm] done session_id=$SESSION_ID" >> "$LOG"
