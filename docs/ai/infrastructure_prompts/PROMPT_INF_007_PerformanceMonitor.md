# MNS Trading Engine
# AI Prompt — INF-007: Performance Monitor Implementation
Version: 1.0
Status: Approved

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `docs/infrastructure/INF_PRD.md` — Infrastructure Product Requirements.
2. `docs/infrastructure/INF_ARCHITECTURE.md` — Directory structure, naming conventions, and dependency rules.
3. `Include/MNS/MNSCore.mqh` — Core metadata, shared results, and assertion macros.
4. `Include/MNS/MNSUtils.mqh` — Utility library helpers.
5. `docs/infrastructure/specs/INF_007_PerformanceMonitor.md` — This module's detailed specification.
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
   - **Performance (INF-007)**: Enforce performance measurements and telemetry. Do not write rendering optimizations inside this module.

---

## SPECIFICATION SUMMARY — INF-007 (Performance Monitor)

### Target File
`Include/MNS/MNSProfiler.mqh`

### Core Features

1. **Struct `SProfileSection`**:
   - `string name;`
   - `ulong  totalTimeUs;`
   - `ulong  callCount;`
   - `ulong  startTime;`

2. **Class `CMNSProfiler`**:
   - Must have only static helper methods and static member variables (pure static utility class).
   - **Static Private Variables**:
     - `s_sections` of type `SProfileSection s_sections[]` (dynamic array to store sections).
     - `s_sectionCount` of type `int`.
   
   - **Static Methods**:
     - `Start(string sectionName)`:
       - Looks up `sectionName` in `s_sections`.
       - If not found:
         - Resizes `s_sections` to `s_sectionCount + 1` (using `ArrayResize`).
         - Initializes new section at index `s_sectionCount`:
           - `name = sectionName;`
           - `totalTimeUs = 0;`
           - `callCount = 0;`
           - `startTime = GetMicrosecondCount();`
         - Increments `s_sectionCount`.
       - If found at index `idx`:
         - Updates `s_sections[idx].startTime = GetMicrosecondCount();`.
     - `Stop(string sectionName)`:
       - Looks up `sectionName` in `s_sections`.
       - If found at index `idx`:
         - Calculates elapsed microseconds: `ulong elapsed = GetMicrosecondCount() - s_sections[idx].startTime;`
         - Adds `elapsed` to `s_sections[idx].totalTimeUs`.
         - Increments `s_sections[idx].callCount`.
     - `ReportTelemetry()`:
       - Loops through all registered sections in `s_sections`.
       - For each section:
         - Calculate average latency: `double avg = s_sections[i].callCount > 0 ? (double)s_sections[i].totalTimeUs / s_sections[i].callCount : 0.0;`
         - Print formatted line:
           `Print("  [PROFILE] ", s_sections[i].name, " - Calls: ", s_sections[i].callCount, ", Total: ", s_sections[i].totalTimeUs, " us, Avg: ", DoubleToString(avg, 2), " us");`

3. **Macro Wrapper API**:
   - Wrap the profiling logic with conditional compilation:
     ```cpp
     #ifdef MNS_PROFILING_ENABLE
         #define MNS_ProfileStart(sec) CMNSProfiler::Start(sec)
         #define MNS_ProfileStop(sec)  CMNSProfiler::Stop(sec)
     #else
         #define MNS_ProfileStart(sec)
         #define MNS_ProfileStop(sec)
     #endif
     ```

4. **MQL5 Static Initializers**:
   - Initialize `s_sections` and `s_sectionCount` in the global namespace of the header file:
     ```cpp
     SProfileSection CMNSProfiler::s_sections[];
     int CMNSProfiler::s_sectionCount = 0;
     ```

---

## GENERATION INSTRUCTIONS

Please generate the complete source file for `Include/MNS/MNSProfiler.mqh` adhering strictly to MQL5 standards, with zero warnings and zero compiler errors.
All code must be fully commented and adhere to the project's documentation standards.
