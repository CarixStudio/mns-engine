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

**Stage 1, 2, 3, 4 & 5 — COMPLETE** ✅  
- Stage 1: `MNS_Indicator.mq5` shell compiled and verified.
- Stage 2: Swing and Structure renderers completed and verified.
- Stage 3: Liquidity Pool renderers completed and verified.
- Stage 4: Advanced Zone Renderers (OB / FVG / Delivery / DOL) completed and verified.
- Stage 5: Dashboard & Info Panel completed and verified (0 errors, 0 warnings). Proceeding to Stage 6.

The following issues are open and will affect Stage 2 and later visual stages:

### M13-ISSUE-005: Visual Theme Style Customization
- **ID**: M13-ISSUE-005
- **Global Tracking ID**: None (Module-specific)
- **Status**: DEFERRED
- **Severity**: Low
- **Discovered In**: Stage 0 (Audit)
- **Affected Stage**: Stage 3 (Core Renderers) & Stage 10 (Production Build)
- **Source Documents**:
  - [docs/indicator/UI_UX_SPECIFICATION.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/indicator/UI_UX_SPECIFICATION.md)
- **Problem**: Visual style choices (colors, font sizes, line styles) are described in the spec but have not been visually approved by the client in a running build. Scattering RGB color codes across renderer files makes later adjustments difficult.
- **Why It Matters**: UI color preferences are highly subjective and frequently changed. Renderers must avoid hardcoding styles inside drawing methods.
- **Current Understanding**: MT5 chart objects support dynamic colors and styling.
- **Required Decision**: Do we hardcode colors inside renderers, or centralize them?
- **Proposed Action**: Classify as DEFERRED. Centralize all visual style tokens (colors, font names, line styles, arrow codes) into a single struct `SIndicatorStyle` inside the controller or a new helper header (e.g. `MNSStyle.mqh`), using the UI/UX spec as default settings. This allows single-point modifications when client feedback is received.
- **Dependencies**: None.
- **Owner**: UI/UX Developer.
- **Resolution Criteria**: Centralized style struct implemented in Stage 3.

---

### M13-ISSUE-006: Visual Object Capping and Performance Overhead
- **ID**: M13-ISSUE-006
- **Global Tracking ID**: None (Module-specific)
- **Status**: DEFERRED
- **Severity**: Low
- **Discovered In**: Stage 0 (Audit)
- **Affected Stage**: Stage 8 (Visual Performance Profiling)
- **Source Documents**:
  - [docs/modules/013_IndicatorIntegration.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/013_IndicatorIntegration.md)
- **Problem**: MetaTrader 5 experiences UI thread lag and memory bloating when drawing thousands of historical objects (arrows, lines, rectangles) over long history charts.
- **Why It Matters**: To maintain performance during live trading or visual testing, the indicator must avoid cluttering the chart with hundreds of old, out-of-scope swing arrows or structural break lines.
- **Current Understanding**: The engine stores up to 500 swings and 200 breaks. The visualizer only needs to show recent ones.
- **Required Decision**: What is the maximum lookback depth or count of objects we should draw?
- **Proposed Action**: Classify as DEFERRED. Implement a `MaxRenderedLines` configuration input (default 20 for breaks, 50 for swings/POIs). The Object Manager will automatically delete visual objects that fall outside this count threshold during its garbage collection sweeps.
- **Implementation Impact**: Performance lookback checks added to the Object Manager in Stage 8.
- **Dependencies**: Object Manager implementation.
- **Owner**: Technical Lead / Performance Engineer.
- **Resolution Criteria**: Visual performance validated in Strategy Tester without lag.

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
- **Status**: ✅ RESOLVED (Partial — foundation complete)
- **Resolution**: `MNSStyle.mqh` created in Stage 2 with `SIndicatorStyle` struct.
  - All visual style tokens (colors, line styles, font sizes, arrow codes) centralized in one struct.
  - No RGB literals hardcoded inside renderer methods (`CSwingRenderer.mqh`, `CStructureRenderer.mqh`).
  - All renderers consume `SIndicatorStyle` exclusively.
- **Resolved In**: Stage 2 — `Include/MNS/MNSStyle.mqh`
- **Commit Reference**: Module013-Stage2

---

### M13-ISSUE-006: Visual Object Capping and Performance Overhead
- **ID**: M13-ISSUE-006
- **Status**: ✅ RESOLVED (Partial — capping implemented; profiling deferred to Stage 8)
- **Resolution**:
  - `InpMaxRenderedSwings` (default 50) and `InpMaxRenderedBreaks` (default 20) added as indicator `input` parameters.
  - Both renderers enforce capping: objects beyond the limit are deleted automatically on each `Draw()` call.
  - `GetConfirmationTime()` optimized from O(N) linear scan to O(1) direct `barIndex` lookup.
- **Resolved In**: Stage 2 — `CSwingRenderer.mqh`, `CStructureRenderer.mqh`
- **Commit Reference**: Module013-Stage2

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

