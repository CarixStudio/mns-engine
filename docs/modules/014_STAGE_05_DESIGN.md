# Module 014 — Stage 5: EA Dashboard & On-Chart Runtime Controls
# Technical Design Specification

This document outlines the technical design for implementing a live on-chart HUD panel and runtime interactive controls entirely within `MNS_EA.mq5`, with no modifications to any core engine files under `Include/MNS/`.

---

## 1. Objectives

- Render a live on-chart HUD panel showing account metrics, active trade details, signal state, and engine reads.
- Implement runtime interactive buttons that allow the trader to control EA behaviour without reloading it.
- Implement runtime stepper controls (▲▼) to adjust risk, spread filter, and drawdown limits on the fly.
- Handle all button and stepper clicks through the already-stubbed `OnChartEvent()` handler.
- Clean up all chart objects on `OnDeinit()` using `ObjectsDeleteAll` with the `MNS_EA_HUD_` prefix.

---

## 2. Engine Freeze

> **Strict Engine Freeze:** Do NOT modify any files under `Include/MNS/`. All HUD rendering and event handling is implemented inside `Experts/MNS_EA/MNS_EA.mq5` only.

---

## 3. Object Naming Convention

All chart objects created by the EA HUD must use the prefix `MNS_EA_HUD_` to avoid collisions with the indicator's own objects (which use `MNS_`, `MNS_BRK_`, `MNS_Dash_`, etc.).

Pattern:
```
MNS_EA_HUD_<Section>_<Row>_<Type>
```

Examples:
- `MNS_EA_HUD_ACCT_Equity_Lbl`
- `MNS_EA_HUD_ACCT_Equity_Val`
- `MNS_EA_HUD_BTN_AutoTrade`
- `MNS_EA_HUD_BTN_CloseAll`
- `MNS_EA_HUD_STP_Risk_Up`
- `MNS_EA_HUD_STP_Risk_Dn`
- `MNS_EA_HUD_BG` (background rectangle)

---

## 4. Runtime State Variables

These file-scope variables mirror the controllable settings and are used at runtime instead of the frozen `input` values (since `input` variables cannot be changed at runtime):

```mql5
// Runtime-mutable mirrors of input settings
bool   g_runtimeAutoTrading     = false;   // Mirrored from InpAutoTrading
bool   g_runtimePauseEntries    = false;   // Pause new entries (existing trade runs)
bool   g_runtimeTrailingStop    = true;    // Mirrored from InpTrailingStop
bool   g_runtimePartialClose    = true;    // Mirrored from InpPartialClose
double g_runtimeRiskPercent     = 1.0;     // Mirrored from InpDefaultRisk
double g_runtimeMaxSpread       = 50.0;    // Mirrored from InpMaxSpreadPoints
double g_runtimeMaxDailyDD      = 5.0;     // Mirrored from InpMaxDailyDrawdown
```

All existing runtime checks inside `OnTick()` that currently use the `input` variables must be updated to use their `g_runtime*` mirrors instead. For example:
- `if (!InpAutoTrading)` → `if (!g_runtimeAutoTrading)`
- `if (InpTrailingStop)` → `if (g_runtimeTrailingStop)`
- `if (InpPartialClose && ...)` → `if (g_runtimePartialClose && ...)`

On `OnInit()`, initialize the runtime mirrors from the input values:
```mql5
g_runtimeAutoTrading  = InpAutoTrading;
g_runtimeTrailingStop = InpTrailingStop;
g_runtimePartialClose = InpPartialClose;
g_runtimeRiskPercent  = InpDefaultRisk;
g_runtimeMaxSpread    = InpMaxSpreadPoints;
g_runtimeMaxDailyDD   = InpMaxDailyDrawdown;
```

---

## 5. HUD Layout

The HUD panel is positioned in the **top-right corner** of the chart (x offset from right edge, y offset from top), rendered using `OBJ_RECTANGLE_LABEL` (background) and `OBJ_LABEL` (text rows). Fixed panel width: `220px`. Row height: `18px`.

```
┌────────────────────────────────┐
│  MNS EA v1.0   [AUTO: ON ]     │   ← Header row + Auto-Trade toggle button
│  EURUSD  H1  London Session    │   ← Symbol / TF / Session row
├────────────────────────────────┤
│  ACCOUNT                       │   ← Section header
│  Equity         $10,420.00     │
│  Balance        $10,300.00     │
│  Daily P&L      +$120.00       │
│  Drawdown        1.2%   [5.0%] │   ← Current DD vs limit (stepper ▲▼)
├────────────────────────────────┤
│  ACTIVE TRADE                  │   ← Section header
│  Direction        BUY          │
│  Entry         1.36295         │
│  Stop Loss     1.36105         │
│  Take Profit   1.36595         │
│  Float P&L     +$48.20         │
│  Partial Close   Done ✓        │
│  [CLOSE ALL]  [MOVE TO B/E]    │   ← Action buttons
├────────────────────────────────┤
│  SIGNAL                        │   ← Section header
│  Status        CONFIRMED       │
│  Confidence    82              │
│  Direction     BUY             │
│  DOL           1.36595         │
│  Delivery      EXPANSION       │
│  [RESET SIGNAL]                │   ← Action button
├────────────────────────────────┤
│  RISK SETTINGS                 │   ← Section header
│  Risk %     [▼] 1.0% [▲]      │   ← Stepper: 0.25 step, min 0.25, max 2.0
│  Max Spread [▼] 50pt [▲]      │   ← Stepper: 5pt step, min 5, max 200
│  Trail Stop   [ON ]            │   ← Toggle button
│  Part. Close  [ON ]            │   ← Toggle button
│  Pause Entry  [OFF]            │   ← Toggle button
└────────────────────────────────┘
```

---

## 6. Chart Object Types

| Element | MQL5 Type | Notes |
|---|---|---|
| Panel background | `OBJ_RECTANGLE_LABEL` | Fixed corner, dark fill `C'18,18,24'`, border `C'60,60,80'` |
| Section headers | `OBJ_LABEL` | Bold, color `C'140,140,180'` |
| Info label (left) | `OBJ_LABEL` | Color `C'160,160,170'`, font size 8 |
| Info value (right) | `OBJ_LABEL` | Color `clrWhite`, font size 8, right-anchored |
| Action button | `OBJ_BUTTON` | Width 90px, height 16px, dynamic color by state |
| Toggle button | `OBJ_BUTTON` | Width 40px — green bg `C'30,100,30'` for ON, red bg `C'100,30,30'` for OFF |
| Stepper button | `OBJ_BUTTON` | Width 18px, height 14px, labels `▲` and `▼` |
| Stepper value | `OBJ_LABEL` | Between stepper buttons, white text |

---

## 7. Button & Stepper Definitions

### 7.1 Action Buttons (one-shot triggers)

| Button Name | Object ID | Action |
|---|---|---|
| Auto-Trade toggle | `MNS_EA_HUD_BTN_AutoTrade` | Toggle `g_runtimeAutoTrading` |
| Pause Entries | `MNS_EA_HUD_BTN_Pause` | Toggle `g_runtimePauseEntries` |
| Close All | `MNS_EA_HUD_BTN_CloseAll` | Call `g_trade.PositionClose()` for all matching positions, then clean GVs |
| Move to B/E | `MNS_EA_HUD_BTN_MoveToBreakEven` | Modify SL to entry price for any open position |
| Reset Signal | `MNS_EA_HUD_BTN_ResetSignal` | Call `g_entryEngine.MarkSignalConsumed()` to clear stale signal |

### 7.2 Toggle Buttons (persistent state)

| Button Name | Object ID | Controls |
|---|---|---|
| Trailing Stop | `MNS_EA_HUD_BTN_TrailStop` | `g_runtimeTrailingStop` |
| Partial Close | `MNS_EA_HUD_BTN_PartialClose` | `g_runtimePartialClose` |

### 7.3 Stepper Controls (▲▼ pairs)

| Stepper | Up ID | Down ID | Value Label ID | Variable | Step | Min | Max |
|---|---|---|---|---|---|---|---|
| Risk % | `MNS_EA_HUD_STP_Risk_Up` | `MNS_EA_HUD_STP_Risk_Dn` | `MNS_EA_HUD_STP_Risk_Val` | `g_runtimeRiskPercent` | 0.25 | 0.25 | 2.0 |
| Max Spread | `MNS_EA_HUD_STP_Spread_Up` | `MNS_EA_HUD_STP_Spread_Dn` | `MNS_EA_HUD_STP_Spread_Val` | `g_runtimeMaxSpread` | 5.0 | 5.0 | 200.0 |
| Max DD% | `MNS_EA_HUD_STP_DD_Up` | `MNS_EA_HUD_STP_DD_Dn` | `MNS_EA_HUD_STP_DD_Val` | `g_runtimeMaxDailyDD` | 0.5 | 1.0 | 10.0 |

---

## 8. OnChartEvent Handler

The `OnChartEvent()` handler must process `CHARTEVENT_OBJECT_CLICK` events:

```mql5
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        // --- Auto-Trade Toggle
        if (sparam == "MNS_EA_HUD_BTN_AutoTrade")
        {
            g_runtimeAutoTrading = !g_runtimeAutoTrading;
            MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[HUD] Auto-Trading set to: %s", g_runtimeAutoTrading ? "ON" : "OFF"));
        }
        // --- Pause Entries Toggle
        else if (sparam == "MNS_EA_HUD_BTN_Pause") { ... }
        // --- Close All
        else if (sparam == "MNS_EA_HUD_BTN_CloseAll") { ... }
        // --- Move to Break Even
        else if (sparam == "MNS_EA_HUD_BTN_MoveToBreakEven") { ... }
        // --- Reset Signal
        else if (sparam == "MNS_EA_HUD_BTN_ResetSignal") { ... }
        // --- Toggle: Trailing Stop
        else if (sparam == "MNS_EA_HUD_BTN_TrailStop") { ... }
        // --- Toggle: Partial Close
        else if (sparam == "MNS_EA_HUD_BTN_PartialClose") { ... }
        // --- Steppers
        else if (sparam == "MNS_EA_HUD_STP_Risk_Up")   { g_runtimeRiskPercent = MathMin(g_runtimeRiskPercent + 0.25, 2.0); }
        else if (sparam == "MNS_EA_HUD_STP_Risk_Dn")   { g_runtimeRiskPercent = MathMax(g_runtimeRiskPercent - 0.25, 0.25); }
        // ... (same pattern for Spread and DD steppers)

        // Always redraw HUD immediately after any control interaction
        DrawHUD();
    }
}
```

---

## 9. HUD Rendering Functions

Implement as file-scope functions (not a class — keep it simple):

```mql5
void CreateHUD();    // Called once in OnInit() — creates all chart objects
void UpdateHUD();    // Called every OnTick() — updates label text and button colors
void DestroyHUD();   // Called in OnDeinit() — ObjectsDeleteAll with prefix MNS_EA_HUD_
void DrawHUD();      // Alias: calls UpdateHUD(), forces ChartRedraw()
```

`CreateHUD()` uses `ObjectCreate()` for each object. `UpdateHUD()` uses `ObjectSetString()` / `ObjectSetInteger()` to update text and colors only — it does **not** re-create objects.

---

## 10. Info Rows Data Sources

| Row | Data Source API |
|---|---|
| Equity | `AccountInfoDouble(ACCOUNT_EQUITY)` |
| Balance | `AccountInfoDouble(ACCOUNT_BALANCE)` |
| Daily P&L | `GetDailyDrawdownPercent()` helper (already implemented in Stage 4) |
| Drawdown % | `GetDailyDrawdownPercent()` |
| Active Trade Direction | `posInfo.type` from `GetActivePosition()` |
| Entry / SL / TP / Float | `posInfo.*` from `GetActivePosition()` |
| Partial Done | Compare `posInfo.volume` vs original GV volume |
| Signal Status | `g_entryEngine.GetActiveSignalState()` |
| Confidence | `g_confirmationEngine.GetConfidenceScore()` |
| Signal Direction | `g_confirmationEngine.GetDirection()` |
| DOL Price | `g_objectiveEngine.GetDolPrice()` |
| Delivery Phase | `g_deliveryEngine.GetLifecycle()` |
| Session | `CSessionRenderer::GetSessionType()` based on server hour |
| Symbol / TF | `_Symbol`, `EnumToString(Period())` |

---

## 11. Lifecycle Integration

| Hook | Action |
|---|---|
| `OnInit()` | Initialize runtime mirrors → `CreateHUD()` → `UpdateHUD()` |
| `OnTick()` | After position management block, call `UpdateHUD()` (throttled: once per second using `static datetime lastHudUpdate`) |
| `OnDeinit()` | Call `DestroyHUD()` — `ObjectsDeleteAll(0, "MNS_EA_HUD_")` |
| `OnChartEvent()` | Handle all `CHARTEVENT_OBJECT_CLICK` events → call `DrawHUD()` after any state change |

---

## 12. Safety Rules

- **Button deselect:** After processing a button click in `OnChartEvent()`, call `ObjectSetInteger(0, sparam, OBJPROP_STATE, false)` to visually depress and release the button.
- **HUD throttle:** Do not call `UpdateHUD()` on every single tick — use a `static datetime` guard so it only updates at most once per second.
- **No position check for irrelevant rows:** If `GetActivePosition()` returns false, show `"---"` in all active trade rows.
- **No signal check for irrelevant rows:** If `g_entryEngine.GetActiveSignalState() == ENTRY_STATE_NONE`, show `"NONE"` in all signal rows.
- **Prefix isolation:** Never use `ObjectsDeleteAll(0, "MNS_")` — always use the full `"MNS_EA_HUD_"` prefix to avoid deleting indicator objects.
