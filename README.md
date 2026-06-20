# XAUUSD Basket-Trailing EA 📈

> A MetaTrader 5 Expert Advisor (algorithmic trading bot) for XAUUSD (gold) that manages a *basket* of positions with grid-style entries, basket-level risk controls, and a ratcheting "no-giveback" profit-locking trailing system — written in MQL5.

![MQL5](https://img.shields.io/badge/MQL5-2E6E9E?style=flat)
![MetaTrader 5](https://img.shields.io/badge/MetaTrader%205-0A0A0A?style=flat)

## Overview

This EA automates a basket-trading approach on gold. It opens an initial position based on short-term trend, scales into the basket as price moves a configurable distance against it, and manages the **entire basket's** profit and loss together rather than trade-by-trade. The headline feature is a profit-lock mechanism that ratchets a locked profit floor upward as the basket gains, and never gives it back.

## Why it's interesting (the engineering)

- **Real-time, event-driven logic** — all decisions run inside `OnTick` under live market conditions.
- **Basket-level P&L accounting** — total profit is computed in points across multiple positions and volumes.
- **Stateful risk management** — peak-profit tracking, a ratcheting profit lock, and a hard basket stop-loss.
- **Clean separation of concerns** — distinct routines for entry, position counting, basket-P&L calculation, and close-all.

## Key features

- Trend-based entry with configurable grid step and maximum basket size
- Progressive position sizing across the basket
- Basket-wide stop-loss (in points)
- **"No-giveback" profit lock** — trails a locked floor below peak basket profit and closes the whole basket if profit retraces to it
- Symbol-scoped position management (safe to run alongside other symbols)

## How it works (high level)

1. With no open positions, open one in the current short-term trend direction.
2. As price moves `StepPoints` against the basket, add a position (up to `MaxTrades`), increasing size each step.
3. Continuously compute total basket profit in points.
4. If profit retraces below the ratcheting locked level → close the whole basket and bank the gain.
5. If basket loss reaches the configured maximum → close the basket to cap risk.

## Tech

`MQL5` · `MetaTrader 5` · `CTrade` library

---

> **About this repository.** The parameter values shown are *illustrative defaults*, not a tuned configuration. This repo demonstrates the engineering and risk-management architecture — it is **not** a turnkey profitable system.

> ⚠️ **Risk disclaimer.** Personal / educational project. Grid and basket strategies carry significant risk and can produce large drawdowns or full account loss. Nothing here is financial advice. Do not trade real capital without thorough independent testing and your own risk assessment.
