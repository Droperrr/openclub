# 04_AUDITOR_REPORT (Risk & Safety)

CHECKLIST: (pass/fail)
- Timezone correctness (UTC everywhere for gates/logs): pass
- Percent/threshold encoding matches WP (incl. comparators): fail
- Rounding/precision policy for boundary cases (tick/Decimal): pass (config placeholders exist; implementation pending)
- Risk limits present (risk per trade, daily stop) and safe-by-default: pass
- WP §7 jsonl logging durability (file persistence) + includes blocked decisions: pass (durable by default; blocked-logging flag present)
- Hardcode/portability (paths, secrets, environment assumptions): pass

FINDINGS: (P0/P1/P2; evidence; impact)

- P1 — BTC Risk-Off comparator ambiguity at exactly -1.0%
  - Evidence:
    - WP prose: “fell more than 1.0% in the last 60 minutes” (STRATEGY_KNOWLEDGE_BASE.md §4.1, lines 59–60) implies strict `< -0.010`.
    - WP pseudocode uses non-strict comparator: `if btc_return_60m <= -0.010: block(...)` (STRATEGY_KNOWLEDGE_BASE.md §4.4, lines 76–77).
    - Config encodes both: `BTC_RISK_OFF_COMPARATOR = "<="` and `BTC_RISK_OFF_COMPARATOR_PROSE = "<"` (config.py:87–91).
  - Impact: Edge-case behavior differs at exactly -1.0%. If not resolved, future engine implementation can pick the wrong comparator, leading to unexpected blocks (or missing blocks) around the threshold.

- P2 — Percent math / rounding boundary risk (float vs Decimal; quantization policy not yet enforced)
  - Evidence:
    - Core % thresholds are floats: `SWEEP_BUFFER = 0.0015` (config.py:66), `BTC_RISK_OFF_RETURN_60M = -0.010` (config.py:87).
    - Stage1 placeholders indicate intent to quantize and use Decimal: `USE_DECIMAL_FOR_COMPARISONS = True`, tick/rounding fields (config.py:75–82), but no engine implementation yet.
  - Impact: When implemented, using binary floats for comparisons near thresholds (0.15%, -1.0%, ADX>25) can cause off-by-one-tick behavior unless Decimal quantization is consistently applied.

- P2 — Weekend stop safety depends on correct “wrap-around week” logic
  - Evidence:
    - Weekend window encoded parse-safe as weekday+minute UTC (config.py:99–104), replacing free-form strings.
  - Impact: Correctness now shifts to implementation: the engine must correctly handle the interval that crosses week boundary (Fri→Mon). A naive “start<=now<=end” check will be wrong.

- P2 — Daily stop reset definition is a Stage1 placeholder
  - Evidence:
    - `DAILY_STOP_RESET_TZ = "UTC"` marked as Stage1 ops placeholder (config.py:113).
  - Impact: Future implementation must define what “next day” means (00:00 UTC vs exchange day vs operator locale). Ambiguity can cause premature/late reset of trading halt.

- P2 — Jsonl schema durability is good, but type clarity should be enforced in future
  - Evidence:
    - Logger uses UTC timestamps: `datetime.now(timezone.utc).isoformat()` (infrastructure/logger.py:22).
    - File persistence is default: `LOG_OUTPUT_TARGET = "file"` (config.py:17) and logger appends to `logs/events.jsonl` (infrastructure/logger.py:32–34).
    - JSON serialization uses `default=str` (infrastructure/logger.py:28).
  - Impact: `default=str` avoids crashes but can hide type/units issues (e.g., Decimal -> string). For quant review, numeric fields should remain numeric when possible.

RECOMMENDATIONS:

1) Resolve Gate 1 comparator policy (PM/orchestrator decision), then collapse to a single source of truth in config:
   - Either align to prose: `< -0.010` ("more than 1.0%"), or
   - Align to pseudocode: `<= -0.010`.
   Also add a unit test for exactly `-0.010` and slightly above/below.

2) In engine implementation, make boundary behavior explicit and deterministic:
   - Use Decimal (or integer ticks) for all price/percent comparisons.
   - Apply quantization BEFORE comparator checks, consistently with `PRICE_TICK_SIZE` + `PRICE_ROUNDING`.

3) Implement Weekend Stop as an explicit UTC interval helper with wrap-around handling, and add tests for:
   - Fri 20:59 UTC (allowed), Fri 21:00 (blocked), Mon 05:59 (blocked), Mon 06:00 (allowed), and mid-week times.

4) Define and document daily stop reset semantics (00:00 UTC recommended for consistency) and add tests for reset boundaries.

5) Keep jsonl logging numeric-friendly:
   - Prefer serializing Decimal as float only if safe, or store scaled integers + explicit units.
   - Document the jsonl schema keys (“ts”, “event”, “message”, plus context) and ensure blocked signals are logged when engine is added.
