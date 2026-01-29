# Live Dialogue

- to:@executor
  1) Current workspace: `.opencode/workflow/02_EXECUTOR_REPORT.md` and `03_CRITIC_REPORT.md` are missing (but copies exist under `.opencode/_selftest_backup/...`). Can you confirm why the pipeline moved/removed them, and what the expected source of truth is for acceptance?
  2) `.opencode/_selftest_backup/**` is present again, which appears to violate the “no artifacts under .opencode/**” rule. What component creates it (selftest/pipeline), and can we configure it to write backups outside `.opencode/**` or to auto-clean after runs?
  3) `__pycache__/*.pyc` artifacts are present in repo root/core/infrastructure. Are these acceptable for Stage1, or should we add a cleanup step / ignore policy?
  Response:
  - Canonical workflow reports are present at `.opencode/workflow/{02,03,04}_*` in the current workspace; repo-root `_selftest_backup/` holds historical copies. Acceptance should treat `.opencode/workflow/*` as the source of truth.
  - `.opencode/_selftest_backup/**` is not present now; backups are being written to repo-root `_selftest_backup/` (outside `.opencode/**`).
  - `__pycache__/` and `*.pyc` are created by `python3 -m py_compile` during evidence runs; policy still needed on allow+ignore vs cleanup.

- to:@orchestrator
   32) Blocking decision needed to close P1: Gate 1 BTC Risk-Off boundary at exactly -1.0% — strict `< -0.010` (WP §4.1 prose) vs non-strict `<= -0.010` (WP §4.4 pseudocode). Please issue final directive.
   33) Please also confirm Stage1 runtime-artifacts policy for outputs outside `.opencode/workflow/*` (logs/events.jsonl, repo-root `_selftest_backup/`, `__pycache__/`/`*.pyc`): allowed+ignored vs mandatory cleanup/guard in selftest/CI.
   34) P0: `.opencode/workflow/04_AUDITOR_REPORT.md` is missing at the canonical path (ls/glob returned not found). Please confirm who will restore/regenerate it.

- to:@auditor
  6) P0: `.opencode/workflow/04_AUDITOR_REPORT.md` missing at canonical path. Please restore/regenerate the auditor report in `.opencode/workflow/`.
  6a) Response: restored/regenerated `.opencode/workflow/04_AUDITOR_REPORT.md` at canonical path. Current audit: P1=1 (Gate 1 BTC Risk-Off comparator decision pending), P2=2 (runtime-artifacts policy not approved; rounding/quantization placeholders).


- to:@orchestrator
  35) Please confirm the final PM decision for Gate 1 BTC Risk-Off boundary at exactly -1.0%: strict `< -0.010` (WP §4.1 prose “more than 1.0%”) vs non-strict `<= -0.010` (WP §4.4 pseudocode). Until this is decided, Critic verdict remains request changes.
  36) Please also approve an explicit Stage1 policy for runtime artifacts outside `.opencode/workflow/*` (logs/events.jsonl, repo-root `_selftest_backup/`, `__pycache__/`/`*.pyc`): allowed+ignored vs mandatory cleanup/guard.


- to:@orchestrator
  37) Please confirm/approve Stage1 runtime-artifacts policy as an explicit decision (P1): are these allowed+ignored, or must be cleaned/guarded?
      - required operational log: `logs/events.jsonl` (WP §7)
      - selftest copies: repo-root `_selftest_backup/`
      - Python caches: `__pycache__/` and `*.pyc`
      The auditor recommendation is: allow logs/events.jsonl + `_selftest_backup/` (outside `.opencode/**`) + allow/optionally clean pycache, and explicitly forbid `.opencode/_selftest_backup/**`.

- to:@critic
  38) Current workspace check: `.opencode/workflow/03_CRITIC_REPORT.md` is missing at the canonical path. Can you restore/regenerate it in `.opencode/workflow/`?

- to:@auditor
  7) Current workspace check: `.opencode/workflow/04_AUDITOR_REPORT.md` is missing at the canonical path. Please restore/regenerate it in `.opencode/workflow/`.

- to:@critic
  39) Current workspace check: `.opencode/workflow/03_CRITIC_REPORT.md` is missing at the canonical path. Please restore/regenerate it in `.opencode/workflow/`.

- to:@auditor
  8) Current workspace check: `.opencode/workflow/04_AUDITOR_REPORT.md` is still missing at the canonical path after latest run. Please restore/regenerate it in `.opencode/workflow/`.

- to:@orchestrator
  40) Critic check (iter=1): please issue final directive for Gate 1 BTC Risk-Off boundary at exactly -1.0% (strict `< -0.010` per WP §4.1 prose vs non-strict `<= -0.010` per WP §4.4 pseudocode). Until decision, verdict remains request changes.
  41) Also confirm Stage1 runtime artifacts policy for: logs/events.jsonl, repo-root `_selftest_backup/`, and `__pycache__/`/`*.pyc` (allowed+ignored vs mandatory cleanup/guard).

- to:@auditor
  9) Critic check (iter=1): `.opencode/workflow/04_AUDITOR_REPORT.md` is missing at canonical path. Please restore/regenerate it in `.opencode/workflow/`.
