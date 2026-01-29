CHECKLIST: (pass/fail)
- Inputs read (01_ARCH_TASKS.md, 02_EXECUTOR_REPORT.md, STRATEGY_KNOWLEDGE_BASE.md, DIALOGUE.md, ISSUES.md): pass
- Timezone correctness: log timestamps are timezone-aware UTC (+00:00): pass (evidence: infrastructure/logger.py:22 uses datetime.now(timezone.utc).isoformat(); 02_EXECUTOR_REPORT.md shows +00:00 examples)
- Weekend stop evaluated in UTC (no local-time dependence): pass (evidence: config.py:100-104 encodes Fri 21:00 / Mon 06:00 as UTC minutes + weekday indices)
- Percent math parameters extracted (0.15% sweep buffer, -1% BTC gate) and comparators explicit: pass (evidence: config.py:66, 87-92)
- Rounding/tick-size risk surfaced (tick size, Decimal flag): pass (evidence: config.py:76-82)
- Risk limits extracted ($10 risk/trade, -$20 daily stop): pass (evidence: config.py:110-116; WP §5.3)
- jsonl logging writes to ./logs by default and flush/close on exit: pass (evidence: infrastructure/logger.py:33-35 uses context manager; 02_EXECUTOR_REPORT.md shows ls/head evidence)
- WP §7 “blocked decisions logging” demonstrable end-to-end in Stage1: fail (evidence: STRATEGY_KNOWLEDGE_BASE.md §7; Stage1 run is “wiring only” and shows only event="decision")
- Secrets hygiene (TELEGRAM_* never logged) evidenced by guard/test: fail (evidence: config.py reads TELEGRAM_BOT_TOKEN/CHAT_ID; infrastructure/logger.py logs arbitrary **context with no denylist)
- Workflow artifact retention: `.opencode/workflow/{01..05}_*.md` persist after DESTRUCTIVE selftest: pass (evidence: current selftest.sh cleanup_state() does not delete 0{1..5}_*.md)
- ISSUES.md/DIALOGUE.md append-only integrity preserved across selftest: fail (evidence: selftest.sh snapshots + restores the files, which can clobber new entries)

FINDINGS: (P0/P1/P2; evidence; impact)

- P0 — selftest can clobber audit trail by restoring pre-run ISSUES.md/DIALOGUE.md snapshots
  - evidence: selftest.sh copies pre-run WF/ISSUES.md and WF/DIALOGUE.md to tmp (lines ~247-255), then after the run it overwrites canonical files from tmp (lines ~340-347), regardless of new entries.
  - impact: new issues/questions written during/after the pipeline (including P0/P1 blockers) can be lost, recreating “ISSUES truncated/overwritten” symptoms and breaking chain-of-custody.

- P1 — Secrets may leak into durable jsonl logs (no explicit sanitization/denylist)
  - evidence: config.py:33-35 reads TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID; infrastructure/logger.py:19-35 merges **context into payload and writes it verbatim
  - impact: accidental inclusion of secrets in any log_event context would persist to logs/events.jsonl.

- P1 — WP §7 “including blocked signals” not demonstrable in Stage1 run
  - evidence: STRATEGY_KNOWLEDGE_BASE.md:135; Stage1 emits only event="decision" (startup + “no strategy evaluation”)
  - impact: required forensic trace for gate blocks/suppressed signals not validated; future implementation could omit required events.

- P1 — BTC Risk-Off boundary comparator unresolved at exactly -1.0%
  - evidence: WP §4.1 prose “fell more than 1.0%” vs WP §4.4 pseudocode `<= -0.010`; config.py:88-90 keeps comparator None
  - impact: undefined equality behavior; future engine/backtests may diverge.

- P1 — DESTRUCTIVE selftest deletes logs/events.jsonl (durable audit data)
  - evidence: selftest.sh cleanup_state() includes `rm -f logs/events.jsonl`
  - impact: loss of jsonl audit evidence unless policy explicitly treats logs as ephemeral and always reproducibly regenerates/backs them up.

- P2 — Precision/rounding portability risk for Stage2 (float thresholds + tick-size placeholders)
  - evidence: config.py uses floats for SWEEP_BUFFER=0.0015 and BTC_RISK_OFF_RETURN_60M=-0.010; tick/Decimal knobs are placeholders
  - impact: off-by-one-tick and equality-edge drift across venues/feeds.

RECOMMENDATIONS:
- Fix ISSUES/DIALOGUE preservation semantics:
  - selftest must never overwrite canonical `.opencode/workflow/ISSUES.md` or `DIALOGUE.md` with pre-run snapshots.
  - replace with: (a) backup-only to `_selftest_backup/…` and (b) append-only regression guard (post-run must contain pre-run content as prefix, or at minimum line count must be >= pre-run, without restoring).
- Secrets hygiene:
  - add logger-level denylist/redaction for keys matching `TELEGRAM_*` (and generic secret patterns) + a small unit/smoke test.
- Close WP §7 blocked-signal logging gap:
  - either add a deterministic non-trading smoke emission for `gate_blocked` + `signal_suppressed`, or make Stage2 tests mandatory before claiming WP §7 compliance.
- Resolve BTC comparator governance:
  - PM/Orchestrator chooses strict vs non-strict; then set config BTC_RISK_OFF_COMPARATOR and add a boundary test for exactly -1.0%.
- Stage2 numeric hardening:
  - use Decimal end-to-end for comparisons; source tick/precision from exchange metadata with explicit config override.
