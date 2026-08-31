# MNS Trading Engine - AI Prompt
# Module 014 — Stage 2: EA Shell & Coordinator

You are the lead software engineer for the MNS Trading Engine.
Your task is to implement the core Expert Advisor file (`MNS_EA.mq5`) under the designated path: **`Experts/MNS_EA/MNS_EA.mq5`**.

---

## REQUIRED CONTEXT FILES (Read These First!)
Before writing any code, inspect the following repository files:
1. `Include/MNS/MNSCore.mqh` — Core success/error codes and constants.
2. `Include/MNS/MNSTypes.mqh` — Data structures.
3. `Include/MNS/MNSConfig.mqh` — Configuration and settings profiles.
4. `Include/MNS/MNSLogger.mqh` — Level-filtered logging.
5. `Include/MNS/CEntryEngine.mqh` — Entry signal state triggers.
6. `docs/modules/014_STAGE_02_DESIGN.md` — Stage 2 Specifications.

---

## Implementation Details

### 1. File Path & Name
* Create the Expert Advisor file at: **`Experts/MNS_EA/MNS_EA.mq5`**.

### 2. Inputs & Setup
Expose the operational inputs described in the design spec:
* `InpConfigFile` (string, default `""`)
* `InpGmtOffset` (int, default `0`)
* `InpMaxSpreadPoints` (double, default `50.0`)
* `InpDefaultRisk` (double, default `1.0`)
* `InpDebugLogging` (bool, default `false`)
* `InpAutoTrading` (bool, default `false`)
* `InpMaxHistoryBars` (int, default `1000`)

### 3. File-Scope Declarations
Declare instances of the following engines at file scope (static allocation) in this exact order:
1. `CSwingDetector g_swingDetector;`
2. `CStructureEngine g_structureEngine;`
3. `CBreakDetector g_breakDetector;`
4. `COrderFlowEngine g_orderFlowEngine;`
5. `CDeliveryStructureEngine g_deliveryEngine;`
6. `CLiquidityEngine g_liquidityEngine;`
7. `CPOIEngine g_poiEngine;`
8. `CObjectiveEngine g_objectiveEngine;`
9. `CConfirmationEngine g_confirmationEngine;`
10. `CEntryEngine g_entryEngine;`
11. `CRiskEngine g_riskEngine;`

### 4. Lifecycle Event Coordination

#### A. OnInit()
* Initialize logging: `CMNSLogger::Initialize("MNS_EA", InpDebugLogging ? MNS_LOG_DEBUG : MNS_LOG_INFO);`
* Call `CMNSConfig::SetDefaults();`
* Sync inputs to config parameters:
  * `CMNSConfig::UpdateParameter("gmtOffset", InpGmtOffset);`
  * `CMNSConfig::UpdateParameter("maxSpreadPoints", InpMaxSpreadPoints);`
  * `CMNSConfig::UpdateParameter("desiredRiskPercent", InpDefaultRisk);`
  * `CMNSConfig::UpdateParameter("logEnable", true);`
  * `CMNSConfig::UpdateParameter("logLevel", InpDebugLogging ? 0.0 : 1.0);`
* Load dynamic settings from file if `InpConfigFile` is provided: `CMNSConfig::LoadFromFile(InpConfigFile);`
* Initialize all 11 engines in sequential order, check return values, and log error/success.
* Set a 1-second system timer: `EventSetTimer(1);`
* Return `INIT_SUCCEEDED`.

#### B. OnDeinit()
* Destroy the timer: `EventKillTimer();`
* Clear engine-specific objects if any.
* Log shutdown message.

#### C. OnTick()
* Verify history: Check if `Bars(_Symbol, _Period) >= InpMaxHistoryBars`. If not, skip calculation.
* Fetch OHLCV data using standard MQL5 arrays (`datetime time[]`, `double open[]`, `double high[]`, `double low[]`, `double close[]`, `long volume[]`). Set all arrays as series (`ArraySetAsSeries(..., true)`).
* Copy rates:
  `int copied = CopyTime(_Symbol, _Period, 0, InpMaxHistoryBars, time);` (and same for open, high, low, close, volume). If copied < `InpMaxHistoryBars`, exit.
* Retrieve the active configuration using `SEngineConfig cfg = CMNSConfig::GetActive();`
* Calculate ATR(14) using volatility helper: `double atr14 = CMNSVolatility::CalculateATR14(high, low, close, copied);`
* Execute the core engine update pipeline sequentially:
  1. `g_swingDetector.Update(high, low, time, copied);`
  2. `g_structureEngine.Update(g_swingDetector, close, time, copied);`
  3. `g_breakDetector.Update(g_swingDetector, g_structureEngine, high, low, close, time, copied, atr14);`
  4. `g_orderFlowEngine.Update(g_breakDetector, g_structureEngine, time, copied);`
  5. `g_deliveryEngine.Update(g_orderFlowEngine, g_structureEngine, time, close, copied);`
  6. `g_liquidityEngine.Update(g_swingDetector, time, high, low, close, copied, cfg.gmtOffset);`
  7. `g_poiEngine.Update(g_swingDetector, g_breakDetector, g_deliveryEngine, open, high, low, close, time, copied);`
  8. `g_objectiveEngine.Update(g_structureEngine, g_breakDetector, g_liquidityEngine, close, time, copied);`
  9. `g_confirmationEngine.Update(g_structureEngine, g_breakDetector, g_poiEngine, g_objectiveEngine, close, time, copied);`
  10. `g_entryEngine.Update(g_confirmationEngine, g_poiEngine, g_objectiveEngine, close, time, copied);`
  11. `g_riskEngine.Update(g_entryEngine, atr14);`
* Check if a new entry signal has triggered on shift 1:
  * Check `g_entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE`.
  * If triggered, log details of the active signal (Direction, Entry price, SL price, TP price) to the console using `Print` or `CMNSLogger`.

#### D. OnTimer()
* Log background status update or perform general operational checks.

---

## 5. Coding Standards
* Enforce MQL5 strict rules.
* Return structures by value, not by local references in const methods.
* Double-check array-series indexing (0 is the current developing candle).
* Write clean comments explaining the event flow.
* Output compiled EA without warnings.
