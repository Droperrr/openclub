# Upgrade Guide

## Official update path

Update (reinstall) `.opencode/**` into a target project root:

```bash
./install-opencode-team.sh --update --target <project_root>
```

## Warning: overwrite behavior

**Update overwrites everything in `.opencode/**`.**

- Any manual changes inside `.opencode/**` will be lost.
- Project-specific configuration must live **outside** `.opencode/**`.

## Verify update

Check version before/after update:

```bash
cat .opencode/VERSION
```

Run health check:

```bash
bash .opencode/workflow/selftest.sh --mode infra --wait 900
```

## Rollback

If an update breaks your setup:

- Restore `.opencode/**` from your VCS (recommended), **or**
- Restore from backups created during selftest runs:
  `.opencode/workflow/_selftest_backup/<timestamp>/`

If you do not have a backup, re-clone the repo and reinstall.
