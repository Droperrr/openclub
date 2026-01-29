SUMMARY:
- Stage1 scaffold largely matches stage1-spec required tree (config.py/main.py/core/*/infrastructure/*/logs/.gitkeep present) per executor tree.
- `config.py` contains the key WP numeric thresholds/conditions and comments with `why:` + `WP ref:`; WP §7 default jsonl persistence is implemented via `LOG_OUTPUT_TARGET="file"` and confirmed by `logs/events.jsonl` entries.
- Remaining blocking issue: workflow hygiene is still violated in **destructive selftest mode** — `.opencode/_selftest_backup/**` will be recreated by `selftest.sh`, contradicting the “no artifacts under .opencode/**” rule.

MISSING:
- Stage1-spec DoD asks to “Provide full config.py for review”; executor report provides fragments + mapping table, but not a full `config.py` listing in 02 report. (stage1-spec DoD)

MISMATCHES:
1) Expected: **No artifacts/backups under `.opencode/**` and selftest/pipeline must not recreate them** (01_ARCH_TASKS.md:47-50).
   -> Actual: `.opencode/workflow/selftest.sh` still backs up to `.opencode/_selftest_backup/$ts` when `--destructive` is used.
   evidence: .opencode/workflow/selftest.sh:39-46 (`local bak=.opencode/_selftest_backup/$ts` + `mkdir -p "$bak"`)

2) Expected: Executor evidence and implementation consistent about backup destination (01_ARCH_TASKS.md:47-50).
   -> Actual: 02_EXECUTOR_REPORT.md states backups moved to repo-root `_selftest_backup/` and “No .opencode/_selftest_backup present”, but `selftest.sh` implementation contradicts this.
   evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:100-101 vs .opencode/workflow/selftest.sh:39-46

RISKS:
- BTC Risk-Off edge-case ambiguity remains in config: prose says “fell more than 1.0%” (strict `< -0.010`) while pseudocode uses `<= -0.010`.
  evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 75-77; config.py:87-91.
  Impact: engine may later pick the wrong comparator; must be resolved by PM/orchestrator to keep a single source of truth.

- Repo contains runtime artifacts (`__pycache__/**`, `*.pyc`, `logs/events.jsonl`). Not forbidden by Stage1 spec explicitly, but can cause review noise; consider cleanup/ignore policy in selftest.
  evidence: 02_EXECUTOR_REPORT.md:6-10,82-85.

VERDICT: request changes
