## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
4. `Include/MNS/MNSTypes.mqh` — Shared Data Structures.
5. `Include/MNS/CSwingDetector.mqh` (and any other previous dependencies).
6. `docs/modules/008_POIEngine.md` — This module's Specification.
7. `docs/modules/008_ALGORITHM.md` — This module's Algorithm.
8. `docs/modules/008_API.md` — This module's Class API.
9. `docs/CLASS_DIAGRAM.md` — Design Blueprint.
10. `docs/CodingStandards.md` — Coding and style guide.
11. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.
12. `docs/Roadmap.md` — Project roadmap.
13. `docs/infrastructure/INF_ROADMAP.md` — Infrastructure roadmap.

---

## IMPLEMENTATION INSTRUCTIONS

Please write the complete code for `Include/MNS/CPOIEngine.mqh` adhering strictly to the algorithm specified in `docs/modules/008_ALGORITHM.md`.

Additionally, you must modify `Include/MNS/MNSTypes.mqh` to append the required POI types, states, and dealing range zone enums/structs at the end of the file, right before the `#endif` guard:

```mql5
enum EPoIType
{
    POI_NONE               = 0,
    POI_OB_BULLISH         = 1,
    POI_OB_BEARISH         = 2,
    POI_BREAKER_BULLISH    = 3,
    POI_BREAKER_BEARISH    = 4,
    POI_MITIGATION_BULLISH = 5,
    POI_MITIGATION_BEARISH = 6,
    POI_FVG_BULLISH        = 7,
    POI_FVG_BEARISH        = 8
};

enum EPoILifecycle
{
    POI_STATE_ACTIVE             = 0,  ///< Active and untouched.
    POI_STATE_PARTIAL_MITIGATED  = 1,  ///< Partially mitigated (1-49% FVG or block wick touch).
    POI_STATE_MATERIAL_MITIGATED = 2,  ///< Materially mitigated (50-99% FVG).
    POI_STATE_FILLED             = 3,  ///< 100% filled (FVG).
    POI_STATE_INVALIDATED        = 4,  ///< Invalidated by close beyond invalidation level.
    POI_STATE_ARCHIVED           = 5   ///< Archived historical POI.
};

enum EDealingRangeZone
{
    ZONE_EQUILIBRIUM = 0,  ///< 50% retracement.
    ZONE_PREMIUM     = 1,  ///< > 50% of the range (sell zone).
    ZONE_DISCOUNT    = 2   ///< < 50% of the range (buy zone).
};

struct SPoIDefinition
{
    int             id;                 ///< Unique POI identifier.
    EPoIType        type;               ///< POI type (OB, Breaker, FVG, etc.).
    EPoILifecycle   lifecycle;          ///< POI lifecycle state.
    double          upperPrice;         ///< Upper price boundary of the POI.
    double          lowerPrice;         ///< Lower price boundary of the POI.
    double          invalidationLevel;  ///< Price level that triggers invalidation if body closes beyond it.
    datetime        createdTime;        ///< Creation time.
    int             barIndex;           ///< Bar index where the POI was created.
    double          rankingScore;       ///< 0-100 quality score.
    EPoolPriority   priority;           ///< Priority (LOW, MEDIUM, HIGH).
    double          fillPercent;        ///< Fill percentage (specifically for FVGs, 0-100%).
    bool            active;             ///< Active flag.
    datetime        mitigatedTime;      ///< Timestamp when first mitigated.
    datetime        invalidatedTime;    ///< Timestamp when invalidated.
    
    /// @brief Resets structure to safe defaults.
    void Reset()
    {
        id                = 0;
        type              = POI_NONE;
        lifecycle         = POI_STATE_ACTIVE;
        upperPrice        = 0.0;
        lowerPrice        = 0.0;
        invalidationLevel = 0.0;
        createdTime       = 0;
        barIndex          = -1;
        rankingScore      = 0.0;
        priority          = PRIORITY_LOW;
        fillPercent       = 0.0;
        active            = true;
        mitigatedTime     = 0;
        invalidatedTime   = 0;
    }
};
```

Ensure:
1. **O(1) Fixed Allocation**: Use a fixed-size array of 128 elements for POI storage (`m_pois[128]`) to avoid dynamic memory allocation fragmentation in MQL5. If the pool overflows, overwrite the oldest inactive/invalidated POI.
2. **Strict FVG Validation**: Filter out any Fair Value Gaps (FVG) smaller than `MinimumFVG = max(3 * SYMBOL_POINT, 0.10 * ATR(14))`.
3. **Displacement checks**: Reuse displacement detection logic conforming to `body/range >= 65%`, `close strength >= 75%`, and `range >= 1.20 * ATR(14)`.
4. **Invalidation & Mitigation**: Correctly identify invalidation of zones via candle body closes (and wick sweeps for FVG fills and zone mitigations).
5. **Merge rules**: Implement POI merging rules for same-direction overlapping POIs, and confluence scoring (boosting rank scores) for different-direction or different-type overlaps.
6. **MQL5 Rules**: Getter methods returning structures must return them by value (e.g. `SPoIDefinition GetPoI(...) const`), and do not declare local variables as const references (`const SPoIDefinition& x = ...` is forbidden).
7. **Commenting**: All public classes and methods must have clean, detailed MQL5 documentation.
