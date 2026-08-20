# MNS Trading Engine — Deferred Issues & Technical Debt

## 1. Purpose

This document is the project-wide register for unresolved work, technical debt, specification ambiguities, and configuration inconsistencies that have been intentionally postponed from the current implementation stages. It ensures that deferred architectural decisions and strategy gaps are recorded, tracked, and revisited at the appropriate developmental milestones rather than being lost.

---

## 2. Rules

- **No Silent Deferral**: Every deferred issue must be formally logged in this document with a unique ID before it is bypassed.
- **Traceability**: Every issue must identify its discovery origin, affected modules, and the stage/milestone where it was found.
- **Milestone Revisit**: Every issue must have a defined "Revisit Stage". An issue will transition to a BLOCKER status once its revisit stage begins if it is still unresolved.
- **Unresolved Status**: A deferred issue must not be treated as resolved or closed until verified by concrete code implementation or formal client confirmation.
- **No Guessing**: Requirements or resolutions must not be fabricated. Use "Unknown / requires confirmation" where the source code or strategy documents do not establish the answer.
- **Resolution Log**: When an issue is resolved, the resolving decision, pull request, or commit details must be recorded.
- **Cross-Reference**: Module-specific issue details should remain in their respective module registers, while the global register maintains references to their IDs.

---

## 3. Status Definitions

- **OPEN**: Discovered and active, but not yet blocking current development.
- **BLOCKER**: Prevents the execution or release of the current development stage.
- **CLIENT_INPUT_REQUIRED**: Requires explicit clarification or decisions from the client before it can be resolved.
- **DEFERRED**: Intentionally postponed to a specified future stage or post-release phase.
- **RESOLVED**: Closed with a verified technical change, test verification, or client sign-off.
- **SUPERSEDED**: Replaced or merged into another tracking record.

---

## 4. Deferred Issues Index

| ID | Issue | Status | Severity | Discovered | Revisit | Category |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **MNS-ISSUE-001** | [CRT / IRL / ERL Terminology Mismatch](#mns-issue-001-crt--irl--erl-terminology-mismatch) | ✅ RESOLVED | High | Stage 0 | Stage 4 | Specification Ambiguity |
| **MNS-ISSUE-002** | [Unification of Risk Sizing & Spread Filters](#mns-issue-002-unification-of-risk-sizing--spread-filters-in-configuration) | DEFERRED | Medium | Stage 0 | Stage 6 | Configuration Inconsistency |
| **MNS-ISSUE-003** | [Historical Delivery Leg & Target Data Storage](#mns-issue-003-historical-delivery-leg--target-dol-data-storage) | ✅ RESOLVED | Low | Stage 0 | Post-Indicator | Technical Debt / Feature |
| **MNS-ISSUE-004** | [Session Parameter & GMT Centralization](#mns-issue-004-session-parameter--gmt-offset-centralization) | DEFERRED | Low | Stage 0 | Stage 6 | Configuration Inconsistency |
| **MNS-ISSUE-005** | [SSwingPoint Monotonic ID Extension](#mns-issue-005-sswingpoint-monotonic-id-extension) | DEFERRED | Low | Module 002 | Phase 2 | Technical Debt |
| **MNS-ISSUE-006** | [Delivery Leg Replacement vs. Archival Rules](#mns-issue-006-delivery-leg-replacement-vs-archival-rules) | ✅ RESOLVED | Medium | Module 006 | Stage 4 | Specification Ambiguity |
| **MNS-ISSUE-007** | [Delivery Leg Mitigation Wick Trigger](#mns-issue-007-delivery-leg-mitigation-wick-trigger) | ✅ RESOLVED | Medium | Module 006 | Stage 4 | Specification Ambiguity |
| **MNS-ISSUE-008** | [Session GMT Hour Ranges](#mns-issue-008-session-gmt-hour-ranges) | ✅ RESOLVED | Medium | Module 007 | Stage 5 | Specification Ambiguity |
| **MNS-ISSUE-009** | [Liquidity Pool Buffer Capacity Limit](#mns-issue-009-liquidity-pool-buffer-capacity-limit) | ✅ RESOLVED | Low | Module 007 | Stage 8 | Specification Ambiguity |
| **MNS-ISSUE-010** | [Opposing HTF POI Sizing & Scoring Weights](#mns-issue-010-opposing-htf-poi-sizing--scoring-weights) | ✅ RESOLVED | Medium | Module 009 | Stage 9 | Specification Ambiguity |
| **MNS-ISSUE-011** | [Candlestick Strong Rejection Formula](#mns-issue-011-candlestick-strong-rejection-formula) | ✅ RESOLVED | Medium | Module 010 | Stage 9 | Specification Ambiguity |

> **Resolution Source**: MNS-ISSUE-001 resolved by CLIENT-Q001; MNS-ISSUE-003 resolved by CLIENT-Q002; MNS-ISSUE-006 through 011 resolved by CLIENT-Q003. All decisions locked in `mns-answers2.md`. Commit: Module013-Stage2.

---


## 5. Global Issue Records

### MNS-ISSUE-001: CRT / IRL / ERL Terminology Mismatch
- **ID**: MNS-ISSUE-001
- **Status**: CLIENT_INPUT_REQUIRED
- **Severity**: High
- **Discovered In**: Stage 0 Audit
- **Origin Module**: Module 013 (Indicator Integration)
- **Affected Module(s)**: Module 007 (Liquidity), Module 008 (POI), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Stage 4 (Advanced Zone Renderers)
- **Category**: Specification Ambiguity
- **Problem**: The visualizer instructions reference "CRT High/Low", "CRT levels", "IRL", and "ERL" rendering elements, but these terms do not exist in the strategy documents or the core engine codebases.
- **Why It Matters**: We cannot build drawing code for concepts that do not exist in the underlying analysis state models.
- **Current Understanding**: IRL/ERL typically map to Internal Range Liquidity (OB/FVG rectangles) and External Range Liquidity (swings/EQH/EQL dashed lines), which are already drawn individually. "CRT" is undefined.
- **Required Decision**: Do these terms map to existing features, or are they new strategy concepts requiring custom analytical modules?
- **Proposed Action**: Request client clarification. If they map to existing components, update status to RESOLVED and omit.
- **Dependencies**: Client input.
- **Owner**: Technical Lead / Product Owner.
- **Resolution Criteria**: Formal confirmation from the client.
- **Evidence / Source**: [013_STAGE_00_AUDIT.md:L444-446](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/013_STAGE_00_AUDIT.md#L444-L446)
- **Related Issues**: [M13-ISSUE-003](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/013_ISSUES.md#m13-issue-003-unresolved-terminology-crt-irl-erl)

---

### MNS-ISSUE-002: Unification of Risk Sizing & Spread Filters in Configuration
- **ID**: MNS-ISSUE-002
- **Status**: DEFERRED
- **Severity**: Medium
- **Discovered In**: Stage 0 Audit
- **Origin Module**: Module 012 (Risk Engine)
- **Affected Module(s)**: Module 011 (Entry), Module 012 (Risk), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Stage 6 (Configuration Binding)
- **Category**: Configuration Inconsistency
- **Problem**: User parameters like risk percentage (`desiredRiskPercent`) and spread threshold (`maxSpreadPoints`) are passed via direct methods or hardcoded, rather than unified in `SEngineConfig` / `MNSConfig.mqh`.
- **Why It Matters**: The dashboard needs to calculate and display pre-trade volume sizes. If these settings are not centralized in configuration files, the indicator and EA calculations will drift.
- **Current Understanding**: Sizing rules (minimum 1.5R, trailing step, partial closes) are strategy invariants and must remain hardcoded. User settings (risk percent, max spread) must be configurable.
- **Required Decision**: Update `SEngineConfig` to include these risk settings or handle them as standalone indicator inputs.
- **Proposed Action**: Manage them as local indicator inputs for Stages 1–5. Add them to `SEngineConfig` in `MNSConfig.mqh` during Stage 6.
- **Dependencies**: None.
- **Owner**: Technical Lead.
- **Resolution Criteria**: Unification of configuration schema.
- **Evidence / Source**: [CRiskEngine.mqh:L40-43](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CRiskEngine.mqh#L40-L43) / [MNSConfig.mqh:L25-34](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSConfig.mqh#L25-L34)
- **Related Issues**: [M13-ISSUE-002](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/013_ISSUES.md#m13-issue-002-risk--spread-configuration-inconsistency)

---

### MNS-ISSUE-003: Historical Delivery Leg & Target (DOL) Data Storage
- **ID**: MNS-ISSUE-003
- **Status**: DEFERRED
- **Severity**: Low
- **Discovered In**: Stage 0 Audit
- **Origin Module**: Module 006 (Delivery Structure Engine)
- **Affected Module(s)**: Module 006 (Delivery), Module 009 (Objectives), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Post-Indicator Release
- **Category**: Technical Debt / Feature Deferral
- **Problem**: `CDeliveryStructureEngine` and `CObjectiveEngine` only store the single current active state in memory. No history of past delivery legs or targets is retained in arrays.
- **Why It Matters**: Prevents rendering previous delivery leg paths or historical hit targets on the chart when loading or reloading the indicator.
- **Current Understanding**: The approved functional and UI specifications do not require drawing historical delivery legs or targets.
- **Required Decision**: Limit visual rendering to active states only, or update the analysis engines to store a historical leg database.
- **Proposed Action**: Render only active delivery legs and active targets.
- **Dependencies**: Client confirmation.
- **Owner**: Technical Lead / Developer.
- **Resolution Criteria**: Acceptance of the recommendation to only render active states.
- **Evidence / Source**: [CDeliveryStructureEngine.mqh:L38-41](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CDeliveryStructureEngine.mqh#L38-L41)
- **Related Issues**: [M13-ISSUE-001](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/013_ISSUES.md#m13-issue-001-historical-delivery-leg--target-dol-data)

---

### MNS-ISSUE-004: Session Parameter & GMT Offset Centralization
- **ID**: MNS-ISSUE-004
- **Status**: DEFERRED
- **Severity**: Low
- **Discovered In**: Stage 0 Audit
- **Origin Module**: Module 007 (Liquidity Engine)
- **Affected Module(s)**: Module 007 (Liquidity), Module 009 (Objectives), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Stage 6 (Configuration Binding)
- **Category**: Configuration Inconsistency
- **Problem**: Trading session hour ranges and GMT timezone offsets are hardcoded or passed as magic numbers in multiple modules.
- **Why It Matters**: To render active session highlights on the dashboard, the indicator must perform timezone conversions. If timezone parameters are not centralized, calculation drifts will occur.
- **Current Understanding**: GMT offset conversions are handled statically by `CMNSUtils`.
- **Required Decision**: Centralize session parameters in `MNSConfig` or keep them hardcoded.
- **Proposed Action**: Dashboard will calculate sessions statically in Stage 5. Add timezone offset inputs to `MNSConfig` in Stage 6.
- **Dependencies**: Centralized configuration binding.
- **Owner**: Technical Lead.
- **Resolution Criteria**: Session parameters centralized in configuration schema.
- **Evidence / Source**: [CLiquidityEngine.mqh:L446](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CLiquidityEngine.mqh#L446) / [CObjectiveEngine.mqh:L346](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CObjectiveEngine.mqh#L346)
- **Related Issues**: [M13-ISSUE-004](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/013_ISSUES.md#m13-issue-004-session-parameter-centralization)

---

### MNS-ISSUE-005: SSwingPoint Monotonic ID Extension
- **ID**: MNS-ISSUE-005
- **Status**: DEFERRED
- **Severity**: Low
- **Discovered In**: Module 002 Implementation
- **Origin Module**: Module 002 (Swing Detector)
- **Affected Module(s)**: Module 002 (Swing), Module 003 (Structure), Module 004 (Breaks)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Phase 2 Refactoring
- **Category**: Technical Debt
- **Problem**: The approved `SSwingPoint` struct does not contain an `id` field. The codebase currently uses `barIndex` as the unique swing identifier, which is dynamic and changes on new bar arrivals (wording in strategy says: "Never reuse IDs").
- **Why It Matters**: Future modules or complex EAs that store persistent references to specific swing points by ID may experience issues when `barIndex` shifts on new bars.
- **Current Understanding**: `barIndex` is stable for historical bars but shifts.
- **Required Decision**: Should we refactor `SSwingPoint` in `MNSTypes.mqh` to include a monotonic `id` field?
- **Proposed Action**: Maintain `barIndex` as the tracking key for the indicator release. Propose adding a monotonic `id` field to `SSwingPoint` in Phase 2.
- **Dependencies**: None.
- **Owner**: Core Architect.
- **Resolution Criteria**: `SSwingPoint` updated with a monotonic `id` field.
- **Evidence / Source**: [CSwingDetector.mqh:L132-140](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CSwingDetector.mqh#L132-L140)
- **Related Issues**: None.

---

### MNS-ISSUE-006: Delivery Leg Replacement vs. Archival Rules
- **ID**: MNS-ISSUE-006
- **Status**: CLIENT_INPUT_REQUIRED
- **Severity**: Medium
- **Discovered In**: Module 006 (Delivery Engine)
- **Origin Module**: Module 006 (Delivery Structure Engine)
- **Affected Module(s)**: Module 006 (Delivery), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Stage 4 (Advanced Zone Renderers)
- **Category**: Specification Ambiguity
- **Problem**: The strategy document does not specify how an active delivery leg is transitioned when a new delivery leg is confirmed.
- **Why It Matters**: Impacts the transition rules in `CDeliveryStructureEngine::Update`.
- **Current Understanding**: If a new BOS confirms a new leg in the same direction, the old leg becomes `DELIVERY_REPLACED`. If the direction reverses, the old leg becomes `DELIVERY_ARCHIVED`.
- **Required Decision**: Clarify if same-direction breaks replace old delivery legs, and if a trend flip archives them.
- **Proposed Action**: Keep the current implementation (same-direction = REPLACED, opposite-direction = ARCHIVED) and query the client.
- **Dependencies**: Client response.
- **Owner**: Technical Lead / Product Owner.
- **Resolution Criteria**: Formal sign-off from the client.
- **Evidence / Source**: [TODO_STRATEGY.md:L205-218](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TODO_STRATEGY.md#L205-L218)
- **Related Issues**: None.

---

### MNS-ISSUE-007: Delivery Leg Mitigation Wick Trigger
- **ID**: MNS-ISSUE-007
- **Status**: CLIENT_INPUT_REQUIRED
- **Severity**: Medium
- **Discovered In**: Module 006 (Delivery Engine)
- **Origin Module**: Module 006 (Delivery Structure Engine)
- **Affected Module(s)**: Module 006 (Delivery), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Stage 4 (Advanced Zone Renderers)
- **Category**: Specification Ambiguity
- **Problem**: Section 3.3 lists `DELIVERY_MITIGATED` as a lifecycle state, but the exact price-action trigger is not defined.
- **Why It Matters**: Determines the wick trigger threshold for mitigation transitions.
- **Current Understanding**: A delivery leg is marked `DELIVERY_MITIGATED` when a candle wick touches or goes past the invalidation level (protected swing price) without generating a body close beyond it.
- **Required Decision**: Confirm if a wick touch of the invalidation level triggers mitigation.
- **Proposed Action**: Maintain the wick touch rule and request client confirmation.
- **Dependencies**: Client response.
- **Owner**: Technical Lead.
- **Resolution Criteria**: Formal sign-off from the client.
- **Evidence / Source**: [TODO_STRATEGY.md:L220-232](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TODO_STRATEGY.md#L220-L232)
- **Related Issues**: None.

---

### MNS-ISSUE-008: Session GMT Hour Ranges
- **ID**: MNS-ISSUE-008
- **Status**: CLIENT_INPUT_REQUIRED
- **Severity**: Medium
- **Discovered In**: Module 007 (Liquidity Engine)
- **Origin Module**: Module 007 (Liquidity Engine)
- **Affected Module(s)**: Module 007 (Liquidity), Module 009 (Objectives), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Stage 5 (Dashboard)
- **Category**: Specification Ambiguity
- **Problem**: The strategy specifies "Session Highs/Lows" but does not define standard hourly bounds or GMT timezone alignment.
- **Why It Matters**: Essential for detecting BSL/SSL pools from sessions and dashboard session displays.
- **Current Understanding**: Standard hours are Tokyo (00:00-08:00 GMT), London (08:00-16:00 GMT), NY (13:00-21:00 GMT).
- **Required Decision**: Confirm if these standard GMT hours align with client parameters.
- **Proposed Action**: Keep standard GMT boundaries and request client verification.
- **Dependencies**: Client response.
- **Owner**: Product Owner.
- **Resolution Criteria**: Formal sign-off from the client.
- **Evidence / Source**: [TODO_STRATEGY.md:L237-249](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TODO_STRATEGY.md#L237-L249) / [TODO_STRATEGY.md:L286-298](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TODO_STRATEGY.md#L286-L298)
- **Related Issues**: None.

---

### MNS-ISSUE-009: Liquidity Pool Buffer Capacity Limit
- **ID**: MNS-ISSUE-009
- **Status**: CLIENT_INPUT_REQUIRED
- **Severity**: Low
- **Discovered In**: Module 007 (Liquidity Engine)
- **Origin Module**: Module 007 (Liquidity Engine)
- **Affected Module(s)**: Module 007 (Liquidity), Module 008 (POI), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Stage 8 (Performance Profiling)
- **Category**: Specification Ambiguity
- **Problem**: To avoid dynamic memory fragmentation in MQL5, pools are stored in a fixed-size array of 128 elements.
- **Why It Matters**: If a chart history has more than 128 active/inactive liquidity pools, the oldest pools will be overwritten.
- **Current Understanding**: 128 pools are sufficient for standard chart rendering.
- **Required Decision**: Confirm if a 128-element buffer is acceptable, or if a larger capacity limit is required.
- **Proposed Action**: Keep 128 size and request client confirmation.
- **Dependencies**: None.
- **Owner**: Core Architect.
- **Resolution Criteria**: Client confirmation or performance profile acceptance.
- **Evidence / Source**: [TODO_STRATEGY.md:L252-264](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TODO_STRATEGY.md#L252-L264)
- **Related Issues**: None.

---

### MNS-ISSUE-010: Opposing HTF POI Sizing & Scoring Weights
- **ID**: MNS-ISSUE-010
- **Status**: CLIENT_INPUT_REQUIRED
- **Severity**: Medium
- **Discovered In**: Module 009 (Objective Engine)
- **Origin Module**: Module 009 (Objective Engine)
- **Affected Module(s)**: Module 009 (Objectives), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Stage 9 (Integration Testing)
- **Category**: Specification Ambiguity
- **Problem**: Section 6.2 lists "Opposing HTF POI boundary" as a target candidate, but the selection scoring weights in Section 6.3 do not map how this candidate is scored.
- **Why It Matters**: Critical for objective target calculations.
- **Current Understanding**: Mapped its base scoring to a liquidity strength of 5 and HTF significance of 15.
- **Required Decision**: Confirm the exact scoring weights for opposing HTF POI boundary candidates.
- **Proposed Action**: Maintain the current weight mappings (strength = 5, HTF = 15) and query the client.
- **Dependencies**: Client response.
- **Owner**: Technical Lead.
- **Resolution Criteria**: Formal sign-off from the client.
- **Evidence / Source**: [TODO_STRATEGY.md:L271-283](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TODO_STRATEGY.md#L271-L283)
- **Related Issues**: None.

---

### MNS-ISSUE-011: Candlestick Strong Rejection Formula
- **ID**: MNS-ISSUE-011
- **Status**: CLIENT_INPUT_REQUIRED
- **Severity**: Medium
- **Discovered In**: Module 010 (Confirmation Engine)
- **Origin Module**: Module 010 (Confirmation Engine)
- **Affected Module(s)**: Module 010 (Confirmation), Module 013 (Indicator)
- **Current Stage**: Stage 0 (Audit)
- **Revisit Stage**: Stage 9 (Integration Testing)
- **Category**: Specification Ambiguity
- **Problem**: Section 7.5 lists "Strong Rejection" as a mandatory confirmation filter when a liquidity sweep is absent, but does not provide a mathematical formula.
- **Why It Matters**: Determines when entries are confirmed when sweeps do not occur.
- **Current Understanding**: Bulletproof wick-to-range formula is implemented: wick must be >= 50% of the total candle high-low range, and the candle must close in the upper half (bullish) or lower half (bearish).
- **Required Decision**: Verify if this mathematical definition matches the client's strategy.
- **Proposed Action**: Maintain the 50% wick-to-range rule and query the client.
- **Dependencies**: Client response.
- **Owner**: Technical Lead.
- **Resolution Criteria**: Written sign-off from the client.
- **Evidence / Source**: [TODO_STRATEGY.md:L305-318](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TODO_STRATEGY.md#L305-L318)
- **Related Issues**: None.
