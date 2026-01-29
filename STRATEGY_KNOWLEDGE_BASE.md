# STRATEGY_KNOWLEDGE_BASE

## 1. Executive Summary

This document is the canonical "White Paper" for the SOL Liquidity Navigator strategy. It is a self-contained technical bible that explains the philosophy, signal mechanics, safety gates, execution protocol, experimental lab, and system architecture used by the project. It must be followed as a strict trading and engineering specification.

## 2. Strategy Philosophy (Concept)

- **Type:** Hybrid system (Algo-Signal + Manual Execution).
- **Asset:** SOL/USDT Perpetual Futures.
- **Timeframes:** M1/M5 for entries, H1 for context.
- **Core hypothesis:** Most of the time the market is balanced. Large stop-loss/liquidation clusters act as liquidity magnets. We trade the false break (sweep) of these clusters and mean-reversion back into balance.

> Architect quote: "We do not predict the future. We wait for the market to make a mistake (irrational stop sweep), and take liquidity after panic fades."

## 3. Core Engine (Signal Mechanics)

### 3.1 Liquidity Magnet Definition

- **Source:** Liquidation streams.
- **Cluster definition:** Aggregated liquidation cluster volume > $20M.
- **Role:** Liquidity magnets define target zones and candidate sweep levels.

### 3.2 Entry Pattern (Sweep + Reclaim)

A valid long entry requires the following sequence:

1. **Sweep:** Price trades below the cluster level.
2. **Buffer confirmation:** The sweep must exceed the level by at least **0.15%** to avoid noise.
3. **Reclaim:** Price returns above the cluster level.

### 3.3 Dead Cat Protection (Trap Filter)

> Behavioral Quant quote: "Instant buybacks often catch falling knives. A real bottom needs time."

- The signal is **not** issued immediately after reclaim.
- **Confirmation rule:** Price must hold **above the level for 3 consecutive candles** before the alert is emitted.

### 3.4 Signal Logic (Pseudocode)

```python
# inputs: price, cluster_level, sweep_buffer=0.0015, confirm_candles=3
sweep = price_low < cluster_level * (1 - sweep_buffer)
reclaim = price_close > cluster_level
confirmed = reclaim_holds_for_n_candles(confirm_candles)

if sweep and reclaim and confirmed:
    emit_signal("LONG")
```

## 4. Safety Gates (Iron Gates)

This is a strict counter-trend strategy. If **any** gate is active, **entry is forbidden**.

### 4.1 Gate 1: BTC Risk-Off (Macro Filter)

> Macro Strategist quote: "Altcoins are a derivative of Bitcoin liquidity. If the 'father' drops, SOL falls into the abyss."

- **Rule:** If BTC fell more than **1.0% in the last 60 minutes**, **block all longs**.

### 4.2 Gate 2: Trend Filter (ADX)

> Quant quote: "Mean reversion in a strong trend is mathematical suicide."

- **Rule:** If **ADX(14) on H1 > 25**, the market is trending and **counter-trend is forbidden**.

### 4.3 Gate 3: Weekend Hard Stop

> Market-maker quote: "On weekends liquidity is thin, moves are chaotic, smart money sleeps."

- **Rule:** No trading from **Friday 21:00 UTC** to **Monday 06:00 UTC**.

### 4.4 Gate Logic (Pseudocode)

```python
if btc_return_60m <= -0.010:
    block("BTC Risk-Off")

if adx_h1 > 25:
    block("Trend Filter")

if is_weekend_utc():
    block("Weekend Stop")

if any_gate_blocked:
    suppress_signal()
```

## 5. Execution Protocol (Human-in-the-Loop)

### 5.1 Role Split

- **Bot:** Computes signals, applies gates, and formats execution alerts.
- **Human:** Executes trades. This avoids analysis paralysis and enforces discretionary oversight.

### 5.2 Alert Format

Alerts must be **directive**, not informational. Example:

```
PLAN: EXECUTE NOW
Instrument: SOL/USDT-PERP
Entry: Reclaim confirmed (3 candles)
Risk: $10
```

### 5.3 Risk Management

- **Fixed risk per trade:** $10 (MVP stage).
- **Daily stop loss:** -$20. If reached, all trading stops until next day.

> Risk Manager quote: "The best trade is the one you did not take in a bad market."

## 6. Shadow Lab (Correlations)

This module runs in the background and **does not trade**. It only logs.

> Data Scientist hypothesis: "Scanning the entire market is noise. You must track only the leaders."

### 6.1 Purpose

- Monitor correlations between SOL and leaders: **BTC, ETH, JUP, WIF**.
- Identify lead-lag situations where the leader moves and SOL lags.

### 6.2 Output

- Log all lead-lag episodes for monthly statistical review.
- No trading actions are taken based on this module during MVP.

## 7. Technical Architecture

- **Language:** Python 3.10+.
- **Libraries:** ccxt (exchange data), pandas_ta (indicators), telebot (execution interface).
- **Deployment:** VPS (Ubuntu), 24/7 operation.
- **Logging:** Every decision (including blocked signals) is written to **jsonl** for quant review.

## 8. Operational Requirements

- Strategy must respect all gates and risk limits at all times.
- Any deviation from this document requires explicit approval.
- All future modifications must be reflected in this file.
