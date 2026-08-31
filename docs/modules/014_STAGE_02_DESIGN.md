# Module 014 — Stage 2: EA Shell & Coordinator
# Technical Design Specifications

This document outlines the design and implementation specifications for the core Expert Advisor shell (`MNS_EA.mq5`) and its lifecycle coordination pipeline.

---

## 1. Objectives
* Establish the primary Expert Advisor file structure at `Experts/MNS_EA/MNS_EA.mq5`.
* Implement the core MT5 event handlers (`OnInit`, `OnDeinit`, `OnTick`, `OnTimer`, `OnChartEvent`).
* Sequence the initialization and update cycles of all 12 core strategy engines to ensure deterministic analysis.
* Provide clean logging outputs during execution state transitions.

---

## 2. Dependencies and Includes
The EA shell coordinates all analysis engines. It must include the following MNS core files:

```mql5
// Infrastructure
#include <MNS/MNSCore.mqh>
#include <MNS/MNSTypes.mqh>
#include <MNS/MNSUtils.mqh>
#include <MNS/MNSLogger.mqh>
#include <MNS/MNSVolatility.mqh>
#include <MNS/MNSConfig.mqh>

// Core Engines
#include <MNS/CSwingDetector.mqh>
#include <MNS/CStructureEngine.mqh>
#include <MNS/CBreakDetector.mqh>
#include <MNS/COrderFlowEngine.mqh>
#include <MNS/CDeliveryStructureEngine.mqh>
#include <MNS/CLiquidityEngine.mqh>
#include <MNS/CPOIEngine.mqh>
#include <MNS/CObjectiveEngine.mqh>
#include <MNS/CConfirmationEngine.mqh>
#include <MNS/CEntryEngine.mqh>
#include <MNS/CRiskEngine.mqh>
```

---

## 3. Input Parameters
The EA exposes the following inputs to the MT5 interface:

```mql5
//--- Strategy Settings
input string InpConfigFile        = "";       // Config File Name
input int    InpGmtOffset        = 0;        // GMT Offset Hours
input double InpMaxSpreadPoints  = 50.0;     // Max Allowed Spread (Points)
input double InpDefaultRisk      = 1.0;      // Default Risk % Per Trade
input bool   InpDebugLogging     = false;    // Verbose Debug Logging

//--- EA Operational Settings
input bool   InpAutoTrading      = false;    // Enable Automated Trade Execution
input int    InpMaxHistoryBars   = 1000;     // History Bars to Analyze
```

---

## 4. Engine Lifecycle & Event Flow

### 4.1 OnInit()
1. Initialize the Logger and output the EA startup message.
2. Load configuration defaults and optional file profile using `CMNSConfig`.
3. Initialize the 12 core engines in sequential dependency order:
   * `CSwingDetector`
   * `CStructureEngine`
   * `CBreakDetector`
   * `COrderFlowEngine`
   * `CDeliveryStructureEngine`
   * `CLiquidityEngine`
   * `CPOIEngine`
   * `CObjectiveEngine`
   * `CConfirmationEngine`
   * `CEntryEngine`
   * `CRiskEngine`
4. Set a 1-second system timer for background checks.
5. Return `INIT_SUCCEEDED`.

### 4.2 OnDeinit(const int reason)
1. Delete the 1-second system timer.
2. Output shutdown logs indicating the reason code.
3. Perform general memory cleanup.

### 4.3 OnTick()
1. Check if history bars are ready. Ensure the chart has at least `InpMaxHistoryBars` bars loaded.
2. Retrieve current bar price arrays (Open, High, Low, Close, Time, Volume) up to `InpMaxHistoryBars`.
3. Execute the Update pipeline of the 12 engines in dependency sequence:
   * Volatility ATR calculation.
   * Swing detection.
   * Market structure classification.
   * Structural break detection.
   * Order flow evaluation.
   * Delivery structure analysis.
   * Liquidity pool assessment.
   * Points of interest mapping.
   * Objectives (DOL) selection.
   * Confirmation state evaluation.
   * Entry trigger checking.
   * Trade risk parameter calculations.
4. Log any newly triggered signals to the MT5 Terminal console (Terminal print & experts tab) for testing.

---

## 5. Coding & Performance Rules
* **No Blocking Calls**: Event loops must execute fast. Do not block thread execution in `OnTick()`.
* **Zero Warnings**: Compile with `#property strict` (implied in MQL5) to enforce type safety.
* **Logger Safety**: Run all normal updates at `MNS_LOG_INFO` and debug-specific loops at `MNS_LOG_DEBUG`.
