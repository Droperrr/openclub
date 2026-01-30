# Project configuration vs forbidden edits

This repository ships a ready-to-install `.opencode` runtime. After installation, **projects must only provide configuration**, not patch the workflow code. This keeps the template reproducible across projects.

## Allowed project configuration (OK to change)

- `PATH` so the `oc` CLI is discoverable.
- Environment variables / secrets:
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_CHAT_ID`
  - any other secrets required by your project
- Optional environment files:
  - `.env.example` (template values)
  - `.env` (project-local secrets, not committed)
- Project-specific runtime settings stored **outside** `.opencode` (if needed).

## Forbidden edits (do NOT change)

- Any edits to `.opencode/workflow/*.sh` after install/update.
- Any edits to `.opencode/agents/*.md` after install/update.
- Changing log API marker strings (e.g., `SELFTEST PASS/FAIL`, `[pipeline]` markers) without updating selftest contract.
- Local one-off patches (“project-specific hotfixes”) to the installed `.opencode` tree.

If you need changes, update the template repo and reinstall.
