# MNS Trading Engine — Module 013
# Stage 7: Session Renderers & Premium/Discount Zones
# AI Implementation Prompt

Version: 1.0
Status: READY — Stage 6 Complete. Begin Stage 7.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:

1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `mns-answers1.md` — Locked client decisions (38 strategy rules, formally approved).
4. `mns-answers2.md` — Final client decisions (CLIENT-Q001, CLIENT-Q002, CLIENT-Q003).
5. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
6. `Include/MNS/MNSTypes.mqh` — Data Structures.
7. `Include/MNS/MNSConfig.mqh` — INF-004 Configuration Engine (To be modified).
8. `Include/MNS/MNSStyle.mqh` — Centralized visual style tokens (To be modified).
9. `Include/MNS/CPOIEngine.mqh` — Module 008: provides `GetEquilibrium()` and `GetDealingRangeZone()`.
10. `Include/MNS/CSwingDetector.mqh` — Module 002: provides latest swings for range calculations.
11. `Include/MNS/Renderers/CSwingRenderer.mqh` — Standard renderer reference pattern.
12. `Include/MNS/Renderers/CDashboardRenderer.mqh` — Dashboard renderer reference pattern.
13. `Indicators/MNS_Indicator.mq5` — Stages 1–6 coordinator (To be modified).
14. `docs/modules/013_IndicatorIntegration.md` — Module 013 functional specification.
15. `docs/indicator/UI_UX_SPECIFICATION.md` — Approved UI/UX specification (describes Premium Discount range fill and Sessions).
16. `docs/modules/013_STAGE_06_DESIGN.md` — Stage 6 design document (reference for configuration structure).

---

## ABSOLUTE RULES

1. Never invent trading logic.
2. All new settings must be centralized in the `CMNSConfig` system.
3. Every visual element must be cleanly separated into its own renderer class (`CSessionRenderer` and `CZoneRenderer`).
4. Prevent overlapping graphical objects. Divide the trading day into non-overlapping session segments.
5. All rectangle objects must draw behind candles using `OBJPROP_BACK = true` and `OBJPROP_FILL = true` for desaturated background fills.
6. Clean up objects on timeframe switch or deinitialization.

---

## STAGE 6 STATUS — COMPLETE ✅

Stage 6 (Configuration Binding) is complete and verified.

**Build result:**
- `MNS_Indicator.mq5`: 0 errors, 0 warnings.
- Tag: `v0.0.13-stage6`
- Runtime: All 11 engines and renderers now initialize using parameters bound to `CMNSConfig::GetActive()`, loaded dynamically from INI profile files and synced with indicator user inputs.

---

## STAGE 7 OBJECTIVES

Implement the **Session Shading Renderer** and the **Premium/Discount Zones Renderer** for `MNS_Indicator.mq5`.

Stage 7 draws:
1. **Premium & Discount Zones**: Shaded horizontal boxes showing cheap/expensive areas based on the current dealing range.
2. **Equilibrium Line**: A horizontal line separating the Premium and Discount zones.
3. **Session Shading bands**: Vertical background columns showing Asia, London, NY, and London/NY overlap hours.

### Deliverables

1. **`docs/modules/013_STAGE_07_DESIGN.md`** ← Create design document.
   - Specify naming conventions, session time segments, and zone drawing formulas.

2. **`Include/MNS/Renderers/CZoneRenderer.mqh`** ← Create new renderer.
   - Draws `"MNS_Zone_Premium"` (rectangle), `"MNS_Zone_Discount"` (rectangle), and `"MNS_Zone_Equilibrium"` (trend line) based on the latest external high and low swing points.

3. **`Include/MNS/Renderers/CSessionRenderer.mqh`** ← Create new renderer.
   - Evaluates historical bar times, groups them into non-overlapping segments using `gmtOffset`, draws vertical shaded boxes, and limits historical objects with a capping parameter.

4. **Update `Include/MNS/MNSStyle.mqh`**
   - Add colors for Premium box fill, Discount box fill, Equilibrium line, and four sessions (Asia, London, NY, Overlap).

5. **Update `Include/MNS/MNSConfig.mqh`**
   - Add settings to `SEngineConfig`: `showZonePremium`, `showZoneDiscount`, `showZoneEquilibrium`, `showSessions`, `maxRenderedSessions`.
   - Add validation bounds inside `UpdateParameter()`.

6. **Update `Indicators/MNS_Indicator.mq5`**
   - Add inputs: `InpShowZonePremium`, `InpShowZoneDiscount`, `InpShowZoneEquilibrium`, `InpShowSessions`, `InpMaxRenderedSessions`.
   - Sync these inputs to `CMNSConfig` inside `OnInit()`.
   - Initialize and run `g_zoneRenderer` and `g_sessionRenderer`.

---

## STAGE 7 TECHNICAL SPECIFICATIONS

### 1. Style Customizations (`Include/MNS/MNSStyle.mqh`)

Extend the `SIndicatorStyle` structure with these style tokens (and assign default desaturated dark tints in `Reset()`):

```mql5
//--- Premium/Discount Zone Styling
color colorZonePremium;       // Premium zone background fill (default: C'0x2F, 0x0A, 0x0A' - Dark Red)
color colorZoneDiscount;      // Discount zone background fill (default: C'0x0A, 0x2A, 0x14' - Dark Green)
color colorZoneEquilibrium;   // Equilibrium line color (default: clrGray)
ENUM_LINE_STYLE styleZoneEq;   // Equilibrium line style (default: STYLE_DASH)

//--- Session Shading Colors (very dark desaturated tints)
color colorSessionAsia;       // Asia session background (default: C'0x05, 0x05, 0x1F' - Dark Blue-Gray)
color colorSessionLondon;     // London-only background (default: C'0x05, 0x1F, 0x05' - Dark Green-Gray)
color colorSessionNY;         // NY-only background (default: C'0x1F, 0x14, 0x05' - Dark Orange-Gray)
color colorSessionOverlap;    // London/NY overlap background (default: C'0x1F, 0x05, 0x1F' - Dark Purple-Gray)
```

---

### 2. Configuration Parameters (`Include/MNS/MNSConfig.mqh`)

Extend `SEngineConfig` and `UpdateParameter()` validation rules:
*   `showZonePremium` (bool, default `true`)
*   `showZoneDiscount` (bool, default `true`)
*   `showZoneEquilibrium` (bool, default `true`)
*   `showSessions` (bool, default `true`)
*   `maxRenderedSessions` (int, default `15`, range `[3 .. 60]`)

---

### 3. Premium / Discount Renderer (`CZoneRenderer.mqh`)

#### Logic & Price Anchors
Query `CSwingDetector` for the latest confirmed external swing points:
*   `SSwingPoint extHigh = swingDetector.GetLatestExternalHigh();`
*   `SSwingPoint extLow = swingDetector.GetLatestExternalLow();`

If both swings are confirmed:
1.  **High Range Boundary**: `highPrice = extHigh.price`
2.  **Low Range Boundary**: `lowPrice = extLow.price`
3.  **Equilibrium (Midpoint)**: `eqPrice = (highPrice + lowPrice) / 2.0`
4.  **Older Swing Timestamp**: `startTime = MathMin(extHigh.createdTime, extLow.createdTime)`
5.  **Right Anchor Timestamp**: `endTime = time[1]` (last closed bar time)

#### Drawing Objects
*   **`MNS_Zone_Premium`** (Rectangle): Anchored from `(startTime, highPrice)` to `(endTime, eqPrice)`.
    *   Set `OBJPROP_FILL = true`, `OBJPROP_BACK = true`, color `colorZonePremium`.
*   **`MNS_Zone_Discount`** (Rectangle): Anchored from `(startTime, eqPrice)` to `(endTime, lowPrice)`.
    *   Set `OBJPROP_FILL = true`, `OBJPROP_BACK = true`, color `colorZoneDiscount`.
*   **`MNS_Zone_Equilibrium`** (Trend Line): Bounded segment from `(startTime, eqPrice)` to `(endTime, eqPrice)`.
    *   Set `OBJPROP_RAY_RIGHT = false`, width 1, style `styleZoneEq`, color `colorZoneEquilibrium`.

If either swing is unconfirmed or expired: delete all three objects.
Ensure `Reset()` wips these objects via `ObjectDelete`.

---

### 4. Session Shading Renderer (`CSessionRenderer.mqh`)

#### Time Segment Math
For a given bar `barTime` (broker local time), convert it to GMT:
```mql5
datetime gmtTime = barTime - gmtOffset * 3600;
MqlDateTime gmtStruct;
TimeToStruct(gmtTime, gStruct);
int hour = gStruct.hour;
```

To prevent overlapping drawing errors, slice the 24-hour day into **four non-overlapping segments**:
1.  **Asia**: `00:00 <= hour < 08:00` GMT $\rightarrow$ `colorSessionAsia`
2.  **London-Only**: `08:00 <= hour < 13:00` GMT $\rightarrow$ `colorSessionLondon`
3.  **London/NY Overlap**: `13:00 <= hour < 16:00` GMT $\rightarrow$ `colorSessionOverlap`
4.  **NY-Only**: `16:00 <= hour < 21:00` GMT $\rightarrow$ `colorSessionNY`
5.  *Off-hours (Closed)*: `21:00 <= hour < 24:00` GMT $\rightarrow$ Do not draw.

#### Drawing Bands
For each daily session block, draw a vertical rectangle:
*   Start Anchor: `(StartTimeOfSegment, 0.0)`
*   End Anchor: `(EndTimeOfSegment, 999999.0)` (or a high price bound, e.g., 2.00000 for FX).
*   Name format: `"MNS_Session_" + TypePrefix + "_" + DateString` (e.g., `"MNS_Session_Asia_2026_08_21"`).
*   TypePrefix: `Asia`, `Lon`, `Overlap`, `NY`.
*   Capping: Keep only the most recent `maxRenderedSessions` blocks rendered. Automatically delete older session objects during updating.
*   Ensure `Reset()` does `ObjectsDeleteAll(0, "MNS_Session_")`.

---

## SELF-REVIEW CHECKLIST

- [ ] All code compiles cleanly with 0 errors, 0 warnings.
- [ ] Session boxes are mapped to non-overlapping segments to prevent visual rendering bugs.
- [ ] `OBJPROP_BACK = true` and `OBJPROP_FILL = true` are applied to all rectangles so wicks stay visible.
- [ ] `Reset()` routines cleanly wipe objects from the chart.
- [ ] No compiler errors in `MNS_TestHarness.mq5`.

---

## NEXT STEP INSTRUCTIONS

After code implementation:
1. Run `Build-And-Archive.ps1`:
   ```powershell
   .\tools\Build-And-Archive.ps1 -Module "Module013_Stage7"
   ```
2. Verify visual rendering inside MT5 (both H1 and M5 charts).
3. Commit your changes and tag the release:
   ```bash
   git tag -a v0.0.13-stage7 -m "Module 013 Stage 7 - Session and Zone renderers complete"
   ```
