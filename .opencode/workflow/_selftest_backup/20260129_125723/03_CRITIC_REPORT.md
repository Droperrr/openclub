SUMMARY:
Stage1 scaffold matches stage1-spec required tree (config.py/main.py + core/* + infrastructure/* + logs/.gitkeep). Executor evidence shows jsonl logging to ./logs/events.jsonl with timezone-aware UTC timestamps (+00:00). config.py centralizes all White Paper numeric parameters/conditions and explicitly surfaces the Gate1 BTC comparator ambiguity (no silent choice).

MISSING:
- Strong append-only integrity enforcement for `.opencode/workflow/ISSUES.md` (at least prefix or hash-based regression check); current selftest only checks “line count not decreased”, which still permits truncation+rewrite.
- Explicit “never log secrets” guard/test preventing accidental TELEGRAM_* leakage into jsonl payloads.
- Policy decision + enforcement for whether `logs/events.jsonl` is considered durable evidence across DESTRUCTIVE selftests (currently deleted).
- PM/Orchestrator decision for Gate1 boundary comparator at exactly -1.0% (strict `<` vs non-strict `<=`).

MISMATCHES: (каждый пункт = что ожидалось -> что фактически; evidence: file/line)
- Expected: ISSUES.md is append-only (no content regression) across pipeline/selftest -> Actual: selftest enforces only non-decreasing line count, which does not prevent truncation+rewrite with equal/greater line count. evidence: `.opencode/workflow/selftest.sh`:46 (PRE_ISSUES_LINES snapshot), 38-42 (line-count check only).
- Expected (WP §7): “Every decision (including blocked signals) is written to jsonl” -> Actual: Stage1 run emits only `event="decision"` (startup/wiring); no `gate_blocked` / `signal_suppressed` demonstrated (documented as Stage1 limitation). evidence: `STRATEGY_KNOWLEDGE_BASE.md`:135-136; `main.py`:18-35; `.opencode/workflow/02_EXECUTOR_REPORT.md`:482-488.
- Expected: Durable jsonl audit log survives runs unless explicitly backed up -> Actual: in DESTRUCTIVE selftest mode, cleanup deletes `logs/events.jsonl`. evidence: `.opencode/workflow/selftest.sh`:45-54 (cleanup_state), specifically line 52.
- Expected: logs cannot contain secrets (TELEGRAM_*) -> Actual: `infrastructure/logger.py` merges arbitrary **context into the payload with no denylist/redaction; config reads TELEGRAM_* from env. evidence: `config.py`:33-35; `infrastructure/logger.py`:19-35.

RISKS:
- P0 audit-chain risk: ISSUES integrity guard can be bypassed by rewrite-with-same-line-count; prior truncation symptoms could recur undetected.
- P1 security risk: potential secret leakage into durable jsonl logs (no sanitization).
- P1 spec gap: Gate1 comparator ambiguity at equality remains unresolved; future engine/backtests could diverge. evidence: `STRATEGY_KNOWLEDGE_BASE.md`:59-60 vs 76-77; `config.py`:87-92.
- P2 equality/tick/rounding drift risk in future engine (placeholder tick/rounding knobs). evidence: `config.py`:75-81.

VERDICT: request changes
