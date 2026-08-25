# Module 014 — Stage 1: Execution Visuals
# Technical Design Specifications

This document outlines the design and implementation specifications for rendering execution-level visuals (Entry, Stop Loss, and Take Profit projections) on the chart.

---

## 1. Objectives
* Render a localized, TradingView-style Risk/Reward Projection Box on the chart.
* Eliminate visual interference and color clashes with existing analysis elements (Premium/Discount zones, Sessions, POIs).
* Only show execution graphics when an entry signal is active or a trade is running, leaving the chart clean at all other times.

---

## 2. Graphic Elements & Color Tokens

To prevent color clashes, we define new dedicated styling tokens inside `SIndicatorStyle` (located in [MNSStyle.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSStyle.mqh)).

| Graphic Component | MQL5 Object Type | Color Default | Line Style / Border | Purpose |
|---|---|---|---|---|
| **Entry Level** | `OBJ_TREND` | **Gold** (`clrGold` / `C'0xFF, 0xD7, 0x00'`) | Solid, `width = 2` | Highlights the trigger entry price. |
| **TP Level** | `OBJ_TREND` | **Lime** (`clrLime`) | Solid, `width = 1` | Highlights the target profit boundary. |
| **SL Level** | `OBJ_TREND` | **Crimson** (`clrCrimson`) | Solid, `width = 1` | Highlights the invalidation risk boundary. |
| **Profit Region** | `OBJ_RECTANGLE` | **Deep Emerald** (`C'0x0C, 0x22, 0x11'`) | No border (`style = STYLE_NONE`) | Visualizes the target profit zone. Set `OBJPROP_FILL = true` and `OBJPROP_BACK = true`. |
| **Risk Region** | `OBJ_RECTANGLE` | **Deep Maroon** (`C'0x26, 0x0C, 0x0C'`) | No border (`style = STYLE_NONE`) | Visualizes the active risk zone. Set `OBJPROP_FILL = true` and `OBJPROP_BACK = true`. |

---

## 3. Position & Sizing Math

To avoid overlapping historical zones, the projection boxes are rendered strictly in the **future chart space** to the right of the current bar:

```
    X1 (Left Anchor)  = time[0] (Trigger/Current bar time)
    X2 (Right Anchor) = time[0] + (ProjectedBars * PeriodSeconds())
    
    Where:
      - ProjectedBars: Default config parameter `cfg.executionProjectedBars` (default 20).
```

### Vertical Coordinates
For a **Bullish (Long) Setup**:
* **Profit Box**: Top = `TakeProfitPrice`, Bottom = `EntryPrice`
* **Risk Box**: Top = `EntryPrice`, Bottom = `StopLossPrice`

For a **Bearish (Short) Setup**:
* **Profit Box**: Top = `EntryPrice`, Bottom = `TakeProfitPrice`
* **Risk Box**: Top = `StopLossPrice`, Bottom = `EntryPrice`

---

## 4. Text Labels and Formatting
Labels are rendered at `X2` (the right edge of the projection box) using three `OBJ_TEXT` objects:

1. **TP Label** (aligned at `TPPrice`):
   * *Format*: `"TP: 1.25600 (+40.0 pips / 2.5R)"`
2. **Entry Label** (aligned at `EntryPrice`):
   * *Format*: `"ENTRY: 1.25200"`
3. **SL Label** (aligned at `StopLossPrice`):
   * *Format*: `"SL: 1.25040 (-16.0 pips)"`

*Note: Pips calculations must account for 3/5 digit brokers (`Point` scale multiplier).*

---

## 5. Lifecycle and State Management
* **Namespace Isolation**: All graphical objects created by the execution visuals renderer must use the namespace prefix: `MNS_EXEC_`.
* **State Hooking**:
  * **OnInit()**: Register the execution renderer instance.
  * **OnCalculate()**:
    * Check if an entry signal is active in `CEntryEngine` or if there is an active trade running.
    * If active, call `Draw(direction, entryPrice, stopLoss, takeProfit, time, atr)`.
    * If inactive, call `Clear()` to delete all `MNS_EXEC_` prefixed objects immediately.
  * **OnDeinit()**: Call `Clear()` to clean the chart on indicator/EA removal.
