- [iter=1] Blocker: python executable not found when running `python -m py_compile ...` for Stage 1 modules. (Resolved by using python3; see executor report for evidence.)

Title: Reports missing from .opencode/workflow (moved into _selftest_backup)
Severity: P0
Path: .opencode/workflow/{02_EXECUTOR_REPORT.md,03_CRITIC_REPORT.md,04_AUDITOR_REPORT.md}
Expected: Files exist and are non-empty per ACCEPTANCE.md (criteria 2)
Actual: Previously missing; 02 report restored at canonical path in this iteration.
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md exists; backups previously in .opencode/_selftest_backup/20260129_055220/
Impact: Acceptance blocked until pipeline no longer relocates artifacts.
Proposed fix: Updated selftest.sh to write backups outside .opencode/**; confirm pipeline/selftest does not delete canonical reports.

Title: Forbidden artifacts under .opencode/** due to _selftest_backup
Severity: P1
Path: .opencode/_selftest_backup/**
Expected: No artifacts under .opencode/** unless explicit exception documented (01_ARCH_TASKS.md constraint)
Actual: _selftest_backup directories with copied workflow files and daemon.log exist from prior runs.
Evidence: `.opencode/_selftest_backup/20260129_055220/*` listing shows multiple backed up reports
Impact: Violates workflow hygiene policy; introduces state drift / dual source of truth
Proposed fix: Reconfigured selftest.sh to write backups to repo-root `_selftest_backup/` instead; decide whether to delete existing `.opencode/_selftest_backup/**` artifacts.

Title: config.py lacks WP ref on some variables
Severity: P2
Path: config.py
Expected: Each variable comment includes both `why:` and `WP ref:` (stage1-spec)
Actual: Stage1 determinism placeholders lacked explicit `WP ref:` entries; updated to `WP ref: N/A (Stage1 ops placeholder)`.
Evidence: config.py:92-104
Impact: Spec compliance ambiguity; reviewers cannot quickly tell what is canon vs stage1 ops.
Proposed fix: Completed (all variables now include `WP ref:`).

Title: BTC Risk-Off comparator strictness ambiguity
Severity: P1
Path: config.py
Expected: Gate 1 triggers only when BTC fell more than 1.0% in last 60 minutes (strict), i.e. return < -0.010.
Actual: Comparator is configured as "<=" at -0.010 with explicit note choosing pseudocode as Stage1 behavior.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60; config.py:115-123
Impact: Edge-case behavior differs at exactly -1.0% (could block when WP says “more than”).
Proposed fix: Confirm with PM whether to keep pseudocode (<=) or align to prose (<).

Title: BTC Risk-Off comparator edge-case unresolved (iter=4)
Severity: P1
Path: config.py
Expected: Single source of truth for comparator at -1.0% threshold.
Actual: Both comparators recorded (<= for pseudocode, < for prose) awaiting PM decision.
Evidence: config.py includes BTC_RISK_OFF_COMPARATOR and BTC_RISK_OFF_COMPARATOR_PROSE plus edge-case label.
Impact: Ambiguous behavior if not resolved; engine implementation could choose wrong comparator.
Proposed fix: PM/orchestrator must decide strict vs non-strict; remove unused comparator once decision made.

Title: BTC Risk-Off comparator decision pending (iter=1)
Severity: P1
Path: config.py
Expected: Decide comparator for -1.0% BTC risk-off threshold.
Actual: BTC_RISK_OFF_COMPARATOR is "<=", with BTC_RISK_OFF_COMPARATOR_PROSE="<" retained for decision.
Evidence: config.py:87-91
Impact: Edge-case at exactly -1.0% remains ambiguous until PM/orchestrator decides.
Proposed fix: Confirm strict vs non-strict comparator; remove unused variable after decision.

Title: Executor report missing in workflow (iter=1)
Severity: P0
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: 02_EXECUTOR_REPORT.md exists and non-empty in workflow directory.
Actual: File missing in current workspace.
Evidence: glob for .opencode/workflow/02_EXECUTOR_REPORT.md returned no file.
Impact: Blocks acceptance per ACCEPTANCE.md artifact requirements.
Proposed fix: Recreate report and ensure pipeline keeps report at canonical path.

Title: BTC Risk-Off comparator decision still pending (iter=5)
Severity: P1
Path: config.py
Expected: Single comparator for BTC Risk-Off threshold.
Actual: Both BTC_RISK_OFF_COMPARATOR (<=) and BTC_RISK_OFF_COMPARATOR_PROSE (<) remain; PM decision unresolved.
Evidence: config.py:87-90; DIALOGUE.md entry to @orchestrator.
Impact: Strategy edge-case at exactly -1.0% remains ambiguous; implementation cannot finalize.
Proposed fix: PM/orchestrator choose strict vs non-strict comparator and remove unused variable.

Title: TELEGRAM_* comments over-claim canon requirement
Severity: P2
Path: config.py
Expected: why-comments only claim what WP mandates.
Actual: Comments previously stated “WP §7 requires telebot interface” for Telegram secrets.
Evidence: config.py:38-46; STRATEGY_KNOWLEDGE_BASE.md:89-106,130-136
Impact: Documentation drift; could mislead implementation priorities.
Proposed fix: Updated comments to clarify WP lists telebot library and does not mandate Telegram as sole channel.

Title: Required workflow report missing (02_EXECUTOR_REPORT.md)
Severity: P0
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: File exists and is non-empty per ACCEPTANCE.md (Artifact Generation).
Actual: Previously missing; restored at canonical path in this iteration.
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md now present; backups previously in .opencode/_selftest_backup/...
Impact: Acceptance blocked until pipeline/selftest no longer relocates artifacts.
Proposed fix: Ensure pipeline writes and preserves 02_EXECUTOR_REPORT.md at canonical location; keep backups elsewhere.

Title: Historical forbidden artifacts under .opencode/** (_selftest_backup)
Severity: P1
Path: .opencode/_selftest_backup/**
Expected: No artifacts under `.opencode/**` unless explicitly excepted (01_ARCH_TASKS.md constraints)
Actual: `.opencode/_selftest_backup/{20260129_055220,20260129_055223}/...` directories are present.
Evidence: `ls -la .opencode/_selftest_backup` shows timestamped directories; 02_EXECUTOR_REPORT.md:197-199 notes prior-run artifacts.
Impact: Violates workflow hygiene; risk of dual source of truth.
Proposed fix: Decide whether to delete these historical backups; ensure selftest/pipeline writes backups outside `.opencode/**` and does not recreate this path.

Title: BTC Risk-Off comparator ambiguity at exactly -1.0%
Severity: P1
Path: config.py
Expected: WP §4.1 prose “fell more than 1.0%” implies strict comparator `< -0.010`.
Actual: config encodes `BTC_RISK_OFF_COMPARATOR = "<="` aligned to WP §4.4 pseudocode; conflict documented.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 75-77; config.py:86-88.
Impact: Edge-case behavior differs; may block trades at exactly -1.0% contrary to prose interpretation.
Proposed fix: PM decision: keep pseudocode (<=) or align to prose (<); then lock and document as single source of truth.


Title: Historical `.opencode/_selftest_backup/**` still present (iter=2)
Severity: P1
Path: .opencode/_selftest_backup/**
Expected: No forbidden artifacts under `.opencode/**` (01_ARCH_TASKS.md constraint; hygiene)
Actual: Timestamped backup directories still exist under `.opencode/_selftest_backup/` (even though executor notes new backups target repo-root).
Evidence: glob shows `.opencode/_selftest_backup/20260129_055220/*` and `20260129_055223/*` still present; 02_EXECUTOR_REPORT.md notes prior-run artifacts.
Impact: Hygiene rule violation; risk of dual source of truth and reviewer confusion.
Proposed fix: Decide policy (delete existing dirs vs allow exception). Prefer deletion + ensure selftest/pipeline never recreates `.opencode/_selftest_backup/**`.

Title: WP §7 jsonl persistence not guaranteed by default
Severity: P1
Path: config.py, infrastructure/logger.py
Expected: Decisions (including blocked signals) are written to persistent jsonl storage by default.
Actual: Default `LOG_OUTPUT_TARGET="stdout"` prints jsonl-formatted records to stdout; file output is only used when LOG_OUTPUT_TARGET != "stdout".
Evidence: config.py:17; infrastructure/logger.py:15-17, 29-35.
Impact: If stdout is not captured/rotated, audit trail can be lost; diverges from literal “written to jsonl” requirement.
Proposed fix: Set default LOG_OUTPUT_TARGET="file" (or similar), or ensure daemon/pipeline captures stdout to a jsonl file and document that as the persistence mechanism.

Title: Weekend stop config moved to numeric encoding (iter=4)
Severity: P2
Path: config.py
Expected: Weekend stop window encoded parse-safe/locale-agnostic.
Actual: Replaced day/time strings with weekday indices + minute-of-day UTC fields.
Evidence: config.py:96-101.
Impact: None.
Proposed fix: None.

Title: WP §7 jsonl default updated to file (iter=4)
Severity: P2
Path: config.py, infrastructure/logger.py
Expected: Default logging writes jsonl to durable storage.
Actual: LOG_OUTPUT_TARGET set to "file" and LOG_FILE_NAME added for events jsonl.
Evidence: config.py:17-19; infrastructure/logger.py:32-34.
Impact: None; note added for traceability.
Proposed fix: None.

Title: Stage1-spec “no business logic” ambiguity in main.py stub
Severity: P2
Path: main.py
Expected: Stage1 scaffold contains wiring only; no gate/signal branching logic outside future engine implementation.
Actual: main.py includes stubbed gate branching (`gate_blocked=True`) and calls log_signal_suppressed / log_signal_emitted paths.
Evidence: main.py:27-45.
Impact: Reviewers may treat this as premature strategy logic; could violate strict Stage1 spec intent.
Proposed fix: Clarify spec allowance for demo stubs; otherwise reduce main.py to setup + single startup log (no gate/signal decisions), or move any illustrative constants/labels into config.

Title: Stage1 main.py wiring-only adjustment (iter=4)
Severity: P2
Path: main.py
Expected: Stage1 scaffold wiring only.
Actual: Removed gate branching; main now logs startup and wiring-only decision with config references.
Evidence: main.py:16-33.
Impact: None.
Proposed fix: None.

Title: WP §7 jsonl logging may be non-persistent by default
Severity: P1
Path: config.py, infrastructure/logger.py
Expected: Every decision (including blocked signals) is written to persistent jsonl storage by default (WP §7).
Actual: Default `LOG_OUTPUT_TARGET="stdout"` prints json records to stdout; file output occurs only when LOG_OUTPUT_TARGET != "stdout".
Evidence: config.py:17; infrastructure/logger.py:29-35.
Impact: If stdout is not reliably captured/rotated, audit trail may be lost; diverges from literal “written to jsonl” requirement.
Proposed fix: Either (a) default LOG_OUTPUT_TARGET to "file" and write to logs/events.jsonl, or (b) document and enforce stdout capture into a jsonl file by the daemon/systemd runner.

Title: Historical .opencode/_selftest_backup artifacts removal policy unclear (iter=4)
Severity: P1
Path: .opencode/_selftest_backup/**
Expected: No forbidden artifacts under `.opencode/**` (01_ARCH_TASKS.md hygiene)
Actual: Existing historical directories were removed manually; policy confirmation needed for future runs.
Evidence: executor plan: delete .opencode/_selftest_backup and ensure backups write to repo-root `_selftest_backup/`.
Impact: Without explicit policy, future runs may recreate forbidden artifacts.
Proposed fix: Confirm deletion is expected and add enforcement (selftest uses repo-root backup; optional guard to prevent .opencode backup).

Title: BTC Risk-Off comparator edge-case unresolved (iter=4)
Severity: P1
Path: config.py
Expected: Single source of truth for comparator at -1.0% threshold.
Actual: Both comparators recorded (<= for pseudocode, < for prose) awaiting PM decision.
Evidence: config.py includes BTC_RISK_OFF_COMPARATOR and BTC_RISK_OFF_COMPARATOR_PROSE plus edge-case label.
Impact: Ambiguous behavior if not resolved; engine implementation could choose wrong comparator.
Proposed fix: PM/orchestrator must decide strict vs non-strict; remove unused comparator once decision made.

Title: BTC Risk-Off comparator decision pending (iter=1)
Severity: P1
Path: config.py
Expected: Decide comparator for -1.0% BTC risk-off threshold.
Actual: BTC_RISK_OFF_COMPARATOR is "<=", with BTC_RISK_OFF_COMPARATOR_PROSE="<" retained for decision.
Evidence: config.py:87-91
Impact: Edge-case at exactly -1.0% remains ambiguous until PM/orchestrator decides.
Proposed fix: Confirm strict vs non-strict comparator; remove unused variable after decision.

Title: Executor report missing in workflow (iter=1)
Severity: P0
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: 02_EXECUTOR_REPORT.md exists and non-empty in workflow directory.
Actual: File missing in current workspace.
Evidence: glob for .opencode/workflow/02_EXECUTOR_REPORT.md returned no file.
Impact: Blocks acceptance per ACCEPTANCE.md artifact requirements.
Proposed fix: Recreate report and ensure pipeline keeps report at canonical path.

Title: selftest.sh recreates forbidden `.opencode/_selftest_backup/**` in destructive mode
Severity: P1
Path: .opencode/workflow/selftest.sh
Expected: Hygiene rule (01_ARCH_TASKS.md) requires no artifacts under `.opencode/**`, and selftest/pipeline must not recreate `.opencode/_selftest_backup/**`.
Actual: In `--destructive` mode, selftest wrote backups to `.opencode/_selftest_backup/$ts`.
Evidence: .opencode/workflow/selftest.sh:39-46 (prior to fix).
Impact: Violates workflow hygiene; risk of dual source of truth/confusion over canonical reports.
Proposed fix: COMPLETED in iter=1: backup destination now repo-root `_selftest_backup/` (outside `.opencode/**`) and destructive cleanup includes __pycache__/pyc.

Title: selftest backups still under `.opencode/_selftest_backup` (observed)
Severity: P1
Path: .opencode/_selftest_backup/** and .opencode/workflow/selftest.sh
Expected: No artifacts under `.opencode/**`; backups must be outside (01_ARCH_TASKS.md:47-50).
Actual: `.opencode/_selftest_backup/20260129_064941` existed; `selftest.sh` `--destructive` created `.opencode/_selftest_backup/$ts` (prior to fix).
Evidence: `ls -la .opencode/_selftest_backup` showed `20260129_064941`; selftest.sh:39-46 (prior to fix).
Impact: Workflow hygiene violation; risk of dual source-of-truth for reports/logs; acceptance can be blocked if reviewers enforce constraint.
Proposed fix: COMPLETED in iter=1: removed `.opencode/_selftest_backup/**` and moved backups to repo-root `_selftest_backup/`. Confirm policy with orchestrator.
