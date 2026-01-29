# Changelog

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
