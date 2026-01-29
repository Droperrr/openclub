# 01_ARCH_TASKS (Architect -> Team)

iter=5

## TASKS

### @executor (implementation + evidence)
1) **Stage1 scaffolding compliance (stage1-spec)**
   - Verify project tree matches exact Stage1 layout:
     - `STRATEGY_KNOWLEDGE_BASE.md` (exists)
     - `config.py` (ONLY source of settings)
     - `main.py`
     - `core/{__init__.py,engine.py,market_data.py,shadow_lab.py}`
     - `infrastructure/{__init__.py,logger.py,telegram_bot.py}`
     - `logs/.gitkeep`
   - Provide evidence-grade output (raw, pasted):
     - Preferred: `pwd && python3 --version && tree -a`
     - If `tree` unavailable: `find . -maxdepth 3 -type f | sort`

2) **config.py completeness vs White Paper (STRATEGY_KNOWLEDGE_BASE.md)**
   - Ensure **EVERY numeric threshold and condition** from WP is extracted into `config.py` with per-variable comment:
     - *why* (reason) + **WP section reference** (e.g., “WP §3.2”).
   - Must include at minimum:
     - Liquidity cluster threshold: aggregated liquidation cluster volume `> $20M` (WP §3.1)
     - Sweep buffer: `0.15%` / `0.0015` (WP §3.2)
     - Reclaim rule: close back above cluster level (WP §3.2)
     - Confirm candles: `3` consecutive candles holding above (WP §3.3)
     - Gate 1 BTC risk-off: `1.0%` drop over last `60` minutes (**comparator is PM decision**; do not silently choose) (WP §4.1 / §4.4)
     - Gate 2 ADX(14) H1 threshold: `> 25` (WP §4.2)
     - Gate 3 weekend hard stop: Fri `21:00 UTC` → Mon `06:00 UTC` (WP §4.3)
     - Risk: fixed risk per trade `$10`, daily stop loss `-$20` + stop until next day (WP §5.3)
     - Shadow lab leaders: `BTC, ETH, JUP, WIF` (WP §6.1)
     - Instrument/timeframes: `SOL/USDT-PERP`, entry TFs `M1/M5`, context TF `H1` (WP §2)
     - Logging requirement: jsonl “every decision including blocked signals” (WP §7)
   - Paste **full** `config.py` content into 02 report (self-contained review).

3) **No hardcoded WP numbers outside config.py**
   - Provide evidence that `core/*` and `infrastructure/*` contain no WP numeric constants/business logic beyond wiring.
   - Acceptable evidence: short code excerpts per file, or deterministic scan output.

4) **WP §7 durable jsonl logging evidence**
   - Run and paste raw outputs (single atomic block) into 02 report:
     - `python3 main.py && ls -la logs && head -n 5 logs/events.jsonl`
   - Confirm timestamps are **UTC with explicit tz offset** (ISO8601 `+00:00`).
   - Confirm file handle flush/close on exit.
   - If Stage1 emits only `event:"decision"`, explicitly document that blocked/suppressed events are a Stage2 requirement (and ensure it is present in ISSUES.md).

5) **P0: Canonical workflow artifact retention (selftest DESTRUCTIVE)**
   - Root cause identified in DIALOGUE.md: `.opencode/workflow/selftest.sh` with `DESTRUCTIVE=1` previously deleted `.opencode/workflow/0{1..5}_*.md`.
   - Action:
     - Patch/verify `.opencode/workflow/selftest.sh` so `cleanup_state()` **never** deletes:
       - `.opencode/workflow/0{1,2,3,4,5}_*.md`
       - `.opencode/workflow/ISSUES.md`
       - `.opencode/workflow/DIALOGUE.md`
     - Provide file+line evidence in 02 report.
     - Re-run the selftest in the same mode used by pipeline and confirm canonical reports remain present after the run.

6) **P0: ISSUES.md append-only semantics (do NOT clobber)**
   - Current risk per ISSUES.md: selftest snapshots ISSUES.md then restores pre-run snapshot post-run, which can drop newly logged issues.
   - Required behavior:
     - ISSUES.md may grow (append-only); it must never be overwritten with a pre-run copy.
     - Selftest/pipeline must fail if ISSUES.md regresses (line count decreases or pre-run content is not a prefix).
   - Action:
     - Update `selftest.sh` guard logic accordingly (append-only, no restore).
     - Provide file+line evidence in 02 report.

7) **Gate-1 boundary decision request (PM decision required)**
   - Surface ambiguity (do not choose silently):
     - WP prose “fell more than 1.0%” ⇒ strict `< -0.010`.
     - WP pseudocode uses `<= -0.010`.
   - Keep config explicitly marked “PM decision required” until approved.

8) **Secrets hygiene (logging)**
   - Confirm TELEGRAM secrets (`TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`) are never logged.
   - If no explicit sanitization exists, document as TODO + raise/keep an ISSUE with proposed guard/test.

---

### @critic (canon/spec verification)
1) Verify Stage1 scaffolding vs **stage1-spec**.
2) Verify `config.py` vs **STRATEGY_KNOWLEDGE_BASE.md**:
   - every WP number/condition present,
   - each has “why” + WP reference,
   - no strategy drift (no extra rules).
3) Special focus:
   - Gate-1 comparator ambiguity (WP §4.1 vs §4.4 pseudocode).
   - WP §7 requirement “including blocked signals” vs Stage1 wiring-only limitation.
   - P0 workflow integrity: canonical reports retention + ISSUES.md append-only semantics.
4) Provide verdict: **approve** / **request changes**.

---

### @auditor (risk + hygiene)
1) Validate UTC correctness:
   - timestamps are timezone-aware (`+00:00`)
   - weekend stop boundaries evaluated strictly in UTC (no local-time dependence).
2) Validate WP §7 logging posture:
   - durable `logs/events.jsonl` after `python3 main.py`.
   - call out Stage1 limitation if blocked/suppressed events aren’t emitted yet.
3) Validate artifact retention policy:
   - `.opencode/workflow/*` is canonical source of truth,
   - `_selftest_backup/*` is backup-only,
   - selftest/pipeline must not delete canonical reports.
4) Validate ISSUES.md integrity:
   - append-only; no snapshot restore; guard catches regressions.
5) Secrets-in-logs risk assessment:
   - verify no TELEGRAM_* leaks,
   - recommend guard + minimal test.
6) Provide verdict: **approve** / **request changes**.

## COLLECT
- `.opencode/workflow/02_EXECUTOR_REPORT.md` (non-empty; contains raw evidence outputs + full config.py + selftest policy evidence)
- `.opencode/workflow/03_CRITIC_REPORT.md` (non-empty; canon/spec verdict)
- `.opencode/workflow/04_AUDITOR_REPORT.md` (non-empty; risk/hygiene verdict)
