CHECKLIST: (pass/fail)
- Hygiene: no forbidden artifacts under `.opencode/**` and no dual source of truth: fail
- Auditability (WP §7): durable jsonl logging by default + includes blocked/gate events: pass (design); partial runtime evidence
- Determinism / cleanup: selftest/py_compile do not leave uncontrolled artifacts OR have explicit cleanup/ignore policy: fail
- Time rules (WP §4.3): weekend stop unambiguous + UTC + parse-safe encoding: pass
- Percent math / rounding: thresholds encoded precisely; rounding/quantization policy explicit to avoid float drift: pass (policy present; verify in later engine)
- Limits (WP §5.3): risk-per-trade + daily stop encoded with clear comparator semantics: pass

FINDINGS: (P0/P1/P2; evidence; impact)
- P1: Forbidden backups under `.opencode/**` still occur
  - Evidence: `.opencode/_selftest_backup/20260129_064941` exists (`ls -la .opencode/_selftest_backup`); `selftest.sh` destructive mode writes to `.opencode/_selftest_backup/$ts` (selftest.sh:39-46).
  - Impact: Violates 01_ARCH_TASKS.md hygiene constraint; risks “dual source of truth” for workflow reports/logs; can block acceptance if the reviewer enforces “no artifacts under .opencode/**”.

- P1: Gate 1 (BTC Risk-Off) comparator ambiguity at exactly -1.0%
  - Evidence: WP prose says “fell more than 1.0%” (STRATEGY_KNOWLEDGE_BASE.md:59-60) while pseudocode uses `<= -0.010` (STRATEGY_KNOWLEDGE_BASE.md:75-77). Config encodes both `BTC_RISK_OFF_COMPARATOR = "<="` and `BTC_RISK_OFF_COMPARATOR_PROSE = "<"` (config.py:87-90).
  - Impact: Edge-case behavior differs at exactly -1.0% return; future engine could choose wrong comparator; cannot claim single-source-of-truth behavior until PM decision.

- P2: Runtime artifacts present (`__pycache__/`, `*.pyc`, `logs/events.jsonl`, `_selftest_backup/`)
  - Evidence: executor TREE includes `__pycache__/**` and `logs/events.jsonl` (02_EXECUTOR_REPORT.md:5-10,25-31).
  - Impact: Not necessarily forbidden, but can create review noise/state drift; if acceptance expects clean tree after selftest, current process is insufficient.

- P2: WP §7 “including blocked signals” is implemented as logger helpers + config flag, but not yet end-to-end proven (Stage1 wiring-only)
  - Evidence: `LOG_INCLUDE_BLOCKED_SIGNALS=True` (config.py:19); `logger.log_signal_suppressed` and `logger.log_gate_blocked` exist (infrastructure/logger.py:42-55); `main.py` is wiring-only and does not exercise gates (main.py:16-35).
  - Impact: Low risk for Stage1 scaffold, but later engine must ensure gate evaluations always emit `gate_blocked` and/or `signal_suppressed` records.

RECOMMENDATIONS:
1) Fix hygiene at the source: update `.opencode/workflow/selftest.sh` to back up into repo-root `_selftest_backup/` (not `.opencode/_selftest_backup/**`) and add a guard to fail if `.opencode/_selftest_backup` is created.
2) Remove/clean existing `.opencode/_selftest_backup/**` directories as part of a destructive run (or document an explicit exception if policy allows it).
3) Request a PM/orchestrator decision on BTC Risk-Off comparator (< vs <= at -1.0%), then collapse config to a single comparator variable (no dual definitions).
4) Decide and document an artifact policy for runtime outputs (`__pycache__`, `*.pyc`, logs/)—either cleanup in selftest destructive mode, or ignore rules for VCS/review.
