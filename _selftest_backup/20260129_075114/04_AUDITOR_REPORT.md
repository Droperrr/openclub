CHECKLIST: (pass/fail)
- Inputs available for audit (01/02/KB/ISSUES/DIALOGUE present): pass
- Timezone correctness (UTC for gates/logs; weekend window encoding): pass
- Percent math / threshold encoding (incl. comparator edge-cases): fail
- Rounding / precision policy (deterministic comparisons plan): pass
- Risk limits (risk/trade, daily stop) present and safe-by-default: pass
- WP §7 jsonl logging durability (persistent by default) + includes blocked decisions: pass
- Hardcode / portability (paths, env/secrets assumptions): pass

FINDINGS: (P0/P1/P2; evidence; impact)

- P1 — Gate 1 (BTC Risk-Off) boundary ambiguity at exactly -1.0%
  - Evidence:
    - STRATEGY_KNOWLEDGE_BASE.md §4.1 prose: “fell more than 1.0% in the last 60 minutes” (strict reading ⇒ trigger only when `btc_return_60m < -0.010`).
    - STRATEGY_KNOWLEDGE_BASE.md §4.4 pseudocode: `if btc_return_60m <= -0.010: block("BTC Risk-Off")` (non-strict).
    - config.py encodes both comparators:
      - BTC_RISK_OFF_COMPARATOR = "<=" (pseudocode)
      - BTC_RISK_OFF_COMPARATOR_PROSE = "<" (prose)
      and explicitly labels the edge-case (`btc_return_60m == -0.010`).
  - Impact:
    - At the exact threshold, the system may block or allow longs depending on which comparator is chosen in the future engine; this is a safety/behavioral ambiguity at a primary gate.

- P2 — Percent math & rounding determinism not yet enforced (future-implementation risk)
  - Evidence:
    - config.py contains Stage1 determinism placeholders (tick size, rounding mode, “use Decimal”) but core engine logic that applies quantize/Decimal before comparisons is not implemented in Stage1 (core/engine.py is a stub).
  - Impact:
    - Near-threshold values (0.15% sweep buffer, -1.0% BTC return, ADX>25) can flip outcomes due to float drift / inconsistent quantization unless the engine enforces a consistent numeric policy.

- P2 — Gate 3 Weekend Stop wrap-around correctness depends on future implementation/tests
  - Evidence:
    - config.py encodes weekend window in parse-safe numeric UTC (weekday index + minute-of-day), which is good.
    - No `is_weekend_utc()` implementation or tests exist yet (Stage1 scaffolding).
  - Impact:
    - Incorrect wrap-around logic could allow trading during the forbidden weekend window or over-block normal weekday periods.

- P2 — WP §7 jsonl schema stability (future tooling risk)
  - Evidence:
    - infrastructure/logger.py writes jsonl records with fields like ts/level/event/message plus context.
    - WP §7 mandates jsonl logging but does not define a strict schema.
  - Impact:
    - Without a minimal “required fields” contract, downstream quant review tooling may be brittle as event shapes evolve.

- P2 — Runtime artifacts policy not explicitly locked (hygiene/CI determinism)
  - Evidence:
    - repo-root `_selftest_backup/` exists (allowed location vs needs cleanup is not formally confirmed).
    - `__pycache__/` and `*.pyc` are created by `python3 -m py_compile`.
  - Impact:
    - Acceptance/CI may fail or become noisy if a clean tree is expected; risk of state drift if backups are treated as an alternate source of truth.

RECOMMENDATIONS:

1) Close Gate 1 boundary decision (P1): PM/orchestrator must choose strict (`< -0.010`) vs non-strict (`<= -0.010`). After the decision:
   - Collapse config to a single comparator constant (single source of truth).
   - Add a boundary test for `btc_return_60m == -0.010`.

2) Enforce deterministic numeric comparisons in engine implementation (P2):
   - Convert inputs to Decimal, quantize-to-tick before applying comparators.
   - Add tests for equality-at-tick and near-threshold rounding behavior.

3) Implement and test Gate 3 weekend window (P2): unit tests at UTC boundaries:
   - Fri 20:59, Fri 21:00, Sat/Sun, Mon 05:59, Mon 06:00.

4) WP §7 jsonl schema (P2): define minimal required keys (e.g., ts, event, message, optional gate/signal fields) and keep it stable.

5) Hygiene policy (P2): explicitly confirm whether `_selftest_backup/` (repo-root) and `__pycache__/`/`*.pyc` are allowed+ignored or must be cleaned in selftest/CI.
