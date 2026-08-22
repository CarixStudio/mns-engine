# MNS Trading Engine — Module 013
# Stage 8: Visual Performance Profiling Design Document

## 1. Overview
This document specifies the design of **Stage 8: Visual Performance Profiling** under Module 013 Indicator Integration.
This stage integrates the high-resolution microsecond timer macros from `INF-007` to measure the precise CPU execution latency of both the analysis engines and the visual renderers. It also includes the integration of the missing Stage 7 renderers (`CZoneRenderer` and `CSessionRenderer`) so that they are actively profiled.

---

## 2. Profiling Architecture & Sections

Profiling is implemented via the compile-time conditional macros `MNS_ProfileStart(sec)` and `MNS_ProfileStop(sec)`. These macros resolve to high-resolution microsecond timing calls to `CMNSProfiler` when `MNS_PROFILING_ENABLE` is defined.

We establish a nested hierarchy of execution timing blocks inside `OnCalculate()`:

```
[OnCalculate Tick Entry]
   |
   |-- "Total_Calculate" (Engine updates)
   |     |
   |     |-- "Core_Engine_Updates"
   |     |     |-- "Engine_Swings" (Swing Detector)
   |     |     |-- "Engine_Structure" (Structure Engine)
   |     |     |-- "Engine_Breaks" (Break Detector)
   |     |     |-- ... (remaining 7 engines)
   |
   |-- "Total_Rendering" (Visual renderers)
   |     |-- "Render_Swings" (Swing Renderer)
   |     |-- "Render_Structure" (Structure Renderer)
   |     |-- "Render_Zones" (Zone Renderer)
   |     |-- "Render_Sessions" (Session Renderer)
   |     |-- "Render_Dashboard" (Dashboard Renderer)
   |     |-- ...
```

---

## 3. Targeted Profile Sections & Microsecond Budgets

To keep the indicator highly responsive and prevent MetaTrader 5 UI freezing, we define strict performance budgets for each profile section.

| Section Name | Profile Target | Expected Budget | Action on Threshold Violation |
| :--- | :--- | :--- | :--- |
| `"Total_Calculate"` | Full Engine Update block | `< 8,000 us` | Performance warning log |
| `"Core_Engine_Updates"` | All 11 sequential engines | `< 6,000 us` | Performance warning log |
| `"Engine_Swings"` | Swing Detection | `< 1,500 us` | Optimize recursive checks |
| `"Engine_Structure"` | Structure Breaks | `< 1,000 us` | Optimize swing traversal |
| `"Engine_Breaks"` | Break Detection | `< 1,000 us` | Optimize ATR & price scan |
| `"Engine_POI"` | POI Range Mapping | `< 500 us` | Optimize object checks |
| `"Total_Rendering"` | All 8 visual drawing scripts | `< 10,000 us` | Performance warning log |
| `"Render_Sessions"` | Session Band grouping | `< 2,000 us` | Optimize run-length scan |
| `"Render_Zones"` | Premium/Discount rectangles | `< 500 us` | Use ObjectMove instead of recreate |
| `"Render_Dashboard"` | Text label properties updates | `< 1,500 us` | Prevent redundant object updates |

---

## 4. Telemetry Reporting Logic

Telemetry is reported to the MT5 Experts log tab under two conditions:

### 1. Periodic Telemetry (On-the-fly)
To monitor active performance without degrading latency via constant logging, `OnCalculate()` tracks calculate events via a static counter. Every **1000 calculate cycles**:
*   The current telemetry report is printed (calls count, total time, average latency in microseconds) **only** if debug logging (`InpDebugLogging`) is enabled.
*   `CMNSProfiler::Reset()` is called to clear accumulated metrics, preventing numerical overflow and capturing the latest running average.

### 2. Final Telemetry (Deinitialization)
When the indicator is removed or the timeframe is changed:
*   A final report is generated via `CMNSProfiler::ReportTelemetry()` at deinitialization inside `OnDeinit()`.
*   All profiler registry arrays are cleared.

---

## 5. Zero-Overhead Stripping Validation

When `#define MNS_PROFILING_ENABLE` is **not** defined, the wrapper macros compile to empty directives:
```mql5
#define MNS_ProfileStart(sec)
#define MNS_ProfileStop(sec)
```
This ensures:
1.  No CPU overhead or memory footprint is introduced in production release mode (complete binary stripping).
2.  No compiler errors occur in the test harness (`MNS_TestHarness.mq5`) or EA imports since they do not define the flag and bypass the telemetry engine completely.
