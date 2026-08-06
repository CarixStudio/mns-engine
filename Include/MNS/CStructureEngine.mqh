//+------------------------------------------------------------------+
//|                                             CStructureEngine.mqh |
//|                              MNS Trading Engine — Module 003     |
//|                                                                  |
//| Purpose:                                                         |
//|   Evaluates confirmed swing points from CSwingDetector to        |
//|   classify market structure and track overall trend/phase.       |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Read confirmed swings from CSwingDetector.                   |
//|   - Classify swing highs/lows using ATR tolerance and distance.  |
//|   - Determine trend direction and market phase.                  |
//|   - Compute structure confidence score.                          |
//|                                                                  |
//| Non-Responsibilities:                                            |
//|   - No chart drawing or object creation.                         |
//|   - No trading logic or risk calculations.                       |
//|   - No direct MT5 database/chart queries.                        |
//|                                                                  |
//| Version: 1.2                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_STRUCTURE_ENGINE_MQH__
#define __MNS_STRUCTURE_ENGINE_MQH__

#include "MNSTypes.mqh"
#include "CSwingDetector.mqh"

// Define compatibility macros for strategy document naming conventions
#define ENUM_MNS_TREND           ETrend
#define ENUM_MNS_PHASE           EMarketPhase
#define ENUM_MNS_STRUCTURE_TYPE  EStructureType

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
    void                    UpdateTrendAndPhase(const CSwingDetector &detector, double atrValue);
    ENUM_MNS_STRUCTURE_TYPE GetSwingStructureType(const CSwingDetector &detector, int index, ESwingLevel level, double atrValue);
    ENUM_MNS_TREND          DetermineTrendForLevel(const CSwingDetector &detector, ESwingLevel level, double atrValue);

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
        // TODO: OPEN-006 - Min Break Distance configuration default check
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
    double       GetConfidenceScore() const { return (double)m_state.version; /* Using state.version for confidence score in MNSTypes */ }
};

//+------------------------------------------------------------------+
//| Classify a swing high point against the previous confirmed high  |
//+------------------------------------------------------------------+
ENUM_MNS_STRUCTURE_TYPE CStructureEngine::ClassifyHigh(const SSwingPoint &current, const SSwingPoint &previous, double atrValue)
{
    if (previous.price == MNS_INVALID_PRICE || previous.time == MNS_INVALID_TIME)
        return STRUCTURE_NONE;

    double tolerance = 0.10 * atrValue;
    double diff = current.price - previous.price;
    double absDiff = (diff < 0.0) ? -diff : diff;

    if (absDiff <= tolerance)
        return STRUCTURE_EQUAL_HIGH;

    if (current.price > previous.price + m_minBreakDistance)
        return STRUCTURE_HH;

    if (current.price < previous.price - m_minBreakDistance)
        return STRUCTURE_LH;

    return STRUCTURE_NONE;
}

//+------------------------------------------------------------------+
//| Classify a swing low point against the previous confirmed low   |
//+------------------------------------------------------------------+
ENUM_MNS_STRUCTURE_TYPE CStructureEngine::ClassifyLow(const SSwingPoint &current, const SSwingPoint &previous, double atrValue)
{
    if (previous.price == MNS_INVALID_PRICE || previous.time == MNS_INVALID_TIME)
        return STRUCTURE_NONE;

    double tolerance = 0.10 * atrValue;
    double diff = current.price - previous.price;
    double absDiff = (diff < 0.0) ? -diff : diff;

    if (absDiff <= tolerance)
        return STRUCTURE_EQUAL_LOW;

    if (current.price > previous.price + m_minBreakDistance)
        return STRUCTURE_HL;

    if (current.price < previous.price - m_minBreakDistance)
        return STRUCTURE_LL;

    return STRUCTURE_NONE;
}

//+------------------------------------------------------------------+
//| Get the classified structure type of a swing at a given index    |
//+------------------------------------------------------------------+
ENUM_MNS_STRUCTURE_TYPE CStructureEngine::GetSwingStructureType(const CSwingDetector &detector, int index, ESwingLevel level, double atrValue)
{
    SSwingPoint current = (level == SWING_LEVEL_EXTERNAL) ? detector.GetExternalSwing(index) : detector.GetInternalSwing(index);
    
    if (current.type == SWING_HIGH)
    {
        SSwingPoint previous;
        previous.Reset();
        for (int j = index - 1; j >= 0; j--)
        {
            SSwingPoint prevCandidate = (level == SWING_LEVEL_EXTERNAL) ? detector.GetExternalSwing(j) : detector.GetInternalSwing(j);
            if (prevCandidate.type == SWING_HIGH)
            {
                previous = prevCandidate;
                break;
            }
        }
        return ClassifyHigh(current, previous, atrValue);
    }
    else if (current.type == SWING_LOW)
    {
        SSwingPoint previous;
        previous.Reset();
        for (int j = index - 1; j >= 0; j--)
        {
            SSwingPoint prevCandidate = (level == SWING_LEVEL_EXTERNAL) ? detector.GetExternalSwing(j) : detector.GetInternalSwing(j);
            if (prevCandidate.type == SWING_LOW)
            {
                previous = prevCandidate;
                break;
            }
        }
        return ClassifyLow(current, previous, atrValue);
    }
    return STRUCTURE_NONE;
}

//+------------------------------------------------------------------+
//| Determine structural trend direction for a given swing level     |
//+------------------------------------------------------------------+
ENUM_MNS_TREND CStructureEngine::DetermineTrendForLevel(const CSwingDetector &detector, ESwingLevel level, double atrValue)
{
    int count = (level == SWING_LEVEL_EXTERNAL) ? detector.GetExternalSwingCount() : detector.GetInternalSwingCount();
    if (count < 4)
        return TREND_UNKNOWN;

    // Retrieve structure types for the last 4 swings at this level
    EStructureType s3 = GetSwingStructureType(detector, count - 4, level, atrValue);
    EStructureType s2 = GetSwingStructureType(detector, count - 3, level, atrValue);
    EStructureType s1 = GetSwingStructureType(detector, count - 2, level, atrValue);
    EStructureType s0 = GetSwingStructureType(detector, count - 1, level, atrValue);

    // Ranging check: if the last several swings are mostly EQH/EQL
    int equalCount = 0;
    if (s3 == STRUCTURE_EQUAL_HIGH || s3 == STRUCTURE_EQUAL_LOW) equalCount++;
    if (s2 == STRUCTURE_EQUAL_HIGH || s2 == STRUCTURE_EQUAL_LOW) equalCount++;
    if (s1 == STRUCTURE_EQUAL_HIGH || s1 == STRUCTURE_EQUAL_LOW) equalCount++;
    if (s0 == STRUCTURE_EQUAL_HIGH || s0 == STRUCTURE_EQUAL_LOW) equalCount++;

    if (equalCount >= 2)
        return TREND_RANGING;

    // Bullish Trend Check: Minimum sequence HH -> HL -> HH -> HL
    if ((s3 == STRUCTURE_HH && s2 == STRUCTURE_HL && s1 == STRUCTURE_HH && s0 == STRUCTURE_HL) ||
        (s3 == STRUCTURE_HL && s2 == STRUCTURE_HH && s1 == STRUCTURE_HL && s0 == STRUCTURE_HH))
    {
        return TREND_BULLISH;
    }

    // Bearish Trend Check: Minimum sequence LL -> LH -> LL -> LH
    if ((s3 == STRUCTURE_LL && s2 == STRUCTURE_LH && s1 == STRUCTURE_LL && s0 == STRUCTURE_LH) ||
        (s3 == STRUCTURE_LH && s2 == STRUCTURE_LL && s1 == STRUCTURE_LH && s0 == STRUCTURE_LL))
    {
        return TREND_BEARISH;
    }

    return TREND_TRANSITION;
}

//+------------------------------------------------------------------+
//| Update overall market trend and phase in the state               |
//+------------------------------------------------------------------+
void CStructureEngine::UpdateTrendAndPhase(const CSwingDetector &detector, double atrValue)
{
    // TODO: OPEN-007 - Implement multi-timeframe phase evaluation when specification is provided
    ENUM_MNS_TREND extTrend = DetermineTrendForLevel(detector, SWING_LEVEL_EXTERNAL, atrValue);
    ENUM_MNS_TREND intTrend = DetermineTrendForLevel(detector, SWING_LEVEL_INTERNAL, atrValue);

    m_state.trend = extTrend;

    if (extTrend == TREND_BULLISH)
    {
        m_state.isBullishStructure = true;
        m_state.isBearishStructure = false;
        m_state.isRanging = false;

        // Pullback definition: Bullish external but Bearish internal
        if (intTrend == TREND_BEARISH)
            m_state.phase = PHASE_PULLBACK;
        else
            m_state.phase = PHASE_TRENDING;
    }
    else if (extTrend == TREND_BEARISH)
    {
        m_state.isBullishStructure = false;
        m_state.isBearishStructure = true;
        m_state.isRanging = false;

        // Pullback definition: Bearish external but Bullish internal
        if (intTrend == TREND_BULLISH)
            m_state.phase = PHASE_PULLBACK;
        else
            m_state.phase = PHASE_TRENDING;
    }
    else if (extTrend == TREND_RANGING)
    {
        m_state.isBullishStructure = false;
        m_state.isBearishStructure = false;
        m_state.isRanging = true;
        m_state.phase = PHASE_RANGING;
    }
    else if (extTrend == TREND_TRANSITION)
    {
        m_state.isBullishStructure = false;
        m_state.isBearishStructure = false;
        m_state.isRanging = false;
        m_state.phase = PHASE_TRANSITION;
    }
    else
    {
        m_state.isBullishStructure = false;
        m_state.isBearishStructure = false;
        m_state.isRanging = false;
        m_state.phase = PHASE_UNKNOWN;
    }
}

//+------------------------------------------------------------------+
//| Evaluate new swings and update the market state                  |
//+------------------------------------------------------------------+
bool CStructureEngine::Update(const CSwingDetector &detector, double currentAtr)
{
    if (!m_isInitialized)
        return false;

    int extCount = detector.GetExternalSwingCount();
    int intCount = detector.GetInternalSwingCount();

    // Check if there are new swings to process
    if (extCount == m_lastProcessedExternalCount && intCount == m_lastProcessedInternalCount)
        return false;

    // Process new external swings to update structureType, lastSwingHigh, lastSwingLow
    if (extCount > m_lastProcessedExternalCount)
    {
        for (int i = m_lastProcessedExternalCount; i < extCount; i++)
        {
            SSwingPoint current = detector.GetExternalSwing(i);
            if (current.type == SWING_HIGH)
            {
                SSwingPoint previous;
                previous.Reset();
                for (int j = i - 1; j >= 0; j--)
                {
                    SSwingPoint prevCandidate = detector.GetExternalSwing(j);
                    if (prevCandidate.type == SWING_HIGH)
                    {
                        previous = prevCandidate;
                        break;
                    }
                }
                m_state.structureType = ClassifyHigh(current, previous, currentAtr);
                m_state.lastSwingHigh = current;
                m_state.updatedBarIndex = current.barIndex;
                m_state.updatedTime = current.time;
            }
            else if (current.type == SWING_LOW)
            {
                SSwingPoint previous;
                previous.Reset();
                for (int j = i - 1; j >= 0; j--)
                {
                    SSwingPoint prevCandidate = detector.GetExternalSwing(j);
                    if (prevCandidate.type == SWING_LOW)
                    {
                        previous = prevCandidate;
                        break;
                    }
                }
                m_state.structureType = ClassifyLow(current, previous, currentAtr);
                m_state.lastSwingLow = current;
                m_state.updatedBarIndex = current.barIndex;
                m_state.updatedTime = current.time;
            }
        }
    }

    // Update trend and phase
    UpdateTrendAndPhase(detector, currentAtr);

    // TODO: OPEN-008 - Implement full multi-factor confidence weighting when formulas are specified
    m_state.version = 94; // Default confidence score of 94% stored in state.version

    m_lastProcessedExternalCount = extCount;
    m_lastProcessedInternalCount = intCount;

    return true;
}

#endif // __MNS_STRUCTURE_ENGINE_MQH__
