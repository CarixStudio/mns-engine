# MNS Trading Engine — AI Prompt
# Testing Tier 3: Fuzz Testing (Chaotic Input Robustness)

You are the lead QA/software engineer for the **MNS Trading Engine**.
Your task is to implement the **Tier 3 Fuzz Testing harness** — a standalone Expert Advisor
that injects pathological, broken, and anomalous market data directly into the MNS engine
modules to verify that zero exceptions, crashes, array-out-of-bounds errors, or logic lockups occur.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, open and fully read the following files in order:

1. [TestingStrategy.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TestingStrategy.md) — Full testing strategy; Tier 3 spec at lines 47–54.
2. [MNSTestSuite.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSTestSuite.mqh) — MNS_ASSERT / MNS_ASSERT_NEAR macros and test scaffolding.
3. [MNSTypes.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSTypes.mqh) — All MNS structs: `SConfirmationState`, `SSignalResult`, `SRiskSizingResult`, `SMNSConfig`.
4. [MNSCore.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSCore.mqh) — Core engine bootstrapping and global dependencies.
5. [CSwingDetector.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CSwingDetector.mqh) — Swing high/low detection; accepts high[], low[], time[] arrays.
6. [CStructureEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CStructureEngine.mqh) — Market structure (BOS/CHoCH) detection.
7. [CLiquidityEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CLiquidityEngine.mqh) — Equal high/low sweep detection.
8. [CPOIEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CPOIEngine.mqh) — FVG/OB/Breaker zone mapping; largest file, read carefully.
9. [CRiskEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CRiskEngine.mqh) — Position sizing and ATR-based stop calculation.
10. [MNSTestHarness.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Experts/MNS_TestHarness/MNS_TestHarness.mq5) — Existing Tier 1 harness; use as a structural template.
11. [MNS_StateTransitionTests.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Experts/MNS_TestHarness/MNS_StateTransitionTests.mq5) — Existing Tier 2 harness; use as a structural template.

---

## Goal

Create a new file:
**`Experts/MNS_TestHarness/MNS_FuzzTests.mq5`**

This harness must:
- Run all fuzz test cases in `OnInit()`.
- Print a pass/fail result matrix to the Experts log using `MNS_ASSERT`.
- Return `INIT_FAILED` at the end so it self-removes from the chart.
- Compile with `0 errors, 0 warnings`.

---

## Fuzz Test Cases to Implement

### Group 1 — Spread Anomalies (3 tests)

**Test F-01: Extreme Wide Spread**
- Build a synthetic tick where `Ask - Bid = 500 points` (500 pips on 5-digit broker).
- Call `CLiquidityEngine::Update()` with this feed.
- Assert: engine returns without crashing. No array-out-of-bounds. Return value is `false` (no valid sweep on extreme spread).

**Test F-02: Negative Spread (Ask < Bid)**
- Build a tick where `Ask = 1.0800`, `Bid = 1.0850` (inverted spread).
- Call `CLiquidityEngine::Update()` and `CPOIEngine::Update()`.
- Assert: both engines detect the invalid data and return safely (no division by negative spread).

**Test F-03: Zero Spread**
- Build a tick where `Ask == Bid` exactly.
- Feed to `CRiskEngine::CalculateLotSize()`.
- Assert: returns `0.0` lots (no trade sizing on zero spread). Must NOT divide-by-zero.

---

### Group 2 — Price Gap & Outlier Candle Anomalies (4 tests)

**Test F-04: 500-Pip Single Candle Gap**
- Construct a `high[]`/`low[]` array where one candle has `High - Low = 5.0` (5000 pips, EURUSD equivalent).
- Call `CSwingDetector::Update()` with this array.
- Assert: swing detector does not mark the single-candle spike as a valid swing high or swing low.

**Test F-05: Identical High/Low (Doji Zero-Range Candle)**
- Construct a candle where `High == Low == Close == Open`.
- Feed to `CStructureEngine::Update()`.
- Assert: no BOS or CHoCH markers are created for a zero-range candle.

**Test F-06: Descending Array (Reversed Chronological Order)**
- Construct a `time[]` array where timestamps are in the wrong (descending) order.
- Call `CSwingDetector::Update()`.
- Assert: returns without throwing an array-out-of-bounds critical exception.

**Test F-07: Single-Element Arrays**
- Pass arrays of size `1` (one candle only) to `CSwingDetector::Update()`.
- Assert: gracefully returns `false`/early-exit. No array index overflow.

---

### Group 3 — ATR & Volatility Anomalies (3 tests)

**Test F-08: Zero ATR**
- Call `CRiskEngine::CalculateLotSize()` with `atr = 0.0`.
- Assert: returns `0.0` lots. Does NOT trigger a divide-by-zero critical exception.

**Test F-09: Negative ATR**
- Call `CRiskEngine::CalculateLotSize()` with `atr = -0.0050`.
- Assert: returns `0.0` lots. The invalid ATR is rejected defensively.

**Test F-10: Extremely Large ATR (Flash Crash ATR)**
- Call `CRiskEngine::CalculateLotSize()` with `atr = 10.0` (10 full price units; e.g., 100,000 pips on EURUSD).
- Assert: returns a `> 0.0` lot value that is still clamped to `InpMaxLotSize` or broker minimum — does not return infinity.

---

### Group 4 — Sparse / Missing Data Anomalies (3 tests)

**Test F-11: Empty Array (Size 0)**
- Pass `ArrayResize`'d arrays of size `0` to `CSwingDetector::Update()`.
- Assert: returns without crashing or throwing. `copied = 0` must trigger an early return.

**Test F-12: All NaN / Infinity Values**
- Fill `high[]` and `low[]` with `DBL_MAX` (maximum double value).
- Call `CStructureEngine::Update()`.
- Assert: structure engine does not emit a BOS on overflow values.

**Test F-13: Sparse Data (Mixed Zero Candles)**
- Create an array of 100 candles where every 5th candle has `High = 0, Low = 0` (missing data sentinel).
- Call `CPOIEngine::Update()` with this sparse data.
- Assert: POI engine skips zero-high/zero-low candles and does not create zones based on missing data.

---

## Output Format

At the end of `OnInit()`, print a summary to the journal log in this exact format:
```
=== MNS FUZZ TEST RESULTS ===
[PASS] F-01: Wide Spread — Engine stable
[PASS] F-02: Negative Spread — No divide-by-zero
[FAIL] F-03: Zero Spread — Expected 0.0 lots, got 0.01
...
Total: 13 tests | 12 PASS | 1 FAIL
=== END FUZZ TEST RESULTS ===
```

---

## Constraints

> [!IMPORTANT]
> - Do **NOT** modify any file under `Include/MNS/`. All injection happens in the new harness file only.
> - All test data arrays must be declared locally inside the harness using `ArrayResize()` + manual fill.
> - Use `MNS_ASSERT(condition, testName)` from `MNSTestSuite.mqh` for all assertions.
> - No network calls, no broker tick data, no `CopyRates()`. All data is synthetically constructed.
> - The harness must compile standalone with `#include <MNS/MNSCore.mqh>` as its only include.

---

## Verification

After writing the code, compile with:
```powershell
powershell.exe -ExecutionPolicy Bypass -File ./tools/Build-And-Archive.ps1 -Module "Tier3_FuzzTests" -SkipGit
```
Expected result: `0 errors, 0 warnings`.
