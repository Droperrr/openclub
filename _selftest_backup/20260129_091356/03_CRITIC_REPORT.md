SUMMARY:
- Stage1-spec scaffolding appears compliant per executor TREE evidence (core/, infrastructure/, logs/.gitkeep; config.py present as single settings source).
- WP→config extraction for key numeric/boolean requirements matches STRATEGY_KNOWLEDGE_BASE.md for the audited set (cluster>$20M, sweep_buffer=0.15%, confirm_candles=3; gates: BTC -1%/60m, ADX(14) H1 > 25, weekend Fri 21:00→Mon 06:00 UTC; risk $10, daily stop -$20; Shadow Lab leaders BTC/ETH/JUP/WIF).
- Gate 1 ambiguity handling is Stage1-safe: config does NOT pick a winner by default (BTC_RISK_OFF_COMPARATOR=None) and documents both candidates.

MISSING:
- PM/orchestrator decision for Gate 1 BTC Risk-Off boundary at exactly -1.0%: strict `< -0.010` (WP §4.1 prose “more than 1.0%”) vs non-strict `<= -0.010` (WP §4.4 pseudocode).
- Approved Stage1 policy for runtime artifacts outside `.opencode/workflow/*` (logs/events.jsonl, repo-root `_selftest_backup/`, `__pycache__/`/`*.pyc`) as flagged in 01_ARCH_TASKS.

MISMATCHES:
1) Expected: project tracking (ISSUES.md) should reflect current canonical implementation/evidence for Gate 1 “no winner” handling -> Actual: ISSUES.md still asserts the default comparator is set to `"<="`.
   evidence: .opencode/workflow/ISSUES.md:458-465 (claims `BTC_RISK_OFF_COMPARATOR = "<="`) -> .opencode/workflow/02_EXECUTOR_REPORT.md:231-235 (shows `BTC_RISK_OFF_COMPARATOR = None` and both candidate comparators documented)

RISKS:
- P1: Until PM decision on Gate 1 boundary, future engine implementation can diverge at btc_return_60m == -0.010 (block vs not block), which affects safety behavior.
- P2 (may escalate): Lack of explicit runtime-artifacts policy can cause hygiene/CI disputes (what must be cleaned vs ignored), especially given “no shadow sources of truth” constraint.

VERDICT: request changes
