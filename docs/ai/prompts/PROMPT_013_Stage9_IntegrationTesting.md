# MNS Trading Engine — Module 013
# Stage 9: Integration Testing
# AI Implementation Prompt

Version: 1.0
Status: READY — Stage 8 Complete. Begin Stage 9.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before running any validation scripts or editing files, you must inspect:

1. `Experts/MNS_TestHarness/MNS_TestHarness.mq5` — The unit test suite.
2. `Indicators/MNS_Indicator.mq5` — The indicator coordinator.
3. `docs/modules/013_STAGE_08_DESIGN.md` — Stage 8 detailed design specifications.
4. `roadmap.md` — Project roadmap.

---

## ABSOLUTE RULES

1. Never bypass failed unit tests. If any test case inside `MNS_TestHarness.mq5` fails, you must investigate and fix the underlying engine module before proceeding.
2. The indicator must handle chart destruction and deinitialization events cleanly. No orphaned graphical objects (arrows, lines, rectangles, dashboard panels) can be left on the chart on timeframe switch or deinitialization.
3. Verify performance under simulated tick pressure. Telemetry timing in the Strategy Tester must show average latencies within the defined budgets (Engine updates < 6ms, Renderers < 10ms).

---

## STAGE 8 STATUS — COMPLETE ✅

Stage 8 (Visual Performance Profiling) is complete and verified under tag `v0.0.13-stage8`.

**Build result:**
- `MNS_Indicator.mq5`: 0 errors, 0 warnings.
- Telemetry: High-resolution timing macros wrap all engines and visual renderers. Periodical reports print average latency to the log journal every 1000 calculate cycles.

---

## STAGE 9 OBJECTIVES

The objective of Stage 9 is to perform comprehensive **Integration Testing** of the entire codebase before we freeze the indicator for final release. 

This stage focuses on validating the engine stability, memory safety, and visual correctness across different symbols, timeframes, and market conditions using both automated test harnesses and manual simulation testing in the Strategy Tester.

### Deliverables

1. **`docs/modules/013_STAGE_09_TEST_REPORT.md`** ← Create testing report.
   - Document the test cases run, unit test pass count, memory/object count verification, latency metrics in visual simulation, and edge-case validation results (e.g. weekend boundaries).

2. **Execute Automated Unit Tests**
   - Compile and execute `MNS_TestHarness.mq5`.
   - Verify that the Experts journal output shows `g_testsFailed = 0` and print the exact pass count.

3. **Verify Timeframe & Symbol Multi-instance Isolation**
   - Load the indicator on `GBPUSD H1`, `GBPUSD M5`, and `EURUSD H1` simultaneously.
   - Verify that object names (which utilize prefix formats) remain completely isolated. Changing settings on one chart must not affect the drawings or dashboard of another chart.
   - Verify that chart deinitialization (switching timeframes or removing indicator) cleans up 100% of the chart objects.

4. **Visual Simulation & Memory Safety Verification**
   - Run the indicator in the MT5 Strategy Tester (Visual mode) on `GBPUSD M5` for at least 1 historical month.
   - Monitor the total object count on the chart using MT5's Objects List dialog (`Ctrl+B`) during simulation.
   - Verify that the object count does not grow infinitely, staying strictly capped under the parameters defined in `CMNSConfig` (e.g. max 50 swings, 20 breaks, 15 sessions).

---

## TEST SUITE RUNNING STEPS

### 1. Run Automated Unit Tests
*   Compile `Experts/MNS_TestHarness/MNS_TestHarness.mq5`.
*   Deploy it on a blank chart. Since it returns `INIT_FAILED` on success, it will print the full report to the journal and immediately remove itself from the chart.
*   Capture the output log and note down the results in your test report.

### 2. Verify Performance Telemetry in Tester
*   Run the indicator in the Strategy Tester in visual mode.
*   Open the Experts tab and search for the prefix `[PROFILE]`.
*   Verify that:
    - `"Total_Calculate"` average latency is `< 8,000` microseconds.
    - `"Total_Rendering"` average latency is `< 10,000` microseconds.

### 3. Edge-Case Scenarios Validation
You must manually verify the following behaviors in the Strategy Tester:
*   **Weekend Boundary**: Confirm that during market close periods, the session shading renderer handles empty time arrays without throwing array out of range exceptions.
*   **Low History Bar Counts**: Load the indicator on a new chart with low history (e.g. less than 100 bars). Confirm that the ATR volatility filter and engines fail-safe cleanly (returning `rates_total` or standard fallbacks) without crashing the MT5 terminal.

---

## POST-IMPLEMENTATION REGISTRY UPDATES

After all integration checks pass:
1. **Update `roadmap.md`**:
   - Mark **Stage 9: Integration Testing** as **✅ Complete** in the status table.
   - Document any test report references under Stage 9 deliverables.
