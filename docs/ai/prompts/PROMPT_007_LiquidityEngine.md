## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
4. `Include/MNS/MNSTypes.mqh` — Shared Data Structures.
5. `Include/MNS/CSwingDetector.mqh` (and any other previous dependencies).
6. `docs/modules/007_LiquidityEngine.md` — This module's Specification.
7. `docs/modules/007_ALGORITHM.md` — This module's Algorithm.
8. `docs/modules/007_API.md` — This module's Class API.
9. `docs/CLASS_DIAGRAM.md` — Design Blueprint.
10. `docs/CodingStandards.md` — Coding and style guide.
11. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.
12. `docs/Roadmap.md` — Project roadmap.
13. `docs/infrastructure/INF_ROADMAP.md` — Infrastructure roadmap.

---

## IMPLEMENTATION INSTRUCTIONS

Please write the complete code for `Include/MNS/CLiquidityEngine.mqh` adhering strictly to the algorithm specified in `docs/modules/007_ALGORITHM.md`.

Ensure:
1. Use a fixed-size array of 128 elements for pool storage to prevent dynamic memory allocation fragmentation in MQL5.
2. Implement robust date-boundary checking on the input `time[]` array to identify Daily (PDH/PDL) and Weekly (PWH/PWL) transitions deterministically.
3. Incorporate session scanning NYPD London and Asia sessions using GMT-offset hour checks.
4. Correctly classify candle wick sweeps (close back below/above) vs. body breakouts (close beyond the level + break distance).
5. Implement the ranking score formula (0 to 100) exactly as specified.
6. Return by value for const struct/getter methods, and avoid local variables as const references.
7. Comment every public class and method in detail.
