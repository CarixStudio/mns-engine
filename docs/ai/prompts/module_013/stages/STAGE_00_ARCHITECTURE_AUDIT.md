# MODULE 013 — STAGE 0
# ARCHITECTURE, DEPENDENCY & CONFIGURATION AUDIT
# MNS Trading Engine — Indicator Integration

You are working inside the existing MNS Trading Engine MQL5 repository.

Module 001 through Module 012 are already implemented and validated.

Your task in this stage is NOT to implement the indicator UI.

This is STAGE 0 ONLY.

The purpose of Stage 0 is to perform a complete architecture and integration audit before any Module 013 production code is written.

============================================================
PRIMARY OBJECTIVE
============================================================

Prepare the repository for Module 013 — Indicator Integration.

Module 013 will eventually expose the already-built trading engine through an MT5 indicator.

The indicator is a PRESENTATION / OBSERVATION / CONFIGURATION INTERFACE.

It must NOT become a second trading engine.

The existing analysis modules remain the source of truth.

The indicator must consume their outputs and visualize them.

The EA must later consume the same engine outputs independently.

Do NOT duplicate analysis logic inside Module 013.

Do NOT modify trading logic in Modules 001–012 during this stage.

Do NOT create chart objects yet.

Do NOT create the dashboard yet.

Do NOT create the final indicator yet.

============================================================
REPOSITORY CONTEXT
============================================================

The repository currently contains:

Include/MNS/
    MNSTypes.mqh
    MNSCore.mqh
    MNSLogger.mqh
    MNSProfiler.mqh
    MNSSerializer.mqh
    MNSTestSuite.mqh
    MNSUtils.mqh
    MNSVolatility.mqh
    MNSConfig.mqh

    CSwingDetector.mqh
    CStructureEngine.mqh
    CBreakDetector.mqh
    COrderFlowEngine.mqh
    CDeliveryStructureEngine.mqh
    CLiquidityEngine.mqh
    CPOIEngine.mqh
    CObjectiveEngine.mqh
    CConfirmationEngine.mqh
    CEntryEngine.mqh
    CRiskEngine.mqh

Experts/
    MNS_TestHarness/
        MNS_TestHarness.mq5

docs/modules/
    013_ALGORITHM.md
    013_IndicatorIntegration.md
    013-Indicator.md
    014-EA.md

docs/indicator/
    UI_UX_SPECIFICATION.md

docs/infrastructure/
    specs/
    INF_ARCHITECTURE.md
    INF_PRD.md
    INF_ROADMAP.md

docs/
    Architecture.md
    ENGINE_ARCHITECTURE_V2.md
    INDICATOR_SPECIFICATION.md
    TechnicalDesign.md
    CLASS_DIAGRAM.md
    CodingStandards.md
    DevelopmentWorkflow.md
    TestingStrategy.md
    TODO_STRATEGY.md

============================================================
AUTHORITATIVE DOCUMENTS
============================================================

Before making any changes, inspect and understand:

1. docs/modules/013_ALGORITHM.md
2. docs/modules/013_IndicatorIntegration.md
3. docs/modules/013-Indicator.md
4. docs/indicator/UI_UX_SPECIFICATION.md
5. docs/INDICATOR_SPECIFICATION.md
6. docs/Architecture.md
7. docs/ENGINE_ARCHITECTURE_V2.md
8. docs/TechnicalDesign.md
9. docs/CLASS_DIAGRAM.md
10. docs/CodingStandards.md
11. docs/TestingStrategy.md
12. docs/TODO_STRATEGY.md
13. docs/infrastructure/specs/INF_004_Configuration.md
14. docs/infrastructure/INF_ARCHITECTURE.md
15. docs/infrastructure/INF_ROADMAP.md

Also inspect the actual source code of:

- MNSConfig.mqh
- MNSTypes.mqh
- CSwingDetector.mqh
- CStructureEngine.mqh
- CBreakDetector.mqh
- COrderFlowEngine.mqh
- CDeliveryStructureEngine.mqh
- CLiquidityEngine.mqh
- CPOIEngine.mqh
- CObjectiveEngine.mqh
- CConfirmationEngine.mqh
- CEntryEngine.mqh
- CRiskEngine.mqh

Do not rely only on documentation.

The actual implementation is authoritative when documentation and implementation differ.

============================================================
STAGE 0 TASK 1 — COMPLETE MODULE 013 DEPENDENCY MAP
============================================================

Determine exactly which existing modules Module 013 must consume.

Build a dependency map such as:

Module 013
    ↓
Configuration
    ↓
Trading Engine
    ↓
Module 001
Module 002
Module 003
...
Module 012

For every dependency, document:

- What data Module 013 needs
- Which class provides it
- Which method/API provides it
- Whether the data is current-state or historical
- Whether the data is mutable
- Whether Module 013 should copy, reference, or query it
- Whether the data is safe to expose visually

Do NOT invent APIs.

If an API does not exist, mark it as:

MISSING API

Do not implement it during Stage 0 unless absolutely required for the audit.

============================================================
STAGE 0 TASK 2 — DETERMINE THE INDICATOR ENTRY ARCHITECTURE
============================================================

Design the intended Module 013 entry point.

Determine whether the final indicator should use:

- OnInit()
- OnDeinit()
- OnCalculate()
- OnTimer()
- OnChartEvent()

or a controlled combination.

Explain exactly what each event will be responsible for.

Example conceptual separation:

OnInit()
    initialize engine
    initialize configuration
    initialize rendering infrastructure
    initialize dashboard

OnCalculate()
    update market data
    update engine state
    detect new analysis events
    request visual refresh

OnTimer()
    perform controlled UI refresh / dashboard refresh if required

OnChartEvent()
    process user interaction only

OnDeinit()
    cleanly remove Module 013 objects
    release resources

Do not implement this yet.

Document the final recommendation.

============================================================
STAGE 0 TASK 3 — IDENTIFY EVERY VISUAL OUTPUT
============================================================

Create a complete inventory of everything the indicator is expected to display.

At minimum investigate:

MARKET STRUCTURE
- Swing High
- Swing Low
- HH
- HL
- LH
- LL
- Strong High
- Strong Low
- Weak High
- Weak Low

BREAKS
- BOS
- Internal BOS / iBOS
- CHoCH

ORDER FLOW
- Bullish
- Bearish
- Neutral / undefined if supported

DELIVERY
- Active delivery
- Delivery origin
- Delivery objective
- Delivery state
- Completed delivery
- Replaced delivery
- Archived delivery
- Mitigated delivery

LIQUIDITY / DOL
- BSL
- SSL
- CRT High / Low
- Previous Day High / Low
- Previous Week High / Low
- Range High / Low
- IRL
- ERL
- Active DOL
- Short-term DOL
- Long-term DOL

POI
- FVG
- IFVG
- Order Block
- Breaker Block if implemented
- CRT levels
- Premium
- Discount
- Key levels

OBJECTIVE
- Objective target
- Objective status
- Objective reached / active / invalidated where supported

CONFIRMATION
- Confirmation status
- Confirmation reason
- Rejection / invalidation reason where available

ENTRY
- Entry readiness
- Entry zone
- Direction
- Entry price
- Stop Loss
- Take Profit
- R:R
- Readiness score

RISK
- Risk percentage
- Risk amount
- Position size
- SL distance
- TP distance

DASHBOARD
- Current symbol
- Current timeframe
- Market bias
- Order flow
- Delivery
- DOL
- POI
- Confirmation
- Entry readiness
- Risk
- Engine status
- Debug status

For every visual item determine:

SOURCE MODULE
DATA TYPE
SOURCE API
VISUAL TYPE
UPDATE FREQUENCY
LIFETIME
CAN REPAINT?
CAN BE DELETED?
CAN BE HIDDEN?
DEPENDS ON CONFIGURATION?

============================================================
STAGE 0 TASK 4 — CRITICAL CONFIGURATION AUDIT
============================================================

This is extremely important.

Inspect ALL Modules 001–012 and identify every value that is currently:

- hardcoded
- compile-time constant
- static constant
- default configuration
- magic number
- threshold
- lookback
- scoring weight
- session boundary
- capacity limit
- ATR multiplier
- tolerance
- confidence threshold
- rejection threshold
- risk parameter
- liquidity parameter
- POI parameter
- objective weight
- confirmation threshold
- entry threshold

The goal is NOT to make everything configurable.

The goal is to determine which parameters are legitimate USER SETTINGS.

For every candidate parameter classify it as:

A — MUST remain internal / immutable

B — CONFIGURABLE through MNSConfig but NOT dashboard-editable

C — CONFIGURABLE through MNSConfig AND potentially dashboard-editable

D — CURRENTLY HARDCODED BUT SHOULD PROBABLY BECOME CONFIGURABLE

E — STRATEGY RULE and MUST NOT be user-editable

F — DISPLAY-ONLY setting

G — DEBUG/DEVELOPER setting

This classification is critical.

Do NOT blindly expose strategy rules to the user.

For example:

A swing algorithm's mathematical invariant may need to remain fixed.

A swing depth may be configurable.

A dashboard visibility toggle should obviously be configurable.

A strategy rule defining what constitutes a valid BOS should NOT casually become a dashboard slider.

============================================================
STAGE 0 TASK 5 — BUILD THE CONFIGURATION EXPOSURE MATRIX
============================================================

Create a table with:

Parameter
Current Location
Current Value
Current Type
Module
Purpose
Strategy-Critical?
User Configurable?
Dashboard Editable?
Allowed Range
Default
Requires Engine Recalculation?
Requires Chart Redraw Only?
Notes

Example:

externalDepth
MNSConfig
15
int
Structure
Swing depth
YES
YES
POSSIBLY
[...]
15
YES
YES

Do this for ALL meaningful configuration parameters discovered.

Pay special attention to parameters that are currently hardcoded in:

- Module 002
- Module 003
- Module 004
- Module 005
- Module 006
- Module 007
- Module 008
- Module 009
- Module 010
- Module 011
- Module 012

Also inspect INF-002, INF-003 and INF-004.

============================================================
STAGE 0 TASK 6 — CONFIGURATION ARCHITECTURE DECISION
============================================================

Determine how dashboard-editable settings should flow.

The intended architecture should be conceptually similar to:

USER
 ↓
DASHBOARD CONTROL
 ↓
MNSConfig
 ↓
VALIDATION
 ↓
ENGINE
 ↓
NEW ANALYSIS STATE
 ↓
INDICATOR RENDERER

NOT:

USER
 ↓
DASHBOARD
 ↓
DIRECTLY MODIFY MODULE INTERNAL STATE

Module 013 must not bypass MNSConfig.

Use the existing configuration validation architecture wherever possible.

MNSConfig already supports parameter updates and validation.

Verify its current capabilities before proposing changes.

Document any missing functionality.

============================================================
STAGE 0 TASK 7 — DISTINGUISH THREE TYPES OF USER SETTINGS
============================================================

Explicitly separate:

1. ANALYSIS SETTINGS

These can alter how the engine interprets market data.

Examples may include:
- swing depth
- ATR tolerance
- minimum break distance
- confidence thresholds
- session parameters

These may require engine recalculation.

2. VISUAL SETTINGS

These only control presentation.

Examples:
- show/hide BOS
- show/hide FVG
- show/hide liquidity
- show/hide delivery
- label visibility
- dashboard visibility
- object density

These should NOT alter trading logic.

3. SYSTEM / DEBUG SETTINGS

Examples:
- logging
- debug mode
- profiler
- diagnostic overlays

These should generally be separated from normal trader-facing settings.

============================================================
STAGE 0 TASK 8 — DETERMINE REINITIALIZATION REQUIREMENTS
============================================================

For every potentially editable analysis parameter determine:

Does changing this parameter require:

A. visual redraw only?

B. partial recalculation?

C. complete engine reset and historical recalculation?

D. indicator reinitialization?

This is critical.

For example:

Changing:

SHOW_FVG = false

should only require a rendering update.

Changing:

SWING_DEPTH = 2 → 5

may invalidate previously detected swings and therefore require historical engine recalculation.

Do NOT implement dynamic settings until these consequences are understood.

============================================================
STAGE 0 TASK 9 — OBJECT OWNERSHIP MODEL
============================================================

Define ownership rules for chart objects.

Module 013 must own all visual objects it creates.

No trading engine module should directly create chart objects.

Define:

- unique object prefix
- naming convention
- ownership
- creation
- update
- reuse
- deletion
- cleanup
- collision prevention

The future Object Manager must prevent stale objects from previous calculations from remaining on the chart.

============================================================
STAGE 0 TASK 10 — REPAINTING / HISTORICAL BEHAVIOUR
============================================================

Determine which engine outputs are:

CONFIRMED
UNCONFIRMED
PROVISIONAL
INVALIDATED
HISTORICAL

The indicator must not visually rewrite confirmed historical events unless the underlying strategy explicitly permits it.

Identify every module output that may change after new candles arrive.

Document the rendering policy for each.

This is especially important for:

- swings
- BOS
- CHoCH
- delivery
- liquidity
- POIs
- objectives
- confirmations
- entry readiness

============================================================
STAGE 0 TASK 11 — PERFORMANCE AUDIT
============================================================

Determine the likely performance risks of Module 013.

Inspect:

- number of chart objects
- historical rendering
- object creation/destruction
- repeated ObjectFind()
- repeated ObjectCreate()
- full-chart redraws
- multi-timeframe data
- recalculation frequency
- dashboard refresh frequency

Recommend where caching, object reuse, dirty flags, throttling, or incremental updates will be required.

Do not implement optimizations yet.

Document them.

============================================================
STAGE 0 TASK 12 — CLIENT REVIEW COMPATIBILITY
============================================================

The client may not have a laptop.

Therefore Module 013 must eventually be capable of being demonstrated through an MT5 environment running on a Windows machine/VPS.

Stage 0 must identify what will be required for client review:

- compiled EX5 indicator
- installation instructions
- chart setup
- symbol/timeframe selection
- historical visual review
- screenshots/video
- remote VPS access if required

However:

DO NOT build the client delivery system now.

Only document the requirements.

============================================================
STAGE 0 TASK 13 — DEFINE TEST STRATEGY FOR MODULE 013
============================================================

Module 013 must eventually be tested at three levels:

1. UNIT / COMPONENT TESTING

Verify:
- object manager
- renderer
- dashboard
- event handling
- configuration binding

2. HISTORICAL VISUAL VALIDATION

Use MT5 Strategy Tester Visual Mode / historical charts.

Compare:

ENGINE DATA
        ↓
INDICATOR VISUALIZATION
        ↓
MANUALLY EXPECTED RESULT

The client strategy specifically requires historical visual validation against manually marked charts.

3. LIVE / FORWARD VALIDATION

Run the indicator on live/demo market data and verify that confirmed events appear correctly.

Do not implement the tests yet.

Define them.

============================================================
STAGE 0 TASK 14 — DETERMINE MISSING APIs
============================================================

Identify every place where Module 013 needs information that the existing modules currently do not expose.

For example:

If the renderer needs:

GetActiveDelivery()

but CDeliveryStructureEngine does not expose it,

mark:

MISSING API:
CDeliveryStructureEngine::GetActiveDelivery()

Do NOT silently modify the engine.

Produce a list:

MISSING API
WHY REQUIRED
SOURCE MODULE
PROPOSED API
DATA TYPE
IMPACT
SAFE TO ADD?

============================================================
STAGE 0 TASK 15 — PRODUCE THE MODULE 013 IMPLEMENTATION PLAN
============================================================

At the end of the audit, create a concrete implementation sequence.

The plan should be approximately:

Stage 0
Architecture / dependency / configuration audit

Stage 1
Indicator shell + engine lifecycle

Stage 2
Object Manager

Stage 3
Core renderers

Stage 4
Advanced market-structure / delivery / liquidity / POI renderers

Stage 5
Dashboard

Stage 6
Configuration binding + dynamic settings

Stage 7
Chart event handling / interaction

Stage 8
Historical rendering and performance validation

Stage 9
Module 013 integration testing

Stage 10
Compiled indicator build + internal QA

You may modify this sequence if the audit reveals a better architecture.

Do NOT begin the next stage.

============================================================
REQUIRED FILE CHANGES
============================================================

Create the following directory:

docs/ai/prompts/module_013/stages/

Create this file:

docs/ai/prompts/module_013/stages/STAGE_00_ARCHITECTURE_AUDIT.md

Put this entire Stage 0 prompt into that file.

Also create:

docs/modules/013_STAGE_00_AUDIT.md

This file must contain the results of the actual audit.

Do NOT overwrite:

docs/modules/013_ALGORITHM.md
docs/modules/013_IndicatorIntegration.md
docs/modules/013-Indicator.md

unless absolutely necessary.

============================================================
STRICT RULES
============================================================

1. DO NOT write production Module 013 code.

2. DO NOT create the final indicator.

3. DO NOT create dashboard objects.

4. DO NOT modify Modules 001–012 merely to make the audit easier.

5. DO NOT invent missing APIs as though they already exist.

6. DO NOT invent strategy rules.

7. DO NOT convert every hardcoded value into a user setting.

8. DO NOT expose strategy-critical rules to dashboard controls without justification.

9. DO NOT bypass MNSConfig.

10. DO NOT place trading logic inside the indicator.

11. DO NOT allow visual state to control engine decisions.

12. Prefer existing architecture over introducing unnecessary new abstractions.

13. If documentation conflicts with implementation, report the conflict.

14. If strategy rules are ambiguous, report them as OPEN QUESTIONS rather than guessing.

15. Do not proceed to Stage 1.

============================================================
FINAL OUTPUT REQUIRED
============================================================

At the end, report:

A. Files inspected

B. Existing Module 013 architecture

C. Dependency graph

D. Required engine APIs

E. Missing APIs

F. Visual output inventory

G. Configuration exposure matrix

H. Hardcoded-variable audit

I. Parameters that should NOT be user-editable

J. Parameters that SHOULD be user-editable

K. Parameters that should be dashboard-editable

L. Parameters requiring engine recalculation

M. Parameters requiring visual redraw only

N. Object ownership architecture

O. Repainting policy

P. Performance risks

Q. Testing strategy

R. Client review requirements

S. Proposed Module 013 stage sequence

T. Open architectural questions

U. Files created/modified

Before finishing, verify that no production Module 013 implementation has been created.

Stage 0 is complete only when the architecture and configuration boundaries are clearly understood.
