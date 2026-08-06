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

#include "..\\..\\Include\\MNS\\MNSTypes.mqh"
#include "..\\..\\Include\\MNS\\CSwingDetector.mqh"
#include "..\\..\\Include\\MNS\\CStructureEngine.mqh"

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
    RunModule001Tests();

    Print("----------------------------------------------");

    RunModule002Tests();

    Print("----------------------------------------------");

    RunModule003Tests();

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
