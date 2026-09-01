# MNS Trading Engine — AI Prompt
# Testing Tier 6: Latency & Performance Micro-Benchmarking

You are the lead QA/software engineer for the **MNS Trading Engine**.
Your task is to implement the **Tier 6 Latency & Performance Benchmarking harness** — a standalone
Expert Advisor that wraps every major computation block in `GetMicrosecondCount()` measurements,
runs them across a statistically significant number of iterations using synthetic market data,
and produces a structured performance report confirming compliance with the MNS latency budget.

The release gate is: **full OnTick pipeline < 1.0 ms**. Any breach fails the tier.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, open and fully read the following files in order:

1. [TestingStrategy.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TestingStrategy.md) — Full testing strategy; Tier 6 spec at lines 70–76. **Read the thresholds carefully.**
2. [MNSProfiler.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSProfiler.mqh) — **Read this entire file first.** MNS already has a profiler wrapper. Use or extend it — do NOT reinvent the wheel.
3. [MNSCore.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSCore.mqh) — Engine bootstrap.
4. [MNSTypes.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSTypes.mqh) — All structs and enums used by the engines.
5. [CSwingDetector.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CSwingDetector.mqh) — Stage 1 (swing detection); most frequently called on every tick.
6. [CStructureEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CStructureEngine.mqh) — Stage 2.
7. [CBreakDetector.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CBreakDetector.mqh) — Stage 3.
8. [CLiquidityEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CLiquidityEngine.mqh) — Stage 4.
9. [CPOIEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CPOIEngine.mqh) — Stage 5; the largest engine — likely the bottleneck. Read the `Update()` function call signature carefully.
10. [CObjectiveEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CObjectiveEngine.mqh) — Stage 6.
11. [CConfirmationEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CConfirmationEngine.mqh) — Stage 7 (final confirmation output).
12. [MNS_EA.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Experts/MNS_EA/MNS_EA.mq5) — Inspect `OnTick()` to understand the exact DAG call sequence and array copy pattern. The benchmark must mirror this call sequence exactly.
13. [MNSTestSuite.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSTestSuite.mqh) — MNS_ASSERT macro; use for threshold assertions.

---

## Goal

Create a new file:
**`Experts/MNS_TestHarness/MNS_LatencyBenchmark.mq5`**

This harness:
- Constructs synthetic market data (1000-candle arrays) once in `OnInit()`.
- Runs the full engine pipeline for `N = 1000` simulated ticks.
- Measures per-stage and end-to-end latency using `GetMicrosecondCount()`.
- Computes: minimum, maximum, mean, median, and 99th-percentile latency per stage.
- Compares each result against defined thresholds and passes/fails.
- Outputs a formatted performance report to the Experts journal.
- Returns `INIT_FAILED` to self-remove.

---

## Latency Thresholds (from TestingStrategy.md)

| Metric | Threshold |
|---|---|
| Full OnTick pipeline (all 7 stages) | **< 1000 µs** (1.0 ms) |
| POI / Zone update on new candle | **< 5000 µs** (5.0 ms) |
| Per-stage (CSwingDetector alone) | **< 200 µs** |
| Per-stage (CStructureEngine alone) | **< 150 µs** |
| Per-stage (CBreakDetector alone) | **< 100 µs** |
| Per-stage (CLiquidityEngine alone) | **< 150 µs** |
| Per-stage (CPOIEngine alone) | **< 500 µs** |
| Per-stage (CObjectiveEngine alone) | **< 100 µs** |
| Per-stage (CConfirmationEngine alone) | **< 50 µs** |

---

## Benchmark Measurement Structure

Implement `struct SLatencyStats` to hold:
```mql5
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
```

---

## Benchmark Scenarios

### Benchmark L-01: Normal Tick (Mid-Candle)
- 1000 iterations, same candle arrays (no new candle signal).
- Only `CSwingDetector`, `CStructureEngine`, `CBreakDetector`, `CLiquidityEngine`, `CConfirmationEngine` run.
- `CPOIEngine` skipped (no new candle = no zone refresh).
- Assert: p99 of full pipeline < 1000 µs.

### Benchmark L-02: New Candle Tick (Full Pipeline Including POI)
- 200 iterations simulating a new M15 candle closure.
- All 7 stages run including `CPOIEngine::Update()`.
- Assert: p99 of full pipeline < 5000 µs (relaxed threshold for candle close).

### Benchmark L-03: CPOIEngine Isolation (Zone Rebuild Stress)
- 500 iterations calling only `CPOIEngine::Update()` in isolation on 1000-candle arrays.
- Measures POI engine alone.
- Assert: p99 < 5000 µs.

### Benchmark L-04: CSwingDetector Isolation
- 1000 iterations calling only `CSwingDetector::Update()` in isolation.
- Assert: p99 < 200 µs.

### Benchmark L-05: CConfirmationEngine Isolation
- 1000 iterations calling only `CConfirmationEngine::Evaluate()` in isolation.
- Assert: p99 < 50 µs.

---

## Warmup

Before starting measurements, run `N = 100` warmup iterations (not measured) to allow:
- MQL5 JIT compilation to complete.
- CPU cache to warm up with the engine's data patterns.

---

## Output Format

```
=== MNS LATENCY BENCHMARK RESULTS ===
Hardware: Intel i7-10750H | 1920x1080 chart | 1000-candle arrays | N=1000 iters

Stage                   | Min(µs) | Max(µs) | Mean(µs) | P99(µs)  | Threshold | Status
------------------------|---------|---------|----------|----------|-----------|-------
L-01 Full OnTick        |    45.2 |   312.4 |    112.3 |    890.1 |   1000 µs | PASS
L-02 Full OnTick+POI    |   210.4 |  1824.1 |    945.2 |   4812.3 |   5000 µs | PASS
L-03 CPOIEngine Only    |   185.0 |  1542.0 |    823.1 |   4211.5 |   5000 µs | PASS
L-04 CSwingDetector     |    12.1 |    88.4 |     34.2 |    178.9 |    200 µs | PASS
L-05 CConfirmation      |     2.3 |    18.7 |      8.1 |     44.2 |     50 µs | PASS

Total: 5 benchmarks | 5 PASS | 0 FAIL

⚡ MNS LATENCY BUDGET: COMPLIANT — All thresholds met.
=== END LATENCY BENCHMARK RESULTS ===
```

If any threshold is breached:
```
⚠️  MNS LATENCY BUDGET: BREACH — 1 threshold violated. See L-03 above.
    CPOIEngine P99 (6200.1 µs) exceeds 5000 µs threshold.
    Recommended action: Profile CPOIEngine::Update() for hotspots using GetMicrosecondCount() inline.
```

---

## Constraints

> [!IMPORTANT]
> - Do **NOT** modify any file under `Include/MNS/`. Benchmarking wraps the engines externally.
> - Use `GetMicrosecondCount()` (MQL5 built-in) for all timing. Do NOT use `GetTickCount()` — it has 15ms resolution.
> - Synthetic data arrays (1000 candles of EURUSD-style prices) must be pre-built in `OnInit()` before timing starts.
> - The median and p99 calculation must sort the `double measurements[]` array — implement a simple `ArraySort()` wrapper.
> - Include `input int InpIterations = 1000;` so the iteration count can be changed from the EA inputs panel.
> - Ensure NO `ChartRedraw()`, `Print()`, or file I/O occurs inside the timed loops — only after completion.

---

## Verification

```powershell
powershell.exe -ExecutionPolicy Bypass -File ./tools/Build-And-Archive.ps1 -Module "Tier6_LatencyBenchmark" -SkipGit
```
Expected: `0 errors, 0 warnings`.

After running on a live chart, the resulting benchmark report should be saved to:
`MQL5\Files\MNS_LatencyReport_YYYYMMDD_HHMMSS.txt`
using `FileWrite()` for permanent archiving and inclusion in the release package.
