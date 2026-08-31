# Module 014 — Stage 3: Signal Querying & Execution Pipeline
# Technical Design Specifications

This document outlines the specifications for implementing the trade execution pipeline, order routing, and market transaction handling inside the `MNS_EA` Expert Advisor.

---

## 1. Objectives
* Integrate the MQL5 standard library `#include <Trade/Trade.mqh>` (`CTrade` class) to manage order execution safely.
* Query entry signals from `CEntryEngine` and pre-trade lot sizing from `CRiskEngine`.
* Verify market execution conditions (broker spread limits, duplicate position checks).
* Route market buy and sell orders with precise entry, stop loss, and take profit price limits.
* Manage unique trade identification parameters (Magic Number, Trade Comment) to isolate EA operations.

---

## 2. Execution Pipeline Components

### 2.1 MQL5 Standard Trade Interface
The EA will use the MQL5 standard `CTrade` instance declared at file scope:
```mql5
#include <Trade/Trade.mqh>
CTrade g_trade;
```

### 2.2 Input Parameters (Added to MNS_EA.mq5)
```mql5
//--- EA Execution & Position ID Settings
input ulong  InpMagicNumber      = 20260831; // EA Magic Number
input string InpTradeComment     = "MNS_EA"; // Order Comment Description
```

---

## 3. Order Execution Pipeline Logic

During each tick inside `OnTick()`, after the 11 engines have executed their sequential updates, the EA will run the execution pipeline check:

### Step 3.1: Check for Active Signal State
Query the entry engine:
```mql5
if (g_entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE)
```

### Step 3.2: Verify No Active Positions or Pending Orders
Ensure the EA does not open multiple overlapping trades for the current symbol. Check:
1. `PositionsTotal()`: Iterate through open positions. If any position matches `_Symbol` and has `POSITION_MAGIC == InpMagicNumber`, abort order execution.
2. `OrdersTotal()`: Iterate through pending orders. If any order matches `_Symbol` and has `ORDER_MAGIC == InpMagicNumber`, abort order execution.

### Step 3.3: Verify Broker Spread Limits
* Query current symbol spread: `double currentSpread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);`
* Verify `currentSpread <= cfg.maxSpreadPoints`. If spread is exceeded, log a warning and abort order execution.

### Step 3.4: Query Trade Parameters and Lot Size
Retrieve the entry signal coordinates:
```mql5
SEntrySignal activeSig = g_entryEngine.GetActiveSignal();
```
Run `g_riskEngine.SizePreTrade(...)` to calculate position lot size (`volume`) and confirm approval (`approved`).

### Step 3.5: Execute Market Order
If `riskResult.approved` is `true` and `riskResult.volume > 0.0`:
* Configure the trade object:
  ```mql5
  g_trade.SetExpertMagicNumber(InpMagicNumber);
  ```
* Execute trade based on confirmation direction:
  * **Bullish Confirmation (BUY):**
    * Request Bid/Ask: `double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);`
    * Execute Market Buy:
      ```mql5
      g_trade.Buy(riskResult.volume, _Symbol, ask, activeSig.stopLoss, activeSig.takeProfit, InpTradeComment);
      ```
  * **Bearish Confirmation (SELL):**
    * Request Bid/Ask: `double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);`
    * Execute Market Sell:
      ```mql5
      g_trade.Sell(riskResult.volume, _Symbol, bid, activeSig.stopLoss, activeSig.takeProfit, InpTradeComment);
      ```
* Check transaction results. If the trade execution succeeds (`g_trade.ResultRetcode()` returns `TRADE_RETCODE_DONE` or `TRADE_RETCODE_PLACED`):
  * Update the entry engine state: `g_entryEngine.SetActiveSignalExecuted();`
  * Log execution details to logger and terminal console.
  * If the order fails, log a fatal execution error code.

---

## 4. Safety Constraints & Error Handling
* **Type Constraints**: Lot sizes must be normalized to broker steps: `NormalizeDouble(volume, 2)` or using broker `SYMBOL_VOLUME_STEP` settings.
* **Price Slippage**: Use trade helper limits to set maximum slippage parameters (default 30 points).
* **Return Code Check**: Always inspect the trade result return code to log execution diagnostic details.
