CHECKLIST: (pass/fail)
- Workflow artifacts present at canonical paths (02/03/04): pass
- config.py is single source of settings (stage1-spec): pass
- Timezone handling explicitly UTC (logs + weekend gate window): pass
- Percent math boundaries explicitly defined (incl. Gate 1 -1.0% edge): fail
- Rounding/quantization rules specified for future price/percent comparisons: pass
- Risk limits encoded (risk/trade, daily stop): pass
- WP §7 jsonl logging is durable-by-default: pass
- Hardcode/portability (no absolute paths; secrets via env): pass

FINDINGS: (P0/P1/P2; evidence; impact)
- P1: Gate 1 BTC Risk-Off boundary at exactly -1.0% is unresolved (strict vs non-strict)
  - Evidence: STRATEGY_KNOWLEDGE_BASE.md §4.1: “fell more than 1.0% in last 60 minutes” vs §4.4 pseudocode: `btc_return_60m <= -0.010`; config.py sets `BTC_RISK_OFF_COMPARATOR = None` and stores both candidates.
  - Impact: Safety-gate behavior at the threshold is undefined; future engine may silently choose an interpretation, causing unexpected over-blocking or under-blocking.

- P1: Stage1 runtime-artifacts policy outside `.opencode/workflow/*` not approved/recorded
  - Evidence: repo contains runtime artifacts: `logs/events.jsonl` (WP §7), repo-root `_selftest_backup/`, and `__pycache__/`/`*.pyc` (seen in 02_EXECUTOR_REPORT.md TREE).
  - Impact: Hygiene/acceptance ambiguity and “dual source of truth” risk (especially around backups); can lead to CI disputes or reviewers rejecting due to extra artifacts.

- P1: Infra selftest cannot prove a completed pipeline cycle (single-flight contention)
  - Evidence: 02_EXECUTOR_REPORT.md shows `selftest.sh --mode infra --wait 120` timing out with repeated `[pipeline] another run is active` messages.
  - Impact: Weakens evidence for “artifact stability across runs” because the full pipeline cycle completion is not observed.

- P2: Float/boundary sensitivity for percent thresholds and future comparisons
  - Evidence: `SWEEP_BUFFER = 0.0015` and `BTC_RISK_OFF_RETURN_60M = -0.010` are Python floats; quantization/Decimal approach is only documented as placeholders.
  - Impact: When business logic is added, float rounding can cause off-by-one-tick/edge behavior at boundaries; may be hard to reproduce without strict Decimal+tick quantization.

- P2: Rounding mode is currently a string constant
  - Evidence: `PRICE_ROUNDING = "ROUND_HALF_UP"` in config.py.
  - Impact: Future wiring can mis-map this string to an actual `decimal` rounding mode (or forget to), creating subtle mismatches.

RECOMMENDATIONS:
1) PM/Orchestrator: decide Gate 1 comparator at exactly -1.0% (`< -0.010` vs `<= -0.010`). Then collapse config to a single comparator and add an explicit boundary test case for `btc_return_60m == -0.010`.
2) PM/Orchestrator: approve an explicit Stage1 runtime-artifacts policy (and enforce in selftest/CI):
   - allow `logs/events.jsonl` (WP §7) as runtime output (keep out of git);
   - allow repo-root `_selftest_backup/` for selftest-only backups;
   - allow `__pycache__/`/`*.pyc` (or clean them only in destructive selftest);
   - explicitly forbid `.opencode/_selftest_backup/**`.
3) Fix selftest evidence reliability: adjust single-flight/pipeline scheduling so `--mode infra` completes deterministically (or document the expected way to clear locks / wait for completion).
4) For Stage2 engine work: implement all price/percent comparisons via `Decimal` + explicit tick-size quantization; log raw + quantized values to jsonl for forensic audit.
