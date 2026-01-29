# 01_ARCH_TASKS (Architect -> Team) — MODE A / iter=2

Контекст (PM): Этап 1 = scaffolding + `config.py` строго по White Paper (STRATEGY_KNOWLEDGE_BASE.md) и stage1-spec.
Ограничения: стратегию не менять без PM APPROVED; STRATEGY_KNOWLEDGE_BASE.md не править.

Наблюдения по текущему состоянию (из ISSUES/DIALOGUE):
- P0/P1 риски по chain-of-custody: selftest/pipeline ранее удаляли/перемещали канонические workflow-артефакты; были инциденты с перезаписью/усечением ISSUES/DIALOGUE.
- Нужны решения PM/Orchestrator: (1) компаратор Gate1 BTC Risk-Off на границе -1.0%; (2) политика retention для `logs/events.jsonl` в DESTRUCTIVE selftest; (3) политика runtime-артефактов.

---

## TASKS

### @executor (implementation + evidence)
1) **Stage1 scaffolding compliance (stage1-spec) — evidence-grade**
   - Provide a deterministic project tree proving the scaffold matches stage1-spec exactly:
     - `STRATEGY_KNOWLEDGE_BASE.md`, `config.py`, `main.py`
     - `core/{__init__.py,engine.py,market_data.py,shadow_lab.py}`
     - `infrastructure/{__init__.py,logger.py,telegram_bot.py}`
     - `logs/.gitkeep`
   - Paste raw output in the report (no paraphrase), e.g. `pwd && python3 --version && tree -a` (or `find ... | sort`).

2) **`config.py` completeness vs White Paper (all numbers/conditions + why+WP ref)**
   - Ensure **every** numeric threshold / condition from STRATEGY_KNOWLEDGE_BASE.md is present in `config.py`.
   - Every parameter must have a comment: **why + WP section reference**.
   - Minimum required WP items:
     - Cluster volume threshold: > **$20M** (WP §3.1)
     - Sweep buffer: **0.15%** (WP §3.2)
     - Confirm candles: **3** (WP §3.3)
     - Gate1 BTC risk-off: **-1.0% over last 60m** (WP §4.1 + §4.4)
     - Gate2 ADX(14) H1 **> 25** (WP §4.2)
     - Gate3 weekend stop: **Fri 21:00 UTC → Mon 06:00 UTC** (WP §4.3)
     - Fixed risk per trade: **$10** (WP §5.3)
     - Daily stop loss: **-$20** (WP §5.3)
     - Shadow lab leaders: **BTC, ETH, JUP, WIF** (WP §6.1)
     - Logging: jsonl, incl. blocked/suppressed decisions (WP §7)
   - Paste full `config.py` into the report.

3) **No strategy constants/business logic outside `config.py` (stage1-spec)**
   - Provide evidence that other modules (core/*, infrastructure/*, main.py) do not hardcode WP thresholds/constants.
   - Evidence format: short excerpts per file showing values read from config only.

4) **WP §7 durable jsonl logging — reproducible proof**
   - Run and paste raw output (single atomic chain) in the report:
     - `python3 main.py && ls -la logs && head -n 20 logs/events.jsonl`
   - Confirm timestamps are UTC ISO8601 with offset (+00:00).

5) **Secrets hygiene (TELEGRAM_* must never leak into jsonl)**
   - Confirm `infrastructure/logger.py` sanitizes/denylists TELEGRAM_* keys.
   - Add a minimal smoke/unit check (or explicit attestation) proving a payload containing TELEGRAM_BOT_TOKEN does not end up in `events.jsonl`.

6) **Workflow integrity / chain-of-custody guards (P0)**
   - Ensure selftest/pipeline **never** deletes/moves canonical workflow artifacts under `.opencode/workflow/`.
   - Specifically validate and reference (file+line) what DESTRUCTIVE cleanup does/does not delete:
     - `.opencode/workflow/0{1..5}_*.md` must persist
     - `.opencode/workflow/ISSUES.md` must be append-only (no truncate/overwrite)
     - `.opencode/workflow/DIALOGUE.md` must be append-only (no truncate/overwrite)
   - If DIALOGUE.md prefix-preservation guard is missing, implement it analogously to ISSUES.md.

7) Deliver: `.opencode/workflow/02_EXECUTOR_REPORT.md`
   - Must be self-contained: STATUS / FILES / TREE / COMMANDS / RAW OUTPUTS / NOTES-RISKS.


### @critic (canon/spec verification)
1) Verify scaffolding vs stage1-spec; call out any missing/extra files.
2) Verify `config.py` vs STRATEGY_KNOWLEDGE_BASE.md:
   - all WP numbers/conditions extracted;
   - each has “why + WP ref”;
   - no extra strategy rules introduced.
3) Highlight ambiguity requiring PM decision (do not decide unilaterally):
   - Gate1 BTC Risk-Off comparator at exactly -1.0% (`<` vs `<=`) due to WP §4.1 prose vs §4.4 pseudocode mismatch.
4) Verify Stage1 evidence quality: outputs pasted (tree + logging chain) and consistent.
5) Deliver: `.opencode/workflow/03_CRITIC_REPORT.md` (SUMMARY / MISSING / MISMATCHES / RISKS / VERDICT).


### @auditor (risk + hygiene)
1) Verify WP §7 logging posture:
   - jsonl is durable at `./logs/events.jsonl`;
   - evidence includes both creation + sample lines.
   - If Stage1 doesn’t yet demonstrate `gate_blocked`/`signal_suppressed`, record as limitation with explicit next-step requirement.
2) Validate secrets hygiene (TELEGRAM_* redaction) + require a test/guard if missing.
3) Validate chain-of-custody:
   - `.opencode/workflow/*` is canonical source of truth;
   - no destructive cleanup of workflow reports;
   - ISSUES.md and DIALOGUE.md are append-only with prefix-preservation.
4) Provide a clear Stage1 runtime-artifacts policy recommendation (allowed+ignored vs cleanup/guard) for:
   - `logs/events.jsonl` (WP §7)
   - repo-root `_selftest_backup/`
   - `__pycache__/` / `*.pyc`
   - explicitly forbid `.opencode/_selftest_backup/**`.
5) Deliver: `.opencode/workflow/04_AUDITOR_REPORT.md` (CHECKLIST / FINDINGS / RECOMMENDATIONS).


## COLLECT
- `.opencode/workflow/02_EXECUTOR_REPORT.md`
- `.opencode/workflow/03_CRITIC_REPORT.md`
- `.opencode/workflow/04_AUDITOR_REPORT.md`


## PM / Orchestrator decisions required (blocking)
1) Gate 1 BTC Risk-Off boundary at exactly -1.0%: choose strict `< -0.010` vs non-strict `<= -0.010` (WP §4.1 prose vs §4.4 pseudocode).
2) Policy for `logs/events.jsonl` under DESTRUCTIVE selftest: durable (keep/backup+restore) vs explicitly ephemeral (delete ok, but evidence must be regenerated deterministically).
3) Stage1 runtime-artifacts policy for `_selftest_backup/` and `__pycache__/`/`*.pyc` (allowed+ignored vs cleanup/guard).
