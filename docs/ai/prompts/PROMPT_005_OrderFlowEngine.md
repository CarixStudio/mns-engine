## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
3. `Include/MNS/MNSTypes.mqh` — Shared Data Structures.
4. `Include/MNS/CSwingDetector.mqh` — Swing Detector dependency.
5. `Include/MNS/CStructureEngine.mqh` — Structure Engine dependency.
6. `Include/MNS/CBreakDetector.mqh` — Break Detector dependency.
7. `docs/modules/005_OrderFlowEngine.md` — This module's Specification.
8. `docs/modules/005_ALGORITHM.md` — This module's Algorithm.
9. `docs/modules/005_API.md` — This module's Class API.
10. `docs/CLASS_DIAGRAM.md` — Design Blueprint.
11. `docs/CodingStandards.md` — Coding and style guide.
12. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.
13. `docs/Roadmap.md` — Project roadmap.
14. `docs/infrastructure/INF_ROADMAP.md` — Infrastructure roadmap.

---

# GENERATOR AI INSTRUCTIONS — MODULE 005 (COrderFlowEngine)

You are the developer AI. Your task is to write the complete production-grade implementation of the Order Flow Engine (`COrderFlowEngine`) in MQL5.

## Architectural Constraints

1. **Deterministic Logic**: The code must be 100% deterministic and must not use live chart functions (such as `iClose`, `iTime`, etc.) or broker API functions.
2. **Defensive Programming**: Check for initializations and boundaries. Ensure that out-of-bound requests return safe sentinel structures.
3. **No MQL5 Local References in Const Methods**: Avoid assigning a local variable as a reference to a function return (e.g. `const SSwingPoint &sw = ...`). MQL5 does not allow local references in const methods. Return structures by value or use normal assignments.
4. **No UI or Drawing Operations**: All visual rendering is deferred to Module 013.
5. **No Placeholders**: Implement the full state transition machine and metric updates completely.

## API Definition

Implement the class exactly as described in `docs/modules/005_API.md` and following the algorithm in `docs/modules/005_ALGORITHM.md`.

Save the resulting file at `Include/MNS/COrderFlowEngine.mqh`.

## Code Outline

```mql5
//+------------------------------------------------------------------+
//|                                           COrderFlowEngine.mqh   |
//|                              MNS Trading Engine — Module 005     |
//|                                                                  |
//| Purpose:                                                         |
//|   Consumes market structure and breaks to track directional      |
//|   order flow state-machine transitions and alignment scores.     |
//+------------------------------------------------------------------+
#ifndef __MNS_ORDER_FLOW_ENGINE_MQH__
#define __MNS_ORDER_FLOW_ENGINE_MQH__

#include "MNSTypes.mqh"
#include "CSwingDetector.mqh"
#include "CStructureEngine.mqh"
#include "CBreakDetector.mqh"

class COrderFlowEngine
{
private:
    bool            m_isInitialized;
    SOrderFlowState m_state;
    int             m_lastProcessedBreakCount;

    // Helper functions
    void UpdateStrengthsAndConfidence(const CStructureEngine &structureEngine, const CBreakDetector &breakDetector, const double &high[], const double &low[], const double &close[], const double &open[], const datetime &time[], int ratesTotal, double currentAtr);
    bool FindLatestSwingBefore(const CSwingDetector &detector, datetime limitTime, ESwingType type, SSwingPoint &outSwing) const;

public:
    COrderFlowEngine()
        : m_isInitialized(false),
          m_lastProcessedBreakCount(0)
    {
        m_state.Reset();
    }

    bool Initialize()
    {
        m_state.Reset();
        m_lastProcessedBreakCount = 0;
        m_isInitialized = true;
        return true;
    }

    void Reset()
    {
        m_state.Reset();
        m_lastProcessedBreakCount = 0;
    }

    bool Update(const CSwingDetector &swingDetector, 
                const CStructureEngine &structureEngine,
                const CBreakDetector &breakDetector,
                const double &high[],
                const double &low[],
                const double &close[],
                const double &open[],
                const datetime &time[],
                int ratesTotal,
                int prevCalculated,
                double currentAtr);

    // Getters
    SOrderFlowState     GetState() const { return m_state; }
    EOrderFlowDirection GetDirection() const { return m_state.direction; }
    EOrderFlowState     GetGranularState() const { return m_state.state; }
    double              GetConfidenceScore() const { return m_state.confidenceScore; }

    bool IsBullish() const { return m_state.direction == ORDER_FLOW_DIR_BULLISH; }
    bool IsBearish() const { return m_state.direction == ORDER_FLOW_DIR_BEARISH; }
    bool IsTransition() const { return m_state.transition; }
    bool IsNeutral() const { return m_state.state == ORDER_FLOW_NEUTRAL; }

    EAlignmentState GetAlignmentWith(ETrend trend) const
    {
        if (m_state.direction == ORDER_FLOW_DIR_NEUTRAL)
            return ALIGN_NEUTRAL;
        if ((m_state.direction == ORDER_FLOW_DIR_BULLISH && trend == TREND_BULLISH) ||
            (m_state.direction == ORDER_FLOW_DIR_BEARISH && trend == TREND_BEARISH))
            return ALIGN_ALIGNED;
        return ALIGN_CONFLICT;
    }
};

// ... Implement helper methods and Update cycle ...

#endif // __MNS_ORDER_FLOW_ENGINE_MQH__
```
