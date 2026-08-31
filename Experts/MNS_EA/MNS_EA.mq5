//+------------------------------------------------------------------+
//|                                                       MNS_EA.mq5 |
//|                              MNS Trading Engine — Module 014     |
//|                                                                  |
//| Purpose:                                                         |
//|   Core Expert Advisor shell and lifecycle coordinator pipeline.   |
//|   Sequences initialization, updates, risk sizing, and order       |
//|   execution across all 11 strategy engines.                       |
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
// Standard Trade Library
#include <Trade/Trade.mqh>

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
input ulong  InpMagicNumber      = 20260831; // EA Magic Number
input string InpTradeComment     = "MNS_EA"; // Order Comment Description

//+------------------------------------------------------------------+
//| File-Scope Engine & Trade Instances                              |
//+------------------------------------------------------------------+
// MQL5 Standard Trade Instance
CTrade g_trade;

// File-Scope Engine Instances (Static Allocation in DAG Order)
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
//| Helper: Check if an open position exists for symbol & magic      |
//+------------------------------------------------------------------+
bool IsPositionOpen()
{
    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        string posSymbol = PositionGetSymbol(i);
        if (posSymbol == _Symbol)
        {
            if (PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Helper: Check if a pending order exists for symbol & magic       |
//+------------------------------------------------------------------+
bool IsOrderPending()
{
    int total = OrdersTotal();
    for (int i = 0; i < total; i++)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket > 0)
        {
            if (OrderGetString(ORDER_SYMBOL) == _Symbol)
            {
                if (OrderGetInteger(ORDER_MAGIC) == (long)InpMagicNumber)
                    return true;
            }
        }
    }
    return false;
}

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

    //--- 2. Configure CTrade instance
    g_trade.SetExpertMagicNumber(InpMagicNumber);
    g_trade.SetDeviationInPoints(30);

    //--- 3. Load default configuration parameters
    CMNSConfig::SetDefaults();

    //--- 4. Sync MT5 input parameters to CMNSConfig
    CMNSConfig::UpdateParameter("gmtOffset", (double)InpGmtOffset);
    CMNSConfig::UpdateParameter("maxSpreadPoints", InpMaxSpreadPoints);
    CMNSConfig::UpdateParameter("desiredRiskPercent", InpDefaultRisk);
    CMNSConfig::UpdateParameter("logEnable", 1.0);
    CMNSConfig::UpdateParameter("logLevel", InpDebugLogging ? 0.0 : 1.0);

    //--- 5. Load dynamic settings from sandbox profile if provided
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

    //--- 6. Initialize all 11 core strategy engines in strict DAG order
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

    //--- 7. Configure system timer for periodic operations
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

    //--- 6. Check Active Signal Triggers & Execute Trade Pipeline
    if (g_entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE)
    {
        SEntrySignal activeSig = g_entryEngine.GetActiveSignal();
        static datetime s_lastProcessedSignalId = 0;

        // Step 3.2: Verify no overlapping open positions or pending orders
        if (IsPositionOpen() || IsOrderPending())
        {
            if (activeSig.id != s_lastProcessedSignalId)
            {
                s_lastProcessedSignalId = activeSig.id;
                MNS_Log(MNS_LOG_INFO, "MNS_EA",
                    "[TRADE SKIPPED] Active position or pending order found for symbol with matching Magic Number.");
            }
        }
        // Step 3.3: Verify broker spread limits
        else if (currentSpread > cfg.maxSpreadPoints)
        {
            if (activeSig.id != s_lastProcessedSignalId)
            {
                s_lastProcessedSignalId = activeSig.id;
                MNS_Log(MNS_LOG_WARN, "MNS_EA",
                    StringFormat("[SPREAD LIMIT EXCEEDED] Current spread (%.1f pts) exceeds maximum limit (%.1f pts). Trade skipped.",
                                 currentSpread, cfg.maxSpreadPoints));
            }
        }
        else
        {
            // Step 3.4: Query risk sizing and execution parameters
            SRiskSizingResult riskResult = g_riskEngine.SizePreTrade(activeSig.direction,
                                                                     activeSig.entryPrice,
                                                                     activeSig.stopLoss,
                                                                     activeSig.takeProfit,
                                                                     atr14,
                                                                     cfg.desiredRiskPercent,
                                                                     AccountInfoDouble(ACCOUNT_EQUITY),
                                                                     _Symbol);

            if (activeSig.id != s_lastProcessedSignalId)
            {
                s_lastProcessedSignalId = activeSig.id;

                string dirStr = (activeSig.direction == CONFIRM_DIR_BULLISH) ? "BULLISH (BUY)" : "BEARISH (SELL)";
                MNS_Log(MNS_LOG_INFO, "MNS_EA",
                    StringFormat("[ENTRY SIGNAL ACTIVE] SignalID: %s | Direction: %s | Entry: %.*f | SL: %.*f | TP: %.*f | R:R: %.2f | Approved: %s | Lot Volume: %.2f | Risk: %.2f",
                                 TimeToString(activeSig.id, TIME_DATE | TIME_SECONDS),
                                 dirStr,
                                 _Digits, activeSig.entryPrice,
                                 _Digits, activeSig.stopLoss,
                                 _Digits, activeSig.takeProfit,
                                 riskResult.expectedRr,
                                 riskResult.approved ? "YES" : "NO",
                                 riskResult.volume,
                                 riskResult.riskAmount));

                // Check Automated Trading toggle input parameter
                if (!InpAutoTrading)
                {
                    MNS_Log(MNS_LOG_INFO, "MNS_EA", "[AUTO-TRADING DISABLED] Signal detected and logged. InpAutoTrading is false — market execution skipped.");
                }
                else if (riskResult.approved && riskResult.volume > 0.0)
                {
                    // Step 3.5: Execute Market Order via CTrade
                    double volMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
                    double volMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
                    double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
                    if (volMin <= 0.0)  volMin = 0.01;
                    if (volMax <= 0.0)  volMax = 100.0;
                    if (volStep <= 0.0) volStep = 0.01;

                    double volume = MathFloor(riskResult.volume / volStep) * volStep;
                    if (volume < volMin) volume = volMin;
                    if (volume > volMax) volume = volMax;
                    volume = NormalizeDouble(volume, 2);

                    double slPrice = NormalizeDouble(activeSig.stopLoss, _Digits);
                    double tpPrice = NormalizeDouble(activeSig.takeProfit, _Digits);

                    g_trade.SetExpertMagicNumber(InpMagicNumber);
                    g_trade.SetDeviationInPoints(30);

                    bool orderSent = false;
                    double execPrice = 0.0;

                    if (activeSig.direction == CONFIRM_DIR_BULLISH)
                    {
                        execPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
                        orderSent = g_trade.Buy(volume, _Symbol, execPrice, slPrice, tpPrice, InpTradeComment);
                    }
                    else if (activeSig.direction == CONFIRM_DIR_BEARISH)
                    {
                        execPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
                        orderSent = g_trade.Sell(volume, _Symbol, execPrice, slPrice, tpPrice, InpTradeComment);
                    }

                    uint retcode = g_trade.ResultRetcode();
                    if (orderSent && (retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_PLACED))
                    {
                        g_entryEngine.SetActiveSignalExecuted();
                        string execMsg = StringFormat("[TRADE EXECUTED] Lot Volume: %.2f | Entry: %.*f | SL: %.*f | TP: %.*f",
                                                     volume, _Digits, execPrice, _Digits, slPrice, _Digits, tpPrice);
                        Print(execMsg);
                        MNS_Log(MNS_LOG_INFO, "MNS_EA", execMsg);
                    }
                    else
                    {
                        string errMsg = StringFormat("[TRADE ERROR] Market execution failed. Retcode: %u (%s) | Error: %d",
                                                     retcode, g_trade.ResultRetcodeDescription(), GetLastError());
                        Print(errMsg);
                        MNS_Log(MNS_LOG_ERROR, "MNS_EA", errMsg);
                    }
                }
                else
                {
                    MNS_Log(MNS_LOG_WARN, "MNS_EA", "[TRADE SKIPPED] Pre-trade risk sizing was not approved or volume is 0.0.");
                }
            }
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
