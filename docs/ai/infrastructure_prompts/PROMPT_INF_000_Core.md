# MNS Trading Engine
# AI Prompt — INF-000: Core Module Implementation
Version: 1.0
Status: Approved

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `docs/infrastructure/INF_PRD.md` — Infrastructure Product Requirements.
2. `docs/infrastructure/INF_ARCHITECTURE.md` — Directory structure, naming conventions, and dependency rules.
3. `Include/MNS/MNSCore.mqh` — Core metadata, shared results, and assertion macros (to be created).
4. `docs/infrastructure/specs/INF_000_Core.md` — This module's detailed specification.
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

## SPECIFICATION SUMMARY — INF-000 (Core Module)

### Target File
`Include/MNS/MNSCore.mqh`

### Core Features

1. **Type Definitions & Error Codes**:
   - `typedef int MNS_RESULT;`
   - Success code:
     - `MNS_S_OK` = `0x00000000` (Generic success)
   - Error codes:
     - `MNS_E_FAIL` = `0x80004005` (Generic failure code)
     - `MNS_E_INVALIDARG` = `0x80070057` (Invalid argument passed)
     - `MNS_E_OUTOFMEMORY` = `0x8007000E` (Memory allocation/array resize failure)
     - `MNS_E_NOTIMPL` = `0x80004001` (Method/function not implemented)

2. **Global Constants**:
   - `MNS_INVALID_PRICE` = `1.7976931348623157e+308` (Double maximum sentinel)
   - `MNS_INVALID_INDEX` = `-1` (Invalid/empty index sentinel)
   - `MNS_INVALID_TIME` = `0` (Zero datetime sentinel)

3. **Assertion Macro**:
   - Conditioned on `MNS_ASSERT_ENABLE`:
     - If `MNS_ASSERT_ENABLE` is defined:
       - `MNS_Assert(expression, message)` should check the condition. If false, it calls `Alert("MNS ASSERTION FAILED: " + message)` and halts execution via `ExpertRemove()`.
     - If `MNS_ASSERT_ENABLE` is not defined:
       - `MNS_Assert(expression, message)` compiles to absolutely nothing.

---

## GENERATION INSTRUCTIONS

Please generate the complete source file for `Include/MNS/MNSCore.mqh` adhering strictly to MQL5 standards, with zero warnings and zero compiler errors.
All code must be fully commented and adhere to the project's documentation standards.

---
