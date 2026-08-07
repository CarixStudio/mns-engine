# MNS Trading Engine
# AI Prompt — INF-001: Logging System Implementation
Version: 1.0
Status: Approved

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `docs/infrastructure/INF_PRD.md` — Infrastructure Product Requirements.
2. `docs/infrastructure/INF_ARCHITECTURE.md` — Directory structure, naming conventions, and dependency rules.
3. `Include/MNS/MNSCore.mqh` — Core metadata, shared results, and assertion macros.
4. `docs/infrastructure/specs/INF_001_Logging.md` — This module's detailed specification.
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

## SPECIFICATION SUMMARY — INF-001 (Logging System)

### Target File
`Include/MNS/MNSLogger.mqh`

### Core Features

1. **Log Level Enumeration**:
   - Define `ENUM_MNS_LOG_LEVEL` with values:
     - `MNS_LOG_DEBUG` = 0
     - `MNS_LOG_INFO`
     - `MNS_LOG_WARN`
     - `MNS_LOG_ERROR`
     - `MNS_LOG_FATAL`

2. **Logger Class (`CMNSLogger`)**:
   - **Static States**:
     - `s_activeLevel` (default threshold, e.g. `MNS_LOG_INFO`)
     - `s_logFileName` (active logging filename)
     - `s_fileHandle` (active file handle, initialized to `INVALID_HANDLE`)
   - **Static Methods**:
     - `Initialize(ENUM_MNS_LOG_LEVEL level, string file = "")`:
       - Set `s_activeLevel`.
       - If `file` is provided and not empty:
         - Close any existing handle first.
         - Store file name.
         - Open file in shared write mode: `FileOpen("MNS_Logs\\" + file, FILE_WRITE | FILE_SHARE_READ | FILE_TXT | FILE_ANSI)`.
         - If file handle is invalid, print an error alert but do not crash.
     - `Close()`:
       - Close file handle using `FileClose` if it is not `INVALID_HANDLE`.
       - Reset `s_fileHandle` to `INVALID_HANDLE` and `s_logFileName` to `""`.
     - `Log(ENUM_MNS_LOG_LEVEL level, string source, string message)`:
       - If `level < s_activeLevel`, return immediately.
       - Construct the log line in format:
         - `[YYYY.MM.DD HH:MM:SS] [LEVEL] [SOURCE] message`
         - Use `TimeToString(TimeLocal(), TIME_DATE | TIME_SECONDS)` for current local time.
         - Convert the enum level to a short string: `"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`, or `"FATAL"`.
       - Output:
         - Call `Print(logLine)` to print to the MT5 Experts tab.
         - If `s_fileHandle` is valid (not `INVALID_HANDLE`), write the line to disk using `FileWrite(s_fileHandle, logLine)`.
         - If `level == MNS_LOG_FATAL`, call MT5's `Alert(logLine)` to show a visual popup/alert.

3. **MQL5 Static Initializers**:
   - In MQL5, static variables declared in a class must be initialized in the global namespace of the header file.
   - Example:
     ```cpp
     ENUM_MNS_LOG_LEVEL CMNSLogger::s_activeLevel = MNS_LOG_INFO;
     string             CMNSLogger::s_logFileName = "";
     int                CMNSLogger::s_fileHandle = INVALID_HANDLE;
     ```

4. **Preprocessor Macro Wrapper API**:
   - Wrapper for compile-time stripping:
     ```cpp
     #ifdef MNS_LOG_ENABLE
         #define MNS_Log(level, src, msg) CMNSLogger::Log(level, src, msg)
     #else
         #define MNS_Log(level, src, msg)
     #endif
     ```

---

## GENERATION INSTRUCTIONS

Please generate the complete source file for `Include/MNS/MNSLogger.mqh` adhering strictly to MQL5 standards, with zero warnings and zero compiler errors.
All code must be fully commented and adhere to the project's documentation standards.

---
