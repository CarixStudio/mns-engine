# MNS Trading Engine
# AI Prompt — INF-006: Testing Framework Implementation
Version: 1.0
Status: Approved

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `docs/infrastructure/INF_PRD.md` — Infrastructure Product Requirements.
2. `docs/infrastructure/INF_ARCHITECTURE.md` — Directory structure, naming conventions, and dependency rules.
3. `Include/MNS/MNSCore.mqh` — Core metadata, shared results, and assertion macros.
4. `Include/MNS/MNSUtils.mqh` — Utility library helpers.
5. `docs/infrastructure/specs/INF_006_Testing.md` — This module's detailed specification.
6. `docs/CodingStandards.md` — Coding style guide.
7. `docs/infrastructure/INF_ROADMAP.md` — Infrastructure roadmap.

---

## ABSOLUTE RULES FOR INFRASTRUCTURE

1. **ZERO Trading Logic**: Infrastructure modules must contain **absolutely zero** market analysis, Smart Money Concepts, Order Blocks, FVGs, trend detection, or execution logic.
2. **Compile-Time Optimization (Macros)**: Logging and profiling methods must be wrapped in preprocessor macros (e.g., `#ifdef MNS_LOG_ENABLE`) to ensure they are completely stripped out at compile-time when disabled, ensuring zero CPU overhead in production.
3. **No Hot-Path Allocations**: To prevent performance degradation during backtesting, hot-path methods (run on every tick or candle update) must avoid dynamic memory allocation (`ArrayResize`, `new`).
4. **Memory Leak Prevention**: Explicitly clean up all dynamic resources (file handles, dynamic arrays) in destructors. MQL5 does not use garbage collection; memory leaks are fatal.
5. **Strict Type Safety**: Utilize the unified error/success codes (`MNS_RESULT`) defined in `MNSCore.mqh` for structured return checks.
6. **No Broker or Chart Dependencies**: Infrastructure modules must process data using passed-in arrays, remaining decoupled from MT5's live broker feeds, indicator handles, or terminal chart drawings.
7. **Write Defensive MQL5**: Perform size and boundary checks on all input arrays before accessing index values.
8. **Preserve Compatibility**: Keep the public API clean, static where possible, and fully documented.
9. **Strict Architectural Separation (Infrastructure vs UI)**: Infrastructure modules must remain decoupled from visualization and visual interface layers:
   - **Testing (INF-006)**: Enforce the mock and test framework assertions. Do not write visual rendering tests inside this module.

---

## SPECIFICATION SUMMARY — INF-006 (Testing Framework)

### Target File
`Include/MNS/MNSTestSuite.mqh`

### Core Features

1. **Class `CMNSTestSuite`**:
   - Must have only static helper methods and static member variables (pure static utility class).
   - **Static Private Variables**:
     - `s_testsPassed` of type `int`.
     - `s_testsFailed` of type `int`.
   
   - **Static Methods**:
     - `Reset()`:
       - Sets `s_testsPassed = 0;` and `s_testsFailed = 0;`.
     - `GetFailedCount()`:
       - Returns `s_testsFailed`.
     - `AssertTrue(bool condition, string testName)`:
       - If `condition` is true:
         - Print `"  [PASS] " + testName` to the Experts log.
         - Increment `s_testsPassed`.
       - If `condition` is false:
         - Print `"  [FAIL] " + testName + " - Expected: true, Actual: false"` to the Experts log.
         - Increment `s_testsFailed`.
     - `AssertEqualInt(int expected, int actual, string testName)`:
       - If `expected == actual`:
         - Print `"  [PASS] " + testName` to the Experts log.
         - Increment `s_testsPassed`.
       - If `expected != actual`:
         - Print `"  [FAIL] " + testName + " - Expected: " + IntegerToString(expected) + ", Actual: " + IntegerToString(actual)` to the log.
         - Increment `s_testsFailed`.
     - `AssertEqualDouble(double expected, double actual, string testName, double epsilon = 0.00001)`:
       - Use `CMNSUtils::IsEqual(expected, actual, epsilon)` to verify equality.
       - If they are equal within epsilon:
         - Print `"  [PASS] " + testName` to the log.
         - Increment `s_testsPassed`.
       - If they are not equal:
         - Print `"  [FAIL] " + testName + " - Expected: " + DoubleToString(expected, 8) + ", Actual: " + DoubleToString(actual, 8)` to the log.
         - Increment `s_testsFailed`.
     - `ReportResults(string moduleName)`:
       - Print a formatted block summarizing the test run:
         ```
         ==============================================
           MODULE: <moduleName>
           Passed : <s_testsPassed>
           Failed : <s_testsFailed>
           Total  : <s_testsPassed + s_testsFailed>
           Result : <ALL TESTS PASSED or <s_testsFailed> TEST(S) FAILED>
         ==============================================
         ```

2. **MQL5 Static Initializers**:
   - Initialize `s_testsPassed` and `s_testsFailed` in the global namespace of the header file:
     ```cpp
     int CMNSTestSuite::s_testsPassed = 0;
     int CMNSTestSuite::s_testsFailed = 0;
     ```

---

## GENERATION INSTRUCTIONS

Please generate the complete source file for `Include/MNS/MNSTestSuite.mqh` adhering strictly to MQL5 standards, with zero warnings and zero compiler errors.
All code must be fully commented and adhere to the project's documentation standards.
