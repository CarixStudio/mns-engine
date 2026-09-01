//+------------------------------------------------------------------+
//|                                     MNS_StateTransitionTests.mq5 |
//|                              MNS Trading Engine — Test Harness   |
//|                                                                  |
//| Purpose:                                                         |
//|   Validates MNS trade execution lifecycles, risk sizing math,    |
//|   trailing stops, partial closes, duplicate signal blocking,     |
//|   and emergency exits under Buy and Sell scenarios.              |
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading execution or visual drawing.                    |
//|   - Runs fully inside OnInit() and self-removes (returns failed).|
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Development                                             |
//+------------------------------------------------------------------+
#property copyright "MNS Trading Engine"
#property version "1.00"
#property strict

#include "..\\..\\Include\\MNS\\MNSCore.mqh"
#define MNS_LOG_ENABLE
#include "..\\..\\Include\\MNS\\MNSLogger.mqh"
#include "..\\..\\Include\\MNS\\MNSTypes.mqh"
#include "..\\..\\Include\\MNS\\CSwingDetector.mqh"
#include "..\\..\\Include\\MNS\\CStructureEngine.mqh"
#include "..\\..\\Include\\MNS\\CBreakDetector.mqh"
#include "..\\..\\Include\\MNS\\COrderFlowEngine.mqh"
#include "..\\..\\Include\\MNS\\CDeliveryStructureEngine.mqh"
#include "..\\..\\Include\\MNS\\CLiquidityEngine.mqh"
#include "..\\..\\Include\\MNS\\CPOIEngine.mqh"
#include "..\\..\\Include\\MNS\\CObjectiveEngine.mqh"
#include "..\\..\\Include\\MNS\\CConfirmationEngine.mqh"
#include "..\\..\\Include\\MNS\\CEntryEngine.mqh"
#include "..\\..\\Include\\MNS\\CRiskEngine.mqh"
#include "..\\..\\Include\\MNS\\MNSUtils.mqh"
#include "..\\..\\Include\\MNS\\MNSVolatility.mqh"
#include "..\\..\\Include\\MNS\\MNSConfig.mqh"
#include "..\\..\\Include\\MNS\\MNSTestSuite.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize logger to debug
    CMNSLogger::Initialize(MNS_LOG_DEBUG, "MNS_StateTransitionTests.log");
    Print("==============================================");
    Print("  STARTING MNS STATE TRANSITION TEST SUITE");
    Print("==============================================");

    CMNSTestSuite::Reset();

    //---------------------------------------------------------
    // Set up mock arrays and time ranges
    //---------------------------------------------------------
    #define TEST_BARS 100
    double   testHigh[TEST_BARS];
    double   testLow[TEST_BARS];
    double   testOpen[TEST_BARS];
    double   testClose[TEST_BARS];
    datetime testTime[TEST_BARS];

    MqlDateTime dt;
    dt.year = 2026;
    dt.mon = 8;
    dt.day = 15;
    dt.hour = 12;
    dt.min = 0;
    dt.sec = 0;
    datetime baseTime = StructToTime(dt);

    for (int i = 0; i < TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
        testTime[i]  = baseTime;
        baseTime -= 3600; // 1 hour step back
    }

    //------------------------------------------------------------------
    // TEST 1: Bullish Signal Generation, Sizing, Execution, and Duplicates
    //------------------------------------------------------------------
    Print("--- Test 1: Bullish Execution Lifecycle ---");
    
    CEntryEngine entryEngine;
    entryEngine.Initialize(50.0); // max 50 points spread

    CRiskEngine riskEngine;
    riskEngine.Initialize(1.0, 0.25, 2.0, 5.0); // 1.0% default, min 0.25%, max 2.0%, max daily DD 5%

    CSwingDetector swingDet;
    swingDet.Initialize(15, 5);
    CStructureEngine structEng;
    structEng.Initialize(0.0002);
    CBreakDetector breakDet;
    breakDet.Initialize();
    COrderFlowEngine ofEngine;
    ofEngine.Initialize();
    CDeliveryStructureEngine delEngine;
    delEngine.Initialize();
    CLiquidityEngine liqEngine;
    liqEngine.Initialize(0);
    CPOIEngine poiEngine;
    poiEngine.Initialize();
    CObjectiveEngine objEngine;
    objEngine.Initialize();
    CConfirmationEngine confEngine;
    confEngine.Initialize();

    // 1. Setup a Bullish Objective (DOL) at 1.2200
    objEngine.OverrideDol(true, 1.2200, DOL_EXTERNAL_SWING, 100.0);
    structEng.OverrideTrend(TREND_BULLISH);

    // 2. Setup Bullish confirmation: trigger price at 1.2000, invalidation at 1.1900
    confEngine.OverrideState(CONFIRMATION_STATE_CONFIRMED, CONFIRM_DIR_BULLISH, 1.2000, 1.1900, TimeCurrent());
    CMNSTestSuite::AssertEqualInt(CONFIRMATION_STATE_CONFIRMED, confEngine.GetConfirmationState(), "Bullish confirmation achieved");

    // 3. Entry Engine generates active signal
    bool signalGenerated = entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, TEST_BARS, 0, 10.0);
    CMNSTestSuite::AssertTrue(signalGenerated, "CEntryEngine generates active signal");
    CMNSTestSuite::AssertEqualInt(ENTRY_STATE_ACTIVE, entryEngine.GetActiveSignalState(), "Signal state is ENTRY_STATE_ACTIVE");

    SEntrySignal activeSig = entryEngine.GetActiveSignal();
    CMNSTestSuite::AssertEqualDouble(1.2000, activeSig.entryPrice, "Bullish Entry Price is 1.2000");
    CMNSTestSuite::AssertEqualDouble(1.1900, activeSig.stopLoss, "Bullish Invalidation level is 1.1900");
    CMNSTestSuite::AssertEqualDouble(1.2200, activeSig.takeProfit, "Bullish DOL take profit is 1.2200");

    // 4. Pre-Trade Risk Sizing (Risk = 1.0%, Equity = 10000.0)
    // Invalidation = 1.1900. Stop Buffer = max(2*pt, 0.20*0.0050) = 0.0010. Expected SL = 1.1900 - 0.0010 = 1.1890.
    // Reward distance = 1.2200 - 1.2000 = 0.0200. Risk distance = 1.2000 - 1.1890 = 0.0110. RR = 1.818 >= 1.50R.
    SRiskSizingResult riskRes = riskEngine.SizePreTrade(activeSig.direction, activeSig.entryPrice, 1.1900, activeSig.takeProfit, 0.0050, 1.0, 10000.0, Symbol());
    CMNSTestSuite::AssertTrue(riskRes.approved, "Risk sizing is approved (RR = 1.82)");
    CMNSTestSuite::AssertEqualDouble(1.1890, riskRes.stopLoss, "Pre-trade Stop Loss is 1.1890 (includes 0.0010 ATR buffer)");
    CMNSTestSuite::AssertTrue(riskRes.volume > 0.0, "Sized volume is valid");
    CMNSTestSuite::AssertEqualDouble(100.0, riskRes.riskAmount, "Risk amount matches 1% of equity ($100.00)");

    // 5. Execution Transition
    bool execSuccess = entryEngine.SetActiveSignalExecuted();
    CMNSTestSuite::AssertTrue(execSuccess, "SetActiveSignalExecuted completes successfully");
    CMNSTestSuite::AssertEqualInt(ENTRY_STATE_EXECUTED, entryEngine.GetActiveSignalState(), "Signal transitions to ENTRY_STATE_EXECUTED");

    // 6. Duplicate Prevention
    // Try to update with the same trigger time. Entry engine must block it.
    bool dupResult = entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, TEST_BARS, 0, 10.0);
    CMNSTestSuite::AssertTrue(!dupResult, "Duplicate update does not recreate active signal");
    CMNSTestSuite::AssertEqualInt(ENTRY_STATE_EXECUTED, entryEngine.GetActiveSignalState(), "Signal state remains ENTRY_STATE_EXECUTED");


    //------------------------------------------------------------------
    // TEST 2: Bearish Signal Sizing, Execution, and Duplicates
    //------------------------------------------------------------------
    Print("--- Test 2: Bearish Execution Lifecycle ---");
    
    entryEngine.Reset();
    riskEngine.ResetPositionTracking();
    confEngine.Reset();
    objEngine.Reset();
    objEngine.Initialize();
    structEng.OverrideTrend(TREND_BEARISH);

    // 1. Setup a Bearish Objective (DOL) at 1.1800
    objEngine.OverrideDol(true, 1.1800, DOL_EXTERNAL_SWING, 100.0);

    // 2. Setup Bearish confirmation: touch POI at 1.2050, invalidation at 1.2100
    // Mock Confirmation state manually for clarity with a unique timestamp
    confEngine.OverrideState(CONFIRMATION_STATE_CONFIRMED, CONFIRM_DIR_BEARISH, 1.2000, 1.2100, TimeCurrent() + 3600);
    CMNSTestSuite::AssertEqualInt(CONFIRMATION_STATE_CONFIRMED, confEngine.GetConfirmationState(), "Bearish confirmation active");

    // 3. Entry Engine generates active signal
    signalGenerated = entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, TEST_BARS, 0, 10.0);
    CMNSTestSuite::AssertTrue(signalGenerated, "CEntryEngine generates active Bearish signal");
    CMNSTestSuite::AssertEqualInt(ENTRY_STATE_ACTIVE, entryEngine.GetActiveSignalState(), "Bearish Signal state is ENTRY_STATE_ACTIVE");

    activeSig = entryEngine.GetActiveSignal();
    CMNSTestSuite::AssertEqualDouble(1.2000, activeSig.entryPrice, "Bearish Entry Price is 1.2000");
    CMNSTestSuite::AssertEqualDouble(1.2100, activeSig.stopLoss, "Bearish Invalidation level is 1.2100");
    CMNSTestSuite::AssertEqualDouble(1.1800, activeSig.takeProfit, "Bearish DOL take profit is 1.1800");

    // 4. Pre-Trade Risk Sizing (Risk = 1.0%, Equity = 10000.0)
    // Invalidation = 1.2100. Stop Buffer = 0.0010. Expected SL = 1.2100 + 0.0010 = 1.2110.
    // Reward distance = 1.2000 - 1.1800 = 0.0200. Risk distance = 1.2110 - 1.2000 = 0.0110. RR = 1.818 >= 1.50R.
    riskRes = riskEngine.SizePreTrade(activeSig.direction, activeSig.entryPrice, 1.2100, activeSig.takeProfit, 0.0050, 1.0, 10000.0, Symbol());
    CMNSTestSuite::AssertTrue(riskRes.approved, "Bearish Risk sizing is approved");
    CMNSTestSuite::AssertEqualDouble(1.2110, riskRes.stopLoss, "Bearish Stop Loss is 1.2110 (includes 0.0010 ATR buffer)");


    //------------------------------------------------------------------
    // TEST 3: Active Position Management (Partial Closes & Trailing Stops)
    //------------------------------------------------------------------
    Print("--- Test 3: Active Position Management ---");
    
    riskEngine.ResetPositionTracking();
    CMNSTestSuite::AssertTrue(!riskEngine.GetHasPartialClosed(), "ResetPositionTracking resets hasPartialClosed to false");

    // Position Details: Buy at 1.2000, Original SL = 1.1890 (risk = 0.0110), Volume = 0.10 lots.
    double entry = 1.2000;
    double origSL = 1.1890;
    double vol = 0.10;
    double atr = 0.0050;

    // A. Price ranges before +1.0R: Bid = 1.2100 (progress = 0.0100 < 0.0110)
    SRiskManagementAction mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, vol, origSL, origSL,
        1.2100, 1.2101, atr, DELIVERY_ACTIVE, false, false, false, 0.0, Symbol()
    );
    CMNSTestSuite::AssertTrue(!mgmtAct.closePartially, "No partial close below +1.0R");
    CMNSTestSuite::AssertEqualDouble(MNS_INVALID_PRICE, mgmtAct.newStopLoss, "No trailing stop below +1.5R");

    // B. Price reaches +1.0R: Bid = 1.2110 (progress = 0.0110 == 1.0R)
    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, vol, origSL, origSL,
        1.2110, 1.2111, atr, DELIVERY_ACTIVE, false, false, false, 0.0, Symbol()
    );
    CMNSTestSuite::AssertTrue(mgmtAct.closePartially, "Partial close triggered at +1.0R");
    CMNSTestSuite::AssertEqualDouble(0.05, mgmtAct.partialVolume, "Partial close volume is exactly 50% of active contract size (0.05)");
    CMNSTestSuite::AssertTrue(riskEngine.GetHasPartialClosed(), "Risk Engine registers m_hasPartialClosed is true");

    // C. Reload scenario: Simulator reloads and calls SetHasPartialClosed(true)
    riskEngine.ResetPositionTracking();
    riskEngine.SetHasPartialClosed(true);
    CMNSTestSuite::AssertTrue(riskEngine.GetHasPartialClosed(), "GetHasPartialClosed returns true after sync setter");

    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, 0.05, origSL, origSL,
        1.2115, 1.2116, atr, DELIVERY_ACTIVE, false, false, false, 0.0, Symbol()
    );
    CMNSTestSuite::AssertTrue(!mgmtAct.closePartially, "No duplicate partial close triggers after state reload");

    // D. Trailing Stop Starts at +1.5R: Bid = 1.2165 (progress = 0.0165 >= 1.5R)
    // Trailing distance is 1.0 * ATR = 0.0050. Expected new SL = Bid - ATR = 1.2165 - 0.0050 = 1.2115.
    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, 0.05, origSL, origSL,
        1.2165, 1.2166, atr, DELIVERY_ACTIVE, false, false, false, 0.0, Symbol()
    );
    CMNSTestSuite::AssertEqualDouble(1.2115, mgmtAct.newStopLoss, "Trailing stop sets new Stop Loss to 1.2115 at +1.5R (+1.0R above entry)");

    // E. Retrace Check: current SL is at 1.2115. Bid drops back to 1.2130 (progress = 1.18R)
    // Candidate SL is 1.2130 - 0.0050 = 1.2080. Since candidate SL (1.2080) < current SL (1.2115), the stop must NOT be worsened.
    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, 0.05, origSL, 1.2115,
        1.2130, 1.2131, atr, DELIVERY_ACTIVE, false, false, false, 0.0, Symbol()
    );
    CMNSTestSuite::AssertEqualDouble(MNS_INVALID_PRICE, mgmtAct.newStopLoss, "Trailing stop does not decrease (never worsen stop loss)");

    // F. Progress to +2.0R: Bid = 1.2220 (progress = 0.0220 == 2.0R)
    // Trailing distance = 0.0050. Expected new SL = 1.2220 - 0.0050 = 1.2170.
    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, 0.05, origSL, 1.2115,
        1.2220, 1.2221, atr, DELIVERY_ACTIVE, false, false, false, 0.0, Symbol()
    );
    CMNSTestSuite::AssertEqualDouble(1.2170, mgmtAct.newStopLoss, "Trailing stop moves to 1.2170 at +2.0R");


    //------------------------------------------------------------------
    // TEST 4: Emergency Exits
    //------------------------------------------------------------------
    Print("--- Test 4: Emergency Exits ---");

    // 1. Daily Drawdown limit breach (current DD = 5.0% >= max daily drawdown 5.0%)
    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, vol, origSL, origSL,
        1.2100, 1.2101, atr, DELIVERY_ACTIVE, false, false, false, 5.0, Symbol()
    );
    CMNSTestSuite::AssertTrue(mgmtAct.closeFully, "Emergency Close triggered on Daily Drawdown breach");

    // 2. MTF Trend Reversal
    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, vol, origSL, origSL,
        1.2100, 1.2101, atr, DELIVERY_ACTIVE, false, false, true, 0.0, Symbol()
    );
    CMNSTestSuite::AssertTrue(mgmtAct.closeFully, "Emergency Close triggered on Higher Timeframe Trend Reversal");

    // 3. Delivery structure invalidation (DELIVERY_INVALIDATED)
    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, vol, origSL, origSL,
        1.2100, 1.2101, atr, DELIVERY_INVALIDATED, false, false, false, 0.0, Symbol()
    );
    CMNSTestSuite::AssertTrue(mgmtAct.closeFully, "Emergency Close triggered on Delivery Invalidation");

    // 4. DOL target reached
    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, vol, origSL, origSL,
        1.2100, 1.2101, atr, DELIVERY_ACTIVE, true, false, false, 0.0, Symbol()
    );
    CMNSTestSuite::AssertTrue(mgmtAct.closeFully, "Emergency Close triggered when DOL is reached");

    // 5. DOL target invalidated
    mgmtAct = riskEngine.UpdateActiveManagement(
        CONFIRM_DIR_BULLISH, entry, vol, origSL, origSL,
        1.2100, 1.2101, atr, DELIVERY_ACTIVE, false, true, false, 0.0, Symbol()
    );
    CMNSTestSuite::AssertTrue(mgmtAct.closeFully, "Emergency Close triggered when DOL is invalidated");


    #undef TEST_BARS

    // Compile and report results
    CMNSTestSuite::ReportResults("MNS State Transitions & Risk Management");

    // Clean up logger
    CMNSLogger::Close();

    // Return INIT_FAILED to self-remove from chart after printing the verification report
    return INIT_FAILED;
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
}
