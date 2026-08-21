# MNS Trading Engine — Module 013
# Stage 6: Configuration Binding (INF-004 Integration)
# AI Implementation Prompt

Version: 1.0
Status: READY — Stage 5 Complete. Begin Stage 6.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:

1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `mns-answers1.md` — Locked client decisions (38 strategy rules, formally approved).
4. `mns-answers2.md` — Final client decisions (CLIENT-Q001, CLIENT-Q002, CLIENT-Q003).
5. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
6. `Include/MNS/MNSTypes.mqh` — Data Structures.
7. `Include/MNS/MNSConfig.mqh` — INF-004 Configuration Engine (Primary file to be modified).
8. `Include/MNS/MNSUtils.mqh` — Utility functions.
9. `Include/MNS/MNSLogger.mqh` — Logging infrastructure.
10. `Include/MNS/CLiquidityEngine.mqh` — Module 007: requires GMT Offset binding.
11. `Include/MNS/CEntryEngine.mqh` — Module 011: requires Max Spread points binding.
12. `Include/MNS/CRiskEngine.mqh` — Module 012: requires Desired Risk Percent binding.
13. `Indicators/MNS_Indicator.mq5` — Stages 1–5 coordinator (Primary file to be modified).
14. `docs/modules/013_IndicatorIntegration.md` — Module 013 functional specification.
15. `docs/indicator/UI_UX_SPECIFICATION.md` — Approved UI/UX specification.
16. `docs/modules/013_ISSUES.md` — Open issue register (tracks M13-ISSUE-002 and M13-ISSUE-004).
17. `docs/DEFERRED.md` — Global deferred issues (tracks MNS-ISSUE-002 and MNS-ISSUE-004).
18. `docs/TODO_STRATEGY.md` — Strategy ambiguities log.
19. `docs/CLASS_DIAGRAM.md` — Design blueprint.
20. `docs/CodingStandards.md` — Coding standards.

---

## ABSOLUTE RULES (Inherited from PROMPT_NEW_MODULE.md)

1. Never invent trading logic.
2. Every parameter must be centralized in the `CMNSConfig` system.
3. Do not bypass configuration validation.
4. If a parameter range is violated at runtime, handle it gracefully by failing parameter updates or using a safe default.
5. Preserve 100% compatibility with all previous stages.
6. Ensure that the test harness (`MNS_TestHarness.mq5`) compiles and passes without errors or warnings.
7. Static arrays must use `#define` or literals — never `const int`.

---

## STAGE 5 STATUS — COMPLETE ✅

Stage 5 (`CDashboardRenderer.mqh`) is done and verified.

**Build result:**
- `MNS_Indicator.mq5`: 0 errors, 0 warnings
- Tag: `v0.13.5`
- Runtime: The status dashboard renders on chart in the top-left corner, correctly highlighting bullish (green), bearish (red), transition (orange), and neutral (white) metrics. Dragging and scrolling recalculate coordinates cleanly.

---

## STAGE 6 OBJECTIVE

The goal of Stage 6 is to complete **Configuration Binding (INF-004 Integration)**. This binds all user-facing indicator inputs and profiles directly to the centralized `CMNSConfig` configuration system, resolving key deferred configuration inconsistencies (`MNS-ISSUE-002` / `MNS-ISSUE-004`).

By the end of this stage, all core engines and visual renderers must initialize and run using parameters retrieved dynamically from `CMNSConfig::GetActive()`, rather than from isolated global inputs.

### Deliverables

1. **`docs/modules/013_STAGE_06_DESIGN.md`** ← Create design document.
   - Describe configuration binding layout, settings profile loading, validation bounds, and engine initialization mapping.

2. **Update `Include/MNS/MNSConfig.mqh`**
   - Extend `SEngineConfig` structure to include analytical settings (`gmtOffset`, `maxSpreadPoints`, `desiredRiskPercent`) and visual settings (`maxRenderedSwings`, `maxRenderedBreaks`, `maxRenderedPools`, `maxRenderedPOIs`, `showDashboard`, `dashboardX`, `dashboardY`, `dashboardWidth`).
   - Extend `SetDefaults()` to assign default values to these settings.
   - Extend `UpdateParameter()` to support validation bounds checks for each new parameter.

3. **Update `Indicators/MNS_Indicator.mq5`**
   - Add input parameter `input string InpConfigFile = "";` (to support loading custom configuration profiles from files).
   - In `OnInit()`:
     1. Load default settings: `CMNSConfig::SetDefaults()`.
     2. If `InpConfigFile` is not empty, load settings from file: `CMNSConfig::LoadFromFile(InpConfigFile)`.
     3. Sync indicator `input` variables to `CMNSConfig` using `CMNSConfig::UpdateParameter()`. This ensures that user changes in the MT5 input dialog box overwrite defaults or profile files.
     4. Retrieve the unified settings structure: `SEngineConfig cfg = CMNSConfig::GetActive();`.
     5. Pass variables from `cfg` to the initialization routines of the engines and renderers (replacing global inputs).
   - In `OnCalculate()`:
     1. Pass configuration-derived boundaries (`minBreakDistance`, etc.) to the update loops.

---

## STAGE 6 CONFIGURATION DETAILS

### 1. Structure Changes (`Include/MNS/MNSConfig.mqh`)

You must add the following parameters to the `SEngineConfig` structure:

```mql5
struct SEngineConfig
{
    //--- Existing Strategy Fields (DO NOT MODIFY)
    int    externalDepth;
    int    internalDepth;
    double atrTolerance;
    double minBreakDistance;
    double confidenceThreshold;
    double displacementMinAtrMultiple;
    double displacementMinBodyRatio;
    double displacementMinCloseStrength;
    int    atrPeriod;
    bool   logEnable;
    int    logLevel;

    //--- Stage 6 Analytical Additions (M13-ISSUE-002, M13-ISSUE-004)
    int    gmtOffset;                 // GMT Offset in hours
    double maxSpreadPoints;           // Max spread filter
    double desiredRiskPercent;         // Desired risk percent per trade

    //--- Stage 6 Visual Capping Additions
    int    maxRenderedSwings;         // Max swing objects to render
    int    maxRenderedBreaks;         // Max BOS/CHoCH lines to render
    int    maxRenderedPools;          // Max liquidity pool lines to render
    int    maxRenderedPOIs;           // Max POI rectangles to render

    //--- Stage 6 Dashboard Layout Additions
    bool   showDashboard;             // Enable dashboard rendering
    int    dashboardX;                // Y-coordinate dashboard pixel offset
    int    dashboardY;                // Y-coordinate dashboard pixel offset
    int    dashboardWidth;            // Panel width in pixels
};
```

### 2. Default Mappings (`CMNSConfig::SetDefaults()`)
Assign the following strategy defaults to the new fields:
*   `gmtOffset = 0;`
*   `maxSpreadPoints = 50.0;`
*   `desiredRiskPercent = 1.0;`
*   `maxRenderedSwings = 50;`
*   `maxRenderedBreaks = 20;`
*   `maxRenderedPools = 20;`
*   `maxRenderedPOIs = 20;`
*   `showDashboard = true;`
*   `dashboardX = 20;`
*   `dashboardY = 20;`
*   `dashboardWidth = 250;`

### 3. Dynamic Bounds Validation (`CMNSConfig::UpdateParameter()`)
Implement strict validation boundary checks for all newly added configurations:
*   `gmtOffset`: Range `[-12 .. 12]`. Fail if outside this range.
*   `maxSpreadPoints`: Must be `>= 0.0` and `<= 500.0`.
*   `desiredRiskPercent`: Must be `>= 0.0` and `<= 10.0`.
*   `maxRenderedSwings`: Range `[10 .. 500]`.
*   `maxRenderedBreaks`: Range `[5 .. 200]`.
*   `maxRenderedPools`: Range `[5 .. 200]`.
*   `maxRenderedPOIs`: Range `[5 .. 200]`.
*   `showDashboard`: Double check `(value != 0.0)` for boolean assignment.
*   `dashboardX`: Range `[0 .. 2000]`.
*   `dashboardY`: Range `[0 .. 2000]`.
*   `dashboardWidth`: Range `[150 .. 500]`.

Example implementation block inside `UpdateParameter()`:
```mql5
else if (name == "gmtOffset")
{
    int val = (int)value;
    MNS_Assert(val >= -12 && val <= 12, "UpdateParameter: gmtOffset must be [-12..12]");
    if (val < -12 || val > 12) return false;
    s_config.gmtOffset = val;
    return true;
}
```

---

## INDICATOR ENTRY & ENGINE LIFECYCLE BINDING (`Indicators/MNS_Indicator.mq5`)

### 1. Add Configuration File Input
Declare a new input parameter under the input section:
```mql5
/// @brief Settings profile file path relative to MQL5\Files sandbox folder (optional).
input string InpConfigFile        = "";
```

### 2. Bind Configuration in `OnInit()`
Execute these actions in order during startup initialization:
```mql5
// 1. Reset defaults
CMNSConfig::SetDefaults();

// 2. Load profile file if specified
if (InpConfigFile != "")
{
    if (CMNSConfig::LoadFromFile(InpConfigFile))
    {
        MNS_Log(MNS_LOG_INFO, MNS_INDICATOR_SOURCE, StringFormat("Settings profile loaded from file: %s", InpConfigFile));
    }
    else
    {
        MNS_Log(MNS_LOG_WARN, MNS_INDICATOR_SOURCE, StringFormat("Failed to load settings profile from %s. Using default parameters.", InpConfigFile));
    }
}

// 3. Sync MT5 Input parameters back to CMNSConfig
CMNSConfig::UpdateParameter("gmtOffset", (double)InpGmtOffset);
CMNSConfig::UpdateParameter("maxSpreadPoints", InpMaxSpreadPoints);
CMNSConfig::UpdateParameter("desiredRiskPercent", InpDefaultRisk);
CMNSConfig::UpdateParameter("maxRenderedSwings", (double)InpMaxRenderedSwings);
CMNSConfig::UpdateParameter("maxRenderedBreaks", (double)InpMaxRenderedBreaks);
CMNSConfig::UpdateParameter("maxRenderedPools", (double)InpMaxRenderedPools);
CMNSConfig::UpdateParameter("maxRenderedPOIs", (double)InpMaxRenderedPOIs);
CMNSConfig::UpdateParameter("showDashboard", InpShowDashboard ? 1.0 : 0.0);
CMNSConfig::UpdateParameter("dashboardX", (double)InpDashboardX);
CMNSConfig::UpdateParameter("dashboardY", (double)InpDashboardY);
CMNSConfig::UpdateParameter("dashboardWidth", (double)InpDashboardWidth);

// 4. Extract active configuration context
SEngineConfig cfg = CMNSConfig::GetActive();
```

### 3. Engine & Renderer Setup
Update the engine instantiations to use `cfg` values:
*   `g_liquidity.Initialize(cfg.gmtOffset)`
*   `g_entry.Initialize(cfg.maxSpreadPoints)`
*   `g_risk.Initialize(cfg.desiredRiskPercent, 0.25, 2.0, 5.0)`
*   `g_swingRenderer.Initialize(style, cfg.maxRenderedSwings)`
*   `g_structureRenderer.Initialize(cfg.maxRenderedBreaks)`
*   `g_liquidityRenderer.Initialize(style, cfg.maxRenderedPools)`
*   `g_poiRenderer.Initialize(style, cfg.maxRenderedPOIs)`

### 4. Dashboard Binding
In `OnCalculate()`, update the dashboard renderer parameters to pass settings from configuration rather than raw inputs:
```mql5
// Read values from active configuration structure
SEngineConfig cfg = CMNSConfig::GetActive();

// Check showDashboard flag before drawing
if (cfg.showDashboard)
{
    datetime gmtTime = time[0] - cfg.gmtOffset * 3600;
    g_dashboardRenderer.Draw(g_poi, g_delivery, g_objective, g_swings, g_structure, g_breaks, g_orderFlow, g_liquidity, g_confirmation, g_entry, g_risk, time, close, limitBars, gmtTime);
}
else
{
    g_dashboardRenderer.Reset(); // Wipe panel objects if disabled
}
```

Make sure `CDashboardRenderer::Draw` internally utilizes `cfg.dashboardX`, `cfg.dashboardY`, and `cfg.dashboardWidth` from settings rather than relying on hardcoded constants or direct global variables.

---

## WHAT STAGE 6 MUST NOT DO

*   ❌ Implement session lines drawing or premium/discount zone drawing (Stage 7).
*   ❌ Implement performance profiling metrics (Stage 8).
*   ❌ Modify raw engine logic calculations (except binding config parameters on initialization).
*   ❌ Let invalid values corrupt variables. Enforce validation boundaries.

---

## SELF-REVIEW CHECKLIST

Before submitting:
- [ ] No compiler errors or warnings in `MNS_Indicator.mq5` or `MNS_TestHarness.mq5`.
- [ ] All new input bindings have assertion checks in `MNSConfig.mqh`.
- [ ] Profile files load cleanly from sandboxed directory using `CMNSConfig::LoadFromFile()`.
- [ ] Changing settings in input dialogue updates the config correctly at runtime.
- [ ] `CDashboardRenderer` uses configuration coordinates (`cfg.dashboardX`, `cfg.dashboardY`, `cfg.dashboardWidth`) for scaling.
- [ ] All 11 engines compile cleanly.

---

## POST-IMPLEMENTATION REGISTRY UPDATES

After verification tests pass:
1. **Update `docs/modules/013_ISSUES.md`**:
   - Mark `M13-ISSUE-002` (Risk & Spread Configuration Inconsistency) as **✅ RESOLVED** with a description of the parameters bound.
   - Mark `M13-ISSUE-004` (Session Parameter Centralization) as **✅ RESOLVED**.
2. **Update `docs/DEFERRED.md`**:
   - Mark `MNS-ISSUE-002` (Unification of Risk Sizing & Spread Filters) as **✅ RESOLVED**.
   - Mark `MNS-ISSUE-004` (Session Parameter & GMT Offset Centralization) as **✅ RESOLVED**.
3. **Update `roadmap.md`**:
   - Mark **Stage 6: Configuration Binding** as **✅ Complete**.

