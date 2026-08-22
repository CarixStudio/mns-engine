# MNS Trading Engine — Module 013
# Stage 8: Visual Performance Profiling
# AI Implementation Prompt

Version: 1.0
Status: READY — Stage 7 Complete. Begin Stage 8.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:

1. `Include/MNS/MNSProfiler.mqh` — INF-007 Performance Monitor (Macro definitions and telemetry reporter).
2. `Indicators/MNS_Indicator.mq5` — Stages 1–7 coordinator (To be modified).
3. `Include/MNS/Renderers/CSwingRenderer.mqh` through `CZoneRenderer.mqh` — Individual visual renderers.
4. `docs/modules/013_STAGE_07_DESIGN.md` — Stage 7 detailed design specifications.
5. `roadmap.md` — Project roadmap.

---

## ABSOLUTE RULES

1. Never invent trading logic.
2. Use the macro-wrapper API (`MNS_ProfileStart(sec)` and `MNS_ProfileStop(sec)`) for profiling. Do not call `CMNSProfiler` methods directly in hot paths, preserving compile-time stripping when `MNS_PROFILING_ENABLE` is undefined.
3. Define `#define MNS_PROFILING_ENABLE` at the very top of `MNS_Indicator.mq5` (before including the engine headers) to activate telemetry.
4. All profiling macros must have exact matching Start/Stop string section names.
5. The performance telemetry must be output to the Experts log both at deinitialization (`OnDeinit`) and periodically during execution.

---

## STAGE 7 STATUS — COMPLETE ✅

Stage 7 (Session Renderers & Premium/Discount Zones) is complete and verified under tag `v0.0.13-stage7`.

**Build result:**
- `MNS_Indicator.mq5`: 0 errors, 0 warnings.
- Runtime: Session shading bands (non-overlapping vertical columns for Asia, London, NY, and Overlap hours) and Premium/Discount zones (colored filled horizontal rectangles divided by the Equilibrium trend line) are drawing correctly in the background behind wicks and candles. The status dashboard has been extended to 16 total rows to display `Entry Price` and `SL (Stop Loss)` metrics.

---

## STAGE 8 OBJECTIVE

Implement visual performance profiling telemetry for `MNS_Indicator.mq5`. This stage integrates the high-resolution microsecond timer macros from `INF-007` to measure the precise CPU execution latency of both the analysis engines and the visual renderers. This ensures the indicator runs under strict speed guidelines and has zero memory or processor footprint leaks.

### Deliverables

1. **`docs/modules/013_STAGE_08_DESIGN.md`** ← Create design document.
   - Describe the targeted profile sections, expected microsecond bounds, periodic logging interval, and validation of zero-overhead stripping.

2. **Update `Indicators/MNS_Indicator.mq5`**
   - Define `#define MNS_PROFILING_ENABLE` at the top of the file.
   - Wrap the calculation loop, the entire engine update block, and each individual engine's `Update()` block in profiling start/stop macros.
   - Wrap the entire rendering block and each individual renderer's `Draw()` block in profiling start/stop macros.
   - Call `CMNSProfiler::ReportTelemetry()` at deinitialization inside `OnDeinit()`.
   - Implement a periodic logging block in `OnCalculate()` to report and reset telemetry every 1000 calculates if debug logging is enabled.

---

## STAGE 8 PROFILE SECTIONS & WRAPPING SPECIFICATION

You must place `MNS_ProfileStart()` and `MNS_ProfileStop()` macros around the following blocks inside `OnCalculate()` of `MNS_Indicator.mq5`:

### 1. Calculation & Engine Updates
*   **Total Calculate block**: Name `"Total_Calculate"`. Spans from the beginning of `OnCalculate()` (after the new bar filter check) to the end of the entry engine update.
*   **Core Engine Updates block**: Name `"Core_Engine_Updates"`. Spans from the start of the swing detector update to the end of the risk engine initialization.
*   **Individual Engine Updates**:
    - Swing Detector: `"Engine_Swings"`
    - Structure Engine: `"Engine_Structure"`
    - Break Detector: `"Engine_Breaks"`
    - Order Flow Engine: `"Engine_OrderFlow"`
    - Delivery Engine: `"Engine_Delivery"`
    - Liquidity Engine: `"Engine_Liquidity"`
    - POI Engine: `"Engine_POI"`
    - Objective Engine: `"Engine_Objective"`
    - Confirmation Engine: `"Engine_Confirmation"`
    - Entry Engine: `"Engine_Entry"`

Example:
```mql5
    MNS_ProfileStart("Engine_Swings");
    if (!g_swings.Update(high, low, close, open, time, limitBars, prev_calculated))
    {
        MNS_Log(MNS_LOG_ERROR, MNS_INDICATOR_SOURCE, "CSwingDetector::Update() FAILED.");
        return 0;
    }
    MNS_ProfileStop("Engine_Swings");
```

### 2. Graphical Rendering Updates
*   **Total Rendering block**: Name `"Total_Rendering"`. Spans from the first renderer call (`g_swingRenderer.Draw`) to the end of the dashboard rendering block.
*   **Individual Renderer Drawings**:
    - Swing Renderer: `"Render_Swings"`
    - Structure Renderer: `"Render_Structure"`
    - Liquidity Renderer: `"Render_Liquidity"`
    - POI Renderer: `"Render_POI"`
    - Delivery Renderer: `"Render_Delivery"`
    - Zone Renderer: `"Render_Zones"`
    - Session Renderer: `"Render_Sessions"`
    - Dashboard Renderer: `"Render_Dashboard"`

---

## TELEMETRY REPORTING LOGIC

### 1. Final Report on Deinitialization
In `OnDeinit()`, call the report generator:
```mql5
void OnDeinit(const int reason)
{
    // Existing reset calls...
    
    #ifdef MNS_PROFILING_ENABLE
        MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "Generating final performance profile report...");
        CMNSProfiler::ReportTelemetry();
        CMNSProfiler::Reset();
    #endif
}
```

### 2. Periodic Live Reporting
To prevent logging on every tick (which degrades performance), implement a 1000-calculate interval check in `OnCalculate()`. This reports metrics to the Experts tab and resets counters to prevent infinite accumulation, ensuring you see the latest latency profile:

```mql5
    // Inside OnCalculate()
    static int calculateCounter = 0;
    calculateCounter++;
    
    if (calculateCounter >= 1000)
    {
        #ifdef MNS_PROFILING_ENABLE
            if (InpDebugLogging)
            {
                MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, "Periodic 1000-tick performance profile report:");
                CMNSProfiler::ReportTelemetry();
            }
            CMNSProfiler::Reset(); // Reset to clear accumulated telemetry for the next interval
        #endif
        calculateCounter = 0;
    }
```

---

## SELF-REVIEW CHECKLIST

- [ ] All code compiles cleanly with 0 errors, 0 warnings.
- [ ] No compiler errors in `MNS_TestHarness.mq5` (proving macro stripping works when `MNS_PROFILING_ENABLE` is undefined).
- [ ] Every `MNS_ProfileStart()` has a corresponding `MNS_ProfileStop()` with the exact same name.
- [ ] Profiling timers wrap calculations after the new bar check, preventing idle ticks from diluting active data.
- [ ] Telemetry is output to the Experts log in `OnDeinit()`.
- [ ] Caching and object manager lookups are profiled to verify O(1) properties.

---

## NEXT STEP INSTRUCTIONS

After code implementation:
1. Run `Build-And-Archive.ps1`:
   ```powershell
   .\tools\Build-And-Archive.ps1 -Module "Module013_Stage8"
   ```
2. Attach the indicator to a chart and check the Experts log on removal (deinitialization) to verify that the telemetry report prints.
3. Commit your changes and tag the release:
   ```bash
   git tag -a v0.0.13-stage8 -m "Module 013 Stage 8 - Visual Performance Profiling complete"
   ```
