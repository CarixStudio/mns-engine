# Module 014 — Stage 4: Active Position Management & Trailing
# Technical Design Specifications

This document outlines the technical design and specifications for implementing active position tracking, partial exits, ATR-based trailing stops, emergency exits, state recovery across EA restarts, and session/weekend risk rules **entirely within the `MNS_EA` Expert Advisor coordinator without modifying any core engine files.**

---

## 1. Objectives
* Implement systematic active position tracking and management in the `OnTick()` execution pipeline.
* Integrate the `CRiskEngine::UpdateActiveManagement` API to evaluate trailing stop, partial close, and emergency exit actions.
* Design a robust state recovery mechanism using MetaTrader 5 Terminal Global Variables (`GlobalVariable*` API) to persist critical position state across restarts, crashes, and power failures **without modifying the frozen `CRiskEngine` code**.
* Implement automated partial exits (closing 50% of the active position volume at `+1.0R` progress).
* Implement dynamic ATR-based trailing stops (starting at `+1.5R` progress, trailing `1.0 * ATR(14)` behind bid/ask, and tightening only at every `+0.5R` incremental progress tier).
* Enforce session-based boundary deactivations and pre-weekend risk reduction rules (Friday evening position flattening).

---

## 2. Component Modifications

### 2.1 Core Engines (Include/MNS/)
* **No Modifications:** All core engine files, including [CRiskEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CRiskEngine.mqh), remain **100% frozen** to preserve the integrity of the indicator calculations.

### 2.2 New EA Input Parameters (Experts/MNS_EA/MNS_EA.mq5)
```mql5
//--- EA Operational Settings
input double InpMaxDailyDrawdown  = 5.0;      // Max Daily Drawdown Limit (%)
input bool   InpTrailingStop      = true;     // Enable Trailing Stop Management
input bool   InpPartialClose      = true;     // Enable +1.0R Partial Close Sizing
input int    InpFridayCloseHour   = 21;       // Friday Close Hour (Server Time, -1 to disable)
```

---

## 3. Position Management Pipeline Logic

On every tick inside `OnTick()`, the EA coordinator will perform the active position management check. 

```mermaid
flowchart TD
    A[OnTick Tick Trigger] --> B{Is Position Open?}
    B -- No -- --> C[Check if GVs Exist & Cleanup]
    C --> D[Proceed to Signal Query & Entry Pipeline]
    
    B -- Yes -- --> E[Calculate Daily Drawdown %]
    E --> F[Load or Initialize Position GVs]
    F --> G[Evaluate Emergency Exit Triggers]
    G --> H[Query CRiskEngine::UpdateActiveManagement]
    H --> I{Evaluate Action}
    
    I -- closeFully == true -- --> J[Execute PositionClose]
    J --> K[Delete GVs & Reset State]
    
    I -- closePartially == true -- --> L{Was Already Partially Closed?}
    L -- No -- --> M[Execute PositionClosePartial]
    M --> N[Update Volume GV]
    L -- Yes -- --> O[Ignore Action]
    
    I -- newStopLoss != MNS_INVALID_PRICE -- --> P[Execute PositionModify]
    P --> Q[Update SL & Tier GVs]
    
    I -- No Action -- --> R[Check Friday Close Hours]
    R -- Friday & hour >= InpFridayCloseHour -- --> J
```

### Step 3.1: Position Identification
Retrieve details of any active position matching the symbol and magic number:
* Loop through open positions (`PositionsTotal()`).
* Match `PositionGetSymbol(i) == _Symbol` and `PositionGetInteger(POSITION_MAGIC) == InpMagicNumber`.
* If found, cache the position ticket `ticket = PositionGetInteger(POSITION_TICKET)`.

### Step 3.2: Daily Drawdown Calculation
To calculate the current daily drawdown percentage for drawdown protection, the EA will query the server account details and historical deal records for the current day:
```mql5
double GetDailyDrawdownPercent()
{
    // Start of the current day (server time)
    datetime today = TimeCurrent() - (TimeCurrent() % 86400);
    
    // Select history from today 00:00 to current time
    if (!HistorySelect(today, TimeCurrent()))
        return 0.0;
        
    // Calculate realized PnL today (including commissions and swap)
    double realizedPnL = 0.0;
    int totalDeals = HistoryDealsTotal();
    for (int i = 0; i < totalDeals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if (ticket > 0)
        {
            realizedPnL += HistoryDealGetDouble(ticket, DEAL_PROFIT);
            realizedPnL += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            realizedPnL += HistoryDealGetDouble(ticket, DEAL_SWAP);
        }
    }
    
    // Initial balance at start of day
    double startOfDayBalance = AccountInfoDouble(ACCOUNT_BALANCE) - realizedPnL;
    if (startOfDayBalance <= 0.0)
        return 0.0;
        
    // Compute current daily equity drawdown
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double drawdownPercent = 0.0;
    if (currentEquity < startOfDayBalance)
    {
        drawdownPercent = ((startOfDayBalance - currentEquity) / startOfDayBalance) * 100.0;
    }
    return drawdownPercent;
}
```

### Step 3.3: Persistence & State Recovery (Global Variables)
To survive restarts without altering `CRiskEngine`, we map two unique Terminal Global Variables based on the symbol and Magic Number:
* `MNS_EA_SL_[Symbol]_[Magic]`: Tracks the original Stop Loss price.
* `MNS_EA_VOL_[Symbol]_[Magic]`: Tracks the original execution volume.

On position detection:
1. **Initialize GVs (On initial entry):** If GVs do not exist, create them:
   * Store `POSITION_SL` to the SL global variable.
   * Store `POSITION_VOLUME` to the Volume global variable.
2. **Bypass State Recovery Check:**
   * If the EA is restarted, the local `CRiskEngine` member variables `m_hasPartialClosed` and `m_lastTrailingTier` are reset to defaults.
   * On the next tick, if the current position volume `posInfo.volume` is less than `originalVolume` (loaded from the Volume GV), the EA coordinator marks the position as already partially closed and will **ignore** any `closePartially` action returned by `g_riskEngine`.

### Step 3.4: Evaluate Risk Actions
Determine the current market Bid/Ask price and evaluate active position conditions:
* Direction mapping: `POSITION_TYPE_BUY` -> `CONFIRM_DIR_BULLISH`, `POSITION_TYPE_SELL` -> `CONFIRM_DIR_BEARISH`.
* **DOL Reached Check:** `isDolReached = (dir == CONFIRM_DIR_BULLISH && currentBid >= TP) || (dir == CONFIRM_DIR_BEARISH && currentAsk <= TP)`.
* **DOL Invalidated Check:** `isDolInvalidated = (!g_objectiveEngine.GetActiveDol().active) || (dir == CONFIRM_DIR_BULLISH && g_objectiveEngine.GetDolPrice() < entryPrice) || (dir == CONFIRM_DIR_BEARISH && g_objectiveEngine.GetDolPrice() > entryPrice)`.
* **Reversal Check:** `mtfReversal = (dir == CONFIRM_DIR_BULLISH && g_confirmationEngine.GetDirection() == CONFIRM_DIR_BEARISH) || (dir == CONFIRM_DIR_BEARISH && g_confirmationEngine.GetDirection() == CONFIRM_DIR_BULLISH)`.
* Call `g_riskEngine.UpdateActiveManagement(...)` using parameters extracted.

### Step 3.5: Execute Management Actions
1. **Close Fully (`closeFully == true`):**
   * Call `g_trade.PositionClose(ticket)`.
   * If successful, delete all associated GVs.
2. **Close Partially (`closePartially == true`):**
   * Check if a partial close was already executed: `bool alreadyClosed = (posInfo.volume < originalVolume - 0.005);`
   * If `InpPartialClose` is true and `!alreadyClosed` and `partialVolume > 0.0`:
     * Execute partial close: `g_trade.PositionClosePartial(ticket, partialVolume)`.
     * Update the Volume GV if successful.
3. **Modify SL (`newStopLoss != MNS_INVALID_PRICE`):**
   * If `InpTrailingStop` is true:
     * Modify the stop loss using `g_trade.PositionModify(ticket, newStopLoss, TP)`.
     * Update the SL GV if successful.

### Step 3.6: Friday/Weekend Close Check
If no action is returned by `UpdateActiveManagement`:
* Retrieve current server time structure (`TimeToStruct(TimeCurrent(), dt)`).
* If `dt.day_of_week == 5` (Friday) and `InpFridayCloseHour >= 0` and `dt.hour >= InpFridayCloseHour`:
  * Log Friday close trigger and execute complete flattening (`g_trade.PositionClose(ticket)`), followed by GV cleanup.

---

## 4. Safety Constraints & Error Handling
* **Stale GV Cleanup:** If `IsPositionOpen()` returns false, the EA must check if any matching GVs exist. If found, they must be deleted immediately to prevent state leaks.
* **Modification Thresholds:** Stop loss modification must respect broker minimum stop level limits (`SYMBOL_TRADE_STOPS_LEVEL`).
* **Volume Normalization:** Normalize partial close volume sizing to symbol volume steps to prevent transaction rejections.
