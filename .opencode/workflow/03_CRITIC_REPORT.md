SUMMARY:
- Stage1 scaffolding matches stage1-spec required tree (config.py/main.py + core/* + infrastructure/* + logs/.gitkeep). evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:6-23.
- config.py centralizes White Paper numeric parameters/conditions and surfaces Gate1 BTC Risk-Off comparator ambiguity (no silent choice). evidence: config.py:87-92.
- jsonl logging writes to ./logs/events.jsonl and uses timezone-aware UTC ISO8601 (+00:00). evidence: infrastructure/logger.py:34-46; .opencode/workflow/02_EXECUTOR_REPORT.md:337-346.

MISSING:
- PM/Orchestrator decisions (blocking):
  - Gate 1 BTC Risk-Off comparator at exactly -1.0%: strict '<' (WP §4.1 prose) vs non-strict '<=' (WP §4.4 pseudocode).
  - Stage1 runtime-artifacts policy for logs/events.jsonl (durable vs ephemeral) and how DESTRUCTIVE selftest should treat it.
- WP §7 “including blocked signals” proof: Stage1 run does not currently demonstrate gate_blocked/signal_suppressed records; need either a deterministic Stage1 smoke emission (no trading) or an explicit defer plan + mandatory Stage2 tests.
- Workflow integrity: DIALOGUE.md has no append-only / prefix-preservation guard (ISSUES.md has one; DIALOGUE.md does not).
- Secrets hygiene evidence: TELEGRAM_* redaction exists, but there is no test/smoke assertion and the denylist is narrow (may miss other secret keys).

MISMATCHES: (каждый пункт = что ожидалось -> что фактически; evidence: file/line)
- Expected (WP §7): jsonl includes decisions *including blocked/suppressed signals* -> Actual: evidence shows only event="decision" startup/wiring entries; no gate_blocked/signal_suppressed emitted in Stage1 run. evidence: STRATEGY_KNOWLEDGE_BASE.md:135-136; main.py:27-35; .opencode/workflow/02_EXECUTOR_REPORT.md:344-346.
- Expected: deterministic Gate 1 boundary behavior at btc_return_60m == -0.010 -> Actual: comparator is intentionally left undecided (BTC_RISK_OFF_COMPARATOR=None), pending PM decision. evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; config.py:87-92.
- Expected: DESTRUCTIVE selftest policy consistent with WP §7 logging durability (if logs are durable evidence) -> Actual: cleanup_state deletes logs/events.jsonl. evidence: .opencode/workflow/selftest.sh:46-54 (rm logs/events.jsonl at line 53).

RISKS:
- Undefined equality semantics at BTC risk-off threshold can cause future engine/backtests divergence.
- Potential loss of audit evidence if logs/events.jsonl is treated as durable but deleted by DESTRUCTIVE cleanup.
- Audit trail regression risk: DIALOGUE.md can be truncated/overwritten without detection.
- Secret leakage risk: current redaction only covers TELEGRAM_* and lacks tests.

VERDICT: request changes
