CHECKLIST: (pass/fail)
- Inputs read (01_ARCH_TASKS.md, 02_EXECUTOR_REPORT.md, STRATEGY_KNOWLEDGE_BASE.md, DIALOGUE.md, ISSUES.md): pass
- Timezone correctness (UTC, tz-aware timestamps in jsonl): pass (evidence: infrastructure/logger.py:34 uses datetime.now(timezone.utc).isoformat())
- Weekend stop boundaries are encoded in UTC (Fri 21:00 → Mon 06:00) and locale-agnostic: pass (evidence: config.py:100-104 WEEKEND_STOP_*_MINUTE_UTC)
- Percent/threshold math captured in config.py (no inline magic numbers): pass (evidence: config.py:64-66 LIQUIDATION_CLUSTER_USD=20_000_000; SWEEP_BUFFER=0.0015; config.py:87 BTC_RISK_OFF_RETURN_60M=-0.010)
- Risk limits captured in config.py: pass (evidence: config.py:110-115 RISK_PER_TRADE_USD=10.0; DAILY_STOP_LOSS_USD=-20.0)
- Hardcode portability: WP numeric constants absent outside config.py: pass (evidence: grep across *.py shows matches only in config.py)
- jsonl logging durability basics (writes to ./logs/events.jsonl; close/flush on exit): pass (evidence: infrastructure/logger.py:45-46 context manager)
- WP §7 requirement “including blocked/suppressed signals” demonstrable end-to-end in Stage1 run: fail (evidence: main.py:27-35 emits only decision events; 02_EXECUTOR_REPORT.md shows only event="decision" lines)
- Gate 1 BTC Risk-Off comparator at exactly -1.0% is defined (strict vs non-strict): fail (evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; config.py:87-92 BTC_RISK_OFF_COMPARATOR=None)
- Rounding/tick-size determinism and equality-edge behavior are fully specified (no placeholders): fail (evidence: config.py:75-81 PRICE_TICK_SIZE/PRICE_ROUNDING placeholders)
- Secrets hygiene for jsonl logs (explicit denylist + tests): fail (evidence: infrastructure/logger.py:19-27 redacts TELEGRAM_* keys only; no test evidence in repo)
- Workflow integrity: ISSUES.md append-only/prefix preserved by selftest: pass (evidence: selftest.sh:70-97 snapshot_issues_prefix/check_issues_prefix)
- Workflow integrity: DIALOGUE.md append-only/prefix preserved by selftest: fail (evidence: selftest.sh has no snapshot/check for DIALOGUE.md; prior truncation incident recorded in ISSUES.md)
- DESTRUCTIVE selftest handling of logs/events.jsonl aligns with an approved durability policy: fail (evidence: selftest.sh:53 rm -f logs/events.jsonl; policy decision pending in DIALOGUE.md)

FINDINGS: (P0/P1/P2; evidence; impact)

- P0 — DIALOGUE.md chain-of-custody not protected
  - evidence: selftest.sh provides prefix-preservation guard for ISSUES.md only (selftest.sh:70-97) and has no analogous guard for DIALOGUE.md; historical truncation incident is recorded in ISSUES.md.
  - impact: live Q/A history can be lost; unresolved directives/questions can disappear; acceptance audit becomes non-deterministic.

- P1 — WP §7 “log every decision including blocked/suppressed signals” not proven end-to-end
  - evidence: STRATEGY_KNOWLEDGE_BASE.md:135-136 requires blocked signals; main.py:27-35 logs “Stage1 wiring only: no strategy evaluation”; logger has helpers (log_gate_blocked/log_signal_suppressed) but Stage1 run evidence contains only event="decision".
  - impact: cannot validate the required forensic trace for gate blocks/suppressed signals; risk of missing critical audit logs in later stages.

- P1 — Gate 1 BTC Risk-Off equality boundary unresolved at -1.0%
  - evidence: STRATEGY_KNOWLEDGE_BASE.md §4.1 prose (“more than 1.0%”) implies strict '<', while §4.4 pseudocode uses '<='; config.py:88 leaves BTC_RISK_OFF_COMPARATOR=None.
  - impact: undefined behavior exactly at threshold; future engine/backtests may diverge and produce inconsistent gating.

- P1 — DESTRUCTIVE selftest deletes logs/events.jsonl without approved policy
  - evidence: selftest.sh:53 `rm -f logs/events.jsonl`.
  - impact: potential loss of WP §7 audit evidence, unless explicitly declared ephemeral and regenerated deterministically; currently ambiguous.

- P1 — Secrets hygiene is partial (narrow denylist; no regression test)
  - evidence: infrastructure/logger.py:19-27 redacts only TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID keys; repository contains no test ensuring secrets never appear in jsonl.
  - impact: credentials could leak to durable logs if new secret keys are ever passed in context (or if secret naming differs); hard to detect regressions.

- P2 — Percent/rounding portability risks remain for Stage2 implementation
  - evidence: config.py uses floats for thresholds (0.0015, -0.010) and includes placeholder tick/rounding knobs (config.py:75-81) without exchange-metadata sourcing.
  - impact: equality/rounding edge drift and off-by-one-tick behavior across venues/feeds when real signal/gate logic is implemented.

RECOMMENDATIONS:
- Add DIALOGUE.md integrity guard in selftest/pipeline (same semantics as ISSUES.md): snapshot pre-run + verify pre-run content remains a prefix post-run; never overwrite canonical file.
- Close Gate 1 comparator decision via PM/Orchestrator directive (< vs <= at exactly -1.0%); then collapse config to a single comparator and add a boundary test.
- Decide and document policy for logs/events.jsonl under DESTRUCTIVE selftests:
  - if durable (recommended per WP §7): do not delete, or back up + restore deterministically;
  - if ephemeral: explicitly state so and ensure reports always regenerate fresh evidence.
- Make WP §7 blocked/suppressed logging verifiable:
  - add a deterministic Stage1 smoke emission of at least one gate_blocked + signal_suppressed event (no trading), OR
  - explicitly defer to Stage2 with mandatory tests that assert these events are emitted.
- Strengthen secret hygiene beyond TELEGRAM_*:
  - broaden sanitizer to pattern-based denylist (e.g., keys containing TOKEN/SECRET/KEY/PASSWORD) and add a minimal test/smoke assertion that jsonl lines never contain those keys.
