SUMMARY:
- Reviewed 01_ARCH_TASKS.md + 02_EXECUTOR_REPORT.md + STRATEGY_KNOWLEDGE_BASE.md + ISSUES.md + DIALOGUE.md against skills: strategy-knowledge-base + stage1-spec.
- Stage1 scaffold appears compliant with stage1-spec (required paths present per executor tree; main.py is wiring-only; config.py is treated as the only settings source).
- Two blocking items remain: (1) Gate 1 BTC Risk-Off boundary decision (< vs <= at exactly -1.0%) is still unresolved, while config currently defaults to "<=" (picks a winner); (2) runtime-artifacts policy (logs/_selftest_backup/__pycache__) is not explicitly approved/recorded, despite artifacts being produced.

MISSING:
- PM/orchestrator directive to resolve Gate 1 BTC Risk-Off boundary at exactly -1.0% (strict `< -0.010` per WP §4.1 prose vs non-strict `<= -0.010` per WP §4.4 pseudocode).
- Explicit Stage1 policy decision (PM/orchestrator) for runtime artifacts vs the “canonical artifacts live in .opencode/workflow/*” constraint:
  - allow+ignore vs mandatory cleanup for repo-root `_selftest_backup/` and `__pycache__/`/`*.pyc`.
  - (optional) document that `logs/events.jsonl` is a normal runtime output per WP §7.

MISMATCHES:
1) Expected: Gate 1 comparator ambiguity must be documented **without choosing a winner** until PM/orchestrator decision (01_ARCH_TASKS) -> Actual: config defaults to pseudocode comparator `BTC_RISK_OFF_COMPARATOR = "<="`, while also keeping a prose comparator, effectively picking behavior pre-decision.
   evidence: .opencode/workflow/01_ARCH_TASKS.md:25-31 -> .opencode/workflow/02_EXECUTOR_REPORT.md:213-216

2) Expected: no “dual truth” / evidence policy must be explicit if runtime artifacts exist (01_ARCH_TASKS) -> Actual: runtime/evidence artifacts are produced outside `.opencode/workflow/*` (logs/events.jsonl, repo-root `_selftest_backup/`, multiple `__pycache__/*.pyc`) without an explicitly approved policy.
   evidence: .opencode/workflow/01_ARCH_TASKS.md:11-13 -> .opencode/workflow/02_EXECUTOR_REPORT.md:1-16 and :83-121

RISKS:
- P1: Gate 1 boundary behavior at exactly -1.0% BTC return remains undefined; a default comparator in config risks silently locking future engine behavior to a non-PM-approved interpretation.
  evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; .opencode/workflow/02_EXECUTOR_REPORT.md:213-217
- P2 (can become P1 depending on acceptance/CI): Hygiene/reproducibility ambiguity until runtime-artifacts policy is explicitly set and enforced (ignore rules vs cleanup steps).
  evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:1-16

VERDICT: request changes
