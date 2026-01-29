
[iter=1] Blocker: .opencode/workflow/02_EXECUTOR_REPORT.md missing at canonical path; regenerated in current run. Reports appear under repo-root _selftest_backup/* from prior runs, suggesting pipeline/selftest may be relocating reports. Please confirm expected source of truth and whether pipeline is allowed to move workflow artifacts.

[iter=4] Critic append:

Title: ISSUES.md unexpectedly truncated/overwritten
Severity: P0
Path: .opencode/workflow/ISSUES.md
Expected: ISSUES.md retains the running issues log and prior evidence across iterations.
Actual: File currently contains only a couple of lines (appears reset/truncated during daemon/pipeline).
Evidence: `wc -l .opencode/workflow/ISSUES.md` shows 2 lines (2026-01-29 10:38).
Impact: Loss of review/audit trail; blocks evidence-based acceptance.
Proposed fix: Identify component overwriting ISSUES.md; enforce append-only behavior or backup/restore deterministically.

Title: Canonical workflow reports not retained (02/04 missing)
Severity: P0
Path: .opencode/workflow/{02_EXECUTOR_REPORT.md,04_AUDITOR_REPORT.md}
Expected: Reports exist and are non-empty at canonical paths per ACCEPTANCE.md (artifact generation) and 01_ARCH_TASKS.md.
Actual: In current workspace `.opencode/workflow` does not contain 02 and 04 (03 recreated manually by critic).
Evidence: ACCEPTANCE.md:14-17; 01_ARCH_TASKS.md:21-26; `ls -la .opencode/workflow` (2026-01-29 10:34) shows no 02/04.
Impact: Blocks acceptance; reviewer chain is broken and selftest cannot validate artifacts.
Proposed fix: Identify which component deletes/moves reports during daemon/pipeline runs; enforce retention of canonical reports in `.opencode/workflow/`.

Title: Gate 1 BTC Risk-Off boundary decision still pending (strict vs non-strict)
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md §4.1 vs §4.4; config.py
Expected: PM/Orchestrator chooses a single canonical comparator for btc_return_60m threshold at exactly -1.0%.
Actual: WP prose implies strict '< -0.010' while pseudocode uses '<= -0.010'; config keeps BTC_RISK_OFF_COMPARATOR=None and records both candidates.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; config.py:87-90.
Impact: Undefined boundary behavior; future engine may implement inconsistent gate behavior.
Proposed fix: PM/Orchestrator decides (< vs <=), then collapse config to a single comparator and add a boundary test.

Title: Stage1 runtime-artifacts policy not approved/recorded
Severity: P2
Path: logs/events.jsonl; repo-root `_selftest_backup/`; `__pycache__/`/`*.pyc`
Expected: Explicit Stage1 policy for runtime artifacts outside `.opencode/workflow/*` (allowed+ignored vs mandatory cleanup), consistent with hygiene constraints.
Actual: Artifacts exist and are referenced by evidence, but no approved policy decision is recorded.
Evidence: 01_ARCH_TASKS.md:12-15; _selftest_backup/20260129_103231/04_AUDITOR_REPORT.md:16-18.
Impact: Hygiene/CI ambiguity and potential “dual source of truth”.
Proposed fix: PM/Orchestrator approve policy; enforce via selftest/CI.

Title: jsonl logging evidence inconsistent (events.jsonl vs ls)
Severity: P1
Path: logs/events.jsonl; .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: Evidence shows durable jsonl file present under ./logs/ and listed by `ls -la logs` after run.
Actual: Executor report shows `ls -la logs` with only `.gitkeep`, but also shows `logs/events.jsonl (head)` containing records.
Evidence: 02_EXECUTOR_REPORT.md lines 187-196.
Impact: Unclear whether WP §7 durable jsonl logging is truly satisfied by default; may indicate file created elsewhere or being deleted/moved by pipeline.
Proposed fix: Re-run `python3 main.py` and capture a single consistent evidence block: `ls -la logs` (shows events.jsonl), then `head -n 5 logs/events.jsonl`.
[iter=1] Evidence inconsistency: logs/events.jsonl presence
Severity: P1
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: Executor evidence commands are consistent (if `logs/events.jsonl` exists and has records, `ls -la logs` should list it).
Actual: `ls -la logs` shows only `.gitkeep`, but immediately after report shows `logs/events.jsonl (head)` with 2 json records.
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:187-196.
Impact: Weakens verification-grade evidence for WP §7 logging DoD.
Proposed fix: Re-run the evidence commands in a single sequence and paste outputs.


[iter=5] Title: jsonl logging durability not proven (evidence inconsistency)
Severity: P1
Path: logs/events.jsonl; .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: After `python3 main.py`, `./logs/events.jsonl` exists, is listed by `ls -la logs`, and contains jsonl lines; logger flushes on exit.
Actual: Evidence in 02 report is contradictory: `ls -la logs` shows only .gitkeep, but events.jsonl head shows records.
Evidence: 02_EXECUTOR_REPORT.md:187-196; existing ISSUES.md entries at iter=1/iter=4.
Impact: WP §7 (durable jsonl audit log) may silently fail; blocks acceptance evidence quality.
Proposed fix: Re-run as a single sequence and paste outputs; ensure logger explicitly creates/flushes/close file in ./logs.

[iter=5] Title: ISSUES.md append-only enforcement missing (prior truncation P0 unresolved)
Severity: P0
Path: .opencode/workflow/ISSUES.md
Expected: Append-only issue log preserved across all daemon/pipeline/selftest runs; never truncated.
Actual: Prior iterations observed truncation/overwrite; root cause not documented as fixed; risk remains.
Evidence: ISSUES.md:6-13 (iter=4 P0).
Impact: Loss of audit chain; acceptance cannot be proven deterministically.
Proposed fix: Add guard in pipeline/selftest that fails if ISSUES.md line count decreases; implement backup/restore without clobbering canonical file.

[iter=2] Title: Executor report missing raw evidence outputs
Severity: P1
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: Evidence-grade verification includes exact commands AND their raw outputs for (a) deterministic tree listing and (b) runtime logging durability check `python3 main.py && ls -la logs && head -n 5 logs/events.jsonl`.
Actual: Report lists the commands but does not paste their outputs.
Evidence: 01_ARCH_TASKS.md:8-15,34-36; 02_EXECUTOR_REPORT.md:283-287.
Impact: Critic cannot independently verify Stage1 DoD items (tree, durable jsonl logging) to evidence standard.
Proposed fix: Paste the raw outputs for the requested command sequences into 02 report.

[iter=2] Title: No evidence that non-config modules avoid hardcoded WP numbers/business logic
Severity: P1
Path: core/*.py, infrastructure/*.py
Expected: Per stage1-spec, config.py is the only source of settings; other modules should contain no strategy constants/business logic (beyond plumbing).
Actual: Executor report provides no snippets/attestation/evidence regarding constants/logic outside config.
Evidence: stage1-spec "config.py requirements"; 02_EXECUTOR_REPORT.md contains no module excerpts.
Impact: Risk of silent drift from WP; cannot approve compliance.
Proposed fix: Provide short excerpts or a grep-based evidence block demonstrating no WP numeric constants exist outside config.py.

[iter=2] Title: Workflow reports removed by destructive selftest cleanup (root cause identified)
Severity: P1
Path: .opencode/workflow/selftest.sh
Expected: Canonical reports remain under `.opencode/workflow/` as source of truth.
Actual: Destructive selftest `backup_state()` copies reports into `_selftest_backup/$ts` and `cleanup_state()` removes `.opencode/workflow/0{1,2,3,4,5}_*.md`.
Evidence: selftest.sh lines 29-46 (backup + cleanup); observed reports under `_selftest_backup/*` while canonical missing.
Impact: Canonical artifacts disappear after destructive selftest; causes missing 02/03/04 reports and evidence gaps.
Proposed fix: Avoid deleting canonical workflow reports in cleanup, or restore them after backup; enforce policy in selftest/pipeline.

[iter=2] Title: Destructive selftest deletes canonical workflow reports
Severity: P0
Path: .opencode/workflow/selftest.sh; .opencode/workflow/0{1,2,3,4,5}_*.md
Expected: Canonical workflow artifacts remain in `.opencode/workflow/*` after pipeline/selftest runs (single source of truth).
Actual: DIALOGUE.md reports that when `DESTRUCTIVE=1`, `selftest.sh` backs up reports into `_selftest_backup/$ts` and then `cleanup_state()` removes `.opencode/workflow/0{1,2,3,4,5}_*.md`.
Evidence: DIALOGUE.md:45-46 ("cleanup_state() removes .opencode/workflow/0{1,2,3,4,5}_*.md").
Impact: Breaks audit chain / reviewer handoff; downstream steps may read empty/missing canonical artifacts; non-deterministic acceptance.
Proposed fix: Disable destructive cleanup for workflow artifacts, or modify `cleanup_state()` to never delete canonical reports and never touch ISSUES.md/DIALOGUE.md. Treat `_selftest_backup` as backup-only.

[iter=2] Title: Executor report still lacks evidence-grade raw outputs (tree/logging)
Severity: P1
Path: .opencode/workflow/02_EXECUTOR_REPORT.md
Expected: Per 01_ARCH_TASKS.md, paste raw outputs for key evidence commands (tree listing; `python3 main.py && ls -la logs && head -n 5 logs/events.jsonl`).
Actual: 02_EXECUTOR_REPORT.md lists commands ("COMMANDS:") but does not include the raw outputs in-file; evidence is only referenced via DIALOGUE.md.
Evidence: 02_EXECUTOR_REPORT.md:283-287 lists commands only; raw outputs appear in DIALOGUE.md:34-44 but not in 02 report.
Impact: Evidence is not self-contained; critic/auditor cannot independently verify DoD from the executor report alone.
Proposed fix: Copy/paste the raw output blocks from DIALOGUE.md into 02_EXECUTOR_REPORT.md, and keep them synchronized.

[iter=2] Title: WP §7 "log blocked signals" not demonstrable in Stage1 run
Severity: P1
Path: logs/events.jsonl; STRATEGY_KNOWLEDGE_BASE.md §7
Expected: jsonl includes both decision events and blocked/suppressed-signal events for auditability.
Actual: Available evidence shows only `event: "decision"` records (startup / wiring-only). No `gate_blocked` / `signal_suppressed` examples are present.
Evidence: DIALOGUE.md:40-44 shows only `event":"decision"` lines; config.py defines blocked event names but Stage1 run message is "Stage1 wiring only: no strategy evaluation".
Impact: Logging compliance with WP §7 cannot be validated end-to-end; risk that future gate blocks are not logged.
Proposed fix: Add a deterministic "simulated blocked signal" path in Stage1 smoke run (no trading) that emits a `gate_blocked` and `signal_suppressed` event, OR explicitly document as Stage1 limitation + add a test requirement for Stage2.

[iter=2] Title: Percent/rounding/tick-size placeholders may cause edge-condition drift
Severity: P2
Path: config.py (as embedded in .opencode/workflow/02_EXECUTOR_REPORT.md)
Expected: Deterministic comparison semantics around WP thresholds; exchange tick size/precision sourced or explicitly constrained; avoid float edge drift.
Actual: Stage1 introduces placeholder tick/rounding knobs and uses float thresholds (e.g., SWEEP_BUFFER=0.0015, BTC_RISK_OFF_RETURN_60M=-0.010) that may diverge at equality boundaries when engine is implemented.
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:235-241 (PRICE_TICK_SIZE/PRICE_DECIMALS/PRICE_ROUNDING/USE_DECIMAL_FOR_COMPARISONS) and :246-252 (BTC risk-off threshold fields).
Impact: Off-by-one-tick false positives/negatives in sweep/reclaim/gates; inconsistent behavior across venues.
Proposed fix: For Stage2, implement Decimal end-to-end + tests for equality-at-threshold; source tick/precision from exchange metadata with config override.

[iter=2] Title: Secrets logging policy not evidenced (TELEGRAM_* hygiene)
Severity: P2
Path: infrastructure/logger.py; logs/events.jsonl; config.py
Expected: Explicit guarantee that logs never include TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID (or any secrets), plus a small test/assertion.
Actual: TELEGRAM_* values are read from environment, but there is no evidence of an explicit sanitization/"never log secrets" policy or a test preventing accidental inclusion.
Evidence: .opencode/workflow/02_EXECUTOR_REPORT.md:193-195 (TELEGRAM_* from env); .opencode/workflow/04_AUDITOR_REPORT.md:11-12 (absence of proof flagged).
Impact: Potential secret leakage into jsonl audit logs.
Proposed fix: Add explicit logger guard + unit test that rejects keys matching TELEGRAM_* in payloads.


[iter=5] Title: Canonical artifact retention not enforced (selftest DESTRUCTIVE deletes workflow reports)
Severity: P0
Path: .opencode/workflow/selftest.sh
Expected: `.opencode/workflow/*` is canonical and persists across runs; backups in `_selftest_backup/*` must not replace/delete canonical artifacts.
Actual: DIALOGUE.md reports that when `DESTRUCTIVE=1`, `cleanup_state()` removes `.opencode/workflow/0{1,2,3,4,5}_*.md` after backing them up.
Evidence: DIALOGUE.md:45-46.
Impact: Breaks chain-of-custody; reviewers may read missing/empty canonical artifacts; acceptance becomes non-deterministic.
Proposed fix: Modify `cleanup_state()` to never delete workflow reports and never touch ISSUES.md/DIALOGUE.md; keep `_selftest_backup/*` as backup-only.

[iter=5] Title: Secrets may leak into jsonl logs (no proven sanitization policy)
Severity: P1
Path: infrastructure/logger.py; logs/events.jsonl; config.py TELEGRAM_* env vars
Expected: Explicit policy + guard/tests ensuring TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID and other secrets are never logged.
Actual: TELEGRAM_* is read from env; current evidence does not include an explicit “never log secrets” rule or test.
Evidence: config excerpt in 02_EXECUTOR_REPORT.md (TELEGRAM_* from env); critic/auditor notes in ISSUES.md:141-148.
Impact: Potential credential leakage into durable audit logs.
Proposed fix: Add logger validation that rejects keys matching TELEGRAM_* (or generic secret patterns) and add a unit/smoke test.

[iter=1] Title: Destructive selftest deletes canonical workflow reports (breaks source of truth)
Severity: P0
Path: .opencode/workflow/selftest.sh
Expected: `.opencode/workflow/{01..05}_*.md` artifacts persist at canonical paths after any run; `_selftest_backup/*` is backup-only.
Actual: In DESTRUCTIVE mode, `cleanup_state()` removes `.opencode/workflow/0{1,2,3,4,5}_*.md`.
Evidence: .opencode/workflow/selftest.sh:47-56 (rm at line 51).
Impact: Breaks chain-of-custody; reviewers may see missing/stale canonical reports; acceptance becomes non-deterministic.
Proposed fix: Modify `cleanup_state()` to never delete workflow reports and never touch ISSUES.md/DIALOGUE.md; keep backups separate.

[iter=1] Title: Destructive selftest deletes logs/events.jsonl (undermines WP §7 durability)
Severity: P1
Path: .opencode/workflow/selftest.sh
Expected: WP §7 jsonl logs are durable evidence; if cleaned, must be explicitly backed up and/or regenerated deterministically.
Actual: In DESTRUCTIVE mode, `cleanup_state()` deletes `logs/events.jsonl`.
Evidence: .opencode/workflow/selftest.sh:55.
Impact: Loss of audit data; weakens evidence for logging compliance.
Proposed fix: Do not delete by default, or always back up and restore; document policy.

[iter=1] Title: No enforced append-only guard for ISSUES.md
Severity: P0
Path: .opencode/workflow/ISSUES.md
Expected: Append-only integrity guard (fail run if line count decreases or content hash regresses).
Actual: Prior truncation incidents exist; no guard confirmed as implemented.
Evidence: .opencode/workflow/ISSUES.md:6-13 and 69-76.
Impact: Audit trail loss; unresolved blockers can disappear.
Proposed fix: Add guard in pipeline/selftest (snapshot before run + verify after run).


[iter=1] Title: selftest restores ISSUES.md snapshot (drops new issues)
Severity: P0
Path: .opencode/workflow/selftest.sh; .opencode/workflow/ISSUES.md
Expected: ISSUES.md is append-only and preserves new issues/questions across selftest/pipeline runs.
Actual: selftest snapshots ISSUES.md pre-run and later copies the snapshot back over the canonical file; it also fails the run if ISSUES.md content changes at all.
Evidence: selftest.sh lines 242-246 (PRE_ISSUES_* snapshot + tmp copy), lines 317-326 (FAIL if hash differs / line count decreases), lines 328-331 (cp pre-run tmp back to WF/ISSUES.md).
Impact: any newly appended P0/P1 issues during/after the run can be lost, recreating “ISSUES truncated/overwritten” symptoms and breaking chain-of-custody.
Proposed fix: Remove the post-run restore of ISSUES.md; replace “content must not change” with an append-only regression guard (post-run must include pre-run content as prefix and have >= line count).
Logged_at_utc: 2026-01-29T08:44:56Z

[iter=5] Title: Selftest destructive run timed out (pipeline contention)
Severity: P1
Path: .opencode/workflow/selftest.sh
Expected: Destructive selftest completes to verify canonical artifact retention.
Actual: `bash ./.opencode/workflow/selftest.sh --destructive --mode infra` timed out after 120s; pipeline log showed "another run is active, exiting" and executor rc=124.
Evidence: terminal output 2026-01-29T11:53+03:00 (timeout).
Impact: Cannot provide evidence that canonical reports remain after destructive selftest.
Proposed fix: Orchestrator to advise how to run selftest without pipeline contention or increase timeout.
Logged_at_utc: 2026-01-29T08:54:20Z

[iter=1] Update: selftest no longer restores ISSUES.md, but append-only guard is too weak
Severity: P0
Path: .opencode/workflow/selftest.sh; .opencode/workflow/ISSUES.md
Expected: Append-only integrity (post-run ISSUES must contain pre-run content as prefix, or a content-hash must not regress; line count alone is insufficient).
Actual: selftest tracks only PRE_ISSUES_LINES and fails only if line count decreases; it does not detect truncation+rewrite with equal/greater line count.
Evidence: .opencode/workflow/selftest.sh:246 (PRE_ISSUES_LINES snapshot), :338-342 (only line-count non-decrease check).
Impact: Audit trail can be lost without detection; prior P0 “ISSUES truncated/overwritten” can recur silently.
Proposed fix: Add prefix-regression guard (store pre-run content to temp and verify it remains a prefix) and/or content-hash monotonicity; never overwrite canonical ISSUES.
Logged_at_utc: 2026-01-29T12:27:00Z

[iter=1] Title: DIALOGUE.md was overwritten/truncated (audit trail risk)
Severity: P0
Path: .opencode/workflow/DIALOGUE.md
Expected: DIALOGUE.md retains full live dialogue history across iterations; no component should truncate/overwrite.
Actual: DIALOGUE.md content was overwritten/truncated during audit actions (lost prior messages).
Evidence: Prior DIALOGUE.md had 136 lines (see earlier audit readout); after overwrite it had 10 lines only.
Impact: Loss of inter-agent Q/A context and chain-of-custody for decisions; can hide unresolved requests.
Proposed fix: Enforce append-only/prefix-preservation guard for DIALOGUE.md similar to ISSUES.md; forbid any restore/overwrite in selftest/pipeline.
Logged_at_utc: 2026-01-29T09:29:00Z

[iter=1] Title: ISSUES.md append-only guard only checked line count (now hardened)
Severity: P1
Path: .opencode/workflow/selftest.sh
Expected: Append-only integrity requires pre-run content preserved as prefix (not just line count).
Actual: Prior guard only checked line count; truncation+rewrite could bypass.
Evidence: DIALOGUE.md to:@executor (item 66); selftest.sh previously used PRE_ISSUES_LINES only.
Impact: Risk of silent audit trail regression.
Proposed fix: Implement prefix-preservation check; completed by adding snapshot_issues_prefix/check_issues_prefix.
Logged_at_utc: 2026-01-29T10:10:00Z

[iter=1] Title: Logger lacks secret redaction (now hardened)
Severity: P1
Path: infrastructure/logger.py
Expected: TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID must never be logged.
Actual: Logger merged arbitrary context into payload without redaction.
Evidence: DIALOGUE.md to:@executor (item 67); logger.py lines 19-27 pre-change.
Impact: Secret leakage into jsonl logs possible.
Proposed fix: Added _sanitize_context denylist for TELEGRAM_* keys in log_event.
Logged_at_utc: 2026-01-29T10:10:00Z


[iter=1] Critic update:

Title: DIALOGUE.md has no append-only integrity guard
Severity: P0
Path: .opencode/workflow/DIALOGUE.md; .opencode/workflow/selftest.sh
Expected: DIALOGUE.md preserved append-only (prefix-preservation), similar to ISSUES.md, across pipeline/selftest runs.
Actual: selftest.sh implements snapshot_issues_prefix/check_issues_prefix for ISSUES.md but has no analogous snapshot/check for DIALOGUE.md.
Evidence: selftest.sh:70-97 (ISSUES prefix guard exists); no corresponding functions for DIALOGUE in selftest.sh (grep found none).
Impact: dialogue/Q&A context can be lost; unresolved requests/decisions can disappear.
Proposed fix: add snapshot_dialogue_prefix/check_dialogue_prefix and fail run if prefix not preserved.

Title: WP §7 blocked-signal logging not demonstrable in Stage1 evidence
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md §7; main.py; logs/events.jsonl
Expected: jsonl contains decisions including blocked/suppressed signals.
Actual: Stage1 run shows only event=decision (startup/wiring); no gate_blocked/signal_suppressed examples.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:135-136; main.py:27-35; 02_EXECUTOR_REPORT.md:344-346.
Impact: required forensic trace is unproven.
Proposed fix: deterministic Stage1 smoke emission (no trading) OR explicit Stage2 test requirement.

Title: Gate 1 BTC Risk-Off comparator decision pending (strict vs non-strict)
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md §4.1 vs §4.4; config.py
Expected: single canonical comparator for btc_return_60m threshold at exactly -1.0%.
Actual: config leaves BTC_RISK_OFF_COMPARATOR=None and records both candidates.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; config.py:87-92.
Impact: equality boundary behavior undefined.
Proposed fix: PM/Orchestrator decides (< vs <=) then collapse config and add boundary test.

Title: DESTRUCTIVE selftest deletes logs/events.jsonl (policy decision required)
Severity: P1
Path: .opencode/workflow/selftest.sh; logs/events.jsonl
Expected: policy-defined handling of jsonl audit log (durable vs ephemeral), consistent with WP §7.
Actual: cleanup_state deletes logs/events.jsonl.
Evidence: selftest.sh:53.
Impact: audit evidence can be lost.
Proposed fix: stop deleting (if durable) OR explicitly declare ephemeral and always regenerate evidence.

[iter=1] Title: DIALOGUE.md lacks append-only integrity guard (still unprotected)
Severity: P0
Path: .opencode/workflow/DIALOGUE.md; .opencode/workflow/selftest.sh
Expected: DIALOGUE.md preserved append-only (prefix-preservation) across pipeline/selftest runs, analogous to ISSUES.md.
Actual: selftest.sh implements snapshot_issues_prefix/check_issues_prefix, but has no snapshot/check for DIALOGUE.md; prior truncation incidents remain possible.
Evidence: selftest.sh:70-97 (ISSUES prefix guard); no functions for DIALOGUE; prior truncation logged earlier in ISSUES.md.
Impact: Loss of live Q/A context and chain-of-custody; unresolved requests/decisions can disappear.
Proposed fix: Add snapshot_dialogue_prefix/check_dialogue_prefix with prefix-preservation semantics; forbid any overwrite/truncate.
Logged_at_utc: 2026-01-29T13:15:00Z

[iter=1] Title: Gate 1 BTC Risk-Off comparator decision still pending (strict vs non-strict)
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md §4.1 vs §4.4; config.py
Expected: Single canonical comparator for btc_return_60m at exactly -1.0%.
Actual: BTC_RISK_OFF_COMPARATOR remains None; both candidates recorded.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:59-60 vs 76-77; config.py:87-92.
Impact: Undefined equality behavior; future engine/backtests may diverge.
Proposed fix: PM/Orchestrator decides (< vs <=), then collapse config to one comparator and add boundary test.
Logged_at_utc: 2026-01-29T13:15:00Z

[iter=1] Title: WP §7 blocked/suppressed-signal logging not demonstrable in Stage1 run
Severity: P1
Path: STRATEGY_KNOWLEDGE_BASE.md §7; main.py; logs/events.jsonl
Expected: jsonl includes every decision including blocked/suppressed signals.
Actual: Stage1 run emits only event="decision" entries (startup/wiring), no gate_blocked/signal_suppressed examples.
Evidence: STRATEGY_KNOWLEDGE_BASE.md:135-136; main.py:27-35.
Impact: Required forensic trace is unproven end-to-end.
Proposed fix: Add deterministic Stage1 smoke emission (no trading) of gate_blocked+signal_suppressed, or explicitly defer with mandatory Stage2 tests.
Logged_at_utc: 2026-01-29T13:15:00Z

[iter=1] Title: DESTRUCTIVE selftest deletes logs/events.jsonl (policy needed)
Severity: P1
Path: .opencode/workflow/selftest.sh; logs/events.jsonl
Expected: Policy-defined handling for WP §7 jsonl log (durable vs ephemeral), consistent with evidence needs.
Actual: cleanup_state() in DESTRUCTIVE mode removes logs/events.jsonl.
Evidence: selftest.sh:46-55 (rm -f logs/events.jsonl at line 53).
Impact: Loss of audit evidence if logs intended durable.
Proposed fix: Decide policy; if durable, stop deleting or backup+restore; if ephemeral, document and ensure reports regenerate evidence deterministically.
Logged_at_utc: 2026-01-29T13:15:00Z
