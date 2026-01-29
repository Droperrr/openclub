CHECKLIST: (pass/fail)
- Timezone handling (UTC everywhere; weekend window UTC): pass
- Percent math & boundary conditions (sweep_buffer=0.15%, btc_return_60m=-1.0% edge): fail
- Rounding/quantization (tick size, Decimal vs float drift): pass
- Risk limits ($10/trade, daily stop -$20): pass
- jsonl logging durability by default: pass
- Hardcode/portability (paths/env secrets): pass
- Runtime artifacts hygiene policy (logs/_selftest_backup/__pycache__): fail

FINDINGS: (P0/P1/P2; evidence; impact)
- P1: Gate 1 BTC Risk-Off boundary at exactly -1.0% is ambiguous in the White Paper and remains unresolved.
  evidence: STRATEGY_KNOWLEDGE_BASE.md §4.1 says “fell more than 1.0%” (implies strict `< -0.010`), while §4.4 pseudocode uses `btc_return_60m <= -0.010` (non-strict). Executor-embedded config shows `BTC_RISK_OFF_RETURN_60M = -0.010`, `BTC_RISK_OFF_COMPARATOR = None` and documents both candidates (`BTC_RISK_OFF_COMPARATOR_PROSE = "<"`, `BTC_RISK_OFF_COMPARATOR_PSEUDOCODE = "<="`).
  impact: Without a PM/orchestrator decision, the safety gate’s edge-case behavior at exactly -1.0% is undefined; a future engine can silently diverge (block vs not block), which is a material safety/behavior change.

- P2: Runtime artifacts policy outside `.opencode/workflow/*` is not explicitly approved.
  evidence: executor evidence shows `logs/events.jsonl` is produced/modified (WP §7 requirement), repo-root `_selftest_backup/` exists (selftest copies), and `__pycache__/`/`*.pyc` are created by `python3 -m py_compile`.
  impact: Hygiene/acceptance ambiguity (what must be cleaned vs ignored). Risk of “shadow sources of truth” if backups proliferate, and risk of CI failures if a clean tree is expected.

- P2: Percent/price comparison determinism is currently “policy-only” (placeholders) and must be implemented consistently later.
  evidence: executor-embedded config contains Stage1 ops placeholders for quantization/rounding (`USE_DECIMAL_FOR_COMPARISONS=True`, `PRICE_TICK_SIZE=0.01`, `PRICE_ROUNDING='ROUND_HALF_UP'`, `PRICE_COMPARATOR_STRICTNESS='strict'`).
  impact: If later code uses float math or different rounding, sweep/reclaim comparisons near boundaries can drift (false positives/negatives) and become non-reproducible across environments.

- P2: Daily stop reset timezone is a Stage1 convention (not specified in WP).
  evidence: config uses `DAILY_STOP_RESET_TZ = 'UTC'` with WP ref marked N/A.
  impact: If operations expect exchange-local or another reset convention, the stop-loss window can be off by hours (behavioral discrepancy).

RECOMMENDATIONS:
- Gate 1: PM/orchestrator must choose a single canonical comparator at the -1.0% boundary (strict `< -0.010` vs non-strict `<= -0.010`). After the decision, collapse config to ONE comparator and add a boundary test case for `btc_return_60m == -0.010`.
- Safety default: while `BTC_RISK_OFF_COMPARATOR` is unset, enforce fail-closed behavior (e.g., “block all longs” or “refuse to run strategy evaluation”) so no trading happens under undefined gate rules.
- Stage1 hygiene policy (recommendation for approval):
  - allow `logs/events.jsonl` (required by WP §7) and keep it out of git;
  - allow repo-root `_selftest_backup/` as selftest-only, but never create `.opencode/_selftest_backup/**`;
  - allow `__pycache__/`/`*.pyc` as runtime artifacts; optionally remove them in destructive selftest/CI for clean diffs.
- Money/percent math: when implementing real signal evaluation, ensure all percent thresholds and money values used in comparisons are either Decimal-based or explicitly quantized (single shared helper) to prevent float edge drift.
