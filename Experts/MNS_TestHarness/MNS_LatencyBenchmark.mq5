//+------------------------------------------------------------------+
//|                                       MNS_LatencyBenchmark.mq5   |
//|                              MNS Trading Engine — Test Harness   |
//|                                                                  |
//| Purpose:                                                         |
//|   Tier 6 Latency & Performance Micro-Benchmarking harness.      |
//|   Wraps engine pipeline computation blocks in GetMicrosecondCount()|
//|   measurements across statistical iterations using synthetic     |
//|   market data, verifying compliance with the MNS latency budget.  |
//|                                                                  |
//| Thresholds:                                                      |
//|   - L-01 Full OnTick Pipeline:        < 1000 µs (1.0 ms)         |
//|   - L-02 Full OnTick + POI Refresh:   < 5000 µs (5.0 ms)         |
//|   - L-03 CPOIEngine Isolation:        < 5000 µs (5.0 ms)         |
//|   - L-04 CSwingDetector Isolation:    <  200 µs                  |
//|   - L-05 CConfirmationEngine Isolation:<   50 µs                  |
//|                                                                  |
//| Rules:                                                           |
//|   - Runs inside OnInit(), prints performance report, saves to    |
//|     MQL5\Files\MNS_LatencyReport_YYYYMMDD_HHMMSS.txt, and        |
//|     returns INIT_FAILED to self-remove from chart.               |
//|                                                                  |
//| Version: 1.00                                                    |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#property copyright "MNS Trading Engine"
#property version   "1.00"
#property strict

//--- Inputs
input int InpIterations = 1000; // Benchmark Iterations (N)

#include "..\..\Include\MNS\MNSCore.mqh"
#define MNS_LOG_ENABLE
#include "..\..\Include\MNS\MNSLogger.mqh"
#include "..\..\Include\MNS\MNSTypes.mqh"
#include "..\..\Include\MNS\MNSProfiler.mqh"
#include "..\..\Include\MNS\CSwingDetector.mqh"
#include "..\..\Include\MNS\CStructureEngine.mqh"
#include "..\..\Include\MNS\CBreakDetector.mqh"
#include "..\..\Include\MNS\COrderFlowEngine.mqh"
#include "..\..\Include\MNS\CDeliveryStructureEngine.mqh"
#include "..\..\Include\MNS\CLiquidityEngine.mqh"
#include "..\..\Include\MNS\CPOIEngine.mqh"
#include "..\..\Include\MNS\CObjectiveEngine.mqh"
#include "..\..\Include\MNS\CConfirmationEngine.mqh"
#include "..\..\Include\MNS\MNSVolatility.mqh"
#include "..\..\Include\MNS\MNSTestSuite.mqh"

//+------------------------------------------------------------------+
//| Latency Statistics Struct                                        |
//+------------------------------------------------------------------+
struct SLatencyStats
{
    string stageName;
    double minUs;
    double maxUs;
    double meanUs;
    double medianUs;
    double p99Us;
    double thresholdUs;
    bool   passed;        // true if p99Us < thresholdUs
};

//+------------------------------------------------------------------+
//| Helper: Compute Statistics from Raw Microsecond Measurements    |
//+------------------------------------------------------------------+
SLatencyStats ComputeStats(string stageName, double &measurements[], double thresholdUs)
{
    SLatencyStats stats;
    stats.stageName = stageName;
    stats.thresholdUs = thresholdUs;
    int n = ArraySize(measurements);
    if (n <= 0)
    {
        stats.minUs = stats.maxUs = stats.meanUs = stats.medianUs = stats.p99Us = 0.0;
        stats.passed = false;
        return stats;
    }

    ArraySort(measurements);
    stats.minUs = measurements[0];
    stats.maxUs = measurements[n - 1];

    double sum = 0.0;
    for (int i = 0; i < n; i++)
    {
        sum += measurements[i];
    }
    stats.meanUs = sum / (double)n;

    if (n % 2 == 0)
        stats.medianUs = (measurements[n / 2 - 1] + measurements[n / 2]) / 2.0;
    else
        stats.medianUs = measurements[n / 2];

    int p99Idx = (int)MathFloor(0.99 * (double)n);
    if (p99Idx >= n) p99Idx = n - 1;
    stats.p99Us = measurements[p99Idx];

    stats.passed = (stats.p99Us < thresholdUs);
    return stats;
}

//+------------------------------------------------------------------+
//| Helper: Generate Synthetic Candle Series                         |
//+------------------------------------------------------------------+
void GenerateSyntheticData(int count, double basePrice, double &high[], double &low[], double &close[], double &open[], datetime &time[])
{
    ArrayResize(high, count);
    ArrayResize(low, count);
    ArrayResize(close, count);
    ArrayResize(open, count);
    ArrayResize(time, count);

    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(time, true);

    datetime startTime = TimeCurrent() - (count * 900); // M15 bars
    double currentPrice = basePrice;

    for (int i = count - 1; i >= 0; i--)
    {
        double change = (MathRand() % 100 - 48.0) * 0.0001; // Trending upward slight bias
        double o = currentPrice;
        double c = o + change;
        double h = MathMax(o, c) + (MathRand() % 30) * 0.0001;
        double l = MathMin(o, c) - (MathRand() % 30) * 0.0001;

        open[i]  = NormalizeDouble(o, 5);
        high[i]  = NormalizeDouble(h, 5);
        low[i]   = NormalizeDouble(l, 5);
        close[i] = NormalizeDouble(c, 5);
        time[i]  = startTime + ((count - 1 - i) * 900);

        currentPrice = c;
    }
}

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    CMNSLogger::Initialize(MNS_LOG_INFO, "MNS_LatencyBenchmark.log");

    int barsCount = 1000;
    double high[], low[], close[], open[];
    datetime time[];
    GenerateSyntheticData(barsCount, 1.2000, high, low, close, open, time);

    double atr14 = CMNSVolatility::CalculateATR14(high, low, close, barsCount);
    if (atr14 <= 0.0) atr14 = 0.0015;

    double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if (pointSize <= 0.0) pointSize = _Point;
    double minBreakDist = MathMax(2.0 * pointSize, 0.10 * atr14);

    // Initialize engines
    CSwingDetector           swingDet;
    CStructureEngine         structEng;
    CBreakDetector           breakDet;
    COrderFlowEngine         ofEng;
    CDeliveryStructureEngine delEng;
    CLiquidityEngine         liqEng;
    CPOIEngine               poiEng;
    CObjectiveEngine         objEng;
    CConfirmationEngine      confEng;

    swingDet.Initialize(15, 5);
    structEng.Initialize(minBreakDist);
    breakDet.Initialize();
    ofEng.Initialize();
    delEng.Initialize();
    liqEng.Initialize(0);
    poiEng.Initialize();
    objEng.Initialize();
    confEng.Initialize();

    int totalIters = MathMax(100, InpIterations);
    int warmupIters = 100;

    // --- Warmup Phase ---
    for (int w = 0; w < warmupIters; w++)
    {
        swingDet.Update(high, low, time, barsCount, 0);
        structEng.Update(swingDet, atr14);
        breakDet.Update(swingDet, structEng, high, low, close, open, time, barsCount, 0, atr14);
        ofEng.Update(swingDet, structEng, breakDet, high, low, close, open, time, barsCount, 0, atr14);
        delEng.Update(swingDet, structEng, breakDet, ofEng, high, low, close, open, time, barsCount, 0, atr14, 0.0);
        liqEng.Update(swingDet, delEng, high, low, close, open, time, barsCount, 0, atr14, minBreakDist);
        poiEng.Update(swingDet, structEng, breakDet, liqEng, delEng, high, low, close, open, time, barsCount, 0, atr14);
        objEng.Update(swingDet, structEng, breakDet, ofEng, delEng, liqEng, poiEng, high, low, close, open, time, barsCount, 0, atr14);
        confEng.Update(swingDet, structEng, breakDet, ofEng, delEng, liqEng, poiEng, objEng, high, low, close, open, time, barsCount, 0, atr14);
    }

    // --- BENCHMARK L-01: Full OnTick Pipeline (Normal Tick, mid-candle tick update) ---
    double l01Us[];
    ArrayResize(l01Us, totalIters);
    int midCandlePrevCalc = barsCount - 1;

    for (int i = 0; i < totalIters; i++)
    {
        ulong start = GetMicrosecondCount();

        swingDet.Update(high, low, time, barsCount, midCandlePrevCalc);
        structEng.Update(swingDet, atr14);
        breakDet.Update(swingDet, structEng, high, low, close, open, time, barsCount, midCandlePrevCalc, atr14);
        ofEng.Update(swingDet, structEng, breakDet, high, low, close, open, time, barsCount, midCandlePrevCalc, atr14);
        delEng.Update(swingDet, structEng, breakDet, ofEng, high, low, close, open, time, barsCount, midCandlePrevCalc, atr14, 0.0);
        liqEng.Update(swingDet, delEng, high, low, close, open, time, barsCount, midCandlePrevCalc, atr14, minBreakDist);
        objEng.Update(swingDet, structEng, breakDet, ofEng, delEng, liqEng, poiEng, high, low, close, open, time, barsCount, midCandlePrevCalc, atr14);
        confEng.Update(swingDet, structEng, breakDet, ofEng, delEng, liqEng, poiEng, objEng, high, low, close, open, time, barsCount, midCandlePrevCalc, atr14);

        l01Us[i] = (double)(GetMicrosecondCount() - start);
    }

    // --- BENCHMARK L-02: Full OnTick Pipeline + POI Refresh (New Candle Tick) ---
    int l02Iters = MathMin(200, totalIters);
    double l02Us[];
    ArrayResize(l02Us, l02Iters);
    for (int i = 0; i < l02Iters; i++)
    {
        ulong start = GetMicrosecondCount();

        swingDet.Update(high, low, time, barsCount, 0);
        structEng.Update(swingDet, atr14);
        breakDet.Update(swingDet, structEng, high, low, close, open, time, barsCount, 0, atr14);
        ofEng.Update(swingDet, structEng, breakDet, high, low, close, open, time, barsCount, 0, atr14);
        delEng.Update(swingDet, structEng, breakDet, ofEng, high, low, close, open, time, barsCount, 0, atr14, 0.0);
        liqEng.Update(swingDet, delEng, high, low, close, open, time, barsCount, 0, atr14, minBreakDist);
        poiEng.Update(swingDet, structEng, breakDet, liqEng, delEng, high, low, close, open, time, barsCount, 0, atr14);
        objEng.Update(swingDet, structEng, breakDet, ofEng, delEng, liqEng, poiEng, high, low, close, open, time, barsCount, 0, atr14);
        confEng.Update(swingDet, structEng, breakDet, ofEng, delEng, liqEng, poiEng, objEng, high, low, close, open, time, barsCount, 0, atr14);

        l02Us[i] = (double)(GetMicrosecondCount() - start);
    }

    // --- BENCHMARK L-03: CPOIEngine Isolation ---
    int l03Iters = MathMin(500, totalIters);
    double l03Us[];
    ArrayResize(l03Us, l03Iters);
    for (int i = 0; i < l03Iters; i++)
    {
        ulong start = GetMicrosecondCount();
        poiEng.Update(swingDet, structEng, breakDet, liqEng, delEng, high, low, close, open, time, barsCount, 0, atr14);
        l03Us[i] = (double)(GetMicrosecondCount() - start);
    }

    // --- BENCHMARK L-04: CSwingDetector Isolation ---
    double l04Us[];
    ArrayResize(l04Us, totalIters);
    for (int i = 0; i < totalIters; i++)
    {
        ulong start = GetMicrosecondCount();
        swingDet.Update(high, low, time, barsCount, 0);
        l04Us[i] = (double)(GetMicrosecondCount() - start);
    }

    // --- BENCHMARK L-05: CConfirmationEngine Isolation ---
    double l05Us[];
    ArrayResize(l05Us, totalIters);
    for (int i = 0; i < totalIters; i++)
    {
        ulong start = GetMicrosecondCount();
        confEng.Update(swingDet, structEng, breakDet, ofEng, delEng, liqEng, poiEng, objEng, high, low, close, open, time, barsCount, 0, atr14);
        l05Us[i] = (double)(GetMicrosecondCount() - start);
    }

    // Compute stats for all 5 benchmark scenarios
    SLatencyStats stats[5];
    stats[0] = ComputeStats("L-01 Full OnTick",        l01Us, 1000.0);
    stats[1] = ComputeStats("L-02 Full OnTick+POI",    l02Us, 5000.0);
    stats[2] = ComputeStats("L-03 CPOIEngine Only",    l03Us, 5000.0);
    stats[3] = ComputeStats("L-04 CSwingDetector",     l04Us,  200.0);
    stats[4] = ComputeStats("L-05 CConfirmation",      l05Us,   50.0);

    int totalPass = 0;
    int totalFail = 0;
    for (int i = 0; i < 5; i++)
    {
        if (stats[i].passed) totalPass++;
        else totalFail++;
    }

    // --- Format and Print Report to Journal & File ---
    Print("=== MNS LATENCY BENCHMARK RESULTS ===");
    Print(StringFormat("Hardware: MetaTrader 5 Terminal | %d-candle synthetic arrays | N=%d iters", barsCount, totalIters));
    Print("");
    Print("Stage                   | Min(µs) | Max(µs) | Mean(µs) | P99(µs)  | Threshold | Status");
    Print("------------------------|---------|---------|----------|----------|-----------|-------");

    for (int i = 0; i < 5; i++)
    {
        string statusStr = stats[i].passed ? "PASS" : "FAIL";
        Print(StringFormat("%-23s | %7.1f | %7.1f | %8.1f | %8.1f | %6.0f µs | %s",
                           stats[i].stageName,
                           stats[i].minUs,
                           stats[i].maxUs,
                           stats[i].meanUs,
                           stats[i].p99Us,
                           stats[i].thresholdUs,
                           statusStr));
    }

    Print("");
    Print(StringFormat("Total: 5 benchmarks | %d PASS | %d FAIL", totalPass, totalFail));
    Print("");

    if (totalFail == 0)
    {
        Print("⚡ MNS LATENCY BUDGET: COMPLIANT — All thresholds met.");
    }
    else
    {
        Print("⚠️  MNS LATENCY BUDGET: BREACH — Threshold violation(s) detected.");
    }
    Print("=== END LATENCY BENCHMARK RESULTS ===");

    // Save report to file
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string timeStr = StringFormat("%04d%02d%02d_%02d%02d%02d", dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
    string reportFileName = StringFormat("MNS_LatencyReport_%s.txt", timeStr);

    int fileHandle = FileOpen(reportFileName, FILE_WRITE | FILE_TXT);
    if (fileHandle != INVALID_HANDLE)
    {
        FileWriteString(fileHandle, "=== MNS LATENCY BENCHMARK REPORT ===\r\n");
        FileWriteString(fileHandle, StringFormat("Generated: %04d-%02d-%02d %02d:%02d:%02d\r\n", dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec));
        FileWriteString(fileHandle, StringFormat("Iterations: %d | Synthetic Bars: %d\r\n\r\n", totalIters, barsCount));
        FileWriteString(fileHandle, "Stage                   | Min(us) | Max(us) | Mean(us) | P99(us)  | Threshold | Status\r\n");
        FileWriteString(fileHandle, "------------------------|---------|---------|----------|----------|-----------|-------\r\n");

        for (int i = 0; i < 5; i++)
        {
            string line = StringFormat("%-23s | %7.1f | %7.1f | %8.1f | %8.1f | %6.0f us | %s\r\n",
                                       stats[i].stageName,
                                       stats[i].minUs,
                                       stats[i].maxUs,
                                       stats[i].meanUs,
                                       stats[i].p99Us,
                                       stats[i].thresholdUs,
                                       stats[i].passed ? "PASS" : "FAIL");
            FileWriteString(fileHandle, line);
        }

        FileWriteString(fileHandle, StringFormat("\r\nTotal: 5 benchmarks | %d PASS | %d FAIL\r\n", totalPass, totalFail));
        if (totalFail == 0)
            FileWriteString(fileHandle, "MNS LATENCY BUDGET: COMPLIANT -- All thresholds met.\r\n");
        else
            FileWriteString(fileHandle, "MNS LATENCY BUDGET: BREACH -- Threshold violation detected.\r\n");

        FileClose(fileHandle);
        Print(StringFormat("Benchmark report saved to MQL5\\Files\\%s", reportFileName));
    }

    CMNSLogger::Close();
    return INIT_FAILED;
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
}
