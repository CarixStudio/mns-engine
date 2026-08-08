# MNS Trading Engine
# AI Prompt — INF-002: Utility Library Implementation
Version: 1.0
Status: Approved

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `docs/infrastructure/INF_PRD.md` — Infrastructure Product Requirements.
2. `docs/infrastructure/INF_ARCHITECTURE.md` — Directory structure, naming conventions, and dependency rules.
3. `Include/MNS/MNSCore.mqh` — Core metadata, shared results, and assertion macros.
4. `docs/infrastructure/specs/INF_002_Utility.md` — This module's detailed specification.
5. `docs/CodingStandards.md` — Coding style guide.
6. `docs/infrastructure/INF_ROADMAP.md` — Infrastructure roadmap.

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

## SPECIFICATION SUMMARY — INF-002 (Utility Library)

### Target File
`Include/MNS/MNSUtils.mqh`

### Core Features

1. **Class `CMNSUtils`**:
   - The class must have only static helper methods (pure static utility class).
   - Do not define any member state variables.
   
2. **Static Methods**:
   - `ArrayCloneDouble(const double &src[], double &dst[])`:
     - Checks the size of `src[]`. If size < 0, returns `false`.
     - Checks if `dst[]` is a dynamic array using `ArrayIsDynamic(dst)`.
       - If dynamic, resizes `dst` to match `src` size using `ArrayResize(dst, size)`. If resize fails, returns `false`.
       - If static, validates that `ArraySize(dst)` is at least `size`. If not, returns `false`.
     - Copies elements from `src` to `dst` using `ArrayCopy(dst, src, 0, 0, WHOLE_ARRAY)`.
     - Returns `true` if all elements were copied successfully, `false` otherwise.
   - `ArrayDeleteIndex(double &array[], int index)`:
     - Validates that `array` is dynamic using `ArrayIsDynamic(array)`. If not, returns `false`.
     - Validates that `index` is within bounds: `index >= 0 && index < ArraySize(array)`.
     - Shifts all elements after `index` one position to the left.
     - Resizes the array to `oldSize - 1` using `ArrayResize(array, oldSize - 1)`.
     - Returns `true` on success, `false` on failure.
   - `IsInSession(datetime time, int sessionStartHour, int sessionEndHour)`:
     - Extracts the hour component from `time` using `TimeToStruct`.
     - If `sessionStartHour < sessionEndHour`:
       - Returns `true` if `hour >= sessionStartHour && hour < sessionEndHour`.
     - If `sessionStartHour > sessionEndHour` (midnight cross):
       - Returns `true` if `hour >= sessionStartHour || hour < sessionEndHour`.
     - If `sessionStartHour == sessionEndHour`:
       - Returns `true` if `hour == sessionStartHour`.
   - `BrokerTimeToGMT(datetime brokerTime, int brokerGmtOffset)`:
     - Adjusts the broker's time to GMT using the shift offset.
     - Formula: `GMT = brokerTime - (brokerGmtOffset * 3600)`
     - Returns the converted datetime.
   - `IsEqual(double a, double b, double epsilon = 0.00001)`:
     - Returns `true` if the absolute difference between `a` and `b` is less than or equal to `epsilon`.
     - Returns `false` otherwise.
   - `RoundToPoints(double price, double pointSize)`:
     - Validates that `pointSize` is greater than 0. If not, returns `price`.
     - Calculates the number of digits using `(int)MathRound(-MathLog10(pointSize))`. If digits < 0, sets digits to 0.
     - Rounds the price using `MathRound(price / pointSize) * pointSize`.
     - Returns the normalized double value using `NormalizeDouble` with the calculated number of digits.

---

## GENERATION INSTRUCTIONS

Please generate the complete source file for `Include/MNS/MNSUtils.mqh` adhering strictly to MQL5 standards, with zero warnings and zero compiler errors.
All code must be fully commented and adhere to the project's documentation standards.
