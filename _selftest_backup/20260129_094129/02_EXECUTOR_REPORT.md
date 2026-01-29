STATUS: FAIL
FILES: created .opencode/workflow/02_EXECUTOR_REPORT.md
TREE:
.
├── config.py
├── core
│   ├── engine.py
│   ├── __init__.py
│   ├── market_data.py
│   └── shadow_lab.py
├── infrastructure
│   ├── __init__.py
│   ├── logger.py
│   └── telegram_bot.py
├── logs
│   └── .gitkeep
├── main.py
├── .opencode
│   ├── agents
│   │   ├── architect.md
│   │   ├── auditor.md
│   │   ├── clear.md
│   │   ├── critic.md
│   │   ├── executor.md
│   │   └── orchestrator.md
│   ├── bun.lock
│   ├── .gitignore
│   ├── node_modules
│   │   ├── @opencode-ai
│   │   └── zod
│   ├── package.json
│   ├── skills
│   │   ├── orchestration-protocol
│   │   ├── stage1-spec
│   │   └── strategy-knowledge-base
│   └── workflow
│       ├── 00_PM_REQUEST.md
│       ├── 01_ARCH_TASKS.md
│       ├── ACCEPTANCE.md
│       ├── daemon_ctl.sh
│       ├── daemon.log
│       ├── daemon.pid
│       ├── daemon.sh
│       ├── DIALOGUE.md
│       ├── ISSUES.md
│       ├── .lock
│       ├── pipeline.sh
│       ├── .pm_request_hash
│       ├── .prompt_auditor_smoke.txt
│       ├── .prompt_auditor.txt
│       ├── .prompt_critic_smoke.txt
│       ├── .prompt_critic.txt
│       ├── .prompt_exec_smoke.txt
│       ├── .prompt_exec.txt
│       ├── .prompt_orch_a.txt
│       ├── .prompt_orch_b.txt
│       ├── .prompt__runner_selftest.txt
│       ├── .prompt_test_dialogue_by_exec.txt
│       ├── .prompt_test_runner_exec.txt
│       ├── .prompt_test_runner_orch.txt
│       ├── .prompt_test.txt
│       ├── runner.sh
│       ├── selftest.sh
│       ├── .step_critic.log
│       └── .step_executor.log
├── _selftest_backup
│   ├── 20260129_064655
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_065659
│   │   ├── 02_EXECUTOR_REPORT.md
│   │   ├── 03_CRITIC_REPORT.md
│   │   ├── 04_AUDITOR_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_071341
│   │   ├── 02_EXECUTOR_REPORT.md
│   │   ├── 03_CRITIC_REPORT.md
│   │   ├── 04_AUDITOR_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_071548
│   │   ├── 03_CRITIC_REPORT.md
│   │   ├── 04_AUDITOR_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_073111
│   │   ├── 02_EXECUTOR_REPORT.md
│   │   ├── 03_CRITIC_REPORT.md
│   │   ├── 04_AUDITOR_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_075114
│   │   ├── 02_EXECUTOR_REPORT.md
│   │   ├── 03_CRITIC_REPORT.md
│   │   ├── 04_AUDITOR_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_081119
│   │   ├── 02_EXECUTOR_REPORT.md
│   │   ├── 03_CRITIC_REPORT.md
│   │   ├── 04_AUDITOR_REPORT.md
│   │   ├── 05_ARCH_FINAL_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_091356
│   │   ├── 02_EXECUTOR_REPORT.md
│   │   ├── 03_CRITIC_REPORT.md
│   │   ├── 04_AUDITOR_REPORT.md
│   │   ├── 05_ARCH_FINAL_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_091633
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_092218
│   │   ├── 02_EXECUTOR_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_092731
│   │   ├── 02_EXECUTOR_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_092949
│   │   ├── 03_CRITIC_REPORT.md
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_093023
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   ├── 20260129_093109
│   │   ├── daemon.log
│   │   ├── DIALOGUE.md
│   │   └── ISSUES.md
│   └── 20260129_093143
│       ├── daemon.log
│       ├── DIALOGUE.md
│       └── ISSUES.md
├── selftest_final.log
├── selftest_green.log
├── selftest_infra.log
└── STRATEGY_KNOWLEDGE_BASE.md

OUTPUT:
(config.py full contents)
"""
Centralized configuration for SOL Liquidity Navigator.
Core strategy parameters derived from STRATEGY_KNOWLEDGE_BASE.md (White Paper).
Infrastructure parameters defined for Stage 1 implementation.
"""

from pathlib import Path
import os

# -----------------------------
# System (Infrastructure Implementation)
# -----------------------------

BASE_DIR = Path(__file__).resolve().parent  # why: Stage1/ops placeholder base path for jsonl outputs; WP ref: WP §7 (jsonl logging required, path not specified)
LOG_DIR = BASE_DIR / "logs"  # why: Stage1/ops placeholder log directory for jsonl outputs; WP ref: WP §7 (jsonl logging required, path not specified)
LOG_FILE_EXTENSION = "jsonl"  # why: logging format specified as jsonl; WP ref: WP §7
LOG_OUTPUT_TARGET = "file"  # why: default jsonl must be durable; write to file by default; WP ref: WP §7 (jsonl logging required)
LOG_FILE_NAME = "events"  # why: Stage1/ops placeholder filename for jsonl output; WP ref: WP §7 (jsonl logging required, filename not specified)
LOG_INCLUDE_BLOCKED_SIGNALS = True  # why: log blocked/suppressed decisions for auditability; WP ref: WP §7
LOG_EVENT_SIGNAL_EMITTED = "signal_emitted"  # why: event name for emitted signals; WP ref: WP §7
LOG_EVENT_SIGNAL_SUPPRESSED = "signal_suppressed"  # why: event name for suppressed signals; WP ref: WP §7
LOG_EVENT_DECISION = "decision"  # why: event name for key decisions; WP ref: WP §7
LOG_EVENT_GATE_BLOCKED = "gate_blocked"  # why: event name for gate blocks; WP ref: WP §7

STRATEGY_ASSET = "SOL/USDT"  # why: asset specified in strategy description; WP ref: WP §2
STRATEGY_INSTRUMENT_TYPE = "Perpetual Futures"  # why: instrument type specified in WP overview; WP ref: WP §2
INSTRUMENT = "SOL/USDT-PERP"  # why: execution alert instrument specified in alert format; WP ref: WP §5.2
STRATEGY_BALANCED_MARKET_HYPOTHESIS = True  # why: core hypothesis that market is balanced; WP ref: WP §2
STRATEGY_TRADES_FALSE_BREAKS = True  # why: strategy trades false breaks/sweeps; WP ref: WP §2
TIMEFRAMES_ENTRY = ("M1", "M5")  # why: entry timeframes specified in WP; WP ref: WP §2
TIMEFRAME_CONTEXT = "H1"  # why: context timeframe specified in WP; WP ref: WP §2

TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")  # why: Stage1/ops secret via env; do not commit secrets; WP ref: WP §7 (telebot library listed; channel not mandated)
TELEGRAM_CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID", "")  # why: Stage1/ops chat id via env; do not commit secrets; WP ref: WP §7 (telebot library listed; channel not mandated)
TELEGRAM_ENABLED = bool(TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID)  # why: Stage1 fail-safe to disable telegram when secrets missing; WP ref: N/A (Stage1 ops placeholder)
ALERT_DIRECTIVE_PLAN_LABEL = "PLAN: EXECUTE NOW"  # why: directive alert requirement in example format; WP ref: WP §5.2
ALERT_DIRECTIVE_EXECUTE_NOW = True  # why: alerts must be directive per execution protocol; WP ref: WP §5.2
ALERT_FIELD_INSTRUMENT_LABEL = "Instrument"  # why: alert field requirement in example format; WP ref: WP §5.2
ALERT_FIELD_ENTRY_LABEL = "Entry"  # why: alert field requirement in example format; WP ref: WP §5.2
ALERT_FIELD_RISK_LABEL = "Risk"  # why: alert field requirement in example format; WP ref: WP §5.2
ALERT_ENTRY_RECLAIM_CONFIRMED_LABEL = "Reclaim confirmed (3 candles)"  # why: reclaim confirmation requirement in entry logic; WP ref: WP §3.3
ALERT_TEMPLATE_FIELDS = (
    "directive_plan",
    "instrument",
    "entry",
    "risk",
)  # why: alert must include directive + instrument + entry + risk fields; WP ref: WP §5.2
ALERT_TEMPLATE = "\n".join(
    (
        ALERT_DIRECTIVE_PLAN_LABEL,
        f"{ALERT_FIELD_INSTRUMENT_LABEL}: {{instrument}}",
        f"{ALERT_FIELD_ENTRY_LABEL}: {{entry}}",
        f"{ALERT_FIELD_RISK_LABEL}: ${{risk}}",
    )
)  # why: directive alert format with required fields; WP ref: WP §5.2

PYTHON_VERSION_MIN = "3.10"  # why: language requirement for deployment; WP ref: WP §7
REQUIRED_LIBRARIES = ("ccxt", "pandas_ta", "telebot")  # why: required libraries list; WP ref: WP §7

# -----------------------------
# Strategy Core
# -----------------------------

LIQUIDATION_CLUSTER_USD = 20_000_000  # why: cluster definition > $20M; WP ref: WP §3.1
LIQUIDATION_CLUSTER_COMPARATOR = ">"  # why: cluster condition uses > threshold comparator; WP ref: WP §3.1
SWEEP_BUFFER = 0.0015  # why: sweep buffer 0.15%; WP ref: WP §3.2
ENTRY_SWEEP_PRICE_FIELD = "price_low"  # why: sweep uses price_low field; WP ref: WP §3.4 pseudocode
ENTRY_SWEEP_LEVEL_FORMULA = "cluster_level * (1 - sweep_buffer)"  # why: sweep formula; WP ref: WP §3.4 pseudocode
ENTRY_SWEEP_COMPARATOR = "<"  # why: sweep comparator strictly <; WP ref: WP §3.4 pseudocode
ENTRY_RECLAIM_PRICE_FIELD = "price_close"  # why: reclaim uses price_close field; WP ref: WP §3.4 pseudocode
ENTRY_RECLAIM_LEVEL_FORMULA = "cluster_level"  # why: reclaim level equals cluster level; WP ref: WP §3.4 pseudocode
ENTRY_RECLAIM_COMPARATOR = ">"  # why: reclaim comparator strictly >; WP ref: WP §3.4 pseudocode
CONFIRM_CANDLES = 3  # why: reclaim confirmation for 3 candles; WP ref: WP §3.3

# Stage1 determinism placeholders (strategy comparators remain strict per WP §3.4)
PRICE_TICK_SIZE = 0.01  # why: Stage1/ops placeholder tick size; deterministic quantization for sweep/reclaim comparisons; WP ref: N/A (Stage1 ops placeholder)
PRICE_DECIMALS = 2  # why: Stage1/ops placeholder precision for logging/quantize; align with tick size; WP ref: N/A (Stage1 ops placeholder)
PRICE_QUANTIZE_MODE = "quantized"  # why: Stage1/ops quantize to tick before comparisons for determinism; WP ref: N/A (Stage1 ops placeholder)
PRICE_ROUNDING = "ROUND_HALF_UP"  # why: Stage1/ops rounding mode when quantizing to tick size; WP ref: N/A (Stage1 ops placeholder)
PRICE_COMPARATOR_STRICTNESS = "strict"  # why: Stage1/ops apply strict '<'/'>' after quantization; equality at tick does not pass; WP ref: N/A (Stage1 ops placeholder)
USE_DECIMAL_FOR_COMPARISONS = True  # why: Stage1/ops prefer Decimal over float to reduce drift; WP ref: N/A (Stage1 ops placeholder)

# -----------------------------
# Risk Gates (Iron Gates)
# -----------------------------

BTC_RISK_OFF_RETURN_60M = -0.010  # why: btc_return_60m threshold -1.0%; WP ref: WP §4.4 pseudocode (note WP §4.1 prose says "more than 1.0%")
BTC_RISK_OFF_COMPARATOR = None  # why: no default until PM/orchestrator decision; guard against silent winner; WP ref: WP §4.1 vs WP §4.4 conflict
BTC_RISK_OFF_COMPARATOR_PSEUDOCODE = "<="  # why: pseudocode comparator documented for PM decision; WP ref: WP §4.4
BTC_RISK_OFF_COMPARATOR_PROSE = "<"  # why: strict comparator from prose "more than 1.0%" for PM decision; WP ref: WP §4.1
BTC_RISK_OFF_WINDOW_MINUTES = 60  # why: BTC return window is 60 minutes; WP ref: WP §4.1
BTC_RISK_OFF_EDGE_CASE_AT_THRESHOLD = "btc_return_60m == -0.010"  # why: explicit edge-case label for PM decision on -1.0% handling; WP ref: WP §4.1 vs WP §4.4 conflict
ADX_LENGTH = 14  # why: ADX(14) indicator length; WP ref: WP §4.2
ADX_TIMEFRAME = "H1"  # why: ADX filter timeframe; WP ref: WP §4.2
ADX_THRESHOLD = 25  # why: trend filter threshold; WP ref: WP §4.2
ADX_COMPARATOR = ">"  # why: comparator uses adx_h1 > 25; WP ref: WP §4.4 pseudocode
GATES_SUPPRESS_SIGNAL_IF_ANY_BLOCKED = True  # why: if any gate active, suppress signal; WP ref: WP §4.4 pseudocode
GATES_FAIL_CLOSED_ON_MISSING_DATA = True  # why: Stage1/ops safety to block signals on missing data; WP ref: N/A (Stage1 ops placeholder)

WEEKEND_STOP_START_WEEKDAY = 4  # why: Friday=4 (0=Mon) to make weekend stop parse-safe; WP ref: WP §4.3
WEEKEND_STOP_START_MINUTE_UTC = 21 * 60  # why: 21:00 UTC encoded as minutes for locale-agnostic parsing; WP ref: WP §4.3
WEEKEND_STOP_END_WEEKDAY = 0  # why: Monday=0 (0=Mon) to close weekend stop window; WP ref: WP §4.3
WEEKEND_STOP_END_MINUTE_UTC = 6 * 60  # why: 06:00 UTC encoded as minutes for locale-agnostic parsing; WP ref: WP §4.3
WEEKEND_STOP_WEEKDAY_ZERO_IS_MONDAY = True  # why: explicit weekday indexing (0=Mon) to avoid locale ambiguity; WP ref: WP §4.3

# -----------------------------
# Execution
# -----------------------------

RISK_PER_TRADE_USD = 10.0  # why: fixed risk per trade $10; WP ref: WP §5.3
ALERT_FIELD_RISK_VALUE_USD = RISK_PER_TRADE_USD  # why: alert risk aliases fixed risk per trade; WP ref: WP §5.3
DAILY_STOP_LOSS_USD = -20.0  # why: stop if cumulative PnL <= -$20; WP ref: WP §5.3
DAILY_STOP_LOSS_COMPARATOR = "<="  # why: stop condition uses <= threshold comparator; WP ref: WP §5.3
DAILY_STOP_RESET_TZ = "UTC"  # why: Stage1 convention to reset at 00:00 UTC; WP ref: N/A (Stage1 ops placeholder)
DAILY_STOP_POLICY_STOP_UNTIL_NEXT_DAY = True  # why: stop trading until next day after daily loss; WP ref: WP §5.3

# -----------------------------
# Shadow Lab
# -----------------------------

SHADOW_LAB_LEADERS = ("BTC", "ETH", "JUP", "WIF")  # why: leaders list for correlation scan; WP ref: WP §6.1
SHADOW_LAB_TRADING_ENABLED = False  # why: Shadow Lab does not trade in MVP; WP ref: WP §6
SHADOW_LAB_LOG_ONLY = True  # why: output is log-only for review; WP ref: WP §6.2

COMMANDS:
- tree -a -L 3
- python3 -m py_compile config.py main.py core/engine.py core/market_data.py core/shadow_lab.py infrastructure/logger.py infrastructure/telegram_bot.py
  stdout: (empty)
  stderr: (empty)
- python3 main.py
  stdout: (empty)
  stderr: (empty)
- ls -la logs
  stdout:
  total 12
  drwxrwxr-x 2 ilya ilya 4096 Jan 29 09:35 .
  drwxrwxr-x 8 ilya ilya 4096 Jan 29 09:35 ..
  -rw-rw-r-- 1 ilya ilya  617 Jan 29 09:35 events.jsonl
  -rw-rw-r-- 1 ilya ilya    0 Jan 28 17:51 .gitkeep
- read logs/events.jsonl (first lines)
  1: {"ts": "2026-01-29T06:35:15.532527+00:00", "level": "INFO", "event": "decision", "message": "SOL Liquidity Navigator starting", "python_version": "3.10.12", "instrument": "SOL/USDT-PERP", "timeframes_entry": ["M1", "M5"], "timeframe_context": "H1", "log_dir": "/home/ilya/club/logs"}
  2: {"ts": "2026-01-29T06:35:15.533067+00:00", "level": "INFO", "event": "decision", "message": "Stage1 wiring only: no strategy evaluation", "risk_off_threshold": -0.01, "risk_off_window_min": 60, "weekend_stop_start_weekday": 4, "weekend_stop_start_minute_utc": 1260, "weekend_stop_end_weekday": 0, "weekend_stop_end_minute_utc": 360}

NOTES/RISKS:
- STATUS set to FAIL because canonical workflow reports are missing: 03_CRITIC_REPORT.md and 04_AUDITOR_REPORT.md are not present in .opencode/workflow (see ISSUES.md additions). 02_EXECUTOR_REPORT.md recreated in this run.
- Gate 1 comparator ambiguity is documented in config.py with BTC_RISK_OFF_COMPARATOR=None and both comparator candidates; awaiting PM/orchestrator decision (see DIALOGUE.md requests).
- Runtime artifacts outside .opencode/workflow exist (logs/events.jsonl, repo-root _selftest_backup/, __pycache__/pyc). Policy decision still pending; recorded in ISSUES.md and DIALOGUE.md.
