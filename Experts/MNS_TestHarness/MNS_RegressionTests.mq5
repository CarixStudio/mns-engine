//+------------------------------------------------------------------+
//|                                        MNS_RegressionTests.mq5   |
//|                              MNS Trading Engine — Test Harness   |
//|                                                                  |
//| Purpose:                                                         |
//|   Tier 4 Deterministic Regression Testing harness for MNS.       |
//|   Replays pre-recorded historical market scenarios through the   |
//|   full MNS DAG engine pipeline, hashes the SConfirmationState    |
//|   output struct, and compares against baseline values.           |
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading logic or chart rendering.                       |
//|   - All market scenarios synthetically generated (no network).   |
//|   - Self-contained deterministic rolling hashing function.       |
//|   - Baseline recording via InpRecordBaseline parameter.          |
//|   - Runs fully inside OnInit() and returns INIT_FAILED to self-  |
//|     remove from chart after execution.                           |
//|                                                                  |
//| Version: 1.00                                                    |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#property copyright "MNS Trading Engine"
#property version   "1.00"
#property strict

#include "..\..\Include\MNS\MNSCore.mqh"
#define MNS_LOG_ENABLE
#include "..\..\Include\MNS\MNSLogger.mqh"
#include "..\..\Include\MNS\MNSTypes.mqh"
#include "..\..\Include\MNS\CSwingDetector.mqh"
#include "..\..\Include\MNS\CStructureEngine.mqh"
#include "..\..\Include\MNS\CBreakDetector.mqh"
#include "..\..\Include\MNS\COrderFlowEngine.mqh"
#include "..\..\Include\MNS\CDeliveryStructureEngine.mqh"
#include "..\..\Include\MNS\CLiquidityEngine.mqh"
#include "..\..\Include\MNS\CPOIEngine.mqh"
#include "..\..\Include\MNS\CObjectiveEngine.mqh"
#include "..\..\Include\MNS\CConfirmationEngine.mqh"
#include "..\..\Include\MNS\MNSUtils.mqh"
#include "..\..\Include\MNS\MNSTestSuite.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input bool InpRecordBaseline = false; ///< Record current computed hashes as new baseline file

//+------------------------------------------------------------------+
//| Pre-baked Hardcoded Expected Hashes                              |
//+------------------------------------------------------------------+
uint EXPECTED_HASH_R01 = 0x61DAA1E9; ///< Brexit Flash Crash baseline
uint EXPECTED_HASH_R02 = 0x098B1CE7; ///< SNB Peg Removal baseline
uint EXPECTED_HASH_R03 = 0x4CE8E72D; ///< COVID Gap Open baseline

//+------------------------------------------------------------------+
//| Hashing Helpers                                                  |
//+------------------------------------------------------------------+
uint HashDouble(double val)
{
    if (val == MNS_INVALID_PRICE || !MathIsValidNumber(val))
        return 0;
    long scaled = (long)MathRound(val * 100000.0);
    return (uint)(scaled ^ (scaled >> 32));
}

uint HashCombine(uint hash, uint val)
{
    return hash ^ (val + 0x9e3779b9 + (hash << 6) + (hash >> 2));
}

//+------------------------------------------------------------------+
//| Deterministic Hashing Function for SConfirmationState            |
//+------------------------------------------------------------------+
uint HashConfirmationState(const SConfirmationState &state)
{
    uint h = 0x811c9dc5; // FNV offset basis

    h = HashCombine(h, (uint)state.state);
    h = HashCombine(h, (uint)state.direction);
    h = HashCombine(h, HashDouble(state.confidenceScore));
    h = HashCombine(h, HashDouble(state.triggerPrice));
    h = HashCombine(h, (uint)state.triggerTime);
    h = HashCombine(h, HashDouble(state.invalidationLevel));

    // Combine boolean fields as bits into a single uint bitmask
    uint boolMask = 0;
    if (state.hasPoiInteraction)  boolMask |= (1 << 0);
    if (state.hasLiquidityEvent)  boolMask |= (1 << 1);
    if (state.hasStrongRejection) boolMask |= (1 << 2);
    if (state.hasChochTrigger)    boolMask |= (1 << 3);
    if (state.hasBosTrigger)      boolMask |= (1 << 4);
    h = HashCombine(h, boolMask);

    h = HashCombine(h, (uint)state.associatedPoiId);
    h = HashCombine(h, (uint)state.associatedPoiType);
    h = HashCombine(h, (uint)state.associatedSweepId);
    h = HashCombine(h, HashDouble(state.breakPrice));
    h = HashCombine(h, (uint)state.breakTime);

    return h;
}

//+------------------------------------------------------------------+
//| Hex String Parser                                                |
//+------------------------------------------------------------------+
uint ParseHexHash(string str)
{
    StringTrimLeft(str);
    StringTrimRight(str);
    int pos = StringFind(str, "=");
    if (pos >= 0)
    {
        str = StringSubstr(str, pos + 1);
        StringTrimLeft(str);
        StringTrimRight(str);
    }
    if (StringFind(str, "0x") == 0 || StringFind(str, "0X") == 0)
    {
        str = StringSubstr(str, 2);
    }
    uint val = 0;
    int len = StringLen(str);
    for (int i = 0; i < len; i++)
    {
        ushort ch = StringGetCharacter(str, i);
        uint digit = 0;
        if (ch >= '0' && ch <= '9')
            digit = ch - '0';
        else if (ch >= 'a' && ch <= 'f')
            digit = 10 + (ch - 'a');
        else if (ch >= 'A' && ch <= 'F')
            digit = 10 + (ch - 'A');
        else
            break;
        val = (val << 4) | digit;
    }
    return val;
}

//+------------------------------------------------------------------+
//| Full Engine Pipeline Replay Runner                               |
//+------------------------------------------------------------------+
uint RunScenarioPipeline(const double &h[],
                         const double &l[],
                         const double &c[],
                         const double &o[],
                         const datetime &t[],
                         int n,
                         double minSwingDist,
                         const double &spreads[],
                         double currentAtr)
{
    CSwingDetector swingDet;
    swingDet.Initialize(15, 5);

    CStructureEngine structEng;
    structEng.Initialize(minSwingDist);

    CBreakDetector breakDet;
    breakDet.Initialize();

    COrderFlowEngine ofEng;
    ofEng.Initialize();

    CDeliveryStructureEngine delEng;
    delEng.Initialize();

    CLiquidityEngine liqEng;
    liqEng.Initialize(0);

    CPOIEngine poiEng;
    poiEng.Initialize();

    CObjectiveEngine objEng;
    objEng.Initialize();

    CConfirmationEngine confirmEng;
    confirmEng.Initialize();

    for (int count = 5; count <= n; count++)
    {
        double sp = (count - 1 < ArraySize(spreads)) ? spreads[count - 1] : spreads[0];

        swingDet.Update(h, l, t, count, 0);
        structEng.Update(swingDet, minSwingDist);
        breakDet.Update(swingDet, structEng, h, l, c, o, t, count, 0, minSwingDist);
        ofEng.Update(swingDet, structEng, breakDet, h, l, c, o, t, count, 0, currentAtr);
        delEng.Update(swingDet, structEng, breakDet, ofEng, h, l, c, o, t, count, 0, currentAtr);
        liqEng.Update(swingDet, delEng, h, l, c, o, t, count, 0, minSwingDist, sp);
        poiEng.Update(swingDet, structEng, breakDet, liqEng, delEng, h, l, c, o, t, count, 0, minSwingDist);
        objEng.Update(swingDet, structEng, breakDet, ofEng, delEng, liqEng, poiEng, h, l, c, o, t, count, 0, currentAtr);
        confirmEng.Update(swingDet, structEng, breakDet, ofEng, delEng, liqEng, poiEng, objEng, h, l, c, o, t, count, 0, currentAtr);
    }

    SConfirmationState state = confirmEng.GetState();
    return HashConfirmationState(state);
}

//+------------------------------------------------------------------+
//| Scenario R-01 Generator: Brexit Flash Crash                     |
//+------------------------------------------------------------------+
uint ExecuteScenarioR01()
{
    int n = 60;
    double h[60], l[60], c[60], o[60], spreads[60];
    datetime t[60];

    datetime baseTime = 1466726400; // 2016-06-24 00:00 UTC

    // Bars 59 down to 27: consolidation around 1.4800 with equal lows at 1.4780
    for (int i = 59; i >= 27; i--)
    {
        h[i] = 1.4820;
        l[i] = 1.4780;
        c[i] = 1.4800;
        o[i] = 1.4800;
        t[i] = baseTime - (datetime)((59 - i) * 3600);
        spreads[i] = 0.0003; // 3 points
    }

    // Bars 26 down to 0: 27 consecutive drop candles (30 pips / 0.0030 drop per candle)
    for (int i = 26; i >= 0; i--)
    {
        int step = 26 - i;
        double startP = 1.4800 - (step * 0.0030);
        o[i] = startP;
        c[i] = startP - 0.0030;
        h[i] = startP + 0.0005;
        l[i] = c[i] - 0.0005;
        t[i] = baseTime - (datetime)((59 - i) * 3600);
        spreads[i] = 0.0003;
    }

    return RunScenarioPipeline(h, l, c, o, t, n, 0.0010, spreads, 0.0050);
}

//+------------------------------------------------------------------+
//| Scenario R-02 Generator: SNB Peg Removal                         |
//+------------------------------------------------------------------+
uint ExecuteScenarioR02()
{
    int n = 60;
    double h[60], l[60], c[60], o[60], spreads[60];
    datetime t[60];

    datetime baseTime = 1421314200; // 2015-01-15 09:30 UTC

    // Bars 59 down to 36: Steady near 1.2005
    for (int i = 59; i >= 36; i--)
    {
        h[i] = 1.2010;
        l[i] = 1.2000;
        c[i] = 1.2005;
        o[i] = 1.2005;
        t[i] = baseTime - (datetime)((59 - i) * 3600);
        spreads[i] = 0.0010; // 10 points
    }

    // Bars 35 down to 26: 10 shock candles dropping 300 pips (0.0300) each (spread = 150 points / 0.0150)
    for (int i = 35; i >= 26; i--)
    {
        int step = 35 - i;
        double startP = 1.2005 - (step * 0.0300);
        o[i] = startP;
        c[i] = startP - 0.0300;
        h[i] = startP + 0.0050;
        l[i] = c[i] - 0.0050;
        t[i] = baseTime - (datetime)((59 - i) * 3600);
        spreads[i] = 0.0150; // 150 points shock spread
    }

    // Bars 25 down to 16: 10 recovery candles rising 200 pips (0.0200) each
    double lowPoint = 1.2005 - (10 * 0.0300); // 0.9005
    for (int i = 25; i >= 16; i--)
    {
        int step = 25 - i;
        double startP = lowPoint + (step * 0.0200);
        o[i] = startP;
        c[i] = startP + 0.0200;
        h[i] = c[i] + 0.0050;
        l[i] = startP - 0.0050;
        t[i] = baseTime - (datetime)((59 - i) * 3600);
        spreads[i] = 0.0010;
    }

    // Bars 15 down to 0: Consolidation near recovery peak
    double peakP = lowPoint + (10 * 0.0200); // 1.1005
    for (int i = 15; i >= 0; i--)
    {
        h[i] = peakP + 0.0020;
        l[i] = peakP - 0.0020;
        c[i] = peakP;
        o[i] = peakP;
        t[i] = baseTime - (datetime)((59 - i) * 3600);
        spreads[i] = 0.0010;
    }

    return RunScenarioPipeline(h, l, c, o, t, n, 0.0010, spreads, 0.0200);
}

//+------------------------------------------------------------------+
//| Scenario R-03 Generator: COVID Open Gap                         |
//+------------------------------------------------------------------+
uint ExecuteScenarioR03()
{
    int n = 60;
    double h[60], l[60], c[60], o[60], spreads[60];
    datetime t[60];

    datetime baseTime = 1583712000; // 2020-03-09 00:00 UTC

    // Bars 59 down to 25: Friday pre-gap trading at USOIL 41.00
    for (int i = 59; i >= 25; i--)
    {
        h[i] = 41.50;
        l[i] = 40.50;
        c[i] = 41.00;
        o[i] = 41.00;
        t[i] = baseTime - (datetime)((59 - i) * 3600);
        spreads[i] = 0.050;
    }

    // Bars 24 down to 0: Sunday open gap down at 31.00 ($10.00 gap) + consolidation
    for (int i = 24; i >= 0; i--)
    {
        h[i] = 31.50;
        l[i] = 30.50;
        c[i] = 31.00;
        o[i] = 31.00;
        t[i] = baseTime - (datetime)((59 - i) * 3600);
        spreads[i] = 0.050;
    }

    return RunScenarioPipeline(h, l, c, o, t, n, 0.100, spreads, 1.000);
}

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    CMNSLogger::Initialize(MNS_LOG_DEBUG, "MNS_RegressionTests.log");

    Print("=== MNS REGRESSION TEST RESULTS ===");
    int passCount = 0;
    int failCount = 0;

    // Run 3 synthetic scenarios
    uint computedR01 = ExecuteScenarioR01();
    uint computedR02 = ExecuteScenarioR02();
    uint computedR03 = ExecuteScenarioR03();

    // Baseline management
    string baselinePath = "MNS_RegressionBaseline.txt";

    if (InpRecordBaseline)
    {
        int fileHandle = FileOpen(baselinePath, FILE_WRITE | FILE_TXT | FILE_ANSI);
        if (fileHandle != INVALID_HANDLE)
        {
            FileWrite(fileHandle, "R-01=" + StringFormat("0x%08X", computedR01));
            FileWrite(fileHandle, "R-02=" + StringFormat("0x%08X", computedR02));
            FileWrite(fileHandle, "R-03=" + StringFormat("0x%08X", computedR03));
            FileClose(fileHandle);
            Print("[RECORD BASELINE] Successfully recorded baseline to ", baselinePath);
        }
        else
        {
            Print("[RECORD BASELINE] ERROR: Failed to write ", baselinePath);
        }

        Print("[RECORD BASELINE] R-01 Hash: ", StringFormat("0x%08X", computedR01));
        Print("[RECORD BASELINE] R-02 Hash: ", StringFormat("0x%08X", computedR02));
        Print("[RECORD BASELINE] R-03 Hash: ", StringFormat("0x%08X", computedR03));
    }

    // Read baseline file if available
    uint expectedR01 = EXPECTED_HASH_R01;
    uint expectedR02 = EXPECTED_HASH_R02;
    uint expectedR03 = EXPECTED_HASH_R03;

    int readFile = FileOpen(baselinePath, FILE_READ | FILE_TXT | FILE_ANSI);
    if (readFile != INVALID_HANDLE)
    {
        while (!FileIsEnding(readFile))
        {
            string line = FileReadString(readFile);
            if (StringFind(line, "R-01=") == 0)      expectedR01 = ParseHexHash(line);
            else if (StringFind(line, "R-02=") == 0) expectedR02 = ParseHexHash(line);
            else if (StringFind(line, "R-03=") == 0) expectedR03 = ParseHexHash(line);
        }
        FileClose(readFile);
    }

    // Compare & Assert R-01
    if (computedR01 == expectedR01)
    {
        Print("[PASS] R-01: Brexit Flash Crash — Hash ", StringFormat("0x%08X", computedR01), " matches baseline");
        passCount++;
    }
    else
    {
        Print("[FAIL] R-01: Brexit Flash Crash — Hash ", StringFormat("0x%08X", computedR01), " != expected ", StringFormat("0x%08X", expectedR01), " (REGRESSION DETECTED)");
        failCount++;
    }

    // Compare & Assert R-02
    if (computedR02 == expectedR02)
    {
        Print("[PASS] R-02: SNB Peg Removal — Hash ", StringFormat("0x%08X", computedR02), " matches baseline");
        passCount++;
    }
    else
    {
        Print("[FAIL] R-02: SNB Peg Removal — Hash ", StringFormat("0x%08X", computedR02), " != expected ", StringFormat("0x%08X", expectedR02), " (REGRESSION DETECTED)");
        failCount++;
    }

    // Compare & Assert R-03
    if (computedR03 == expectedR03)
    {
        Print("[PASS] R-03: COVID Gap Open — Hash ", StringFormat("0x%08X", computedR03), " matches baseline");
        passCount++;
    }
    else
    {
        Print("[FAIL] R-03: COVID Gap Open — Hash ", StringFormat("0x%08X", computedR03), " != expected ", StringFormat("0x%08X", expectedR03), " (REGRESSION DETECTED)");
        failCount++;
    }

    Print("Total: 3 scenarios | ", passCount, " PASS | ", failCount, " FAIL");
    Print("=== END REGRESSION TEST RESULTS ===");

    CMNSLogger::Close();

    // Return INIT_FAILED to self-remove from chart after running test suite
    return INIT_FAILED;
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
}
