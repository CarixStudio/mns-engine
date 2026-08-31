# MNS Trading Engine - AI Prompt
# Module 014 — Stage 4: Active Position Management & Trailing

You are the lead software engineer for the MNS Trading Engine.
Your task is to implement the active position management, trailing stops, state recovery, and weekend risk rules inside:
*   **`Experts/MNS_EA/MNS_EA.mq5`** — Implement position tracking loop, daily drawdown calculation, Friday close, and state persistence.

> [!IMPORTANT]
> **Strict Engine Freeze:** Do **NOT** modify any files under `Include/MNS/`, including `CRiskEngine.mqh`. All state restoration, partial close tracking, and synchronization must be handled entirely in the EA coordinator file (`MNS_EA.mq5`).

---

## REQUIRED CONTEXT FILES (Read These First!)
Before writing any code, inspect the following repository files:
1. [CRiskEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CRiskEngine.mqh) — Sizing and active-position tracking.
2. [MNS_EA.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Experts/MNS_EA/MNS_EA.mq5) — Expert Advisor coordinator.
3. [014_STAGE_04_DESIGN.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/014_STAGE_04_DESIGN.md) — Stage 4 specifications.

---

## Modification Details

### 1. Update [MNS_EA.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Experts/MNS_EA/MNS_EA.mq5)

#### 1.1 Add Input Parameters
Add the following inputs under the EA Operational Settings:
* `InpMaxDailyDrawdown` (double, default `5.0`, comment `"Max Daily Drawdown Limit (%)"`)
* `InpTrailingStop` (bool, default `true`, comment `"Enable Trailing Stop Management"`)
* `InpPartialClose` (bool, default `true`, comment `"Enable +1.0R Partial Close Sizing"`)
* `InpFridayCloseHour` (int, default `21`, comment `"Friday Close Hour (Server Time, -1 to disable)"`)

#### 1.2 Add Active Position Info Struct and Helper
Add the following code block above `OnInit()` to hold and query active position details:
```mql5
struct SActivePositionInfo
{
    bool   exists;
    ulong  ticket;
    long   type;
    double entryPrice;
    double volume;
    double stopLoss;
    double takeProfit;
    
    void Reset()
    {
        exists = false;
        ticket = 0;
        type = 0;
        entryPrice = 0.0;
        volume = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
    }
};

bool GetActivePosition(SActivePositionInfo &posInfo)
{
    posInfo.Reset();
    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        string posSymbol = PositionGetSymbol(i);
        if (posSymbol == _Symbol)
        {
            if (PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
            {
                posInfo.exists     = true;
                posInfo.ticket     = PositionGetInteger(POSITION_TICKET);
                posInfo.type       = PositionGetInteger(POSITION_TYPE);
                posInfo.entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                posInfo.volume     = PositionGetDouble(POSITION_VOLUME);
                posInfo.stopLoss   = PositionGetDouble(POSITION_SL);
                posInfo.takeProfit = PositionGetDouble(POSITION_TP);
                return true;
            }
        }
    }
    return false;
}
```

#### 1.3 Add Daily Drawdown Helper Function
Add the `GetDailyDrawdownPercent()` function at file scope:
```mql5
double GetDailyDrawdownPercent()
{
    datetime today = TimeCurrent() - (TimeCurrent() % 86400);
    if (!HistorySelect(today, TimeCurrent()))
        return 0.0;
        
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
    
    double startOfDayBalance = AccountInfoDouble(ACCOUNT_BALANCE) - realizedPnL;
    if (startOfDayBalance <= 0.0)
        return 0.0;
        
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double drawdownPercent = 0.0;
    if (currentEquity < startOfDayBalance)
    {
        drawdownPercent = ((startOfDayBalance - currentEquity) / startOfDayBalance) * 100.0;
    }
    return drawdownPercent;
}
```

#### 1.4 Add Active Position Management Loop inside OnTick()
Inside `OnTick()`, immediately after calculating `atr14` (and before running the core engine update pipeline):
1. Call `GetActivePosition(posInfo)`.
2. Construct two Global Variable names:
   * `string gvSlName = StringFormat("MNS_EA_SL_%s_%I64u", _Symbol, InpMagicNumber);`
   * `string gvVolName = StringFormat("MNS_EA_VOL_%s_%I64u", _Symbol, InpMagicNumber);`
3. **If position exists:**
   * Check if GVs exist. If not, initialize them:
     * `GlobalVariableSet(gvSlName, posInfo.stopLoss);`
     * `GlobalVariableSet(gvVolName, posInfo.volume);`
   * Load GV parameters:
     * `double originalSL = GlobalVariableGet(gvSlName);`
     * `double originalVolume = GlobalVariableGet(gvVolName);`
   * Determine if a partial close already took place:
     * `bool alreadyPartiallyClosed = (posInfo.volume < originalVolume - 0.005);`
   * Map setup states:
     * `EConfirmationDirection dir = (posInfo.type == POSITION_TYPE_BUY) ? CONFIRM_DIR_BULLISH : CONFIRM_DIR_BEARISH;`
     * `double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);`
     * `double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);`
     * `bool isDolReached = (dir == CONFIRM_DIR_BULLISH && currentBid >= posInfo.takeProfit) || (dir == CONFIRM_DIR_BEARISH && currentAsk <= posInfo.takeProfit);`
     * `bool isDolInvalidated = (!g_objectiveEngine.GetActiveDol().active) || (dir == CONFIRM_DIR_BULLISH && g_objectiveEngine.GetDolPrice() < posInfo.entryPrice) || (dir == CONFIRM_DIR_BEARISH && g_objectiveEngine.GetDolPrice() > posInfo.entryPrice);`
     * `bool mtfReversal = (dir == CONFIRM_DIR_BULLISH && g_confirmationEngine.GetDirection() == CONFIRM_DIR_BEARISH) || (dir == CONFIRM_DIR_BEARISH && g_confirmationEngine.GetDirection() == CONFIRM_DIR_BULLISH);`
     * `double currentDailyDrawdown = GetDailyDrawdownPercent();`
   * Call `g_riskEngine.UpdateActiveManagement(...)`:
     * *Note: Pass `alreadyPartiallyClosed` check results internally if the engine flags need to be bypassed, or ignore the action returned.*
   * Process returned `SRiskManagementAction action`:
     * **If `action.closeFully` is true:**
       * Call `g_trade.PositionClose(posInfo.ticket)`.
       * Clean up: `GlobalVariableDel` for both GVs.
       * Call `g_riskEngine.ResetPositionTracking()`.
     * **Else if `action.closePartially` is true & `action.partialVolume > 0.0`:**
       * If `InpPartialClose` is true and `!alreadyPartiallyClosed`:
         * Execute partial close: `g_trade.PositionClosePartial(posInfo.ticket, action.partialVolume)`.
         * Update GV volume: `GlobalVariableSet(gvVolName, posInfo.volume - action.partialVolume)`.
     * **If `action.newStopLoss` is valid and different from `posInfo.stopLoss`:**
       * If `InpTrailingStop` is true:
         * Normalize SL: `double newSL = NormalizeDouble(action.newStopLoss, _Digits);`
         * Modify SL: `g_trade.PositionModify(posInfo.ticket, newSL, posInfo.takeProfit)`.
         * Update GV: `GlobalVariableSet(gvSlName, newSL)`.
   * **Friday Close Check:**
     * If no action was taken, check Friday close:
       ```mql5
       MqlDateTime dt;
       TimeToStruct(TimeCurrent(), dt);
       if (dt.day_of_week == 5 && InpFridayCloseHour >= 0 && dt.hour >= InpFridayCloseHour)
       {
           MNS_Log(MNS_LOG_INFO, "MNS_EA", "[FRIDAY CLOSE] Enforcing weekend risk limit. Flattening position.");
           g_trade.PositionClose(posInfo.ticket);
           GlobalVariableDel(gvSlName);
           GlobalVariableDel(gvVolName);
           g_riskEngine.ResetPositionTracking();
       }
       ```
4. **If position DOES NOT exist:**
   * If any of the GVs exist, delete them (clean up manual close or natural SL/TP hits):
     * `GlobalVariableDel(gvSlName); GlobalVariableDel(gvVolName);`
   * Reset tracking: `g_riskEngine.ResetPositionTracking();`

---

## SELF-REVIEW CHECKLIST
- [ ] MQL5 code compiles cleanly with 0 errors and 0 warnings.
- [ ] No files under `Include/MNS/` were modified.
- [ ] Double-triggers of partial close are prevented by comparing current volume against GV stored volume.
- [ ] GVs are deleted cleanly on position closure.
- [ ] Drawdown limit checks are active and trigger flattening when exceeded.
