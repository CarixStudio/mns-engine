# Module Specification — INF-007: Performance Monitor
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Purpose

The Performance Monitor (`MNSProfiler.mqh`) tracks execution latency of hot paths using high-resolution microsecond timers. It provides metrics to detect CPU bottlenecks and trace overhead of updates.

---

## 2. Responsibilities

- **Execution Timing**: Profile code segments using native `GetMicrosecondCount()`.
- **Telemetry Processing**: Store cumulative execution duration and calls count for target modules.
- **Zero Profiling Overhead**: Ensure all profiling logic is completely stripped at compile-time when not explicitly enabled.

---

## 3. Public API

```cpp
struct SProfileSection
{
    string name;
    ulong  totalTimeUs;
    ulong  callCount;
    ulong  startTime;
};

class CMNSProfiler
{
private:
    static SProfileSection s_sections[];
    static int             s_sectionCount;

public:
    /// @brief Marks the entry of a profiled code section.
    static void Start(string sectionName);

    /// @brief Marks the exit of a profiled code section and records elapsed microseconds.
    static void Stop(string sectionName);

    /// @brief Reports average and total latency metrics for all sections.
    static void ReportTelemetry();
};

// --- Macro Wrapper API (Enables compile-time stripping) ---
#ifdef MNS_PROFILING_ENABLE
    #define MNS_ProfileStart(sec) CMNSProfiler::Start(sec)
    #define MNS_ProfileStop(sec)  CMNSProfiler::Stop(sec)
#else
    #define MNS_ProfileStart(sec)
    #define MNS_ProfileStop(sec)
#endif
```

---

## 4. Internal Architecture & Dependencies

- **File**: `Include/MNS/MNSProfiler.mqh`
- **Dependencies**: `MNSCore.mqh`, `MNSUtils.mqh`
- **Telemetry Format**: Prints summary reports: `[PROFILE] <sectionName> - Calls: <count>, Total: <time> us, Avg: <avg> us`.

---

## 5. Testing & Acceptance Criteria

- **Test Cases**:
  1. Profile a block containing `Sleep(10)` and confirm the recorded time is at least $10,000$ microseconds.
  2. Verify that when `MNS_PROFILING_ENABLE` is undefined, the profiling calls compile to empty instructions.
  3. Validate that section counters increment correctly on nested profile triggers.
- **Acceptance Criteria**:
  - Standalone header compiles cleanly.
  - Zero performance leakage when disabled.
