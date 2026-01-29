# 01_ARCH_TASKS (Architect -> Team)

Iter: 1

TASKS:

- @executor (implementation + evidence)
  1) Stage1 scaffolding compliance (per stage1-spec)
     - Ensure project tree matches exact layout:
       - STRATEGY_KNOWLEDGE_BASE.md (exists)
       - config.py (ONLY source of settings)
       - main.py
       - core/{__init__.py, engine.py, market_data.py, shadow_lab.py}
       - infrastructure/{__init__.py, logger.py, telegram_bot.py}
       - logs/.gitkeep
     - Provide evidence-grade raw output in 02 report:
       - preferred: `pwd && python3 --version && tree -a`
       - if tree unavailable: `find . -maxdepth 3 -type f | sort`

  2) config.py completeness vs White Paper (STRATEGY_KNOWLEDGE_BASE.md)
     - Extract EVERY number/condition from WP into config.py.
     - Each variable must have a short comment: why + WP section reference.
     - Must include (minimum set):
       - WP §2: instrument SOL/USDT-PERP; entry TFs M1/M5; context TF H1
       - WP §3.1: liquidation cluster threshold volume > $20M
       - WP §3.2: sweep buffer 0.15% (0.0015); reclaim = close above level
       - WP §3.3: confirmation candles = 3 consecutive candles above level
       - WP §4.1/§4.4: Gate 1 BTC risk-off: 1.0% drop over last 60 minutes (comparator ambiguity must be surfaced; do not choose silently)
       - WP §4.2: Gate 2 ADX(14) on H1 > 25
       - WP §4.3: Gate 3 weekend stop: Fri 21:00 UTC → Mon 06:00 UTC
       - WP §5.3: fixed risk per trade $10; daily stop loss -$20 (stop until next day)
       - WP §6.1: Shadow Lab leaders list: BTC, ETH, JUP, WIF
       - WP §7: jsonl logging of every decision including blocks
     - Paste full config.py content into 02 report.

  3) No hardcoded WP numbers outside config.py
     - Ensure core/* and infrastructure/* contain no WP numeric constants and no strategy business logic beyond wiring.
     - Provide evidence (snippets per file, or deterministic scan output) in 02 report.

  4) WP §7 durable jsonl logging (proof)
     - Run and paste raw outputs (single atomic block) into 02 report:
       - `python3 main.py && ls -la logs && head -n 5 logs/events.jsonl`
     - Confirm timestamps are UTC timezone-aware (ISO8601 with +00:00).
     - Confirm file handle flush/close on exit.
     - If Stage1 is wiring-only and does not yet emit `gate_blocked` / `signal_suppressed`, explicitly document as Stage1 limitation + TODO/issue for Stage2.

  5) Workflow integrity (must be deterministic)
     - Ensure canonical workflow artifacts persist under `.opencode/workflow/*` after runs.
     - Address known risk from ISSUES/DIALOGUE: destructive selftest/pipeline may delete/relocate canonical reports; fix/guard so `.opencode/workflow/{01..05}_*.md` remain source of truth.
     - Ensure `.opencode/workflow/ISSUES.md` is append-only and never clobbered/truncated by automation.

  6) Produce `.opencode/workflow/02_EXECUTOR_REPORT.md` (canonical path, non-empty)
     - Include: STATUS / FILES / TREE / COMMANDS+RAW OUTPUTS / NOTES-RISKS.

- @critic (canon/spec verification)
  1) Verify Stage1 scaffolding vs stage1-spec.
  2) Verify config.py vs STRATEGY_KNOWLEDGE_BASE.md:
     - all WP numbers/conditions present;
     - each has “why” + WP section reference;
     - no strategy drift (no extra rules).
  3) Highlight and log mismatches/decisions needed (notably Gate 1 comparator ambiguity: “more than 1.0%” vs pseudocode `<= -0.010`).
  4) Write `.opencode/workflow/03_CRITIC_REPORT.md` with evidence + verdict (approve / request changes).

- @auditor (risk + hygiene)
  1) Validate UTC correctness (timestamps + weekend gate boundaries in UTC; no naive datetimes).
  2) Validate WP §7 logging posture (durable jsonl, and plan for blocked-signal logging).
  3) Validate artifact retention policy and single source of truth:
     - `.opencode/workflow/*` is canonical; `_selftest_backup/*` backup-only.
  4) Validate ISSUES.md integrity (append-only; no overwrite/regression).
  5) Validate secrets hygiene (no TELEGRAM_* leakage into logs; recommend guard/test if missing).
  6) Write `.opencode/workflow/04_AUDITOR_REPORT.md` with findings + recommendations.

COLLECT:
- 02_EXECUTOR_REPORT.md: tree evidence, full config.py, raw command outputs (run proof), notes/risks.
- 03_CRITIC_REPORT.md: canon/spec mismatches, missing items, risks, verdict.
- 04_AUDITOR_REPORT.md: checklist, findings (artifact retention, ISSUES append-only, secrets, UTC), recommendations.
