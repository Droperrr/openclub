# Changelog

## 2026.01.31-brainstorm.6

### Added
- Persistent CONTEXT.md with sha256 recorded in META.
- `--no-context` flag for brainstorm CLI.
- Model presets reference with available model IDs.

### Changed
- Runner writes 00_PROMPT.md with optional Context block.

## 2026.01.31-brainstorm.5

### Added
- Config-driven rounds, roles, and prompts in `brainstorm.yml`.
- Per-round files and transcript sections with round headers.
- Brainstorm log markers now include full `model_id` values.
- Graceful degrade for missing modelB and short outputs.

### Changed
- Runner uses round-aware prompts and synthesis settings from config.

## 2026.01.31-brainstorm.4

### Added
- Short-circuit for `/brainstorm` to bypass dev pipeline markers.
- Brainstorm chat validates text and errors when config is missing.

### Changed
- Pipeline exits early on brainstorm requests to avoid dev markers.

## 2026.01.31-brainstorm.3

### Added
- Chat trigger for `/brainstorm` and `brainstorm:` in chat mode.
- Brainstorm chat runner that writes `LAST_SESSION`.

### Changed
- Pipeline routes chat brainstorm requests to runner with transcript output.

## 2026.01.31-brainstorm.2

### Added
- Brainstorm stdout output with BEGIN/END transcript blocks.
- Brainstorm flags: `--quiet` and `--tail N`, with validation.

### Changed
- Brainstorm command supports transcript printing without changing artifacts.

## 2026.01.31-brainstorm.1

### Added
- Brainstorm config file for roles, models, and output length thresholds.
- Brainstorm runner that writes META, role outputs, synthesis, and transcript.
- `club brainstorm` command with session metadata reporting.

### Changed
- Brainstorm artifacts are written under workflow/brainstorm sessions with model IDs.

## 2026.01.31

### Added
- Chat-first UX: `club ask` triggers pipeline and logs run_id/root for each run.
- Executor report now captures real commands/results for chat runs.

### Changed
- Pipeline chat-mode runs orchestrator→executor only, avoiding manual file edits.

## 2026.01.30

### Added
- Runner-safe INFRA contract: 02 report required, run_id/root log API, and global club launcher.
- Installer guarantee for 00_PM_REQUEST.md.

### Changed
- Pipeline log start includes run_id and root for deterministic selftest gating.
- Runtime artifacts removed from template tracking and ignored by git.

## 2026.01.29

### Added
- INFRA selftest gate with deterministic single-flight validation (v2.1).
- CI workflow for INFRA gate (`.github/workflows/infra-selftest.yml`).
- Installer/update script `install-opencode-team.sh`.
- Product version file `.opencode/VERSION` and version output in selftest.
- Acceptance contract updates for INFRA/GREEN modes and backup path.

### Changed
- Backup path standardized to `.opencode/workflow/_selftest_backup/<timestamp>/`.
- README quick start sections for install/update/CI.

### Fixed
- GREEN honesty: fail when `approved, done` is missing and ignore stale 05.
