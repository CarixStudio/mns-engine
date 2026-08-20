# MNS Trading Engine — Module 013
# Stage 5: Dashboard & Info Panel
# AI Implementation Prompt

Version: 1.0
Status: READY — Stage 4 Complete. Begin Stage 5.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:

1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `mns-answers1.md` — Locked client decisions (38 strategy rules, formally approved).
4. `mns-answers2.md` — Final client decisions (CLIENT-Q001, CLIENT-Q002, CLIENT-Q003).
5. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
6. `Include/MNS/MNSTypes.mqh` — All shared data structures (`SMarketState`, `SOrderFlowState`, `SDeliveryState`, `SDolDefinition`, `SConfirmationState`, etc.).
7. `Include/MNS/MNSUtils.mqh` — Utility functions.
8. `Include/MNS/MNSLogger.mqh` — Logging infrastructure.
9. `Include/MNS/MNSStyle.mqh` — Centralized visual style tokens (`SIndicatorStyle`).
10. `Include/MNS/CSwingDetector.mqh` — Module 002.
11. `Include/MNS/CStructureEngine.mqh` — Module 003: trend/phase data.
12. `Include/MNS/CBreakDetector.mqh` — Module 004: BOS/CHoCH data.
13. `Include/MNS/COrderFlowEngine.mqh` — Module 005: order flow state data.
14. `Include/MNS/CDeliveryStructureEngine.mqh` — Module 006: delivery leg data.
15. `Include/MNS/CLiquidityEngine.mqh` — Module 007: BSL/SSL data.
16. `Include/MNS/CPOIEngine.mqh` — Module 008: OB/FVG data.
17. `Include/MNS/CObjectiveEngine.mqh` — Module 009: DOL target data.
18. `Include/MNS/CConfirmationEngine.mqh` — Module 010: confirmation setup data.
19. `Include/MNS/CEntryEngine.mqh` — Module 011: entry signals.
20. `Include/MNS/CRiskEngine.mqh` — Module 012: risk calculations.
21. `Include/MNS/Renderers/CSwingRenderer.mqh` — Stage 2 reference.
22. `Include/MNS/Renderers/CStructureRenderer.mqh` — Stage 2 reference.
23. `Include/MNS/Renderers/CLiquidityRenderer.mqh` — Stage 3 reference.
24. `Include/MNS/Renderers/CPOIRenderer.mqh` — Stage 4 reference.
25. `Include/MNS/Renderers/CDeliveryRenderer.mqh` — Stage 4 reference.
26. `Indicators/MNS_Indicator.mq5` — Stages 1–4 coordinator (read carefully before modifying).
27. `docs/modules/013_IndicatorIntegration.md` — Module 013 spec.
28. `docs/INDICATOR_SPECIFICATION.md` — Approved visual inventory.
29. `docs/indicator/UI_UX_SPECIFICATION.md` — Approved UI/UX specification.
30. `docs/modules/013_ISSUES.md` — Open issue register.
31. `docs/DEFERRED.md` — Global deferred items register.

---

## ABSOLUTE RULES (Inherited from PROMPT_NEW_MODULE.md)

1. Never invent trading logic.
2. Never substitute generic SMC/ICT algorithms.
3. Every dashboard text string and visual state must be traceable to a core engine output or locked client decision.
4. If a strategy rule is ambiguous — document it. Do NOT guess.
5. Distinguish clearly:
   - ✅ **Specified** — directly stated in strategy or locked client decision
   - ⚠️ **Inferred** — reasonable engineering inference
   - ❌ **Unknown / TODO** — not covered, do not implement
6. Write production-quality MQL5 for long-term maintenance.
7. Comment every public class and method.
8. Preserve consistency with Stages 1–4.
9. **Never modify `MNS_Indicator.mq5`** except to add includes, global renderer instances, `Initialize()` calls in `OnInit()`, `Draw()` calls at the end of `OnCalculate()`, and `Reset()` calls in `OnDeinit()`.
10. Never modify core engine headers (`CSwingDetector.mqh` through `CRiskEngine.mqh`).
11. Never modify Stage 2–4 renderer files.
12. Static arrays must use `#define` or literals — never `const int`.
13. No broker API / trading calls anywhere in the indicator layer.

---

## STAGE 4 STATUS — COMPLETE ✅

Stage 4 (`CPOIRenderer.mqh`, `CDeliveryRenderer.mqh`) is done, compiled with 0 errors and 0 warnings, committed, and tagged as `v0.13.4`.

**What Stage 4 produced:**
- `Include/MNS/Renderers/CPOIRenderer.mqh` — OB/FVG/Breaker/Mitigation zone filled rectangles.
- `Include/MNS/Renderers/CDeliveryRenderer.mqh` — Active delivery leg segment & active DOL target horizontal ray.
- `MNSStyle.mqh` — Extended with POI, Delivery, and DOL visual style tokens.

---

## LOCKED CLIENT DECISIONS

All locked decisions from `mns-answers1.md` and `mns-answers2.md` must be respected.
Specifically:
- **CLIENT-Q001**: Omit CRT/IRL/ERL as separate engines. Use standard MNS terminology (BSL, SSL, OB, FVG).
- **CLIENT-Q002**: Active only. The dashboard displays the *current active* state of the engines. No historical stats or tracking.
- **CLIENT-Q003**: Enforced heuristics (GMT offset, minimum break distances, session hours: Tokyo 00-08, London 08-16, NY 13-21 GMT).

---

## STAGE 5 OBJECTIVE

Implement the **Dashboard & Info Panel** visual layer for `MNS_Indicator.mq5`.

Stage 5 creates a graphical panel anchored to a specified chart corner (default: Top-Right) using standard MT5 graphical objects (`OBJ_RECTANGLE_LABEL` for the background and `OBJ_LABEL` for text rows). It reads the active state from all 11 core engines and displays key market metrics clearly in a stacked layout.

### Deliverables

1. **`Include/MNS/Renderers/CDashboardRenderer.mqh`** ← PRIMARY DELIVERABLE
   - Creates a background container using `OBJ_RECTANGLE_LABEL`.
   - Creates structured rows of text labels using `OBJ_LABEL`.
   - Dynamically updates text strings and colors based on active engine values.
   - Cleans up all dashboard objects on deinitialization.

2. **Update `Include/MNS/MNSStyle.mqh`**
   - Add styling tokens for the dashboard panel (e.g. background color, border color, text colors for headers, labels, and status values, font name, font sizes, width, row height, and spacing).
   - Do NOT remove or rename existing fields.

3. **Update `Indicators/MNS_Indicator.mq5`**
   - Add `#include <MNS/Renderers/CDashboardRenderer.mqh>`.
   - Declare `CDashboardRenderer g_dashboardRenderer;` as a global instance.
   - Call `g_dashboardRenderer.Initialize(style, InpShowDashboard, InpDashboardX, InpDashboardY, InpDashboardWidth)` in `OnInit()`.
   - Call `g_dashboardRenderer.Draw(...)` at the end of `OnCalculate()`, passing all 11 engines, current symbol, period, spread, and GMT time.
   - Call `g_dashboardRenderer.Reset()` in `OnDeinit()`.
   - Add the following inputs:
     - `input bool   InpShowDashboard      = true;`
     - `input int    InpDashboardX         = 20;`
     - `input int    InpDashboardY         = 20;`
     - `input int    InpDashboardWidth     = 250;`

---

## STAGE 5 RENDERING & LAYOUT RULES

### Background Container
- Object type: `OBJ_RECTANGLE_LABEL`.
- Name: `"MNS_Dash_Bg"`.
- Properties:
  - `OBJPROP_XDISTANCE`: `InpDashboardX`.
  - `OBJPROP_YDISTANCE`: `InpDashboardY`.
  - `OBJPROP_XSIZE`: `InpDashboardWidth` (default 250 px).
  - `OBJPROP_YSIZE`: Auto-calculated based on the number of rows (typically 12-15 rows × RowHeight).
  - `OBJPROP_CORNER`: `CORNER_RIGHT_UPPER` (or style config).
  - `OBJPROP_BGCOLOR`: `m_style.colorDashboardBg` (default: Dark Gray C'30,30,30' or C'20,20,20').
  - `OBJPROP_COLOR`: `m_style.colorDashboardBorder` (default: Medium Gray C'60,60,60').
  - `OBJPROP_BORDER_TYPE`: `BORDER_FLAT`.
  - `OBJPROP_BACK`: `false` (must sit on top of the chart candles).

### Text Row Object Structure
To achieve a clean vertical alignment:
- Each row of the dashboard consists of a pair of `OBJ_LABEL` objects:
  1. **Label Name (Left-aligned)**: Static text (e.g. `"Trend:"`, `"Phase:"`, `"Last BOS:"`).
  2. **Label Value (Right-aligned)**: Dynamic text populated from engine state (e.g. `"Bullish"`, `"Pullback"`, `"Bullish @ 1.2750"`).
- Left-aligned text: `OBJPROP_XDISTANCE = InpDashboardX + Padding` (e.g., 10px from the left edge).
- Right-aligned text: `OBJPROP_XDISTANCE = InpDashboardX + InpDashboardWidth - Padding` (e.g., 10px from the right edge), and set `OBJPROP_ANCHOR = ANCHOR_RIGHT_UPPER` or `ANCHOR_RIGHT_LOWER`.
- Vertical position for row `N`: `Y = InpDashboardY + HeaderHeight + (N * RowHeight)`.
- Use unique names for every text object, prefixed with `"MNS_Dash_Lbl_"` and `"MNS_Dash_Val_"`.
  - Examples: `"MNS_Dash_Lbl_Trend"`, `"MNS_Dash_Val_Trend"`.

### Dashboard Sections & Values

The dashboard must display the following structured information:

1. **Header Section**
   - Main Header: `"MNS ENGINE v1.0"` (Bold font, `colorDashboardHeader` - default `clrLime`).
   - Context: `SymbolInfo` / timeframe (e.g. `"Symbol/TF: GBPUSD, H1"`).

2. **Market State Section**
   - **Trend**: Bullish / Bearish / Ranging / Transition. Color code: `Bullish` = Lime, `Bearish` = Red, `Ranging`/`Transition` = Orange/Gold.
   - **Phase**: Trending / Pullback / Range / Transition (derived from `CStructureEngine::GetState()`).
   - **Structure**: HH / HL / LH / LL status.

3. **Structure Breaks Section**
   - **Last BOS**: Direction + Price (e.g. `"Bullish @ 1.2704"`) or `"None"` if not set.
   - **Last CHoCH**: Direction + Price (e.g. `"Bearish @ 1.2721"`) or `"None"`.

4. **Liquidity & Objectives Section**
   - **Liq Bias**: Bullish / Bearish / Balanced.
     - ⚠️ **Inferred**: If active DOL target is bullish → `"Buy Side"`. If active DOL target is bearish → `"Sell Side"`. If no active DOL target → `"Balanced"`.
   - **Active DOL**: Price and type (e.g. `"1.2850 (Session High)"`) or `"None"`.

5. **POI & Zones Section**
   - **Active POI**: Closest active POI type and boundaries (e.g. `"Bullish OB (1.2650-1.2670)"`) or `"None"`. Find the closest POI to current price using `g_poi.GetNearestBullishPOI()` and `g_poi.GetNearestBearishPOI()`.
   - **DR Zone**: Premium / Discount / Equilibrium (obtained from `g_poi.GetDealingRangeZone()`).

6. **Session & Signals Section**
   - **Session**: Active session name(s) (Asia, London, NY) or `"Closed"`. Determine using `IsInSession` and GMT time.
   - **Confirmation**: Confirmation state (None / Pending / Confirmed) + Direction (e.g. `"Confirmed (Bullish)"` or `"Pending"`).
   - **Entry**: Opportunity flag (e.g. `"Buy Triggered"` / `"Sell Triggered"` / `"None"`).

---

## NEW STYLE TOKENS TO ADD TO `MNSStyle.mqh`

Add the following fields to `SIndicatorStyle` (do NOT touch existing fields):

```mql5
// --- Dashboard Styling
color colorDashboardBg;      // Dashboard panel background (default: C'20, 20, 20')
color colorDashboardBorder;  // Dashboard border color (default: C'50, 50, 50')
color colorDashboardText;    // Default label text color (default: clrWhite)
color colorDashboardHeader;  // Header text color (default: clrLime)
color colorDashboardValue;   // Default value text color (default: clrLightGray)
string fontNameDashboard;    // Font for dashboard labels (default: "Arial")
int fontSizeDashboard;       // Font size for dashboard labels (default: 8)
int rowHeightDashboard;      // Height of each text row in px (default: 16)
int paddingDashboard;        // Padding inside the panel in px (default: 10)
```

---

## WHAT STAGE 5 MUST NOT DO

- ❌ Draw session boxes on the chart — that is Stage 7.
- ❌ Draw premium/discount zone lines or shading on the chart — that is Stage 7.
- ❌ Modify any of the 12 core engine headers.
- ❌ Modify Stage 2–4 renderer files.
- ❌ Perform any trading execution, order modification, or broker trading API calls.
- ❌ hardcode color values inside the dashboard renderer.

---

## MQL5 TECHNICAL CONSTRAINTS

- Object creation: `ObjectCreate(0, name, OBJ_LABEL, ...)` and `ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, ...)`.
- Label alignment uses `OBJPROP_ANCHOR` (`ANCHOR_RIGHT_UPPER` for right-aligned text).
- Coordinate corner is controlled by `OBJPROP_CORNER` (`CORNER_RIGHT_UPPER` by default).
- Set `OBJPROP_SELECTABLE = false` and `OBJPROP_SELECTED = false` on all panel elements so they do not interfere with chart interaction.
- Set `OBJPROP_HIDDEN = true` to prevent dashboard objects from cluttering the MT5 object list.
- Font sizes and text coordinates must be calculated cleanly to avoid text overlapping or wrapping.

---

## WORKFLOW

Follow the standard workflow from `docs/ai/PROMPT_NEW_MODULE.md`:

1. Read the required context files.
2. Produce the design document:
   - `docs/modules/013_STAGE_05_DESIGN.md` — listing dashboard layout rows, object names, anchoring math, and engine mappings.
3. Update `Include/MNS/MNSStyle.mqh` with the dashboard style tokens.
4. Generate production MQL5 for `Include/MNS/Renderers/CDashboardRenderer.mqh`.
5. Update `Indicators/MNS_Indicator.mq5` per the Deliverables section.
6. Self-review checklist:
   - [ ] No compiler warnings.
   - [ ] All objects prefixed with `"MNS_Dash_"`.
   - [ ] Pinned corner calculation respects settings.
   - [ ] Clean cleanup of all graphical labels in `Reset()`.
   - [ ] Correctly mapping core engine types to user-friendly strings.
7. Present files. Instruct user to run:
   ```powershell
   .\tools\Build-And-Archive.ps1 -Module "Module013-Stage5"
   ```
8. Update `docs/modules/013_ISSUES.md` and `roadmap.md` upon successful compilation.

---

## STAGE ROADMAP (for orientation only)

| Stage | Description | Status |
|---|---|---|
| Stage 0 | Architecture & Dependency Audit | ✅ Complete |
| Stage 1 | Indicator Shell & Lifecycle Coordinator | ✅ Complete |
| Stage 2 | Swing Point & Structure Renderers | ✅ Complete — v0.13.2 |
| Stage 3 | Liquidity Pool Renderers (BSL/SSL/EQH/EQL) | ✅ Complete — v0.13.3 |
| Stage 4 | Advanced Zone Renderers (OB/FVG/Delivery/DOL) | ✅ Complete — v0.13.4 |
| **Stage 5** | **Dashboard & Info Panel** | 🔄 **YOU ARE HERE** |
| Stage 6 | Configuration Binding (INF-004 integration) | ⬜ Pending |
| Stage 7 | Session Renderers & Premium/Discount Zones | ⬜ Pending |
| Stage 8 | Visual Performance Profiling | ⬜ Pending |
| Stage 9 | Integration Testing | ⬜ Pending |
| Stage 10 | Production Build & Release | ⬜ Pending |
