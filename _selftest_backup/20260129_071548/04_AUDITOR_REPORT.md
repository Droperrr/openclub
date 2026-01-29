CHECKLIST: (pass/fail)
- Timezone correctness (UTC for gates/logs): pass
- Percent math / threshold encoding (incl. comparator edge-cases): fail
- Rounding / precision policy (float vs Decimal; quantization): pass
- Risk limits (risk per trade, daily stop) present and safe-by-default: pass
- WP §7 jsonl logging durability (persistent by default) + includes blocked decisions: pass
- Hardcode / portability (paths, env/secrets assumptions): pass

FINDINGS: (P0/P1/P2; evidence; impact)

- P1 — Gate 1 (BTC Risk-Off) comparator ambiguity at exactly -1.0%
  - Evidence:
    - WP prose: “fell more than 1.0% in the last 60 minutes” (STRATEGY_KNOWLEDGE_BASE.md §4.1) implies strict `< -0.010`.
    - WP pseudocode: `if btc_return_60m <= -0.010: block(...)` (STRATEGY_KNOWLEDGE_BASE.md §4.4) implies non-strict `<= -0.010`.
    - Executor evidence: config encodes both comparators to document the conflict (02_EXECUTOR_REPORT.md lines 58–60).
  - Impact: Boundary behavior at exactly -1.0% is undefined unless PM/orchestrator chooses; future engine implementation may block (or not block) unexpectedly at the threshold.

- P2 — Boundary rounding risk for percent thresholds (implementation-phase)
  - Evidence:
    - Thresholds are represented as floats in config per executor report (e.g., 0.0015 sweep buffer; -0.010 BTC return).
    - Stage1 currently has no engine math implementation; precision policy is therefore not enforced yet.
  - Impact: When engine is implemented, float comparisons near boundaries (0.15%, -1.0%, ADX>25) can cause off-by-one behavior unless Decimal/tick-quantization is applied consistently.

- P2 — Weekend Stop interval correctness depends on wrap-around implementation (Fri→Mon)
  - Evidence:
    - Weekend window is now encoded parse-safe as weekday index + minute-of-day UTC (02_EXECUTOR_REPORT.md line 60).
  - Impact: A naive interval check (start<=now<=end) will be incorrect across week boundary; requires explicit wrap-around logic + tests.

- P2 — Jsonl logging schema/type stability (implementation-phase)
  - Evidence:
    - WP §7 requires decisions (incl. blocked signals) written to jsonl; executor report claims default target is file `logs/events.jsonl` and that blocked logging flag exists (02_EXECUTOR_REPORT.md line 63).
  - Impact: For quant review, numeric fields should remain numeric (not stringified); this is a future guardrail for logger/event schema.

RECOMMENDATIONS:

1) Close the Gate 1 boundary decision at -1.0% (PM/orchestrator): choose one comparator (< vs <=), then collapse config to a single source of truth and add a boundary test for exactly -0.010.

2) In engine implementation, make threshold math deterministic:
   - Prefer Decimal or integer ticks for %/price comparisons.
   - Quantize before comparisons (consistent with tick size / rounding policy).

3) Implement Weekend Stop with explicit wrap-around handling and tests around: Fri 21:00 UTC, Mon 06:00 UTC, and mid-week times.

4) Keep logging durable-by-default (file) and define a stable jsonl schema with explicit units/types, ensuring blocked signals are always recorded per WP §7.
