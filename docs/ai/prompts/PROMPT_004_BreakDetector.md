# MNS Trading Engine — Module 004 Generator Prompt
## Target File: `Include/MNS/CBreakDetector.mqh`
Version: 1.0

---

You are the senior MQL5 engineer. Implement the `CBreakDetector` class exactly as described below.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `Include/MNS/MNSTypes.mqh` — Shared Data Structures.
3. `Include/MNS/CSwingDetector.mqh` (and any other previous dependencies).
4. `docs/modules/004_BreakDetector.md` — This module's Specification.
5. `docs/modules/004_ALGORITHM.md` — This module's Algorithm.
6. `docs/modules/004_API.md` — This module's Class API.
7. `docs/CLASS_DIAGRAM.md` — Design Blueprint.
8. `docs/CodingStandards.md` — Coding and style guide.
9. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.
10. `docs/Roadmap.md` — Project roadmap.

---

## Absolute Constraints

1. **Follow the MNS Architecture Rules (docs/ai/ARCHITECTURE_RULES.md)**:
   - No direct MT5 calls (`iHigh()`, `iLow()`, `iTime()`, `Bars()`, etc.).
   - No chart object drawing (`ObjectCreate()`, etc.).
   - No trading logic or order placements.
   - No logger statements (`Print()`, etc.) inside the engine class itself.
2. **MQL5 Syntax Rules**:
   - Do NOT return `const SStructureBreak&` or any const reference from const methods on member structs. Return by value.
   - Do NOT declare local variables as references to struct properties or arrays (`const SSwingPoint& x = ...`). Use value copies.
   - Use `#define` or literals for array dimensions, never `const int`.

---

## 1. Context and Class Interface

This module evaluates closed candles to detect structural breaks.

Implement the following class structure:

```mql5
#ifndef __MNS_BREAK_DETECTOR_MQH__
#define __MNS_BREAK_DETECTOR_MQH__

#include "MNSTypes.mqh"
#include "CSwingDetector.mqh"
#include "CStructureEngine.mqh"

class CBreakDetector
{
private:
    bool            m_isInitialized;
    SStructureBreak m_breaks[];
    int             m_breakCount;
    int             m_lastProcessedRatesTotal;
    
    // Cached latest breaks for O(1) retrieval
    SStructureBreak m_latestBOS;
    SStructureBreak m_latestIBOS;
    SStructureBreak m_latestCHOCH;
    SStructureBreak m_emptyBreak;

    // Helpers
    bool IsBreakAlreadyRecorded(datetime swingTime, EStructureBreak type) const;
    void RecordBreak(int barIndex, double price, datetime time, EStructureBreak breakType, EStrength strength, const SSwingPoint &brokenSwing, double displacement, double atrMultiple);
    bool EvaluateBarForBreaks(int index, const CSwingDetector &swingDetector, const CStructureEngine &structureEngine, const double &high[], const double &low[], const double &close[], const double &open[], const datetime &time[], int ratesTotal, double currentAtr);

public:
    CBreakDetector()
        : m_isInitialized(false),
          m_breakCount(0),
          m_lastProcessedRatesTotal(0)
    {
        m_latestBOS.Reset();
        m_latestIBOS.Reset();
        m_latestCHOCH.Reset();
        m_emptyBreak.Reset();
    }

    /// @brief Initializes the Break Detector.
    /// @return True on success.
    bool Initialize()
    {
        if (ArrayResize(m_breaks, MNS_MAX_STRUCTURE_BREAKS) != MNS_MAX_STRUCTURE_BREAKS)
            return false;
        
        m_breakCount = 0;
        m_lastProcessedRatesTotal = 0;
        m_latestBOS.Reset();
        m_latestIBOS.Reset();
        m_latestCHOCH.Reset();
        m_emptyBreak.Reset();
        m_isInitialized = true;
        return true;
    }

    /// @brief Resets detector state.
    void Reset()
    {
        m_breakCount = 0;
        m_lastProcessedRatesTotal = 0;
        m_latestBOS.Reset();
        m_latestIBOS.Reset();
        m_latestCHOCH.Reset();
        m_emptyBreak.Reset();
        for (int i = 0; i < MNS_MAX_STRUCTURE_BREAKS; i++)
            m_breaks[i].Reset();
    }

    /// @brief Updates the break history with newly closed bars.
    bool Update(const CSwingDetector &swingDetector, 
                const CStructureEngine &structureEngine,
                const double &high[],
                const double &low[],
                const double &close[],
                const double &open[],
                const datetime &time[],
                int ratesTotal,
                int prevCalculated,
                double currentAtr);

    // Getters (returned by value to comply with MQL5 constraints)
    int             GetBreakCount() const { return m_breakCount; }
    SStructureBreak GetBreak(int index) const;
    SStructureBreak GetLatestBOS() const { return m_latestBOS; }
    SStructureBreak GetLatestIBOS() const { return m_latestIBOS; }
    SStructureBreak GetLatestCHOCH() const { return m_latestCHOCH; }

    bool HasBullishBOS() const { return m_latestBOS.isConfirmed && m_latestBOS.breakType == BREAK_BOS && m_latestBOS.brokenSwing.type == SWING_HIGH; }
    bool HasBearishBOS() const { return m_latestBOS.isConfirmed && m_latestBOS.breakType == BREAK_BOS && m_latestBOS.brokenSwing.type == SWING_LOW; }
    bool HasBullishIBOS() const { return m_latestIBOS.isConfirmed && m_latestIBOS.breakType == BREAK_INTERNAL_BOS && m_latestIBOS.brokenSwing.type == SWING_HIGH; }
    bool HasBearishIBOS() const { return m_latestIBOS.isConfirmed && m_latestIBOS.breakType == BREAK_INTERNAL_BOS && m_latestIBOS.brokenSwing.type == SWING_LOW; }
    bool HasBullishCHOCH() const { return m_latestCHOCH.isConfirmed && m_latestCHOCH.breakType == BREAK_CHOCH && m_latestCHOCH.brokenSwing.type == SWING_HIGH; }
    bool HasBearishCHOCH() const { return m_latestCHOCH.isConfirmed && m_latestCHOCH.breakType == BREAK_CHOCH && m_latestCHOCH.brokenSwing.type == SWING_LOW; }
};

#endif // __MNS_BREAK_DETECTOR_MQH__
```

---

## 2. Implementation Logic

### A. Incremental Update Scan
- In `Update()`, only closed bars are evaluated. Start scan from `ratesTotal - 1` (or last ratesTotal processed) down to index `1` (newest closed bar). Index `0` (forming candle) is ignored.
- Only check bars that have not been processed. If `prevCalculated > 0`, scan from `m_lastProcessedRatesTotal - 1` down to `1`.

### B. BOS / iBOS Detection (Candle Body Closes Beyond Swing)
1. For bar `i`: retrieve the latest confirmed external swing high and low at that point in time (whose `barIndex > i`, meaning they are historical swings relative to bar `i`).
2. **Bullish BOS**: If `close[i] > swingHigh.price` and `swingHigh.price != MNS_INVALID_PRICE`:
   - Verify that this swing high has not already been broken in our break history.
   - If not broken, log a `BREAK_BOS` break.
3. **Bearish BOS**: If `close[i] < swingLow.price` and `swingLow.price != MNS_INVALID_PRICE`:
   - Verify that this swing low has not already been broken.
   - If not broken, log a `BREAK_BOS` break.
4. **Internal BOS (iBOS)**: Perform identical checks using internal swings. If broken, log `BREAK_INTERNAL_BOS`.

### C. CHoCH Detection (Wick-Only Reversal Warning)
1. Retrieve current trend bias from `CStructureEngine`.
2. **Bearish CHoCH (Bullish Reversal Warning)**: If trend is `TREND_BULLISH`:
   - Protected swing is the latest confirmed External Swing Low.
   - If `low[i] < protectedLow.price` AND `close[i] >= protectedLow.price` (wick-only breach):
     - Log `BREAK_CHOCH` break with `brokenSwing` set to the protected low.
3. **Bullish CHoCH (Bearish Reversal Warning)**: If trend is `TREND_BEARISH`:
   - Protected swing is the latest confirmed External Swing High.
   - If `high[i] > protectedHigh.price` AND `close[i] <= protectedHigh.price` (wick-only breach):
     - Log `BREAK_CHOCH` break with `brokenSwing` set to the protected high.

### D. Strength Score Calculation
1. Compute candle range: `range = high[i] - low[i]`.
2. Compute `atrMultiple = range / currentAtr` (volatility size).
3. Classify:
   - `atrMultiple >= 2.0` $\implies$ Strength = `STRENGTH_STRONG` (Score 90.0)
   - `atrMultiple >= 1.0` $\implies$ Strength = `STRENGTH_AVERAGE` (Score 70.0)
   - `atrMultiple < 1.0` $\implies$ Strength = `STRENGTH_WEAK` (Score 45.0)

---

## 3. Ambiguities & TODOs to Include

Ensure the following comments are added to code sections:
- **`// TODO: OPEN-009 - Verify if CHoCH should apply to non-trend swing points`**
- **`// TODO: OPEN-010 - Check displacement calculation parameters`**

Write the complete code directly to `Include/MNS/CBreakDetector.mqh`.
Do not use `Print` or external dependencies.
