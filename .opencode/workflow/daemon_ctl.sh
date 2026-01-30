#!/usr/bin/env bash
set -euo pipefail

WF=".opencode/workflow"
PIDFILE="$WF/.daemon.pid"
LOG="$WF/daemon.log"

cmd="${1:-}"

case "$cmd" in
  start)
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      echo "daemon already running pid=$(cat "$PIDFILE")"
      exit 0
    fi
    nohup "$WF/daemon.sh" >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
    echo "started pid=$!"
    ;;
  stop)
    if [[ -f "$PIDFILE" ]]; then
      pid="$(cat "$PIDFILE")"
      kill "$pid" 2>/dev/null || true
      rm -f "$PIDFILE"
      echo "stopped pid=$pid"
    else
      echo "not running"
    fi
    ;;
  status)
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      echo "running pid=$(cat "$PIDFILE")"
    else
      echo "not running"
    fi
    ;;
  log)
    tail -n 120 "$LOG"
    ;;
  *)
    echo "usage: $0 {start|stop|status|log}"
    exit 1
    ;;
esac
