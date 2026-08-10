## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
4. `Include/MNS/MNSTypes.mqh` — Shared Data Structures.
5. `Include/MNS/CSwingDetector.mqh` (and any other previous dependencies).
6. `docs/modules/009_ObjectiveEngine.md` — This module's Specification.
7. `docs/modules/009_ALGORITHM.md` — This module's Algorithm.
8. `docs/modules/009_API.md` — This module's Class API.
9. `docs/CLASS_DIAGRAM.md` — Design Blueprint.
10. `docs/CodingStandards.md` — Coding and style guide.
11. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.
12. `docs/Roadmap.md` — Project roadmap.
13. `docs/infrastructure/INF_ROADMAP.md` — Infrastructure roadmap.

---

## IMPLEMENTATION INSTRUCTIONS

Please write the complete code for `Include/MNS/CObjectiveEngine.mqh` implementing the Objective Engine class `CObjectiveEngine` according to the API defined in `docs/modules/009_API.md` and the scoring and replacement logic rules defined in `docs/modules/009_ALGORITHM.md`.

Additionally, you must modify `Include/MNS/MNSTypes.mqh` to append the required DOL types and definitions at the end of the file, right before the `#endif` guard:

```mql5
//-------------------------------------------------------------------
/// @brief Represents the specific type of Draw on Liquidity (DOL).
//-------------------------------------------------------------------
enum EDolType
{
    DOL_NONE              = 0,  ///< No DOL assigned.
    DOL_EXTERNAL_SWING    = 1,  ///< External Swing High/Low.
    DOL_EQH_EQL           = 2,  ///< Equal Highs/Lows pool.
    DOL_PREV_DAY_HL       = 3,  ///< Previous Day High/Low.
    DOL_PREV_WEEK_HL      = 4,  ///< Previous Week High/Low.
    DOL_SESSION_HL        = 5,  ///< Session High/Low.
    DOL_UNMITIGATED_EXT   = 6,  ///< Unmitigated swing extreme.
    DOL_FVG_MIDPOINT      = 7,  ///< Fair Value Gap midpoint.
    DOL_OB_MIDPOINT       = 8,  ///< Order Block midpoint.
    DOL_EQUILIBRIUM       = 9   ///< Dealing range equilibrium.
};

//-------------------------------------------------------------------
/// @brief Holds details of a tracked Draw on Liquidity (DOL) objective.
//-------------------------------------------------------------------
struct SDolDefinition
{
    double      price;              ///< Price level of the target.
    EDolType    type;               ///< Specific DOL type.
    double      score;              ///< Selection score (0-100).
    datetime    createdTime;        ///< Target creation time.
    bool        active;             ///< Active flag.
    
    /// @brief Resets structure to safe defaults.
    void Reset()
    {
        price       = 0.0;
        type        = DOL_NONE;
        score       = 0.0;
        createdTime = 0;
        active      = false;
    }
};
```

Ensure:
1. **O(1) Memory Footprint**: Candidates are evaluated in a fixed-size buffer `m_candidates[64]` to prevent dynamic allocation memory fragmentation in MQL5.
2. **Deterministic Scanning**: Implement local boundary scans on the passed `time[]`, `high[]`, `low[]` arrays to extract PDH/PDL, PWH/PWL, and session boundaries (assumed London 8-16, NY 13-21, Tokyo 0-8) without broker API queries.
3. **ATR Feasibility**: Distance feasibility scoring checks if the price target is too close or far relative to `currentAtr` (ideal distance is 1.0x to 5.0x ATR).
4. **Hysteresis rule**: Implement the `ReplacementScoreAdvantage = 15` rule so that a valid active DOL is only replaced if a candidate outscores it by at least 15 points AND has higher structural or liquidity significance.
5. **No Local References**: Do not use `const T&` local references (`const SDolDefinition& x = ...` is forbidden). Getter methods must return structures by value.
6. **Detailed Comments**: Fully comment all public classes and methods.
