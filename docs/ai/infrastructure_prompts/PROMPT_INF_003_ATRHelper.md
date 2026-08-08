# MNS Trading Engine
# AI Prompt — INF-003: ATR Helper Implementation
Version: 1.0
Status: Approved

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `docs/infrastructure/INF_PRD.md` — Infrastructure Product Requirements.
2. `docs/infrastructure/INF_ARCHITECTURE.md` — Directory structure, naming conventions, and dependency rules.
3. `Include/MNS/MNSCore.mqh` — Core metadata, shared results, and assertion macros.
4. `Include/MNS/MNSUtils.mqh` — Utility library helpers.
5. `docs/infrastructure/specs/INF_003_ATRHelper.md` — This module's detailed specification.
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

---

## SPECIFICATION SUMMARY — INF-003 (ATR Helper)

### Target File
`Include/MNS/MNSVolatility.mqh`

### Core Features

1. **Class `CMNSVolatility`**:
   - The class must have only static helper methods (pure static utility class).
   - Do not define any member state variables.
   
2. **Static Methods**:
   - `CalculateATR(const double &high[], const double &low[], const double &close[], int index, int period, int ratesTotal)`:
     - Calculates the Average True Range value for a specific bar index.
     - **Defensive Validation Checks**:
       - Verify sizes of `high[]`, `low[]`, and `close[]` match `ratesTotal`. If not, return `0.0`.
       - Assert that `period > 0` and `ratesTotal >= period + 1` using `MNS_Assert`. If invalid, return `0.0`.
       - Assert that the requested `index` satisfies `index >= 0 && index < ratesTotal`. If invalid, return `0.0`.
       - Assert that `ArrayGetAsSeries(high) == ArrayGetAsSeries(low) && ArrayGetAsSeries(high) == ArrayGetAsSeries(close)`. If they mismatch, return `0.0`.
     
     - **Array Direction Mapping**:
       - Detect orientation using `bool isSeries = ArrayGetAsSeries(high)`.
       - Define a helper macro or local variable mappings to translate time-based logical indexing (where index 0 is the oldest bar and index `ratesTotal - 1` is the newest bar) into actual index offsets:
         - `actualIndex(k) = isSeries ? (ratesTotal - 1 - k) : k`
       - Calculate the logical requested index: `logicalRequestedIndex = isSeries ? (ratesTotal - 1 - index) : index`.
       - If `logicalRequestedIndex < period`, there is insufficient history to calculate the initial ATR. Assert this state and return `0.0`.
     
     - **Calculation Logic**:
       1. Compute True Range ($TR$) for any logical index `k` (from `1` up to `logicalRequestedIndex`):
          - $TR_1 = High[k] - Low[k]$
          - $TR_2 = |High[k] - Close[k - 1]|$
          - $TR_3 = |Low[k] - Close[k - 1]|$
          - $TR = \max(TR_1, TR_2, TR_3)$
       2. Initial SMA Calculation at logical index `period`:
          - Calculate the Simple Moving Average of True Ranges for logical indices from `1` to `period`.
          - `initialSMA = (Sum of TR from k=1 to period) / period`.
       3. Wilder's Smoothing Recursion (if `logicalRequestedIndex > period`):
          - Loop from `k = period + 1` up to `logicalRequestedIndex`:
            - `prevATR = (prevATR * (period - 1) + TR[k]) / period`.
            - Ensure zero dynamic memory allocation is performed inside this loop.
       4. Return the computed ATR value.

---

## GENERATION INSTRUCTIONS

Please generate the complete source file for `Include/MNS/MNSVolatility.mqh` adhering strictly to MQL5 standards, with zero warnings and zero compiler errors.
All code must be fully commented and adhere to the project's documentation standards.
