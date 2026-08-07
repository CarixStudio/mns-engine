# Module Specification — INF-001: Logging System
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Purpose

The Logging System (`MNSLogger.mqh`) provides standard diagnostic messaging across all engine modules. It features multiple log targets, level filtering, and compile-time macro switches to ensure zero overhead in production.

---

## 2. Responsibilities

- **Level Filtering**: Suppress messages below the active log level threshold.
- **Log Targets**: Route messages to the MT5 Experts tab (`Print()`), a dedicated file on disk (`FileWrite`), or visual terminal alerts (`Alert()`).
- **Zero Production Overhead**: Ensure all debug logging calls are fully optimized away by the compiler when built for release.

---

## 3. Public API

```cpp
enum ENUM_MNS_LOG_LEVEL
{
    MNS_LOG_DEBUG = 0,
    MNS_LOG_INFO,
    MNS_LOG_WARN,
    MNS_LOG_ERROR,
    MNS_LOG_FATAL
};

class CMNSLogger
{
private:
    static ENUM_MNS_LOG_LEVEL s_activeLevel;
    static string             s_logFileName;
    static int                s_fileHandle;

public:
    /// @brief Configures active log levels and optional file logging targets.
    static void Initialize(ENUM_MNS_LOG_LEVEL level, string file = "");
    
    /// @brief Closes any open file handles.
    static void Close();

    /// @brief Outputs a message at the specified log level.
    static void Log(ENUM_MNS_LOG_LEVEL level, string source, string message);
};

// --- Macro Wrapper API (Enables compile-time stripping) ---
#ifdef MNS_LOG_ENABLE
    #define MNS_Log(level, src, msg) CMNSLogger::Log(level, src, msg)
#else
    #define MNS_Log(level, src, msg)
#endif
```

---

## 4. Internal Architecture & Dependencies

- **File**: `Include/MNS/MNSLogger.mqh`
- **Dependencies**: `MNSCore.mqh`
- **Formatting**: Every message must follow a strict bracketed timestamp format: `[YYYY-MM-DD HH:MM:SS] [LEVEL] [SOURCE] message`.

---

## 5. Threading & Execution Considerations

- File logging utilizes MT5's local sandbox environment (`MQL5\Files\MNS_Logs\`).
- File handles must be opened in shared mode (`FILE_WRITE | FILE_SHARE_READ`) to allow other diagnostic tools to read the logs in real-time.

---

## 6. Testing & Acceptance Criteria

- **Test Cases**:
  1. Confirm messages below the initialized `ENUM_MNS_LOG_LEVEL` threshold are not written to targets.
  2. Confirm `MNS_LOG_FATAL` triggers both a print log and a chart alert.
  3. Validate that disabling `MNS_LOG_ENABLE` compile-time strips the code.
- **Acceptance Criteria**:
  - Standalone header compiles cleanly.
  - File locking or resource leakage does not occur on reset.
