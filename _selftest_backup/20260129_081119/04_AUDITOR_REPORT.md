CHECKLIST: (pass/fail)
- Inputs available for audit (01/02/KB/ISSUES/DIALOGUE present): pass
- Timezone correctness (UTC for gates/logs; weekend window encoding): pass
- Percent math / threshold encoding (incl. comparator edge-cases): fail
- Rounding / precision policy (deterministic comparisons plan defined in config): pass
- Risk limits (risk/trade, daily stop) present and safe-by-default: pass
- WP §7 jsonl logging durability (persistent by default) + includes blocked decisions config: pass
- Hardcode / portability (paths, env/secrets assumptions): pass

FINDINGS: (P0/P1/P2; evidence; impact)

- P1 — Gate 1 (BTC Risk-Off) boundary ambiguity at exactly -1.0% + config “winner picked” despite 01_ARCH_TASKS
  - Evidence:
    - STRATEGY_KNOWLEDGE_BASE.md §4.1 prose: “fell more than 1.0% in the last 60 minutes” (strict reading ⇒ trigger only when btc_return_60m < -0.010).
    - STRATEGY_KNOWLEDGE_BASE.md §4.4 pseudocode: `if btc_return_60m <= -0.010: block("BTC Risk-Off")` (non-strict).
    - 01_ARCH_TASKS.md: requires “do not pick a winner” until PM/orchestrator decision.
    - 02_EXECUTOR_REPORT.md embeds config.py with `BTC_RISK_OFF_COMPARATOR = "<="` while also retaining `BTC_RISK_OFF_COMPARATOR_PROSE = "<"`.
  - Impact:
    - At the exact threshold (btc_return_60m == -0.010) Gate 1 behavior is undefined/contested.
    - Defaulting to `<=` risks silently locking a non-PM-approved interpretation, violating “no winner”.

- P2 — Percent/units guard missing for BTC return input (future engine risk)
  - Evidence:
    - Threshold encoded as -0.010 (decimal return, i.e. -1.0%), but Stage1 does not yet implement/validate the return calculation.
  - Impact:
    - Future engine could accidentally supply “percent points” (-1.0) instead of decimal (-0.010), making the gate permanently active/inactive.

- P2 — Gate 3 Weekend Stop is timezone/parse-safe, but needs boundary tests in future engine
  - Evidence:
    - config encodes weekend stop as weekday index + minute-of-day UTC (no locale parsing).
    - WP references `is_weekend_utc()` but Stage1 has no tests.
  - Impact:
    - Off-by-one/minute boundary bugs could violate the “no trading” window (Fri 21:00 UTC → Mon 06:00 UTC).

- P2 — Rounding/precision policy is declared but not enforced end-to-end yet (future engine risk)
  - Evidence:
    - config declares Decimal usage + quantize-to-tick + explicit rounding mode for deterministic comparisons.
  - Impact:
    - Near-threshold flips possible (sweep buffer 0.15%, BTC -1.0%, ADX>25) if future engine uses floats/inconsistent rounding.

- P2 — Runtime artifacts policy outside `.opencode/workflow/*` is not explicitly approved
  - Evidence:
    - Workspace contains runtime outputs: `logs/events.jsonl` (WP §7-required), plus repo-root `_selftest_backup/`, and `__pycache__/`/`*.pyc`.
    - 01_ARCH_TASKS warns about “dual source of truth”; current policy decision is not recorded.
  - Impact:
    - Potential acceptance/CI disputes if “clean tree” is expected; reviewer confusion until policy is fixed.

RECOMMENDATIONS:

1) Close Gate 1 boundary decision (P1): PM/orchestrator must choose strict (`< -0.010`) vs non-strict (`<= -0.010`). After decision:
   - Collapse config to a single comparator constant (single source of truth).
   - Add a boundary test for btc_return_60m == -0.010.
   - If decision is still pending: comply with 01_ARCH_TASKS by removing the “live default” comparator (set to None/"UNDECIDED" + guard), keeping both interpretations only as documentation.

2) Add explicit unit/scale assertions for percent math (P2):
   - Ensure engine computes/accepts returns strictly as decimal fractions (e.g., -0.010 == -1.0%).
   - Add a fail-fast assertion/test for accidental -1.0 input.

3) Enforce deterministic numeric comparisons in future engine (P2):
   - Convert inputs to Decimal; quantize-to-tick before applying comparators.
   - Add tests for equality-at-tick and rounding edge cases.

4) Gate 3 tests (P2): add UTC boundary tests (Fri 20:59, 21:00; Mon 05:59, 06:00).

5) Approve and document Stage1 hygiene policy (P2): explicitly confirm allow+ignore vs mandatory cleanup for repo-root `_selftest_backup/` and `__pycache__/`/`*.pyc` (while keeping `logs/events.jsonl` as a normal WP §7 runtime output).
