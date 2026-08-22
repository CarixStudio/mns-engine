//+------------------------------------------------------------------+
//|                                                  MNS_Indicator.mq5 |
//|                              MNS Trading Engine — Module 013       |
//|                              Stage 1: Shell & Lifecycle Coordinator|
//|                                                                    |
//| Purpose:                                                           |
//|   Coordinator shell for the MNS Trading Engine Strategy 3 indicator|
//|   integration. Orchestrates engine lifecycle and update sequencing |
//|   without implementing any visual rendering or trading execution.  |
//|                                                                    |
//| Stage 1 Responsibilities:                                          |
//|   - Validate chart context (symbol / timeframe).                   |
//|   - Load engine configuration via CMNSConfig.                      |
//|   - Instantiate all 11 analysis engine objects.                    |
//|   - Initialize them in correct DAG dependency order.               |
//|   - Fail safely with diagnostic messages on any init failure.      |
//|   - Drive engine Update() calls in dependency order on every closed|
//|     bar inside OnCalculate().                                       |
//|   - Cleanly destroy all engines in OnDeinit().                     |
//|                                                                    |
//| Stage 1 Non-Responsibilities (explicitly deferred):                |
//|   - No chart object creation.                                      |
//|   - No swing arrows, break labels, OB/FVG rectangles, or lines.    |
//|   - No dashboard or statistics panel.                              |
//|   - No trading orders or position management.                      |
//|   - No risk execution.                                             |
//|   - No new strategy calculations beyond engine coordination.       |
//|                                                                    |
//| Client-Locked Strategy Rules (Stage 1 scope):                      |
//|   - Primary execution timeframe: M5.                               |
//|   - Confirmation uses closed candle (shift 1 on tick, shift 2+     |
//|     for swing confirmation).                                        |
//|   - ATR period: 14 (locked, from CMNSConfig defaults).             |
//|   - External swing depth: 15 (locked).                             |
//|   - Internal swing depth: 5 (locked).                              |
//|   - Min break distance: max(2*Point, 0.10*ATR(14)) (runtime).      |
//|                                                                    |
//| Architecture:                                                       |
//|   Engines are stored as file-scope object instances (static        |
//|   allocation). No dynamic heap allocation is required at the       |
//|   coordinator level because each engine manages its own internal   |
//|   arrays and states.                                               |
//|                                                                    |
//| Version: 1.0                                                       |
//| Status:  Stage 1 — Shell Only                                      |
//+------------------------------------------------------------------+
#property copyright   "MNS Trading Engine"
#property link        ""
#property version     "1.00"
#property description "MNS Trading Engine — Strategy 3 Indicator (Stage 1: Coordinator Shell)"

//--- Indicator declaration: custom indicator, no sub-window, zero buffers.
//    Stage 1 renders nothing. Buffers are introduced in Stage 2+.
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//--- Enable logger macro output
#define MNS_LOG_ENABLE

//--- Enable performance profiling telemetry
#define MNS_PROFILING_ENABLE

//+------------------------------------------------------------------+
//| Engine Include Headers (dependency order)                        |
//+------------------------------------------------------------------+
// Infrastructure layer — must come first
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

// Visual Renderers layer — Stage 2
#include <MNS/MNSStyle.mqh>
#include <MNS/Renderers/CSwingRenderer.mqh>
#include <MNS/Renderers/CStructureRenderer.mqh>
#include <MNS/Renderers/CLiquidityRenderer.mqh>
#include <MNS/Renderers/CPOIRenderer.mqh>
#include <MNS/Renderers/CDeliveryRenderer.mqh>
#include <MNS/Renderers/CDashboardRenderer.mqh>
#include <MNS/Renderers/CZoneRenderer.mqh>
#include <MNS/Renderers/CSessionRenderer.mqh>

//+------------------------------------------------------------------+
//| Indicator Input Parameters                                        |
//+------------------------------------------------------------------+

/// @brief Settings profile file path relative to MQL5\Files sandbox folder (optional).
input string InpConfigFile        = "";

/// @brief GMT offset in whole hours for session boundary calculations.
/// Used by CLiquidityEngine to detect daily/weekly/session transitions.
/// Default 0 = UTC/GMT broker time.
input int    InpGmtOffset        = 0;

/// @brief Maximum spread in points to allow signal processing.
/// Passed to CEntryEngine. Default 50 points.
input double InpMaxSpreadPoints  = 50.0;

/// @brief Default risk percentage per trade (for display only in Stage 1).
/// Passed to CRiskEngine. Default 1.0%.
input double InpDefaultRisk      = 1.0;

/// @brief Enable verbose debug-level logging to the Experts tab.
/// When false, only INFO/WARN/ERROR messages are printed.
input bool   InpDebugLogging     = false;

//--- Visual Renderer Capping inputs (Stage 2)
/// @brief Maximum historical swing points to render on the chart.
input int    InpMaxRenderedSwings = 50;

/// @brief Maximum historical BOS/CHoCH lines to render on the chart.
input int    InpMaxRenderedBreaks = 20;

/// @brief Maximum historical active liquidity pools to render on the chart.
input int    InpMaxRenderedPools = 20;

/// @brief Maximum historical active POI zones to render on the chart.
input int    InpMaxRenderedPOIs = 20;

/// @brief Maximum history bars to process (prevents engine array overflows).
input int    InpMaxHistoryBars   = 1000;

/// @brief Enable visual rendering of the status dashboard.
input bool   InpShowDashboard    = true;

/// @brief X offset in pixels from chart corner for dashboard.
input int    InpDashboardX       = 20;

/// @brief Y offset in pixels from chart corner for dashboard.
input int    InpDashboardY       = 20;

/// @brief Width of dashboard panel in pixels.
input int    InpDashboardWidth   = 250;

/// @brief Enable rendering of Premium Zones on the chart.
input bool   InpShowZonePremium      = true;

/// @brief Enable rendering of Discount Zones on the chart.
input bool   InpShowZoneDiscount     = true;

/// @brief Enable rendering of the Equilibrium midpoint line.
input bool   InpShowZoneEquilibrium  = true;

/// @brief Enable background session shading bands.
input bool   InpShowSessions         = true;

/// @brief Maximum historical session shading blocks to render.
input int    InpMaxRenderedSessions  = 15;

//+------------------------------------------------------------------+
//| Module Identifier                                                 |
//+------------------------------------------------------------------+
#define MNS_INDICATOR_SOURCE "MNS_Indicator"

//+------------------------------------------------------------------+
//| Minimum history bars required before any engine can be updated.   |
//|                                                                    |
//| Rationale:                                                         |
//|   - External swing confirmation requires 15 bars each side = 30.  |
//|   - MNS_SWING_MIN_SHIFT = 2 adds 2 bars for safety margin.        |
//|   - ATR(14) requires 14+1 = 15 bars.                               |
//|   - We use 64 as a conservative, practical minimum that ensures   |
//|     at least one external swing can be confirmed before engines    |
//|     begin processing.                                              |
//+------------------------------------------------------------------+
#define MNS_INDICATOR_MIN_BARS 64

//+------------------------------------------------------------------+
//| Engine Object Instances                                           |
//|                                                                    |
//| All engines are statically allocated at file scope.               |
//| MQL5 initialises global objects before OnInit() is called.        |
//| OnInit() calls Initialize() on each engine and aborts on failure. |
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

//--- Renderer Object Instances (Stage 2)
CSwingRenderer           g_swingRenderer;
CStructureRenderer       g_structureRenderer;
CLiquidityRenderer       g_liquidityRenderer;
CPOIRenderer             g_poiRenderer;
CDeliveryRenderer        g_deliveryRenderer;
CDashboardRenderer       g_dashboardRenderer;
CZoneRenderer            g_zoneRenderer;
CSessionRenderer         g_sessionRenderer;

//+------------------------------------------------------------------+
//| Lifecycle State                                                   |
//+------------------------------------------------------------------+

/// @brief Set to true only after all engines have initialised
///        successfully. Guards OnCalculate() from running with a
///        partial engine graph.
bool g_isReady = false;

/// @brief Cached Point value for the current symbol, set in OnInit().
double g_point = 0.0;

//+------------------------------------------------------------------+
//| OnInit — Indicator Initialization                                 |
//+------------------------------------------------------------------+
/// @brief Called by MT5 once when the indicator is loaded or the chart
///        symbol/timeframe changes.
///
/// Sequence:
///   1. Configure logger.
///   2. Set engine configuration defaults.
///   3. Initialize all engines in DAG dependency order.
///   4. Return INIT_FAILED on any engine initialization failure to
///      prevent OnCalculate() from executing with a broken engine graph.
///
/// @return INIT_SUCCEEDED on success, INIT_FAILED on any failure.
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
        StringFormat("Initializing MNS Indicator v1.0 on %s %s",
                     _Symbol, EnumToString((ENUM_TIMEFRAMES)_Period)));

    //--- 2. Load configuration defaults & profile
    CMNSConfig::SetDefaults();

    // Load settings from config file if specified
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
    CMNSConfig::UpdateParameter("showDashboard", InpShowDashboard ? 1.0 : 0.0);
    CMNSConfig::UpdateParameter("dashboardX", (double)InpDashboardX);
    CMNSConfig::UpdateParameter("dashboardY", (double)InpDashboardY);
    CMNSConfig::UpdateParameter("dashboardWidth", (double)InpDashboardWidth);
    CMNSConfig::UpdateParameter("showZonePremium", InpShowZonePremium ? 1.0 : 0.0);
    CMNSConfig::UpdateParameter("showZoneDiscount", InpShowZoneDiscount ? 1.0 : 0.0);
    CMNSConfig::UpdateParameter("showZoneEquilibrium", InpShowZoneEquilibrium ? 1.0 : 0.0);
    CMNSConfig::UpdateParameter("showSessions", InpShowSessions ? 1.0 : 0.0);
    CMNSConfig::UpdateParameter("maxRenderedSessions", (double)InpMaxRenderedSessions);

    // Fetch active unified configuration context
    SEngineConfig cfg = CMNSConfig::GetActive();

    //--- 3. Compute runtime-derived minimum break distance
    //       max(2 * Point, 0.10 * ATR(14)) is evaluated dynamically per bar.
    //       For initialization we set a safe static fallback.
    //       The actual dynamic value is calculated inside OnCalculate().
    double staticMinBreakDist = 2.0 * g_point;

    //--- 4. Initialize engines in strict DAG dependency order.
    //       If any engine fails, log a FATAL error and return INIT_FAILED.

    // --- Engine 1: CSwingDetector (no engine dependencies)
    if (!g_swings.Initialize(cfg.externalDepth, cfg.internalDepth))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CSwingDetector::Initialize() FAILED — check externalDepth/internalDepth config.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CSwingDetector initialized.");

    // --- Engine 2: CStructureEngine (depends on: CSwingDetector)
    if (!g_structure.Initialize(staticMinBreakDist))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CStructureEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CStructureEngine initialized.");

    // --- Engine 3: CBreakDetector (depends on: CSwingDetector, CStructureEngine)
    if (!g_breaks.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CBreakDetector::Initialize() FAILED — possible array allocation failure.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CBreakDetector initialized.");

    // --- Engine 4: COrderFlowEngine (depends on: CSwingDetector, CStructureEngine, CBreakDetector)
    if (!g_orderFlow.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "COrderFlowEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "COrderFlowEngine initialized.");

    // --- Engine 5: CDeliveryStructureEngine
    //               (depends on: CSwingDetector, CStructureEngine, CBreakDetector, COrderFlowEngine)
    if (!g_delivery.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CDeliveryStructureEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CDeliveryStructureEngine initialized.");

    // --- Engine 6: CLiquidityEngine (depends on: CSwingDetector, CDeliveryStructureEngine)
    if (!g_liquidity.Initialize(cfg.gmtOffset))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CLiquidityEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CLiquidityEngine initialized.");

    // --- Engine 7: CPOIEngine
    //               (depends on: CSwingDetector, CStructureEngine, CBreakDetector,
    //                            CLiquidityEngine, CDeliveryStructureEngine)
    if (!g_poi.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CPOIEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CPOIEngine initialized.");

    // --- Engine 8: CObjectiveEngine (depends on: all previous 7 engines)
    if (!g_objective.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CObjectiveEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CObjectiveEngine initialized.");

    // --- Engine 9: CConfirmationEngine (depends on: all previous 8 engines)
    if (!g_confirmation.Initialize())
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CConfirmationEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CConfirmationEngine initialized.");

    // --- Engine 10: CEntryEngine
    //                (depends on: CConfirmationEngine, CObjectiveEngine, CStructureEngine,
    //                             CDeliveryStructureEngine, CPOIEngine)
    if (!g_entry.Initialize(cfg.maxSpreadPoints))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CEntryEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CEntryEngine initialized.");

    // --- Engine 11: CRiskEngine (no bar-by-bar Update(); on-demand calls only)
    if (!g_risk.Initialize(cfg.desiredRiskPercent, 0.25, 2.0, 5.0))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE,
            "CRiskEngine::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "CRiskEngine initialized.");

    // --- Visual Renderers Initialization (Stage 2)
    SIndicatorStyle style;
    style.Reset(); // Load default premium visual tokens
    if (!g_swingRenderer.Initialize(style, cfg.maxRenderedSwings))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE, "CSwingRenderer::Initialize() FAILED.");
        return INIT_FAILED;
    }
    if (!g_structureRenderer.Initialize(style, cfg.maxRenderedBreaks))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE, "CStructureRenderer::Initialize() FAILED.");
        return INIT_FAILED;
    }
    if (!g_liquidityRenderer.Initialize(style, cfg.maxRenderedPools))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE, "CLiquidityRenderer::Initialize() FAILED.");
        return INIT_FAILED;
    }
    if (!g_poiRenderer.Initialize(style, cfg.maxRenderedPOIs))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE, "CPOIRenderer::Initialize() FAILED.");
        return INIT_FAILED;
    }
    if (!g_deliveryRenderer.Initialize(style))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE, "CDeliveryRenderer::Initialize() FAILED.");
        return INIT_FAILED;
    }
    if (!g_dashboardRenderer.Initialize(style, cfg.showDashboard, cfg.dashboardX, cfg.dashboardY, cfg.dashboardWidth))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE, "CDashboardRenderer::Initialize() FAILED.");
        return INIT_FAILED;
    }
    if (!g_zoneRenderer.Initialize(style))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE, "CZoneRenderer::Initialize() FAILED.");
        return INIT_FAILED;
    }
    if (!g_sessionRenderer.Initialize(style, cfg.maxRenderedSessions))
    {
        MNS_Log(MNS_LOG_FATAL, MNS_INDICATOR_SOURCE, "CSessionRenderer::Initialize() FAILED.");
        return INIT_FAILED;
    }
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "Visual renderers initialized.");

    //--- All engines initialized successfully
    g_isReady = true;
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE,
        "All engines initialized. Indicator ready.");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit — Indicator Deinitialization                             |
//+------------------------------------------------------------------+
/// @brief Called by MT5 when the indicator is removed or the chart
///        context changes.
///
/// Resets all engine states and closes the logger file handle.
/// No chart objects are present to remove in Stage 1.
///
/// @param reason The deinitialization reason code from MT5.
void OnDeinit(const int reason)
{
    MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE,
        StringFormat("OnDeinit called. Reason: %d. Resetting engines.", reason));

    //--- Reset all engines in reverse DAG order to release internal state cleanly.
    //    Stage 1 engines store fixed-size arrays internally; Reset() zeroes them
    //    without heap deallocation, which is safe and sufficient.
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

    //--- Clear all visual objects on deinitialization (Stage 2)
    g_swingRenderer.Reset();
    g_structureRenderer.Reset();
    g_liquidityRenderer.Reset();
    g_poiRenderer.Reset();
    g_deliveryRenderer.Reset();
    g_zoneRenderer.Reset();
    g_sessionRenderer.Reset();
    if (reason == REASON_REMOVE)
    {
        g_dashboardRenderer.DeleteGlobalVariables();
    }
    g_dashboardRenderer.Reset();

    #ifdef MNS_PROFILING_ENABLE
        MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "Generating final performance profile report...");
        CMNSProfiler::ReportTelemetry();
        CMNSProfiler::Reset();
    #endif

    //--- Close logger file handle
    CMNSLogger::Close();

    g_isReady = false;
}

//+------------------------------------------------------------------+
//| OnCalculate — Bar-by-Bar Engine Coordination                      |
//+------------------------------------------------------------------+
/// @brief Called by MT5 on every tick and on every new bar close.
///
/// Lifecycle handling:
///   - Returns 0 immediately if engines are not ready (failed OnInit).
///   - Returns 0 if insufficient history is available.
///   - On the first call (prevCalculated == 0) forces a full history
///     rescan by all engines.
///   - On incremental ticks processes only newly closed bars.
///   - Does NOT process index 0 (the forming/live candle) for any
///     engine that requires confirmed candles (all of them).
///
/// ATR computation:
///   - Calculated at bar index 1 (last closed bar) using Wilder's
///     smoothing from MNSVolatility.
///   - This value is passed to every engine in the current Update() call.
///   - The dynamic minBreakDistance is derived from this ATR value.
///
/// Engine update order strictly follows the DAG:
///   SwingDetector → StructureEngine → BreakDetector → OrderFlowEngine
///   → DeliveryStructureEngine → LiquidityEngine → POIEngine
///   → ObjectiveEngine → ConfirmationEngine → EntryEngine
///   (RiskEngine has no bar-driven Update — called on-demand only.)
///
/// @return The number of bars calculated (standard MT5 convention).
///         Returning ratesTotal tells MT5 not to request a recalculation
///         unless new bars arrive.
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
    //--- Guard: engines must be fully initialized before any processing.
    if (!g_isReady)
    {
        Print("[DEBUG] [MNS_Indicator] Engines not ready yet.");
        return 0;
    }

    //--- Guard: require a minimum history depth before any engine update.
    if (rates_total < MNS_INDICATOR_MIN_BARS)
    {
        Print(StringFormat("[DEBUG] [MNS_Indicator] rates_total (%d) < MIN_BARS (%d). Returning early.", rates_total, MNS_INDICATOR_MIN_BARS));
        return 0;
    }

    //--- Set all price arrays as time-series (index 0 = newest bar).
    //    This matches the data contract expected by all engine Update() calls.
    //    ArraySetAsSeries is idempotent — safe to call on every tick.
    ArraySetAsSeries(high,  true);
    ArraySetAsSeries(low,   true);
    ArraySetAsSeries(open,  true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(time,  true);

    //--- Detect whether this is a new bar or a tick within the same bar.
    //    MT5 convention: if prev_calculated == rates_total, no new bar has
    //    closed since the last OnCalculate() call.
    //    We use a static variable to track the last known bar time.
    static datetime s_lastBarTime = 0;
    bool isNewBar = (time[0] != s_lastBarTime);

    //--- Only perform engine updates on new bars to avoid redundant
    //    recalculation on every tick. The engines update only confirmed
    //    (closed) candles, so tick-level calls within the same bar carry
    //    no new analytical information.
    if (!isNewBar && prev_calculated > 0)
        return rates_total;

    //--- Update the last-bar timestamp tracker.
    s_lastBarTime = time[0];

    //--- Start main calculate performance profiling
    MNS_ProfileStart("Total_Calculate");

    //--- Log entry for debugging attach/recalculation issues (printed after setting time array series order)
    Print(StringFormat("[DEBUG] [MNS_Indicator] OnCalculate: rates_total=%d, prev_calculated=%d, live_time=%s", 
                       rates_total, prev_calculated, TimeToString(time[0], TIME_DATE|TIME_MINUTES|TIME_SECONDS)));

    //--- Compute the current ATR at bar index 1 (last closed bar).
    //    Index 0 is the forming candle — never used for ATR input.
    //    We need at least (ATR period + 1) closed bars.
    SEngineConfig cfg = CMNSConfig::GetActive();
    int atrPeriod = cfg.atrPeriod; // default 14
    if (rates_total < atrPeriod + 2)
    {
        MNS_ProfileStop("Total_Calculate");
        return 0;
    }

    double currentAtr = CMNSVolatility::CalculateATR(high, low, close, 1, atrPeriod, rates_total);
    if (currentAtr <= 0.0)
    {
        MNS_Log(MNS_LOG_WARN, MNS_INDICATOR_SOURCE,
            StringFormat("ATR calculation returned 0 at bar %d. Skipping engine update.",
                         rates_total));
        MNS_ProfileStop("Total_Calculate");
        return rates_total;
    }

    //--- Compute the dynamic minimum break distance.
    //    Strategy rule (client-locked): max(2 * Point, 0.10 * ATR(14))
    double minBreakDist = MathMax(2.0 * g_point, 0.10 * currentAtr);

    //--- Determine prevCalculated to pass to engines.
    //    We restrict the history processed by the engines to prevent filling fixed-size buffers.
    int limitBars = MathMin(rates_total, InpMaxHistoryBars);

    //    Incremental prevCalc: on normal bar-by-bar operation, pass prev_calculated so
    //    engines that support incremental processing skip already-confirmed bars.
    //    Force a full rescan (prevCalc = 0) when:
    //      a) This is the very first calculation (prev_calculated == 0), or
    //      b) More than 1 new bar arrived since the last call (gap / chart reload).
    //    This guarantees correctness is never sacrificed for the performance gain.
    int prevCalc = ((prev_calculated > 0) && ((rates_total - prev_calculated) <= 1))
                   ? prev_calculated
                   : 0;

    //+------------------------------------------------------------------+
    //| Engine Update Sequence — strict DAG order                        |
    //+------------------------------------------------------------------+
    MNS_ProfileStart("Core_Engine_Updates");

    // 1. CSwingDetector — root of the engine graph
    MNS_ProfileStart("Engine_Swings");
    g_swings.Update(high, low, time, limitBars, prevCalc);
    MNS_ProfileStop("Engine_Swings");

    // 2. CStructureEngine — depends on CSwingDetector output
    MNS_ProfileStart("Engine_Structure");
    g_structure.Update(g_swings, currentAtr);
    MNS_ProfileStop("Engine_Structure");

    // 3. CBreakDetector — depends on CSwingDetector + CStructureEngine
    MNS_ProfileStart("Engine_Breaks");
    g_breaks.Update(g_swings, g_structure,
                    high, low, close, open, time,
                    limitBars, prevCalc, currentAtr);
    MNS_ProfileStop("Engine_Breaks");

    // 4. COrderFlowEngine — depends on CSwingDetector + CStructureEngine + CBreakDetector
    MNS_ProfileStart("Engine_OrderFlow");
    g_orderFlow.Update(g_swings, g_structure, g_breaks,
                       high, low, close, open, time,
                       limitBars, prevCalc, currentAtr);
    MNS_ProfileStop("Engine_OrderFlow");

    // 5. CDeliveryStructureEngine
    //    — depends on CSwingDetector, CStructureEngine, CBreakDetector, COrderFlowEngine
    //    — htfDolPrice passed as DBL_MAX; objective is not yet available on
    //      first pass (CObjectiveEngine has not run yet). On subsequent bars,
    //      the previous objective DOL price is passed to enable the engine to
    //      compare against its internal delivery target.
    MNS_ProfileStart("Engine_Delivery");
    double prevDolPrice = g_objective.GetDolPrice();
    g_delivery.Update(g_swings, g_structure, g_breaks, g_orderFlow,
                      high, low, close, open, time,
                      limitBars, prevCalc, currentAtr,
                      prevDolPrice);
    MNS_ProfileStop("Engine_Delivery");

    // 6. CLiquidityEngine — depends on CSwingDetector + CDeliveryStructureEngine
    MNS_ProfileStart("Engine_Liquidity");
    g_liquidity.Update(g_swings, g_delivery,
                       high, low, close, open, time,
                       limitBars, prevCalc, currentAtr, minBreakDist);
    MNS_ProfileStop("Engine_Liquidity");

    // 7. CPOIEngine
    //    — depends on CSwingDetector, CStructureEngine, CBreakDetector,
    //                 CLiquidityEngine, CDeliveryStructureEngine
    MNS_ProfileStart("Engine_POI");
    g_poi.Update(g_swings, g_structure, g_breaks, g_liquidity, g_delivery,
                 high, low, close, open, time,
                 limitBars, prevCalc, currentAtr);
    MNS_ProfileStop("Engine_POI");

    // 8. CObjectiveEngine — depends on all previous engines
    MNS_ProfileStart("Engine_Objective");
    g_objective.Update(g_swings, g_structure, g_breaks, g_orderFlow,
                       g_delivery, g_liquidity, g_poi,
                       high, low, close, open, time,
                       limitBars, prevCalc, currentAtr);
    MNS_ProfileStop("Engine_Objective");

    // 9. CConfirmationEngine — depends on all previous engines
    MNS_ProfileStart("Engine_Confirmation");
    g_confirmation.Update(g_swings, g_structure, g_breaks, g_orderFlow,
                          g_delivery, g_liquidity, g_poi, g_objective,
                          high, low, close, open, time,
                          limitBars, prevCalc, currentAtr);
    MNS_ProfileStop("Engine_Confirmation");

    // 10. CEntryEngine
    //     — depends on CConfirmationEngine, CObjectiveEngine, CStructureEngine,
    //                  CDeliveryStructureEngine, CPOIEngine
    //     — currentSpreadPoints: obtained from the live spread array index 0
    //       (the forming bar spread is sufficient for the entry filter check).
    MNS_ProfileStart("Engine_Entry");
    double currentSpread = (ArraySize(spread) > 0) ? (double)spread[0] : 0.0;
    g_entry.Update(g_confirmation, g_objective, g_structure, g_delivery, g_poi,
                   high, low, close, open, time,
                   limitBars, prevCalc, currentSpread);
    MNS_ProfileStop("Engine_Entry");

    // 11. CRiskEngine — no bar-driven Update().
    //     SizePreTrade() and UpdateActiveManagement() are called on-demand
    //     by the EA or the Stage 5 dashboard when a signal is active.
    //     No call is made here.

    MNS_ProfileStop("Core_Engine_Updates");
    MNS_ProfileStop("Total_Calculate");

    //+------------------------------------------------------------------+
    //| Visual Renderers execution (Stage 2)                              |
    //+------------------------------------------------------------------+
    MNS_ProfileStart("Total_Rendering");

    int numSwings = g_swings.GetExternalSwingCount() + g_swings.GetInternalSwingCount();
    int numBreaks = g_breaks.GetBreakCount();
    Print(StringFormat("[DEBUG] [MNS_Indicator] Renderers: ExtSwingCount=%d, IntSwingCount=%d, BreakCount=%d", 
                       g_swings.GetExternalSwingCount(), g_swings.GetInternalSwingCount(), numBreaks));

    MNS_ProfileStart("Render_Swings");
    g_swingRenderer.Draw(g_swings, time, limitBars, currentAtr);
    MNS_ProfileStop("Render_Swings");

    MNS_ProfileStart("Render_Structure");
    g_structureRenderer.Draw(g_breaks, time, limitBars);
    MNS_ProfileStop("Render_Structure");

    MNS_ProfileStart("Render_Liquidity");
    g_liquidityRenderer.Draw(g_liquidity, time, limitBars);
    MNS_ProfileStop("Render_Liquidity");

    MNS_ProfileStart("Render_POI");
    g_poiRenderer.Draw(g_poi, time, limitBars);
    MNS_ProfileStop("Render_POI");

    MNS_ProfileStart("Render_Delivery");
    g_deliveryRenderer.Draw(g_delivery, g_objective, time, close, limitBars);
    MNS_ProfileStop("Render_Delivery");

    MNS_ProfileStart("Render_Zones");
    g_zoneRenderer.Draw(g_swings, time, rates_total);
    MNS_ProfileStop("Render_Zones");

    MNS_ProfileStart("Render_Sessions");
    g_sessionRenderer.Draw(time, limitBars);
    MNS_ProfileStop("Render_Sessions");

    MNS_ProfileStart("Render_Dashboard");
    // Check showDashboard flag before drawing
    if (cfg.showDashboard)
    {
        datetime gmtTime = time[0] - cfg.gmtOffset * 3600;
        g_dashboardRenderer.Draw(g_poi, g_delivery, g_objective, g_swings, g_structure, g_breaks, g_orderFlow, g_liquidity, g_confirmation, g_entry, g_risk, time, close, limitBars, gmtTime);
    }
    else
    {
        g_dashboardRenderer.Reset(); // Wipe panel objects if disabled
    }
    MNS_ProfileStop("Render_Dashboard");

    MNS_ProfileStop("Total_Rendering");

    //--- Force chart refresh to draw changes instantly
    ChartRedraw(0);

    //+------------------------------------------------------------------+
    //| Diagnostic heartbeat (debug mode only)                            |
    //+------------------------------------------------------------------+
    if (InpDebugLogging)
    {
        MNS_Log(MNS_LOG_DEBUG, MNS_INDICATOR_SOURCE,
            StringFormat("Bar %d | ATR=%.5f | MinBreak=%.5f | Swings=%d | Breaks=%d | POIs=%d",
                         rates_total,
                         currentAtr,
                         minBreakDist,
                         g_swings.GetExternalSwingCount() + g_swings.GetInternalSwingCount(),
                         g_breaks.GetBreakCount(),
                         g_poi.GetPoIsCount()));
    }

    //--- Periodic 1000-calculate telemetry report
    static int calculateCounter = 0;
    calculateCounter++;
    
    if (calculateCounter >= 1000)
    {
        #ifdef MNS_PROFILING_ENABLE
            if (InpDebugLogging)
            {
                MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "Periodic 1000-tick performance profile report:");
                CMNSProfiler::ReportTelemetry();
            }
            CMNSProfiler::Reset(); // Reset to clear accumulated telemetry for the next interval
        #endif
        calculateCounter = 0;
    }

    //--- Return rates_total to indicate all bars are processed.
    //    MT5 will not force a full recalculation on the next tick.
    return rates_total;
}

//+------------------------------------------------------------------+
//| OnChartEvent — Handles user interaction and drag-and-drop        |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    g_dashboardRenderer.HandleChartEvent(id, lparam, dparam, sparam);
}
