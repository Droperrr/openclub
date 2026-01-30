#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
WF_SRC="$ROOT/.opencode"

usage() {
  cat <<'EOF'
Usage: ./install-opencode-team.sh [--install|--update] [--target DIR] [--dry-run] [--install-cli] [--reset-runtime]

Defaults:
  --install, target current directory

Options:
  --install       Install .opencode into target (default)
  --update        Update .opencode in target (same behavior as install)
  --target DIR    Target project root (default: current directory)
  --dry-run       Show actions without copying
  --install-cli   Install global launcher in ~/.local/bin/club
  --reset-runtime Reset runtime artifacts (no ISSUES/DIALOGUE wipe)
  --help          Show this help

Notes:
  - 00_PM_REQUEST.md is created if missing (UX entrypoint)
EOF
}

MODE="install"
TARGET="$(pwd)"
DRY_RUN=0
INSTALL_CLI=0
RESET_RUNTIME=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) MODE="install"; shift ;;
    --update) MODE="update"; shift ;;
    --target) TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --install-cli) INSTALL_CLI=1; shift ;;
    --reset-runtime) RESET_RUNTIME=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) shift ;;
  esac
done

if [[ ! -d "$WF_SRC" ]]; then
  echo "ERROR: .opencode source not found at $WF_SRC"
  exit 1
fi

DEST="$TARGET/.opencode"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY-RUN] $MODE .opencode -> $DEST"
  if [[ $INSTALL_CLI -eq 1 ]]; then
    echo "[DRY-RUN] install cli -> $HOME/.local/bin/club"
  fi
  if [[ $RESET_RUNTIME -eq 1 ]]; then
    echo "[DRY-RUN] reset runtime artifacts"
  fi
  exit 0
fi

mkdir -p "$DEST"
RSYNC_EXCLUDES=()
if [[ $RESET_RUNTIME -eq 1 ]]; then
  RSYNC_EXCLUDES+=("--exclude" "workflow/daemon.log")
  RSYNC_EXCLUDES+=("--exclude" "workflow/.daemon.pid")
  RSYNC_EXCLUDES+=("--exclude" "workflow/.lock")
  RSYNC_EXCLUDES+=("--exclude" "workflow/.pm_request_hash")
  RSYNC_EXCLUDES+=("--exclude" "workflow/.step_*.log")
  RSYNC_EXCLUDES+=("--exclude" "workflow/_selftest_backup")
  RSYNC_EXCLUDES+=("--exclude" "workflow/0*_*.md")
fi

rsync -a --delete "${RSYNC_EXCLUDES[@]}" "$WF_SRC/" "$DEST/"

WF_DEST="$DEST/workflow"
mkdir -p "$WF_DEST"
if [[ ! -f "$WF_DEST/daemon.log" ]]; then
  : > "$WF_DEST/daemon.log"
fi
if [[ $RESET_RUNTIME -eq 1 ]]; then
  rm -rf "$WF_DEST/_selftest_backup"
  rm -f "$WF_DEST/.lock" "$WF_DEST/.pm_request_hash" "$WF_DEST/.daemon.pid"
  rm -f "$WF_DEST/.step_"*.log 2>/dev/null || true
  rm -f "$WF_DEST/0"{1,2,3,4,5}_*.md 2>/dev/null || true
  : > "$WF_DEST/daemon.log"
fi
if [[ ! -f "$WF_DEST/ISSUES.md" ]]; then
  : > "$WF_DEST/ISSUES.md"
fi
if [[ ! -f "$WF_DEST/DIALOGUE.md" ]]; then
  : > "$WF_DEST/DIALOGUE.md"
fi
if [[ ! -f "$WF_DEST/00_PM_REQUEST.md" ]]; then
  : > "$WF_DEST/00_PM_REQUEST.md"
fi

echo "OK: $MODE completed at $DEST"

if [[ $INSTALL_CLI -eq 1 ]]; then
  CLI_DIR="$HOME/.local/bin"
  mkdir -p "$CLI_DIR"
  cat > "$CLI_DIR/club" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

find_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.opencode/workflow" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  if [[ -d "/.opencode/workflow" ]]; then
    echo "/"
    return 0
  fi
  return 1
}

ROOT=$(find_root) || {
  echo "FAIL: no .opencode/workflow found in parent directories"
  echo "cd into a project with opencode installed, or run installer"
  exit 1
}

exec "$ROOT/.opencode/bin/club" "$@"
EOF
  chmod +x "$CLI_DIR/club"
  echo "OK: installed cli to $CLI_DIR/club"
fi
