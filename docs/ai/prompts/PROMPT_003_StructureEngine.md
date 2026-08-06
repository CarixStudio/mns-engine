# MNS Trading Engine — Module 003 Generator Prompt
## Target File: `Include/MNS/CStructureEngine.mqh`
Version: 1.2

---

You are the senior MQL5 engineer. Implement the `CStructureEngine` class exactly as described below.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files for the rules, types, and standards:

1. **`kennystrstegy.md`** — The Strategy Document (Source of Truth). Read the section "Structure Engine" (specifically lines 700-915) for structural classification, equal highs/lows, trend rules, and Phase definitions.
2. **`Include/MNS/MNSTypes.mqh`** — Shared Data Structures. Look up the definition of `SMarketState` and structure/trend/phase enumerations (`ENUM_MNS_TREND`, `ENUM_MNS_PHASE`, `ENUM_MNS_STRUCTURE_TYPE`).
3. **`Include/MNS/CSwingDetector.mqh`** — Previous Module. This is the module containing the confirmed swings history that `CStructureEngine` will read.
4. **`docs/modules/003_StructureEngine.md`** — Module Specification. Defines purpose, inputs, outputs, and requirements.
5. **`docs/modules/003_ALGORITHM.md`** — Module Algorithm. Defines the step-by-step logic rules and processing pipeline.
6. **`docs/modules/003_API.md`** — Module Class API. Defines class layout, public methods, and members.
7. **`docs/CLASS_DIAGRAM.md`** — Design Blueprint. Shows the architecture context and relationships between modules.
8. **`docs/CodingStandards.md`** — Coding and style guide (naming conventions like `m_` prefixes, class name `CStructureEngine`).
9. **`docs/TODO_STRATEGY.md`** — Active strategy ambiguities tracker.
10. **`docs/Roadmap.md`** — Project roadmap context.

---

## Absolute Constraints

1. **Follow the MNS Architecture Rules (docs/ai/ARCHITECTURE_RULES.md)**:
   - No direct MT5 calls (`iHigh()`, `iLow()`, `iTime()`, `Bars()`, etc.).
   - No chart object drawing (`ObjectCreate()`, etc.).
   - No trading logic or order placements.
   - No logger statements (`Print()`, etc.) inside the engine class itself.
2. **MQL5 Syntax Rules**:
   - Do NOT return `const SMarketState&` or any const reference from const methods on member structs. Return by value.
   - Do NOT declare local variables as references to struct properties or arrays (`const SSwingPoint& x = ...`). Use value copies.
   - Use `#define` or literals for array dimensions, never `const int`.

---

## 1. Context and Class Interface

This module consumes the swing histories from `CSwingDetector` and updates the current market structure state.

Implement the following structure:

```mql5
#ifndef __MNS_STRUCTURE_ENGINE_MQH__
#define __MNS_STRUCTURE_ENGINE_MQH__

#include "MNSTypes.mqh"
#include "CSwingDetector.mqh"

class CStructureEngine
{
private:
    bool            m_isInitialized;
    SMarketState    m_state;
    double          m_minBreakDistance; // Configured minimum break distance (default = 0.0)
    
    // Track last processed swing indices to avoid reprocessing the same swing
    int             m_lastProcessedExternalCount;
    int             m_lastProcessedInternalCount;

    // Helper functions
    ENUM_MNS_STRUCTURE_TYPE ClassifyHigh(const SSwingPoint &current, const SSwingPoint &previous, double atrValue);
    ENUM_MNS_STRUCTURE_TYPE ClassifyLow(const SSwingPoint &current, const SSwingPoint &previous, double atrValue);
    void                    UpdateTrendAndPhase(const CSwingDetector &detector);

public:
    // Lifecycle
    CStructureEngine()
        : m_isInitialized(false),
          m_minBreakDistance(0.0),
          m_lastProcessedExternalCount(0),
          m_lastProcessedInternalCount(0)
    {
        m_state.Reset();
    }

    /// @brief Initializes the structure engine.
    /// @param minBreakDistance Minimum price distance (in points) required to confirm a break (HH/LL/LH/HL).
    /// @return True on success.
    bool Initialize(double minBreakDistance = 0.0)
    {
        m_minBreakDistance = minBreakDistance;
        m_lastProcessedExternalCount = 0;
        m_lastProcessedInternalCount = 0;
        m_state.Reset();
        m_isInitialized = true;
        return true;
    }

    /// @brief Resets engine state
    void Reset()
    {
        m_lastProcessedExternalCount = 0;
        m_lastProcessedInternalCount = 0;
        m_state.Reset();
    }

    /// @brief Evaluates new swings and updates the market state.
    /// @param detector Active CSwingDetector instance containing the swing history.
    /// @param currentAtr The ATR value at the current bar (used for Equal High/Low calculations).
    /// @return True if the market state was updated.
    bool Update(const CSwingDetector &detector, double currentAtr);

    // Getters (returned by value to comply with MQL5 constraints)
    SMarketState GetState() const { return m_state; }
    bool         IsBullish() const { return m_state.trend == TREND_BULLISH; }
    bool         IsBearish() const { return m_state.trend == TREND_BEARISH; }
    bool         IsTransition() const { return m_state.trend == TREND_TRANSITION; }
    bool         IsRanging() const { return m_state.trend == TREND_RANGING; }
    double       GetConfidenceScore() const { return m_state.version; /* Using state.version for confidence score in MNSTypes */ }
};

#endif // __MNS_STRUCTURE_ENGINE_MQH__
```

---

## 2. Implementation Rules

### A. Swing Classification
Whenever a new external swing is confirmed in `CSwingDetector`:
1. Compare it to the **previous confirmed swing of the same direction** (High to High, Low to Low).
2. Compute **Tolerance Zone**: `Tolerance = 0.10 * atrValue` (10% of current ATR).
3. If `Absolute(current.price - previous.price) <= Tolerance`:
   - High swing: Set `m_state.structureType = STRUCTURE_EQH`
   - Low swing: Set `m_state.structureType = STRUCTURE_EQL`
4. If it's a High and is NOT an Equal High:
   - If `current.price > previous.price + m_minBreakDistance`: Set type `STRUCTURE_HH`
   - Else if `current.price < previous.price - m_minBreakDistance`: Set type `STRUCTURE_LH`
5. If it's a Low and is NOT an Equal Low:
   - If `current.price > previous.price + m_minBreakDistance`: Set type `STRUCTURE_HL`
   - Else if `current.price < previous.price - m_minBreakDistance`: Set type `STRUCTURE_LL`

### B. Trend Logic
- **Bullish Trend**: Minimum sequence of **HH -> HL -> HH -> HL** (read chronological order from `CSwingDetector`'s stored history).
- **Bearish Trend**: Minimum sequence of **LL -> LH -> LL -> LH**.
- **Transition Trend**: If sequence is mixed.
- **Ranging Trend**: If the last several swings are mostly EQH/EQL with no clear trend.

*Note: Since these rules contain ambiguities (OPEN-006, OPEN-007, OPEN-008), implement them based on direct sequence history comparison. If there are insufficient swings to confirm a trend, default the trend to `TREND_UNKNOWN`.*

---

## 3. Ambiguities & TODOs to Include

Ensure the following TODOs are placed in the code comments referencing their OPEN IDs:
- **`// TODO: OPEN-006 - Min Break Distance configuration default check`**
- **`// TODO: OPEN-007 - Implement multi-timeframe phase evaluation when specification is provided`**
- **`// TODO: OPEN-008 - Implement full multi-factor confidence weighting when formulas are specified`**
  - Until specified, return confidence score as a static default (e.g. `94.0` as shown in output examples).

---

Please output the complete contents of `CStructureEngine.mqh` inside a single markdown code block. Do not use any external dependencies.
