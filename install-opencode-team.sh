#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
WF_SRC="$ROOT/.opencode"

usage() {
  cat <<'EOF'
Usage: ./install-opencode-team.sh [--install|--update] [--target DIR] [--dry-run]

Defaults:
  --install, target current directory

Options:
  --install    Install .opencode into target (default)
  --update     Update .opencode in target (same behavior as install)
  --target DIR Target project root (default: current directory)
  --dry-run    Show actions without copying
  --help       Show this help
EOF
}

MODE="install"
TARGET="$(pwd)"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) MODE="install"; shift ;;
    --update) MODE="update"; shift ;;
    --target) TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
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
  exit 0
fi

mkdir -p "$DEST"
rsync -a --delete "$WF_SRC/" "$DEST/"

echo "OK: $MODE completed at $DEST"
