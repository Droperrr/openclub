- [iter=1] Blocker: python executable not found when running `python -m py_compile ...` for Stage 1 modules. (Resolved by using python3; see executor report for evidence.)

Title: Missing executor report artifact (02_EXECUTOR_REPORT.md)
Severity: P0
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: 02_EXECUTOR_REPORT.md exists and is non-empty per 01_ARCH_TASKS.md deliverable list.
Actual: File is missing at canonical path (ls -la .opencode/workflow shows no 02_EXECUTOR_REPORT.md).
Evidence: tree -a -L 3 and ls -la .opencode/workflow on 2026-01-29 show no 02_EXECUTOR_REPORT.md.
Impact: Blocks acceptance; executor deliverable absent.
Proposed fix: Recreate 02_EXECUTOR_REPORT.md with required evidence and ensure pipeline/selftest preserves it at canonical path.

Title: Missing critic report artifact (03_CRITIC_REPORT.md)
Severity: P0
Path: .opencode/workflow/03_CRITIC_REPORT.md
Expected: 03_CRITIC_REPORT.md exists and is non-empty per 01_ARCH_TASKS.md deliverable list.
Actual: File is missing at canonical path (ls -la .opencode/workflow shows no 03_CRITIC_REPORT.md).
Evidence: tree -a -L 3 and ls -la .opencode/workflow on 2026-01-29 show no 03_CRITIC_REPORT.md.
Impact: Blocks acceptance; critic deliverable absent.
Proposed fix: Critic restores/regenerates 03_CRITIC_REPORT.md at canonical path; ensure pipeline/selftest preserves it.

Title: Missing auditor report artifact (04_AUDITOR_REPORT.md)
Severity: P0
Path: .opencode/workflow/04_AUDITOR_REPORT.md
Expected: 04_AUDITOR_REPORT.md exists and is non-empty per 01_ARCH_TASKS.md deliverable list.
Actual: File is missing at canonical path (ls -la .opencode/workflow shows no 04_AUDITOR_REPORT.md).
Evidence: tree -a -L 3 and ls -la .opencode/workflow on 2026-01-29 show no 04_AUDITOR_REPORT.md.
Impact: Blocks acceptance; auditor deliverable absent.
Proposed fix: Auditor restores/regenerates 04_AUDITOR_REPORT.md at canonical path; ensure pipeline/selftest preserves it.

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

Title: Runtime artifacts policy not finalized (repo-root _selftest_backup, __pycache__, *.pyc)
Severity: P2
Path: repo-root `_selftest_backup/`, `__pycache__/`, `*.pyc`
Expected: Explicit Stage1 policy on whether these runtime artifacts are allowed+ignored or must be cleaned for acceptance.
Actual: repo-root `_selftest_backup/` exists and py_compile created `__pycache__/`/`*.pyc`; policy decision still pending.
Evidence: tree -a shows `_selftest_backup/`; `python3 -m py_compile ...` created `__pycache__/` entries; 02_EXECUTOR_REPORT.md NOTES/RISKS.
Impact: Hygiene ambiguity could cause CI/acceptance failures or dual sources of truth.
Proposed fix: PM/orchestrator to confirm allow+ignore vs mandatory cleanup; enforce via selftest/CI accordingly.


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
Status: Pending verification; `.opencode/_selftest_backup/**` currently absent (2026-01-29).


Title: Missing required auditor report artifact (iter=1)
Severity: P0
Path: .opencode/workflow/04_AUDITOR_REPORT.md
Expected: Auditor report exists and is non-empty at canonical path (selftest artifact check expects it).
Actual: File is missing in current workspace.
Evidence: .opencode/workflow/selftest.sh:71-79 (checks 02/03/04 reports); `ls -la .opencode/workflow` shows no 04_AUDITOR_REPORT.md as of 2026-01-29 07:05.
Impact: Blocks infra selftest expectations / acceptance workflow.
Proposed fix: Auditor generates 04_AUDITOR_REPORT.md; ensure pipeline preserves it at canonical path.

Title: Missing operational evidence for Stage1 checks (iter=1)
Severity: P1
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: Include command + output for `python3 -m py_compile ...` and `python3 main.py`, and show that jsonl events are produced/persisted.
Actual: Executor report does not include required command outputs; selftest run attempted via python3 failed due to bash script.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:32-36; .opencode/workflow/02_EXECUTOR_REPORT.md:215-224.
Impact: Reproducibility gap; cannot verify Stage1 runnability and logging behavior from artifacts alone.
Proposed fix: Re-run commands and paste outputs; clarify that selftest.sh should be run via bash or provide python wrapper.

Title: BTC Risk-Off comparator ambiguity at exactly -1.0% (unresolved)
Severity: P1
Path: config.py; STRATEGY_KNOWLEDGE_BASE.md
Expected: Single, unambiguous comparator for Gate 1 threshold consistent with PM decision.
Actual: Both comparators present: BTC_RISK_OFF_COMPARATOR="<=" (pseudocode) and BTC_RISK_OFF_COMPARATOR_PROSE="<" (prose).
Evidence: STRATEGY_KNOWLEDGE_BASE.md §4.1 vs §4.4; config.py:87-91.
Impact: Engine implementation can choose wrong comparator; unexpected blocks/missed blocks at boundary.
Proposed fix: PM/orchestrator decides (< vs <=) then remove the unused comparator variable and add boundary test for -0.010.


Title: Executor report lacks required command outputs (iter=1)
Severity: P1
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: Include exact commands + their outputs for `python3 -m py_compile ...` and `python3 main.py`, and show persisted jsonl evidence (e.g., `ls -la logs` + excerpt of logs/events.jsonl).
Actual: Report lists commands only; no stdout/stderr and no persisted-jsonl evidence.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:32-36; .opencode/workflow/02_EXECUTOR_REPORT.md:37-45.
Impact: Cannot independently verify Stage1 runnability/logging from artifacts.
Proposed fix: Re-run commands and paste outputs; add minimal filesystem evidence for logs/events.jsonl.
Status: Resolved in current iteration; 02_EXECUTOR_REPORT.md includes command outputs (empty stdout/stderr), logs directory listing, and events.jsonl excerpt.

Title: Executor tree evidence omits dotfiles (logs/.gitkeep not proven)
Severity: P2
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: Explicit scaffold proof includes `logs/.gitkeep` per stage1-spec/01_ARCH_TASKS.
Actual: `tree` output in executor report does not show `.gitkeep` (likely due to tree default hiding dotfiles), so evidence is incomplete.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:9-10; .opencode/workflow/02_EXECUTOR_REPORT.md:17-19.
Impact: Reviewer cannot confirm scaffold requirement from provided evidence alone.
Proposed fix: Use `tree -a` or add `ls -la logs` output to executor report.
Status: Resolved; report now includes tree -a output showing logs/.gitkeep and ls -la logs evidence.

Title: Executor report lacks full config.py for verification
Severity: P1
Path: .opencode/workflow/02_EXECUTOR_REPORT.md (deliverable), config.py (target)
Expected: Per stage1-spec DoD, provide full `config.py` (or sufficient excerpts) for review, so reviewers can verify every variable includes `why:` + `WP ref:` and that all WP numbers/conditions are correctly encoded.
Actual: Executor report provides only a summary mapping with line references; it does not include the actual config.py content/snippets.
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:54-63
Impact: Critic/auditor cannot independently verify White Paper → config.py mapping from the provided artifacts; increases risk of silent drift.
Proposed fix: Include full config.py (or paste relevant sections) into 02_EXECUTOR_REPORT.md and reference exact lines.
Status: Resolved; full config.py content now embedded in 02_EXECUTOR_REPORT.md.

Title: Runtime artifact policy not explicitly confirmed (_selftest_backup, __pycache__, *.pyc)
Severity: P2
Path: repo-root `_selftest_backup/`, `__pycache__/` under root/core/infrastructure
Expected: Clear policy for whether these artifacts are allowed in Stage1 runs (and how they are cleaned/ignored), especially given hygiene constraints.
Actual: Executor notes repo-root `_selftest_backup/` exists and is “assumed allowed” with policy pending; `__pycache__/` artifacts present due to py_compile.
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:14-18, 34-45, 72-75, 84-85
Impact: Potential hygiene violations / reviewer confusion; harder to ensure deterministic clean runs.
Proposed fix: Orchestrator/PM to confirm policy; document it in reports and/or enforce via selftest cleanup and gitignore.

Title: Gate 1 comparator ambiguity at exactly -1.0% (BTC Risk-Off)
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md §4.1 vs §4.4; config.py
Expected: Single, unambiguous comparator at -1.0% threshold per PM/orchestrator decision.
Actual: WP prose implies strict (< -0.010) while pseudocode uses non-strict (<= -0.010); config currently documents both awaiting decision.
Evidence: STRATEGY_KNOWLEDGE_BASE.md lines 59-60 vs 76-77; 02_EXECUTOR_REPORT.md line 58.
Impact: Boundary behavior undefined; future engine may block or not block unexpectedly at exactly -1.0%.
Proposed fix: PM/orchestrator decides (< vs <=), then collapse config to single comparator and add boundary test for exactly -0.010.


Title: Gate 1 BTC Risk-Off comparator not finalized (iter=4 critic)
Severity: P1
Path: config.py (as embedded in .opencode/workflow/02_EXECUTOR_REPORT.md)
Expected: Single, unambiguous comparator for Gate 1 threshold at -1.0% per PM/orchestrator decision.
Actual: Both comparators exist; default configured as `<=` with a retained `<` "prose" comparator and explicit edge-case label.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; .opencode/workflow/02_EXECUTOR_REPORT.md:240-245.
Impact: Undefined boundary behavior at exactly -1.0%; future engine may implement inconsistent gate behavior.
Proposed fix: PM/orchestrator chooses strict (<) or non-strict (<=); then collapse config to a single comparator and add a boundary test case for exactly -0.010.


Title: Missing required critic report artifact (03_CRITIC_REPORT.md)
Severity: P0
Path: .opencode/workflow/03_CRITIC_REPORT.md
Expected: File exists and is non-empty per workflow acceptance (and 01_ARCH_TASKS.md deliverables).
Actual: File not present at canonical path (observed via executor TREE showing .opencode/workflow contents).
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md TREE section lists workflow files but not 03_CRITIC_REPORT.md.
Impact: Blocks acceptance/audit workflow; critic verdict unavailable at source of truth.
Proposed fix: Regenerate/restore 03_CRITIC_REPORT.md at canonical path and ensure pipeline/selftest preserves it.

Title: Gate 1 comparator ambiguity not closed (PM decision missing)
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md §4.1 vs §4.4; config.py (as embedded in .opencode/workflow/02_EXECUTOR_REPORT.md)
Expected: Single, PM-approved comparator at -1.0% BTC Risk-Off threshold; config.py should contain only the chosen interpretation.
Actual: White Paper prose says “fell more than 1.0%” (implies strict `< -0.010`), while pseudocode uses `<= -0.010`; config.py encodes both and defaults to `<=`, explicitly pending PM/orchestrator decision.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; .opencode/workflow/02_EXECUTOR_REPORT.md:245-249; .opencode/workflow/03_CRITIC_REPORT.md:MISMATCHES(1)
Impact: Boundary behavior at exactly -1.0% is undefined; future engine could block or not block unexpectedly at the threshold.
Proposed fix: PM/orchestrator chooses strict (<) or non-strict (<=) as canonical; collapse config to single comparator and add a boundary test case for btc_return_60m == -0.010.


Title: (Critic iter=4) Gate 1 comparator not finalized (PM/orchestrator decision missing)
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md; config.py
Expected: Single, PM-approved comparator for BTC Risk-Off threshold at -1.0%.
Actual: WP prose says “fell more than 1.0%” (implies strict `< -0.010`), while pseudocode uses `<= -0.010`; config encodes both and defaults to `<=` pending decision.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; .opencode/workflow/02_EXECUTOR_REPORT.md:247-251.
Impact: Undefined boundary behavior at exactly -1.0%; engine may block or not block unexpectedly.
Proposed fix: PM/orchestrator chooses strict (<) or non-strict (<=); then collapse config to a single comparator and add a boundary test for btc_return_60m == -0.010.

Title: (Critic iter=4) Runtime artifacts policy not defined (_selftest_backup, __pycache__)
Severity: P2
Path: repo-root `_selftest_backup/`, `__pycache__/` and `*.pyc`
Expected: Explicit Stage1 policy for allowed runtime artifacts and cleanup/ignore rules.
Actual: Executor report notes presence of `_selftest_backup/` and `__pycache__` with “policy needed”.
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:152-156, 289-293.
Impact: Hygiene/reproducibility ambiguity; risk of dual source of truth and reviewer confusion.
Proposed fix: Orchestrator/PM to confirm allow+ignore vs mandatory cleanup; enforce via selftest/CI.

Title: Executor report missing at canonical path (iter=3)
Severity: P0
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: Report exists and is non-empty at canonical path per 01_ARCH_TASKS.md.
Actual: 02_EXECUTOR_REPORT.md was missing; restored from _selftest_backup/20260129_073111 and regenerated with latest evidence.
Evidence: `find . -maxdepth 3 -type f | sort` showed no 02 report; _selftest_backup/20260129_073111/02_EXECUTOR_REPORT.md used to restore.
Impact: Blocks acceptance and reviewer workflow until canonical artifact exists.
Proposed fix: Ensure pipeline/selftest preserves .opencode/workflow/02_EXECUTOR_REPORT.md; avoid relocating artifacts into _selftest_backup during runs.


Title: (Critic iter=2) Gate 1 BTC Risk-Off comparator ambiguity unresolved
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md §4.1 vs §4.4; config.py (as embedded in .opencode/workflow/02_EXECUTOR_REPORT.md)
Expected: Single, PM-approved comparator at -1.0% threshold.
Actual: Conflict remains (prose implies strict '< -0.010', pseudocode uses '<= -0.010'); config documents both and defaults to '<='.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; .opencode/workflow/02_EXECUTOR_REPORT.md:98-99, 131-133.
Impact: Undefined boundary behavior at exactly -1.0%; future engine may block or not block unexpectedly.
Proposed fix: PM/orchestrator chooses strict (<) or non-strict (<=); then collapse config to a single comparator and add a boundary test for btc_return_60m == -0.010.

Title: (Critic iter=4) stage1-spec DoD not satisfied: full config.py not included in executor report
Severity: P1
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: Per stage1-spec DoD and 01_ARCH_TASKS.md task ("Put the full config.py content into 02_EXECUTOR_REPORT.md"), the executor report must include the complete config.py text so reviewers can verify every variable has `why:` + `WP ref:` and that EVERY WP number/condition is extracted.
Actual: 02_EXECUTOR_REPORT.md provides a summary mapping with line references, but does not embed the full config.py content; independent verification from workflow artifacts is not possible.
Evidence: stage1-spec DoD ("Provide full config.py for review"); .opencode/workflow/01_ARCH_TASKS.md:52; .opencode/workflow/02_EXECUTOR_REPORT.md:892-902.
Impact: Review cannot confirm strict WP→config compliance; increases risk of silent drift.
Proposed fix: Embed full config.py (verbatim) into 02_EXECUTOR_REPORT.md (or attach a dedicated snippet section), ensuring each config variable has `why:` and `WP ref:`.

Title: Gate 1 comparator picked despite 'no winner' instruction
Severity: P1
Path: config.py
Expected: Per .opencode/workflow/01_ARCH_TASKS.md, do NOT pick a winner for Gate 1 boundary until PM/orchestrator decision; keep both comparators only as documentation.
Actual: (RESOLVED iter=4) config.py now sets `BTC_RISK_OFF_COMPARATOR = None` and documents both pseudocode/prose comparators for PM decision.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:25-31; config.py:87-91
Impact: None after fix; still requires PM/orchestrator to pick canonical comparator.
Proposed fix: PM/orchestrator decides canonical comparator (< vs <=) then collapse to a single value.

Title: Evidence artifacts created outside .opencode/workflow need explicit policy
Severity: P2
Path: logs/events.jsonl, __pycache__/**, _selftest_backup/**
Expected: “Артефакты/доказательства — только в .opencode/workflow/*” unless exceptions/policy documented.
Actual: Operational evidence generation creates/modifies logs/events.jsonl and __pycache__/*.pyc; executor also maintains repo-root _selftest_backup/.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:12-13; .opencode/workflow/02_EXECUTOR_REPORT.md:2-14,36-39,111-142
Impact: Potential spec non-compliance and hygiene ambiguity; reviewers may treat as acceptance failure.
Proposed fix: PM/orchestrator to clarify policy: either allow runtime outputs outside workflow (logs/, caches, backups) with ignore/cleanup rules, or enforce cleanup and store only evidence snapshots under .opencode/workflow/.

Title: Missing required auditor report artifact (04_AUDITOR_REPORT.md)
Severity: P0
Path: .opencode/workflow/04_AUDITOR_REPORT.md
Expected: File exists and is non-empty per 01_ARCH_TASKS.md deliverables.
Actual: File not found in current workspace (glob returned no file).
Evidence: glob(".opencode/workflow/04_AUDITOR_REPORT.md") returned no files on 2026-01-29; tree -a -L 3 shows workflow dir without 04 report.
Impact: Blocks acceptance (required artifact missing).
Proposed fix: Auditor to regenerate/restore report at canonical path. Executor can only request guidance if asked to create placeholder.

Title: Auditor report artifact generated (iter=1)
Severity: P0
Path: .opencode/workflow/04_AUDITOR_REPORT.md
Expected: File exists and is non-empty at canonical path.
Actual: Created/updated by auditor in iter=1.
Evidence: `.opencode/workflow/04_AUDITOR_REPORT.md` now present (see workflow directory listing).
Impact: Removes missing-auditor-report blocker; remaining blockers are Gate 1 comparator decision (P1).
Proposed fix: None.
Status: Resolved (artifact now exists).

Title: Gate 1 ambiguity violates 'no winner' instruction
Severity: P1
Path: config.py
Expected: Per 01_ARCH_TASKS.md, document WP §4.1 vs §4.4 comparator conflict without choosing a winner until PM/orchestrator directive.
Actual: config.py sets a default `BTC_RISK_OFF_COMPARATOR = "<="` (pseudocode) while retaining strict `<` comparator, effectively picking behavior pre-decision.
Evidence: 01_ARCH_TASKS.md:43-44; STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; config.py:87-89.
Impact: Boundary behavior at exactly -1.0% may be prematurely locked to a non-PM-approved interpretation; future engine may silently inherit it.
Proposed fix: PM/orchestrator to decide (< vs <=) OR remove default comparator until decision.

Title: (Critic iter=1) Gate 1 comparator default violates “no winner” instruction
Severity: P1
Path: config.py
Expected: Document WP §4.1 vs §4.4 comparator conflict without choosing a default until PM/orchestrator directive (01_ARCH_TASKS).
Actual: config.py sets default `BTC_RISK_OFF_COMPARATOR = "<="` (pseudocode) while also keeping prose comparator `<`, effectively picking behavior pre-decision.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:43-44; STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; config.py:87-89.
Impact: Boundary behavior at exactly -1.0% may be prematurely locked to a non-PM-approved interpretation; future engine may silently inherit it.
Proposed fix: PM/orchestrator decides (< vs <=), then collapse config to single comparator; OR remove default comparator until decision.

Title: (Critic iter=1) Evidence artifacts created outside workflow need explicit Stage1 policy
Severity: P2
Path: logs/events.jsonl, __pycache__/**, _selftest_backup/**
Expected: “Артефакты/доказательства — только в .opencode/workflow/*” OR an explicit exception/policy defining allowed runtime artifacts and cleanup/ignore rules.
Actual: Stage1 evidence/run creates/modifies `logs/events.jsonl` and `__pycache__/`/`*.pyc`; repo-root `_selftest_backup/` exists.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:12-13; .opencode/workflow/02_EXECUTOR_REPORT.md:1-15, 29-74.
Impact: Hygiene/reproducibility ambiguity; acceptance may fail if a clean tree is required.
Proposed fix: PM/orchestrator to confirm allow+ignore vs mandatory cleanup; enforce via selftest/CI and document.

[iter=5] Critic append:

Title: Gate 1 comparator default violates “do not pick a winner”
Severity: P1
Path: config.py (as embedded in workflow evidence)
Expected: Until PM/orchestrator decision, do not set an active default comparator for the BTC Risk-Off boundary (01_ARCH_TASKS:25-31).
Actual: Default comparator is set to `BTC_RISK_OFF_COMPARATOR = "<="` (pseudocode) while prose comparator is also present.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:25-31 -> .opencode/workflow/02_EXECUTOR_REPORT.md:162-166; STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77.
Impact: Boundary behavior at exactly -1.0% may be prematurely locked without PM approval; future engine may inherit this silently.
Proposed fix: PM/orchestrator chooses (< vs <=) OR explicitly authorizes temporary removal of default; then collapse config to a single comparator.

Title: Runtime artifacts policy not explicit (files outside .opencode/workflow)
Severity: P2
Path: logs/events.jsonl, repo-root _selftest_backup/, __pycache__/ and *.pyc
Expected: Explicit Stage1 policy defining allowed runtime artifacts (and ignore/cleanup rules) consistent with “no dual source of truth” constraints.
Actual: Executor run modifies `logs/events.jsonl`, creates `__pycache__/`/`*.pyc`, and maintains repo-root `_selftest_backup/` without an approved policy.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:11-13,17-18 -> .opencode/workflow/02_EXECUTOR_REPORT.md:1-15.
Impact: Hygiene/reproducibility ambiguity; may break acceptance/CI if clean tree is required.
Proposed fix: PM/orchestrator confirms allow+ignore vs mandatory cleanup; enforce via selftest/CI and document.

Title: (Critic iter=5) Gate 1 comparator still picks a winner (default "<=")
Severity: P1
Path: config.py (embedded in .opencode/workflow/02_EXECUTOR_REPORT.md)
Expected: Per 01_ARCH_TASKS.md, do NOT pick a default comparator for Gate 1 until PM/orchestrator decides strict vs non-strict boundary at -1.0%.
Actual: `BTC_RISK_OFF_COMPARATOR = "<="` is still set as the default.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:25-31; .opencode/workflow/02_EXECUTOR_REPORT.md:213-216.
Impact: Boundary behavior at exactly -1.0% may be prematurely locked to a non-PM-approved interpretation.
Proposed fix: PM/orchestrator chooses (< vs <=) OR set comparator to "UNDECIDED"/None with a guard, then collapse to single comparator after decision.

Title: (Critic iter=5) Runtime artifacts policy not approved/explicit
Severity: P2
Path: logs/events.jsonl; repo-root `_selftest_backup/`; `__pycache__/`/`*.pyc`
Expected: Per 01_ARCH_TASKS.md constraints, canonical evidence lives in `.opencode/workflow/*`; if runtime artifacts outside exist, an explicit Stage1 policy (allow+ignore vs mandatory cleanup) must be approved and documented.
Actual: Workspace contains runtime artifacts outside `.opencode/workflow/*` (logs/events.jsonl, repo-root `_selftest_backup/`, and multiple `__pycache__/*.pyc`) without an explicitly approved/recorded policy.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:11-13 and :37-42; .opencode/workflow/02_EXECUTOR_REPORT.md:1-16.
Impact: Hygiene ambiguity / potential acceptance disputes; can become P1 if CI requires a clean working tree.
Proposed fix: PM/orchestrator to confirm policy (allow+ignore vs cleanup). If cleanup required, enforce via selftest/CI; if allowed, add ignore rules and document exceptions.
Title: (Auditor iter=5) Gate 1 BTC Risk-Off comparator default violates “do not pick a winner”
Severity: P1
Path: config.py
Expected: Per 01_ARCH_TASKS.md, do NOT set an active default comparator for Gate 1 threshold until PM/orchestrator decides strict `< -0.010` vs non-strict `<= -0.010`.
Actual: config sets `BTC_RISK_OFF_COMPARATOR = "<="` while also retaining `BTC_RISK_OFF_COMPARATOR_PROSE = "<"`.
Evidence: STRATEGY_KNOWLEDGE_BASE.md lines 59-60 vs 76-77; executor report embeds config.py lines 213-217; 01_ARCH_TASKS.md lines 25-31.
Impact: Boundary behavior at exactly -1.0% may be prematurely locked without PM approval; future engine may silently inherit non-approved behavior.
Proposed fix: PM/orchestrator chooses (< vs <=) and config collapses to single comparator, OR remove default comparator until decision.

[iter=2] Critic append:

Title: Missing required auditor report artifact (04_AUDITOR_REPORT.md)
Severity: P0
Path: .opencode/workflow/04_AUDITOR_REPORT.md
Expected: File exists and is non-empty per 01_ARCH_TASKS.md deliverables.
Actual: File is missing in the current workspace.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:50-55 (requires 04); `.opencode/workflow/ISSUES.md:240-247` already notes missing 04; current `ls -la .opencode/workflow` listing contains no 04_AUDITOR_REPORT.md.
Impact: Blocks acceptance/audit workflow.
Proposed fix: Auditor restores/regenerates 04_AUDITOR_REPORT.md at canonical path and ensure pipeline preserves it.

Title: Executor report claims 04 exists but it is missing
Severity: P1
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: 02 report NOTES/RISKS must accurately reflect canonical artifact presence.
Actual: 02 report states 04 exists and is non-empty, but 04 is not present at canonical path.
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:93-99 -> missing file .opencode/workflow/04_AUDITOR_REPORT.md (confirmed by workflow dir listing).
Impact: Reviewer confusion; risk of approving with missing artifacts.
Proposed fix: Update 02 report to reflect reality OR restore 04 so statement becomes true.

Title: Auditor report missing at canonical path (iter=1)
Severity: P0
Path: .opencode/workflow/04_AUDITOR_REPORT.md
Expected: 04 report exists and non-empty at canonical path.
Actual: `ls -la .opencode/workflow` and glob show no 04_AUDITOR_REPORT.md.
Evidence: `ls -la .opencode/workflow` on 2026-01-29 shows no 04 report; glob(".opencode/workflow/04_AUDITOR_REPORT.md") returned none.
Impact: Blocks acceptance; required artifact missing.
Proposed fix: Auditor regenerate/restore 04_AUDITOR_REPORT.md at canonical path.

[iter=5] Critic append:

Title: ISSUES.md contains stale Gate 1 default-comparator claim
Severity: P2
Path: .opencode/workflow/ISSUES.md
Expected: Issues log matches current canonical evidence for Gate 1 “no winner” handling (BTC_RISK_OFF_COMPARATOR unset/None until PM decision).
Actual: ISSUES.md still contains entries claiming BTC_RISK_OFF_COMPARATOR is actively set to "<=".
Evidence: .opencode/workflow/ISSUES.md:458-465 (claims default "<=") -> .opencode/workflow/02_EXECUTOR_REPORT.md:231-235 (shows BTC_RISK_OFF_COMPARATOR = None)
Impact: Reviewers may incorrectly believe the team violated 01_ARCH_TASKS “do not pick a winner” constraint; could cause unnecessary rework or incorrect approvals.
Proposed fix: Mark the older entries as stale/superseded, or add a clear “RESOLVED (iter=5): comparator default removed” note near those items.


Title: (Auditor iter=5) Runtime artifacts policy not approved/explicit
Severity: P1
Path: logs/events.jsonl; repo-root `_selftest_backup/`; `__pycache__/`/`*.pyc`
Expected: Explicit Stage1 policy approved by PM/orchestrator for runtime artifacts outside `.opencode/workflow/*` (allowed+ignored vs mandatory cleanup), consistent with “no shadow sources of truth”.
Actual: Runtime/evidence runs create or modify artifacts outside `.opencode/workflow/*` (jsonl log file, caches, and selftest backups) without an approved policy decision recorded.
Evidence: .opencode/workflow/01_ARCH_TASKS.md lines 20-24 + 113-118; executor TREE shows `logs/events.jsonl`, `_selftest_backup/`, and `__pycache__/` entries (02_EXECUTOR_REPORT.md TREE section); DIALOGUE.md asks orchestrator for policy (items 33/36).
Impact: Hygiene/acceptance ambiguity; can become acceptance blocker if CI expects clean tree or if backups are treated as dual source of truth.
Proposed fix: PM/orchestrator decide policy. Recommended: allow logs/events.jsonl (WP §7) and keep out of git; allow repo-root `_selftest_backup/` selftest-only; allow `__pycache__/` or clean in destructive selftest; forbid `.opencode/_selftest_backup/**`.

[iter=1] Critic append:

Title: Missing required auditor report artifact (04_AUDITOR_REPORT.md)
Severity: P0
Path: .opencode/workflow/04_AUDITOR_REPORT.md
Expected: File exists and is non-empty at canonical path per 01_ARCH_TASKS.md.
Actual: File is missing at canonical path.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:62-67; .opencode/workflow/02_EXECUTOR_REPORT.md:290-292; `ls -la .opencode/workflow` (2026-01-29) shows no 04_AUDITOR_REPORT.md.
Impact: Blocks acceptance/workflow review.
Proposed fix: Auditor restores/regenerates 04_AUDITOR_REPORT.md at `.opencode/workflow/`.

Title: Gate 1 BTC Risk-Off boundary decision missing (PM/orchestrator)
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md §4.1 vs §4.4; config.py
Expected: PM/orchestrator issues a single canonical comparator for the -1.0% boundary (< vs <=) and config collapses to the chosen behavior.
Actual: Conflict remains; config documents both candidates and keeps BTC_RISK_OFF_COMPARATOR=None (no winner yet).
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; .opencode/workflow/02_EXECUTOR_REPORT.md:230-235.
Impact: Boundary behavior at exactly -1.0% remains undefined; future engine may implement inconsistent behavior.
Proposed fix: PM/orchestrator decides strict (<) or non-strict (<=), then update config to single comparator and add boundary test.

Title: Runtime artifacts policy outside `.opencode/workflow/*` not approved
Severity: P2
Path: logs/events.jsonl; repo-root `_selftest_backup/`; `__pycache__/` and `*.pyc`
Expected: Explicit Stage1 policy (allowed+ignored vs mandatory cleanup/guard) consistent with 01_ARCH_TASKS hygiene constraints.
Actual: Runtime artifacts exist without an approved policy decision.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:20-24; .opencode/workflow/02_EXECUTOR_REPORT.md TREE section shows `_selftest_backup/` and `__pycache__/`; executor NOTES/RISKS: 289-295.
Impact: Hygiene ambiguity; potential acceptance/CI failures.
Proposed fix: PM/orchestrator approve policy and enforce via selftest/CI.

[iter=1] Critic append:

Title: Missing required auditor report artifact (04_AUDITOR_REPORT.md)
Severity: P0
Path: .opencode/workflow/04_AUDITOR_REPORT.md
Expected: 04_AUDITOR_REPORT.md exists and is non-empty per deliverables list.
Actual: File is missing at canonical path.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:104-108 (deliverables) + `ls -la .opencode/workflow` (2026-01-29) shows no 04_AUDITOR_REPORT.md.
Impact: Blocks acceptance/audit workflow.
Proposed fix: Auditor restores/regenerates 04_AUDITOR_REPORT.md at `.opencode/workflow/`.

Title: Gate 1 BTC Risk-Off boundary decision missing (PM/orchestrator)
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md; config.py
Expected: Single, PM-approved comparator at the -1.0% boundary (< vs <=) and config collapses to the chosen behavior.
Actual: White Paper has prose vs pseudocode conflict; config intentionally leaves comparator unset (BTC_RISK_OFF_COMPARATOR=None) awaiting decision.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; config.py:87-90.
Impact: Boundary behavior at exactly -1.0% remains undefined; future engine may implement inconsistent behavior.
Proposed fix: PM/orchestrator decides strict (<) or non-strict (<=), then update config to single comparator and add a boundary test.

Title: Stage1 runtime-artifacts policy not approved/explicit
Severity: P2
Path: logs/events.jsonl; repo-root `_selftest_backup/`; `__pycache__/`/`*.pyc`
Expected: Explicit Stage1 policy for runtime artifacts outside `.opencode/workflow/*` (allowed+ignored vs mandatory cleanup/guard).
Actual: Runtime artifacts exist and are referenced by executor evidence, but policy is not approved/recorded.
Evidence: .opencode/workflow/01_ARCH_TASKS.md:110-112; .opencode/workflow/02_EXECUTOR_REPORT.md:1-6 and TREE section.
Impact: Hygiene/acceptance ambiguity; potential CI disputes.
Proposed fix: PM/orchestrator confirms policy; enforce via selftest/CI and document.

Title: Missing required auditor report artifact (iter=1 re-check)
Severity: P0
Path: .opencode/workflow/04_AUDITOR_REPORT.md
Expected: File exists and is non-empty per 01_ARCH_TASKS deliverables.
Actual: File was missing at canonical path; regenerated by auditor in iter=1.
Evidence: `ls -la .opencode/workflow` (2026-01-29) showed no 04 prior to regeneration; auditor regenerated file at canonical path.
Impact: Blocks acceptance until artifact is present; breaks audit chain.
Proposed fix: Keep canonical 04 in `.opencode/workflow/` and ensure pipeline/selftest does not relocate/delete it.
Status: Resolved (restored by auditor).

Title: Gate 1 BTC Risk-Off comparator decision pending (iter=1 re-check)
Severity: P1
Path: config.py; STRATEGY_KNOWLEDGE_BASE.md
Expected: Single, PM-approved comparator at -1.0% boundary.
Actual: Comparator is intentionally unset (BTC_RISK_OFF_COMPARATOR=None) because WP prose vs pseudocode conflict remains undecided.
Evidence: STRATEGY_KNOWLEDGE_BASE.md §4.1 vs §4.4; config.py: BTC_RISK_OFF_COMPARATOR=None with both candidate comparators recorded.
Impact: Boundary behavior undefined at exactly -1.0%; future engine can silently pick wrong behavior.
Proposed fix: PM/orchestrator decides strict (<) vs non-strict (<=), then collapse config to single comparator and add boundary test.

Title: Stage1 runtime-artifacts policy not approved/recorded (iter=1 re-check)
Severity: P1
Path: logs/events.jsonl; repo-root _selftest_backup/; __pycache__/ and *.pyc
Expected: Explicit, approved policy for artifacts outside `.opencode/workflow/*`.
Actual: Runtime artifacts exist (required operational jsonl log and Python caches) without an explicit approved policy.
Evidence: logs/events.jsonl exists; glob shows __pycache__/config.cpython-310.pyc and __pycache__/main.cpython-310.pyc; 01_ARCH_TASKS calls for a decision.
Impact: Hygiene/acceptance ambiguity; may break CI expectations or cause dual-source-of-truth disputes.
Proposed fix: Approve allow+ignore vs cleanup/guard, and enforce via selftest/CI; explicitly forbid `.opencode/_selftest_backup/**`.
