# MNS Trading Engine
# Strategy Ambiguity Log
Version: 1.0
Status: Open

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

### OPEN-001 — Right-side confirmation window size

**Source of conflict:**

Section 1 states:
> "At least 2 candles close after Candle A. Neither of those two candles
> makes a higher High."

Phase 1B states:
> "Look Left 15 candles / Look Right 15 candles"

**The conflict:**
Section 1 defines the right-side confirmation as exactly 2 candles.
Phase 1B defines both sides as 15 candles.

These are two different numbers for the same side of the same rule.
The document does not state which takes precedence, or whether
Section 1 is a simplified explanation and Phase 1B is the authoritative rule.

**Current implementation decision:**
Phase 1B was followed. Right-side window = 15 (external), 5 (internal).
This is an assumption that has not been confirmed by the client.

**Question for client:**
Is the right-side confirmation window:
- Always exactly 2 candles (as stated in Section 1)?
- Equal to the full depth on each side (15 for external, 5 for internal, as in Phase 1B)?

---

### OPEN-002 — What "15 candles" means in Section 2

**Source:**

Section 2 states:
> "Main Swing Uses: Minimum distance — 15 candles"
> "Internal Swing Uses: 5 candles"

**The ambiguity:**
"15 candles" has no directional qualifier in Section 2.
It could mean:
- 15 candles on EACH side (30 total) — symmetric window.
- 15 candles TOTAL (7 left, 8 right, or similar split).
- 15 candles on the LEFT only, with a different right-side rule.

Phase 1B adds "Look Left 15 / Look Right 15," which supports the
symmetric interpretation. However, Section 2's original phrasing
leaves the direction undefined.

**Current implementation decision:**
Symmetric. 15 each side. Follows Phase 1B phrasing.
This is an assumption.

**Question for client:**
Does "15 candles" mean 15 on each side, or 15 total?

---

### OPEN-003 — Tie-breaking rule (equal highs or lows)

**Source:**
Not mentioned anywhere in the strategy document.

**The gap:**
If two bars have exactly the same high value, the strategy does not
define whether the pivot is confirmed or rejected.

Example:
```
Candle A high = 1.2058
Candle B high = 1.2058  (adjacent)
```

Is Candle A a valid swing high?

**Current implementation decision:**
Rejected. The comparison uses strict `>=` to disqualify equal values.
This means a pivot must be strictly greater than every surrounding bar.
This is an assumption.

**Question for client:**
If a surrounding bar has a high equal to the candidate pivot high,
is the candidate confirmed or rejected?

---

### OPEN-004 — "Shift = 2" relationship to the depth window

**Source:**

Phase 1B states:
> "Always analyse Shift = 2 because Shift 0 = Live candle,
> Shift 1 = Just closed, Shift 2 = Enough confirmation."

**The ambiguity:**
"Shift = 2" means the evaluation starts at bar index 2 minimum.
With an external depth of 15, the right-side window already requires
15 bars (indices 1–15), which is more restrictive than shift 2.

It is unclear whether:
- "Shift = 2" is the only right-side confirmation required (consistent
  with OPEN-001's Section 1 reading of 2 candles), and the "15 candles"
  refers only to the left side.
- "Shift = 2" is simply a floor that is automatically satisfied by
  the larger depth requirement.

**Current implementation decision:**
Treated as a floor. Since external depth (15) > 2, the shift constraint
is always satisfied automatically. No separate "shift 2" logic was applied
beyond the depth window.

**Question for client:**
Does "Shift = 2" define the right-side confirmation window size,
or is it simply stating that the forming and just-closed candles
must be excluded from evaluation?

---

### OPEN-005 — Internal swing uses "exactly the same logic"

**Source:**

Phase 1B states:
> "Exactly same algorithm except Depth = 5 instead of [15]"

For the swing low:
> "Depth = [5]"
(The value 5 is implied from the surrounding context but the sentence
is incomplete in the document as received.)

**The gap:**
The internal swing algorithm is described as identical to the external
algorithm with only the depth changed. If OPEN-001, OPEN-002, OPEN-003,
or OPEN-004 are resolved differently for the external swing, the same
resolution must be applied to the internal swing.

No additional questions specific to internal swings — resolution of
the above items applies equally.

---

## Module 003 — CStructureEngine

---

### OPEN-006 — Minimum Break Distance Value

**Source:**
Section 754-783 (Rules 1-4).

**The ambiguity:**
Rules 1-4 state that to classify a swing high as a Higher High (HH) or a Lower High (LH), the price must exceed/fall short of the previous high by a "Minimum Break Distance". The document does not define this distance or how it is configured (e.g. static points, pips, or ATR multiple).

**Current decision:**
Implemented as a configurable class property `m_minBreakDistance` that defaults to `0.0` points (meaning any breach constitutes a break).
This is an assumption.

**Question for client:**
What is the default value or configuration method for the Minimum Break Distance (e.g. 0 points, a fixed number of pips, or an ATR ratio)?

---

### OPEN-007 — Market Phase Evaluation Logic

**Source:**
Section 859-868.

**The ambiguity:**
The document uses daily timeframe and 15-minute timeframe alignments to define "Pullback" phase. Since the engine is running on a single timeframe's supplied arrays, there is no direct mechanism to cross-reference multiple timeframes unless multiple engine instances are running in parallel.

**Current decision:**
Left as a documented TODO in `UpdateTrendAndPhase()`. The phase logic is bypassed or returns `PHASE_UNKNOWN` when multi-timeframe correlation is requested.
This is an assumption.

**Question for client:**
How should the market phase be calculated within a single-timeframe engine, or do you expect the engine to run multiple instances in parallel for MTF analysis?

---

### OPEN-008 — Structure Confidence score formula

**Source:**
Section 871-885.

**The ambiguity:**
The document lists weighting factors (e.g. HH/HL consistency 30%, Swing quality 20%) but does not specify the mathematical formula or calculations to derive the scores for each individual factor.

**Current decision:**
Returns a default confidence score of `94.0` as shown in Section 909-910, with a code TODO pointing to this item.
This is an assumption.

**Question for client:**
What are the exact formulas to calculate the score for each of the 5 confidence factors (HH/HL consistency, BOS confirmation, Swing quality, Displacement strength, and EQH/EQL noise)?


## Module 004 — CBreakDetector

---

### OPEN-009 — CHoCH applicability to non-trend swing points

**Source:**
Section 2 & Module 004 Specification.

**The ambiguity:**
The strategy implies that CHoCH (Change of Character) is a wick-only breach of the protected external swing point (the latest confirmed swing low in a bullish trend, or the latest confirmed swing high in a bearish trend). However, the document does not clarify if CHoCH should be checked or how it behaves when the trend state is transition, ranging, or unknown.

**Current decision:**
Implemented such that CHoCH is only evaluated when the trend is strictly `TREND_BULLISH` or `TREND_BEARISH`. If the trend is transitional or ranging, CHoCH detection is disabled (returns unconfirmed).
This is an assumption.

**Question for client:**
Should CHoCH only be evaluated when the trend is strictly bullish or bearish? If the trend is transitional or ranging, what constitutes the protected swing point, if any?

---

### OPEN-010 — Displacement calculation parameters

**Source:**
Module 004 Specification.

**The ambiguity:**
The strategy mentions "displacement" and "ATR multiple" to determine structure break strength but does not provide an exact mathematical definition or configuration parameters for how displacement should be calculated (e.g. body-to-body size ratio, number of expansion candles, or specific ATR ratio).

**Current decision:**
Mapped the calculated ATR multiple of the breaking candle to the `EStrength` enum (`strength` field of the break struct) to comply with the existing struct without breaking interface changes.
This is an assumption.

**Question for client:**
What is the exact formula and parameter set for displacement calculation, and does it require additional fields in the `SStructureBreak` struct?

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
