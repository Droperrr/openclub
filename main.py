"""
Minimal entrypoint stub for SOL Liquidity Navigator (Stage 1 scaffold).
"""

from __future__ import annotations

import sys
import platform

sys.dont_write_bytecode = True

import config
from infrastructure import logger


def main() -> None:
    logger.setup()
    logger.log_decision(
        "SOL Liquidity Navigator starting",
        python_version=platform.python_version(),
        instrument=config.INSTRUMENT,
        timeframes_entry=config.TIMEFRAMES_ENTRY,
        timeframe_context=config.TIMEFRAME_CONTEXT,
        log_dir=str(config.LOG_DIR),
    )

    logger.log_decision(
        "Stage1 wiring only: no strategy evaluation",
        risk_off_threshold=config.BTC_RISK_OFF_RETURN_60M,
        risk_off_window_min=config.BTC_RISK_OFF_WINDOW_MINUTES,
        weekend_stop_start_weekday=config.WEEKEND_STOP_START_WEEKDAY,
        weekend_stop_start_minute_utc=config.WEEKEND_STOP_START_MINUTE_UTC,
        weekend_stop_end_weekday=config.WEEKEND_STOP_END_WEEKDAY,
        weekend_stop_end_minute_utc=config.WEEKEND_STOP_END_MINUTE_UTC,
    )


if __name__ == "__main__":
    main()
