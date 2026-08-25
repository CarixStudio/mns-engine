//+------------------------------------------------------------------+
//|                                     MNS_Indicator_ExecutionOnly.mq5 |
//|                              MNS Trading Engine — Module 014       |
//|                                                                    |
//| Purpose:                                                           |
//|   Execution-Only visual coordinator for the MNS Trading Engine     |
//|   renders Entry, SL, and TP risk-reward projection boxes.          |
//|   All other visual layers (swings, zones, dashboard, etc.) are     |
//|   deactivated for a clean, TradingView-style chart experience.    |
//|                                                                    |
//| Version: 1.0.0                                                     |
//| Status:  Production Release — Module 014 Stage 1                   |
//+------------------------------------------------------------------+
#property copyright   "MNS Trading Engine"
#property link        ""
#property version     "1.00"
#property description "MNS Trading Engine — Strategy 3 Execution-Only Indicator"

#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//--- Enable logger macro output
#define MNS_LOG_ENABLE

//+------------------------------------------------------------------+
//| Engine Include Headers (dependency order)                        |
//+------------------------------------------------------------------+
#include <MNS/MNSCore.mqh>
#include <MNS/MNSTypes.mqh>
#include <MNS/MNSUtils.mqh>
#include <MNS/MNSLogger.mqh>
#include <MNS/MNSVolatility.mqh>
#include <MNS/MNSConfig.mqh>
#include <MNS/MNSProfiler.mqh>

// Analysis engines — in DAG dependency order
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

// Visual Renderers layer
#include <MNS/MNSStyle.mqh>
#include <MNS/Renderers/CExecutionRenderer.mqh>

//+------------------------------------------------------------------+
//| Indicator Input Parameters                                        |
//+------------------------------------------------------------------+
input string InpConfigFile        = "";
input int    InpGmtOffset        = 0;
input double InpMaxSpreadPoints  = 50.0;
input double InpDefaultRisk      = 1.0;
input bool   InpDebugLogging     = false;

// Capping & display inputs (kept for compatibility with config updates)
input int    InpMaxRenderedSwings = 50;
input int    InpMaxRenderedBreaks = 20;
input int    InpMaxRenderedPools = 20;
input int    InpMaxRenderedPOIs = 20;
input int    InpMaxHistoryBars   = 1000;
input bool   InpShowDashboard    = false;
input int    InpDashboardX       = 20;
input int    InpDashboardY       = 20;
input int    InpDashboardWidth   = 250;
input bool   InpShowZonePremium      = false;
input bool   InpShowZoneDiscount     = false;
input bool   InpShowZoneEquilibrium  = false;
input bool   InpShowSessions         = false;
input int    InpMaxRenderedSessions  = 15;

#define MNS_INDICATOR_SOURCE "MNS_Indicator_ExecOnly"
#define MNS_INDICATOR_MIN_BARS 64

//+------------------------------------------------------------------+
//| Engine Object Instances                                           |
//+------------------------------------------------------------------+
CSwingDetector           g_swings;
CStructureEngine         g_structure;
CBreakDetector           g_breaks;
COrderFlowEngine         g_orderFlow;
CDeliveryStructureEngine g_delivery;
CLiquidityEngine         g_liquidity;
CPOIEngine               g_poi;
CObjectiveEngine         g_objective;
CConfirmationEngine      g_confirmation;
CEntryEngine             g_entry;
CRiskEngine              g_risk;

//--- Renderer Object Instances
CExecutionRenderer       g_executionRenderer;

//+------------------------------------------------------------------+
//| Lifecycle State                                                   |
//+------------------------------------------------------------------+
bool g_isReady = false;
double g_point = 0.0;

//+------------------------------------------------------------------+
//| OnInit — Indicator Initialization                                 |
//+------------------------------------------------------------------+
int OnInit()
{
    g_isReady = false;
    g_point   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if (g_point <= 0.0)
        g_point = _Point;

    //--- 1. Configure logging
    ENUM_MNS_LOG_LEVEL logLevel = InpDebugLogging ? MNS_LOG_DEBUG : MNS_LOG_INFO;
    CMNSLogger::Initialize(logLevel);

    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE,
        StringFormat("Initializing MNS Execution-Only Indicator v1.0 on %s %s",
                     _Symbol, EnumToString((ENUM_TIMEFRAMES)_Period)));

    //--- 2. Load configuration defaults & profile
    CMNSConfig::SetDefaults();

    if (InpConfigFile != "")
    {
        if (CMNSConfig::LoadFromFile(InpConfigFile))
        {
            MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, StringFormat("Settings profile loaded from file: %s", InpConfigFile));
        }
        else
        {
            MNS_Log(MNS_LOG_WARN, MNS_INDICATOR_SOURCE, StringFormat("Failed to load settings profile from %s. Using default parameters.", InpConfigFile));
        }
    }

    // Sync MT5 Input parameters back to CMNSConfig
    CMNSConfig::UpdateParameter("gmtOffset", (double)InpGmtOffset);
    CMNSConfig::UpdateParameter("maxSpreadPoints", InpMaxSpreadPoints);
    CMNSConfig::UpdateParameter("desiredRiskPercent", InpDefaultRisk);
    CMNSConfig::UpdateParameter("maxRenderedSwings", (double)InpMaxRenderedSwings);
    CMNSConfig::UpdateParameter("maxRenderedBreaks", (double)InpMaxRenderedBreaks);
    CMNSConfig::UpdateParameter("maxRenderedPools", (double)InpMaxRenderedPools);
    CMNSConfig::UpdateParameter("maxRenderedPOIs", (double)InpMaxRenderedPOIs);
    CMNSConfig::UpdateParameter("showDashboard", 0.0); // Always false for Exec Only
    CMNSConfig::UpdateParameter("showZonePremium", 0.0);
    CMNSConfig::UpdateParameter("showZoneDiscount", 0.0);
    CMNSConfig::UpdateParameter("showZoneEquilibrium", 0.0);
    CMNSConfig::UpdateParameter("showSessions", 0.0);

    // Fetch active unified configuration context
    SEngineConfig cfg = CMNSConfig::GetActive();
    double staticMinBreakDist = 2.0 * g_point;

    //--- Initialize engines in strict DAG dependency order.
    if (!g_swings.Initialize(cfg.externalDepth, cfg.internalDepth)) return INIT_FAILED;
    if (!g_structure.Initialize(staticMinBreakDist)) return INIT_FAILED;
    if (!g_breaks.Initialize()) return INIT_FAILED;
    if (!g_orderFlow.Initialize()) return INIT_FAILED;
    if (!g_delivery.Initialize()) return INIT_FAILED;
    if (!g_liquidity.Initialize(cfg.gmtOffset)) return INIT_FAILED;
    if (!g_poi.Initialize()) return INIT_FAILED;
    if (!g_objective.Initialize()) return INIT_FAILED;
    if (!g_confirmation.Initialize()) return INIT_FAILED;
    if (!g_entry.Initialize(cfg.maxSpreadPoints)) return INIT_FAILED;
    if (!g_risk.Initialize(cfg.desiredRiskPercent, 0.25, 2.0, 5.0)) return INIT_FAILED;

    // --- Visual Renderer Initialization
    if (!g_executionRenderer.Initialize("MNS_EXEC_"))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE, "CExecutionRenderer::Initialize() FAILED.");
        return INIT_FAILED;
    }

    g_isReady = true;
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "All engines and execution renderer initialized.");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit — Indicator Deinitialization                             |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "OnDeinit called. Resetting engines.");

    g_risk.ResetPositionTracking();
    g_entry.Reset();
    g_confirmation.Reset();
    g_objective.Reset();
    g_poi.Reset();
    g_liquidity.Reset();
    g_delivery.Reset();
    g_orderFlow.Reset();
    g_breaks.Reset();
    g_structure.Reset();
    g_swings.Reset();

    //--- Clear visuals
    g_executionRenderer.Clear();

    CMNSLogger::Close();
    g_isReady = false;
}

//+------------------------------------------------------------------+
//| GetActivePositionDetails                                         |
//+------------------------------------------------------------------+
bool GetActivePositionDetails(string symbol, EConfirmationDirection &dir, double &entry, double &sl, double &tp, double &vol)
{
    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        string posSymbol = PositionGetSymbol(i);
        if (posSymbol == symbol)
        {
            long type = PositionGetInteger(POSITION_TYPE);
            dir = (type == POSITION_TYPE_BUY) ? CONFIRM_DIR_BULLISH : CONFIRM_DIR_BEARISH;
            entry = PositionGetDouble(POSITION_PRICE_OPEN);
            sl = PositionGetDouble(POSITION_SL);
            tp = PositionGetDouble(POSITION_TP);
            vol = PositionGetDouble(POSITION_VOLUME);
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| OnCalculate — Bar-by-Bar Engine Coordination                      |
//+------------------------------------------------------------------+
int OnCalculate(const int      rates_total,
                const int      prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
    if (!g_isReady) return 0;
    if (rates_total < MNS_INDICATOR_MIN_BARS) return 0;

    ArraySetAsSeries(high,  true);
    ArraySetAsSeries(low,   true);
    ArraySetAsSeries(open,  true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(time,  true);

    // Run on every tick to ensure real-time drawing updates for positions and entries

    SEngineConfig cfg = CMNSConfig::GetActive();
    int atrPeriod = cfg.atrPeriod;
    if (rates_total < atrPeriod + 2) return 0;

    double currentAtr = CMNSVolatility::CalculateATR(high, low, close, 1, atrPeriod, rates_total);
    if (currentAtr <= 0.0) return rates_total;

    double minBreakDist = MathMax(2.0 * g_point, 0.10 * currentAtr);
    int limitBars = MathMin(rates_total, InpMaxHistoryBars);
    int prevCalc = ((prev_calculated > 0) && ((rates_total - prev_calculated) <= 1)) ? prev_calculated : 0;

    //+------------------------------------------------------------------+
    //| Engine Update Sequence                                           |
    //+------------------------------------------------------------------+
    g_swings.Update(high, low, time, limitBars, prevCalc);
    g_structure.Update(g_swings, currentAtr);
    g_breaks.Update(g_swings, g_structure, high, low, close, open, time, limitBars, prevCalc, currentAtr);
    g_orderFlow.Update(g_swings, g_structure, g_breaks, high, low, close, open, time, limitBars, prevCalc, currentAtr);
    
    double prevDolPrice = g_objective.GetDolPrice();
    g_delivery.Update(g_swings, g_structure, g_breaks, g_orderFlow, high, low, close, open, time, limitBars, prevCalc, currentAtr, prevDolPrice);
    g_liquidity.Update(g_swings, g_delivery, high, low, close, open, time, limitBars, prevCalc, currentAtr, minBreakDist);
    g_poi.Update(g_swings, g_structure, g_breaks, g_liquidity, g_delivery, high, low, close, open, time, limitBars, prevCalc, currentAtr);
    g_objective.Update(g_swings, g_structure, g_breaks, g_orderFlow, g_delivery, g_liquidity, g_poi, high, low, close, open, time, limitBars, prevCalc, currentAtr);
    g_confirmation.Update(g_swings, g_structure, g_breaks, g_orderFlow, g_delivery, g_liquidity, g_poi, g_objective, high, low, close, open, time, limitBars, prevCalc, currentAtr);
    
    double currentSpread = (ArraySize(spread) > 0) ? (double)spread[0] : 0.0;
    g_entry.Update(g_confirmation, g_objective, g_structure, g_delivery, g_poi, high, low, close, open, time, limitBars, prevCalc, currentSpread);

    //+------------------------------------------------------------------+
    //| Visual Renderers execution — Execution Projection Only           |
    //+------------------------------------------------------------------+
    EConfirmationDirection posDir = CONFIRM_DIR_NEUTRAL;
    double posEntry = 0.0, posSl = 0.0, posTp = 0.0, posVol = 0.0;

    if (g_entry.HasActiveSignal())
    {
        SEntrySignal activeSig = g_entry.GetActiveSignal();
        SRiskSizingResult riskResult = g_risk.SizePreTrade(activeSig.direction, 
                                                           activeSig.entryPrice, 
                                                           activeSig.stopLoss, 
                                                           activeSig.takeProfit, 
                                                           currentAtr, 
                                                           cfg.desiredRiskPercent, 
                                                           AccountInfoDouble(ACCOUNT_EQUITY), 
                                                           _Symbol);
        double volVal = riskResult.approved ? riskResult.volume : 0.0;
        double riskVal = riskResult.approved ? riskResult.riskAmount : 0.0;
        double rewardVal = riskResult.approved ? (riskResult.riskAmount * riskResult.expectedRr) : 0.0;
        
        g_executionRenderer.Draw(activeSig.direction, 
                                 activeSig.entryPrice, 
                                 activeSig.stopLoss, 
                                 activeSig.takeProfit, 
                                 time, 
                                 currentAtr, 
                                 cfg.executionProjectedBars,
                                 volVal,
                                 riskVal,
                                 rewardVal);
    }
    else if (GetActivePositionDetails(_Symbol, posDir, posEntry, posSl, posTp, posVol))
    {
        double riskDist = MathAbs(posEntry - posSl);
        double rewardDist = MathAbs(posTp - posEntry);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        if (tickSize <= 0.0) tickSize = pointSize;
        if (tickValue <= 0.0) tickValue = 1.0;
        
        double cashRisk = (tickSize > 0.0 && posSl > 0.0) ? ((riskDist / tickSize) * tickValue * posVol) : 0.0;
        double cashReward = (tickSize > 0.0 && posTp > 0.0) ? ((rewardDist / tickSize) * tickValue * posVol) : 0.0;
        
        g_executionRenderer.Draw(posDir, 
                                 posEntry, 
                                 (posSl > 0.0 ? posSl : posEntry - 100 * _Point), 
                                 (posTp > 0.0 ? posTp : posEntry + 100 * _Point), 
                                 time, 
                                 currentAtr, 
                                 cfg.executionProjectedBars,
                                 posVol,
                                 cashRisk,
                                 cashReward);
    }
    else
    {
        g_executionRenderer.Clear();
    }

    ChartRedraw(0);
    return rates_total;
}

//+------------------------------------------------------------------+
//| OnChartEvent — Stubbed                                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
}
