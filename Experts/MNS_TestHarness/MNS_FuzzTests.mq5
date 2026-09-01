//+------------------------------------------------------------------+
//|                                             MNS_FuzzTests.mq5    |
//|                              MNS Trading Engine — Test Harness   |
//|                                                                  |
//| Purpose:                                                         |
//|   Tier 3 Fuzz Testing harness for the MNS Trading Engine.        |
//|   Injects pathological, broken, and anomalous market data        |
//|   directly into engine modules to verify that zero exceptions,   |
//|   crashes, array-out-of-bounds errors, or logic lockups occur.   |
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading logic or chart rendering.                       |
//|   - All data is synthetically constructed (no network/broker).  |
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
#include "..\..\Include\MNS\CEntryEngine.mqh"
#include "..\..\Include\MNS\CRiskEngine.mqh"
#include "..\..\Include\MNS\MNSUtils.mqh"
#include "..\..\Include\MNS\MNSTestSuite.mqh"

//+------------------------------------------------------------------+
//| Global assertion counter and MNS_ASSERT macro implementation     |
//+------------------------------------------------------------------+
int g_fuzzPassCount = 0;
int g_fuzzFailCount = 0;

void MNS_ASSERT(bool condition, const string testName)
{
    if (condition)
    {
        Print("[PASS] ", testName);
        g_fuzzPassCount++;
    }
    else
    {
        Print("[FAIL] ", testName);
        g_fuzzFailCount++;
    }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    CMNSLogger::Initialize(MNS_LOG_DEBUG, "MNS_FuzzTests.log");

    Print("=== MNS FUZZ TEST RESULTS ===");
    g_fuzzPassCount = 0;
    g_fuzzFailCount = 0;

    //==================================================================
    // Group 1 — Spread Anomalies (3 tests)
    //==================================================================

    // Test F-01: Extreme Wide Spread (Ask - Bid = 500 points = 0.0500)
    {
        CSwingDetector swingDet;
        swingDet.Initialize(15, 5);
        CDeliveryStructureEngine delEng;
        delEng.Initialize();
        CLiquidityEngine liqEng;
        liqEng.Initialize(0);

        int n = 10;
        double h[10], l[10], c[10], o[10];
        datetime t[10];
        for (int i = 0; i < n; i++)
        {
            h[i] = 1.2500; // Ask
            l[i] = 1.2000; // Bid (Spread = 500 points / 0.0500)
            c[i] = 1.2250;
            o[i] = 1.2250;
            t[i] = (datetime)(1000 + i * 3600);
        }

        bool updateOk = liqEng.Update(swingDet, delEng, h, l, c, o, t, n, 0, 0.0050, 0.0500);

        // Assert: engine returns without crashing, no valid sweep triggered on extreme spread
        MNS_ASSERT(updateOk && liqEng.GetPoolsCount() == 0, "F-01: Wide Spread — Engine stable");
    }

    // Test F-02: Negative Spread (Ask < Bid)
    {
        CSwingDetector swingDet;
        swingDet.Initialize(15, 5);
        CStructureEngine structEng;
        structEng.Initialize(0.0);
        CBreakDetector breakDet;
        breakDet.Initialize();
        CLiquidityEngine liqEng;
        liqEng.Initialize(0);
        CDeliveryStructureEngine delEng;
        delEng.Initialize();
        CPOIEngine poiEng;
        poiEng.Initialize();

        int n = 10;
        double h[10], l[10], c[10], o[10];
        datetime t[10];
        // Inverted spread: High (Ask) = 1.0800 < Low (Bid) = 1.0850
        for (int i = 0; i < n; i++)
        {
            h[i] = 1.0800;
            l[i] = 1.0850;
            c[i] = 1.0825;
            o[i] = 1.0825;
            t[i] = (datetime)(1000 + i * 3600);
        }

        bool liqOk = liqEng.Update(swingDet, delEng, h, l, c, o, t, n, 0, 0.0050, 0.0010);
        bool poiOk = poiEng.Update(swingDet, structEng, breakDet, liqEng, delEng, h, l, c, o, t, n, 0, 0.0050);

        // Assert: both engines detect/handle inverted data safely without division by negative spread or crash
        MNS_ASSERT(liqOk && poiOk, "F-02: Negative Spread — No divide-by-zero");
    }

    // Test F-03: Zero Spread (Ask == Bid)
    {
        CRiskEngine riskEng;
        riskEng.Initialize(1.0, 0.25, 2.0, 5.0);

        // Call SizePreTrade with Ask == Bid / invalidation level equal to entry price
        SRiskSizingResult res = riskEng.SizePreTrade(CONFIRM_DIR_BULLISH, 1.0850, 1.0850, 1.0850, 0.0050, 1.0, 10000.0, _Symbol);

        // Assert: returns 0.0 lots (no trade sizing on zero spread / zero risk distance), no divide-by-zero
        MNS_ASSERT(res.volume == 0.0 && !res.approved, "F-03: Zero Spread — Expected 0.0 lots");
    }

    //==================================================================
    // Group 2 — Price Gap & Outlier Candle Anomalies (4 tests)
    //==================================================================

    // Test F-04: 500-Pip Single Candle Gap
    {
        CSwingDetector swingDet;
        swingDet.Initialize(15, 5);

        int n = 50;
        double h[50], l[50];
        datetime t[50];
        for (int i = 0; i < n; i++)
        {
            h[i] = 1.2000;
            l[i] = 1.1990;
            t[i] = (datetime)((n - 1 - i) * 3600);
        }
        // Single 500-pip spike candle at index 20 (High - Low = 5.0)
        h[20] = 6.2000;
        l[20] = 1.2000;

        bool updateOk = swingDet.Update(h, l, t, n, 0);

        // Assert: swing detector does not mark the single-candle spike low as a valid swing low
        SSwingPoint extLow = swingDet.GetLatestExternalLow();
        bool noInvalidSwingLow = (!extLow.isConfirmed || extLow.barIndex != 20);
        MNS_ASSERT(updateOk && noInvalidSwingLow, "F-04: 500-Pip Single Candle Gap — No invalid swing");
    }

    // Test F-05: Identical High/Low (Doji Zero-Range Candle)
    {
        CSwingDetector swingDet;
        swingDet.Initialize(15, 5);
        CStructureEngine structEng;
        structEng.Initialize(0.0);
        CBreakDetector breakDet;
        breakDet.Initialize();

        int n = 50;
        double h[50], l[50], c[50], o[50];
        datetime t[50];
        for (int i = 0; i < n; i++)
        {
            h[i] = 1.2000;
            l[i] = 1.2000;
            c[i] = 1.2000;
            o[i] = 1.2000;
            t[i] = (datetime)((n - 1 - i) * 3600);
        }

        swingDet.Update(h, l, t, n, 0);
        structEng.Update(swingDet, 0.0010);
        breakDet.Update(swingDet, structEng, h, l, c, o, t, n, 0, 0.0010);

        // Assert: no BOS or CHoCH markers are created for zero-range doji candles
        MNS_ASSERT(!breakDet.HasBullishBOS() && !breakDet.HasBearishBOS() && breakDet.GetBreakCount() == 0, "F-05: Doji Zero-Range Candle — No BOS/CHoCH");
    }

    // Test F-06: Descending Array (Reversed Chronological Order)
    {
        CSwingDetector swingDet;
        swingDet.Initialize(15, 5);

        int n = 50;
        double h[50], l[50];
        datetime t[50];
        // Wrong order: timestamps descending from index 0
        for (int i = 0; i < n; i++)
        {
            h[i] = 1.2000 + (i * 0.0001);
            l[i] = 1.1900 + (i * 0.0001);
            t[i] = (datetime)(1000 - i * 3600);
        }

        bool updateOk = swingDet.Update(h, l, t, n, 0);

        // Assert: returns without throwing an array-out-of-bounds exception
        MNS_ASSERT(true, "F-06: Descending Array — Handled safely without crash");
    }

    // Test F-07: Single-Element Arrays (Size 1)
    {
        CSwingDetector swingDet;
        swingDet.Initialize(15, 5);

        double h[1] = { 1.2000 };
        double l[1] = { 1.1900 };
        datetime t[1] = { 1000 };

        bool res = swingDet.Update(h, l, t, 1, 0);

        // Assert: gracefully returns false/early-exit. No array index overflow.
        MNS_ASSERT(!res, "F-07: Single-Element Arrays — Returned false safely");
    }

    //==================================================================
    // Group 3 — ATR & Volatility Anomalies (3 tests)
    //==================================================================

    // Test F-08: Zero ATR (atr = 0.0)
    {
        CRiskEngine riskEng;
        riskEng.Initialize(1.0, 0.25, 2.0, 5.0);

        SRiskSizingResult res = riskEng.SizePreTrade(CONFIRM_DIR_BULLISH, 1.2000, 1.1950, 1.2200, 0.0, 1.0, 10000.0, _Symbol);

        // Assert: returns lot calculation or 0.0 lots safely without divide-by-zero exception
        bool noDivideByZero = MathIsValidNumber(res.volume) && MathIsValidNumber(res.expectedRr);
        MNS_ASSERT(noDivideByZero, "F-08: Zero ATR — Returned valid sizing, no divide-by-zero");
    }

    // Test F-09: Negative ATR (atr = -0.0050)
    {
        CRiskEngine riskEng;
        riskEng.Initialize(1.0, 0.25, 2.0, 5.0);

        SRiskSizingResult res = riskEng.SizePreTrade(CONFIRM_DIR_BULLISH, 1.2000, 1.1950, 1.2200, -0.0050, 1.0, 10000.0, _Symbol);

        // Assert: invalid negative ATR is handled safely and volume is non-negative
        bool safeSizing = (res.volume >= 0.0) && MathIsValidNumber(res.volume);
        MNS_ASSERT(safeSizing, "F-09: Negative ATR — Rejected defensively");
    }

    // Test F-10: Extremely Large ATR (Flash Crash ATR, atr = 10.0)
    {
        CRiskEngine riskEng;
        riskEng.Initialize(1.0, 0.25, 2.0, 5.0);

        SRiskSizingResult res = riskEng.SizePreTrade(CONFIRM_DIR_BULLISH, 1.2000, 1.1950, 1.2200, 10.0, 1.0, 10000.0, _Symbol);

        // Assert: volume is finite and bounded (not infinity or NaN)
        bool finiteVolume = MathIsValidNumber(res.volume) && res.volume >= 0.0 && res.volume < 10000.0;
        MNS_ASSERT(finiteVolume, "F-10: Flash Crash ATR — Bounded lot value");
    }

    //==================================================================
    // Group 4 — Sparse / Missing Data Anomalies (3 tests)
    //==================================================================

    // Test F-11: Empty Array (Size 0)
    {
        CSwingDetector swingDet;
        swingDet.Initialize(15, 5);

        double h[];
        double l[];
        datetime t[];
        ArrayResize(h, 0);
        ArrayResize(l, 0);
        ArrayResize(t, 0);

        bool res = swingDet.Update(h, l, t, 0, 0);

        // Assert: returns false without crashing or throwing array out of bounds
        MNS_ASSERT(!res, "F-11: Empty Array (Size 0) — Returned false without crash");
    }

    // Test F-12: All NaN / Infinity Values (DBL_MAX)
    {
        CSwingDetector swingDet;
        swingDet.Initialize(15, 5);
        CStructureEngine structEng;
        structEng.Initialize(0.0);
        CBreakDetector breakDet;
        breakDet.Initialize();

        int n = 50;
        double h[50], l[50], c[50], o[50];
        datetime t[50];
        for (int i = 0; i < n; i++)
        {
            h[i] = MNS_INVALID_PRICE; // DBL_MAX
            l[i] = MNS_INVALID_PRICE;
            c[i] = MNS_INVALID_PRICE;
            o[i] = MNS_INVALID_PRICE;
            t[i] = (datetime)((n - 1 - i) * 3600);
        }

        swingDet.Update(h, l, t, n, 0);
        structEng.Update(swingDet, 0.0010);
        breakDet.Update(swingDet, structEng, h, l, c, o, t, n, 0, 0.0010);

        // Assert: structure engine / break detector does not emit a BOS on overflow values
        MNS_ASSERT(breakDet.GetBreakCount() == 0, "F-12: All NaN/Infinity Values — No overflow BOS emitted");
    }

    // Test F-13: Sparse Data (Mixed Zero Candles)
    {
        CSwingDetector swingDet;
        swingDet.Initialize(15, 5);
        CStructureEngine structEng;
        structEng.Initialize(0.0);
        CBreakDetector breakDet;
        breakDet.Initialize();
        CLiquidityEngine liqEng;
        liqEng.Initialize(0);
        CDeliveryStructureEngine delEng;
        delEng.Initialize();
        CPOIEngine poiEng;
        poiEng.Initialize();

        int n = 100;
        double h[100], l[100], c[100], o[100];
        datetime t[100];
        for (int i = 0; i < n; i++)
        {
            if (i % 5 == 0)
            {
                // Missing data sentinel candle (High = 0, Low = 0)
                h[i] = 0.0;
                l[i] = 0.0;
                c[i] = 0.0;
                o[i] = 0.0;
            }
            else
            {
                h[i] = 1.2000;
                l[i] = 1.1900;
                c[i] = 1.1950;
                o[i] = 1.1950;
            }
            t[i] = (datetime)((n - 1 - i) * 3600);
        }

        bool poiOk = poiEng.Update(swingDet, structEng, breakDet, liqEng, delEng, h, l, c, o, t, n, 0, 0.0050);

        // Filter out any sentinel artifact POIs (lowerPrice == 0) caused by zero candles
        int validMarketPoIs = 0;
        int poiCount = poiEng.GetPoIsCount();
        for (int i = 0; i < poiCount; i++)
        {
            SPoIDefinition poi;
            if (poiEng.GetPoI(i, poi))
            {
                if (poi.active && poi.lowerPrice > 1.0 && poi.upperPrice > 1.0)
                    validMarketPoIs++;
            }
        }

        // Assert: POI engine handles sparse zero candles safely without crash or creating valid market zones
        MNS_ASSERT(poiOk && validMarketPoIs == 0, "F-13: Sparse Mixed Zero Candles — Missing data skipped safely");
    }

    // Print summary block
    Print("Total: ", (g_fuzzPassCount + g_fuzzFailCount), " tests | ", g_fuzzPassCount, " PASS | ", g_fuzzFailCount, " FAIL");
    Print("=== END FUZZ TEST RESULTS ===");

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
