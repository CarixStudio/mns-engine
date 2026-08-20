# MNS Trading Engine — Module 013
# Stage 2: Swing Point & Structure Renderers
# AI Implementation Prompt

Version: 1.0
Status: READY — Stage 1 Complete. Begin Stage 2.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:

1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `mns-answers1.md` — Locked client decisions (38 strategy rules, formally approved).
4. `mns-answers2.md` — Final client decisions (CLIENT-Q001, CLIENT-Q002, CLIENT-Q003).
5. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
6. `Include/MNS/MNSTypes.mqh` — All shared data structures (`SSwingPoint`, `SStructureBreak`, etc.).
7. `Include/MNS/MNSUtils.mqh` — Utility functions.
8. `Include/MNS/MNSLogger.mqh` — Logging infrastructure.
9. `Include/MNS/CSwingDetector.mqh` — Module 001/002: swing data source.
10. `Include/MNS/CStructureEngine.mqh` — Module 003: market structure source.
11. `Include/MNS/CBreakDetector.mqh` — Module 004: BOS/CHoCH source.
12. `Include/MNS/COrderFlowEngine.mqh` — Module 005: order flow state.
13. `Include/MNS/CDeliveryStructureEngine.mqh` — Module 006: active delivery state.
14. `Include/MNS/CLiquidityEngine.mqh` — Module 007: liquidity pools source.
15. `Include/MNS/CPOIEngine.mqh` — Module 008: POI source.
16. `Include/MNS/CObjectiveEngine.mqh` — Module 009: DOL/objective source.
17. `Include/MNS/CConfirmationEngine.mqh` — Module 010: confirmation signals.
18. `Include/MNS/CEntryEngine.mqh` — Module 011: entry signals.
19. `Include/MNS/CRiskEngine.mqh` — Module 012: risk sizing.
20. `Indicators/MNS_Indicator.mq5` — Stage 1 shell (coordinator, DO NOT MODIFY).
21. `docs/modules/013_IndicatorIntegration.md` — Module 013 functional specification.
22. `docs/modules/013_ALGORITHM.md` — Module 013 algorithm.
23. `docs/modules/013-Indicator.md` — Module 013 stage breakdown.
24. `docs/INDICATOR_SPECIFICATION.md` — Approved visual inventory.
25. `docs/indicator/UI_UX_SPECIFICATION.md` — Approved UI/UX specification.
26. `docs/modules/013_ISSUES.md` — Open issue register (read before writing any code).
27. `docs/DEFERRED.md` — Global deferred items register.
28. `docs/CLASS_DIAGRAM.md` — Design blueprint.
29. `docs/CodingStandards.md` — Coding and style guide.
30. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.

---

## ABSOLUTE RULES (Inherited from PROMPT_NEW_MODULE.md)

1. Never invent trading logic.
2. Never substitute generic SMC/ICT algorithms.
3. Every visual element must be traceable to an engine output or locked client decision.
4. If a strategy rule is ambiguous — document it. Do NOT guess.
5. Distinguish clearly:
   - ✅ **Specified** — directly stated in strategy or locked client decision
   - ⚠️ **Inferred** — reasonable engineering inference
   - ❌ **Unknown / TODO** — not covered, do not implement
6. Write production-quality MQL5 for long-term maintenance.
7. Comment every public class and method.
8. Preserve consistency with Stage 1 (`MNS_Indicator.mq5`).
9. **Never modify `MNS_Indicator.mq5`** except to add one call per new renderer's
   `Draw()` method at the end of `OnCalculate()`.
10. Never modify core engine headers (`CSwingDetector.mqh` through `CRiskEngine.mqh`).
11. Static arrays must use `#define` or literals — never `const int`.
12. No broker API / trading calls anywhere in the indicator layer.
13. No O(N²) loops. Chart object creation is O(N) worst case per update — minimize it.

---

## STAGE 1 STATUS — COMPLETE ✅

Stage 1 (`MNS_Indicator.mq5`) is done and passing.

**Build result:**
- `MNS_TestHarness`: 320/320 PASSED — 0 errors, 0 warnings
- `MNS_Indicator.mq5`: 0 errors, 0 warnings
- `MNS_Indicator.ex5`: 67,372 bytes, produced by `Build-And-Archive.ps1`
- Runtime: All 11 engines initialized and logged on GBPUSD H1

**Stage 1 deliberately contains NO chart drawing.**
Stage 2 introduces the first visual layer.

---

## LOCKED CLIENT DECISIONS (from mns-answers1.md & mns-answers2.md)

All of the following are formally approved and must NOT be questioned or reopened:

### CLIENT-Q001 — CRT / IRL / ERL
**DECISION: OMIT as separate strategy concepts.**
- Do NOT create `CCRT_Engine`, `CIRL_Engine`, or `CERL_Engine`.
- Do NOT add new fields to `CLiquidityEngine` or `CPOIEngine` for these labels.
- Map legacy visual mock-up labels to authoritative MNS terminology:
  - "ERL High" → External Buy-Side Liquidity
  - "ERL Low" → External Sell-Side Liquidity
  - "IRL" → Internal Liquidity
  - "CRT High/Low" → Confirmed structural / liquidity high or low
- Stage 2 renderers consume existing `CSwingDetector` and `CLiquidityEngine` outputs only.

### CLIENT-Q002 — Historical Delivery / Objective Rendering
**DECISION: ACTIVE ONLY.**
- Render only the **current active delivery leg** and **current active DOL**.
- Do NOT render historical delivery legs or historical DOL targets.
- Do NOT refactor `CDeliveryStructureEngine` or `CObjectiveEngine` for history storage.
- Historical data is retained in journals/analytics only.

### CLIENT-Q003 — Core Engine Heuristics (ALL LOCKED)
| Rule | Locked Value |
|---|---|
| Session Filter | OFF by default (`UseSessionFilter = false`) |
| Liquidity buffer | 128 records per symbol/timeframe; deterministic eviction order |
| Strong Rejection | Wick ≥ 50% + close location ≥ 70% + body direction + range ≥ 0.50 ATR + POI/liquidity context |
| Delivery Mitigation | Price re-enters originating POI/delivery zone; wick = MITIGATION_STARTED, NOT invalidation |
| Delivery Invalidation | Confirmed body close beyond protected level + MinimumBreakDistance |
| Delivery Replacement | Same-direction BOS only if: confirmed body close, new structural level, new protected swing, same delivery sequence, not duplicate break |
| Delivery Archival | Confirmed opposite CHoCH only; wick CHoCH does NOT archive |
| HTF POI Score | HTF significance = 15/100; Liquidity relationship = 5/100 |
| Internal Swings | Depth = 5 each side |
| External Swings | Depth = 15 each side |
| MinimumBreakDistance | max(2 × Point, 0.10 × ATR(14)) |
| Displacement | Range ≥ 1.20 ATR; BodyRatio ≥ 65%; DirectionalCloseStrength ≥ 75% |
| EQH/EQL Tolerance | max(3 × Point, 0.10 × ATR(14)) |
| FVG Minimum Size | max(3 × Point, 0.10 × ATR(14)) |
| DOL Min Score | 60/100 |
| DOL Replacement | invalidated/consumed OR delivery changes OR new candidate score ≥ current + 15 |
| Entry TF | M5; closed candle confirmation; next market price execution |
| Signal Expiry | 5 execution bars; one signal = one execution max |
| Minimum RR | 1.50R |
| Sessions | Not mandatory trade filters; Tokyo 00-08, London 08-16, NY 13-21 GMT retained for liquidity classification only |
| News Filter | NOT defined by strategy; keep separate until formally approved |

---

## STAGE 2 OBJECTIVE

Implement the first visual rendering layer for `MNS_Indicator.mq5`.

Stage 2 draws **swing points** and **market structure breaks** on the chart using
MT5 chart objects. It does NOT draw POIs, FVGs, liquidity pools, or the dashboard.

### Deliverables

1. **`Include/MNS/Renderers/CSwingRenderer.mqh`**
   - Draws confirmed external and internal swing high/low arrows on the chart.
   - Consumes `CSwingDetector` outputs only.
   - Tracks drawn objects to avoid duplication.

2. **`Include/MNS/Renderers/CStructureRenderer.mqh`**
   - Draws BOS and CHoCH labels/lines on the chart.
   - Consumes `CBreakDetector` outputs only.
   - Tracks drawn objects to avoid duplication.

3. **`Include/MNS/MNSStyle.mqh`** *(new shared header)*
   - Centralizes all visual style tokens (colors, line styles, font sizes, arrow codes).
   - Resolves M13-ISSUE-005 (visual style centralization, deferred to Stage 3 — but
     the struct foundation must be created NOW to avoid scattering literals).
   - All renderers must consume `SIndicatorStyle` from this header, not hardcode values.

4. **Update `Indicators/MNS_Indicator.mq5`**
   - Add `#include` for both renderers.
   - Declare renderer instances as global objects.
   - Call `Initialize()` in `OnInit()` after engine initialization.
   - Call `Draw()` at the end of `OnCalculate()`.
   - Call `Reset()` in `OnDeinit()`.
   - No other modifications.

---

## STAGE 2 RENDERING RULES (from INDICATOR_SPECIFICATION.md & UI_UX_SPECIFICATION.md)

### Swing Points
- **External swing high** → up arrow above the bar, colored BULLISH_COLOR (e.g. cyan/blue tones)
- **External swing low** → down arrow below the bar, colored BEARISH_COLOR (e.g. red/orange tones)
- **Internal swing high** → smaller up arrow, distinct but muted color
- **Internal swing low** → smaller down arrow, distinct but muted color
- Arrow must be placed at the `confirmationTime` bar, NOT the `originTime` bar
- Do NOT place arrows on bar[0] (currently forming) — confirmed swings only
- Draw at most `MaxRenderedSwings` (configurable, default 50) most-recent swing objects
  to avoid cluttering long histories (addresses M13-ISSUE-006 partial mitigation)

### Structure Breaks
- **BOS** → horizontal dashed line from the broken swing high/low extending right
- **CHoCH** → horizontal dashed line, different color, extending right
- Label text placed at the right end of the line: "BOS" or "CHoCH"
- Bullish BOS / Bullish CHoCH use the BULLISH_COLOR palette
- Bearish BOS / Bearish CHoCH use the BEARISH_COLOR palette
- Draw at most `MaxRenderedBreaks` (configurable, default 20) most-recent breaks

### Object Naming Convention (CRITICAL — prevents collision)
All chart objects created by the indicator MUST use a prefixed name:
```
"MNS_" + ObjectType + "_" + UniqueID
```
Examples:
- `MNS_SwingEH_1723680000` (external high at timestamp)
- `MNS_SwingEL_1723680001` (external low)
- `MNS_SwingIH_1723680002` (internal high)
- `MNS_SwingIL_1723680003` (internal low)
- `MNS_BOS_B_1723680004` (bullish BOS)
- `MNS_BOS_Be_1723680005` (bearish BOS)
- `MNS_CHOCH_B_1723680006` (bullish CHoCH)
- `MNS_CHOCH_Be_1723680007` (bearish CHoCH)

The suffix MUST be unique per object. Use the `originTime` or `barIndex` cast to string.

### Object Lifetime
- On `OnDeinit()`, all objects with the `MNS_` prefix must be deleted using
  `ObjectsDeleteAll(0, "MNS_")`.
- On a full chart rescan (`prevCalculated == 0`), clear and redraw all objects.
- On incremental bar updates, add new objects only — do not redraw existing ones.

---

## OPEN ISSUES FOR STAGE 2 (from 013_ISSUES.md & DEFERRED.md)

The following issues WILL AFFECT Stage 2 implementation.
Read the full issue records in `docs/modules/013_ISSUES.md` and `docs/DEFERRED.md`.

### M13-ISSUE-005 — Visual Style Centralization
- **Status**: DEFERRED (partial resolution in Stage 2)
- **Action in Stage 2**: Create `MNSStyle.mqh` with `SIndicatorStyle` struct.
  Do not hardcode any RGB values in renderer files.

### M13-ISSUE-006 — Visual Object Count Capping
- **Status**: DEFERRED (partial mitigation in Stage 2)
- **Action in Stage 2**: Add `MaxRenderedSwings` (default 50) and `MaxRenderedBreaks`
  (default 20) as indicator `input` parameters and enforce them in the renderers.

### MNS-ISSUE-001 — CRT / IRL / ERL Terminology ← RESOLVED BY CLIENT
- **Status**: RESOLVED — CLIENT-Q001 = OPTION A (omit as separate concepts).
- Update `013_ISSUES.md` and `DEFERRED.md` M13-ISSUE-003 and MNS-ISSUE-001 to RESOLVED
  after Stage 2 starts, since Stage 2 is the first rendering stage where this matters.

### MNS-ISSUE-005 — SSwingPoint Monotonic ID Extension
- **Status**: DEFERRED to Phase 2.
- **Action in Stage 2**: Use `originTime` cast to string as the unique object name suffix.
  Do NOT use `barIndex` alone as an object name component (it shifts on new bars).

### MNS-ISSUE-006 — Delivery Replacement Rules ← RESOLVED BY CLIENT
- **Status**: RESOLVED — same-direction BOS with structural qualification approved.
- No action needed in Stage 2 (affects Stage 4 delivery renderer).

### MNS-ISSUE-007 — Delivery Mitigation Wick Trigger ← RESOLVED BY CLIENT
- **Status**: RESOLVED — wick entering origin zone = MITIGATION_STARTED; body close
  beyond protected level = INVALIDATED.
- No action needed in Stage 2 (affects Stage 4 delivery renderer).

### MNS-ISSUE-008 — Session GMT Hours ← RESOLVED BY CLIENT
- **Status**: RESOLVED — Tokyo 00-08, London 08-16, NY 13-21 GMT, NOT mandatory filters.
- No action needed in Stage 2 (affects Stage 5 dashboard).

### MNS-ISSUE-009 — Liquidity Buffer 128 ← RESOLVED BY CLIENT
- **Status**: RESOLVED — 128 records approved with priority eviction.
- No action needed in Stage 2 (affects CLiquidityEngine, Stage 7).

### MNS-ISSUE-010 — HTF POI Scoring Weights ← RESOLVED BY CLIENT
- **Status**: RESOLVED — HTF = 15/100, Liquidity = 5/100 approved.
- No action needed in Stage 2 (affects Stage 4 zone renderers).

### MNS-ISSUE-011 — Strong Rejection Formula ← RESOLVED BY CLIENT
- **Status**: RESOLVED — Full 5-condition formula locked.
- No action needed in Stage 2 (affects CConfirmationEngine, applied in Stage 9).

> **IMPORTANT**: After Stage 2 is complete, update `docs/DEFERRED.md` to mark the above
> CLIENT-resolved issues as RESOLVED and add the resolution commit reference.

---

## WHAT STAGE 2 MUST NOT DO

- ❌ Draw POI zones (Order Blocks, FVGs, Mitigation Blocks, Breaker Blocks)
- ❌ Draw Liquidity pool lines (BSL/SSL/EQH/EQL)
- ❌ Draw the dashboard or info panel
- ❌ Draw Delivery leg arrows or DOL target lines
- ❌ Draw session boxes or premium/discount zones
- ❌ Modify any of the 12 core engine headers
- ❌ Modify `OnCalculate()` logic in `MNS_Indicator.mq5` other than adding Draw() calls
- ❌ Add any trading execution or broker API calls
- ❌ Hardcode colors or style values inside renderer methods

---

## MQL5 TECHNICAL CONSTRAINTS

Apply these rules in every file:

- `ArraySetAsSeries()` requires **dynamic** arrays (`double arr[]`), not static (`double arr[N]`).
- `FileSize()` and `FileTell()` return `ulong` — assign to `ulong`, not `long`.
- No `const T& x = ...` local references in const methods.
- No `const T&` return types from const methods on member arrays — return by value.
- Static array sizes must use `#define` or literal integers, never `const int`.
- `ObjectCreate()` returns `bool` — always check and log on failure.
- `ChartRedraw()` should be called at most once per `OnCalculate()` call, at the end.

---

## WORKFLOW

Follow every step from `docs/ai/PROMPT_NEW_MODULE.md`:

1. Read all required context files above.
2. Produce design documentation:
   - `docs/modules/013_STAGE_02_DESIGN.md` — class diagrams, object naming, rendering pipeline.
3. Cross-check every renderer method against the locked strategy rules.
4. Generate production MQL5 for all files listed under **Deliverables**.
5. Self-review checklist:
   - [ ] No compiler warnings (check `ArraySetAsSeries` on static arrays, `ulong` types).
   - [ ] Object names always prefixed with `MNS_`.
   - [ ] No objects created for bar[0] (forming bar).
   - [ ] `MaxRenderedSwings` and `MaxRenderedBreaks` enforced.
   - [ ] `ObjectsDeleteAll(0, "MNS_")` called in `Reset()`.
   - [ ] `ChartRedraw()` called once per update, at the end.
   - [ ] All style values come from `SIndicatorStyle`, none hardcoded.
   - [ ] `MNS_Indicator.mq5` modified only to add renderer includes and calls.
   - [ ] All 12 engine headers unmodified.
6. Present files. Instruct user to run:
   ```powershell
   .\tools\Build-And-Archive.ps1 -Module "Module013-Stage2"
   ```
7. After build passes, update `docs/modules/013_ISSUES.md` Section 5 (Resolved Issues)
   for all CLIENT-resolved issues, and update `docs/DEFERRED.md`.

---

## STAGE ROADMAP (for orientation only — do not implement future stages)

| Stage | Description | Status |
|---|---|---|
| Stage 0 | Architecture & Dependency Audit | ✅ Complete |
| Stage 1 | Indicator Shell & Lifecycle Coordinator | ✅ Complete |
| **Stage 2** | **Swing Point & Structure Renderers** | 🔄 **YOU ARE HERE** |
| Stage 3 | Liquidity Pool Renderers (BSL/SSL/EQH/EQL) | ⬜ Pending |
| Stage 4 | Advanced Zone Renderers (OB/FVG/Delivery/DOL) | ⬜ Pending |
| Stage 5 | Dashboard & Info Panel | ⬜ Pending |
| Stage 6 | Configuration Binding (INF-004 integration) | ⬜ Pending |
| Stage 7 | Session Renderers & Premium/Discount Zones | ⬜ Pending |
| Stage 8 | Visual Performance Profiling | ⬜ Pending |
| Stage 9 | Integration Testing | ⬜ Pending |
| Stage 10 | Production Build & Release | ⬜ Pending |
