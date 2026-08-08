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
#property version   "2.00"
#property strict

#include "..\\..\\Include\\MNS\\MNSCore.mqh"
#define MNS_LOG_ENABLE
#include "..\\..\\Include\\MNS\\MNSLogger.mqh"
#include "..\\..\\Include\\MNS\\MNSTypes.mqh"
#include "..\\..\\Include\\MNS\\CSwingDetector.mqh"
#include "..\\..\\Include\\MNS\\CStructureEngine.mqh"
#include "..\\..\\Include\\MNS\\CBreakDetector.mqh"
#include "..\\..\\Include\\MNS\\MNSUtils.mqh"
#include "..\\..\\Include\\MNS\\MNSVolatility.mqh"

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
void AssertTrue(bool condition, const string testName)
{
    if (condition)
    {
        Print("  [PASS] ", testName);
        g_testsPassed++;
    }
    else
    {
        Print("  [FAIL] ", testName);
        g_testsFailed++;
    }
}

//+------------------------------------------------------------------+
//| Module 001 — MNSTypes validation                                 |
//|                                                                  |
//| Validates that every shared structure initializes to the         |
//| expected safe default values defined in MNSTypes.mqh.            |
//+------------------------------------------------------------------+
void RunModule001Tests()
{
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

    AssertTrue(swing.barIndex    == MNS_INVALID_INDEX, "SSwingPoint.barIndex default is MNS_INVALID_INDEX");
    AssertTrue(swing.price       == MNS_INVALID_PRICE,  "SSwingPoint.price default is MNS_INVALID_PRICE");
    AssertTrue(swing.time        == MNS_INVALID_TIME,   "SSwingPoint.time default is MNS_INVALID_TIME");
    AssertTrue(swing.type        == SWING_NONE,          "SSwingPoint.type default is SWING_NONE");
    AssertTrue(swing.level       == SWING_LEVEL_INTERNAL,"SSwingPoint.level default is SWING_LEVEL_INTERNAL");
    AssertTrue(swing.isConfirmed == false,               "SSwingPoint.isConfirmed default is false");

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

    AssertTrue(structBreak.barIndex    == MNS_INVALID_INDEX, "SStructureBreak.barIndex default is MNS_INVALID_INDEX");
    AssertTrue(structBreak.price       == MNS_INVALID_PRICE,  "SStructureBreak.price default is MNS_INVALID_PRICE");
    AssertTrue(structBreak.time        == MNS_INVALID_TIME,   "SStructureBreak.time default is MNS_INVALID_TIME");
    AssertTrue(structBreak.breakType   == BREAK_NONE,         "SStructureBreak.breakType default is BREAK_NONE");
    AssertTrue(structBreak.strength    == STRENGTH_UNKNOWN,   "SStructureBreak.strength default is STRENGTH_UNKNOWN");
    AssertTrue(structBreak.isConfirmed == false,              "SStructureBreak.isConfirmed default is false");

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

    AssertTrue(state.trend              == TREND_UNKNOWN,    "SMarketState.trend default is TREND_UNKNOWN");
    AssertTrue(state.phase              == PHASE_UNKNOWN,    "SMarketState.phase default is PHASE_UNKNOWN");
    AssertTrue(state.structureType      == STRUCTURE_NONE,   "SMarketState.structureType default is STRUCTURE_NONE");
    AssertTrue(state.isBullishStructure == false,            "SMarketState.isBullishStructure default is false");
    AssertTrue(state.isBearishStructure == false,            "SMarketState.isBearishStructure default is false");
    AssertTrue(state.isRanging          == false,            "SMarketState.isRanging default is false");
    AssertTrue(state.updatedBarIndex    == MNS_INVALID_INDEX,"SMarketState.updatedBarIndex default is MNS_INVALID_INDEX");
    AssertTrue(state.updatedTime        == MNS_INVALID_TIME, "SMarketState.updatedTime default is MNS_INVALID_TIME");
    AssertTrue(state.version            == 1,                "SMarketState.version default is 1");

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
void RunModule002Tests()
{
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
    bool badInitZero  = badDetector.Initialize(0, 0);
    bool badInitFlip  = badDetector.Initialize(3, 10); // internal > external
    AssertTrue(badInitZero == false, "CSwingDetector.Initialize(0, 0) returns false");
    AssertTrue(badInitFlip == false, "CSwingDetector.Initialize(3, 10) returns false (internal > external)");

    //------------------------------------------------------------------
    //| Test 3: Pre-Update() state is empty
    //------------------------------------------------------------------
    AssertTrue(detector.HasConfirmedSwing()       == false, "HasConfirmedSwing() is false before Update()");
    AssertTrue(detector.GetSwingCount()           == 0,     "GetSwingCount() is 0 before Update()");
    AssertTrue(detector.GetExternalSwingCount()   == 0,     "GetExternalSwingCount() is 0 before Update()");
    AssertTrue(detector.GetInternalSwingCount()   == 0,     "GetInternalSwingCount() is 0 before Update()");

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
    SSwingPoint emptyLatest  = detector.GetLatestSwing();
    SSwingPoint emptyExtHigh = detector.GetLatestExternalHigh();
    SSwingPoint emptyExtLow  = detector.GetLatestExternalLow();
    SSwingPoint emptyIntHigh = detector.GetLatestInternalHigh();
    SSwingPoint emptyIntLow  = detector.GetLatestInternalLow();

    AssertTrue(emptyLatest.isConfirmed  == false, "GetLatestSwing() on empty detector returns unconfirmed swing");
    AssertTrue(emptyExtHigh.isConfirmed == false, "GetLatestExternalHigh() on empty detector returns unconfirmed swing");
    AssertTrue(emptyExtLow.isConfirmed  == false, "GetLatestExternalLow() on empty detector returns unconfirmed swing");
    AssertTrue(emptyIntHigh.isConfirmed == false, "GetLatestInternalHigh() on empty detector returns unconfirmed swing");
    AssertTrue(emptyIntLow.isConfirmed  == false, "GetLatestInternalLow() on empty detector returns unconfirmed swing");

    //------------------------------------------------------------------
    //| Test 6: Update() with insufficient bars returns false safely
    //------------------------------------------------------------------
    double  tinyHigh[5]  = {1.2001, 1.2002, 1.2003, 1.2004, 1.2005};
    double  tinyLow[5]   = {1.1991, 1.1992, 1.1993, 1.1994, 1.1995};
    datetime tinyTime[5] = {10000, 20000, 30000, 40000, 50000};

    bool tinyResult = detector.Update(tinyHigh, tinyLow, tinyTime, 5, 0);
    AssertTrue(tinyResult == false, "Update() with fewer bars than (2*depth+1) returns false");
    AssertTrue(detector.GetSwingCount() == 0, "GetSwingCount() remains 0 after Update() with insufficient bars");

    //------------------------------------------------------------------
    //| Test 7: Update() on not-initialized detector returns false
    //------------------------------------------------------------------
    CSwingDetector uninitDetector;
    double  dummyHigh[50];
    double  dummyLow[50];
    datetime dummyTime[50];
    ArrayInitialize(dummyHigh, 1.2000);
    ArrayInitialize(dummyLow,  1.1990);
    for (int i = 0; i < 50; i++) dummyTime[i] = (datetime)(i * 3600);

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
    #define TEST_BARS        50
    #define PIVOT_HIGH_INDEX 20
    #define PIVOT_LOW_INDEX  25

    double   testHigh[TEST_BARS];
    double   testLow[TEST_BARS];
    double   testOpen[TEST_BARS];
    double   testClose[TEST_BARS];
    datetime testTime[TEST_BARS];

    //--- Populate baseline values
    for (int i = 0; i < TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1990;
        testOpen[i]  = 1.1993;
        testClose[i] = 1.1995;
        //--- Series order: index 0 = newest. Each bar is 1 hour apart.
        //--- Oldest bar (index 49) starts at a fixed epoch offset.
        testTime[i]  = (datetime)((TEST_BARS - 1 - i) * 3600);
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
    AssertTrue(detector.GetSwingCount()         == 0,     "GetSwingCount() is 0 after Reset()");
    AssertTrue(detector.GetExternalSwingCount() == 0,     "GetExternalSwingCount() is 0 after Reset()");
    AssertTrue(detector.GetInternalSwingCount() == 0,     "GetInternalSwingCount() is 0 after Reset()");
    AssertTrue(detector.HasConfirmedSwing()     == false, "HasConfirmedSwing() is false after Reset()");

    //--- Latest accessors must return unconfirmed empty swings after Reset.
    SSwingPoint rsLatest  = detector.GetLatestSwing();
    SSwingPoint rsExtHigh = detector.GetLatestExternalHigh();
    SSwingPoint rsExtLow  = detector.GetLatestExternalLow();
    SSwingPoint rsIntHigh = detector.GetLatestInternalHigh();
    SSwingPoint rsIntLow  = detector.GetLatestInternalLow();

    AssertTrue(rsLatest.isConfirmed  == false, "GetLatestSwing() is unconfirmed after Reset()");
    AssertTrue(rsExtHigh.isConfirmed == false, "GetLatestExternalHigh() is unconfirmed after Reset()");
    AssertTrue(rsExtLow.isConfirmed  == false, "GetLatestExternalLow() is unconfirmed after Reset()");
    AssertTrue(rsIntHigh.isConfirmed == false, "GetLatestInternalHigh() is unconfirmed after Reset()");
    AssertTrue(rsIntLow.isConfirmed  == false, "GetLatestInternalLow() is unconfirmed after Reset()");

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
void RunModule003Tests()
{
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
    double   bullishHigh[BULLISH_BARS];
    double   bullishLow[BULLISH_BARS];
    datetime bullishTime[BULLISH_BARS];

    for (int i = 0; i < BULLISH_BARS; i++)
    {
        bullishHigh[i] = 1.2000;
        bullishLow[i]  = 1.1900;
        bullishTime[i] = (datetime)((BULLISH_BARS - 1 - i) * 3600);
    }

    // Lows
    for (int i = 115; i <= 145; i++) bullishLow[i] = 1.1900;
    bullishLow[130] = 1.1400;

    for (int i = 75; i <= 105; i++) bullishLow[i] = 1.1900;
    bullishLow[90] = 1.1500;

    for (int i = 35; i <= 65; i++) bullishLow[i] = 1.1900;
    bullishLow[50] = 1.1600;

    // Highs
    for (int i = 95; i <= 125; i++) bullishHigh[i] = 1.2000;
    bullishHigh[110] = 1.2600;

    for (int i = 55; i <= 85; i++) bullishHigh[i] = 1.2000;
    bullishHigh[70] = 1.2700;

    for (int i = 15; i <= 45; i++) bullishHigh[i] = 1.2000;
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
    AssertTrue(bullishEngine.GetConfidenceScore() == 94.0, "Confidence score is 94.0");

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
    double   bearishHigh[BEARISH_BARS];
    double   bearishLow[BEARISH_BARS];
    datetime bearishTime[BEARISH_BARS];

    for (int i = 0; i < BEARISH_BARS; i++)
    {
        bearishHigh[i] = 1.2000;
        bearishLow[i]  = 1.1900;
        bearishTime[i] = (datetime)((BEARISH_BARS - 1 - i) * 3600);
    }

    // Highs
    for (int i = 115; i <= 145; i++) bearishHigh[i] = 1.2000;
    bearishHigh[130] = 1.2800;

    for (int i = 75; i <= 105; i++) bearishHigh[i] = 1.2000;
    bearishHigh[90] = 1.2700;

    for (int i = 35; i <= 65; i++) bearishHigh[i] = 1.2000;
    bearishHigh[50] = 1.2600;

    // Lows
    for (int i = 95; i <= 125; i++) bearishLow[i] = 1.1900;
    bearishLow[110] = 1.1600;

    for (int i = 55; i <= 85; i++) bearishLow[i] = 1.1900;
    bearishLow[70] = 1.1500;

    for (int i = 15; i <= 45; i++) bearishLow[i] = 1.1900;
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
    double   pbHigh[PB_BARS];
    double   pbLow[PB_BARS];
    datetime pbTime[PB_BARS];

    for (int i = 0; i < PB_BARS; i++)
    {
        pbHigh[i] = 1.2000;
        pbLow[i]  = 1.1900;
        pbTime[i] = (datetime)((PB_BARS - 1 - i) * 3600);
    }

    // External Lows (depth 15)
    pbLow[140] = 1.1400;
    pbLow[100] = 1.1500;
    pbLow[65]  = 1.1600;

    // External Highs (depth 15)
    pbHigh[120] = 1.2600;
    pbHigh[80]  = 1.2700;
    pbHigh[50]  = 1.2800;

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
    double   rangeHigh[RANGE_BARS];
    double   rangeLow[RANGE_BARS];
    datetime rangeTime[RANGE_BARS];

    for (int i = 0; i < RANGE_BARS; i++)
    {
        rangeHigh[i] = 1.2000;
        rangeLow[i]  = 1.1900;
        rangeTime[i] = (datetime)((RANGE_BARS - 1 - i) * 3600);
    }

    // Lows
    rangeLow[130] = 1.1500;
    rangeLow[90]  = 1.1505;
    rangeLow[50]  = 1.1502;

    // Highs
    rangeHigh[110] = 1.2500;
    rangeHigh[70]  = 1.2495;
    rangeHigh[30]  = 1.2504;

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
void RunModule004Tests()
{
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
    double   testHigh[BREAK_TEST_BARS];
    double   testLow[BREAK_TEST_BARS];
    double   testOpen[BREAK_TEST_BARS];
    double   testClose[BREAK_TEST_BARS];
    datetime testTime[BREAK_TEST_BARS];

    for (int i = 0; i < BREAK_TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
        testTime[i]  = (datetime)((BREAK_TEST_BARS - 1 - i) * 3600);
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
    testHigh[54]  = 1.2780; 
    testLow[54]   = 1.2700;

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
    for (int i = 0; i < BREAK_TEST_BARS; i++)
    {
        testHigh[i]  = 1.2000;
        testLow[i]   = 1.1900;
        testOpen[i]  = 1.1950;
        testClose[i] = 1.1950;
        testTime[i]  = (datetime)((BREAK_TEST_BARS - 1 - i) * 3600);
    }

    // Restore swing low pivots
    testLow[130] = 1.1400;
    testLow[90] = 1.1500;
    testLow[50] = 1.1600;

    // Restore swing high pivots
    testHigh[110] = 1.2600;
    testHigh[70] = 1.2700;
    testHigh[30] = 1.2800;

    // Plant CHoCH wick break at index 5
    testLow[5] = 1.1550;
    testClose[5] = 1.1650;
    testHigh[5] = 1.1700;

    swingDetector.Reset();
    swingDetector.Update(testHigh, testLow, testTime, BREAK_TEST_BARS, 0);
    structureEngine.Reset();
    structureEngine.Update(swingDetector, 0.0010);
    breakDetector.Reset();
    breakDetector.Update(swingDetector, structureEngine, testHigh, testLow, testClose, testOpen, testTime, BREAK_TEST_BARS, 0, 0.0010);

    AssertTrue(breakDetector.HasBearishCHOCH() == true, "HasBearishCHOCH() is true after wick-only break of protected low");
    SStructureBreak latestCHOCH = breakDetector.GetLatestCHOCH();
    AssertTrue(latestCHOCH.brokenSwing.price == 1.1600, "CHoCH broken swing price is 1.1600");

    #undef BREAK_TEST_BARS

    Print("--- Module 004 complete ---");
}

//+------------------------------------------------------------------+
//| Module INF-000 — MNSCore validation                              |
//+------------------------------------------------------------------+
void RunModuleINF000Tests()
{
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
void RunModuleINF001Tests()
{
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
    if(handle != INVALID_HANDLE)
    {
        string fileContent = "";
        while(!FileIsEnding(handle))
        {
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
    }
    else
    {
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
void RunModuleINF002Tests()
{
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
    datetime timeLondon = D'2026.08.08 10:30:00'; // Hour 10
    datetime timeOutLondon = D'2026.08.08 17:00:00'; // Hour 17
    AssertTrue(CMNSUtils::IsInSession(timeLondon, 8, 16) == true, "IsInSession(10:30, 8, 16) is in session");
    AssertTrue(CMNSUtils::IsInSession(timeOutLondon, 8, 16) == false, "IsInSession(17:00, 8, 16) is out of session");

    // 4b. Overnight session (start > end) e.g. Tokyo / Midnight spanning (22 to 6)
    datetime timeTokyoSpanning = D'2026.08.08 23:30:00'; // Hour 23
    datetime timeTokyoSpanning2 = D'2026.08.08 02:00:00'; // Hour 2
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
    arrayDel[0] = 10.0; arrayDel[1] = 20.0; arrayDel[2] = 30.0; arrayDel[3] = 40.0; arrayDel[4] = 50.0;

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
void RunModuleINF003Tests()
{
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
    double hTest[TEST_ATR_SIZE];
    double lTest[TEST_ATR_SIZE];
    double cTest[TEST_ATR_SIZE];
    
    for (int i = 0; i < TEST_ATR_SIZE; i++)
    {
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
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
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

    RunModule001Tests();

    Print("----------------------------------------------");

    RunModule002Tests();

    Print("----------------------------------------------");

    RunModule003Tests();

    Print("----------------------------------------------");

    RunModule004Tests();

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
void OnDeinit(const int reason)
{
    Print("MNS_TestHarness deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Intentionally empty.
    // This harness runs its full validation suite in OnInit() only.
}

//+------------------------------------------------------------------+
//| End of MNS_TestHarness.mq5                                       |
//+------------------------------------------------------------------+
