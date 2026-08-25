# MNS Trading Engine — Execution-Only Indicator Visual Reference Guide

This guide details the visual elements and behavior of the **MNS Execution-Only Indicator** (`MNS_Indicator_ExecutionOnly.ex5`). This version disables all other visual overlays (swing arrows, structure lines, liquidity pools, premium/discount zones, sessions, and dashboard panels) to present a clean chart layout focused strictly on trade execution setups.

---

## 1. Visual Elements Map

When an entry signal is active or a trade is running, the indicator renders a TradingView-style Risk/Reward Projection Box to the right of the current bar in the future chart space:

| Visual Component | Object Type | Default Color | Line Style / Border | Purpose |
|---|---|---|---|---|
| **Entry Level** | `OBJ_TREND` | **Gold** (`clrGold`) | Solid, `width = 2` | Highlights the trigger entry level price. |
| **Take Profit (TP) Level** | `OBJ_TREND` | **Lime Green** (`clrLime`) | Solid, `width = 1` | Highlights the target profit boundary level. |
| **Stop Loss (SL) Level** | `OBJ_TREND` | **Red** (`clrRed`) | Solid, `width = 1` | Highlights the invalidation risk boundary level. |
| **Profit Region** | `OBJ_RECTANGLE` | **Deep Emerald** (`C'0x0C, 0x22, 0x11'`) | Filled, no border | Visualizes the target profit zone in the chart background. |
| **Risk Region** | `OBJ_RECTANGLE` | **Deep Maroon** (`C'0x26, 0x0C, 0x0C'`) | Filled, no border | Visualizes the active risk zone in the chart background. |

---

## 2. Dynamic Sizing Labels

Labels are rendered at the right edge of the projection box (`X2`) and dynamically integrate account-level risk sizing metrics from `CRiskEngine`:

1. **TP Label** (aligned at `TPPrice`):
   * *Format*: `TP: 1.25600 (+40.0 pips / 2.5R) [Reward: 250.00 USD]`
   * Shows target price, distance in pips, expected risk-reward ratio, and cash profit in the account deposit currency.
2. **Entry Label** (aligned at `EntryPrice`):
   * *Format*: `ENTRY: 1.25200 [Size: 1.25 Lots]`
   * Shows entry price and the calculated position volume in lots scaled to risk limits.
3. **SL Label** (aligned at `StopLossPrice`):
   * *Format*: `SL: 1.25040 (-16.0 pips) [Risk: 100.00 USD]`
   * Shows stop loss price, risk distance in pips, and maximum cash risk in the account deposit currency.

---

## 3. Activation & Tracking States

To maintain maximum chart space, the projection boxes are strictly state-driven:

### State A: No Signal & No Trade (Clean Chart)
If there is no active entry signal and no open position on the chart's symbol, the indicator remains completely invisible, leaving the chart clean.

### State B: Active Entry Signal (Pre-Trade Setup)
When `g_entry.HasActiveSignal()` is true:
* The indicator calculates sizing parameters using the client's desired risk percentage and account equity.
* The projection box draws to the right of the current bar.
* Labels display the calculated lot size and cash risk/reward parameters.

### State C: Active Position (Live Trade Tracking)
If the entry is filled and the position is active:
* The indicator tracks the active position on the account for the current symbol.
* The projection box remains on the chart, using the live position's open price, stop loss, and take profit.
* Sizing metrics are derived from the actual live lot size and current level boundaries.
* The box disappears immediately once the position is closed.
