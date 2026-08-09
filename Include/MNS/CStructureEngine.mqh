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

// Define alignment state for multi-factor confidence calculations (OPEN-008)
enum EAlignmentState
{
    ALIGN_CONFLICT = -1,
    ALIGN_NEUTRAL  = 0,
    ALIGN_ALIGNED  = 1
};
#define ENUM_MNS_ALIGNMENT EAlignmentState

#define ENUM_MNS_TREND           ETrend
#define ENUM_MNS_PHASE           EMarketPhase
#define ENUM_MNS_STRUCTURE_TYPE  EStructureType

class CStructureEngine
{
private:
    bool            m_isInitialized;
    SMarketState    m_state;
    double          m_minBreakDistance; // Configured minimum break distance (default = 0.0)
    
    // Confidence alignments
    ENUM_MNS_ALIGNMENT m_orderFlowAlign;
    ENUM_MNS_ALIGNMENT m_displacementAlign;
    ENUM_MNS_ALIGNMENT m_mtfAlign;
    ENUM_MNS_ALIGNMENT m_deliveryAlign;
    ENUM_MNS_ALIGNMENT m_dolAlign;
    ENUM_MNS_ALIGNMENT m_bosAlign;
    ENUM_MNS_ALIGNMENT m_internalAlign;
    
    // Track last processed swing indices to avoid reprocessing the same swing
    int             m_lastProcessedExternalCount;
    int             m_lastProcessedInternalCount;

    // Helper functions
    ENUM_MNS_STRUCTURE_TYPE ClassifyHigh(const SSwingPoint &current, const SSwingPoint &previous, double atrValue) const;
    ENUM_MNS_STRUCTURE_TYPE ClassifyLow(const SSwingPoint &current, const SSwingPoint &previous, double atrValue) const;
    void                    UpdateTrendAndPhase(const CSwingDetector &detector, double atrValue);
    ENUM_MNS_STRUCTURE_TYPE GetSwingStructureType(const CSwingDetector &detector, int index, ESwingLevel level, double atrValue) const;
    ENUM_MNS_TREND          DetermineTrendForLevel(const CSwingDetector &detector, ESwingLevel level, double atrValue) const;
    double                  CalculateConfidenceScore(const CSwingDetector &detector, double atrValue) const;

public:
    // Lifecycle
    CStructureEngine()
        : m_isInitialized(false),
          m_minBreakDistance(0.0),
          m_orderFlowAlign(ALIGN_NEUTRAL),
          m_displacementAlign(ALIGN_NEUTRAL),
          m_mtfAlign(ALIGN_NEUTRAL),
          m_deliveryAlign(ALIGN_NEUTRAL),
          m_dolAlign(ALIGN_NEUTRAL),
          m_bosAlign(ALIGN_NEUTRAL),
          m_internalAlign(ALIGN_NEUTRAL),
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
        m_orderFlowAlign = ALIGN_NEUTRAL;
        m_displacementAlign = ALIGN_NEUTRAL;
        m_mtfAlign = ALIGN_NEUTRAL;
        m_deliveryAlign = ALIGN_NEUTRAL;
        m_dolAlign = ALIGN_NEUTRAL;
        m_bosAlign = ALIGN_NEUTRAL;
        m_internalAlign = ALIGN_NEUTRAL;
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
    string       GetConfidenceInterpretation() const;

    // Setters for external confidence alignments (default to neutral if not set)
    void SetOrderFlowAlignment(ENUM_MNS_ALIGNMENT val)      { m_orderFlowAlign = val; }
    void SetDisplacementQuality(ENUM_MNS_ALIGNMENT val)     { m_displacementAlign = val; }
    void SetMtfAgreement(ENUM_MNS_ALIGNMENT val)            { m_mtfAlign = val; }
    void SetActiveDeliveryAlignment(ENUM_MNS_ALIGNMENT val)  { m_deliveryAlign = val; }
    void SetDolCompatibility(ENUM_MNS_ALIGNMENT val)        { m_dolAlign = val; }
    void SetBosAlignment(ENUM_MNS_ALIGNMENT val)            { m_bosAlign = val; }
    void SetInternalStructureAlignment(ENUM_MNS_ALIGNMENT val) { m_internalAlign = val; }
};

//+------------------------------------------------------------------+
//| Classify a swing high point against the previous confirmed high  |
//+------------------------------------------------------------------+
ENUM_MNS_STRUCTURE_TYPE CStructureEngine::ClassifyHigh(const SSwingPoint &current, const SSwingPoint &previous, double atrValue) const
{
    if (previous.price == MNS_INVALID_PRICE || previous.time == MNS_INVALID_TIME)
        return STRUCTURE_NONE;

    double tolerance = MathMax(3.0 * _Point, 0.10 * atrValue);
    double diff = current.price - previous.price;
    double absDiff = (diff < 0.0) ? -diff : diff;

    if (absDiff <= tolerance)
        return STRUCTURE_EQUAL_HIGH;

    double minBreakDistance = MathMax(2.0 * _Point, 0.10 * atrValue);

    if (current.price > previous.price + minBreakDistance)
        return STRUCTURE_HH;

    if (current.price < previous.price - minBreakDistance)
        return STRUCTURE_LH;

    return STRUCTURE_NONE;
}

//+------------------------------------------------------------------+
//| Classify a swing low point against the previous confirmed low   |
//+------------------------------------------------------------------+
ENUM_MNS_STRUCTURE_TYPE CStructureEngine::ClassifyLow(const SSwingPoint &current, const SSwingPoint &previous, double atrValue) const
{
    if (previous.price == MNS_INVALID_PRICE || previous.time == MNS_INVALID_TIME)
        return STRUCTURE_NONE;

    double tolerance = MathMax(3.0 * _Point, 0.10 * atrValue);
    double diff = current.price - previous.price;
    double absDiff = (diff < 0.0) ? -diff : diff;

    if (absDiff <= tolerance)
        return STRUCTURE_EQUAL_LOW;

    double minBreakDistance = MathMax(2.0 * _Point, 0.10 * atrValue);

    if (current.price > previous.price + minBreakDistance)
        return STRUCTURE_HL;

    if (current.price < previous.price - minBreakDistance)
        return STRUCTURE_LL;

    return STRUCTURE_NONE;
}

//+------------------------------------------------------------------+
//| Get the classified structure type of a swing at a given index    |
//+------------------------------------------------------------------+
ENUM_MNS_STRUCTURE_TYPE CStructureEngine::GetSwingStructureType(const CSwingDetector &detector, int index, ESwingLevel level, double atrValue) const
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
ENUM_MNS_TREND CStructureEngine::DetermineTrendForLevel(const CSwingDetector &detector, ESwingLevel level, double atrValue) const
{
    int count = (level == SWING_LEVEL_EXTERNAL) ? detector.GetExternalSwingCount() : detector.GetInternalSwingCount();
    if (count < 2)
        return TREND_UNKNOWN;

    ENUM_MNS_TREND currentTrend = TREND_UNKNOWN;
    
    // Track the latest structural relationship types
    EStructureType lastHighType = STRUCTURE_NONE;
    EStructureType lastLowType  = STRUCTURE_NONE;
    
    // Consecutive equal swings to detect range
    int equalCount = 0;

    // Scan through confirmed swings chronologically (oldest first) to evaluate transitions
    for (int i = 0; i < count; i++)
    {
        SSwingPoint sw = (level == SWING_LEVEL_EXTERNAL) ? detector.GetExternalSwing(i) : detector.GetInternalSwing(i);
        EStructureType type = GetSwingStructureType(detector, i, level, atrValue);
        
        if (type == STRUCTURE_EQUAL_HIGH || type == STRUCTURE_EQUAL_LOW)
            equalCount++;
        else
            equalCount = 0;

        if (sw.type == SWING_HIGH)
            lastHighType = type;
        else if (sw.type == SWING_LOW)
            lastLowType = type;

        // Apply Section 1.6 State Transition Machine
        if (currentTrend == TREND_UNKNOWN)
        {
            if (lastHighType == STRUCTURE_HH && lastLowType == STRUCTURE_HL)
                currentTrend = TREND_BULLISH;
            else if (lastHighType == STRUCTURE_LH && lastLowType == STRUCTURE_LL)
                currentTrend = TREND_BEARISH;
            else if (equalCount >= 2)
                currentTrend = TREND_RANGING;
        }
        else if (currentTrend == TREND_BULLISH)
        {
            // Bearish CHoCH: price closes below protected HL low (triggers transition state)
            if (sw.type == SWING_LOW && type == STRUCTURE_LL)
            {
                currentTrend = TREND_TRANSITION;
            }
            else if (equalCount >= 2)
            {
                currentTrend = TREND_RANGING;
            }
        }
        else if (currentTrend == TREND_BEARISH)
        {
            // Bullish CHoCH: price closes above protected LH high (triggers transition state)
            if (sw.type == SWING_HIGH && type == STRUCTURE_HH)
            {
                currentTrend = TREND_TRANSITION;
            }
            else if (equalCount >= 2)
            {
                currentTrend = TREND_RANGING;
            }
        }
        else if (currentTrend == TREND_TRANSITION)
        {
            // Transition ends when a new directional BOS confirms continuation
            if (lastHighType == STRUCTURE_HH && lastLowType == STRUCTURE_HL)
                currentTrend = TREND_BULLISH;
            else if (lastHighType == STRUCTURE_LH && lastLowType == STRUCTURE_LL)
                currentTrend = TREND_BEARISH;
            else if (equalCount >= 2)
                currentTrend = TREND_RANGING;
        }
        else if (currentTrend == TREND_RANGING)
        {
            // Range ends on structure break out establishing new trend
            if (lastHighType == STRUCTURE_HH && lastLowType == STRUCTURE_HL)
                currentTrend = TREND_BULLISH;
            else if (lastHighType == STRUCTURE_LH && lastLowType == STRUCTURE_LL)
                currentTrend = TREND_BEARISH;
        }
    }

    return currentTrend;
}

//+------------------------------------------------------------------+
//| Update overall market trend and phase in the state               |
//| Source: kennystrategy2.md Section 1.6 & 10.4                     |
//+------------------------------------------------------------------+
void CStructureEngine::UpdateTrendAndPhase(const CSwingDetector &detector, double atrValue)
{
    // Trend and phase are evaluated per-timeframe using swing structure sequence transitions.
    // Coordinated multi-timeframe correlation is handled at the CMNSContext level.
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

    // Calculate and update confidence score dynamically (OPEN-008)
    double score = CalculateConfidenceScore(detector, currentAtr);
    m_state.version = (uint)MathRound(score);

    m_lastProcessedExternalCount = extCount;
    m_lastProcessedInternalCount = intCount;

    return true;
}

//+------------------------------------------------------------------+
//| Calculate dynamic 0-100 multi-factor structure confidence score   |
//| Source: kennystrategy2.md Section 1.7                            |
//+------------------------------------------------------------------+
double CStructureEngine::CalculateConfidenceScore(const CSwingDetector &detector, double atrValue) const
{
    double score = 0.0;

    // 1. External structure direction (25 points)
    if (m_state.trend == TREND_BULLISH || m_state.trend == TREND_BEARISH)
        score += 25.0;
    else if (m_state.trend == TREND_TRANSITION || m_state.trend == TREND_RANGING)
        score += 12.5;

    // 2. Latest confirmed BOS alignment (20 points)
    if (m_bosAlign == ALIGN_ALIGNED)
        score += 20.0;
    else if (m_bosAlign == ALIGN_CONFLICT)
        score += 0.0;
    else // ALIGN_NEUTRAL (fallback to structure engine classification)
    {
        if (m_state.trend == TREND_BULLISH)
        {
            if (m_state.structureType == STRUCTURE_HH)
                score += 20.0;
            else if (m_state.structureType == STRUCTURE_LH || m_state.structureType == STRUCTURE_LL)
                score += 0.0;
            else
                score += 10.0;
        }
        else if (m_state.trend == TREND_BEARISH)
        {
            if (m_state.structureType == STRUCTURE_LL)
                score += 20.0;
            else if (m_state.structureType == STRUCTURE_HL || m_state.structureType == STRUCTURE_HH)
                score += 0.0;
            else
                score += 10.0;
        }
        else
        {
            score += 10.0;
        }
    }

    // 3. Internal structure alignment (10 points)
    if (m_internalAlign == ALIGN_ALIGNED)
        score += 10.0;
    else if (m_internalAlign == ALIGN_CONFLICT)
        score += 0.0;
    else // ALIGN_NEUTRAL (fallback to dynamic internal trend scan)
    {
        int count = detector.GetInternalSwingCount();
        ENUM_MNS_TREND intTrend = TREND_UNKNOWN;
        if (count >= 2)
        {
            intTrend = DetermineTrendForLevel(detector, SWING_LEVEL_INTERNAL, atrValue);
        }
        
        if (m_state.trend == TREND_BULLISH)
        {
            if (intTrend == TREND_BULLISH)
                score += 10.0;
            else if (intTrend == TREND_BEARISH)
                score += 0.0;
            else
                score += 5.0;
        }
        else if (m_state.trend == TREND_BEARISH)
        {
            if (intTrend == TREND_BEARISH)
                score += 10.0;
            else if (intTrend == TREND_BULLISH)
                score += 0.0;
            else
                score += 5.0;
        }
        else
        {
            score += 5.0;
        }
    }

    // 4. Order-flow alignment (15 points)
    if (m_orderFlowAlign == ALIGN_ALIGNED)
        score += 15.0;
    else if (m_orderFlowAlign == ALIGN_NEUTRAL)
        score += 7.5;

    // 5. Displacement quality (10 points)
    if (m_displacementAlign == ALIGN_ALIGNED)
        score += 10.0;
    else if (m_displacementAlign == ALIGN_NEUTRAL)
        score += 5.0;

    // 6. MTF agreement (10 points)
    if (m_mtfAlign == ALIGN_ALIGNED)
        score += 10.0;
    else if (m_mtfAlign == ALIGN_NEUTRAL)
        score += 5.0;

    // 7. Active delivery alignment (5 points)
    if (m_deliveryAlign == ALIGN_ALIGNED)
        score += 5.0;
    else if (m_deliveryAlign == ALIGN_NEUTRAL)
        score += 2.5;

    // 8. DOL directional compatibility (5 points)
    if (m_dolAlign == ALIGN_ALIGNED)
        score += 5.0;
    else if (m_dolAlign == ALIGN_NEUTRAL)
        score += 2.5;

    return score;
}

//+------------------------------------------------------------------+
//| Get confidence score rating interpretation string                |
//| Source: kennystrategy2.md Section 1.7                            |
//+------------------------------------------------------------------+
string CStructureEngine::GetConfidenceInterpretation() const
{
    double score = GetConfidenceScore();
    if (score >= 90.0) return "Elite";
    if (score >= 80.0) return "Strong";
    if (score >= 70.0) return "Valid";
    if (score >= 60.0) return "Weak";
    return "No trade";
}

#endif // __MNS_STRUCTURE_ENGINE_MQH__
