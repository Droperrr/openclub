CHECKLIST: (pass/fail)
- Inputs read (01_ARCH_TASKS.md, 02_EXECUTOR_REPORT.md, STRATEGY_KNOWLEDGE_BASE.md, DIALOGUE.md, ISSUES.md): pass
- Timezone correctness: log timestamps are timezone-aware UTC (+00:00): pass (evidence: infrastructure/logger.py:22)
- Weekend stop specified in UTC (Fri 21:00 UTC → Mon 06:00 UTC) with locale-agnostic encoding: pass (evidence: config.py:100-104)
- Percent math extracted and represented explicitly in config.py: pass (evidence: config.py:66 sweep_buffer=0.0015; config.py:87 btc threshold=-0.010)
- Comparator ambiguity surfaced (no silent Gate1 decision): pass (evidence: config.py:88-90 sets BTC_RISK_OFF_COMPARATOR=None and records both candidates)
- Rounding/precision portability risks surfaced: pass (evidence: config.py:75-81 tick/rounding/Decimal placeholders)
- Risk limits extracted from WP: pass (evidence: config.py:110-116)
- jsonl logging path + flush/close on exit: pass (evidence: infrastructure/logger.py:33-35 uses context manager)
- WP §7 requirement “including blocked signals” demonstrable end-to-end in Stage1 run: fail (evidence: main.py emits only decision events; executor report shows only event="decision")
- Secrets hygiene: explicit guard/test preventing TELEGRAM_* leakage into jsonl logs: fail (evidence: config.py reads TELEGRAM_*; infrastructure/logger.py merges **context verbatim)
- Workflow canonical artifacts retained under `.opencode/workflow/*` after DESTRUCTIVE selftest: pass (evidence: selftest.sh cleanup_state() no longer deletes `.opencode/workflow/0{1..5}_*.md`, but see risk on DIALOGUE/ISSUES integrity)
- ISSUES.md append-only integrity strongly enforced (prefix/hash-based): fail (evidence: selftest.sh checks only line-count non-decrease at 38-42; allows truncation+rewrite with same/greater line count)
- DIALOGUE.md integrity preserved (no overwrite/truncation): fail (evidence: prior truncation incident logged in ISSUES.md as P0; no guard exists)

FINDINGS: (P0/P1/P2; evidence; impact)

- P0 — Audit trail integrity not strongly protected (ISSUES/DIALOGUE can be overwritten/truncated without detection)
  - evidence:
    - selftest.sh: PRE_ISSUES_LINES snapshot at ~246; post-run guard only checks line-count non-decrease at ~338-342 (no prefix/hash)
    - prior DIALOGUE.md overwrite/truncation incident logged in ISSUES.md (see “Title: DIALOGUE.md was overwritten/truncated”)
  - impact: chain-of-custody can be broken; unresolved questions/issues can disappear; acceptance becomes non-deterministic.

- P1 — Secrets may leak into durable jsonl logs (no sanitization/denylist)
  - evidence: config.py:33-35 reads TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID; infrastructure/logger.py:21-27 merges **context into payload; 28-35 writes verbatim json
  - impact: any accidental inclusion of secrets in log context will persist to logs/events.jsonl.

- P1 — WP §7 “including blocked signals” not demonstrable in Stage1
  - evidence: STRATEGY_KNOWLEDGE_BASE.md:135-136; main.py:27-35 logs “Stage1 wiring only: no strategy evaluation”; logger has functions for gate_blocked/signal_suppressed but not used
  - impact: required forensic trace for gate blocks/suppressed signals is unproven; future implementation might omit required events.

- P1 — Gate 1 BTC Risk-Off boundary comparator unresolved at exactly -1.0%
  - evidence: STRATEGY_KNOWLEDGE_BASE.md §4.1 (“fell more than 1.0%”) vs §4.4 pseudocode (`<= -0.010`); config.py:88-90
  - impact: undefined equality behavior; future engine/backtests may diverge.

- P1 — DESTRUCTIVE selftest deletes logs/events.jsonl
  - evidence: selftest.sh cleanup_state(): `rm -f logs/events.jsonl` (line 52)
  - impact: loss of jsonl audit evidence unless policy explicitly treats logs as ephemeral and always backs up/regenerates deterministically.

- P2 — Float/rounding/tick-size portability risk for Stage2
  - evidence: config.py:66 (0.0015), :87 (-0.010) are floats; tick/rounding placeholders exist without exchange-metadata sourcing
  - impact: off-by-one-tick and equality-edge drift across venues/feeds.

RECOMMENDATIONS:

- Strengthen audit-trail integrity:
  - For ISSUES.md: enforce prefix-preservation (post-run file must contain pre-run content as prefix) and/or store pre-run hash and ensure the old content is still present; line-count-only is insufficient.
  - For DIALOGUE.md: apply the same non-regression guard; forbid any overwrite/truncate.

- Secrets hygiene:
  - Add redaction/denylist in infrastructure/logger.py for keys matching `TELEGRAM_*` (and other common secret names), and add a minimal test/smoke check.

- WP §7 blocked-signal logging:
  - Either add a deterministic Stage1 smoke path that emits one `gate_blocked` + `signal_suppressed` record (no trading), OR explicitly defer and create mandatory Stage2 tests that assert those events are emitted.

- Gate 1 governance:
  - PM/Orchestrator must choose strict (<) vs non-strict (<=) at exactly -1.0%; then collapse config to one comparator and add a boundary test.

- Logs durability policy:
  - Decide whether logs/events.jsonl is a durable artifact. If yes: stop deleting in destructive selftest or back up+restore it; if no: explicitly document and ensure evidence is always generated fresh in reports.
