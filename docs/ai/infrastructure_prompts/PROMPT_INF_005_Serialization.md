# MNS Trading Engine
# AI Prompt — INF-005: Serialization Interfaces Implementation
Version: 1.0
Status: Approved

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `docs/infrastructure/INF_PRD.md` — Infrastructure Product Requirements.
2. `docs/infrastructure/INF_ARCHITECTURE.md` — Directory structure, naming conventions, and dependency rules.
3. `Include/MNS/MNSCore.mqh` — Core metadata, shared results, and assertion macros.
4. `docs/infrastructure/specs/INF_005_Serialization.md` — This module's detailed specification.
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

## SPECIFICATION SUMMARY — INF-005 (Serialization Interfaces)

### Target File
`Include/MNS/MNSSerializer.mqh`

### Core Features

1. **Interface `IMNSSerializable`**:
   - This must be defined as an abstract base class.
   - **Virtual Destructor**:
     - Must define `virtual ~IMNSSerializable() {}`.
   - **Pure Virtual Methods**:
     - `virtual MNS_RESULT Serialize(int fileHandle) = 0;`
     - `virtual MNS_RESULT Deserialize(int fileHandle) = 0;`

2. **Dependencies**:
   - Must include `MNSCore.mqh`.

---

## GENERATION INSTRUCTIONS

Please generate the complete source file for `Include/MNS/MNSSerializer.mqh` adhering strictly to MQL5 standards, with zero warnings and zero compiler errors.
All code must be fully commented and adhere to the project's documentation standards.
