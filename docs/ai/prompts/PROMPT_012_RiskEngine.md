## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
4. `Include/MNS/MNSTypes.mqh` — Shared Data Structures.
5. `Include/MNS/CEntryEngine.mqh` — Preceding entry engine dependency.
6. `docs/modules/012_RiskEngine.md` — This module's Specification.
7. `docs/modules/012_ALGORITHM.md` — This module's Algorithm.
8. `docs/modules/012_API.md` — This module's Class API.
9. `docs/CLASS_DIAGRAM.md` — Design Blueprint.
10. `docs/CodingStandards.md` — Coding and style guide.
11. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.
12. `docs/Roadmap.md` — Project roadmap.

---

## Instructions for CRiskEngine Implementation

You must implement the `CRiskEngine` class inside `Include/MNS/CRiskEngine.mqh`.

### 1. Requirements Checklist
- **Pre-Trade Risk Sizing**:
  - Calculate `StopBuffer = max(2 * SYMBOL_POINT, 0.20 * ATR(14))`.
  - Calculate Stop Loss level (`InvalidationLow - StopBuffer` for Buy, `InvalidationHigh + StopBuffer` for Sell).
  - Calculate Reward-to-Risk ratio. If `RR < 1.50R`, set `approved = false` and reject the trade.
  - Calculate Cash Risk Amount from account equity and clamped risk percentage (between 0.25% and 2.00%).
  - Calculate position size volume using MT5's `OrderCalcProfit` or manual fallback if offline:
    $$\text{Volume} = \frac{\text{RiskAmount}}{\text{LossPerLot}}$$
  - Floor volume to `SYMBOL_VOLUME_STEP` size. Ensure the final volume step size does not exceed the cash risk amount limit.
- **Active Position Management**:
  - Trigger a 50% partial close action exactly **once** at $+1.0\text{R}$ progress.
  - Activate trailing stop at $+1.5\text{R}$ progress. Trailing distance is $1 \times \text{ATR}(14)$ behind current price.
  - Update trailing stop only at each $+0.5\text{R}$ incremental progress tier.
  - Stop Movement constraint: **Never worsen a stop** (stops can only move in the direction of profit).
  - Emergency Exits: Trigger full exit if DOL target reached/invalidated, delivery leg invalidated, MTF reversed, or daily drawdown limit breached.

### 2. MQL5 Restrictions
- const methods returning structures (e.g. `SRiskSizingResult` or `SRiskManagementAction`) must return them **by value** (no `const T&` return).
- No references to local variables as references (`const T& x = ...` is invalid).
- Keep inclusion guard: `#ifndef __MNS_RISK_ENGINE_MQH__`.

### 3. Log Output
- Use the shared logging module `CLogger` to write diagnostic information when:
  - Sizing is approved/rejected (include calculated SL, TP, volume, and RR).
  - A partial close is triggered.
  - Trailing stop level is updated.
  - An emergency exit is triggered.
