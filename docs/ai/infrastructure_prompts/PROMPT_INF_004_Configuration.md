# MNS Trading Engine
# AI Prompt — INF-004: Configuration System Implementation
Version: 1.0
Status: Approved

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `docs/infrastructure/INF_PRD.md` — Infrastructure Product Requirements.
2. `docs/infrastructure/INF_ARCHITECTURE.md` — Directory structure, naming conventions, and dependency rules.
3. `Include/MNS/MNSCore.mqh` — Core metadata, shared results, and assertion macros.
4. `Include/MNS/MNSUtils.mqh` — Utility library helpers.
5. `docs/infrastructure/specs/INF_004_Configuration.md` — This module's detailed specification.
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
   - **Configuration (INF-004)**: Enforce the configuration data layer and parsing service. Do not write user-facing settings GUI panels, control buttons, or indicator inputs inside this module.

---

## SPECIFICATION SUMMARY — INF-004 (Configuration System)

### Target File
`Include/MNS/MNSConfig.mqh`

### Core Features

1. **Structure `SEngineConfig`**:
   - Contains the following properties:
     - `int externalDepth;`
     - `int internalDepth;`
     - `double atrTolerance;`
     - `double minBreakDistance;`
     - `double confidenceThreshold;`
     - `bool logEnable;`
     - `int logLevel;`

2. **Class `CMNSConfig`**:
   - **Static Private States**:
     - `s_config` of type `SEngineConfig`.
   - **Static Methods**:
     - `SetDefaults()`:
       - Sets s_config variables to:
         - `externalDepth = 15;`
         - `internalDepth = 5;`
         - `atrTolerance = 0.0010;`
         - `minBreakDistance = 0.0;`
         - `confidenceThreshold = 94.0;`
         - `logEnable = true;`
         - `logLevel = 1;` (Matches `MNS_LOG_INFO` value)
     - `GetActive()`:
       - Returns a copy of `s_config` by value (MQL5 returns structs by value).
     - `UpdateParameter(string name, double value)`:
       - Validates and writes parameters dynamically.
       - Returns `true` if parameter name was matched and value was within bounds (and updated); returns `false` if value was out of bounds or parameter was unknown.
       - Bounds rules:
         - `externalDepth`: must be `>= 1` and `>= s_config.internalDepth`.
         - `internalDepth`: must be `>= 1` and `<= s_config.externalDepth`.
         - `atrTolerance`: must be `>= 0.0`.
         - `minBreakDistance`: must be `>= 0.0`.
         - `confidenceThreshold`: must be `>= 0.0` and `<= 100.0`.
         - `logEnable`: updates boolean setting (`value != 0.0`).
         - `logLevel`: must be between `0` (Debug) and `4` (Fatal) inclusive.
     - `LoadFromFile(string fileName)`:
       - Restricted to MQL5 standard sandbox (`MQL5\Files\`).
       - Opens file using `FileOpen(fileName, FILE_READ | FILE_TXT | FILE_ANSI)`. If handle is invalid, returns `false`.
       - Reads the file line-by-line using `FileReadString`.
       - For each line:
         - Trim leading/trailing whitespace.
         - Skip empty lines or lines starting with `;` or `#` (standard INI comments).
         - Locate the `=` character. If not found or at the start, skip line.
         - Substring the line into `key` (before `=`) and `value` (after `=`). Trim both.
         - Convert the value string to double using `StringToDouble`.
         - Run `UpdateParameter(key, val)`. If it returns `false`, record failure but continue parsing remaining lines.
       - Closes file and returns `true` if file opened and all parameters parsed/validated successfully; returns `false` if file failed to open or any parameter failed validation/bounds.

3. **MQL5 Static Initializers**:
   - Initialize `s_config` in the global namespace of the header file:
     ```cpp
     SEngineConfig CMNSConfig::s_config;
     ```

---

## GENERATION INSTRUCTIONS

Please generate the complete source file for `Include/MNS/MNSConfig.mqh` adhering strictly to MQL5 standards, with zero warnings and zero compiler errors.
All code must be fully commented and adhere to the project's documentation standards.
