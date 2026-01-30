# Acceptance Criteria & Operations (Definition of Done)

## Selftest modes

### INFRA (CI gate)
INFRA validates infrastructure only and must be fast/deterministic.

**Pass criteria (all must be true in current log window):**
1. **Pipeline milestones:**
   - `[pipeline] start run_id=<id> root=<abs_root>`
   - `done role=orchestrator`
   - `done role=executor`
2. **Single-flight proof:** at least one `[pipeline] another run is active, exiting`.
3. **Log cleanliness:** no forbidden patterns:
   - `Permission required`
   - `Terminated`
   - `opencode run [message..]`
   - `ERROR.*rc=0`
4. **Artifact check:** `.opencode/workflow/02_EXECUTOR_REPORT.md` exists and size > 0.

**Runtime UX requirement:** `00_PM_REQUEST.md` must exist after install (may be empty) and is never modified by selftest/cleanup.

### GREEN (optional / nightly)
GREEN validates content (approval) and is not a CI gate.

**Pass criteria (all must be true in current log window):**
1. `[pipeline] approved, done`
2. `02/03/04/05` reports exist and size > 0.
3. **Log cleanliness:** forbidden patterns are absent (same as INFRA).

If `approved, done` is not found, GREEN must fail and report:
- `approved, done not found`
- `05 ignored because not from current run`

## Backup path

Selftest backups are written to:
```
.opencode/workflow/_selftest_backup/<timestamp>/
```

## Log API markers (contract)

Selftest relies on these markers in `daemon.log`:
- `[pipeline] start`
- `done role=orchestrator`
- `done role=executor`
- `done role=critic`
- `done role=auditor`
- `[pipeline] another run is active, exiting`
- `[pipeline] approved, done`

## Operations Cheatsheet

### 1. Run Automated Selftest
Checks infrastructure health without destroying data (by default).
```bash
bash .opencode/workflow/selftest.sh
```
Options:
* `--destructive`: Wipes logs/reports for a clean slate test.
* `--mode infra|green`: Select selftest mode.
* `--wait 900`: Set custom timeout (default 1800s).

### 2. Trigger Pipeline Manually
```bash
printf "\nManual Trigger: %s\n" "$(date)" >> .opencode/workflow/00_PM_REQUEST.md
```

### 3. Monitor Logs
```bash
tail -f .opencode/workflow/daemon.log
```
