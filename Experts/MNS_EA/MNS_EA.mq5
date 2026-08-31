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

//--- Strategy Logic Settings (Exposed for Backtest Optimization)
input int    InpExternalDepth           = 15;       // External Swing Depth (10-100)
input int    InpInternalDepth           = 5;        // Internal Swing Depth (2-20)
input double InpAtrTolerance            = 0.0010;   // ATR Proximity Tolerance Zone
input double InpMinBreakDistance        = 0.0000;   // Min Break Distance (Points)
input double InpConfidenceThreshold     = 94.0;     // Signal Confidence Threshold % (50-100)
input double InpDisplacementMinAtrMult  = 1.20;     // Min Displacement ATR Multiple
input double InpDisplacementMinBodyRatio = 0.65;    // Min Displacement Candle Body Ratio (0.0-1.0)
input double InpDisplacementMinCloseStr = 0.75;     // Min Displacement Close Strength (0.0-1.0)
input int    InpAtrPeriod               = 14;       // ATR Volatility Period

//--- EA Operational Settings
input bool   InpAutoTrading      = false;    // Enable Automated Trade Execution
input int    InpMaxHistoryBars   = 1000;     // History Bars to Analyze
input ulong  InpMagicNumber      = 20260831; // EA Magic Number
input string InpTradeComment     = "MNS_EA"; // Order Comment Description
input double InpMaxDailyDrawdown  = 5.0;      // Max Daily Drawdown Limit (%)
input bool   InpTrailingStop      = true;     // Enable Trailing Stop Management
input bool   InpPartialClose      = true;     // Enable +1.0R Partial Close Sizing
input int    InpFridayCloseHour   = 21;       // Friday Close Hour (Server Time, -1 to disable)

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
//| Runtime-Mutable Control Mirrors (changed by HUD at runtime)      |
//+------------------------------------------------------------------+
bool   g_runtimeAutoTrading  = false;
bool   g_runtimePauseEntries = false;
bool   g_runtimeTrailingStop = true;
bool   g_runtimePartialClose = true;
double g_runtimeRiskPercent  = 1.0;
double g_runtimeMaxSpread    = 50.0;
double g_runtimeMaxDailyDD   = 5.0;
datetime g_lastHudInteractionTime = 0;

//+------------------------------------------------------------------+
//| HUD Constants                                                    |
//+------------------------------------------------------------------+
#define HUD_PREFIX       "MNS_EA_HUD_"
#define HUD_CORNER       CORNER_RIGHT_UPPER
#define HUD_X            250       // px from right edge
#define HUD_Y_START      20        // px from top
#define HUD_ROW_H        18        // px per row
#define HUD_WIDTH        220       // panel width px
#define HUD_FONT         "Consolas"
#define HUD_FONT_SIZE    8
#define HUD_COL_BG       C'18,18,24'
#define HUD_COL_BORDER   C'60,60,80'
#define HUD_COL_HEADER   C'120,120,200'
#define HUD_COL_LABEL    C'140,140,155'
#define HUD_COL_VALUE    clrWhite
#define HUD_COL_ON       C'30,110,30'
#define HUD_COL_OFF      C'110,30,30'
#define HUD_COL_ACTION   C'50,80,130'
#define HUD_COL_WARN     C'180,100,0'

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
//| Active Position Management Helpers                               |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| HUD Helper: Create a single label                                |
//+------------------------------------------------------------------+
void HUD_CreateLabel(const string name, const int xDist, const int yDist,
                     const string text, const color clr,
                     const int fontSize = HUD_FONT_SIZE, const uint anchor = ANCHOR_LEFT)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER,    HUD_CORNER);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xDist);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, yDist);
    ObjectSetString (0, name, OBJPROP_TEXT,      text);
    ObjectSetString (0, name, OBJPROP_FONT,      HUD_FONT);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  fontSize);
    ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
    ObjectSetInteger(0, name, OBJPROP_ANCHOR,    anchor);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_BACK,      false);
}

//+------------------------------------------------------------------+
//| HUD Helper: Create a button                                      |
//+------------------------------------------------------------------+
void HUD_CreateButton(const string name, const int xDist, const int yDist,
                      const int width, const int height,
                      const string text, const color bgColor)
{
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER,    HUD_CORNER);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xDist);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, yDist);
    ObjectSetInteger(0, name, OBJPROP_XSIZE,     width);
    ObjectSetInteger(0, name, OBJPROP_YSIZE,     height);
    ObjectSetString (0, name, OBJPROP_TEXT,      text);
    ObjectSetString (0, name, OBJPROP_FONT,      HUD_FONT);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  HUD_FONT_SIZE);
    ObjectSetInteger(0, name, OBJPROP_COLOR,     clrWhite);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR,   bgColor);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_BACK,      false);
}

//+------------------------------------------------------------------+
//| CreateHUD — Build all chart objects (called once in OnInit)      |
//+------------------------------------------------------------------+
void CreateHUD()
{
    int lx  = HUD_X;                   // x of left-aligned label
    int vx  = HUD_X - HUD_WIDTH + 5;  // x of right-side value label
    int y   = HUD_Y_START;

    // --- Background panel ---
    ObjectCreate(0, HUD_PREFIX + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_CORNER,    HUD_CORNER);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_XDISTANCE, HUD_X - HUD_WIDTH - 15);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_YDISTANCE, HUD_Y_START - 5);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_XSIZE,     HUD_WIDTH + 30);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_YSIZE,     590);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_BGCOLOR,   HUD_COL_BG);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_COLOR,     HUD_COL_BORDER); // Border color
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_BACK,      false);
    ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_SELECTABLE, false);

    // === ROW 0: Header title + Auto-Trade button ===
    HUD_CreateLabel(HUD_PREFIX + "HDR_Title", lx, y, "MNS EA v1.0", HUD_COL_HEADER, 9);
    HUD_CreateButton(HUD_PREFIX + "BTN_AutoTrade", 130, y - 1, 90, 16, "AUTO: OFF", HUD_COL_OFF);

    // === ROW 1: Session info ===
    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "HDR_Session", lx, y, _Symbol + "  " + EnumToString(Period()), HUD_COL_LABEL);

    // === Separator 1 ===
    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "SEP1", lx, y, "─────────────────────────────", HUD_COL_BORDER);

    // === ACCOUNT section ===
    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "ACCT_Hdr", lx, y, "ACCOUNT", HUD_COL_HEADER);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "ACCT_Equity_Lbl", lx, y, "Equity", HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "ACCT_Equity_Val", vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "ACCT_Balance_Lbl", lx, y, "Balance", HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "ACCT_Balance_Val", vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "ACCT_PnL_Lbl", lx, y, "Daily P&L", HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "ACCT_PnL_Val", vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "ACCT_DD_Lbl", lx, y, "Drawdown", HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "ACCT_DD_Val", vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    // === Separator 2 ===
    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "SEP2", lx, y, "─────────────────────────────", HUD_COL_BORDER);

    // === ACTIVE TRADE section ===
    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "TRADE_Hdr", lx, y, "ACTIVE TRADE", HUD_COL_HEADER);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "TRADE_Dir_Lbl",   lx, y, "Direction",  HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "TRADE_Dir_Val",   vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "TRADE_Entry_Lbl", lx, y, "Entry",      HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "TRADE_Entry_Val", vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "TRADE_SL_Lbl",    lx, y, "Stop Loss",  HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "TRADE_SL_Val",    vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "TRADE_TP_Lbl",    lx, y, "Take Profit", HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "TRADE_TP_Val",    vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "TRADE_Float_Lbl", lx, y, "Float P&L",  HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "TRADE_Float_Val", vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "TRADE_Part_Lbl",  lx, y, "Partial",    HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "TRADE_Part_Val",  vx - 5, y, "---", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    // Action buttons: CLOSE ALL and MOVE TO B/E on same row
    y += HUD_ROW_H;
    HUD_CreateButton(HUD_PREFIX + "BTN_CloseAll",       lx - 10, y, 95, 15, "CLOSE ALL",   HUD_COL_OFF);
    HUD_CreateButton(HUD_PREFIX + "BTN_MoveToBreakEven", 140, y, 100, 15, "MOVE TO B/E", HUD_COL_ACTION);

    // === Separator 3 ===
    y += HUD_ROW_H + 1;
    HUD_CreateLabel(HUD_PREFIX + "SEP3", lx, y, "─────────────────────────────", HUD_COL_BORDER);

    // === SIGNAL section ===
    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "SIG_Hdr", lx, y, "SIGNAL", HUD_COL_HEADER);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "SIG_Status_Lbl", lx, y, "Status",     HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "SIG_Status_Val", vx - 5, y, "NONE", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "SIG_Conf_Lbl", lx, y, "Confidence",  HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "SIG_Conf_Val", vx - 5, y, "---",      HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "SIG_Dir_Lbl", lx, y, "Direction",    HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "SIG_Dir_Val", vx - 5, y, "---",       HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "SIG_DOL_Lbl", lx, y, "DOL",          HUD_COL_LABEL);
    HUD_CreateLabel(HUD_PREFIX + "SIG_DOL_Val", vx - 5, y, "---",       HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_RIGHT);

    y += HUD_ROW_H;
    HUD_CreateButton(HUD_PREFIX + "BTN_ResetSignal", lx - 10, y, 130, 15, "RESET SIGNAL", HUD_COL_ACTION);

    // === Separator 4 ===
    y += HUD_ROW_H + 1;
    HUD_CreateLabel(HUD_PREFIX + "SEP4", lx, y, "─────────────────────────────", HUD_COL_BORDER);

    // === RISK SETTINGS section ===
    y += HUD_ROW_H;
    HUD_CreateLabel(HUD_PREFIX + "RISK_Hdr", lx, y, "RISK SETTINGS", HUD_COL_HEADER);

    // Risk % stepper row
    y += HUD_ROW_H;
    HUD_CreateLabel (HUD_PREFIX + "RISK_Risk_Lbl",   lx, y, "Risk %",     HUD_COL_LABEL);
    HUD_CreateButton(HUD_PREFIX + "STP_Risk_Dn",     140,  y, 18, 14, "v", HUD_COL_ACTION);
    HUD_CreateLabel (HUD_PREFIX + "STP_Risk_Val",    90, y, "1.00%", HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_TOP);
    HUD_CreateButton(HUD_PREFIX + "STP_Risk_Up",     58, y, 18, 14, "^", HUD_COL_ACTION);

    // Max Spread stepper row
    y += HUD_ROW_H;
    HUD_CreateLabel (HUD_PREFIX + "RISK_Spread_Lbl", lx, y, "Max Spread", HUD_COL_LABEL);
    HUD_CreateButton(HUD_PREFIX + "STP_Spread_Dn",  140,  y, 18, 14, "v", HUD_COL_ACTION);
    HUD_CreateLabel (HUD_PREFIX + "STP_Spread_Val",  90, y, "50pt",  HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_TOP);
    HUD_CreateButton(HUD_PREFIX + "STP_Spread_Up",   58, y, 18, 14, "^", HUD_COL_ACTION);

    // Max DD% stepper row
    y += HUD_ROW_H;
    HUD_CreateLabel (HUD_PREFIX + "RISK_DD_Lbl",     lx, y, "Max DD%",    HUD_COL_LABEL);
    HUD_CreateButton(HUD_PREFIX + "STP_DD_Dn",       140,  y, 18, 14, "v", HUD_COL_ACTION);
    HUD_CreateLabel (HUD_PREFIX + "STP_DD_Val",      90, y, "5.0%",  HUD_COL_VALUE, HUD_FONT_SIZE, ANCHOR_TOP);
    HUD_CreateButton(HUD_PREFIX + "STP_DD_Up",       58, y, 18, 14, "^", HUD_COL_ACTION);

    // Trail Stop toggle row
    y += HUD_ROW_H;
    HUD_CreateLabel (HUD_PREFIX + "RISK_Trail_Lbl",   lx, y, "Trail Stop", HUD_COL_LABEL);
    HUD_CreateButton(HUD_PREFIX + "BTN_TrailStop",    90,  y, 50, 14, "ON", HUD_COL_ON);

    // Partial Close toggle row
    y += HUD_ROW_H;
    HUD_CreateLabel (HUD_PREFIX + "RISK_Part_Lbl",    lx, y, "Part. Close", HUD_COL_LABEL);
    HUD_CreateButton(HUD_PREFIX + "BTN_PartialClose", 90,  y, 50, 14, "ON", HUD_COL_ON);

    // Pause Entries toggle row
    y += HUD_ROW_H;
    HUD_CreateLabel (HUD_PREFIX + "RISK_Pause_Lbl",   lx, y, "Pause Entry", HUD_COL_LABEL);
    HUD_CreateButton(HUD_PREFIX + "BTN_Pause",        100,  y, 60, 14, "PAUSE", HUD_COL_ACTION);

    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| UpdateHUD bypass flag (set by DrawHUD to force immediate update) |
//+------------------------------------------------------------------+
bool g_hudForceUpdate = false;

//+------------------------------------------------------------------+
//| UpdateHUD — Refresh all display values (throttled: once/second)  |
//+------------------------------------------------------------------+
void UpdateHUD()
{
    static datetime lastUpdate = 0;
    if (!g_hudForceUpdate && TimeCurrent() - lastUpdate < 1) return;
    g_hudForceUpdate = false;
    lastUpdate = TimeCurrent();

    // === DYNAMIC BG PANEL FOCUS / UNFOCUS ===
    if (TimeLocal() - g_lastHudInteractionTime > 10)
    {
        // Unfocused state (Muted background, no borders)
        ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_BGCOLOR, C'8,8,10');
        ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_COLOR,   clrNONE);
    }
    else
    {
        // Focused state (Solid background, highlighted borders)
        ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_BGCOLOR, HUD_COL_BG);
        ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_COLOR,   HUD_COL_BORDER);
    }

    // === HEADER ===
    string autoStr = g_runtimeAutoTrading ? "ON " : "OFF";
    ObjectSetInteger(0, HUD_PREFIX + "BTN_AutoTrade", OBJPROP_BGCOLOR, g_runtimeAutoTrading ? HUD_COL_ON : HUD_COL_OFF);
    ObjectSetString (0, HUD_PREFIX + "BTN_AutoTrade", OBJPROP_TEXT,    "AUTO: " + autoStr);

    // Session label
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string sessionStr = "OFF-HOURS";
    if      (dt.hour >= 2  && dt.hour < 10) sessionStr = "ASIA";
    if      (dt.hour >= 8  && dt.hour < 17) sessionStr = "LONDON";
    if      (dt.hour >= 13 && dt.hour < 22) sessionStr = "NEW YORK";
    ObjectSetString(0, HUD_PREFIX + "HDR_Session", OBJPROP_TEXT,
                    _Symbol + "  " + EnumToString(Period()) + "  " + sessionStr);

    // === ACCOUNT ===
    double equity   = AccountInfoDouble(ACCOUNT_EQUITY);
    double balance  = AccountInfoDouble(ACCOUNT_BALANCE);
    double ddPct    = GetDailyDrawdownPercent();
    double dailyPnL = equity - balance;

    ObjectSetString(0, HUD_PREFIX + "ACCT_Equity_Val",  OBJPROP_TEXT, StringFormat("$%.2f", equity));
    ObjectSetString(0, HUD_PREFIX + "ACCT_Balance_Val", OBJPROP_TEXT, StringFormat("$%.2f", balance));
    ObjectSetString(0, HUD_PREFIX + "ACCT_PnL_Val",     OBJPROP_TEXT, StringFormat("%+.2f", dailyPnL));
    ObjectSetInteger(0, HUD_PREFIX + "ACCT_PnL_Val",    OBJPROP_COLOR, (dailyPnL >= 0) ? clrLime : clrTomato);

    color ddColor = (ddPct >= g_runtimeMaxDailyDD * 0.8) ? HUD_COL_WARN : HUD_COL_VALUE;
    ObjectSetString (0, HUD_PREFIX + "ACCT_DD_Val",     OBJPROP_TEXT,
                     StringFormat("%.1f%% / %.1f%%", ddPct, g_runtimeMaxDailyDD));
    ObjectSetInteger(0, HUD_PREFIX + "ACCT_DD_Val",     OBJPROP_COLOR, ddColor);

    // === ACTIVE TRADE ===
    SActivePositionInfo posInfo;
    bool hasPos = GetActivePosition(posInfo);

    if (hasPos)
    {
        string dirStr   = (posInfo.type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
        double floatPnL = PositionGetDouble(POSITION_PROFIT);
        string gvVolName = StringFormat("MNS_EA_VOL_%s_%I64u", _Symbol, InpMagicNumber);
        double origVol   = GlobalVariableCheck(gvVolName) ? GlobalVariableGet(gvVolName) : posInfo.volume;
        bool partialDone = (posInfo.volume < origVol - 0.005);

        ObjectSetString(0, HUD_PREFIX + "TRADE_Dir_Val",   OBJPROP_TEXT, dirStr);
        ObjectSetString(0, HUD_PREFIX + "TRADE_Entry_Val", OBJPROP_TEXT, StringFormat("%.*f", _Digits, posInfo.entryPrice));
        ObjectSetString(0, HUD_PREFIX + "TRADE_SL_Val",    OBJPROP_TEXT, StringFormat("%.*f", _Digits, posInfo.stopLoss));
        ObjectSetString(0, HUD_PREFIX + "TRADE_TP_Val",    OBJPROP_TEXT, StringFormat("%.*f", _Digits, posInfo.takeProfit));
        ObjectSetString(0, HUD_PREFIX + "TRADE_Float_Val", OBJPROP_TEXT, StringFormat("%+.2f", floatPnL));
        ObjectSetString(0, HUD_PREFIX + "TRADE_Part_Val",  OBJPROP_TEXT, partialDone ? "Done v" : "Pending");
        ObjectSetInteger(0, HUD_PREFIX + "TRADE_Float_Val",OBJPROP_COLOR, (floatPnL >= 0) ? clrLime : clrTomato);
        ObjectSetInteger(0, HUD_PREFIX + "TRADE_Dir_Val",  OBJPROP_COLOR,
                         (posInfo.type == POSITION_TYPE_BUY) ? clrLime : clrTomato);
    }
    else
    {
        string noPos = "---";
        ObjectSetString(0, HUD_PREFIX + "TRADE_Dir_Val",   OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_Entry_Val", OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_SL_Val",    OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_TP_Val",    OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_Float_Val", OBJPROP_TEXT, noPos);
        ObjectSetString(0, HUD_PREFIX + "TRADE_Part_Val",  OBJPROP_TEXT, noPos);
        ObjectSetInteger(0, HUD_PREFIX + "TRADE_Dir_Val",  OBJPROP_COLOR, HUD_COL_VALUE);
        ObjectSetInteger(0, HUD_PREFIX + "TRADE_Float_Val",OBJPROP_COLOR, HUD_COL_VALUE);
    }

    // === SIGNAL ===
    EEntryState sigState = g_entryEngine.GetActiveSignalState();
    string sigStr = "NONE";
    switch (sigState)
    {
        case ENTRY_STATE_ACTIVE:      sigStr = "CONFIRMED"; break;
        case ENTRY_STATE_EXECUTED:    sigStr = "EXECUTED";  break;
        case ENTRY_STATE_EXPIRED:     sigStr = "EXPIRED";   break;
        case ENTRY_STATE_CANCELLED:   sigStr = "CANCELLED"; break;
        case ENTRY_STATE_INVALIDATED: sigStr = "INVALID";   break;
        default:                      sigStr = "NONE";      break;
    }
    ObjectSetString(0, HUD_PREFIX + "SIG_Status_Val", OBJPROP_TEXT, sigStr);

    if (sigState == ENTRY_STATE_NONE)
    {
        ObjectSetString(0, HUD_PREFIX + "SIG_Conf_Val", OBJPROP_TEXT, "---");
        ObjectSetString(0, HUD_PREFIX + "SIG_Dir_Val",  OBJPROP_TEXT, "NONE");
        ObjectSetString(0, HUD_PREFIX + "SIG_DOL_Val",  OBJPROP_TEXT, "---");
    }
    else
    {
        ObjectSetString(0, HUD_PREFIX + "SIG_Conf_Val",   OBJPROP_TEXT,
                        StringFormat("%.0f", g_confirmationEngine.GetConfidenceScore()));

        EConfirmationDirection confDir = g_confirmationEngine.GetDirection();
        string confDirStr = (confDir == CONFIRM_DIR_BULLISH) ? "BUY"
                          : (confDir == CONFIRM_DIR_BEARISH) ? "SELL" : "NONE";
        ObjectSetString(0, HUD_PREFIX + "SIG_Dir_Val", OBJPROP_TEXT, confDirStr);
        ObjectSetString(0, HUD_PREFIX + "SIG_DOL_Val", OBJPROP_TEXT,
                        StringFormat("%.*f", _Digits, g_objectiveEngine.GetDolPrice()));
    }

    // === RISK SETTINGS ===
    ObjectSetString(0, HUD_PREFIX + "STP_Risk_Val",   OBJPROP_TEXT, StringFormat("%.2f%%", g_runtimeRiskPercent));
    ObjectSetString(0, HUD_PREFIX + "STP_Spread_Val", OBJPROP_TEXT, StringFormat("%.0fpt", g_runtimeMaxSpread));
    ObjectSetString(0, HUD_PREFIX + "STP_DD_Val",     OBJPROP_TEXT, StringFormat("%.1f%%", g_runtimeMaxDailyDD));

    ObjectSetInteger(0, HUD_PREFIX + "BTN_TrailStop",    OBJPROP_BGCOLOR, g_runtimeTrailingStop ? HUD_COL_ON : HUD_COL_OFF);
    ObjectSetString (0, HUD_PREFIX + "BTN_TrailStop",    OBJPROP_TEXT,    g_runtimeTrailingStop ? "ON" : "OFF");
    ObjectSetInteger(0, HUD_PREFIX + "BTN_PartialClose", OBJPROP_BGCOLOR, g_runtimePartialClose ? HUD_COL_ON : HUD_COL_OFF);
    ObjectSetString (0, HUD_PREFIX + "BTN_PartialClose", OBJPROP_TEXT,    g_runtimePartialClose ? "ON" : "OFF");
    ObjectSetInteger(0, HUD_PREFIX + "BTN_Pause",        OBJPROP_BGCOLOR, g_runtimePauseEntries ? HUD_COL_WARN : HUD_COL_ACTION);
    ObjectSetString (0, HUD_PREFIX + "BTN_Pause",        OBJPROP_TEXT,    g_runtimePauseEntries ? "PAUSED" : "PAUSE");

    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| DrawHUD — Force immediate redraw (bypasses 1-second throttle)    |
//+------------------------------------------------------------------+
void DrawHUD()
{
    g_hudForceUpdate = true;
    UpdateHUD();
}

//+------------------------------------------------------------------+
//| DestroyHUD — Remove all chart objects with HUD prefix            |
//+------------------------------------------------------------------+
void DestroyHUD()
{
    ObjectsDeleteAll(0, HUD_PREFIX);
    ChartRedraw(0);
}

bool PositionClosePartial(const ulong ticket, const double volume)
{
    if (!PositionSelectByTicket(ticket))
        return false;

    string symbol = PositionGetString(POSITION_SYMBOL);
    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double price = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);

    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);

    uint filling = (uint)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
    ENUM_ORDER_TYPE_FILLING type_filling = ORDER_FILLING_FOK;
    if ((filling & SYMBOL_FILLING_FOK) != 0) type_filling = ORDER_FILLING_FOK;
    else if ((filling & SYMBOL_FILLING_IOC) != 0) type_filling = ORDER_FILLING_IOC;
    else type_filling = ORDER_FILLING_RETURN;

    request.action       = TRADE_ACTION_DEAL;
    request.symbol       = symbol;
    request.volume       = volume;
    request.price        = price;
    request.position     = ticket;
    request.type         = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.type_filling = type_filling;
    request.deviation    = 30;
    request.magic        = InpMagicNumber;

    ResetLastError();
    bool res = OrderSend(request, result);
    
    if (!res || (result.retcode != TRADE_RETCODE_DONE && result.retcode != TRADE_RETCODE_PLACED))
    {
        MNS_Log(MNS_LOG_ERROR, "MNS_EA", StringFormat("[TRADE ERROR] Partial close failed. Retcode: %u | Error: %d", result.retcode, GetLastError()));
        return false;
    }
    
    return true;
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
    CMNSConfig::UpdateParameter("externalDepth", (double)InpExternalDepth);
    CMNSConfig::UpdateParameter("internalDepth", (double)InpInternalDepth);
    CMNSConfig::UpdateParameter("atrTolerance", InpAtrTolerance);
    CMNSConfig::UpdateParameter("minBreakDistance", InpMinBreakDistance);
    CMNSConfig::UpdateParameter("confidenceThreshold", InpConfidenceThreshold);
    CMNSConfig::UpdateParameter("displacementMinAtrMultiple", InpDisplacementMinAtrMult);
    CMNSConfig::UpdateParameter("displacementMinBodyRatio", InpDisplacementMinBodyRatio);
    CMNSConfig::UpdateParameter("displacementMinCloseStrength", InpDisplacementMinCloseStr);
    CMNSConfig::UpdateParameter("atrPeriod", (double)InpAtrPeriod);

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

    if (!g_riskEngine.Initialize(cfg.desiredRiskPercent, 0.25, 2.0, InpMaxDailyDrawdown))
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

    //--- 8. Initialize runtime control mirrors from input values
    g_runtimeAutoTrading  = InpAutoTrading;
    g_runtimeTrailingStop = InpTrailingStop;
    g_runtimePartialClose = InpPartialClose;
    g_runtimeRiskPercent  = InpDefaultRisk;
    g_runtimeMaxSpread    = InpMaxSpreadPoints;
    g_runtimeMaxDailyDD   = InpMaxDailyDrawdown;
    g_lastHudInteractionTime = TimeLocal();

    //--- 9. Build on-chart HUD
    CreateHUD();
    UpdateHUD();

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

    //--- 2. Destroy on-chart HUD objects
    DestroyHUD();

    //--- 3. Reset engine states in reverse DAG dependency order
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

    //--- 4. Log shutdown summary and close logger
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

    //--- Active Position Management & Trailing Stops
    SActivePositionInfo posInfo;
    string gvSlName = StringFormat("MNS_EA_SL_%s_%I64u", _Symbol, InpMagicNumber);
    string gvVolName = StringFormat("MNS_EA_VOL_%s_%I64u", _Symbol, InpMagicNumber);

    if (GetActivePosition(posInfo))
    {
        if (!GlobalVariableCheck(gvSlName))
        {
            GlobalVariableSet(gvSlName, posInfo.stopLoss);
        }
        if (!GlobalVariableCheck(gvVolName))
        {
            GlobalVariableSet(gvVolName, posInfo.volume);
        }

        double originalSL = GlobalVariableGet(gvSlName);
        double originalVolume = GlobalVariableGet(gvVolName);
        bool alreadyPartiallyClosed = (posInfo.volume < originalVolume - 0.005);

        EConfirmationDirection dir = (posInfo.type == POSITION_TYPE_BUY) ? CONFIRM_DIR_BULLISH : CONFIRM_DIR_BEARISH;
        double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        bool isDolReached = (posInfo.takeProfit > 0.0) && 
                            ((dir == CONFIRM_DIR_BULLISH && currentBid >= posInfo.takeProfit) || 
                             (dir == CONFIRM_DIR_BEARISH && currentAsk <= posInfo.takeProfit));
                             
        bool isDolInvalidated = (!g_objectiveEngine.GetActiveDol().active) || 
                               (dir == CONFIRM_DIR_BULLISH && g_objectiveEngine.GetDolPrice() < posInfo.entryPrice) || 
                               (dir == CONFIRM_DIR_BEARISH && g_objectiveEngine.GetDolPrice() > posInfo.entryPrice);
                               
        bool mtfReversal = (dir == CONFIRM_DIR_BULLISH && g_confirmationEngine.GetDirection() == CONFIRM_DIR_BEARISH) || 
                           (dir == CONFIRM_DIR_BEARISH && g_confirmationEngine.GetDirection() == CONFIRM_DIR_BULLISH);
                           
        double currentDailyDrawdown = GetDailyDrawdownPercent();

        SRiskManagementAction action = g_riskEngine.UpdateActiveManagement(
            dir,
            posInfo.entryPrice,
            posInfo.volume,
            originalSL,
            posInfo.stopLoss,
            currentBid,
            currentAsk,
            atr14,
            g_deliveryEngine.GetLifecycle(),
            isDolReached,
            isDolInvalidated,
            mtfReversal,
            currentDailyDrawdown,
            _Symbol
        );

        bool positionClosed = false;

        if (action.closeFully)
        {
            MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[ACTIVE MANAGEMENT] Emergency close triggered for ticket %I64u.", posInfo.ticket));
            if (g_trade.PositionClose(posInfo.ticket))
            {
                GlobalVariableDel(gvSlName);
                GlobalVariableDel(gvVolName);
                g_riskEngine.ResetPositionTracking();
                positionClosed = true;
            }
        }
        else 
        {
            if (action.closePartially && action.partialVolume > 0.0)
            {
                if (g_runtimePartialClose && !alreadyPartiallyClosed)
                {
                    MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[ACTIVE MANAGEMENT] Executing partial close of %.2f lots for ticket %I64u.", action.partialVolume, posInfo.ticket));
                    if (PositionClosePartial(posInfo.ticket, action.partialVolume))
                    {
                        GlobalVariableSet(gvVolName, posInfo.volume - action.partialVolume);
                    }
                }
            }

            if (action.newStopLoss != MNS_INVALID_PRICE && action.newStopLoss != posInfo.stopLoss)
            {
                if (g_runtimeTrailingStop)
                {
                    double newSL = NormalizeDouble(action.newStopLoss, _Digits);
                    double stopLevelPoints = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
                    double minStopDistance = stopLevelPoints * pointSize;
                    bool isModifyValid = true;
                    
                    if (dir == CONFIRM_DIR_BULLISH)
                    {
                        if (currentBid - newSL < minStopDistance)
                        {
                            isModifyValid = false;
                            MNS_Log(MNS_LOG_WARN, "MNS_EA", StringFormat("[ACTIVE MANAGEMENT] Trailing SL modify rejected: new SL (%.5f) violates stop level limits relative to Bid (%.5f).", newSL, currentBid));
                        }
                    }
                    else 
                    {
                        if (newSL - currentAsk < minStopDistance)
                        {
                            isModifyValid = false;
                            MNS_Log(MNS_LOG_WARN, "MNS_EA", StringFormat("[ACTIVE MANAGEMENT] Trailing SL modify rejected: new SL (%.5f) violates stop level limits relative to Ask (%.5f).", newSL, currentAsk));
                        }
                    }
                    
                    if (isModifyValid)
                    {
                        MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[ACTIVE MANAGEMENT] Modifying SL to %.*f for ticket %I64u.", _Digits, newSL, posInfo.ticket));
                        if (g_trade.PositionModify(posInfo.ticket, newSL, posInfo.takeProfit))
                        {
                            GlobalVariableSet(gvSlName, newSL);
                        }
                    }
                }
            }
        }

        if (!positionClosed)
        {
            MqlDateTime dt;
            TimeToStruct(TimeCurrent(), dt);
            if (dt.day_of_week == 5 && InpFridayCloseHour >= 0 && dt.hour >= InpFridayCloseHour)
            {
                MNS_Log(MNS_LOG_INFO, "MNS_EA", "[FRIDAY CLOSE] Enforcing weekend risk limit. Flattening position.");
                if (g_trade.PositionClose(posInfo.ticket))
                {
                    GlobalVariableDel(gvSlName);
                    GlobalVariableDel(gvVolName);
                    g_riskEngine.ResetPositionTracking();
                }
            }
        }
    }
    else
    {
        if (GlobalVariableCheck(gvSlName))
        {
            GlobalVariableDel(gvSlName);
        }
        if (GlobalVariableCheck(gvVolName))
        {
            GlobalVariableDel(gvVolName);
        }
        g_riskEngine.ResetPositionTracking();
    }

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
    //        Pause Entries: skip entry block entirely when pause is active
    if (!g_runtimePauseEntries && g_entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE)
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
        else if (currentSpread > g_runtimeMaxSpread)
        {
            if (activeSig.id != s_lastProcessedSignalId)
            {
                s_lastProcessedSignalId = activeSig.id;
                MNS_Log(MNS_LOG_WARN, "MNS_EA",
                    StringFormat("[SPREAD LIMIT EXCEEDED] Current spread (%.1f pts) exceeds maximum limit (%.1f pts). Trade skipped.",
                                 currentSpread, g_runtimeMaxSpread));
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
                                                                     g_runtimeRiskPercent,
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

                // Check Automated Trading toggle runtime mirror
                if (!g_runtimeAutoTrading)
                {
                    MNS_Log(MNS_LOG_INFO, "MNS_EA", "[AUTO-TRADING DISABLED] Signal detected and logged. g_runtimeAutoTrading is false — market execution skipped.");
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

    //--- 7. Update on-chart HUD (throttled to once/second inside UpdateHUD)
    UpdateHUD();
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
                             stateStr, g_runtimeAutoTrading ? "ENABLED" : "DISABLED"));
    }
}

//+------------------------------------------------------------------+
//| Chart Event Handler (OnChartEvent)                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if (id != CHARTEVENT_OBJECT_CLICK) return;

    // Reset HUD user inactivity timer
    g_lastHudInteractionTime = TimeLocal();

    // === Auto-Trade Toggle ===
    if (sparam == HUD_PREFIX + "BTN_AutoTrade")
    {
        g_runtimeAutoTrading = !g_runtimeAutoTrading;
        MNS_Log(MNS_LOG_INFO, "MNS_EA",
                StringFormat("[HUD] Auto-Trading set to: %s", g_runtimeAutoTrading ? "ON" : "OFF"));
    }
    // === Pause Entries Toggle ===
    else if (sparam == HUD_PREFIX + "BTN_Pause")
    {
        g_runtimePauseEntries = !g_runtimePauseEntries;
        MNS_Log(MNS_LOG_INFO, "MNS_EA",
                StringFormat("[HUD] Pause Entries set to: %s", g_runtimePauseEntries ? "ON" : "OFF"));
    }
    // === Close All Positions ===
    else if (sparam == HUD_PREFIX + "BTN_CloseAll")
    {
        string gvSlName  = StringFormat("MNS_EA_SL_%s_%I64u",  _Symbol, InpMagicNumber);
        string gvVolName = StringFormat("MNS_EA_VOL_%s_%I64u", _Symbol, InpMagicNumber);
        int total = PositionsTotal();
        for (int i = total - 1; i >= 0; i--)
        {
            string posSymbol = PositionGetSymbol(i);
            if (posSymbol == _Symbol)
            {
                if (PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
                {
                    ulong ticket = PositionGetInteger(POSITION_TICKET);
                    if (g_trade.PositionClose(ticket))
                    {
                        MNS_Log(MNS_LOG_INFO, "MNS_EA",
                                StringFormat("[HUD] CloseAll: closed ticket %I64u.", ticket));
                    }
                }
            }
        }
        GlobalVariableDel(gvSlName);
        GlobalVariableDel(gvVolName);
        g_riskEngine.ResetPositionTracking();
        MNS_Log(MNS_LOG_INFO, "MNS_EA", "[HUD] CloseAll completed. GVs cleared, risk tracking reset.");
    }
    // === Move to Break Even ===
    else if (sparam == HUD_PREFIX + "BTN_MoveToBreakEven")
    {
        SActivePositionInfo posInfo;
        if (GetActivePosition(posInfo))
        {
            double pointSize   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            if (pointSize <= 0.0) pointSize = _Point;
            double stopLevel   = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * pointSize;
            double currentBid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double currentAsk  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            bool   isModValid  = true;

            if (posInfo.type == POSITION_TYPE_BUY)
            {
                if (currentBid - posInfo.entryPrice < stopLevel) isModValid = false;
            }
            else
            {
                if (posInfo.entryPrice - currentAsk < stopLevel) isModValid = false;
            }

            if (isModValid)
            {
                double beSL = NormalizeDouble(posInfo.entryPrice, _Digits);
                if (g_trade.PositionModify(posInfo.ticket, beSL, posInfo.takeProfit))
                {
                    string gvSlName = StringFormat("MNS_EA_SL_%s_%I64u", _Symbol, InpMagicNumber);
                    GlobalVariableSet(gvSlName, beSL);
                    MNS_Log(MNS_LOG_INFO, "MNS_EA",
                            StringFormat("[HUD] MoveToBreakEven: SL moved to entry %.*f for ticket %I64u.",
                                         _Digits, beSL, posInfo.ticket));
                }
            }
            else
            {
                MNS_Log(MNS_LOG_WARN, "MNS_EA",
                        "[HUD] MoveToBreakEven rejected: entry price violates broker stop level distance.");
            }
        }
        else
        {
            MNS_Log(MNS_LOG_WARN, "MNS_EA", "[HUD] MoveToBreakEven: no active position found.");
        }
    }
    // === Reset Signal ===
    else if (sparam == HUD_PREFIX + "BTN_ResetSignal")
    {
        g_entryEngine.MarkSignalConsumed();
        MNS_Log(MNS_LOG_INFO, "MNS_EA", "[HUD] ResetSignal: active signal marked as consumed.");
    }
    // === Toggle: Trailing Stop ===
    else if (sparam == HUD_PREFIX + "BTN_TrailStop")
    {
        g_runtimeTrailingStop = !g_runtimeTrailingStop;
        MNS_Log(MNS_LOG_INFO, "MNS_EA",
                StringFormat("[HUD] Trailing Stop set to: %s", g_runtimeTrailingStop ? "ON" : "OFF"));
    }
    // === Toggle: Partial Close ===
    else if (sparam == HUD_PREFIX + "BTN_PartialClose")
    {
        g_runtimePartialClose = !g_runtimePartialClose;
        MNS_Log(MNS_LOG_INFO, "MNS_EA",
                StringFormat("[HUD] Partial Close set to: %s", g_runtimePartialClose ? "ON" : "OFF"));
    }
    // === Stepper: Risk % Up ===
    else if (sparam == HUD_PREFIX + "STP_Risk_Up")
    {
        g_runtimeRiskPercent = NormalizeDouble(MathMin(g_runtimeRiskPercent + 0.25, 2.0), 2);
        MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[HUD] Risk%% set to: %.2f%%", g_runtimeRiskPercent));
    }
    // === Stepper: Risk % Down ===
    else if (sparam == HUD_PREFIX + "STP_Risk_Dn")
    {
        g_runtimeRiskPercent = NormalizeDouble(MathMax(g_runtimeRiskPercent - 0.25, 0.25), 2);
        MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[HUD] Risk%% set to: %.2f%%", g_runtimeRiskPercent));
    }
    // === Stepper: Max Spread Up ===
    else if (sparam == HUD_PREFIX + "STP_Spread_Up")
    {
        g_runtimeMaxSpread = MathMin(g_runtimeMaxSpread + 5.0, 200.0);
        MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[HUD] Max Spread set to: %.0fpt", g_runtimeMaxSpread));
    }
    // === Stepper: Max Spread Down ===
    else if (sparam == HUD_PREFIX + "STP_Spread_Dn")
    {
        g_runtimeMaxSpread = MathMax(g_runtimeMaxSpread - 5.0, 5.0);
        MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[HUD] Max Spread set to: %.0fpt", g_runtimeMaxSpread));
    }
    // === Stepper: Max DD% Up ===
    else if (sparam == HUD_PREFIX + "STP_DD_Up")
    {
        g_runtimeMaxDailyDD = NormalizeDouble(MathMin(g_runtimeMaxDailyDD + 0.5, 10.0), 1);
        MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[HUD] Max Daily DD set to: %.1f%%", g_runtimeMaxDailyDD));
    }
    // === Stepper: Max DD% Down ===
    else if (sparam == HUD_PREFIX + "STP_DD_Dn")
    {
        g_runtimeMaxDailyDD = NormalizeDouble(MathMax(g_runtimeMaxDailyDD - 0.5, 1.0), 1);
        MNS_Log(MNS_LOG_INFO, "MNS_EA", StringFormat("[HUD] Max Daily DD set to: %.1f%%", g_runtimeMaxDailyDD));
    }

    // Always depress button and force immediate HUD redraw after any click
    ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
    DrawHUD();
}
