# MNS Trading Engine - AI Prompt
# Module 014 — Stage 5: EA Dashboard & On-Chart Runtime Controls

You are the lead software engineer for the MNS Trading Engine.
Your task is to implement the live on-chart HUD panel, runtime toggle/stepper controls, and the `OnChartEvent` handler entirely inside `Experts/MNS_EA/MNS_EA.mq5`.

> [!IMPORTANT]
> **Strict Engine Freeze:** Do NOT modify any files under `Include/MNS/`. All HUD code stays inside `MNS_EA.mq5` only.

---

## REQUIRED CONTEXT FILES (Read These First!)
1. [MNS_EA.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Experts/MNS_EA/MNS_EA.mq5) — Current EA coordinator (819 lines).
2. [014_STAGE_05_DESIGN.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/014_STAGE_05_DESIGN.md) — Full Stage 5 specification.
3. [014_STAGE_04_DESIGN.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/014_STAGE_04_DESIGN.md) — Stage 4 reference (GetActivePosition, GV names, daily drawdown).

---

## Step-by-Step Implementation

### STEP 1 — Add Runtime Mirror Variables (file scope, above OnInit)

Add these variables immediately after the engine instance declarations:

```mql5
//+------------------------------------------------------------------+
//| Runtime-Mutable Control Mirrors (changed by HUD at runtime)      |
//+------------------------------------------------------------------+
bool   g_runtimeAutoTrading  = false;
bool   g_runtimePauseEntries = false;
bool   g_runtimeTrailingStop = true;
bool   g_runtimePartialClose = true;
double g_runtimeRiskPercent  = 1.0;
double g_runtimeMaxSpread    = 50.0;
double g_runtimeMaxDailyDD   = 5.0;
```

---

### STEP 2 — Update OnTick() to Use Runtime Mirrors

Search for all usages of input variables and replace them with the runtime mirrors:
- `InpAutoTrading` → `g_runtimeAutoTrading`
- `InpTrailingStop` → `g_runtimeTrailingStop`
- `InpPartialClose` → `g_runtimePartialClose`
- `InpMaxSpreadPoints` → `g_runtimeMaxSpread`
- `InpMaxDailyDrawdown` → `g_runtimeMaxDailyDD` *(passed to `g_riskEngine.Initialize()` stays as input; runtime DD is only used in `GetDailyDrawdownPercent()` comparison)*

Also check: the pause entries logic — if `g_runtimePauseEntries == true`, skip the entry signal execution block entirely (wrap it with `if (!g_runtimePauseEntries)`).

---

### STEP 3 — Initialize Runtime Mirrors in OnInit()

In `OnInit()`, after all engine initializations, add:
```mql5
    // Initialize runtime control mirrors from input values
    g_runtimeAutoTrading  = InpAutoTrading;
    g_runtimeTrailingStop = InpTrailingStop;
    g_runtimePartialClose = InpPartialClose;
    g_runtimeRiskPercent  = InpDefaultRisk;
    g_runtimeMaxSpread    = InpMaxSpreadPoints;
    g_runtimeMaxDailyDD   = InpMaxDailyDrawdown;
```

---

### STEP 4 — Implement HUD Helper Functions

Add the following four functions at file scope, placed after `GetDailyDrawdownPercent()` and before `OnInit()`.

#### 4.1 Constants (define at file scope)
```mql5
#define HUD_PREFIX       "MNS_EA_HUD_"
#define HUD_CORNER       CORNER_RIGHT_UPPER
#define HUD_X            240       // px from right edge
#define HUD_Y_START      20        // px from top
#define HUD_ROW_H        18        // px per row
#define HUD_WIDTH        220       // panel width px
#define HUD_FONT         "Consolas"
#define HUD_FONT_SIZE    8
#define HUD_COL_BG       C'18,18,24'
#define HUD_COL_BORDER   C'60,60,80'
#define HUD_COL_HEADER   C'120,120,200'
#define HUD_COL_LABEL    C'140,140,155'
#define HUD_COL_VALUE    clrWhite
#define HUD_COL_ON       C'30,110,30'
#define HUD_COL_OFF      C'110,30,30'
#define HUD_COL_ACTION   C'50,80,130'
#define HUD_COL_WARN     C'180,100,0'
```

#### 4.2 `CreateHUD()` — object construction
```mql5
void CreateHUD()
{
    // Background rectangle
    ObjectCreate(0, HUD_PREFIX + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_CORNER,    HUD_CORNER);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_XDISTANCE, HUD_X - HUD_WIDTH - 10);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_YDISTANCE, HUD_Y_START - 5);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_XSIZE,     HUD_WIDTH + 20);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_YSIZE,     820);  // will be adjusted
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_BGCOLOR,   HUD_COL_BG);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_BORDER_COLOR, HUD_COL_BORDER);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_BACK,      false);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_SELECTABLE, false);
}
```
*The full `CreateHUD()` must create one `OBJ_LABEL` per info row and one `OBJ_BUTTON` per control (see Section 5 below for the complete list of rows and buttons to create). Follow the naming convention `HUD_PREFIX + "SECTION_RowName_Type"` for every object.*

#### 4.3 `UpdateHUD()` — data binding
```mql5
void UpdateHUD()
{
    static datetime lastUpdate = 0;
    if (TimeCurrent() - lastUpdate < 1) return;  // throttle: update at most once/second
    lastUpdate = TimeCurrent();

    // == HEADER ==
    string autoStr = g_runtimeAutoTrading ? "ON " : "OFF";
    ObjectSetInteger(0, HUD_PREFIX + "BTN_AutoTrade", OBJPROP_BGCOLOR, g_runtimeAutoTrading ? HUD_COL_ON : HUD_COL_OFF);
    ObjectSetString (0, HUD_PREFIX + "BTN_AutoTrade", OBJPROP_TEXT, "AUTO: " + autoStr);

    // == ACCOUNT ==
    double equity   = AccountInfoDouble(ACCOUNT_EQUITY);
    double balance  = AccountInfoDouble(ACCOUNT_BALANCE);
    double dailyPnL = equity - balance;   // simplified; use history-based calc from Stage4 helper for drawdown %
    double ddPct    = GetDailyDrawdownPercent();
    
    ObjectSetString(0, HUD_PREFIX + "ACCT_Equity_Val",  OBJPROP_TEXT, StringFormat("$%.2f", equity));
    ObjectSetString(0, HUD_PREFIX + "ACCT_Balance_Val", OBJPROP_TEXT, StringFormat("$%.2f", balance));
    ObjectSetString(0, HUD_PREFIX + "ACCT_PnL_Val",     OBJPROP_TEXT, StringFormat("%+.2f", dailyPnL));
    
    color ddColor = (ddPct >= g_runtimeMaxDailyDD * 0.8) ? HUD_COL_WARN : HUD_COL_VALUE;
    ObjectSetString (0, HUD_PREFIX + "ACCT_DD_Val",    OBJPROP_TEXT,  StringFormat("%.1f%% / %.1f%%", ddPct, g_runtimeMaxDailyDD));
    ObjectSetInteger(0, HUD_PREFIX + "ACCT_DD_Val",    OBJPROP_COLOR, ddColor);

    // == ACTIVE TRADE ==
    SActivePositionInfo posInfo;
    bool hasPos = GetActivePosition(posInfo);
    
    if (hasPos)
    {
        string dirStr   = (posInfo.type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
        double floatPnL = PositionGetDouble(POSITION_PROFIT);
        string gvVolName = StringFormat("MNS_EA_VOL_%s_%I64u", _Symbol, InpMagicNumber);
        double origVol   = GlobalVariableCheck(gvVolName) ? GlobalVariableGet(gvVolName) : posInfo.volume;
        bool partialDone = (posInfo.volume < origVol - 0.005);
        
        ObjectSetString(0, HUD_PREFIX + "TRADE_Dir_Val",    OBJPROP_TEXT, dirStr);
        ObjectSetString(0, HUD_PREFIX + "TRADE_Entry_Val",  OBJPROP_TEXT, StringFormat("%.*f", _Digits, posInfo.entryPrice));
        ObjectSetString(0, HUD_PREFIX + "TRADE_SL_Val",     OBJPROP_TEXT, StringFormat("%.*f", _Digits, posInfo.stopLoss));
        ObjectSetString(0, HUD_PREFIX + "TRADE_TP_Val",     OBJPROP_TEXT, StringFormat("%.*f", _Digits, posInfo.takeProfit));
        ObjectSetString(0, HUD_PREFIX + "TRADE_Float_Val",  OBJPROP_TEXT, StringFormat("%+.2f", floatPnL));
        ObjectSetString(0, HUD_PREFIX + "TRADE_Part_Val",   OBJPROP_TEXT, partialDone ? "Done v" : "Pending");
        ObjectSetInteger(0, HUD_PREFIX + "TRADE_Float_Val", OBJPROP_COLOR, (floatPnL >= 0) ? clrLime : clrTomato);
    }
    else
    {
        string noPos = "---";
        ObjectSetString(0, HUD_PREFIX + "TRADE_Dir_Val",   OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_Entry_Val", OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_SL_Val",    OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_TP_Val",    OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_Float_Val", OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_Part_Val",  OBJPROP_TEXT, noPos);
    }

    // == SIGNAL ==
    EEntryState sigState = g_entryEngine.GetActiveSignalState();
    string sigStr = "NONE";
    switch (sigState)
    {
        case ENTRY_STATE_ACTIVE:      sigStr = "CONFIRMED"; break;
        case ENTRY_STATE_EXECUTED:    sigStr = "EXECUTED";  break;
        case ENTRY_STATE_EXPIRED:     sigStr = "EXPIRED";   break;
        case ENTRY_STATE_CANCELLED:   sigStr = "CANCELLED"; break;
        case ENTRY_STATE_INVALIDATED: sigStr = "INVALID";   break;
        default:                      sigStr = "NONE";      break;
    }
    ObjectSetString(0, HUD_PREFIX + "SIG_Status_Val",  OBJPROP_TEXT, sigStr);
    ObjectSetString(0, HUD_PREFIX + "SIG_Conf_Val",    OBJPROP_TEXT, StringFormat("%.0f", g_confirmationEngine.GetConfidenceScore()));
    
    EConfirmationDirection confDir = g_confirmationEngine.GetDirection();
    string confDirStr = (confDir == CONFIRM_DIR_BULLISH) ? "BUY" : (confDir == CONFIRM_DIR_BEARISH) ? "SELL" : "NONE";
    ObjectSetString(0, HUD_PREFIX + "SIG_Dir_Val",     OBJPROP_TEXT, confDirStr);
    ObjectSetString(0, HUD_PREFIX + "SIG_DOL_Val",     OBJPROP_TEXT, StringFormat("%.*f", _Digits, g_objectiveEngine.GetDolPrice()));

    // == RISK SETTINGS ==
    ObjectSetString(0, HUD_PREFIX + "STP_Risk_Val",   OBJPROP_TEXT, StringFormat("%.2f%%", g_runtimeRiskPercent));
    ObjectSetString(0, HUD_PREFIX + "STP_Spread_Val", OBJPROP_TEXT, StringFormat("%.0fpt", g_runtimeMaxSpread));
    ObjectSetString(0, HUD_PREFIX + "STP_DD_Val",     OBJPROP_TEXT, StringFormat("%.1f%%", g_runtimeMaxDailyDD));

    ObjectSetInteger(0, HUD_PREFIX + "BTN_TrailStop",    OBJPROP_BGCOLOR, g_runtimeTrailingStop ? HUD_COL_ON : HUD_COL_OFF);
    ObjectSetString (0, HUD_PREFIX + "BTN_TrailStop",    OBJPROP_TEXT, g_runtimeTrailingStop ? "ON" : "OFF");
    ObjectSetInteger(0, HUD_PREFIX + "BTN_PartialClose", OBJPROP_BGCOLOR, g_runtimePartialClose ? HUD_COL_ON : HUD_COL_OFF);
    ObjectSetString (0, HUD_PREFIX + "BTN_PartialClose", OBJPROP_TEXT, g_runtimePartialClose ? "ON" : "OFF");
    ObjectSetInteger(0, HUD_PREFIX + "BTN_Pause",        OBJPROP_BGCOLOR, g_runtimePauseEntries ? HUD_COL_WARN : HUD_COL_ACTION);
    ObjectSetString (0, HUD_PREFIX + "BTN_Pause",        OBJPROP_TEXT, g_runtimePauseEntries ? "PAUSED" : "PAUSE");

    // Session label
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string sessionStr = "OFF-HOURS";
    if      (dt.hour >= 2  && dt.hour < 10) sessionStr = "ASIA";
    else if (dt.hour >= 8  && dt.hour < 17) sessionStr = "LONDON";
    else if (dt.hour >= 13 && dt.hour < 22) sessionStr = "NEW YORK";
    ObjectSetString(0, HUD_PREFIX + "HDR_Session", OBJPROP_TEXT, _Symbol + "  " + EnumToString(Period()) + "  " + sessionStr);

    ChartRedraw(0);
}
```

#### 4.4 `DestroyHUD()`
```mql5
void DestroyHUD()
{
    ObjectsDeleteAll(0, HUD_PREFIX);
    ChartRedraw(0);
}
```

---

### STEP 5 — Full CreateHUD() Object List

Create each of these objects in `CreateHUD()`. For each `OBJ_LABEL`, set `OBJPROP_CORNER = HUD_CORNER`, position with `OBJPROP_XDISTANCE` and `OBJPROP_YDISTANCE`, and set font, size, color. For each `OBJ_BUTTON`, set width, height, and initial color.

**Y positions** (calculated from `HUD_Y_START`, incrementing by `HUD_ROW_H` per row):

| Object Name (suffix) | Type | Y offset | Initial Text / Color |
|---|---|---|---|
| `HDR_Title` | `OBJ_LABEL` | +0 | `"MNS EA v1.0"`, `HUD_COL_HEADER`, bold |
| `BTN_AutoTrade` | `OBJ_BUTTON` | +0 | `"AUTO: OFF"`, `HUD_COL_OFF` |
| `HDR_Session` | `OBJ_LABEL` | +18 | `"EURUSD H1 LONDON"`, `HUD_COL_LABEL` |
| *(separator)* | `OBJ_LABEL` | +36 | `"─────────────────────"`, `HUD_COL_BORDER` |
| `ACCT_Hdr` | `OBJ_LABEL` | +52 | `"ACCOUNT"`, `HUD_COL_HEADER` |
| `ACCT_Equity_Lbl` / `ACCT_Equity_Val` | `OBJ_LABEL` × 2 | +70 | `"Equity"` / `"---"` |
| `ACCT_Balance_Lbl` / `ACCT_Balance_Val` | `OBJ_LABEL` × 2 | +88 | `"Balance"` / `"---"` |
| `ACCT_PnL_Lbl` / `ACCT_PnL_Val` | `OBJ_LABEL` × 2 | +106 | `"Daily P&L"` / `"---"` |
| `ACCT_DD_Lbl` / `ACCT_DD_Val` | `OBJ_LABEL` × 2 | +124 | `"Drawdown"` / `"---"` |
| *(separator)* | `OBJ_LABEL` | +142 | separator |
| `TRADE_Hdr` | `OBJ_LABEL` | +158 | `"ACTIVE TRADE"` |
| `TRADE_Dir_Lbl` / `TRADE_Dir_Val` | `OBJ_LABEL` × 2 | +176 | `"Direction"` / `"---"` |
| `TRADE_Entry_Lbl` / `TRADE_Entry_Val` | `OBJ_LABEL` × 2 | +194 | `"Entry"` / `"---"` |
| `TRADE_SL_Lbl` / `TRADE_SL_Val` | `OBJ_LABEL` × 2 | +212 | `"Stop Loss"` / `"---"` |
| `TRADE_TP_Lbl` / `TRADE_TP_Val` | `OBJ_LABEL` × 2 | +230 | `"Take Profit"` / `"---"` |
| `TRADE_Float_Lbl` / `TRADE_Float_Val` | `OBJ_LABEL` × 2 | +248 | `"Float P&L"` / `"---"` |
| `TRADE_Part_Lbl` / `TRADE_Part_Val` | `OBJ_LABEL` × 2 | +266 | `"Partial"` / `"---"` |
| `BTN_CloseAll` | `OBJ_BUTTON` | +284 | `"CLOSE ALL"`, `HUD_COL_OFF` |
| `BTN_MoveToBreakEven` | `OBJ_BUTTON` | +284 | `"MOVE TO B/E"`, `HUD_COL_ACTION` |
| *(separator)* | `OBJ_LABEL` | +302 | separator |
| `SIG_Hdr` | `OBJ_LABEL` | +318 | `"SIGNAL"` |
| `SIG_Status_Lbl` / `SIG_Status_Val` | `OBJ_LABEL` × 2 | +336 | `"Status"` / `"NONE"` |
| `SIG_Conf_Lbl` / `SIG_Conf_Val` | `OBJ_LABEL` × 2 | +354 | `"Confidence"` / `"---"` |
| `SIG_Dir_Lbl` / `SIG_Dir_Val` | `OBJ_LABEL` × 2 | +372 | `"Direction"` / `"---"` |
| `SIG_DOL_Lbl` / `SIG_DOL_Val` | `OBJ_LABEL` × 2 | +390 | `"DOL"` / `"---"` |
| `BTN_ResetSignal` | `OBJ_BUTTON` | +408 | `"RESET SIGNAL"`, `HUD_COL_ACTION` |
| *(separator)* | `OBJ_LABEL` | +426 | separator |
| `RISK_Hdr` | `OBJ_LABEL` | +442 | `"RISK SETTINGS"` |
| `RISK_Risk_Lbl` / `STP_Risk_Dn` / `STP_Risk_Val` / `STP_Risk_Up` | mix | +460 | `"Risk %"` + steppers |
| `RISK_Spread_Lbl` / `STP_Spread_Dn` / `STP_Spread_Val` / `STP_Spread_Up` | mix | +478 | `"Max Spread"` + steppers |
| `RISK_DD_Lbl` / `STP_DD_Dn` / `STP_DD_Val` / `STP_DD_Up` | mix | +496 | `"Max DD%"` + steppers |
| `RISK_Trail_Lbl` / `BTN_TrailStop` | `OBJ_LABEL` + `OBJ_BUTTON` | +514 | `"Trail Stop"` + toggle |
| `RISK_Part_Lbl` / `BTN_PartialClose` | `OBJ_LABEL` + `OBJ_BUTTON` | +532 | `"Part. Close"` + toggle |
| `RISK_Pause_Lbl` / `BTN_Pause` | `OBJ_LABEL` + `OBJ_BUTTON` | +550 | `"Pause Entry"` + toggle |

---

### STEP 6 — Implement OnChartEvent()

Replace the stubbed `OnChartEvent()` with the full handler. For each button click:
1. Identify button by `sparam`.
2. Execute the corresponding action.
3. Call `ObjectSetInteger(0, sparam, OBJPROP_STATE, false)` to visually release the button.
4. Call `DrawHUD()` (= `UpdateHUD()` + `ChartRedraw(0)`).

**Action implementations:**

- **`BTN_CloseAll`**: Loop all positions matching `_Symbol` and `InpMagicNumber`, call `g_trade.PositionClose(ticket)` for each. Then `GlobalVariableDel` GV names and `g_riskEngine.ResetPositionTracking()`.
- **`BTN_MoveToBreakEven`**: Call `GetActivePosition(posInfo)`. If found, call `g_trade.PositionModify(posInfo.ticket, posInfo.entryPrice, posInfo.takeProfit)`.
- **`BTN_ResetSignal`**: Call `g_entryEngine.MarkSignalConsumed()` (or the alias `SetActiveSignalExecuted()`).
- **Steppers**: Clamp value within min/max bounds after each step.

---

### STEP 7 — Hook into Lifecycle

**In `OnInit()`** (after runtime mirror initialization):
```mql5
    CreateHUD();
    UpdateHUD();
```

**In `OnTick()`** (at the very end of the function, after the engine update pipeline):
```mql5
    UpdateHUD();
```

**In `OnDeinit()`**:
```mql5
    DestroyHUD();
```

---

## SELF-REVIEW CHECKLIST
- [ ] MQL5 compiles cleanly: 0 errors, 0 warnings.
- [ ] No files under `Include/MNS/` were modified.
- [ ] All chart objects use the `MNS_EA_HUD_` prefix exclusively.
- [ ] `DestroyHUD()` uses `ObjectsDeleteAll(0, "MNS_EA_HUD_")` — not `"MNS_"`.
- [ ] All runtime checks in `OnTick()` use `g_runtime*` mirrors, not `input` variables.
- [ ] HUD update is throttled to once per second with a `static datetime` guard.
- [ ] All buttons call `ObjectSetInteger(0, sparam, OBJPROP_STATE, false)` after handling.
- [ ] `BTN_CloseAll` safely cleans GVs and resets risk engine tracking state.
- [ ] `BTN_MoveToBreakEven` respects broker minimum stop level before calling `PositionModify`.
- [ ] `BTN_ResetSignal` only calls `MarkSignalConsumed()` — it does not touch any engine state.
- [ ] Stepper values are clamped within their configured min/max bounds.
- [ ] If no active trade, all trade rows show `"---"`.
- [ ] If no active signal, all signal rows show `"NONE"`.
