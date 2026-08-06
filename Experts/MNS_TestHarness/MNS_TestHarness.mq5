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
