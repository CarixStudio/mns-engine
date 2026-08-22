# Module 013 — Issue Register

## 1. Purpose

This file is the authoritative registry for tracking all architectural blockers, client clarification questions, deferred implementation decisions, configuration inconsistencies, and design limitations identified during the development of **Module 013 — Indicator Integration**.

Every issue must have a status. The allowed statuses are:
- **BLOCKER**: Prevents the implementation of the immediate stage or later stages of Module 013.
- **CLIENT_INPUT_REQUIRED**: Requires explicit clarification from the client before implementation can proceed.
- **DEFERRED**: Intentionally postponed to a later stage or post-release module.
- **RESOLVED**: Closed with a verified technical implementation or client approval.
- **SUPERSEDED**: Replaced by a subsequent issue or design decision.

Each issue is assigned a unique identifier (`M13-ISSUE-001`, `M13-ISSUE-002`, etc.) and documented with standard fields to ensure traceability, including references to its project-level entry in [docs/DEFERRED.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/DEFERRED.md).

---

## 2. Active Module 013 Issues

**Stage 1 through 8 — COMPLETE** ✅  
- Stage 1: `MNS_Indicator.mq5` shell compiled and verified.
- Stage 2: Swing and Structure renderers completed and verified.
- Stage 3: Liquidity Pool renderers completed and verified.
- Stage 4: Advanced Zone Renderers (OB / FVG / Delivery / DOL) completed and verified.
- Stage 5: Dashboard & Info Panel completed and verified (0 errors, 0 warnings).
- Stage 6: Centralized Configuration Binding completed and verified.
- Stage 7: Session shading and Premium/Discount zones completed and verified.
- Stage 8: High-resolution Performance Profiling telemetry integrated and verified.

*There are no open active issues for Module 013.*

---


## 3. Deferred Module 013 Issues

### M13-ISSUE-001: Historical Delivery Leg & Target (DOL) Data
- **ID**: M13-ISSUE-001
- **Global Tracking ID**: [MNS-ISSUE-003](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/DEFERRED.md#mns-issue-003-historical-delivery-leg--target-dol-data-storage)
- **Status**: DEFERRED
- **Severity**: Low
- **Discovered In**: Stage 0 (Audit)
- **Affected Stage**: Stage 4 (Advanced Zone Renderers) & Stage 5 (Dashboard)
- **Source Documents**:
  - [Include/MNS/CDeliveryStructureEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CDeliveryStructureEngine.mqh)
  - [Include/MNS/CObjectiveEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CObjectiveEngine.mqh)
  - [docs/modules/006_ALGORITHM.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/006_ALGORITHM.md)
  - [docs/modules/009_ALGORITHM.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/009_ALGORITHM.md)
  - [docs/INDICATOR_SPECIFICATION.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/INDICATOR_SPECIFICATION.md)
  - [docs/indicator/UI_UX_SPECIFICATION.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/indicator/UI_UX_SPECIFICATION.md)
- **Problem**: 
  - `CDeliveryStructureEngine` maintains only a single active delivery state (`m_state`).
  - `CObjectiveEngine` maintains only the single active DOL (`m_activeDol`).
  - There are no internal arrays or history logs for previous delivery legs or objectives. When a delivery leg is replaced/archived or a target is hit, the previous data is immediately overwritten.
- **Why It Matters**: If rendering previous (historical) delivery legs or hit objective levels on the chart is required, the indicator cannot reconstruct them upon loading or switching timeframes.
- **Current Understanding**: The approved functional and UI/UX specifications ([docs/INDICATOR_SPECIFICATION.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/INDICATOR_SPECIFICATION.md) and [docs/indicator/UI_UX_SPECIFICATION.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/indicator/UI_UX_SPECIFICATION.md)) do not contain any requirements to draw delivery legs or active objectives as lines on the chart. They only specify drawing swings, structure breaks, equal highs/lows, BSL/SSL pools, OBs, FVGs, premium/discount zones, and the text dashboard. Thus, drawing historical legs or objective targets is not a committed requirement.
- **Required Decision**: Should the indicator limit rendering of delivery legs and targets to the *current active* state, or must the core engines be refactored to cache and expose historical arrays?
- **Proposed Resolution**: Classify as DEFERRED. Only render the current active delivery leg and active objective target (DOL). This fully satisfies the approved specification. If the client demands historical logs in the future, the history buffer should be added to the analysis modules (006/009), not cached inside the visualizer, preserving stateless rendering rules.
- **Implementation Impact**: None. The visualizer queries `GetState()` and `GetActiveDol()` on each update, drawing only active lines.
- **Dependencies**: Client confirmation.
- **Owner**: Technical Lead / Developer.
- **Resolution Criteria**: Acceptance of the recommendation to only render active states.

---

## 5. Resolved Issues

### M13-ISSUE-002: Risk & Spread Configuration Inconsistency
- **ID**: M13-ISSUE-002
- **Global Tracking ID**: [MNS-ISSUE-002](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/DEFERRED.md#mns-issue-002-unification-of-risk-sizing--spread-filters-in-configuration)
- **Status**: ✅ RESOLVED
- **Resolution**:
  - `desiredRiskPercent` and `maxSpreadPoints` integrated into `SEngineConfig` structure and `CMNSConfig` class.
  - Sizing and filter configurations are dynamically synchronized in `OnInit()` from MT5 indicator inputs or config files.
  - Both `CEntryEngine` and `CRiskEngine` initialize using unified parameters retrieved from `CMNSConfig::GetActive()`.
- **Resolved In**: Stage 6 — Configuration Binding
- **Commit Reference**: Module013-Stage6

---

### M13-ISSUE-004: Session Parameter Centralization
- **ID**: M13-ISSUE-004
- **Global Tracking ID**: [MNS-ISSUE-004](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/DEFERRED.md#mns-issue-004-session-parameter--gmt-offset-centralization)
- **Status**: ✅ RESOLVED
- **Resolution**:
  - `gmtOffset` added to `SEngineConfig` and `CMNSConfig` class.
  - Active time evaluations and session shifts on the dashboard and inside `CLiquidityEngine` bind to `cfg.gmtOffset` dynamically.
- **Resolved In**: Stage 6 — Configuration Binding
- **Commit Reference**: Module013-Stage6

---

### M13-ISSUE-003: Unresolved Terminology (CRT, IRL, ERL)
- **ID**: M13-ISSUE-003
- **Global Tracking ID**: [MNS-ISSUE-001](../DEFERRED.md#mns-issue-001-crt--irl--erl-terminology-mismatch)
- **Status**: ✅ RESOLVED
- **Resolution**: **CLIENT-Q001 = OPTION A** (mns-answers2.md).
  - CRT, IRL, ERL are **not implemented** as separate strategy concepts.
  - Existing Swings, Liquidity Pools, POIs, OBs, FVGs, and DOL are the authoritative visual representations.
  - No new engines or fields were added to `CLiquidityEngine` or `CPOIEngine`.
  - Stage 2 renderers consume `CSwingDetector` and `CBreakDetector` outputs only.
- **Resolved In**: Stage 2 — Swing Point & Structure Renderers
- **Commit Reference**: Module013-Stage2

---

### Historical Delivery Legs and Targets (M13-ISSUE-001 sub-question)
- **Origin Issue ID**: M13-ISSUE-001 / MNS-ISSUE-003
- **Status**: ✅ RESOLVED
- **Resolution**: **CLIENT-Q002 = OPTION A — ACTIVE ONLY** (mns-answers2.md).
  - Indicator renders only the current active delivery leg and current active DOL target.
  - Historical delivery legs are **not rendered** on the chart.
  - Historical events are retained in journals/analytics only (engine state, not visual layer).
  - No refactoring of `CDeliveryStructureEngine` or `CObjectiveEngine` required.
- **Resolved In**: Stage 2 (decision confirmed; rendering deferred to Stage 4)
- **Commit Reference**: Module013-Stage2

---

### M13-ISSUE-005: Visual Theme Style Customization
- **ID**: M13-ISSUE-005
- **Status**: ✅ RESOLVED
- **Resolution**:
  - `SIndicatorStyle` struct inside `MNSStyle.mqh` hosts all centralized visual style tokens (colors, font names, sizes, line styles, arrow codes).
  - No hardcoded RGB color codes exist inside any drawing classes; all renderers (CSwingRenderer, CStructureRenderer, CLiquidityRenderer, CPOIRenderer, CDeliveryRenderer, CDashboardRenderer, CZoneRenderer, CSessionRenderer) consume `SIndicatorStyle` exclusively.
  - Stage 7 extended this structure to support desaturated premium/discount zone colors and vertical session shading colors.
- **Resolved In**: Stage 7 — Session and Zone Renderers
- **Commit Reference**: Module013-Stage7

---

### M13-ISSUE-006: Visual Object Capping and Performance Overhead
- **ID**: M13-ISSUE-006
- **Status**: ✅ RESOLVED
- **Resolution**:
  - Centralized visual limits inputs (`InpMaxRenderedSwings`, `InpMaxRenderedBreaks`, etc.) wired into all rendering classes to automatically sweep and delete excess chart objects.
  - Confirmation time calculations optimized from O(N) linear search to O(1) direct lookup.
  - Stage 8 integrated high-resolution performance telemetry via `MNSProfiler.mqh` conditioning. Real-time microsecond profiling logs verify that engine updates (<6ms) and graphics rendering (<10ms) remain well within target budgets.
- **Resolved In**: Stage 8 — Visual Performance Profiling
- **Commit Reference**: Module013-Stage8

---

### MNS-ISSUE-006, MNS-ISSUE-007, MNS-ISSUE-008, MNS-ISSUE-009, MNS-ISSUE-010, MNS-ISSUE-011 — Core Engine Heuristics
- **Status**: ✅ RESOLVED by **CLIENT-Q003 = OPTION B** (mns-answers2.md).
- **Resolution Summary** (all locked values):

| Rule | Locked Value |
|---|---|
| Session Filter | `UseSessionFilter = false` by default |
| Liquidity buffer | 128 records; priority eviction order locked |
| Strong Rejection | 5-condition formula: wick ≥50%, close ≥70%, body direction, range ≥0.5 ATR, POI context |
| Delivery Mitigation | Wick = MITIGATION_STARTED; body close beyond protected level = INVALIDATED |
| Delivery Replacement | Same-direction BOS only with 5 strict conditions |
| Delivery Archival | Confirmed opposite CHoCH only; wick CHoCH does NOT archive |
| HTF POI Score | HTF significance = 15/100; Liquidity relationship = 5/100 |

- **Note**: These rules affect core engine behaviour (Modules 005–012). No Stage 2 code changes required. Engines already implemented with these values per prior modules.
- **Resolved In**: mns-answers2.md CLIENT-Q003
- **Commit Reference**: Module013-Stage2

