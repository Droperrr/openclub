# SOL Liquidity Navigator — Ops Quick Start

## What is this

This repository ships an **agent team product** under `.opencode/**` with a deterministic INFRA selftest gate and CI workflow.

## Install

Install opencode workflow into a project root:

```bash
./install-opencode-team.sh --install
```

Target another directory:

```bash
./install-opencode-team.sh --install --target /path/to/project
```

## Run selftest (INFRA gate)

```bash
bash .opencode/workflow/selftest.sh --mode infra --wait 900
```

## Update

Update (reinstall) `.opencode/**` in a project:

```bash
./install-opencode-team.sh --update --target /path/to/project
```

**Warning:** update overwrites `.opencode/**`. See `UPGRADE.md` for details.

## Version

Current team version is stored in:

```bash
cat .opencode/VERSION
```

## Release / versioning policy

- VERSION uses datever (YYYY.MM.DD) and is the source of truth.
- Git tags use `v<YYYY.MM.DD>` and must match `.opencode/VERSION`.
- All changes are recorded in `CHANGELOG.md`.
- Updates are delivered via `install-opencode-team.sh --update`.

## Requirements

Linux only. Required tools:
- bash
- coreutils (cp, rm, mkdir, head, tail)
- flock
- timeout
- grep
- rsync
- oc in PATH (configured and authenticated)

## Project-specific config

Currently only requires `oc` configured and accessible in PATH. All other settings are defaulted inside `.opencode/`.

## CI

GitHub Actions workflow runs the INFRA gate:

```
.github/workflows/infra-selftest.yml
```

INFRA is the CI gate. GREEN is optional/nightly.
