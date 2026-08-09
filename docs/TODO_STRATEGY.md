# MNS Trading Engine
# Strategy Ambiguity Log
Version: 1.0
Status: Resolved

---

## Purpose

This file records every open question, conflict, or missing specification
in the Kenny Strategy document that currently prevents a verified,
100%-faithful implementation.

No assumption is permitted to substitute for a missing rule.
Every item here must be resolved by the client before the affected
module can be marked as complete.

---

## Module 002 — CSwingDetector

---

### OPEN-001 — Right-side confirmation window size [RESOLVED]

**Source of conflict:**
Section 1 states a 2-candle window. Phase 1B states a 15-candle window.

**Resolution:**
The right-side confirmation window must equal the configured swing depth (15 for external, 5 for internal). The Shift = 2 concept is separate and must not replace swing depth.

**Implementation Status:**
Completed. The swing detector uses symmetric windows of size `depth` on both sides.

---

### OPEN-002 — What "15 candles" means in Section 2 [RESOLVED]

**Source:**
Section 2 states: "Main Swing Uses: Minimum distance — 15 candles", "Internal Swing Uses: 5 candles".

**Resolution:**
"15 candles" means 15 candles on each side (symmetric window), not 15 total.

**Implementation Status:**
Completed. The swing detector processes 15 left + candidate + 15 right for external swings, and 5 left + candidate + 5 right for internal swings.

---

### OPEN-003 — Tie-breaking rule (equal highs or lows) [RESOLVED]

**Source:**
Ambiguity in equal pivots.

**Resolution:**
Use symbol-aware tolerance: `EqualityTolerance = max(2 * SYMBOL_POINT, 0.05 * ATR(14))`. If adjacent highs/lows are within tolerance, keep the earliest candle as the structural swing, and mark subsequent equal pivots as liquidity touches.

**Implementation Status:**
Completed. `CSwingDetector.mqh` was refactored to support passing the ATR array, calculating the dynamic `EqualityTolerance`, and applying it in the left/right window checks (rejecting equal values in the left window, but allowing them in the right window to preserve the earliest pivot).

---

### OPEN-004 — "Shift = 2" relationship to the depth window [RESOLVED]

**Source:**
Phase 1B mentions evaluating Shift = 2 because Shift 0 is live and Shift 1 is just closed.

**Resolution:**
Shift = 2 is simply a floor stating that the forming (0) and just-closed (1) candles must be excluded from evaluation. It does not define swing confirmation depth.

**Implementation Status:**
Completed. Clamping in the swing detector enforces `MNS_SWING_MIN_SHIFT = 2` as a floor.

---

### OPEN-005 — Internal swing uses "exactly the same logic" [RESOLVED]

**Source:**
Phase 1B states: "Exactly same algorithm except Depth = 5 instead of [15]"

**Resolution:**
Symmetric 5-candle depth is used for internal swings. The resolutions for OPEN-001, OPEN-002, and OPEN-004 apply equally to internal swings.

**Implementation Status:**
Completed. The swing detector implements internal swings with depth 5 symmetrically.

## Module 003 — CStructureEngine

---

### OPEN-006 — Minimum Break Distance Value [RESOLVED]

**Source:**
Section 754-783 (Rules 1-4).

**Resolution:**
The break distance is volatility-aware: `MinimumBreakDistance = max(2 * SYMBOL_POINT, 0.10 * ATR(14))`. Price must body close beyond the swing point + `MinimumBreakDistance` (bullish) or below the swing point - `MinimumBreakDistance` (bearish). Wicks alone are liquidity sweeps.

**Implementation Status:**
Completed. Modified `CStructureEngine.mqh` and `CBreakDetector.mqh` to calculate `MinimumBreakDistance` dynamically using this formula for both swing classification and external/internal BOS detection.

---

### OPEN-007 — Market Phase Evaluation Logic [RESOLVED]

**Source:**
Section 859-868.

**Resolution:**
Each timeframe receives one of: `BULLISH`, `BEARISH`, `RANGE`, `TRANSITION`, `UNKNOWN` trend phases. MTF architecture coordinates these per-timeframe states in a single context: `Single CMNSContext -> registered timeframe states -> per-timeframe analysis -> MultiTimeframeEngine -> combined narrative`.

**Implementation Status:**
Completed. In `CStructureEngine.mqh`, `UpdateTrendAndPhase()` evaluates each timeframe independently using external/internal swing sequences, and multi-timeframe correlation is designed to be coordinated at the context level.

---

### OPEN-008 — Structure Confidence score formula [RESOLVED]

**Source:**
Section 871-885 (and Section 1.7 in `kennystrategy2.md`).

**Resolution:**
The confidence score is a weighted 0-100 score based on 8 components:
- External structure direction: 25 points
- Latest confirmed BOS alignment: 20 points
- Internal structure alignment: 10 points
- Order-flow alignment: 15 points
- Displacement quality: 10 points
- MTF agreement: 10 points
- Active delivery alignment: 5 points
- DOL directional compatibility: 5 points
Each component contributes its full weight when aligned, half when neutral/partial, and zero when conflicting.

**Implementation Status:**
Completed. In `CStructureEngine.mqh`, implemented the `CalculateConfidenceScore()` method which dynamically calculates and sums these weights. Setters were added for the external parameters (Order Flow, Displacement, MTF, Delivery, DOL) to allow other engines/contexts to feed their alignment states (defaulting to neutral if unset).


## Module 004 — CBreakDetector

---

### OPEN-009 — CHoCH applicability and body-close transition logic [RESOLVED]

**Source:**
Section 2, Module 004 Specification, and Section 1.8 in `kennystrategy2.md`.

**Resolution:**
A CHoCH must only occur when a prior directional condition exists (Bullish or Bearish, or their corresponding transition states). Completely neutral ranges do not produce CHoCHs. Under the finalized rules, CHoCH is strictly confirmed by a **body close** beyond the protected swing high/low plus/minus the `MinimumBreakDistance` (meaning wicks alone do not trigger CHoCH).
- Bearish CHoCH: Close < Protected Low - `MinimumBreakDistance` (where protected low is the HL low establishing the bullish trend).
- Bullish CHoCH: Close > Protected High + `MinimumBreakDistance` (where protected high is the LH high establishing the bearish trend).

**Implementation Status:**
Completed. Refactored `CBreakDetector.mqh` to check for CHoCH confirmation via a body close beyond the protected swing point by the dynamic `MinimumBreakDistance` value. Updated the unit test harness `MNS_TestHarness.mq5` to use body-close data instead of a wick break.

---

### OPEN-010 — Displacement calculation parameters [RESOLVED]

**Source:**
Module 004 Specification (and Sections 1.9, 1.10, and 12 in `kennystrategy2.md`).

**Resolution:**
Displacement calculation follows these strict formulas:
- Range = `High - Low`
- Body = `abs(Close - Open)`
- Body/Range Ratio = `Body / Range >= 65%`
- Close Strength (Bullish): `(Close - Low) / Range >= 75%`
- Close Strength (Bearish): `(High - Close) / Range >= 75%`
- Volatility: `Range >= 1.20 * ATR(14)`
If a break meets all 3 requirements, it is a displacement break (graded as average/strong/very strong). If it fails any of them, it is a "Low Momentum Break" (weak).

**Implementation Status:**
Completed. Configured `SEngineConfig` inside `MNSConfig.mqh` to support these parameters with their default strategy values. Implemented the `CalculateBreakStrength()` method inside `CBreakDetector.mqh` to apply this dynamic logic to all BOS, internal BOS, and CHoCH events.

---

## Module 006 — CDeliveryStructureEngine

---

### OPEN-011 — Dependency on Liquidity & POI Engines [RESOLVED]

**Source of conflict:**
Section 3.1 states that the origin is a POI (Order Block/FVG) and the objective is a DOL (Draw on Liquidity). However, Module 007 (Liquidity Engine) and Module 008 (POI Engine) are built after Module 006.

**Resolution:**
The CDeliveryStructureEngine accepts an optional `htfDolPrice` parameter in its `Update()` method, and provides an `OverrideObjective(price)` setter. If no external target is provided, it automatically falls back to the price of the latest opposite confirmed external swing point from `CSwingDetector` as the objective target.

**Implementation Status:**
Completed. Implementations and unit tests utilize these parameters and fallbacks successfully.

---

### OPEN-012 — Mitigation Trigger Criteria [RESOLVED]

**Source:**
Section 3.3 includes `DELIVERY_MITIGATED` state, but does not define the exact price trigger.

**Resolution:**
A delivery leg transitions from `DELIVERY_ACTIVE` to `DELIVERY_MITIGATED` when a candle wick touches or goes past the invalidation level (the origin/protected swing price) without generating a candle body close beyond it.

**Implementation Status:**
Completed. In `CDeliveryStructureEngine.mqh`, a wick low below invalidation for bullish or wick high above invalidation for bearish triggers the transition to `DELIVERY_MITIGATED`.

### OPEN-013 — Delivery Leg Replacement vs Archival Rules

**Source:** Kenny Strategy 2 - Section 3.3

**The ambiguity:**
It is unclear how an active delivery leg is transitioned when a new delivery leg in the same direction or opposite direction is confirmed.

**Current decision:**
If a new BOS confirms a newer delivery leg in the same direction, the old leg becomes `DELIVERY_REPLACED`. If the direction reverses, the old leg becomes `DELIVERY_ARCHIVED`.

**Question for client:**
Does a new break of structure in the same direction replace the old delivery leg, and does a complete trend flip archive the previous leg?

---

### OPEN-014 — Mitigation Trigger Criteria

**Source:** Kenny Strategy 2 - Section 3.3

**The ambiguity:**
Section 3.3 lists `DELIVERY_MITIGATED` as a lifecycle state, but the exact price-action trigger is not defined.

**Current decision:**
A delivery leg transitions from `DELIVERY_ACTIVE` or `DELIVERY_OBJECTIVE_REACHED` to `DELIVERY_MITIGATED` when price retraces and a candle wick touches or goes beyond the origin swing price (or the invalidation level) without generating a candle body close past it.

**Question for client:**
Is a delivery leg considered "mitigated" the moment a candle wick touches or retraces past the origin price level (without closing past it)?

## Module 007 — CLiquidityEngine

---

### OPEN-015 — Session Boundaries Time Range and Timezone Offset

**Source:** Kenny Strategy 2 - Section 4.1 & 4.2

**The ambiguity:**
Section 4 refers to "Session highs" and "Session lows" (London, New York, Asia) as BSL/SSL sources, but the exact GMT hour boundaries and daily session boundaries are not specified.

**Current decision:**
Standard session GMT ranges are implemented: Asia (00:00 - 08:00 GMT), London (08:00 - 16:00 GMT), New York (13:00 - 21:00 GMT). These are converted to broker local time using the configured `m_gmtOffset` parameter.

**Question for client:**
Do the GMT session boundaries (Asia: 00:00-08:00, London: 08:00-16:00, NY: 13:00-21:00) align with your trading definitions?

---

### OPEN-016 — Liquidity Pool Database Size Limit (Memory Management)

**Source:** Module 007 Design / MQL5 Constraints

**The ambiguity:**
To avoid dynamic memory fragmentation in MQL5 during backtests, we propose storing pools in a fixed-size array instead of dynamic scaling.

**Current decision:**
A circular-style fixed array of 128 elements is used to store liquidity pools to guarantee O(1) allocation and maximum execution speed. When the buffer is full, the oldest inactive/broken pool is overwritten.

**Question for client:**
Is a fixed-size history of 128 active/inactive liquidity pools per chart sufficient for your analysis, or is a larger limit required?

---

## Resolution Process

When the client resolves any item above:

1. Remove the item from this file (or mark it RESOLVED with the answer).
2. Update the corresponding TODO comment in `CSwingDetector.mqh`.
3. Implement the confirmed rule.
4. Update the test harness expected values in `MNS_TestHarness.mq5`.
5. Compile and run the harness to verify the result.

---

## Items NOT in dispute

The following rules are unambiguous in the strategy document
and are already implemented exactly as written:

| Rule | Source |
|---|---|
| External depth = 15 | Section 2, Phase 1B |
| Internal depth = 5 | Section 2, Phase 1B |
| Two separate swing arrays (external + internal) | Phase 1B class design |
| Loop left, loop right, reject if higher/lower found | Phase 1B pseudocode |
| Never evaluate the forming candle | Phase 1B Update() |
| Duplicate check by datetime | Phase 1B: "Same Time? Already Exists? Ignore" |
| Swing storage is append-only (never repaint) | Section 1 Principle, Phase 1B |
| External and internal structures maintained simultaneously | Section 2, Phase 1B |

---

*This file is maintained by the development team.*
*Do not resolve items here without written confirmation from the client.*
