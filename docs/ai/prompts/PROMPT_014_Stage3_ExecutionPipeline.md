# MNS Trading Engine - AI Prompt
# Module 014 — Stage 3: Signal Querying & Execution Pipeline

You are the lead software engineer for the MNS Trading Engine.
Your task is to implement the execution pipeline inside the Expert Advisor coordinator file (`MNS_EA.mq5`) located at: **`Experts/MNS_EA/MNS_EA.mq5`**.

---

## REQUIRED CONTEXT FILES (Read These First!)
Before writing any code, inspect the following repository files:
1. `Experts/MNS_EA/MNS_EA.mq5` — The existing EA shell coordinator.
2. `Include/MNS/MNSCore.mqh` — Core metadata and constants.
3. `Include/MNS/MNSTypes.mqh` — Data structures.
4. `Include/MNS/MNSConfig.mqh` — Config parameters.
5. `docs/modules/014_STAGE_03_DESIGN.md` — Stage 3 Specifications.

---

## Modification Details

### 1. Includes & Global Trade Instance
* Include the MQL5 standard trade library:
  ```mql5
  #include <Trade/Trade.mqh>
  ```
* Declare a global `CTrade` instance at file-scope:
  ```mql5
  CTrade g_trade;
  ```

### 2. New Input Parameters
Add the following inputs under the EA Operational Settings:
* `InpMagicNumber` (ulong, default `20260831`, comment `"EA Magic Number"`)
* `InpTradeComment` (string, default `"MNS_EA"`, comment `"Order Comment Description"`)

### 3. Duplicate Position & Order Checkers
Create two new private helper functions inside `MNS_EA.mq5`:
1. `bool IsPositionOpen()`:
   * Iterate through all open positions (`PositionsTotal()`).
   * Check if position matches current symbol (`PositionGetSymbol(i) == _Symbol`) and position magic matches `InpMagicNumber` (`PositionGetInteger(POSITION_MAGIC) == InpMagicNumber`).
   * Return `true` if a match is found, otherwise `false`.
2. `bool IsOrderPending()`:
   * Iterate through all active pending orders (`OrdersTotal()`).
   * Check if order matches current symbol (`OrderGetSymbol(i) == _Symbol`) and order magic matches `InpMagicNumber` (`OrderGetInteger(ORDER_MAGIC) == InpMagicNumber`).
   * Return `true` if a match is found, otherwise `false`.

### 4. Trade Execution Pipeline (Inside OnTick)
Locate the block under `OnTick()` where the active entry signal is checked (`if (g_entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE)`).
Replace that block to execute the trade pipeline logic:

1. **Verify No Overlapping Trades:**
   * Call `IsPositionOpen()` and `IsOrderPending()`. If either returns `true`, skip order execution and abort (do not log this on every tick, or log it once using static flag).
2. **Verify Spread Limit:**
   * Get current symbol spread: `double currentSpread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);`
   * Check `currentSpread <= cfg.maxSpreadPoints`. If spread is exceeded, log a warning and abort order execution.
3. **Query Sizing and Execution:**
   * Get the active signal: `SEntrySignal activeSig = g_entryEngine.GetActiveSignal();`
   * Run pre-trade sizing:
     ```mql5
     SRiskSizingResult riskResult = g_riskEngine.SizePreTrade(activeSig.direction,
                                                             activeSig.entryPrice,
                                                             activeSig.stopLoss,
                                                             activeSig.takeProfit,
                                                             atr14,
                                                             cfg.desiredRiskPercent,
                                                             AccountInfoDouble(ACCOUNT_EQUITY),
                                                             _Symbol);
     ```
   * If `riskResult.approved` is `true` and `riskResult.volume > 0.0`:
     * Set the trade magic number: `g_trade.SetExpertMagicNumber(InpMagicNumber);`
     * Determine lot volume: Normalize the lot volume size based on symbol volume rules (`SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP)` and `SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) / SYMBOL_VOLUME_MAX`).
     * Execute Market Order based on confirmation direction:
       * **Bullish (BUY):**
         * Fetch current Ask price: `double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);`
         * Call `g_trade.Buy(riskResult.volume, _Symbol, ask, activeSig.stopLoss, activeSig.takeProfit, InpTradeComment);`
       * **Bearish (SELL):**
         * Fetch current Bid price: `double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);`
         * Call `g_trade.Sell(riskResult.volume, _Symbol, bid, activeSig.stopLoss, activeSig.takeProfit, InpTradeComment);`
     * **Verify Transaction Results:**
       * Check `g_trade.ResultRetcode()`. If the retcode is `TRADE_RETCODE_DONE` (10009) or `TRADE_RETCODE_PLACED` (10008):
         * Update the entry engine signal state: `g_entryEngine.SetActiveSignalExecuted();`
         * Log a success message: `"[TRADE EXECUTED] Lot Volume: X.XX | Entry: X.XXXX | SL: X.XXXX | TP: X.XXXX"` using `Print` and `MNS_Log`.
       * If the retcode returns a failure, print and log a fatal trade execution error with retcode and error details.

---

## 5. Coding & Performance Rules
* Enforce type-safety and ensure clean compiling with 0 errors and 0 warnings.
* Normalize prices to symbol digits using `NormalizeDouble(price, _Digits)`.
* Do not double-trigger trades (only execute if `activeSig.id != s_lastLoggedSignalId` or track using static state variable).
