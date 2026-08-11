## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
4. `Include/MNS/MNSTypes.mqh` — Shared Data Structures.
5. `Include/MNS/CSwingDetector.mqh` (and any other previous dependencies).
6. `docs/modules/010_ConfirmationEngine.md` — This module's Specification.
7. `docs/modules/010_ALGORITHM.md` — This module's Algorithm.
8. `docs/modules/010_API.md` — This module's Class API.
9. `docs/CLASS_DIAGRAM.md` — Design Blueprint.
10. `docs/CodingStandards.md` — Coding and style guide.
11. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.
12. `docs/Roadmap.md` — Project roadmap.
13. `docs/infrastructure/INF_ROADMAP.md` — Infrastructure roadmap.

---

## IMPLEMENTATION INSTRUCTIONS

Please write the complete code for `Include/MNS/CConfirmationEngine.mqh` implementing the Confirmation Engine class `CConfirmationEngine` according to the API defined in `docs/modules/010_API.md` and the algorithm rules defined in `docs/modules/010_ALGORITHM.md`.

### Mandatory Rules for the MQL5 Compiler:
1. **No local references in const methods**: MQL5 does not support local reference variables (e.g. `const SPoIDefinition& poi = ...` or `SPoIDefinition& x = ...`) in `const` class methods. Always declare them as values or copy them directly.
2. **Const struct returns by value**: Do not return structures by reference from const methods; always return by value.
3. **Array sizes**: Use `#define` or literals for array sizes, never `const int`.
4. **Clean includes**: Include `MNSCore.mqh`, `MNSTypes.mqh`, and previous engine files correctly.
5. **No trading or chart operations**: Keep the logic purely mathematical and analysis-driven.

### Core Methods to Implement:
1. **Initialize()**: Set defaults, thresholds (`m_minConfidence = 60.0`, `m_minDisplacementRatio = 1.5`), and initialize the state.
2. **Update(...)**:
   - Perform invalidation checks on existing `PENDING`/`CONFIRMED` states (POI invalidation, body close past invalidation level, DOL invalidation/direction shift, signal expiration after 5 bars).
   - If state is `NONE`, scan active POIs in `CPOIEngine` to see if one has been touched. If so, transition to `PENDING` and save the touch time.
   - If state is `PENDING`, verify checklist: MTF trend agreement, delivery direction alignment, liquidity sweep or candlestick rejection, and structural break trigger (CHoCH or BOS) on or after the POI touch time.
   - If all are satisfied, transition to `CONFIRMED`, set trigger price/time, and calculate the confidence score.
3. **CalculateConfidence(...)**: Compute the quality score from 60 to 100 based on confluence, premium/discount (use `EDealingRangeZone` zone check if delivery range exists), session alignment, and displacement size relative to ATR.
