#!/usr/bin/env bash
set -euo pipefail

SESSION_ID="${1:?session id required}"
SESSION_DIR="${2:?session dir required}"
PROMPT_TEXT="${3:?prompt text required}"
PRINT_TRANSCRIPT=1
TAIL_LINES=""
NO_COLOR=0
USE_CONTEXT=1

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
      --no-context)
        USE_CONTEXT=0
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

CONFIG_RAW="$(cat "$CONFIG_FILE")"

MODEL_A_CONFIG=""
MODEL_B_CONFIG=""
MODELS_SOURCE="config"
PRESET_NAME=""
DEFAULT_MIN_LENGTH=""
DEFAULT_TIMEOUT_SEC=""
DEFAULT_MAX_ATTEMPTS=""
SYNTHESIS_MIN_CHARS=""
SYNTHESIS_PROMPT=""
CONTEXT_FILE=""
CONTEXT_ENABLED=0
CONTEXT_SHA256=""
CONTEXT_BLOCK=""

ROUND_NAMES=()
ROUND_ENABLED=()
ROUND_ROLE_NAMES=()
ROUND_ROLE_RUNS=()
ROUND_ROLE_PROMPTS=()

current_section=""
current_round=""
current_round_enabled=1
current_role=""
current_role_prompt=""
current_role_run=""

finalize_role() {
  if [[ -n "$current_role" ]]; then
    ROUND_ROLE_NAMES+=("$current_round:$current_role")
    ROUND_ROLE_RUNS+=("$current_round:${current_role_run:-both}")
    ROUND_ROLE_PROMPTS+=("$current_round:${current_role_prompt}")
  fi
  current_role=""
  current_role_prompt=""
  current_role_run=""
}

finalize_round() {
  finalize_role
  if [[ -n "$current_round" ]]; then
    ROUND_NAMES+=("$current_round")
    ROUND_ENABLED+=("$current_round_enabled")
  fi
  current_round=""
  current_round_enabled=1
}

while IFS= read -r raw_line; do
  line="${raw_line%%#*}"
  if [[ -z "${line//[[:space:]]/}" ]]; then
    continue
  fi

  if [[ "$line" =~ ^models: ]]; then
    current_section="models"
    continue
  fi
  if [[ "$line" =~ ^defaults: ]]; then
    current_section="defaults"
    continue
  fi
  if [[ "$line" =~ ^rounds: ]]; then
    current_section="rounds"
    continue
  fi
  if [[ "$line" =~ ^synthesis: ]]; then
    current_section="synthesis"
    continue
  fi

  if [[ "$current_section" == "models" ]]; then
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

  if [[ "$current_section" == "defaults" ]]; then
    if [[ "$line" =~ ^[[:space:]]*min_length_chars: ]]; then
      value="${line#*:}"
      DEFAULT_MIN_LENGTH="$(trim_value "$value")"
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*role_timeout_sec: ]]; then
      value="${line#*:}"
      DEFAULT_TIMEOUT_SEC="$(trim_value "$value")"
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*max_attempts: ]]; then
      value="${line#*:}"
      DEFAULT_MAX_ATTEMPTS="$(trim_value "$value")"
      continue
    fi
  fi

  if [[ "$current_section" == "synthesis" ]]; then
    if [[ "$line" =~ ^[[:space:]]*min_chars: ]]; then
      value="${line#*:}"
      SYNTHESIS_MIN_CHARS="$(trim_value "$value")"
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*prompt: ]]; then
      value="${line#prompt:}"
      SYNTHESIS_PROMPT="$(trim_value "$value")"
      continue
    fi
  fi

  if [[ "$current_section" == "rounds" ]]; then
    if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]*name: ]]; then
      finalize_round
      current_round="$(trim_value "${line#*:}")"
      current_round_enabled=1
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*enabled: ]]; then
      value="$(trim_value "${line#*:}")"
      if [[ "$value" == "false" ]]; then
        current_round_enabled=0
      else
        current_round_enabled=1
      fi
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]{6}-[[:space:]]*name: ]]; then
      finalize_role
      current_role="$(trim_value "${line#*:}")"
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]{8}name: ]]; then
      finalize_role
      current_role="$(trim_value "${line#*:}")"
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]{8}prompt: ]]; then
      current_role_prompt="$(trim_value "${line#prompt:}")"
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]{8}run: ]]; then
      current_role_run="$(trim_value "${line#run:}")"
      continue
    fi
  fi

done < "$CONFIG_FILE"

finalize_round

if [[ -z "$MODEL_A_CONFIG" ]]; then
  echo "FAIL: brainstorm config missing modelA" >&2
  exit 1
fi
if [[ -z "$DEFAULT_MIN_LENGTH" ]]; then
  echo "FAIL: brainstorm config missing defaults.min_length_chars" >&2
  exit 1
fi
if [[ -z "$DEFAULT_TIMEOUT_SEC" ]]; then
  DEFAULT_TIMEOUT_SEC="120"
fi
if [[ -z "$DEFAULT_MAX_ATTEMPTS" ]]; then
  DEFAULT_MAX_ATTEMPTS="2"
fi
if [[ -n "${BRAINSTORM_MODEL_TIMEOUT:-}" ]]; then
  DEFAULT_TIMEOUT_SEC="$BRAINSTORM_MODEL_TIMEOUT"
fi
if [[ -n "${BRAINSTORM_MAX_ATTEMPTS:-}" ]]; then
  DEFAULT_MAX_ATTEMPTS="$BRAINSTORM_MAX_ATTEMPTS"
fi
if [[ -z "$SYNTHESIS_MIN_CHARS" ]]; then
  SYNTHESIS_MIN_CHARS="1500"
fi
if [[ -z "$SYNTHESIS_PROMPT" ]]; then
  SYNTHESIS_PROMPT="Summarize the brainstorm outputs across all rounds. Provide 3 implementation variants, risks, and recommended next steps."
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

if [[ -n "${BRAINSTORM_MODELS_SOURCE:-}" ]]; then
  MODELS_SOURCE="$BRAINSTORM_MODELS_SOURCE"
fi
if [[ -n "${BRAINSTORM_PRESET_NAME:-}" ]]; then
  PRESET_NAME="$BRAINSTORM_PRESET_NAME"
fi
if [[ -n "${BRAINSTORM_MODEL_A:-}" ]]; then
  MODEL_A_CONFIG="$BRAINSTORM_MODEL_A"
  MODEL_B_CONFIG="${BRAINSTORM_MODEL_B:-}"
  if [[ "$MODELS_SOURCE" == "config" ]]; then
    MODELS_SOURCE="env"
  fi
fi

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

if [[ "$MODELS_SOURCE" == preset:* ]]; then
  echo "[brainstorm] models_source=$MODELS_SOURCE modelA=$MODEL_A modelB=$MODEL_B" >> "$LOG"
else
  echo "[brainstorm] models_source=$MODELS_SOURCE modelA=$MODEL_A modelB=$MODEL_B" >> "$LOG"
fi

MODEL_A_LABEL="modelA"
MODEL_B_LABEL="modelB"
MODEL_A_LABEL_ID="$MODEL_A"
MODEL_B_LABEL_ID="${MODEL_B_CONFIG:-NONE}"

mkdir -p "$SESSION_DIR"

CONTEXT_FILE="$WF/brainstorm/CONTEXT.md"
if [[ $USE_CONTEXT -eq 1 && -f "$CONTEXT_FILE" ]]; then
  CONTEXT_TEXT="$(cat "$CONTEXT_FILE")"
  if [[ -n "${CONTEXT_TEXT//[[:space:]]/}" ]]; then
    CONTEXT_ENABLED=1
    if command -v sha256sum >/dev/null 2>&1; then
      CONTEXT_SHA256=$(sha256sum "$CONTEXT_FILE" | awk '{print $1}')
    else
      CONTEXT_SHA256=$(shasum -a 256 "$CONTEXT_FILE" | awk '{print $1}')
    fi
    CONTEXT_BLOCK="## Context\n\n${CONTEXT_TEXT}\n\n"
  fi
fi


STARTED_AT="$(date -Is)"
META_FILE="$SESSION_DIR/01_META.md"
{
  printf "# Brainstorm Meta\n"
  printf "session_id=%s\n" "$SESSION_ID"
  printf "root=%s\n" "$ROOT"
  printf "started_at=%s\n" "$STARTED_AT"
  printf "modelA=%s\n" "$MODEL_A"
  if [[ -n "$MODEL_B" ]]; then
    printf "modelB=%s\n" "$MODEL_B"
  else
    printf "modelB=NONE\n"
  fi
  printf "min_length_chars=%s\n" "$DEFAULT_MIN_LENGTH"
  printf "synthesis_min_chars=%s\n" "$SYNTHESIS_MIN_CHARS"
  printf "models_source=%s\n" "$MODELS_SOURCE"
  if [[ "$MODELS_SOURCE" == preset:* ]]; then
    printf "preset_name=%s\n" "$PRESET_NAME"
  fi
  if [[ $CONTEXT_ENABLED -eq 1 ]]; then
    printf "context_file=%s\n" "$CONTEXT_FILE"
    printf "context_enabled=1\n"
    printf "context_sha256=%s\n" "$CONTEXT_SHA256"
  else
    printf "context_file=NONE\n"
    printf "context_enabled=0\n"
  fi
} > "$META_FILE"

PROMPT_FILE="$SESSION_DIR/00_PROMPT.md"
{
  printf "# Brainstorm Prompt\n"
  printf "session_id=%s\n" "$SESSION_ID"
  printf "root=%s\n\n" "$ROOT"
  if [[ $CONTEXT_ENABLED -eq 1 ]]; then
    printf "## Context\n\n%s\n\n" "$CONTEXT_TEXT"
  fi
  printf "%s\n" "$PROMPT_TEXT"
} > "$PROMPT_FILE"

run_with_prompt() {
  local model_id="$1"
  local prompt="$2"
  local output_file="$3"
  timeout "$DEFAULT_TIMEOUT_SEC" oc opencode run --model "$model_id" "$prompt" > "$output_file" 2>&1
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
    if [[ $attempts -ge $((DEFAULT_MAX_ATTEMPTS - 1)) ]]; then
      printf "\nSHORT_OUTPUT: expected >= %s chars\n" "$min_len" >> "$output_file"
      return 1
    fi
    attempts=$((attempts + 1))
    local previous
    previous="$(cat "$output_file")"
    local expand_prompt
    expand_prompt="${base_prompt}\n\nPrevious response:\n${previous}\n\nExpand with more detail, concrete steps, and risks. Add new content only. Ensure the total length is at least ${min_len} characters."
    timeout "$DEFAULT_TIMEOUT_SEC" oc opencode run --model "$model_id" "$expand_prompt" >> "$output_file" 2>&1 || return 1
  done
}

write_skipped() {
  local output_file="$1"
  local reason="$2"
  printf "SKIPPED: modelB not available\nreason: %s\n" "$reason" > "$output_file"
}

run_role_model() {
  local round_name="$1"
  local role_name="$2"
  local role_prompt="$3"
  local model_id="$4"
  local model_label="$5"
  local output_file="$6"
  local min_len="$DEFAULT_MIN_LENGTH"
  local prompt

  if [[ -z "$model_id" ]]; then
    write_skipped "$output_file" "$MODEL_B_REASON"
    echo "[brainstorm] round=$round_name role=$role_name model_id=NONE done" >> "$LOG"
    return 0
  fi

  if [[ -z "$MODEL_B" && "$model_label" == "$MODEL_B_LABEL" ]]; then
    write_skipped "$output_file" "$MODEL_B_REASON"
    echo "[brainstorm] round=$round_name role=$role_name model_id=NONE done" >> "$LOG"
    return 0
  fi

  prompt="Role: ${role_name}. ${role_prompt}\nMinimum length: ${min_len} characters. Do not respond with acknowledgements. Provide 3-5 ideas, risks, and recommendations.\n\n${CONTEXT_BLOCK}Prompt:\n${PROMPT_TEXT}\n"

  echo "[brainstorm] round=$round_name role=$role_name model_id=$model_id start" >> "$LOG"
  if run_with_prompt "$model_id" "$prompt" "$output_file"; then
    if append_for_length "$model_id" "$output_file" "$min_len" "$prompt"; then
      echo "[brainstorm] round=$round_name role=$role_name model_id=$model_id done" >> "$LOG"
      return 0
    fi
  fi

  write_skipped "$output_file" "call failed or output too short"
  echo "[brainstorm] ERROR round=$round_name role=$role_name model_id=$model_id failed" >> "$LOG"
  return 1
}

TRANSCRIPT_FILE="$SESSION_DIR/99_TRANSCRIPT.md"
: > "$TRANSCRIPT_FILE"

model_fail=0
for idx in "${!ROUND_NAMES[@]}"; do
  round_name="${ROUND_NAMES[$idx]}"
  round_enabled="${ROUND_ENABLED[$idx]}"
  if [[ "$round_enabled" -ne 1 ]]; then
    continue
  fi

  printf "## Round: %s\n\n" "$round_name" >> "$TRANSCRIPT_FILE"

  for role_entry in "${ROUND_ROLE_NAMES[@]}"; do
    if [[ "$role_entry" != "$round_name:"* ]]; then
      continue
    fi
    role_name="${role_entry#${round_name}:}"

    role_prompt=""
    for prompt_entry in "${ROUND_ROLE_PROMPTS[@]}"; do
      if [[ "$prompt_entry" == "$round_name:$role_name:"* ]]; then
        role_prompt="${prompt_entry#${round_name}:${role_name}:}"
        break
      fi
    done

    role_run="both"
    for run_entry in "${ROUND_ROLE_RUNS[@]}"; do
      if [[ "$run_entry" == "$round_name:$role_name:"* ]]; then
        role_run="${run_entry#${round_name}:${role_name}:}"
        break
      fi
    done

    if [[ "$role_run" == "modelA" || "$role_run" == "both" ]]; then
      output_file="$SESSION_DIR/20_${round_name}_${role_name}_${MODEL_A_LABEL}.md"
      run_role_model "$round_name" "$role_name" "$role_prompt" "$MODEL_A" "$MODEL_A_LABEL" "$output_file" || model_fail=1
      printf "### [%s@%s:%s]\n\n" "$role_name" "$MODEL_A_LABEL" "$MODEL_A_LABEL_ID" >> "$TRANSCRIPT_FILE"
      cat "$output_file" >> "$TRANSCRIPT_FILE"
      printf "\n\n" >> "$TRANSCRIPT_FILE"
    fi

    if [[ "$role_run" == "modelB" || "$role_run" == "both" ]]; then
      output_file="$SESSION_DIR/20_${round_name}_${role_name}_${MODEL_B_LABEL}.md"
      run_role_model "$round_name" "$role_name" "$role_prompt" "$MODEL_B" "$MODEL_B_LABEL" "$output_file" || model_fail=1
      printf "### [%s@%s:%s]\n\n" "$role_name" "$MODEL_B_LABEL" "$MODEL_B_LABEL_ID" >> "$TRANSCRIPT_FILE"
      cat "$output_file" >> "$TRANSCRIPT_FILE"
      printf "\n\n" >> "$TRANSCRIPT_FILE"
    fi

  done

done

SYNTHESIS_FILE="$SESSION_DIR/90_SYNTHESIS.md"
SYNTH_PROMPT="Role: moderator. ${SYNTHESIS_PROMPT}\nMinimum length: ${SYNTHESIS_MIN_CHARS} characters. Use the transcript below.\n\n${CONTEXT_BLOCK}Transcript:\n"
SYNTH_PROMPT+="$(cat "$TRANSCRIPT_FILE")"
SYNTH_PROMPT+="\n\nWrite only the synthesis."

if run_with_prompt "$MODEL_A" "$SYNTH_PROMPT" "$SYNTHESIS_FILE"; then
  if ! append_for_length "$MODEL_A" "$SYNTHESIS_FILE" "$SYNTHESIS_MIN_CHARS" "$SYNTH_PROMPT"; then
    echo "[brainstorm] ERROR synthesis output too short" >> "$LOG"
    model_fail=1
  fi
else
  echo "[brainstorm] ERROR synthesis runner failed" >> "$LOG"
  model_fail=1
fi

printf "## Round: synthesis\n\n" >> "$TRANSCRIPT_FILE"
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
if [[ $model_fail -ne 0 ]]; then
  exit 2
fi
