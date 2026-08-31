//+------------------------------------------------------------------+
//|                                                       MNS_EA.mq5 |
//|                              MNS Trading Engine — Module 014     |
//|                                                                  |
//| Purpose:                                                         |
//|   Core Expert Advisor shell and lifecycle coordinator pipeline.   |
//|   Sequences initialization, updates, and risk sizing across all  |
//|   11 strategy engines.                                           |
//|                                                                  |
//| Version: 1.00                                                    |
//| Copyright 2026, MNS Trading Engine.                              |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MNS Trading Engine."
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Dependencies & Includes                                          |
//+------------------------------------------------------------------+
// Infrastructure Includes
#include <MNS/MNSCore.mqh>
#include <MNS/MNSTypes.mqh>
#include <MNS/MNSUtils.mqh>
#include <MNS/MNSLogger.mqh>
#include <MNS/MNSVolatility.mqh>
#include <MNS/MNSConfig.mqh>

// Core Strategy Engine Includes
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

//+------------------------------------------------------------------+
//| Strategy & Operational Input Parameters                          |
//+------------------------------------------------------------------+
//--- Strategy Settings
input string InpConfigFile        = "";       // Config File Name
input int    InpGmtOffset        = 0;        // GMT Offset Hours
input double InpMaxSpreadPoints  = 50.0;     // Max Allowed Spread (Points)
input double InpDefaultRisk      = 1.0;      // Default Risk % Per Trade
input bool   InpDebugLogging     = false;    // Verbose Debug Logging

//--- EA Operational Settings
input bool   InpAutoTrading      = false;    // Enable Automated Trade Execution
input int    InpMaxHistoryBars   = 1000;     // History Bars to Analyze

//+------------------------------------------------------------------+
//| File-Scope Engine Instances (Static Allocation in DAG Order)     |
//+------------------------------------------------------------------+
CSwingDetector           g_swingDetector;
CStructureEngine         g_structureEngine;
CBreakDetector           g_breakDetector;
COrderFlowEngine         g_orderFlowEngine;
CDeliveryStructureEngine g_deliveryEngine;
CLiquidityEngine         g_liquidityEngine;
CPOIEngine               g_poiEngine;
CObjectiveEngine         g_objectiveEngine;
CConfirmationEngine      g_confirmationEngine;
CEntryEngine             g_entryEngine;
CRiskEngine              g_riskEngine;

//+------------------------------------------------------------------+
//| Expert Initialization Function (OnInit)                          |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- 1. Initialize diagnostic logger
    ENUM_MNS_LOG_LEVEL logLevel = InpDebugLogging ? MNS_LOG_DEBUG : MNS_LOG_INFO;
    CMNSLogger::Initialize(logLevel, "MNS_EA.log");

    MNS_Log(MNS_LOG_INFO, "MNS_EA",
        StringFormat("Initializing MNS Expert Advisor v1.0 on %s %s",
                     _Symbol, EnumToString((ENUM_TIMEFRAMES)_Period)));

    //--- 2. Load default configuration parameters
    CMNSConfig::SetDefaults();

    //--- 3. Sync MT5 input parameters to CMNSConfig
    CMNSConfig::UpdateParameter("gmtOffset", (double)InpGmtOffset);
    CMNSConfig::UpdateParameter("maxSpreadPoints", InpMaxSpreadPoints);
    CMNSConfig::UpdateParameter("desiredRiskPercent", InpDefaultRisk);
    CMNSConfig::UpdateParameter("logEnable", 1.0);
    CMNSConfig::UpdateParameter("logLevel", InpDebugLogging ? 0.0 : 1.0);

    //--- 4. Load dynamic settings from sandbox profile if provided
    if (InpConfigFile != "")
    {
        if (CMNSConfig::LoadFromFile(InpConfigFile))
        {
            MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("Configuration profile loaded from file: %s", InpConfigFile));
        }
        else
        {
            MNS_Log(MNS_LOG_WARN, "MNS_EA", StringFormat("Failed to load configuration profile from: %s. Using default settings.", InpConfigFile));
        }
    }

    //--- Fetch active unified engine configuration
    SEngineConfig cfg = CMNSConfig::GetActive();
    double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if (pointSize <= 0.0) pointSize = _Point;
    double staticMinBreakDist = 2.0 * pointSize;

    //--- 5. Initialize all 11 core strategy engines in strict DAG order
    if (!g_swingDetector.Initialize(cfg.externalDepth, cfg.internalDepth))
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CSwingDetector::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CSwingDetector initialized.");

    if (!g_structureEngine.Initialize(staticMinBreakDist))
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CStructureEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CStructureEngine initialized.");

    if (!g_breakDetector.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CBreakDetector::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CBreakDetector initialized.");

    if (!g_orderFlowEngine.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "COrderFlowEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "COrderFlowEngine initialized.");

    if (!g_deliveryEngine.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CDeliveryStructureEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CDeliveryStructureEngine initialized.");

    if (!g_liquidityEngine.Initialize(cfg.gmtOffset))
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CLiquidityEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CLiquidityEngine initialized.");

    if (!g_poiEngine.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CPOIEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CPOIEngine initialized.");

    if (!g_objectiveEngine.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CObjectiveEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CObjectiveEngine initialized.");

    if (!g_confirmationEngine.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CConfirmationEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CConfirmationEngine initialized.");

    if (!g_entryEngine.Initialize(cfg.maxSpreadPoints))
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CEntryEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CEntryEngine initialized.");

    if (!g_riskEngine.Initialize(cfg.desiredRiskPercent, 0.25, 2.0, 5.0))
    {
        MNS_Log(MNS_LOG_FATAL, "MNS_EA", "CRiskEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, "MNS_EA", "CRiskEngine initialized.");

    //--- 6. Configure system timer for periodic operations
    if (!EventSetTimer(1))
    {
        MNS_Log(MNS_LOG_WARN, "MNS_EA", "Failed to register 1-second system timer.");
    }

    MNS_Log(MNS_LOG_INFO, "MNS_EA", "All 11 engines initialized successfully. Expert Advisor ready.");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function (OnDeinit)                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- 1. Kill system timer
    EventKillTimer();

    //--- 2. Reset engine states in reverse DAG dependency order
    g_riskEngine.ResetPositionTracking();
    g_entryEngine.Reset();
    g_confirmationEngine.Reset();
    g_objectiveEngine.Reset();
    g_poiEngine.Reset();
    g_liquidityEngine.Reset();
    g_deliveryEngine.Reset();
    g_orderFlowEngine.Reset();
    g_breakDetector.Reset();
    g_structureEngine.Reset();
    g_swingDetector.Reset();

    //--- 3. Log shutdown summary and close logger
    MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("MNS Expert Advisor deinitialized cleanly. Reason code: %d", reason));
    CMNSLogger::Close();
}

//+------------------------------------------------------------------+
//| Expert Tick Handling Function (OnTick)                           |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- 1. Verify history depth availability
    if (Bars(_Symbol, _Period) < InpMaxHistoryBars)
        return;

    //--- 2. Fetch OHLCV bar series data
    datetime time[];
    double   open[];
    double   high[];
    double   low[];
    double   close[];
    long     volume[];

    ArraySetAsSeries(time,   true);
    ArraySetAsSeries(open,   true);
    ArraySetAsSeries(high,   true);
    ArraySetAsSeries(low,    true);
    ArraySetAsSeries(close,  true);
    ArraySetAsSeries(volume, true);

    int copiedTime  = CopyTime(_Symbol, _Period, 0, InpMaxHistoryBars, time);
    int copiedOpen  = CopyOpen(_Symbol, _Period, 0, InpMaxHistoryBars, open);
    int copiedHigh  = CopyHigh(_Symbol, _Period, 0, InpMaxHistoryBars, high);
    int copiedLow   = CopyLow(_Symbol, _Period, 0, InpMaxHistoryBars, low);
    int copiedClose = CopyClose(_Symbol, _Period, 0, InpMaxHistoryBars, close);
    int copiedVol   = CopyTickVolume(_Symbol, _Period, 0, InpMaxHistoryBars, volume);

    if (copiedTime < InpMaxHistoryBars || copiedOpen < InpMaxHistoryBars ||
        copiedHigh < InpMaxHistoryBars || copiedLow < InpMaxHistoryBars ||
        copiedClose < InpMaxHistoryBars || copiedVol < InpMaxHistoryBars)
    {
        return;
    }

    int copied = InpMaxHistoryBars;

    //--- 3. Retrieve active configuration context
    SEngineConfig cfg = CMNSConfig::GetActive();

    //--- 4. Calculate ATR(14) using volatility helper
    double atr14 = CMNSVolatility::CalculateATR14(high, low, close, copied);
    if (atr14 <= 0.0)
        return;

    double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if (pointSize <= 0.0) pointSize = _Point;
    double minBreakDist = MathMax(2.0 * pointSize, 0.10 * atr14);

    //--- 5. Execute core engine update pipeline in sequential DAG order
    // 1. Swing Detection
    g_swingDetector.Update(high, low, time, copied, 0);

    // 2. Market Structure
    g_structureEngine.Update(g_swingDetector, atr14);

    // 3. Structural Break Detection
    g_breakDetector.Update(g_swingDetector, g_structureEngine,
                           high, low, close, open, time,
                           copied, 0, atr14);

    // 4. Order Flow Evaluation
    g_orderFlowEngine.Update(g_swingDetector, g_structureEngine, g_breakDetector,
                            high, low, close, open, time,
                            copied, 0, atr14);

    // 5. Delivery Structure Analysis
    double prevDolPrice = g_objectiveEngine.GetDolPrice();
    g_deliveryEngine.Update(g_swingDetector, g_structureEngine, g_breakDetector, g_orderFlowEngine,
                            high, low, close, open, time,
                            copied, 0, atr14, prevDolPrice);

    // 6. Liquidity Assessment
    g_liquidityEngine.Update(g_swingDetector, g_deliveryEngine,
                             high, low, close, open, time,
                             copied, 0, atr14, minBreakDist);

    // 7. POI Mapping
    g_poiEngine.Update(g_swingDetector, g_structureEngine, g_breakDetector,
                       g_liquidityEngine, g_deliveryEngine,
                       high, low, close, open, time,
                       copied, 0, atr14);

    // 8. Objectives (DOL) Selection
    g_objectiveEngine.Update(g_swingDetector, g_structureEngine, g_breakDetector,
                             g_orderFlowEngine, g_deliveryEngine, g_liquidityEngine, g_poiEngine,
                             high, low, close, open, time,
                             copied, 0, atr14);

    // 9. Confirmation State Evaluation
    g_confirmationEngine.Update(g_swingDetector, g_structureEngine, g_breakDetector,
                                 g_orderFlowEngine, g_deliveryEngine, g_liquidityEngine, g_poiEngine, g_objectiveEngine,
                                 high, low, close, open, time,
                                 copied, 0, atr14);

    // 10. Entry Signal Triggers
    double currentSpread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    g_entryEngine.Update(g_confirmationEngine, g_objectiveEngine, g_structureEngine,
                         g_deliveryEngine, g_poiEngine,
                         high, low, close, open, time,
                         copied, 0, currentSpread);

    //--- 6. Check Active Signal Triggers & Sizing
    if (g_entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE)
    {
        SEntrySignal activeSig = g_entryEngine.GetActiveSignal();

        static datetime s_lastLoggedSignalId = 0;
        if (activeSig.id != s_lastLoggedSignalId)
        {
            s_lastLoggedSignalId = activeSig.id;

            // Compute pre-trade risk parameters
            SRiskSizingResult riskResult = g_riskEngine.SizePreTrade(activeSig.direction,
                                                                     activeSig.entryPrice,
                                                                     activeSig.stopLoss,
                                                                     activeSig.takeProfit,
                                                                     atr14,
                                                                     cfg.desiredRiskPercent,
                                                                     AccountInfoDouble(ACCOUNT_EQUITY),
                                                                     _Symbol);

            string dirStr = (activeSig.direction == CONFIRM_DIR_BULLISH) ? "BULLISH (BUY)" : "BEARISH (SELL)";
            string logMsg = StringFormat("[ENTRY SIGNAL ACTIVE] SignalID: %s | Direction: %s | Entry: %.5f | SL: %.5f | TP: %.5f | R:R: %.2f | Approved: %s | Lot Volume: %.2f | Risk: %.2f",
                                         TimeToString(activeSig.id, TIME_DATE | TIME_SECONDS),
                                         dirStr,
                                         activeSig.entryPrice,
                                         activeSig.stopLoss,
                                         activeSig.takeProfit,
                                         riskResult.expectedRr,
                                         riskResult.approved ? "YES" : "NO",
                                         riskResult.volume,
                                         riskResult.riskAmount);

            Print(logMsg);
            MNS_Log(MNS_LOG_INFO, "MNS_EA", logMsg);
        }
    }
}

//+------------------------------------------------------------------+
//| Expert Timer Event Function (OnTimer)                            |
//+------------------------------------------------------------------+
void OnTimer()
{
    static int s_timerCounter = 0;
    s_timerCounter++;

    // Operational check every 60 seconds
    if (s_timerCounter % 60 == 0)
    {
        EEntryState signalState = g_entryEngine.GetActiveSignalState();
        string stateStr = "";
        switch (signalState)
        {
            case ENTRY_STATE_NONE:        stateStr = "NONE"; break;
            case ENTRY_STATE_ACTIVE:      stateStr = "ACTIVE"; break;
            case ENTRY_STATE_EXECUTED:    stateStr = "EXECUTED"; break;
            case ENTRY_STATE_EXPIRED:     stateStr = "EXPIRED"; break;
            case ENTRY_STATE_CANCELLED:   stateStr = "CANCELLED"; break;
            case ENTRY_STATE_INVALIDATED: stateStr = "INVALIDATED"; break;
            default:                      stateStr = "UNKNOWN"; break;
        }

        MNS_Log(MNS_LOG_DEBUG, "MNS_EA",
                StringFormat("OnTimer heartbeat: ActiveSignalState=%s | AutoTrading=%s",
                             stateStr, InpAutoTrading ? "ENABLED" : "DISABLED"));
    }
}

//+------------------------------------------------------------------+
//| Chart Event Handler (OnChartEvent)                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Reserved for interactive EA chart events
}
