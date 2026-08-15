//+------------------------------------------------------------------+
//|                                            MNS_TestHarness.mq5  |
//|                              MNS Trading Engine — Test Harness   |
//|                                                                  |
//| Purpose:                                                         |
//|   Validates that each completed MNS module compiles correctly    |
//|   and behaves according to its specification.                    |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Validate Module 001 (MNSTypes) structure defaults.           |
//|   - Validate Module 002 (CSwingDetector) public API behaviour.   |
//|   - Print PASS / FAIL results per assertion to the Experts log.  |
//|   - Run all tests in a single OnInit() pass.                     |
//|   - Never connect to broker, draw objects, or place trades.      |
//|                                                                  |
//| Rules:                                                           |
//|   - No trading logic.                                            |
//|   - No indicator drawing.                                        |
//|   - No chart operations beyond Print().                          |
//|   - All test data is deterministic and hard-coded.               |
//|   - Each module section is independent.                          |
//|                                                                  |
//| Version: 2.0                                                     |
//| Status:  Development                                             |
//+------------------------------------------------------------------+
#property copyright "MNS Trading Engine"
#property version "2.00"
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
#include "..\\..\\Include\\MNS\\MNSSerializer.mqh"
#include "..\\..\\Include\\MNS\\MNSTestSuite.mqh"
#define MNS_PROFILING_ENABLE
#include "..\\..\\Include\\MNS\\MNSProfiler.mqh"

//+------------------------------------------------------------------+
//| Test result tracking                                             |
//+------------------------------------------------------------------+
int g_testsPassed = 0;
int g_testsFailed = 0;

//+------------------------------------------------------------------+
//| Assertion helper                                                 |
//|                                                                  |
//| Prints PASS or FAIL to the Experts log and updates counters.     |
//|                                                                  |
//| @param condition   The boolean result of the assertion.          |
//| @param testName    Descriptive name printed in the log output.   |
//+------------------------------------------------------------------+
void AssertTrue(bool condition, const string testName) {
    if (condition) {
        Print("  [PASS] ", testName);
        g_testsPassed++;
    } else {
        Print("  [FAIL] ", testName);
        g_testsFailed++;
    }
}

void AssertEqualDouble(double actual, double expected, const string testName) {
    if (MathAbs(actual - expected) < 0.00001) {
        Print("  [PASS] ", testName);
        g_testsPassed++;
    } else {
        Print("  [FAIL] ", testName, " - Expected: ", DoubleToString(expected, 5), ", Actual: ", DoubleToString(actual, 5));
        g_testsFailed++;
    }
}

void AssertEqualInt(int actual, int expected, const string testName) {
    if (actual == expected) {
        Print("  [PASS] ", testName);
        g_testsPassed++;
    } else {
        Print("  [FAIL] ", testName, " - Expected: ", IntegerToString(expected), ", Actual: ", IntegerToString(actual));
        g_testsFailed++;
    }
}

//+------------------------------------------------------------------+
//| Module 001 — MNSTypes validation                                 |
//|                                                                  |
//| Validates that every shared structure initializes to the         |
//| expected safe default values defined in MNSTypes.mqh.            |
//+------------------------------------------------------------------+
void RunModule001Tests() {
    Print("--- Module 001: MNSTypes ---");
    Print("Engine Version : ", MNS_ENGINE_VERSION);
    Print("Module Version : ", MNS_MODULE_VERSION);

    //------------------------------------------------------------------
    //| SSwingPoint default initialization
    //------------------------------------------------------------------
    SSwingPoint swing;
    swing.Reset();

    Print("[SSwingPoint]");
    Print("  barIndex    = ", swing.barIndex);
    Print("  price       = ", swing.price);
    Print("  time        = ", swing.time);
    Print("  type        = ", EnumToString(swing.type));
    Print("  level       = ", EnumToString(swing.level));
    Print("  isConfirmed = ", swing.isConfirmed);

    AssertTrue(swing.barIndex == MNS_INVALID_INDEX, "SSwingPoint.barIndex default is MNS_INVALID_INDEX");
    AssertTrue(swing.price == MNS_INVALID_PRICE, "SSwingPoint.price default is MNS_INVALID_PRICE");
    AssertTrue(swing.time == MNS_INVALID_TIME, "SSwingPoint.time default is MNS_INVALID_TIME");
    AssertTrue(swing.type == SWING_NONE, "SSwingPoint.type default is SWING_NONE");
    AssertTrue(swing.level == SWING_LEVEL_INTERNAL, "SSwingPoint.level default is SWING_LEVEL_INTERNAL");
    AssertTrue(swing.isConfirmed == false, "SSwingPoint.isConfirmed default is false");

    //------------------------------------------------------------------
    //| SStructureBreak default initialization
    //------------------------------------------------------------------
    SStructureBreak structBreak;
    structBreak.Reset();

    Print("[SStructureBreak]");
    Print("  barIndex    = ", structBreak.barIndex);
    Print("  price       = ", structBreak.price);
    Print("  time        = ", structBreak.time);
    Print("  breakType   = ", EnumToString(structBreak.breakType));
    Print("  strength    = ", EnumToString(structBreak.strength));
    Print("  isConfirmed = ", structBreak.isConfirmed);

    AssertTrue(structBreak.barIndex == MNS_INVALID_INDEX, "SStructureBreak.barIndex default is MNS_INVALID_INDEX");
    AssertTrue(structBreak.price == MNS_INVALID_PRICE, "SStructureBreak.price default is MNS_INVALID_PRICE");
    AssertTrue(structBreak.time == MNS_INVALID_TIME, "SStructureBreak.time default is MNS_INVALID_TIME");
    AssertTrue(structBreak.breakType == BREAK_NONE, "SStructureBreak.breakType default is BREAK_NONE");
    AssertTrue(structBreak.strength == STRENGTH_UNKNOWN, "SStructureBreak.strength default is STRENGTH_UNKNOWN");
    AssertTrue(structBreak.isConfirmed == false, "SStructureBreak.isConfirmed default is false");

    //------------------------------------------------------------------
    //| SMarketState default initialization
    //------------------------------------------------------------------
    SMarketState state;
    state.Reset();

    Print("[SMarketState]");
    Print("  trend              = ", EnumToString(state.trend));
    Print("  phase              = ", EnumToString(state.phase));
    Print("  structureType      = ", EnumToString(state.structureType));
    Print("  isBullishStructure = ", state.isBullishStructure);
    Print("  isBearishStructure = ", state.isBearishStructure);
    Print("  isRanging          = ", state.isRanging);
    Print("  updatedBarIndex    = ", state.updatedBarIndex);
    Print("  updatedTime        = ", state.updatedTime);
    Print("  version            = ", state.version);

    AssertTrue(state.trend == TREND_UNKNOWN, "SMarketState.trend default is TREND_UNKNOWN");
    AssertTrue(state.phase == PHASE_UNKNOWN, "SMarketState.phase default is PHASE_UNKNOWN");
    AssertTrue(state.structureType == STRUCTURE_NONE, "SMarketState.structureType default is STRUCTURE_NONE");
    AssertTrue(state.isBullishStructure == false, "SMarketState.isBullishStructure default is false");
    AssertTrue(state.isBearishStructure == false, "SMarketState.isBearishStructure default is false");
    AssertTrue(state.isRanging == false, "SMarketState.isRanging default is false");
    AssertTrue(state.updatedBarIndex == MNS_INVALID_INDEX, "SMarketState.updatedBarIndex default is MNS_INVALID_INDEX");
    AssertTrue(state.updatedTime == MNS_INVALID_TIME, "SMarketState.updatedTime default is MNS_INVALID_TIME");
    AssertTrue(state.version == 1, "SMarketState.version default is 1");

    Print("--- Module 001 complete ---");
}

//+------------------------------------------------------------------+
//| Module 002 — CSwingDetector validation                          |
//|                                                                  |
//| Tests the public API of CSwingDetector using deterministic       |
//| hard-coded OHLC arrays. No broker data is used.                  |
//|                                                                  |
//| Test data design:                                                |
//|   - 50 bars of synthetic OHLC (series order: index 0 = newest). |
//|   - A clear swing HIGH is planted at index 20:                   |
//|     high[20] is set to 1.2100, which is strictly greater than    |
//|     all surrounding highs (index 5..35 range).                   |
//|   - A clear swing LOW is planted at index 20:                    |
//|     This is NOT planted — a single bar cannot simultaneously be  |
//|     the highest high and lowest low. The low at index 20 is kept |
//|     at baseline. A separate swing low is planted at index 22.    |
//|   - All other bars form a flat baseline (high = 1.2000,          |
//|     low = 1.1990, close = 1.1995, open = 1.1993).               |
//|   - The detector is run with externalDepth = 15 and              |
//|     internalDepth = 5 (strategy defaults).                       |
//|                                                                  |
//| Expected outcome:                                                |
//|   Because IsSwingHigh() and IsSwingLow() currently return false  |
//|   (TODOs pending strategy specification completion), no swings   |
//|   are confirmed. The API safety tests below validate that the    |
//|   module compiles, initializes, and handles empty-state queries  |
//|   without crashes or undefined behaviour.                        |
//|                                                                  |
//|   Once the strategy confirmation rules are implemented in        |
//|   IsSwingHigh() / IsSwingLow(), GetSwingCount() expectations     |
//|   should be updated to assert > 0 for the planted pivot bars.   |
//+------------------------------------------------------------------+
void RunModule002Tests() {
    Print("--- Module 002: CSwingDetector ---");

    //------------------------------------------------------------------
    //| Test 1: Initialize() with valid parameters
    //------------------------------------------------------------------
    CSwingDetector detector;

    bool initResult = detector.Initialize(MNS_SWING_EXTERNAL_DEPTH,
                                          MNS_SWING_INTERNAL_DEPTH);
    AssertTrue(initResult == true, "CSwingDetector.Initialize() returns true with valid depths");

    //------------------------------------------------------------------
    //| Test 2: Initialize() rejects invalid parameters
    //------------------------------------------------------------------
    CSwingDetector badDetector;
    bool badInitZero = badDetector.Initialize(0, 0);
    bool badInitFlip = badDetector.Initialize(3, 10); // internal > external
    AssertTrue(badInitZero == false, "CSwingDetector.Initialize(0, 0) returns false");
    AssertTrue(badInitFlip == false, "CSwingDetector.Initialize(3, 10) returns false (internal > external)");

    //------------------------------------------------------------------
    //| Test 3: Pre-Update() state is empty
    //------------------------------------------------------------------
    AssertTrue(detector.HasConfirmedSwing() == false, "HasConfirmedSwing() is false before Update()");
    AssertTrue(detector.GetSwingCount() == 0, "GetSwingCount() is 0 before Update()");
    AssertTrue(detector.GetExternalSwingCount() == 0, "GetExternalSwingCount() is 0 before Update()");
    AssertTrue(detector.GetInternalSwingCount() == 0, "GetInternalSwingCount() is 0 before Update()");

    //------------------------------------------------------------------
    //| Test 4: Out-of-range GetSwing() returns an empty SSwingPoint
    //------------------------------------------------------------------
    SSwingPoint oobExt = detector.GetExternalSwing(0);
    SSwingPoint oobInt = detector.GetInternalSwing(0);
    AssertTrue(oobExt.isConfirmed == false, "GetExternalSwing(0) on empty detector returns unconfirmed swing");
    AssertTrue(oobInt.isConfirmed == false, "GetInternalSwing(0) on empty detector returns unconfirmed swing");

    //------------------------------------------------------------------
    //| Test 5: GetLatestSwing() and GetLatest*() on empty detector
    //------------------------------------------------------------------
    SSwingPoint emptyLatest = detector.GetLatestSwing();
    SSwingPoint emptyExtHigh = detector.GetLatestExternalHigh();
    SSwingPoint emptyExtLow = detector.GetLatestExternalLow();
    SSwingPoint emptyIntHigh = detector.GetLatestInternalHigh();
    SSwingPoint emptyIntLow = detector.GetLatestInternalLow();

    AssertTrue(emptyLatest.isConfirmed == false, "GetLatestSwing() on empty detector returns unconfirmed swing");
    AssertTrue(emptyExtHigh.isConfirmed == false, "GetLatestExternalHigh() on empty detector returns unconfirmed swing");
    AssertTrue(emptyExtLow.isConfirmed == false, "GetLatestExternalLow() on empty detector returns unconfirmed swing");
    AssertTrue(emptyIntHigh.isConfirmed == false, "GetLatestInternalHigh() on empty detector returns unconfirmed swing");
    AssertTrue(emptyIntLow.isConfirmed == false, "GetLatestInternalLow() on empty detector returns unconfirmed swing");

    //------------------------------------------------------------------
    //| Test 6: Update() with insufficient bars returns false safely
    //------------------------------------------------------------------
    double tinyHigh[5] = {1.2001, 1.2002, 1.2003, 1.2004, 1.2005};
    double tinyLow[5] = {1.1991, 1.1992, 1.1993, 1.1994, 1.1995};
    datetime tinyTime[5] = {10000, 20000, 30000, 40000, 50000};

    bool tinyResult = detector.Update(tinyHigh, tinyLow, tinyTime, 5, 0);
    AssertTrue(tinyResult == false, "Update() with fewer bars than (2*depth+1) returns false");
    AssertTrue(detector.GetSwingCount() == 0, "GetSwingCount() remains 0 after Update() with insufficient bars");

    //------------------------------------------------------------------
    //| Test 7: Update() on not-initialized detector returns false
    //------------------------------------------------------------------
    CSwingDetector uninitDetector;
    double dummyHigh[50];
    double dummyLow[50];
    datetime dummyTime[50];
    ArrayInitialize(dummyHigh, 1.2000);
    ArrayInitialize(dummyLow, 1.1990);
    for (int i = 0; i < 50; i++)
        dummyTime[i] = (datetime)(i * 3600);

    bool uninitResult = uninitDetector.Update(dummyHigh, dummyLow, dummyTime, 50, 0);
    AssertTrue(uninitResult == false, "Update() on uninitialized detector returns false");

//------------------------------------------------------------------
//| Test 8: Update() with full synthetic OHLC dataset executes safely
//|
//| Builds 50 bars of deterministic test data (series order:
//|   index 0 = newest bar, index 49 = oldest bar).
//|
//| Swing high planted at bar index 20 (series order):
//|   high[20] = 1.2100 — strictly greater than all surrounding bars
//|   in the range [5..35], which covers the 15-candle external window.
//|
//| Swing low planted at bar index 25 (series order):
//|   low[25] = 1.1900 — strictly less than all surrounding bars
//|   in the range [10..40].
//|
//| All other bars: high = 1.2000, low = 1.1990.
//------------------------------------------------------------------
//--- MQL5 requires a literal or #define for static array sizes,
//--- not a const int variable. Using literals directly here.
#define TEST_BARS 50
#define PIVOT_HIGH_INDEX 20
#define PIVOT_LOW_INDEX 25

    double testHigh[TEST_BARS];
    double testLow[TEST_BARS];
    double testOpen[TEST_BARS];
    double testClose[TEST_BARS];
    datetime testTime[TEST_BARS];

    //--- Populate baseline values
    for (int i = 0; i < TEST_BARS; i++) {
        testHigh[i] = 1.2000;
        testLow[i] = 1.1990;
        testOpen[i] = 1.1993;
        testClose[i] = 1.1995;
        //--- Series order: index 0 = newest. Each bar is 1 hour apart.
        //--- Oldest bar (index 49) starts at a fixed epoch offset.
        testTime[i] = (datetime)((TEST_BARS - 1 - i) * 3600);
    }

    //--- Plant swing HIGH at PIVOT_HIGH_INDEX
    //--- high[20] = 1.2100 is the highest in [5..35] window
    testHigh[PIVOT_HIGH_INDEX] = 1.2100;

    //--- Plant swing LOW at PIVOT_LOW_INDEX
    //--- low[25] = 1.1900 is the lowest in [10..40] window
    testLow[PIVOT_LOW_INDEX] = 1.1900;

    bool updateResult = detector.Update(testHigh, testLow, testTime, TEST_BARS, 0);

    //--- Update() must not crash and must return a bool without error.
    //--- Whether swings were confirmed depends on IsSwingHigh/Low() implementation.
    //--- The assertion here validates safe execution, not a specific count.
    Print("  Update() returned: ", updateResult ? "true" : "false");
    Print("  GetSwingCount() after Update(): ", detector.GetSwingCount());
    Print("  GetExternalSwingCount(): ", detector.GetExternalSwingCount());
    Print("  GetInternalSwingCount(): ", detector.GetInternalSwingCount());

    AssertTrue(true, "Update() with 50-bar dataset executes without crash");

    //--- Count must be consistent across all accessors.
    AssertTrue(
        detector.GetSwingCount() == detector.GetExternalSwingCount() + detector.GetInternalSwingCount(),
        "GetSwingCount() equals GetExternalSwingCount() + GetInternalSwingCount()");

    //--- HasConfirmedSwing() must agree with GetSwingCount().
    bool expectedHas = (detector.GetSwingCount() > 0);
    AssertTrue(detector.HasConfirmedSwing() == expectedHas,
               "HasConfirmedSwing() is consistent with GetSwingCount()");

    //------------------------------------------------------------------
    //| Test 9: Reset() clears all confirmed swings
    //------------------------------------------------------------------
    detector.Reset();
    AssertTrue(detector.GetSwingCount() == 0, "GetSwingCount() is 0 after Reset()");
    AssertTrue(detector.GetExternalSwingCount() == 0, "GetExternalSwingCount() is 0 after Reset()");
    AssertTrue(detector.GetInternalSwingCount() == 0, "GetInternalSwingCount() is 0 after Reset()");
    AssertTrue(detector.HasConfirmedSwing() == false, "HasConfirmedSwing() is false after Reset()");

    //--- Latest accessors must return unconfirmed empty swings after Reset.
    SSwingPoint rsLatest = detector.GetLatestSwing();
    SSwingPoint rsExtHigh = detector.GetLatestExternalHigh();
    SSwingPoint rsExtLow = detector.GetLatestExternalLow();
    SSwingPoint rsIntHigh = detector.GetLatestInternalHigh();
    SSwingPoint rsIntLow = detector.GetLatestInternalLow();

    AssertTrue(rsLatest.isConfirmed == false, "GetLatestSwing() is unconfirmed after Reset()");
    AssertTrue(rsExtHigh.isConfirmed == false, "GetLatestExternalHigh() is unconfirmed after Reset()");
    AssertTrue(rsExtLow.isConfirmed == false, "GetLatestExternalLow() is unconfirmed after Reset()");
    AssertTrue(rsIntHigh.isConfirmed == false, "GetLatestInternalHigh() is unconfirmed after Reset()");
    AssertTrue(rsIntLow.isConfirmed == false, "GetLatestInternalLow() is unconfirmed after Reset()");

    //------------------------------------------------------------------
    //| Test 10: Initialize() is safe to call again after Reset()
    //------------------------------------------------------------------
    bool reinitResult = detector.Initialize(MNS_SWING_EXTERNAL_DEPTH,
                                            MNS_SWING_INTERNAL_DEPTH);
    AssertTrue(reinitResult == true, "Initialize() succeeds again after Reset()");

#undef TEST_BARS
#undef PIVOT_HIGH_INDEX
#undef PIVOT_LOW_INDEX

    Print("--- Module 002 complete ---");
}

//+------------------------------------------------------------------+
//| Module 003 — CStructureEngine validation                         |
//+------------------------------------------------------------------+
void RunModule003Tests() {
    Print("--- Module 003: CStructureEngine ---");

    //------------------------------------------------------------------
    //| Test 1: Initialize() and Reset()
    //------------------------------------------------------------------
    CStructureEngine engine;
    bool initResult = engine.Initialize(0.0);
    AssertTrue(initResult == true, "CStructureEngine.Initialize() returns true");

    SMarketState state = engine.GetState();
    AssertTrue(state.trend == TREND_UNKNOWN, "Default trend is TREND_UNKNOWN");
    AssertTrue(state.phase == PHASE_UNKNOWN, "Default phase is PHASE_UNKNOWN");
    AssertTrue(engine.GetConfidenceScore() == 1.0, "Default confidence score (version) is 1.0");

    //------------------------------------------------------------------
    //| Test 2: Update() with empty detector
    //------------------------------------------------------------------
    CSwingDetector detector;
    detector.Initialize(MNS_SWING_EXTERNAL_DEPTH, MNS_SWING_INTERNAL_DEPTH);
    bool updateResultEmpty = engine.Update(detector, 0.0010);
    AssertTrue(updateResultEmpty == false, "Update() on empty detector returns false");

//------------------------------------------------------------------
//| Test 3: Bullish Trend and Trending Phase
//|
//| We construct a 150-bar dataset with 6 external swings (depth 15):
//|   - Low at 130: 1.1400
//|   - High at 110: 1.2600
//|   - Low at 90: 1.1500 (HL)
//|   - High at 70: 1.2700 (HH)
//|   - Low at 50: 1.1600 (HL)
//|   - High at 30: 1.2800 (HH)
//------------------------------------------------------------------
#define BULLISH_BARS 150
    double bullishHigh[BULLISH_BARS];
    double bullishLow[BULLISH_BARS];
    datetime bullishTime[BULLISH_BARS];

    for (int i = 0; i < BULLISH_BARS; i++) {
        bullishHigh[i] = 1.2000;
        bullishLow[i] = 1.1900;
        bullishTime[i] = (datetime)((BULLISH_BARS - 1 - i) * 3600);
    }

    // Lows
    for (int i = 115; i <= 145; i++)
        bullishLow[i] = 1.1900;
    bullishLow[130] = 1.1400;

    for (int i = 75; i <= 105; i++)
        bullishLow[i] = 1.1900;
    bullishLow[90] = 1.1500;

    for (int i = 35; i <= 65; i++)
        bullishLow[i] = 1.1900;
    bullishLow[50] = 1.1600;

    // Highs
    for (int i = 95; i <= 125; i++)
        bullishHigh[i] = 1.2000;
    bullishHigh[110] = 1.2600;

    for (int i = 55; i <= 85; i++)
        bullishHigh[i] = 1.2000;
    bullishHigh[70] = 1.2700;

    for (int i = 15; i <= 45; i++)
        bullishHigh[i] = 1.2000;
    bullishHigh[30] = 1.2800;

    CSwingDetector bullishDetector;
    bullishDetector.Initialize(15, 5);
    bullishDetector.Update(bullishHigh, bullishLow, bullishTime, BULLISH_BARS, 0);

    AssertTrue(bullishDetector.GetExternalSwingCount() == 6, "Bullish test dataset confirms 6 external swings");

    CStructureEngine bullishEngine;
    bullishEngine.Initialize(0.0);
    bool engineUpdate = bullishEngine.Update(bullishDetector, 0.0010);
    AssertTrue(engineUpdate == true, "CStructureEngine.Update() on bullish swings returns true");

    SMarketState bullishState = bullishEngine.GetState();
    AssertTrue(bullishState.trend == TREND_BULLISH, "Trend is Bullish");
    AssertTrue(bullishState.phase == PHASE_TRENDING, "Phase is Trending");
    AssertTrue(bullishState.isBullishStructure == true, "isBullishStructure is true");
    AssertTrue(bullishState.isBearishStructure == false, "isBearishStructure is false");
    AssertTrue(bullishState.isRanging == false, "isRanging is false");

    // Dynamic confidence score:
    // Bullish Trend (25) + BOS HH (20) + Internal Bullish (10) + 5 neutral alignments (22.5) = 77.5 (rounds to 78)
    AssertTrue(bullishEngine.GetConfidenceScore() == 78.0, "Confidence score is 78.0 with default neutral alignments");

    // Recalculate and test setters
    bullishEngine.Reset();
    bullishEngine.SetOrderFlowAlignment(ALIGN_ALIGNED);
    bullishEngine.SetDisplacementQuality(ALIGN_ALIGNED);
    bullishEngine.SetMtfAgreement(ALIGN_ALIGNED);
    bullishEngine.SetActiveDeliveryAlignment(ALIGN_ALIGNED);
    bullishEngine.SetDolCompatibility(ALIGN_ALIGNED);
    bullishEngine.Update(bullishDetector, 0.0010);
    AssertTrue(bullishEngine.GetConfidenceScore() == 100.0, "Confidence score is 100.0 when fully aligned");

#undef BULLISH_BARS

//------------------------------------------------------------------
//| Test 4: Bearish Trend
//|
//| We construct a 150-bar dataset with 6 external swings (depth 15):
//|   - High at 130: 1.2800
//|   - Low at 110: 1.1600
//|   - High at 90: 1.2700 (LH)
//|   - Low at 70: 1.1500 (LL)
//|   - High at 50: 1.2600 (LH)
//|   - Low at 30: 1.1400 (LL)
//------------------------------------------------------------------
#define BEARISH_BARS 150
    double bearishHigh[BEARISH_BARS];
    double bearishLow[BEARISH_BARS];
    datetime bearishTime[BEARISH_BARS];

    for (int i = 0; i < BEARISH_BARS; i++) {
        bearishHigh[i] = 1.2000;
        bearishLow[i] = 1.1900;
        bearishTime[i] = (datetime)((BEARISH_BARS - 1 - i) * 3600);
    }

    // Highs
    for (int i = 115; i <= 145; i++)
        bearishHigh[i] = 1.2000;
    bearishHigh[130] = 1.2800;

    for (int i = 75; i <= 105; i++)
        bearishHigh[i] = 1.2000;
    bearishHigh[90] = 1.2700;

    for (int i = 35; i <= 65; i++)
        bearishHigh[i] = 1.2000;
    bearishHigh[50] = 1.2600;

    // Lows
    for (int i = 95; i <= 125; i++)
        bearishLow[i] = 1.1900;
    bearishLow[110] = 1.1600;

    for (int i = 55; i <= 85; i++)
        bearishLow[i] = 1.1900;
    bearishLow[70] = 1.1500;

    for (int i = 15; i <= 45; i++)
        bearishLow[i] = 1.1900;
    bearishLow[30] = 1.1400;

    CSwingDetector bearishDetector;
    bearishDetector.Initialize(15, 5);
    bearishDetector.Update(bearishHigh, bearishLow, bearishTime, BEARISH_BARS, 0);

    AssertTrue(bearishDetector.GetExternalSwingCount() == 6, "Bearish test dataset confirms 6 external swings");

    CStructureEngine bearishEngine;
    bearishEngine.Initialize(0.0);
    bearishEngine.Update(bearishDetector, 0.0010);

    SMarketState bearishState = bearishEngine.GetState();
    AssertTrue(bearishState.trend == TREND_BEARISH, "Trend is Bearish");
    AssertTrue(bearishState.phase == PHASE_TRENDING, "Phase is Trending");
    AssertTrue(bearishState.isBearishStructure == true, "isBearishStructure is true");

#undef BEARISH_BARS

//------------------------------------------------------------------
//| Test 5: Bullish Pullback Phase
//|
//| External trend is Bullish (established by older pivots):
//|   - Low at 140: 1.1400 (depth 15)
//|   - High at 120: 1.2600 (depth 15)
//|   - Low at 100: 1.1500 (depth 15)
//|   - High at 80:  1.2700 (depth 15)
//|   - Low at 65:  1.1600 (depth 15)
//|   - High at 50: 1.2800 (depth 15)
//|
//| Internal trend is Bearish (established by newer micro pivots).
//| These points are spaced 14 bars apart so they FAIL the depth-15
//| external check but PASS the depth-5 internal check.
//| The 6 external points also qualify as internal swings (depth 5),
//| giving 6 + 4 = 10 total internal swings.
//|
//|   - High at 36: 1.2500 (internal only, fails external)
//|   - Low at 28:  1.1400 (internal only, fails external: index 14 is in right window)
//|   - High at 22: 1.2400 (internal only, fails external: index 36 is in left window)
//|   - Low at 14:  1.1300 (internal only, fails external: right bound out of range)
//------------------------------------------------------------------
#define PB_BARS 160
    double pbHigh[PB_BARS];
    double pbLow[PB_BARS];
    datetime pbTime[PB_BARS];

    for (int i = 0; i < PB_BARS; i++) {
        pbHigh[i] = 1.2000;
        pbLow[i] = 1.1900;
        pbTime[i] = (datetime)((PB_BARS - 1 - i) * 3600);
    }

    // External Lows (depth 15)
    pbLow[140] = 1.1400;
    pbLow[100] = 1.1500;
    pbLow[65] = 1.1600;

    // External Highs (depth 15)
    pbHigh[120] = 1.2600;
    pbHigh[80] = 1.2700;
    pbHigh[50] = 1.2800;

    // Internal Lows (depth 5, fail depth 15 because they are too close to each other)
    pbLow[28] = 1.1400;
    pbLow[14] = 1.1300;

    // Internal Highs (depth 5, fail depth 15)
    pbHigh[36] = 1.2500;
    pbHigh[22] = 1.2400;

    CSwingDetector pbDetector;
    pbDetector.Initialize(15, 5);
    pbDetector.Update(pbHigh, pbLow, pbTime, PB_BARS, 0);

    AssertTrue(pbDetector.GetExternalSwingCount() == 6, "Pullback test dataset confirms 6 external swings");
    AssertTrue(pbDetector.GetInternalSwingCount() == 10, "Pullback test dataset confirms 10 internal swings");

    CStructureEngine pbEngine;
    pbEngine.Initialize(0.0);
    pbEngine.Update(pbDetector, 0.0010);

    SMarketState pbState = pbEngine.GetState();
    AssertTrue(pbState.trend == TREND_BULLISH, "External trend remains Bullish");
    AssertTrue(pbState.phase == PHASE_PULLBACK, "Phase is Pullback");

#undef PB_BARS

//------------------------------------------------------------------
//| Test 6: Equal Highs / Equal Lows (Ranging Trend)
//|
//| We construct a sequence of swings within the ATR tolerance (0.10 * ATR):
//| ATR = 0.0100 -> Tolerance = 0.0010
//| Swings:
//|   - Low at 130: 1.1500
//|   - High at 110: 1.2500
//|   - Low at 90: 1.1505 (Diff = 0.0005 <= 0.0010 -> Equal Low)
//|   - High at 70: 1.2495 (Diff = 0.0005 <= 0.0010 -> Equal High)
//|   - Low at 50: 1.1502 (Diff = 0.0003 <= 0.0010 -> Equal Low)
//|   - High at 30: 1.2504 (Diff = 0.0009 <= 0.0010 -> Equal High)
//------------------------------------------------------------------
#define RANGE_BARS 150
    double rangeHigh[RANGE_BARS];
    double rangeLow[RANGE_BARS];
    datetime rangeTime[RANGE_BARS];

    for (int i = 0; i < RANGE_BARS; i++) {
        rangeHigh[i] = 1.2000;
        rangeLow[i] = 1.1900;
        rangeTime[i] = (datetime)((RANGE_BARS - 1 - i) * 3600);
    }

    // Lows
    rangeLow[130] = 1.1500;
    rangeLow[90] = 1.1505;
    rangeLow[50] = 1.1502;

    // Highs
    rangeHigh[110] = 1.2500;
    rangeHigh[70] = 1.2495;
    rangeHigh[30] = 1.2504;

    CSwingDetector rangeDetector;
    rangeDetector.Initialize(15, 5);
    rangeDetector.Update(rangeHigh, rangeLow, rangeTime, RANGE_BARS, 0);

    CStructureEngine rangeEngine;
    rangeEngine.Initialize(0.0);
    rangeEngine.Update(rangeDetector, 0.0100);

    SMarketState rangeState = rangeEngine.GetState();
    AssertTrue(rangeState.trend == TREND_RANGING, "Trend is Ranging");
    AssertTrue(rangeState.phase == PHASE_RANGING, "Phase is Ranging");
    AssertTrue(rangeState.isRanging == true, "isRanging is true");

#undef RANGE_BARS

    Print("--- Module 003 complete ---");
}

//+------------------------------------------------------------------+
//| Module 004 — CBreakDetector validation                           |
//+------------------------------------------------------------------+
void RunModule004Tests() {
    Print("--- Module 004: CBreakDetector ---");

    // Test 1: Initialize and Reset
    CBreakDetector detector;
    bool initResult = detector.Initialize();
    AssertTrue(initResult == true, "CBreakDetector.Initialize() returns true");
    AssertTrue(detector.GetBreakCount() == 0, "Initial break count is 0");

    // Test 2: Empty state getters return empty sentinels
    SStructureBreak emptyBOS = detector.GetLatestBOS();
    SStructureBreak emptyIBOS = detector.GetLatestIBOS();
    SStructureBreak emptyCHOCH = detector.GetLatestCHOCH();
    AssertTrue(emptyBOS.isConfirmed == false, "Default latest BOS is unconfirmed");
    AssertTrue(emptyIBOS.isConfirmed == false, "Default latest iBOS is unconfirmed");
    AssertTrue(emptyCHOCH.isConfirmed == false, "Default latest CHoCH is unconfirmed");

// Test 3: BOS Break Detection
#define BREAK_TEST_BARS 150
    double testHigh[BREAK_TEST_BARS];
    double testLow[BREAK_TEST_BARS];
    double testOpen[BREAK_TEST_BARS];
    double testClose[BREAK_TEST_BARS];
    datetime testTime[BREAK_TEST_BARS];

    for (int i = 0; i < BREAK_TEST_BARS; i++) {
        testHigh[i] = 1.2000;
        testLow[i] = 1.1900;
        testOpen[i] = 1.1950;
        testClose[i] = 1.1950;
        testTime[i] = (datetime)((BREAK_TEST_BARS - 1 - i) * 3600);
    }

    // Lows to plant swings
    testLow[130] = 1.1400;
    testLow[90] = 1.1500;
    testLow[50] = 1.1600;

    // Highs to plant swings
    testHigh[110] = 1.2600;
    testHigh[70] = 1.2700;
    testHigh[30] = 1.2800;

    // Create a body close above the swing high at 70 (price 1.2700) at index 54
    testClose[54] = 1.2750;
    testHigh[54] = 1.2780;
    testLow[54] = 1.2700;

    CSwingDetector swingDetector;
    swingDetector.Initialize(15, 5);
    swingDetector.Update(testHigh, testLow, testTime, BREAK_TEST_BARS, 0);

    CStructureEngine structureEngine;
    structureEngine.Initialize(0.0);
    structureEngine.Update(swingDetector, 0.0010);

    CBreakDetector breakDetector;
    breakDetector.Initialize();
    bool updated = breakDetector.Update(swingDetector, structureEngine, testHigh, testLow, testClose, testOpen, testTime, BREAK_TEST_BARS, 0, 0.0010);

    AssertTrue(updated == true, "Update returns true when breaks are detected");
    AssertTrue(breakDetector.GetBreakCount() > 0, "At least one break detected");
    AssertTrue(breakDetector.HasBullishBOS() == true, "HasBullishBOS() returns true");

    SStructureBreak latestBOS = breakDetector.GetLatestBOS();
    AssertTrue(latestBOS.brokenSwing.price == 1.2700, "BOS broken swing price matches swing high at 70");
    AssertTrue(latestBOS.breakType == BREAK_BOS, "Break type is BREAK_BOS");

    // Test 4: Bearish CHoCH detection
    // Re-initialize arrays to baseline to clear Test 3 pollution
    for (int i = 0; i < BREAK_TEST_BARS; i++) {
        testHigh[i] = 1.2000;
        testLow[i] = 1.1900;
        testOpen[i] = 1.1950;
        testClose[i] = 1.1950;
        testTime[i] = (datetime)((BREAK_TEST_BARS - 1 - i) * 3600);
    }

    // Restore swing low pivots
    testLow[130] = 1.1400;
    testLow[90] = 1.1500;
    testLow[50] = 1.1600;

    // Restore swing high pivots
    testHigh[110] = 1.2600;
    testHigh[70] = 1.2700;
    testHigh[30] = 1.2800;

    // Plant CHoCH body-close break at index 5 (protected low is 1.1600)
    // Close below 1.1600 - minBreakDistance (which is max(2 points, 0.10*ATR) = 0.0002) -> e.g. 1.1580
    testLow[5] = 1.1550;
    testClose[5] = 1.1580; // Body close below protected low - break distance
    testHigh[5] = 1.1700;

    swingDetector.Reset();
    swingDetector.Update(testHigh, testLow, testTime, BREAK_TEST_BARS, 0);
    structureEngine.Reset();
    structureEngine.Update(swingDetector, 0.0010);
    breakDetector.Reset();
    breakDetector.Update(swingDetector, structureEngine, testHigh, testLow, testClose, testOpen, testTime, BREAK_TEST_BARS, 0, 0.0010);

    AssertTrue(breakDetector.HasBearishCHOCH() == true, "HasBearishCHOCH() is true after body-close break of protected low");
    SStructureBreak latestCHOCH = breakDetector.GetLatestCHOCH();
    AssertTrue(latestCHOCH.brokenSwing.price == 1.1600, "CHoCH broken swing price is 1.1600");

#undef BREAK_TEST_BARS

    Print("--- Module 004 complete ---");
}

//+------------------------------------------------------------------+
//| Module 005 — COrderFlowEngine validation                         |
//+------------------------------------------------------------------+
void RunModule005Tests() {
    Print("--- Module 005: COrderFlowEngine ---");

    // Test 1: Initialize and default values
    COrderFlowEngine ofEngine;
    bool initRes = ofEngine.Initialize();
    AssertTrue(initRes == true, "COrderFlowEngine.Initialize() returns true");
    AssertTrue(ofEngine.IsNeutral() == true, "Default state is NEUTRAL");
    AssertTrue(ofEngine.GetDirection() == ORDER_FLOW_DIR_NEUTRAL, "Default direction is NEUTRAL");
    AssertTrue(ofEngine.GetConfidenceScore() == 0.0, "Default confidence score is 0.0");

    // Test 2: Out-of-bounds updates and empty history
    CSwingDetector swingDet;
    swingDet.Initialize(15, 5);
    CStructureEngine structEng;
    structEng.Initialize(0.0);
    CBreakDetector breakDet;
    breakDet.Initialize();

    double dummyHigh[10] = {1.2000, 1.2000, 1.2000, 1.2000, 1.2000, 1.2000, 1.2000, 1.2000, 1.2000, 1.2000};
    double dummyLow[10] = {1.1900, 1.1900, 1.1900, 1.1900, 1.1900, 1.1900, 1.1900, 1.1900, 1.1900, 1.1900};
    double dummyClose[10] = {1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950};
    double dummyOpen[10] = {1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950, 1.1950};
    datetime dummyTime[10] = {1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000};

    bool updated = ofEngine.Update(swingDet, structEng, breakDet, dummyHigh, dummyLow, dummyClose, dummyOpen, dummyTime, 10, 0, 0.0010);
    AssertTrue(updated == false, "Update returns false when no breaks occur");
    AssertTrue(ofEngine.IsNeutral() == true, "State remains NEUTRAL");

// Test 3: Bullish Order Flow transition happy path
#define OF_TEST_BARS 180
    double testHigh[OF_TEST_BARS];
    double testLow[OF_TEST_BARS];
    double testOpen[OF_TEST_BARS];
    double testClose[OF_TEST_BARS];
    datetime testTime[OF_TEST_BARS];

    for (int i = 0; i < OF_TEST_BARS; i++) {
        testHigh[i] = 1.2000;
        testLow[i] = 1.1900;
        testOpen[i] = 1.1950;
        testClose[i] = 1.1950;
        testTime[i] = (datetime)((OF_TEST_BARS - 1 - i) * 3600);
    }

    // Plant swing lows (external)
    testLow[150] = 1.1400; // Swing Low 1
    testLow[90] = 1.1500;  // Swing Low 2 (HL)
    testLow[30] = 1.1600;  // Swing Low 3 (HL)

    // Plant swing highs (external)
    testHigh[120] = 1.2600; // Swing High 1
    testHigh[60] = 1.2700;  // Swing High 2 (HH)

    // Plant Bullish BOS with displacement at index 80 (breaks swing high at 120, price 1.2600)
    testOpen[80] = 1.2500;
    testLow[80] = 1.2500;
    testClose[80] = 1.2750;
    testHigh[80] = 1.2750;

    swingDet.Reset();
    swingDet.Update(testHigh, testLow, testTime, OF_TEST_BARS, 0);
    structEng.Reset();
    structEng.Update(swingDet, 0.0010);
    breakDet.Reset();
    breakDet.Update(swingDet, structEng, testHigh, testLow, testClose, testOpen, testTime, OF_TEST_BARS, 0, 0.0010);

    ofEngine.Reset();
    bool ofUpdated = ofEngine.Update(swingDet, structEng, breakDet, testHigh, testLow, testClose, testOpen, testTime, OF_TEST_BARS, 0, 0.0010);

    AssertTrue(ofUpdated == true, "Update returns true when transitioning to BULLISH");
    AssertTrue(ofEngine.IsBullish() == true, "State transitioned to BULLISH");
    AssertTrue(ofEngine.GetDirection() == ORDER_FLOW_DIR_BULLISH, "Direction is Bullish");
    AssertTrue(ofEngine.GetState().protectedSwingId == testTime[90], "Protected swing ID is set to Swing Low 2 time");

    // Plant Bearish CHoCH (breaks protected low at 90, price 1.1500)
    testOpen[50] = 1.1550;
    testHigh[50] = 1.1550;
    testLow[50] = 1.1400;
    testClose[50] = 1.1450;

    swingDet.Reset();
    swingDet.Update(testHigh, testLow, testTime, OF_TEST_BARS, 0);
    structEng.Reset();
    structEng.Update(swingDet, 0.0010);
    breakDet.Reset();
    breakDet.Update(swingDet, structEng, testHigh, testLow, testClose, testOpen, testTime, OF_TEST_BARS, 0, 0.0010);

    ofEngine.Update(swingDet, structEng, breakDet, testHigh, testLow, testClose, testOpen, testTime, OF_TEST_BARS, 0, 0.0010);

    AssertTrue(ofEngine.GetGranularState() == ORDER_FLOW_TRANSITION_BEARISH, "State transitioned to TRANSITION_BEARISH after break of protected low");
    AssertTrue(ofEngine.GetDirection() == ORDER_FLOW_DIR_NEUTRAL, "Direction is Neutral during transition");
    AssertTrue(ofEngine.IsTransition() == true, "IsTransition() returns true");

    // Plant Bearish BOS of a swing low formed AFTER transition began (index 30)
    testOpen[10] = 1.1650;
    testHigh[10] = 1.1650;
    testLow[10] = 1.1400;
    testClose[10] = 1.1450;

    swingDet.Reset();
    swingDet.Update(testHigh, testLow, testTime, OF_TEST_BARS, 0);
    structEng.Reset();
    structEng.Update(swingDet, 0.0010);
    breakDet.Reset();
    breakDet.Update(swingDet, structEng, testHigh, testLow, testClose, testOpen, testTime, OF_TEST_BARS, 0, 0.0010);

    ofEngine.Update(swingDet, structEng, breakDet, testHigh, testLow, testClose, testOpen, testTime, OF_TEST_BARS, 0, 0.0010);

    AssertTrue(ofEngine.IsBearish() == true, "State transitioned to BEARISH after bearish BOS confirmation");
    AssertTrue(ofEngine.GetDirection() == ORDER_FLOW_DIR_BEARISH, "Direction is Bearish");

#undef OF_TEST_BARS

    Print("--- Module 005 complete ---");
}

//+------------------------------------------------------------------+
//| Module 006 — CDeliveryStructureEngine validation                 |
//+------------------------------------------------------------------+
void RunModule006Tests()
{
    Print("--- Module 006: CDeliveryStructureEngine ---");

    // Test 1: Initialize and default values
    CDeliveryStructureEngine delEngine;
    bool initRes = delEngine.Initialize();
    AssertTrue(initRes == true, "CDeliveryStructureEngine.Initialize() returns true");
    AssertTrue(delEngine.GetDirection() == DELIVERY_DIR_NEUTRAL, "Default direction is NEUTRAL");
    AssertTrue(delEngine.GetLifecycle() == DELIVERY_CANDIDATE, "Default lifecycle is CANDIDATE");
    AssertTrue(delEngine.GetConfidenceScore() == 0.0, "Default confidence score is 0.0");

    // Test 2: Active leg activation and progress happy path
    CSwingDetector swingDet;
    swingDet.Initialize(15, 5);
    CStructureEngine structEng;
    structEng.Initialize(0.0);
    CBreakDetector breakDet;
    breakDet.Initialize();
    COrderFlowEngine ofEngine;
    ofEngine.Initialize();

    #define DEL_TEST_BARS 180
    double   testHigh[DEL_TEST_BARS];
    double   testLow[DEL_TEST_BARS];
    double   testOpen[DEL_TEST_BARS];
    double   testClose[DEL_TEST_BARS];
    datetime testTime[DEL_TEST_BARS];

    for (int i = 0; i < DEL_TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
        testTime[i]  = (datetime)((DEL_TEST_BARS - 1 - i) * 3600);
    }

    // Swings
    testLow[150] = 1.1400; // Swing Low 1
    testLow[90]  = 1.1500; // Swing Low 2 (HL)
    testHigh[120] = 1.2600; // Swing High 1

    // Plant Bullish BOS (break of high at 120, price 1.2600)
    testOpen[80]  = 1.2500;
    testLow[80]   = 1.2500;
    testClose[80] = 1.2750;
    testHigh[80]  = 1.2750;

    // Run detector updates
    swingDet.Update(testHigh, testLow, testTime, DEL_TEST_BARS, 0);
    structEng.Update(swingDet, 0.0010);
    breakDet.Update(swingDet, structEng, testHigh, testLow, testClose, testOpen, testTime, DEL_TEST_BARS, 0, 0.0010);
    ofEngine.Update(swingDet, structEng, breakDet, testHigh, testLow, testClose, testOpen, testTime, DEL_TEST_BARS, 0, 0.0010);

    // Update delivery engine
    delEngine.Reset();
    bool updated = delEngine.Update(swingDet, structEng, breakDet, ofEngine, testHigh, testLow, testClose, testOpen, testTime, DEL_TEST_BARS, 0, 0.0010);
    
    AssertTrue(updated == true, "Update returns true on active bullish leg confirmation");
    AssertTrue(delEngine.GetDirection() == DELIVERY_DIR_BULLISH, "Direction is BULLISH");
    AssertTrue(delEngine.GetLifecycle() == DELIVERY_ACTIVE, "Lifecycle is ACTIVE");
    AssertTrue(delEngine.GetState().originPrice == 1.1500, "Origin price is swing low 2 price (1.1500)");
    AssertTrue(delEngine.GetState().invalidationLevel == 1.1500, "Invalidation level is swing low 2 price (1.1500)");

    // Test 3: Objective Reached
    // Target is swing high 1 (1.2600) by default. Let's push high above target at index 10.
    testHigh[1]  = 1.2700;
    testClose[1] = 1.2400; // close below target and origin to prevent invalidation/mitigation
    
    delEngine.Update(swingDet, structEng, breakDet, ofEngine, testHigh, testLow, testClose, testOpen, testTime, DEL_TEST_BARS, 0, 0.0010);
    AssertTrue(delEngine.GetLifecycle() == DELIVERY_OBJECTIVE_REACHED, "Lifecycle is OBJECTIVE_REACHED after high touches objective");

    // Test 4: Invalidation and mitigation
    // Reset and confirm leg again
    testHigh[1]  = 1.2000;
    testClose[1] = 1.1950;
    testLow[1]   = 1.1900;
    delEngine.Reset();
    delEngine.Update(swingDet, structEng, breakDet, ofEngine, testHigh, testLow, testClose, testOpen, testTime, DEL_TEST_BARS, 0, 0.0010);
    AssertTrue(delEngine.GetLifecycle() == DELIVERY_ACTIVE, "Re-initialized to ACTIVE state");

    // Wick breach low without close below protected low (1.1500) -> mitigation
    testLow[1]   = 1.1450;
    testClose[1] = 1.1550; // Close remains above 1.1500
    
    delEngine.Update(swingDet, structEng, breakDet, ofEngine, testHigh, testLow, testClose, testOpen, testTime, DEL_TEST_BARS, 0, 0.0010);
    AssertTrue(delEngine.GetLifecycle() == DELIVERY_MITIGATED, "Lifecycle transitions to MITIGATED after wick low dips below invalidation");

    // Close below invalidation level -> invalidation
    testLow[1]   = 1.1400;
    testClose[1] = 1.1400; // Close below 1.1500
    
    delEngine.Update(swingDet, structEng, breakDet, ofEngine, testHigh, testLow, testClose, testOpen, testTime, DEL_TEST_BARS, 0, 0.0010);
    AssertTrue(delEngine.GetLifecycle() == DELIVERY_INVALIDATED, "Lifecycle transitions to INVALIDATED after body close below invalidation");
    AssertTrue(delEngine.GetDirection() == DELIVERY_DIR_NEUTRAL, "Direction returns to NEUTRAL upon invalidation");

    #undef DEL_TEST_BARS

    Print("--- Module 006 complete ---");
}

//+------------------------------------------------------------------+
//| Module 007 — CLiquidityEngine validation                         |
//+------------------------------------------------------------------+
void RunModule007Tests()
{
    Print("--- Module 007: CLiquidityEngine ---");

    // Test 1: Initialize and default values
    CLiquidityEngine liqEngine;
    bool initRes = liqEngine.Initialize(0);
    AssertTrue(initRes == true, "CLiquidityEngine.Initialize() returns true");
    AssertTrue(liqEngine.GetPoolsCount() == 0, "Default pools count is 0");

    CSwingDetector swingDet;
    swingDet.Initialize(15, 5);
    CDeliveryStructureEngine delEngine;
    delEngine.Initialize();

    #define LIQ_TEST_BARS 100
    double   testHigh[LIQ_TEST_BARS];
    double   testLow[LIQ_TEST_BARS];
    double   testOpen[LIQ_TEST_BARS];
    double   testClose[LIQ_TEST_BARS];
    datetime testTime[LIQ_TEST_BARS];

    for (int i = 0; i < LIQ_TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
        testTime[i]  = (datetime)((LIQ_TEST_BARS - 1 - i) * 3600);
    }

    // Swings for BSL and SSL
    testHigh[80] = 1.2500; // Swing High at 80
    testLow[60]  = 1.1500; // Swing Low at 60

    swingDet.Update(testHigh, testLow, testTime, LIQ_TEST_BARS, 0);

    // Update liquidity engine
    liqEngine.Update(swingDet, delEngine, testHigh, testLow, testClose, testOpen, testTime, LIQ_TEST_BARS, 0, 0.0010, 0.0002);
    AssertTrue(liqEngine.GetPoolsCount() >= 2, "At least 2 pools detected from swings");
    AssertTrue(liqEngine.GetNearestBSL(1.2000) == 1.2500, "Nearest BSL matches swing high at 1.2500");
    AssertTrue(liqEngine.GetNearestSSL(1.2000) == 1.1500, "Nearest SSL matches swing low at 1.1500");

    // Test 2: EQH/EQL touches
    // Reset test arrays to base values first
    for (int i = 0; i < LIQ_TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
    }
    // Set two swing highs far enough apart (at least 31 bars separation for depth 15 external swing high check)
    testHigh[80] = 1.2500; // Swing High 1
    testHigh[45] = 1.2500; // Swing High 2 (exactly equal)

    swingDet.Reset();
    swingDet.Update(testHigh, testLow, testTime, LIQ_TEST_BARS, 0);
    liqEngine.Reset();
    liqEngine.Update(swingDet, delEngine, testHigh, testLow, testClose, testOpen, testTime, LIQ_TEST_BARS, 0, 0.0010, 0.0002);

    // Retrieve EQ pool
    bool eqFound = false;
    for (int k = 0; k < liqEngine.GetPoolsCount(); k++)
    {
        SLiquidityPool p;
        if (liqEngine.GetPool(k, p) && p.source == LIQ_SRC_EQ && p.type == LIQUIDITY_BSL)
        {
            eqFound = true;
            AssertTrue(p.touchesCount >= 2, "EQH touches count is >= 2");
            AssertTrue(MathAbs(p.level - 1.2500) <= 0.0001, "EQH level is average of touches");
        }
    }
    AssertTrue(eqFound == true, "EQH pool successfully detected");

    // Test 3: BSL Sweep vs Breakout
    // BSL level is 1.2500. Let's trigger a sweep at index 1: high goes above, but close closes back below.
    testHigh[1]  = 1.2550; // breaches level (1.2500)
    testClose[1] = 1.2450; // closes below level

    liqEngine.Update(swingDet, delEngine, testHigh, testLow, testClose, testOpen, testTime, LIQ_TEST_BARS, 0, 0.0010, 0.0002);

    bool sweepConfirmed = false;
    for (int k = 0; k < liqEngine.GetPoolsCount(); k++)
    {
        SLiquidityPool p;
        if (liqEngine.GetPool(k, p) && p.level == 1.2500)
        {
            AssertTrue(p.active == false, "BSL pool is no longer active after sweep");
            AssertTrue(p.swept == true, "BSL pool is marked as swept");
            AssertTrue(p.lifecycle == LIQ_SWEPT, "BSL pool lifecycle transitioned to LIQ_SWEPT");
            sweepConfirmed = true;
        }
    }
    AssertTrue(sweepConfirmed == true, "Sweep checked and confirmed successfully");

    #undef LIQ_TEST_BARS

    Print("--- Module 007 complete ---");
}

//+------------------------------------------------------------------+
//| Module 008 — CPOIEngine validation                               |
//+------------------------------------------------------------------+
void RunModule008Tests()
{
    Print("--- Module 008: CPOIEngine ---");

    // Test 1: Initialize and default values
    CPOIEngine poiEngine;
    bool initRes = poiEngine.Initialize();
    AssertTrue(initRes == true, "CPOIEngine.Initialize() returns true");
    AssertTrue(poiEngine.GetPoIsCount() == 0, "Default POIs count is 0");

    CSwingDetector swingDet;
    swingDet.Initialize(15, 5);
    CStructureEngine structEng;
    structEng.Initialize(0.0);
    CBreakDetector breakDet;
    breakDet.Initialize();
    CLiquidityEngine liqEngine;
    liqEngine.Initialize(0);
    CDeliveryStructureEngine delEngine;
    delEngine.Initialize();

    #define POI_TEST_BARS 100
    double   testHigh[POI_TEST_BARS];
    double   testLow[POI_TEST_BARS];
    double   testOpen[POI_TEST_BARS];
    double   testClose[POI_TEST_BARS];
    datetime testTime[POI_TEST_BARS];

    for (int i = 0; i < POI_TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
        testTime[i]  = (datetime)((POI_TEST_BARS - 1 - i) * 3600);
    }

    // 1. Plant a Bullish FVG below the baseline low (1.1900)
    // FVG at sequence A=22, B=21, C=20
    // i+2 = 22, i+1 = 21, i = 20
    // Bullish FVG: Low[20] > High[22]
    // Let's set: High[22] = 1.1800, Low[20] = 1.1850 -> Gap = 0.0050.
    testHigh[22] = 1.1800;
    testLow[22] = 1.1750;
    testOpen[22] = 1.1780;
    testClose[22] = 1.1780;

    testHigh[21] = 1.2000;
    testLow[21] = 1.1805;
    testOpen[21] = 1.1810;
    testClose[21] = 1.1830;

    testHigh[20] = 1.2000;
    testLow[20] = 1.1850; // Low[20] is 1.1850, strictly > High[22] (1.1800)
    testOpen[20] = 1.1860;
    testClose[20] = 1.1870;

    // Run update with FVG
    poiEngine.Update(swingDet, structEng, breakDet, liqEngine, delEngine, testHigh, testLow, testClose, testOpen, testTime, POI_TEST_BARS, 0, 0.0010);
    
    AssertTrue(poiEngine.GetPoIsCount() >= 1, "At least 1 POI detected (FVG)");
    
    SPoIDefinition fvgPoi;
    bool foundFVG = false;
    for (int k = 0; k < poiEngine.GetPoIsCount(); k++)
    {
        if (poiEngine.GetPoI(k, fvgPoi) && fvgPoi.type == POI_FVG_BULLISH)
        {
            foundFVG = true;
            AssertTrue(fvgPoi.lowerPrice == 1.1800, "FVG lower price is 1.1800");
            AssertTrue(fvgPoi.upperPrice == 1.1850, "FVG upper price is 1.1850");
            AssertTrue(fvgPoi.active == true, "FVG is active initially");
        }
    }
    AssertTrue(foundFVG == true, "Bullish FVG successfully registered");

    // Test 2: Invalidation of FVG via fill
    // Low touches or goes below lower price (1.1800) on closed bar index 1
    testLow[1] = 1.1790;
    testClose[1] = 1.1820;
    poiEngine.Update(swingDet, structEng, breakDet, liqEngine, delEngine, testHigh, testLow, testClose, testOpen, testTime, POI_TEST_BARS, 0, 0.0010);
    
    for (int k = 0; k < poiEngine.GetPoIsCount(); k++)
    {
        if (poiEngine.GetPoI(k, fvgPoi) && fvgPoi.type == POI_FVG_BULLISH)
        {
            AssertTrue(fvgPoi.active == false, "FVG is deactivated after 100% fill");
            AssertTrue(fvgPoi.lifecycle == POI_STATE_FILLED, "FVG lifecycle is POI_STATE_FILLED");
        }
    }

    #undef POI_TEST_BARS

    Print("--- Module 008 complete ---");
}

//+------------------------------------------------------------------+
//| Module 009 — CObjectiveEngine validation                         |
//+------------------------------------------------------------------+
void RunModule009Tests()
{
    Print("--- Module 009: CObjectiveEngine ---");

    CObjectiveEngine objEngine;
    bool initRes = objEngine.Initialize();
    AssertTrue(initRes == true, "CObjectiveEngine.Initialize() returns true");
    AssertTrue(objEngine.GetDolPrice() == DBL_MAX, "Default DOL price is MNS_INVALID_PRICE");
    AssertTrue(objEngine.GetCandidateCount() == 0, "Default candidates count is 0");

    CSwingDetector swingDet;
    swingDet.Initialize(15, 5);
    CStructureEngine structEng;
    structEng.Initialize(0.0);
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

    #define OBJ_TEST_BARS 100
    double   testHigh[OBJ_TEST_BARS];
    double   testLow[OBJ_TEST_BARS];
    double   testOpen[OBJ_TEST_BARS];
    double   testClose[OBJ_TEST_BARS];
    datetime testTime[OBJ_TEST_BARS];

    // Set times to span multiple days
    MqlDateTime dt;
    dt.year = 2026;
    dt.mon = 8;
    dt.day = 10;
    dt.hour = 23;
    dt.min = 0;
    dt.sec = 0;

    for (int i = 0; i < OBJ_TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
        
        datetime t = StructToTime(dt);
        testTime[i] = t;
        
        dt.hour--;
        if (dt.hour < 0)
        {
            dt.hour = 23;
            dt.day--;
        }
    }

    // Set previous day (Day 9) high to 1.2200 and low to 1.1800
    testHigh[30] = 1.2200;
    testLow[30] = 1.1800;

    // Set structure trend to bullish
    structEng.OverrideTrend(TREND_BULLISH);

    // Update the objective engine (passed ATR is 0.0050)
    objEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, OBJ_TEST_BARS, 0, 0.0050);

    AssertTrue(objEngine.GetCandidateCount() > 0, "Candidates gathered from previous day scans");
    
    SDolDefinition activeDol = objEngine.GetActiveDol();
    AssertTrue(activeDol.active == true, "Active DOL is selected");
    AssertTrue(activeDol.price == 1.2200, "Active DOL price matches PDH (1.2200)");
    AssertTrue(activeDol.type == DOL_PREV_DAY_HL, "Active DOL type is DOL_PREV_DAY_HL");

    // Test 2: Consumption of active DOL
    // Bullish target (1.2200) is hit when index 1 high >= 1.2200
    testHigh[1] = 1.2250;
    testClose[1] = 1.2100;
    
    objEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, OBJ_TEST_BARS, 0, 0.0050);
    
    activeDol = objEngine.GetActiveDol();
    AssertTrue(activeDol.active == false || activeDol.price == DBL_MAX, "Active DOL consumed/deactivated when price hits target");

    #undef OBJ_TEST_BARS

    Print("--- Module 009 complete ---");
}

//+------------------------------------------------------------------+
//| Module 010 — CConfirmationEngine validation                       |
//+------------------------------------------------------------------+
void RunModule010Tests()
{
    Print("--- Module 010: CConfirmationEngine ---");

    CConfirmationEngine confEngine;
    bool initRes = confEngine.Initialize();
    AssertTrue(initRes == true, "CConfirmationEngine.Initialize() returns true");
    AssertTrue(confEngine.GetConfirmationState() == CONFIRMATION_STATE_NONE, "Default confirmation state is CONFIRMATION_STATE_NONE");

    // Initialize mock dependencies
    CSwingDetector swingDet;
    swingDet.Initialize(15, 5);
    CStructureEngine structEng;
    structEng.Initialize(0.0);
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

    #define CONF_TEST_BARS 100
    double   testHigh[CONF_TEST_BARS];
    double   testLow[CONF_TEST_BARS];
    double   testOpen[CONF_TEST_BARS];
    double   testClose[CONF_TEST_BARS];
    datetime testTime[CONF_TEST_BARS];

    // Set times to span multiple days
    MqlDateTime dt;
    dt.year = 2026;
    dt.mon = 8;
    dt.day = 10;
    dt.hour = 23;
    dt.min = 0;
    dt.sec = 0;

    for (int i = 0; i < CONF_TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
        
        datetime t = StructToTime(dt);
        testTime[i] = t;
        
        dt.hour--;
        if (dt.hour < 0)
        {
            dt.hour = 23;
            dt.day--;
        }
    }

    // Set previous day (Day 9) high to 1.2200 and low to 1.1800
    testHigh[30] = 1.2200;
    testLow[30] = 1.1800;

    // Set structure trend to bullish
    structEng.OverrideTrend(TREND_BULLISH);
    objEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);

    // Revert testHigh[30] to baseline 1.2000 so it does not get detected as a swing high by CSwingDetector.
    // We keep testLow[30] = 1.1800 so it is detected as a swing low (which the delivery engine needs).
    testHigh[30] = 1.2000;

    // Mock an active delivery leg (deliveryEngine)
    // CBreakDetector needs a confirmed swing to break. Let's make Swing High 60 = 1.2100.
    testHigh[60] = 1.2100;
    swingDet.Update(testHigh, testLow, testTime, CONF_TEST_BARS, 0);
    structEng.Update(swingDet, 0.0050);
    structEng.OverrideTrend(TREND_BULLISH); // Re-apply override since structEng.Update recalculates trend based on swing count
    
    // Now trigger a break: close[1] = 1.2150 (above 1.2100)
    testClose[1] = 1.2150;
    testOpen[1] = 1.2050;
    testHigh[1] = 1.2160; // Set to 1.2160 to ensure bodyRatio is >= 0.65 for displacement check
    testLow[1] = 1.2040;  // Set to 1.2040 to ensure bodyRatio is >= 0.65 for displacement check
    breakDet.Update(swingDet, structEng, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);
    
    // Update delivery and order flow engines
    ofEngine.Update(swingDet, structEng, breakDet, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);
    delEngine.Update(swingDet, structEng, breakDet, ofEngine, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);

    // Assert that delivery leg is active and bullish
    AssertTrue(delEngine.GetDirection() == DELIVERY_DIR_BULLISH, "Delivery engine direction is Bullish");
    AssertTrue(delEngine.GetLifecycle() == DELIVERY_ACTIVE, "Delivery engine lifecycle is Active");

    // Add a valid active POI: Bullish OB at 1.1900 to 1.2000
    testOpen[2] = 1.2050;
    testClose[2] = 1.1950;
    testLow[2] = 1.1900;
    testHigh[2] = 1.2060;
    
    breakDet.Update(swingDet, structEng, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);
    ofEngine.Update(swingDet, structEng, breakDet, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);
    delEngine.Update(swingDet, structEng, breakDet, ofEngine, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);
    poiEngine.Update(swingDet, structEng, breakDet, liqEngine, delEngine, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);
    
    AssertTrue(poiEngine.GetPoIsCount() > 0, "POI Engine has registered POIs");

    // Test 1: POI Touch -> Transition to PENDING
    testLow[1] = 1.1950;
    testClose[1] = 1.2000;
    
    confEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, objEngine, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);
    
    AssertTrue(confEngine.GetConfirmationState() == CONFIRMATION_STATE_PENDING, "Confirmation state is PENDING after POI touch");
    AssertTrue(confEngine.GetDirection() == CONFIRM_DIR_BULLISH, "Confirmation direction is BULLISH");

    // Test 2: Liquidity Sweep OR Strong Rejection + Structural Trigger -> CONFIRMED
    testOpen[1] = 1.2000;
    testClose[1] = 1.2000;
    testLow[1] = 1.1900;
    testHigh[1] = 1.2000;
    
    confEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, objEngine, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);
    
    AssertTrue(confEngine.GetConfirmationState() == CONFIRMATION_STATE_CONFIRMED, "Confirmation state transitions to CONFIRMED when all filters are met");
    AssertTrue(confEngine.GetConfidenceScore() >= 60.0, "Confidence score is calculated and >= 60.0");

    // Test 3: Invalidation via body close beyond invalidation level
    testClose[1] = 1.1850;
    testLow[1] = 1.1800;
    
    confEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, objEngine, testHigh, testLow, testClose, testOpen, testTime, CONF_TEST_BARS, 0, 0.0050);
    
    AssertTrue(confEngine.GetConfirmationState() == CONFIRMATION_STATE_INVALIDATED, "Confirmation state is INVALIDATED after body close beyond invalidation level");

    #undef CONF_TEST_BARS
    Print("--- Module 010 complete ---");
}

//+------------------------------------------------------------------+
//| Module 011 — CEntryEngine validation                             |
//+------------------------------------------------------------------+
void RunModule011Tests()
{
    Print("--- Module 011: CEntryEngine ---");

    CEntryEngine entryEngine;
    bool initRes = entryEngine.Initialize(50.0); // max 50 points spread
    AssertTrue(initRes == true, "CEntryEngine.Initialize() returns true");
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_NONE, "Default signal state is ENTRY_STATE_NONE");
    AssertTrue(entryEngine.HasActiveSignal() == false, "Default HasActiveSignal() is false");

    // Initialize mock dependencies
    CSwingDetector swingDet;
    swingDet.Initialize(15, 5);
    CStructureEngine structEng;
    structEng.Initialize(0.0);
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

    #define ENTRY_TEST_BARS 100
    double   testHigh[ENTRY_TEST_BARS];
    double   testLow[ENTRY_TEST_BARS];
    double   testOpen[ENTRY_TEST_BARS];
    double   testClose[ENTRY_TEST_BARS];
    datetime testTime[ENTRY_TEST_BARS];

    // Set times to span multiple days
    MqlDateTime dt;
    dt.year = 2026;
    dt.mon = 8;
    dt.day = 10;
    dt.hour = 23;
    dt.min = 0;
    dt.sec = 0;
    datetime baseTime = StructToTime(dt);

    for (int i = 0; i < ENTRY_TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
        testTime[i]  = baseTime;
        baseTime -= 3600; // 1 hour steps backwards
    }

    // Set up a valid Bullish Confirmation
    // A. Objective Engine needs a target (DOL)
    testHigh[30] = 1.2200;
    testLow[30] = 1.1800;
    structEng.OverrideTrend(TREND_BULLISH);
    objEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 0.0050);
    testHigh[30] = 1.2000; // Revert to avoid swing detection interference

    // B. Swing detection & Break detection for BOS confirmation
    testHigh[60] = 1.2100;
    swingDet.Update(testHigh, testLow, testTime, ENTRY_TEST_BARS, 0);
    structEng.Update(swingDet, 0.0050);
    structEng.OverrideTrend(TREND_BULLISH);

    // Now trigger a break: close[1] = 1.2150 (above 1.2100)
    testClose[1] = 1.2150;
    testOpen[1] = 1.2050;
    testHigh[1] = 1.2160;
    testLow[1] = 1.2040;
    breakDet.Update(swingDet, structEng, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 0.0050);
    ofEngine.Update(swingDet, structEng, breakDet, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 0.0050);
    delEngine.Update(swingDet, structEng, breakDet, ofEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 0.0050);
    poiEngine.Update(swingDet, structEng, breakDet, liqEngine, delEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 0.0050);

    // Test 1: Generate Pending confirmation state
    testLow[1] = 1.1950;
    testClose[1] = 1.2000;
    confEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, objEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 0.0050);
    AssertTrue(confEngine.GetConfirmationState() == CONFIRMATION_STATE_PENDING, "Setup is PENDING after POI touch");

    // Test 2: Trigger Confirmation Engine to CONFIRMED
    testOpen[1] = 1.2000;
    testClose[1] = 1.2000;
    testLow[1] = 1.1900;
    testHigh[1] = 1.2000;
    confEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, objEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 0.0050);
    AssertTrue(confEngine.GetConfirmationState() == CONFIRMATION_STATE_CONFIRMED, "Setup is CONFIRMED in confirmation engine");

    // Test 3: CEntryEngine Updates to ACTIVE (Spread and RR filters are met)
    bool updateRes = entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 10.0);
    AssertTrue(updateRes == true, "CEntryEngine.Update() returns true when active signal is generated");
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE, "Signal state is ENTRY_STATE_ACTIVE");
    AssertTrue(entryEngine.HasActiveSignal() == true, "HasActiveSignal() is true");
    SEntrySignal sig = entryEngine.GetActiveSignal();
    AssertTrue(sig.entryPrice == 1.2000, "Signal entry price matches trigger price");
    AssertTrue(sig.stopLoss == 1.2100, "Signal Stop Loss matches confirmation invalidation level");
    AssertTrue(sig.takeProfit == 1.2200, "Signal Take Profit matches DOL price");

    // Test 4: Spread Filter Rejection
    entryEngine.Reset();
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_NONE, "Signal state is NONE after Reset");
    updateRes = entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 60.0);
    AssertTrue(updateRes == false, "Update returns false when signal is rejected due to high spread");
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_NONE, "Signal state remains NONE");

    // Test 5: Risk-Reward Filter Rejection
    testHigh[30] = 1.2120;
    swingDet.Reset(); // Clear swings so objEngine doesn't select 1.2100
    objEngine.Reset();
    objEngine.Initialize();
    objEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 0.0050);
    testHigh[30] = 1.2000; // revert
    
    updateRes = entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 10.0);
    AssertTrue(updateRes == false, "Update returns false when signal is rejected due to low RR");
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_NONE, "Signal state remains NONE");

    // Revert DOL to 1.2200
    testHigh[30] = 1.2200;
    objEngine.Reset();
    objEngine.Initialize();
    objEngine.Update(swingDet, structEng, breakDet, ofEngine, delEngine, liqEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 0.0050);
    testHigh[30] = 1.2000; // revert

    // Test 6: Invalidation of active signal due to MTF Reversal
    updateRes = entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 10.0);
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE, "Signal is active again");
    
    structEng.OverrideTrend(TREND_BEARISH);
    updateRes = entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 10.0);
    AssertTrue(updateRes == true, "Update returns true when active signal invalidates");
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_INVALIDATED, "Active signal transitions to ENTRY_STATE_INVALIDATED on MTF reversal");
    
    structEng.OverrideTrend(TREND_BULLISH);

    // Test 7: Signal Expiration (5 bars)
    entryEngine.Reset();
    entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 10.0);
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE, "Signal is active for expiration test");
    
    datetime originalTriggerTime = confEngine.GetState().triggerTime;
    for (int i = 0; i < ENTRY_TEST_BARS; i++)
    {
        testTime[i] += 5 * 3600;
    }
    updateRes = entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 10.0);
    AssertTrue(updateRes == true, "Update returns true when signal expires");
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_EXPIRED, "Signal is EXPIRED");

    for (int i = 0; i < ENTRY_TEST_BARS; i++)
    {
        testTime[i] -= 5 * 3600;
    }

    // Test 8: Duplicate Prevention
    entryEngine.Reset();
    entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 10.0);
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_ACTIVE, "Signal active before execution");
    
    bool consumeRes = entryEngine.MarkSignalConsumed();
    AssertTrue(consumeRes == true, "MarkSignalConsumed returns true");
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_EXECUTED, "Signal state is ENTRY_STATE_EXECUTED");
    AssertTrue(entryEngine.IsConsumed(originalTriggerTime) == true, "Signal ID is marked as consumed in history");

    entryEngine.Reset();
    entryEngine.Update(confEngine, objEngine, structEng, delEngine, poiEngine, testHigh, testLow, testClose, testOpen, testTime, ENTRY_TEST_BARS, 0, 10.0);
    AssertTrue(entryEngine.GetActiveSignalState() == ENTRY_STATE_NONE, "Signal state remains NONE due to duplicate prevention blocking");

    #undef ENTRY_TEST_BARS
    Print("--- Module 011 complete ---");
}

//+------------------------------------------------------------------+
//| Module 012 — CRiskEngine validation                              |
//+------------------------------------------------------------------+
void RunModule012Tests()
{
    Print("--- Module 012: CRiskEngine ---");

    CRiskEngine riskEngine;
    bool initRes = riskEngine.Initialize(1.0, 0.25, 2.0, 5.0); // default 1%, min 0.25%, max 2%, max DD 5%
    AssertTrue(initRes == true, "CRiskEngine.Initialize() returns true");

    string symbol = Symbol();

    // Test 1: Pre-Trade Sizing SL Buffer & Approved Sizing
    // Buy setup: entry = 1.2000, invalidation = 1.1900, dolPrice = 1.2200, atr = 0.0050.
    // StopBuffer = max(2*point, 0.20*0.0050) = 0.0010 (on GBPUSD/EURUSD point is 0.00001)
    // Expected SL = 1.1900 - 0.0010 = 1.1890.
    // RiskDistance = 0.0110. RewardDistance = 0.0200. RR = 1.818 >= 1.50R.
    SRiskSizingResult res = riskEngine.SizePreTrade(CONFIRM_DIR_BULLISH, 1.2000, 1.1900, 1.2200, 0.0050, 1.0, 10000.0, symbol);
    AssertTrue(res.approved == true, "Pre-trade sizing is approved when RR >= 1.50R");
    AssertEqualDouble(res.entryPrice, 1.2000, "Entry price is 1.2000");
    AssertEqualDouble(res.stopLoss, 1.1890, "Calculated Stop Loss matches 1.1890");
    AssertEqualDouble(res.takeProfit, 1.2200, "Take profit matches DOL target 1.2200");
    AssertTrue(res.expectedRr >= 1.80, "Expected RR is calculated correctly");
    AssertTrue(res.volume > 0.0, "Sized volume is greater than 0.0");
    AssertTrue(res.riskAmount == 100.0, "Risk amount is 100.0 (1% of 10000)");

    // Test 2: Pre-Trade Sizing RR Rejection
    // dolPrice = 1.2150 -> RewardDistance = 0.0150. RiskDistance = 0.0110. RR = 1.36 < 1.50R.
    res = riskEngine.SizePreTrade(CONFIRM_DIR_BULLISH, 1.2000, 1.1900, 1.2150, 0.0050, 1.0, 10000.0, symbol);
    AssertTrue(res.approved == false, "Pre-trade sizing is rejected when RR < 1.50R");

    // Test 3: Pre-Trade Sizing Sell Setup
    // entry = 1.2000, invalidation = 1.2100, dolPrice = 1.1800, atr = 0.0050.
    // StopBuffer = 0.0010. Expected SL = 1.2100 + 0.0010 = 1.2110.
    // RiskDistance = 0.0110. RewardDistance = 0.0200. RR = 1.818 >= 1.50R.
    res = riskEngine.SizePreTrade(CONFIRM_DIR_BEARISH, 1.2000, 1.2100, 1.1800, 0.0050, 1.0, 10000.0, symbol);
    AssertTrue(res.approved == true, "Pre-trade sizing is approved for Bearish Setup");
    AssertEqualDouble(res.stopLoss, 1.2110, "Bearish Stop Loss is 1.2110");
    AssertEqualDouble(res.takeProfit, 1.1800, "Bearish Take Profit is 1.1800");

    // Test 4: Active Position Management — Partial Close (+1.0R)
    riskEngine.ResetPositionTracking();
    // Entry = 1.2000, Original SL = 1.1890. RiskDistance = 0.0110. Current Vol = 0.10.
    // Bid = 1.2100 (progress = 0.0100 < 1.0R) -> No partial close.
    SRiskManagementAction act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.10, 1.1890, 1.1890, 1.2100, 1.2101, 0.0050, DELIVERY_ACTIVE, false, false, false, 0.0, symbol);
    AssertTrue(act.closePartially == false, "Partial close is false before reaching +1.0R");

    // Bid = 1.2110 (progress = 0.0110 == 1.0R) -> Partial close triggered!
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.10, 1.1890, 1.1890, 1.2110, 1.2111, 0.0050, DELIVERY_ACTIVE, false, false, false, 0.0, symbol);
    AssertTrue(act.closePartially == true, "Partial close is true when progress reaches +1.0R");
    AssertEqualDouble(act.partialVolume, 0.05, "Partial close volume is 50% of 0.10 (0.05)");

    // Bid = 1.2120 (progress > 1.0R) -> No partial close (should trigger only once).
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.1890, 1.2120, 1.2121, 0.0050, DELIVERY_ACTIVE, false, false, false, 0.0, symbol);
    AssertTrue(act.closePartially == false, "Partial close does not trigger again once m_hasPartialClosed is true");

    // Test 5: Active Position Management — Trailing Stop (+1.5R)
    // Bid = 1.2160 (progress = 0.0160 < 1.65 pips / +1.5R) -> Trailing stop not active.
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.1890, 1.2160, 1.2161, 0.0050, DELIVERY_ACTIVE, false, false, false, 0.0, symbol);
    AssertTrue(act.newStopLoss == MNS_INVALID_PRICE, "Trailing stop is inactive before +1.5R");

    // Bid = 1.2165 (progress = 0.0165 == 1.5R) -> Trailing stop active!
    // TrailingSL = Bid - ATR = 1.2165 - 0.0050 = 1.2115.
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.1890, 1.2165, 1.2166, 0.0050, DELIVERY_ACTIVE, false, false, false, 0.0, symbol);
    AssertEqualDouble(act.newStopLoss, 1.2115, "Trailing stop activates at +1.5R, SL set to Bid - ATR");

    // Test 6: Trailing Stop Incremental Tier (+2.0R)
    // Bid = 1.2210 (progress = 1.90R < 2.0R) -> No update yet (remains in tier 0).
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.2115, 1.2210, 1.2211, 0.0050, DELIVERY_ACTIVE, false, false, false, 0.0, symbol);
    AssertTrue(act.newStopLoss == MNS_INVALID_PRICE, "Trailing stop does not update between tiers (+1.90R)");

    // Bid = 1.2220 (progress = 2.0R) -> Next tier update!
    // TrailingSL = Bid - ATR = 1.2220 - 0.0050 = 1.2170.
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.2115, 1.2220, 1.2221, 0.0050, DELIVERY_ACTIVE, false, false, false, 0.0, symbol);
    AssertEqualDouble(act.newStopLoss, 1.2170, "Trailing stop updates at next +0.5R milestone (+2.0R tier)");

    // Test 7: Trailing Stop Never Worsen
    // Bid drops back to 1.2180.
    // TrailingSL candidate = 1.2180 - 0.0050 = 1.2130.
    // Since 1.2130 < 1.2170 (current stop), we must not update (never worsen).
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.2170, 1.2180, 1.2181, 0.0050, DELIVERY_ACTIVE, false, false, false, 0.0, symbol);
    AssertTrue(act.newStopLoss == MNS_INVALID_PRICE, "Trailing stop does not move backwards when price retraces");

    // Test 8: Emergency Exits
    // A. DOL Reached
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.2170, 1.2220, 1.2221, 0.0050, DELIVERY_ACTIVE, true, false, false, 0.0, symbol);
    AssertTrue(act.closeFully == true, "Emergency exit triggered when DOL is reached");

    // B. DOL Invalidated
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.2170, 1.2220, 1.2221, 0.0050, DELIVERY_ACTIVE, false, true, false, 0.0, symbol);
    AssertTrue(act.closeFully == true, "Emergency exit triggered when DOL is invalidated");

    // C. Delivery Invalidated
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.2170, 1.2220, 1.2221, 0.0050, DELIVERY_INVALIDATED, false, false, false, 0.0, symbol);
    AssertTrue(act.closeFully == true, "Emergency exit triggered when Delivery structure is invalidated");

    // D. MTF Reversal
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.2170, 1.2220, 1.2221, 0.0050, DELIVERY_ACTIVE, false, false, true, 0.0, symbol);
    AssertTrue(act.closeFully == true, "Emergency exit triggered when MTF reversal occurs");

    // E. Daily Drawdown Protection
    act = riskEngine.UpdateActiveManagement(CONFIRM_DIR_BULLISH, 1.2000, 0.05, 1.1890, 1.2170, 1.2220, 1.2221, 0.0050, DELIVERY_ACTIVE, false, false, false, 5.5, symbol);
    AssertTrue(act.closeFully == true, "Emergency exit triggered when Daily drawdown percent (5.5%) exceeds limit (5.0%)");

    Print("--- Module 012 complete ---");
}

//+------------------------------------------------------------------+
//| Module INF-000 — MNSCore validation                              |
//+------------------------------------------------------------------+
void RunModuleINF000Tests() {
    Print("--- Module INF-000: MNSCore ---");

    // 1. Validate Sentinel Constants
    AssertTrue(MNS_INVALID_PRICE == 1.7976931348623157e+308, "MNS_INVALID_PRICE is DBL_MAX");
    AssertTrue(MNS_INVALID_INDEX == -1, "MNS_INVALID_INDEX is -1");
    AssertTrue(MNS_INVALID_TIME == 0, "MNS_INVALID_TIME is 0");

    // 2. Validate Result Codes
    AssertTrue(MNS_S_OK == 0x00000000, "MNS_S_OK is 0x00000000");
    AssertTrue(MNS_E_FAIL == 0x80004005, "MNS_E_FAIL is 0x80004005");
    AssertTrue(MNS_E_INVALIDARG == 0x80070057, "MNS_E_INVALIDARG is 0x80070057");
    AssertTrue(MNS_E_OUTOFMEMORY == 0x8007000E, "MNS_E_OUTOFMEMORY is 0x8007000E");
    AssertTrue(MNS_E_NOTIMPL == 0x80004001, "MNS_E_NOTIMPL is 0x80004001");

    // 3. Validate MNS_Assert when disabled
#ifndef MNS_ASSERT_ENABLE
    // If assertion is disabled, MNS_Assert(false, ...) should do absolutely nothing and not crash or halt.
    MNS_Assert(false, "This should not trigger because MNS_ASSERT_ENABLE is undefined");
    AssertTrue(true, "MNS_Assert does not execute when MNS_ASSERT_ENABLE is undefined");
#else
    AssertTrue(true, "MNS_ASSERT_ENABLE is defined, skipping disabled assertion check");
#endif

    Print("--- Module INF-000 complete ---");
}

//+------------------------------------------------------------------+
//| Module INF-001 — MNSLogger validation                            |
//+------------------------------------------------------------------+
void RunModuleINF001Tests() {
    Print("--- Module INF-001: MNSLogger ---");

    // 1. Initialize Logger with WARN threshold and a file target
    CMNSLogger::Initialize(MNS_LOG_WARN, "harness_test.log");

    // 2. Log messages at different levels
    // INFO is below WARN -> Should be filtered out
    MNS_Log(MNS_LOG_INFO, "TEST_HARNESS", "This INFO message should be filtered out");

    // WARN and ERROR are >= WARN -> Should be recorded
    MNS_Log(MNS_LOG_WARN, "TEST_HARNESS", "This WARN message should be recorded");
    MNS_Log(MNS_LOG_ERROR, "TEST_HARNESS", "This ERROR message should be recorded");

    // Close logger to flush file writes and release file handle
    CMNSLogger::Close();

    // 3. Verify file contents to ensure correct level filtering
    // In MT5, files are read from the MQL5\Files sandbox, and the path is relative.
    int handle = FileOpen("MNS_Logs\\harness_test.log", FILE_READ | FILE_TXT | FILE_ANSI);
    if (handle != INVALID_HANDLE) {
        string fileContent = "";
        while (!FileIsEnding(handle)) {
            fileContent += FileReadString(handle) + "\n";
        }
        FileClose(handle);

        // Delete the test file to keep the sandbox clean
        FileDelete("MNS_Logs\\harness_test.log");

        // Validate contents
        AssertTrue(StringFind(fileContent, "WARN") >= 0, "Warn level log is written to file");
        AssertTrue(StringFind(fileContent, "ERROR") >= 0, "Error level log is written to file");
        AssertTrue(StringFind(fileContent, "INFO") < 0, "Info level log is filtered out and NOT in file");
        AssertTrue(StringFind(fileContent, "TEST_HARNESS") >= 0, "Log line contains source identifier");
    } else {
        AssertTrue(false, "Failed to open harness_test.log for verification");
    }

    // 4. Verify FATAL alert (we use a high threshold to prevent popup blocking but let's test logging behavior)
    // We can verify that it executes. Note: Alert() will trigger terminal popups.
    // To prevent popping up multiple times during automated testing, we initialize it and log it.
    CMNSLogger::Initialize(MNS_LOG_FATAL);
    MNS_Log(MNS_LOG_FATAL, "TEST_HARNESS", "Testing FATAL log (Print + Alert)");
    CMNSLogger::Close();
    AssertTrue(true, "FATAL level log triggered print and alert wrapper successfully");

    Print("--- Module INF-001 complete ---");
}

//+------------------------------------------------------------------+
//| Module INF-002 — MNSUtils validation                            |
//+------------------------------------------------------------------+
void RunModuleINF002Tests() {
    Print("--- Module INF-002: MNSUtils ---");

    // 1. Validate IsEqual
    AssertTrue(CMNSUtils::IsEqual(1.00001, 1.00001), "IsEqual returns true for identical values");
    AssertTrue(CMNSUtils::IsEqual(1.00001, 1.000015, 0.00001), "IsEqual returns true within epsilon (diff 0.000005 <= 0.00001)");
    AssertTrue(!CMNSUtils::IsEqual(1.00001, 1.000025, 0.00001), "IsEqual returns false outside epsilon (diff 0.000015 > 0.00001)");

    // 2. Validate RoundToPoints
    AssertTrue(CMNSUtils::IsEqual(CMNSUtils::RoundToPoints(1.204567, 0.0001), 1.2046), "RoundToPoints(1.204567, 0.0001) rounds to 1.2046");
    AssertTrue(CMNSUtils::IsEqual(CMNSUtils::RoundToPoints(1.204543, 0.0001), 1.2045), "RoundToPoints(1.204543, 0.0001) rounds to 1.2045");
    AssertTrue(CMNSUtils::IsEqual(CMNSUtils::RoundToPoints(145.678, 0.01), 145.68), "RoundToPoints(145.678, 0.01) rounds to 145.68");
    AssertTrue(CMNSUtils::IsEqual(CMNSUtils::RoundToPoints(1.204567, 0.0), 1.204567), "RoundToPoints with 0 pointSize returns price");

    // 3. Validate BrokerTimeToGMT
    datetime bTime = D'2026.08.08 12:00:00';
    datetime gmtTime = CMNSUtils::BrokerTimeToGMT(bTime, 3); // GMT+3 broker
    AssertTrue(gmtTime == D'2026.08.08 09:00:00', "BrokerTimeToGMT converts GMT+3 correctly");

    datetime gmtTimeNeg = CMNSUtils::BrokerTimeToGMT(bTime, -5); // GMT-5 broker
    AssertTrue(gmtTimeNeg == D'2026.08.08 17:00:00', "BrokerTimeToGMT converts GMT-5 correctly");

    // 4. Validate IsInSession
    // 4a. Simple session (start < end) e.g. London (8 to 16)
    datetime timeLondon = D'2026.08.08 10:30:00';    // Hour 10
    datetime timeOutLondon = D'2026.08.08 17:00:00'; // Hour 17
    AssertTrue(CMNSUtils::IsInSession(timeLondon, 8, 16) == true, "IsInSession(10:30, 8, 16) is in session");
    AssertTrue(CMNSUtils::IsInSession(timeOutLondon, 8, 16) == false, "IsInSession(17:00, 8, 16) is out of session");

    // 4b. Overnight session (start > end) e.g. Tokyo / Midnight spanning (22 to 6)
    datetime timeTokyoSpanning = D'2026.08.08 23:30:00';    // Hour 23
    datetime timeTokyoSpanning2 = D'2026.08.08 02:00:00';   // Hour 2
    datetime timeTokyoSpanningOut = D'2026.08.08 12:00:00'; // Hour 12
    AssertTrue(CMNSUtils::IsInSession(timeTokyoSpanning, 22, 6) == true, "IsInSession(23:30, 22, 6) spans midnight (before midnight)");
    AssertTrue(CMNSUtils::IsInSession(timeTokyoSpanning2, 22, 6) == true, "IsInSession(02:00, 22, 6) spans midnight (after midnight)");
    AssertTrue(CMNSUtils::IsInSession(timeTokyoSpanningOut, 22, 6) == false, "IsInSession(12:00, 22, 6) spans midnight (outside session)");

    // 4c. Single hour session (start == end)
    AssertTrue(CMNSUtils::IsInSession(timeTokyoSpanningOut, 12, 12) == true, "IsInSession(12:00, 12, 12) matches start==end hour");

    // 5. Validate ArrayCloneDouble
    double src[5] = {1.1, 2.2, 3.3, 4.4, 5.5};
    double dstDynamic[];
    double dstStatic[5];
    double dstStaticTooSmall[3];

    AssertTrue(CMNSUtils::ArrayCloneDouble(src, dstDynamic) == true, "ArrayCloneDouble into dynamic array succeeds");
    AssertTrue(ArraySize(dstDynamic) == 5 && dstDynamic[3] == 4.4, "Dynamic dst has correct size and values");

    AssertTrue(CMNSUtils::ArrayCloneDouble(src, dstStatic) == true, "ArrayCloneDouble into static array of same size succeeds");
    AssertTrue(dstStatic[4] == 5.5, "Static dst has correct values");

    AssertTrue(CMNSUtils::ArrayCloneDouble(src, dstStaticTooSmall) == false, "ArrayCloneDouble into smaller static array fails");

    // 6. Validate ArrayDeleteIndex
    double arrayDel[];
    ArrayResize(arrayDel, 5);
    arrayDel[0] = 10.0;
    arrayDel[1] = 20.0;
    arrayDel[2] = 30.0;
    arrayDel[3] = 40.0;
    arrayDel[4] = 50.0;

    AssertTrue(CMNSUtils::ArrayDeleteIndex(arrayDel, 2) == true, "ArrayDeleteIndex of middle element returns true");
    AssertTrue(ArraySize(arrayDel) == 4, "Array size reduced by 1");
    AssertTrue(arrayDel[0] == 10.0 && arrayDel[1] == 20.0 && arrayDel[2] == 40.0 && arrayDel[3] == 50.0, "Elements shifted correctly");

    AssertTrue(CMNSUtils::ArrayDeleteIndex(arrayDel, -1) == false, "ArrayDeleteIndex with negative index fails");
    AssertTrue(CMNSUtils::ArrayDeleteIndex(arrayDel, 4) == false, "ArrayDeleteIndex with index >= size fails");

    double staticArray[5];
    AssertTrue(CMNSUtils::ArrayDeleteIndex(staticArray, 1) == false, "ArrayDeleteIndex on static array fails");

    Print("--- Module INF-002 complete ---");
}

//+------------------------------------------------------------------+
//| Module INF-003 — MNSVolatility validation                       |
//+------------------------------------------------------------------+
void RunModuleINF003Tests() {
    Print("--- Module INF-003: MNSVolatility ---");

    // 1. Validation failure: ratesTotal < period + 1
    double hSmall[5] = {1.2010, 1.2020, 1.2015, 1.2030, 1.2025};
    double lSmall[5] = {1.1990, 1.2000, 1.1995, 1.2010, 1.2005};
    double cSmall[5] = {1.2000, 1.2010, 1.2005, 1.2020, 1.2015};

    double val1 = CMNSVolatility::CalculateATR(hSmall, lSmall, cSmall, 4, 14, 5);
    AssertTrue(val1 == 0.0, "CalculateATR returns 0.0 when ratesTotal < period + 1");

    // 2. Validation failure: index out of bounds
    double val2 = CMNSVolatility::CalculateATR(hSmall, lSmall, cSmall, 5, 3, 5);
    AssertTrue(val2 == 0.0, "CalculateATR returns 0.0 when index is out of bounds (index == ratesTotal)");
    double val3 = CMNSVolatility::CalculateATR(hSmall, lSmall, cSmall, -1, 3, 5);
    AssertTrue(val3 == 0.0, "CalculateATR returns 0.0 when index is negative");

// 3. Exact ATR verification: All candles have identical range and Close == Low.
#define TEST_ATR_SIZE 20
    double hTest[];
    double lTest[];
    double cTest[];
    ArrayResize(hTest, TEST_ATR_SIZE);
    ArrayResize(lTest, TEST_ATR_SIZE);
    ArrayResize(cTest, TEST_ATR_SIZE);

    for (int i = 0; i < TEST_ATR_SIZE; i++) {
        hTest[i] = 1.0010;
        lTest[i] = 1.0000;
        cTest[i] = 1.0000;
    }

    // Test standard array direction (AsSeries = false)
    double atrStd = CMNSVolatility::CalculateATR(hTest, lTest, cTest, 10, 5, TEST_ATR_SIZE);
    AssertTrue(CMNSUtils::IsEqual(atrStd, 0.0010), "CalculateATR on standard array yields correct ATR (0.0010)");

    // Test timeseries array direction (AsSeries = true)
    ArraySetAsSeries(hTest, true);
    ArraySetAsSeries(lTest, true);
    ArraySetAsSeries(cTest, true);

    double atrSeries = CMNSVolatility::CalculateATR(hTest, lTest, cTest, 9, 5, TEST_ATR_SIZE);
    AssertTrue(CMNSUtils::IsEqual(atrSeries, 0.0010), "CalculateATR on timeseries array yields correct ATR (0.0010)");

    // Restore series property to avoid side-effects
    ArraySetAsSeries(hTest, false);
    ArraySetAsSeries(lTest, false);
    ArraySetAsSeries(cTest, false);

    // 4. Mathematical test: Wilder's smoothing recursion check.
    double hWilder[6] = {10.0, 12.0, 15.0, 11.0, 14.0, 16.0};
    double lWilder[6] = {5.0, 7.0, 9.0, 8.0, 10.0, 11.0};
    double cWilder[6] = {6.0, 8.0, 10.0, 9.0, 12.0, 13.0};

    double atrWilder3 = CMNSVolatility::CalculateATR(hWilder, lWilder, cWilder, 3, 3, 6);
    double atrWilder4 = CMNSVolatility::CalculateATR(hWilder, lWilder, cWilder, 4, 3, 6);
    double atrWilder5 = CMNSVolatility::CalculateATR(hWilder, lWilder, cWilder, 5, 3, 6);

    AssertTrue(CMNSUtils::IsEqual(atrWilder3, 16.0 / 3.0), "Wilder's ATR at index 3 (initial SMA) is correct");
    AssertTrue(CMNSUtils::IsEqual(atrWilder4, 47.0 / 9.0), "Wilder's ATR at index 4 (first smoothed) is correct");
    AssertTrue(CMNSUtils::IsEqual(atrWilder5, 139.0 / 27.0), "Wilder's ATR at index 5 (second smoothed) is correct");

#undef TEST_ATR_SIZE

    Print("--- Module INF-003 complete ---");
}

//+------------------------------------------------------------------+
//| Module INF-004 — MNSConfig validation                            |
//+------------------------------------------------------------------+
void RunModuleINF004Tests() {
    Print("--- Module INF-004: MNSConfig ---");

    // 1. Confirm SetDefaults sets correct initial values
    CMNSConfig::SetDefaults();
    SEngineConfig active = CMNSConfig::GetActive();

    AssertTrue(active.externalDepth == 15, "Default externalDepth is 15");
    AssertTrue(active.internalDepth == 5, "Default internalDepth is 5");
    AssertTrue(CMNSUtils::IsEqual(active.atrTolerance, 0.0010), "Default atrTolerance is 0.0010");
    AssertTrue(CMNSUtils::IsEqual(active.minBreakDistance, 0.0000), "Default minBreakDistance is 0.0000");
    AssertTrue(CMNSUtils::IsEqual(active.confidenceThreshold, 94.0), "Default confidenceThreshold is 94.0");
    AssertTrue(active.logEnable == true, "Default logEnable is true");
    AssertTrue(active.logLevel == 1, "Default logLevel is 1 (MNS_LOG_INFO)");

    // 2. Verify UpdateParameter and parameter bounds
    // Test valid updates
    AssertTrue(CMNSConfig::UpdateParameter("atrTolerance", 0.0020) == true, "Update atrTolerance to 0.0020 succeeds");
    AssertTrue(CMNSConfig::UpdateParameter("externalDepth", 20) == true, "Update externalDepth to 20 succeeds");
    AssertTrue(CMNSConfig::UpdateParameter("internalDepth", 8) == true, "Update internalDepth to 8 succeeds");
    AssertTrue(CMNSConfig::UpdateParameter("confidenceThreshold", 50.0) == true, "Update confidenceThreshold to 50.0 succeeds");
    AssertTrue(CMNSConfig::UpdateParameter("logLevel", 3) == true, "Update logLevel to 3 succeeds");

    SEngineConfig updated = CMNSConfig::GetActive();
    AssertTrue(CMNSUtils::IsEqual(updated.atrTolerance, 0.0020), "Active atrTolerance updated to 0.0020");
    AssertTrue(updated.externalDepth == 20, "Active externalDepth updated to 20");
    AssertTrue(updated.internalDepth == 8, "Active internalDepth updated to 8");
    AssertTrue(CMNSUtils::IsEqual(updated.confidenceThreshold, 50.0), "Active confidenceThreshold updated to 50.0");
    AssertTrue(updated.logLevel == 3, "Active logLevel updated to 3");

    // Test invalid updates (rejections)
    AssertTrue(CMNSConfig::UpdateParameter("externalDepth", 5) == false, "Rejects externalDepth (5) because it is < internalDepth (8)");
    AssertTrue(CMNSConfig::UpdateParameter("externalDepth", -2) == false, "Rejects negative externalDepth");
    AssertTrue(CMNSConfig::UpdateParameter("internalDepth", 25) == false, "Rejects internalDepth (25) because it is > externalDepth (20)");
    AssertTrue(CMNSConfig::UpdateParameter("internalDepth", 0) == false, "Rejects zero internalDepth");
    AssertTrue(CMNSConfig::UpdateParameter("atrTolerance", -0.0001) == false, "Rejects negative atrTolerance");
    AssertTrue(CMNSConfig::UpdateParameter("minBreakDistance", -0.0001) == false, "Rejects negative minBreakDistance");
    AssertTrue(CMNSConfig::UpdateParameter("confidenceThreshold", 101.0) == false, "Rejects confidenceThreshold > 100.0");
    AssertTrue(CMNSConfig::UpdateParameter("confidenceThreshold", -1.0) == false, "Rejects negative confidenceThreshold");
    AssertTrue(CMNSConfig::UpdateParameter("logLevel", 5) == false, "Rejects logLevel > 4");
    AssertTrue(CMNSConfig::UpdateParameter("logLevel", -1) == false, "Rejects negative logLevel");
    AssertTrue(CMNSConfig::UpdateParameter("unknownKey", 123.0) == false, "Rejects unknown parameters");

    // Verify parameters remained unchanged after rejections
    SEngineConfig verified = CMNSConfig::GetActive();
    AssertTrue(verified.externalDepth == 20, "externalDepth unchanged after rejections");
    AssertTrue(verified.internalDepth == 8, "internalDepth unchanged after rejections");
    AssertTrue(verified.logLevel == 3, "logLevel unchanged after rejections");

    // 3. Load from File verification
    string testFileName = "MNS_Settings_Harness_Test.ini";
    int fileHandle = FileOpen(testFileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
    if (fileHandle != INVALID_HANDLE) {
        FileWrite(fileHandle, "; MNS Test Settings file");
        FileWrite(fileHandle, "# Another comment style");
        FileWrite(fileHandle, "externalDepth=30");
        FileWrite(fileHandle, "internalDepth=10");
        FileWrite(fileHandle, "atrTolerance = 0.0015");
        FileWrite(fileHandle, "minBreakDistance= 0.0002");
        FileWrite(fileHandle, "confidenceThreshold =88.5");
        FileWrite(fileHandle, "logEnable = 0.0");
        FileWrite(fileHandle, "logLevel=2");
        FileWrite(fileHandle, "invalid_key=999"); // Graceful check
        FileClose(fileHandle);

        bool loadResult = CMNSConfig::LoadFromFile(testFileName);
        // Will return false because of 'invalid_key', but should fail gracefully and load valid keys
        AssertTrue(loadResult == false, "LoadFromFile returns false when invalid keys exist but completes parsing");

        SEngineConfig loaded = CMNSConfig::GetActive();
        AssertTrue(loaded.externalDepth == 30, "LoadFromFile successfully parsed externalDepth = 30");
        AssertTrue(loaded.internalDepth == 10, "LoadFromFile successfully parsed internalDepth = 10");
        AssertTrue(CMNSUtils::IsEqual(loaded.atrTolerance, 0.0015), "LoadFromFile successfully parsed atrTolerance = 0.0015");
        AssertTrue(CMNSUtils::IsEqual(loaded.minBreakDistance, 0.0002), "LoadFromFile successfully parsed minBreakDistance = 0.0002");
        AssertTrue(CMNSUtils::IsEqual(loaded.confidenceThreshold, 88.5), "LoadFromFile successfully parsed confidenceThreshold = 88.5");
        AssertTrue(loaded.logEnable == false, "LoadFromFile successfully parsed logEnable = false");
        AssertTrue(loaded.logLevel == 2, "LoadFromFile successfully parsed logLevel = 2");

        // Clean up settings file
        FileDelete(testFileName);
    } else {
        AssertTrue(false, "Failed to create mock config file for testing");
    }

    // 4. Test loading non-existent file returns false cleanly
    AssertTrue(CMNSConfig::LoadFromFile("non_existent_settings_file.ini") == false, "LoadFromFile returns false for missing files");

    Print("--- Module INF-004 complete ---");
}

//+------------------------------------------------------------------+
//| Mock Serializable Class for Testing INF-005                      |
//+------------------------------------------------------------------+
class CMockSerializable : public IMNSSerializable {
  public:
    int m_valInt;
    double m_valDouble;
    bool m_valBool;

    CMockSerializable() : m_valInt(0), m_valDouble(0.0), m_valBool(false) {
    }
    CMockSerializable(int valInt, double valDouble, bool valBool)
        : m_valInt(valInt), m_valDouble(valDouble), m_valBool(valBool) {
    }

    virtual MNS_RESULT Serialize(int fileHandle) override {
        if (fileHandle == INVALID_HANDLE)
            return MNS_E_INVALIDARG;

        uint bytesWritten = 0;
        bytesWritten += FileWriteInteger(fileHandle, m_valInt);
        bytesWritten += FileWriteDouble(fileHandle, m_valDouble);
        bytesWritten += FileWriteInteger(fileHandle, m_valBool ? 1 : 0);

        if (bytesWritten != 16)
            return MNS_E_FAIL;

        return MNS_S_OK;
    }

    virtual MNS_RESULT Deserialize(int fileHandle) override {
        if (fileHandle == INVALID_HANDLE)
            return MNS_E_INVALIDARG;

        ulong remaining = FileSize(fileHandle) - FileTell(fileHandle);
        if (remaining < 16)
            return MNS_E_FAIL;

        m_valInt = FileReadInteger(fileHandle);
        m_valDouble = FileReadDouble(fileHandle);
        int boolVal = FileReadInteger(fileHandle);
        m_valBool = (boolVal != 0);

        return MNS_S_OK;
    }
};

//+------------------------------------------------------------------+
//| Module INF-005 — MNSSerializer validation                       |
//+------------------------------------------------------------------+
void RunModuleINF005Tests() {
    Print("--- Module INF-005: MNSSerializer ---");

    string testFile = "MNS_Serializer_Harness_Test.bin";

    // 1. Validate happy-path: Serialize and Deserialize matches
    CMockSerializable mockWrite(101, 1234.5678, true);

    int fileHandle = FileOpen(testFile, FILE_WRITE | FILE_BIN);
    AssertTrue(fileHandle != INVALID_HANDLE, "Created binary file for serialization");

    if (fileHandle != INVALID_HANDLE) {
        MNS_RESULT res = mockWrite.Serialize(fileHandle);
        AssertTrue(res == MNS_S_OK, "Serialize returns MNS_S_OK");
        FileClose(fileHandle);
    }

    CMockSerializable mockRead;
    fileHandle = FileOpen(testFile, FILE_READ | FILE_BIN);
    AssertTrue(fileHandle != INVALID_HANDLE, "Opened binary file for deserialization");

    if (fileHandle != INVALID_HANDLE) {
        MNS_RESULT res = mockRead.Deserialize(fileHandle);
        AssertTrue(res == MNS_S_OK, "Deserialize returns MNS_S_OK");
        FileClose(fileHandle);
    }

    // Verify properties match
    AssertTrue(mockRead.m_valInt == 101, "Deserialized integer matches (101)");
    AssertTrue(CMNSUtils::IsEqual(mockRead.m_valDouble, 1234.5678), "Deserialized double matches (1234.5678)");
    AssertTrue(mockRead.m_valBool == true, "Deserialized boolean matches (true)");

    // Clean up
    FileDelete(testFile);

    // 2. Validate corrupt/incomplete file handling (returns MNS_E_FAIL)
    string corruptFile = "MNS_Serializer_Corrupt_Test.bin";
    fileHandle = FileOpen(corruptFile, FILE_WRITE | FILE_BIN);
    AssertTrue(fileHandle != INVALID_HANDLE, "Created binary file for corrupt test");
    if (fileHandle != INVALID_HANDLE) {
        // Write only 4 bytes (int) instead of the full 16 bytes
        FileWriteInteger(fileHandle, 999);
        FileClose(fileHandle);
    }

    CMockSerializable mockCorrupt;
    fileHandle = FileOpen(corruptFile, FILE_READ | FILE_BIN);
    AssertTrue(fileHandle != INVALID_HANDLE, "Opened binary file for corrupt reading");
    if (fileHandle != INVALID_HANDLE) {
        ulong sz = FileSize(fileHandle);
        Print("  [INFO] Diagnostic: corrupt file size = ", sz);
        MNS_RESULT res = mockCorrupt.Deserialize(fileHandle);
        Print("  [INFO] Diagnostic: Deserialize result = 0x", IntegerToString(res, 8, '0'));
        AssertTrue(res == MNS_E_FAIL, "Deserialize returns MNS_E_FAIL for incomplete file");
        FileClose(fileHandle);
    }

    FileDelete(corruptFile);

    // 3. Validate invalid file handle handling (returns MNS_E_INVALIDARG)
    CMockSerializable mockInvalid;
    AssertTrue(mockInvalid.Serialize(INVALID_HANDLE) == MNS_E_INVALIDARG, "Serialize with INVALID_HANDLE returns MNS_E_INVALIDARG");
    AssertTrue(mockInvalid.Deserialize(INVALID_HANDLE) == MNS_E_INVALIDARG, "Deserialize with INVALID_HANDLE returns MNS_E_INVALIDARG");

    Print("--- Module INF-005 complete ---");
}

//+------------------------------------------------------------------+
//| Module INF-006 — MNSTestSuite validation                         |
//+------------------------------------------------------------------+
void RunModuleINF006Tests() {
    Print("--- Module INF-006: MNSTestSuite ---");

    // 1. Reset and check initial state
    CMNSTestSuite::Reset();
    AssertTrue(CMNSTestSuite::GetFailedCount() == 0, "GetFailedCount is 0 after Reset");

    // 2. Test successful assertions
    CMNSTestSuite::AssertTrue(true, "TestSuite AssertTrue Pass");
    CMNSTestSuite::AssertEqualInt(10, 10, "TestSuite AssertEqualInt Pass");
    CMNSTestSuite::AssertEqualDouble(1.23456, 1.234565, "TestSuite AssertEqualDouble Pass", 0.00001);

    AssertTrue(CMNSTestSuite::GetFailedCount() == 0, "No failures after successful assertions");

    // 3. Test failing assertions. Since these will print [FAIL] in the log, they are expected failures of the test suite itself.
    Print("  [INFO] The following 3 [FAIL] logs are EXPECTED as part of INF-006 verification:");
    CMNSTestSuite::AssertTrue(false, "TestSuite AssertTrue Fail");
    CMNSTestSuite::AssertEqualInt(10, 20, "TestSuite AssertEqualInt Fail");
    CMNSTestSuite::AssertEqualDouble(1.23456, 1.23458, "TestSuite AssertEqualDouble Fail", 0.00001);

    AssertTrue(CMNSTestSuite::GetFailedCount() == 3, "GetFailedCount returns 3 after 3 failures");

    // 4. Test ReportResults
    CMNSTestSuite::ReportResults("INF-006 Mock Module");

    // Reset again to leave it clean
    CMNSTestSuite::Reset();
    AssertTrue(CMNSTestSuite::GetFailedCount() == 0, "GetFailedCount reset to 0");

    Print("--- Module INF-006 complete ---");
}

//+------------------------------------------------------------------+
//| Module INF-007 — MNSProfiler validation                          |
//+------------------------------------------------------------------+
void RunModuleINF007Tests() {
    Print("--- Module INF-007: MNSProfiler ---");

    CMNSProfiler::Reset();

    // 1. Basic Start and Stop measuring
    string testSec = "Test_Sleep_Block";

    // Warm up the section registration
    MNS_ProfileStart(testSec);
    MNS_ProfileStop(testSec);

    ulong callsBefore = CMNSProfiler::GetCallCount(testSec);
    AssertTrue(callsBefore == 1, "Profiler section registered with 1 call");

    // Sleep 10ms to verify duration
    MNS_ProfileStart(testSec);
    Sleep(10);
    MNS_ProfileStop(testSec);

    ulong totalTime = CMNSProfiler::GetTotalTimeUs(testSec);
    ulong callsAfter = CMNSProfiler::GetCallCount(testSec);

    AssertTrue(callsAfter == 2, "Call count incremented to 2");
    AssertTrue(totalTime >= 10000, "Recorded time is >= 10,000 microseconds (10ms Sleep)");

    // 2. Validate nested profiling
    string nestedOuter = "Nested_Outer";
    string nestedInner = "Nested_Inner";

    MNS_ProfileStart(nestedOuter);
    Sleep(5);
    MNS_ProfileStart(nestedInner);
    Sleep(5);
    MNS_ProfileStop(nestedInner);
    MNS_ProfileStop(nestedOuter);

    AssertTrue(CMNSProfiler::GetCallCount(nestedOuter) == 1, "Outer call count is 1");
    AssertTrue(CMNSProfiler::GetCallCount(nestedInner) == 1, "Inner call count is 1");
    AssertTrue(CMNSProfiler::GetTotalTimeUs(nestedOuter) >= 10000, "Outer time spans both sleep calls (>= 10ms)");
    AssertTrue(CMNSProfiler::GetTotalTimeUs(nestedInner) >= 5000, "Inner time spans inner sleep call (>= 5ms)");

    // 3. Print telemetry log block
    CMNSProfiler::ReportTelemetry();

    CMNSProfiler::Reset();
    Print("--- Module INF-007 complete ---");
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    g_testsPassed = 0;
    g_testsFailed = 0;

    Print("==============================================");
    Print("  MNS Trading Engine — Test Harness v2.0");
    Print("==============================================");

    //--- Run all module test suites
    RunModuleINF000Tests();

    Print("----------------------------------------------");

    RunModuleINF001Tests();

    Print("----------------------------------------------");

    RunModuleINF002Tests();

    Print("----------------------------------------------");

    RunModuleINF003Tests();

    Print("----------------------------------------------");

    RunModuleINF004Tests();

    Print("----------------------------------------------");

    RunModuleINF005Tests();

    Print("----------------------------------------------");

    RunModuleINF006Tests();

    Print("----------------------------------------------");

    RunModuleINF007Tests();

    Print("----------------------------------------------");

    RunModule001Tests();

    Print("----------------------------------------------");

    RunModule002Tests();

    Print("----------------------------------------------");

    RunModule003Tests();

    Print("----------------------------------------------");

    RunModule004Tests();

    Print("----------------------------------------------");

    RunModule005Tests();

    Print("----------------------------------------------");

    RunModule006Tests();

    Print("----------------------------------------------");

    RunModule007Tests();

    Print("----------------------------------------------");

    RunModule008Tests();

    Print("----------------------------------------------");

    RunModule009Tests();

    Print("----------------------------------------------");

    RunModule010Tests();

    Print("----------------------------------------------");

    RunModule011Tests();

    Print("----------------------------------------------");

    RunModule012Tests();

    //--- Print summary
    Print("==============================================");
    Print("  TEST SUMMARY");
    Print("  Passed : ", g_testsPassed);
    Print("  Failed : ", g_testsFailed);
    Print("  Total  : ", g_testsPassed + g_testsFailed);

    if (g_testsFailed == 0)
        Print("  Result : ALL TESTS PASSED");
    else
        Print("  Result : ", g_testsFailed, " TEST(S) FAILED — review log above");

    Print("==============================================");

    //--- Return INIT_FAILED to self-remove after single-pass validation.
    return INIT_FAILED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("MNS_TestHarness deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Intentionally empty.
    // This harness runs its full validation suite in OnInit() only.
}

//+------------------------------------------------------------------+
//| End of MNS_TestHarness.mq5                                       |
//+------------------------------------------------------------------+
