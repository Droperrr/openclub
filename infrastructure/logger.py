"""Logging utilities (Stage 1 jsonl stub)."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import config


def setup() -> None:
    """Ensure log directory exists (Stage 1)."""
    if config.LOG_OUTPUT_TARGET != "stdout":
        Path(config.LOG_DIR).mkdir(parents=True, exist_ok=True)


def _sanitize_context(context: dict[str, Any]) -> dict[str, Any]:
    """Remove secret fields from log context payloads."""
    blocked_keys = {"TELEGRAM_BOT_TOKEN", "TELEGRAM_CHAT_ID"}
    sanitized: dict[str, Any] = {}
    for key, value in context.items():
        if key in blocked_keys:
            continue
        sanitized[key] = value
    return sanitized


def log_event(event_type: str, message: str, **context: object) -> None:
    """Append a jsonl log entry (Stage 1)."""
    sanitized_context = _sanitize_context(dict(context))
    payload: dict[str, Any] = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "level": "INFO",
        "event": event_type,
        "message": message,
        **sanitized_context,
    }
    record = json.dumps(payload, ensure_ascii=False, default=str)
    if config.LOG_OUTPUT_TARGET == "stdout":
        print(record)
        return
    log_path = Path(config.LOG_DIR) / f"{config.LOG_FILE_NAME}.{config.LOG_FILE_EXTENSION}"
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(record + "\n")


def log_signal_emitted(signal: str, **context: object) -> None:
    """Log emitted signals for WP 7 traceability."""
    log_event(config.LOG_EVENT_SIGNAL_EMITTED, "Signal emitted", signal=signal, **context)


def log_signal_suppressed(reason: str, **context: object) -> None:
    """Log suppressed signals with gate reasons (WP 7)."""
    log_event(
        config.LOG_EVENT_SIGNAL_SUPPRESSED,
        "Signal suppressed",
        reason=reason,
        **context,
    )


def log_gate_blocked(gate: str, **context: object) -> None:
    """Log gate blocks for auditability (WP 7)."""
    log_event(config.LOG_EVENT_GATE_BLOCKED, "Gate blocked", gate=gate, **context)


def log_decision(message: str, **context: object) -> None:
    """Log key decisions/events (WP 7)."""
    log_event(config.LOG_EVENT_DECISION, message, **context)
