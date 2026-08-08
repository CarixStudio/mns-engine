//+------------------------------------------------------------------+
//|                                                  MNSProfiler.mqh |
//|                              MNS Trading Engine — Module INF-007 |
//|                                                                  |
//| Purpose:                                                         |
//|   Provides latency tracking and telemetry profiling metrics      |
//|   for hot path execution blocks using microsecond resolution.    |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Define execution timing profile blocks (SProfileSection).    |
//|   - Accumulate total execution duration and call count metrics.   |
//|   - Output latency telemetry reports to log targets.             |
//|   - Support compile-time macro stripping (MNS_PROFILING_ENABLE). |
//|                                                                  |
//| Dependencies:                                                    |
//|   - MNSCore.mqh                                                  |
//|   - MNSUtils.mqh                                                 |
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading logic.                                          |
//|   - No hot path dynamic allocations after initial registration.  |
//|   - Compile-time macro conditional execution.                   |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_PROFILER_MQH__
#define __MNS_PROFILER_MQH__

//+------------------------------------------------------------------+
//| Profile Section Telemetry Structure                              |
//+------------------------------------------------------------------+
struct SProfileSection
{
    string name;          // Unique name of the profiled block
    ulong  totalTimeUs;   // Cumulative execution duration in microseconds
    ulong  callCount;     // Cumulative call frequency counter
    ulong  startTime;     // Timestamp at section entry in microseconds
};

//+------------------------------------------------------------------+
//| CMNSProfiler Class                                               |
//+------------------------------------------------------------------+
class CMNSProfiler
{
private:
    static SProfileSection s_sections[];      // Section registry
    static int             s_sectionCount;    // Current registration count

    /// @brief Finds the index of a registered profile section.
    /// @param name Name of the section.
    /// @return The index in the registry, or -1 if not found.
    static int FindSection(string name)
    {
        for (int i = 0; i < s_sectionCount; i++)
        {
            if (s_sections[i].name == name)
                return i;
        }
        return -1;
    }

public:
    /// @brief Resets the profiler state and releases dynamic memory.
    static void Reset()
    {
        ArrayFree(s_sections);
        s_sectionCount = 0;
    }

    /// @brief Marks the entry of a profiled code section.
    /// @param sectionName Unique string identifier for the block.
    static void Start(string sectionName)
    {
        int idx = FindSection(sectionName);
        if (idx == -1)
        {
            // Register section on first entry
            int currentSize = ArraySize(s_sections);
            if (s_sectionCount >= currentSize)
            {
                int newSize = (currentSize == 0) ? 8 : currentSize * 2;
                if (ArrayResize(s_sections, newSize) < 0)
                    return; // Fail-safe: do not crash if allocation fails
            }
            
            s_sections[s_sectionCount].name = sectionName;
            s_sections[s_sectionCount].totalTimeUs = 0;
            s_sections[s_sectionCount].callCount = 0;
            s_sections[s_sectionCount].startTime = GetMicrosecondCount();
            s_sectionCount++;
        }
        else
        {
            s_sections[idx].startTime = GetMicrosecondCount();
        }
    }

    /// @brief Marks the exit of a profiled code section and logs elapsed latency.
    /// @param sectionName Unique string identifier for the block.
    static void Stop(string sectionName)
    {
        int idx = FindSection(sectionName);
        if (idx != -1)
        {
            ulong elapsed = GetMicrosecondCount() - s_sections[idx].startTime;
            s_sections[idx].totalTimeUs += elapsed;
            s_sections[idx].callCount++;
        }
    }

    /// @brief Reports average and total latency metrics for all sections.
    static void ReportTelemetry()
    {
        Print("=== MNS Performance Telemetry ===");
        for (int i = 0; i < s_sectionCount; i++)
        {
            double avg = (s_sections[i].callCount > 0) ? (double)s_sections[i].totalTimeUs / s_sections[i].callCount : 0.0;
            Print("  [PROFILE] ", s_sections[i].name, 
                  " - Calls: ", s_sections[i].callCount, 
                  ", Total: ", s_sections[i].totalTimeUs, " us", 
                  ", Avg: ", DoubleToString(avg, 2), " us");
        }
        Print("=================================");
    }

    /// @brief Gets the total time registered for a section.
    /// @param sectionName Name of the section.
    /// @return Total time in microseconds, or 0 if not found.
    static ulong GetTotalTimeUs(string sectionName)
    {
        int idx = FindSection(sectionName);
        return (idx != -1) ? s_sections[idx].totalTimeUs : 0;
    }

    /// @brief Gets the call count registered for a section.
    /// @param sectionName Name of the section.
    /// @return Call count, or 0 if not found.
    static ulong GetCallCount(string sectionName)
    {
        int idx = FindSection(sectionName);
        return (idx != -1) ? s_sections[idx].callCount : 0;
    }
};

//+------------------------------------------------------------------+
//| Static Member Initializations                                    |
//+------------------------------------------------------------------+
SProfileSection CMNSProfiler::s_sections[];
int CMNSProfiler::s_sectionCount = 0;

//+------------------------------------------------------------------+
//| Macro Wrapper API (Enables compile-time stripping)              |
//+------------------------------------------------------------------+
#ifdef MNS_PROFILING_ENABLE
    #define MNS_ProfileStart(sec) CMNSProfiler::Start(sec)
    #define MNS_ProfileStop(sec)  CMNSProfiler::Stop(sec)
#else
    #define MNS_ProfileStart(sec)
    #define MNS_ProfileStop(sec)
#endif

#endif // __MNS_PROFILER_MQH__
