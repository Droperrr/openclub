STATUS: FAIL
FILES: changed
- .opencode/workflow/02_EXECUTOR_REPORT.md
- .opencode/workflow/DIALOGUE.md
TREE:
.
├── STRATEGY_KNOWLEDGE_BASE.md
├── config.py
├── core
│   ├── __init__.py
│   ├── engine.py
│   ├── market_data.py
│   ├── shadow_lab.py
│   └── __pycache__
│       ├── __init__.cpython-310.pyc
│       ├── engine.cpython-310.pyc
│       ├── market_data.cpython-310.pyc
│       └── shadow_lab.cpython-310.pyc
├── infrastructure
│   ├── __init__.py
│   ├── logger.py
│   ├── telegram_bot.py
│   └── __pycache__
│       ├── __init__.cpython-310.pyc
│       ├── logger.cpython-310.pyc
│       └── telegram_bot.cpython-310.pyc
├── logs
│   ├── .gitkeep
│   └── events.jsonl
├── main.py
├── __pycache__
│   ├── config.cpython-310.pyc
│   └── main.cpython-310.pyc
├── _selftest_backup
│   ├── 20260129_064655
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   └── 20260129_065659
│       ├── 02_EXECUTOR_REPORT.md
│       ├── 03_CRITIC_REPORT.md
│       ├── 04_AUDITOR_REPORT.md
│       ├── daemon.log
│       ├── DIALOGUE.md
│       └── ISSUES.md
├── selftest_final.log
├── selftest_green.log
└── selftest_infra.log
OUTPUT:
Stage1 scaffolding compliance:
- Required structure present: STRATEGY_KNOWLEDGE_BASE.md, config.py, main.py, core/{__init__.py,engine.py,market_data.py,shadow_lab.py}, infrastructure/{__init__.py,logger.py,telegram_bot.py}, logs/.gitkeep (see TREE).
- main.py wiring-only: only logger setup and startup decisions (main.py:16-35). No business logic outside engine modules.

config.py completeness vs White Paper (line refs):
- Cluster threshold >$20M: LIQUIDATION_CLUSTER_USD=20_000_000, comparator '>' (config.py:64-65, WP §3.1).
- Sweep buffer 0.15%: SWEEP_BUFFER=0.0015 (config.py:66, WP §3.2).
- Confirmation holds 3 candles: CONFIRM_CANDLES=3 (config.py:73, WP §3.3).
- Gate1 BTC risk-off -1.0% over 60m + comparator ambiguity noted: BTC_RISK_OFF_RETURN_60M=-0.010, comparator <= plus prose '<' stored (config.py:87-91, WP §4.1 vs §4.4).
- Gate2 ADX(14) H1 > 25: ADX_LENGTH=14, ADX_TIMEFRAME='H1', ADX_THRESHOLD=25, ADX_COMPARATOR='>' (config.py:92-95, WP §4.2).
- Gate3 weekend stop Fri 21:00 UTC → Mon 06:00 UTC: WEEKEND_STOP_START_WEEKDAY=4, START_MINUTE_UTC=1260, END_WEEKDAY=0, END_MINUTE_UTC=360 (config.py:99-103, WP §4.3).
- Risk $10 per trade, daily stop -$20: RISK_PER_TRADE_USD=10.0; DAILY_STOP_LOSS_USD=-20.0 with comparator <= (config.py:109-112, WP §5.3).
- Shadow lab leaders BTC/ETH/JUP/WIF: SHADOW_LAB_LEADERS=("BTC","ETH","JUP","WIF") (config.py:120, WP §6.1).
- Logging jsonl incl blocked signals: LOG_OUTPUT_TARGET="file", LOG_FILE_NAME="events", LOG_FILE_EXTENSION="jsonl", LOG_INCLUDE_BLOCKED_SIGNALS=True (config.py:16-19, WP §7). Logger writes jsonl to logs/events.jsonl (infrastructure/logger.py:29-34).

Operational evidence (Stage1 checks):
- `python3 -m py_compile config.py main.py core/__init__.py core/engine.py core/market_data.py core/shadow_lab.py infrastructure/__init__.py infrastructure/logger.py infrastructure/telegram_bot.py`
  Output: (no stdout/stderr)
- `python3 main.py`
  Output: (no stdout/stderr)
- logs/events.jsonl exists and contains records after main.py (logs/events.jsonl:1-2 show decision records).

Workflow hygiene:
- No `.opencode/_selftest_backup/**` present (tree shows only repo-root `_selftest_backup/`).
- Repo-root `_selftest_backup/` exists; assumed allowed, but policy confirmation pending.

Open decision / ambiguity:
- BTC Risk-Off comparator at exactly -1.0% remains ambiguous (WP §4.1 prose vs §4.4 pseudocode). Recommendation: PM decision to choose strict (< -0.010) vs non-strict (<= -0.010); remove unused comparator after decision.
COMMANDS:
- tree -a -L 3
- python3 -m py_compile config.py main.py core/__init__.py core/engine.py core/market_data.py core/shadow_lab.py infrastructure/__init__.py infrastructure/logger.py infrastructure/telegram_bot.py
- python3 main.py
NOTES/RISKS:
- STATUS set to FAIL only because PM/orchestrator decision is still required for BTC Risk-Off comparator at exactly -1.0% (documented in ISSUES.md).
- __pycache__/ artifacts exist due to py_compile; policy needed for cleanup/ignore.
- selftest.sh not executed here; not requested in 01_ARCH_TASKS.md. If required, need clarification on bash invocation vs “all commands via python3”.
