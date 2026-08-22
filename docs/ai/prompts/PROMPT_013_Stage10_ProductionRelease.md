# MNS Trading Engine — Module 013
# Stage 10: Production Build & Release
# AI Implementation Prompt

Version: 1.1
Status: READY — Stage 9 Complete. Begin Stage 10.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:

1. `Indicators/MNS_Indicator.mq5` — The indicator coordinator (To be modified).
2. `CHANGELOG.md` — Project changelog (To be modified).
3. `docs/modules/013_STAGE_09_TEST_REPORT.md` — Stage 9 integration test report.
4. `roadmap.md` — Project roadmap (To be modified).

---

## ABSOLUTE RULES

1. The final release build of `MNS_Indicator.ex5` must be completely optimized for execution speed. All development profiling flags (`MNS_PROFILING_ENABLE`) must be deactivated.
2. Ensure both the indicator and the test harness compile with 0 errors and 0 warnings.
3. Update the changelog with clear, structured release entries following the "Keep a Changelog" format.

---

## STAGE 9 STATUS — COMPLETE ✅

Stage 9 (Integration Testing) is complete and verified under tag `v0.0.13-stage9`.

**Build result:**
- `MNS_Indicator.mq5` & `MNS_TestHarness.mq5`: 0 errors, 0 warnings.
- Test Suite: All 320 unit tests successfully passed (`g_testsFailed = 0`).
- Isolation: Multi-instance namespace isolation verified.
- Memory: Object capping limits (swings, breaks, sessions) successfully prevent graphic bloating or memory growth.

---

## STAGE 10 OBJECTIVES

Produce the final **Production Build & Release** for Module 013 (Indicator Integration).

### Deliverables

1. **Update `Indicators/MNS_Indicator.mq5`** — three sub-tasks:

   **a. Deactivate profiling** — Comment out the performance profiling activation define:
   ```mql5
   //--- Enable performance profiling telemetry (Deactivated for production release)
   //#define MNS_PROFILING_ENABLE
   ```

   **b. Remove stray debug `Print()` statement** — Delete the two lines below (found in the Visual Renderers section, immediately before the `MNS_ProfileStart("Render_Swings")` call). This bare `Print()` fires on **every tick** and must not be present in production:
   ```mql5
   // DELETE THESE TWO LINES:
   Print(StringFormat("[DEBUG] [MNS_Indicator] Renderers: ExtSwingCount=%d, IntSwingCount=%d, BreakCount=%d", 
                      g_swings.GetExternalSwingCount(), g_swings.GetInternalSwingCount(), numBreaks));
   ```
   Also delete the now-unused variables `numSwings` and `numBreaks` declared directly above the `Print()` call:
   ```mql5
   // DELETE THESE TWO LINES TOO:
   int numSwings = g_swings.GetExternalSwingCount() + g_swings.GetInternalSwingCount();
   int numBreaks = g_breaks.GetBreakCount();
   ```

   **c. Update the stale file header comment & version string** — The block comment at the top of the file still says *"Stage 1: Shell & Lifecycle Coordinator"* with `Status: Stage 1 — Shell Only`. Update it to reflect the production release:
   ```mql5
   // Line 4  — change to:
   //|              MNS Trading Engine — Module 013 Production Release   |
   //
   // Lines 5-26 (Stage 1 Responsibilities / Non-Responsibilities blocks)
   //   — Replace the entire Stage 1 description block with:
   //| Purpose:                                                           |
   //|   Full chart visualization coordinator for the MNS Trading Engine  |
   //|   Strategy 3 indicator integration. Orchestrates engine lifecycle,  |
   //|   update sequencing, and all visual rendering layers.              |
   //
   // Line 44-45 — change to:
   //| Version: 1.0.0                                                     |
   //| Status:  Production Release — Module 013 Complete                  |
   //
   // Line 50 — change description property to:
   #property description "MNS Trading Engine — Strategy 3 Indicator v1.0.0"
   ```

2. **Update `CHANGELOG.md`**
   - Create a release entry for version `1.0.0` detailing all indicator features, visual renderers, configurations, and dashboards added during Module 013 development.

3. **Update `roadmap.md`**
   - Mark **Stage 10: Production Build & Release** as **✅ Complete**.
   - Mark the overall **Module 013** progress status as **✅ Complete**.

4. **Run Final Release Build Script**
   - Execute the final release build/archive script:
     ```powershell
     .\tools\Build-And-Archive.ps1 -Module "Module013_Release"
     ```

---

## CHANGELOG ENTRY SPECIFICATION (`CHANGELOG.md`)

Add the following entry under `CHANGELOG.md` right after the `## [Unreleased]` section header:

```markdown
## [1.0.0] - 2026-08-22

### Added
- **Module 013 (Indicator Integration) Complete**: Full chart visualization layer of the MNS Trading Engine.
- **Renderer Framework**: Individual renderers for Swings, Structure Breaks, Liquidity Pools, POIs (Order Blocks & Fair Value Gaps), Active Delivery Leg, and active Take Profit target (Draw on Liquidity).
- **Session Shading bands**: Colored non-overlapping vertical columns for Asia, London, NY, and London/NY overlap hours.
- **Premium/Discount Zones**: Desaturated horizontal range fills divided by the Equilibrium midpoint line.
- **Floating Status Dashboard**: 16-row expandable/collapsible HUD showing real-time trends, broken levels, target DOL, active POI, session, confirmation status, entry signals, entry price, and stop loss.
- **Configuration Engine Binding**: Dynamic config profile loading from custom `.ini` files synced with standard MT5 user inputs.
- **Visual Performance Telemetry**: Compile-time strippable performance monitoring macros wrapping all calculation and rendering loops.

### Fixed
- Resolved `MNS-ISSUE-002` / `M13-ISSUE-002` (Risk and spread parameters centralization).
- Resolved `MNS-ISSUE-004` / `M13-ISSUE-004` (Session GMT Offset centralization).
- Resolved `M13-ISSUE-005` (Visual theme customization).
- Resolved `M13-ISSUE-006` (Visual object capping and performance timing validation).
```

---

## SELF-REVIEW CHECKLIST

- [ ] `MNS_Indicator.mq5` compiles with 0 errors and 0 warnings with profiling deactivated.
- [ ] `MNS_TestHarness.mq5` compiles with 0 errors and 0 warnings (macros strip cleanly).
- [ ] The bare `Print(StringFormat("[DEBUG]..."))` statement and its two associated variable declarations (`numSwings`, `numBreaks`) are removed from `MNS_Indicator.mq5`.
- [ ] The file header comment in `MNS_Indicator.mq5` no longer says "Stage 1" — it reflects the v1.0.0 production release description.
- [ ] `CHANGELOG.md` is updated and clean.
- [ ] `roadmap.md` is updated showing all stages of Module 013 complete.

---

## NEXT STEP INSTRUCTIONS

After code implementation:
1. Run `Build-And-Archive.ps1`:
   ```powershell
   .\tools\Build-And-Archive.ps1 -Module "Module013_Release"
   ```
2. Commit all changes and tag the production release:
   ```bash
   git add .
   git commit -m "release(indicator): publish production build v1.0.0"
   git tag -a v1.0.0 -m "MNS Indicator v1.0.0 Production Release"
   ```
