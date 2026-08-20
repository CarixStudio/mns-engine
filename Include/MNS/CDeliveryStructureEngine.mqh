//+------------------------------------------------------------------+
//|                                     CDeliveryStructureEngine.mqh |
//|                              MNS Trading Engine — Module 006     |
//|                                                                  |
//| Purpose:                                                         |
//|   Consumes market structure, breaks, and order flow to identify  |
//|   and track the active price-delivery leg toward objectives.     |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Manage delivery leg lifecycle states.                        |
//|   - Detect close-based invalidations of the protected low/high.  |
//|   - Track wick-based mitigation tests of the origin.             |
//|   - Calculate leg progress percentage and confidence metrics.    |
//|                                                                  |
//| Non-Responsibilities:                                            |
//|   - No chart object drawing or rendering (deferred to Module 013).|
//|   - No order execution or risk sizing calculations.              |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_DELIVERY_STRUCTURE_ENGINE_MQH__
#define __MNS_DELIVERY_STRUCTURE_ENGINE_MQH__

#include "MNSTypes.mqh"
#include "CSwingDetector.mqh"
#include "CStructureEngine.mqh"
#include "CBreakDetector.mqh"
#include "COrderFlowEngine.mqh"
#include "MNSConfig.mqh"

//-------------------------------------------------------------------
/// @class CDeliveryStructureEngine
/// @brief Tracks the active price-delivery legs and progress metrics.
//-------------------------------------------------------------------
class CDeliveryStructureEngine
{
private:
    bool                m_isInitialized;            ///< Initialization flag.
    SDeliveryState      m_state;                    ///< Current active state.
    int                 m_lastProcessedBreakCount;  ///< Break count watermark.

    // Private helper methods
    void                UpdateMetrics(const CStructureEngine &structureEngine, const CBreakDetector &breakDetector, const double &high[], const double &low[], const double &close[], const double &open[], const datetime &time[], int ratesTotal, double currentAtr);
    bool                FindLatestSwingBefore(const CSwingDetector &detector, datetime limitTime, ESwingType type, SSwingPoint &outSwing) const;

public:
    //+------------------------------------------------------------------+
    //| Constructor                                                      |
    //+------------------------------------------------------------------+
    CDeliveryStructureEngine()
        : m_isInitialized(false),
          m_lastProcessedBreakCount(0)
    {
        m_state.Reset();
    }

    //+------------------------------------------------------------------+
    //| Destructor                                                       |
    //+------------------------------------------------------------------+
    ~CDeliveryStructureEngine() {}

    /// @brief Initializes the Delivery Structure Engine.
    /// @return True on success.
    bool Initialize()
    {
        m_state.Reset();
        m_lastProcessedBreakCount = 0;
        m_isInitialized = true;
        return true;
    }

    /// @brief Resets the engine state.
    void Reset()
    {
        m_state.Reset();
        m_lastProcessedBreakCount = 0;
    }

    /// @brief Evaluates new breaks and updates delivery leg state.
    /// @param swingDetector Confirmed swings database.
    /// @param structureEngine Confirmed market structure engine.
    /// @param breakDetector Confirmed structure breaks database.
    /// @param orderFlowEngine Confirmed active order flow engine.
    /// @param high price array
    /// @param low price array
    /// @param close price array
    /// @param open price array
    /// @param time array
    /// @param ratesTotal total elements in price arrays
    /// @param prevCalculated processed bars count
    /// @param currentAtr ATR value
    /// @param htfDolPrice (Optional) target objective price
    /// @return True if state changed.
    bool Update(const CSwingDetector &swingDetector,
                const CStructureEngine &structureEngine,
                const CBreakDetector &breakDetector,
                const COrderFlowEngine &orderFlowEngine,
                const double &high[],
                const double &low[],
                const double &close[],
                const double &open[],
                const datetime &time[],
                int ratesTotal,
                int prevCalculated,
                double currentAtr,
                double htfDolPrice = DBL_MAX);

    // Getters
    SDeliveryState      GetState() const { return m_state; }
    EDeliveryDirection  GetDirection() const { return m_state.direction; }
    EDeliveryLifecycle  GetLifecycle() const { return m_state.lifecycle; }
    double              GetConfidenceScore() const { return m_state.confidence; }
    
    // Explicit setters/overrides
    void OverrideObjective(double price) { m_state.currentObjective = price; }
};

//+------------------------------------------------------------------+
//| Updates active delivery state based on newly confirmed breaks    |
//+------------------------------------------------------------------+
bool CDeliveryStructureEngine::Update(const CSwingDetector &swingDetector,
                                    const CStructureEngine &structureEngine,
                                    const CBreakDetector &breakDetector,
                                    const COrderFlowEngine &orderFlowEngine,
                                    const double &high[],
                                    const double &low[],
                                    const double &close[],
                                    const double &open[],
                                    const datetime &time[],
                                    int ratesTotal,
                                    int prevCalculated,
                                    double currentAtr,
                                    double htfDolPrice)
{
    if (!m_isInitialized)
        return false;

    if (ratesTotal < 2)
        return false;

    bool stateChanged = false;
    double invalidationLevel = m_state.invalidationLevel;
    double minBreakDist = MathMax(2.0 * _Point, 0.10 * currentAtr);

    // --- 1. Evaluate Invalidation & Mitigation & Objective on Active Leg ---
    if (m_state.lifecycle == DELIVERY_ACTIVE || 
        m_state.lifecycle == DELIVERY_OBJECTIVE_REACHED || 
        m_state.lifecycle == DELIVERY_MITIGATED)
    {
        if (m_state.direction == DELIVERY_DIR_BULLISH)
        {
            // Close below protected low minus break distance triggers invalidation (Rule 3.4)
            if (close[1] < invalidationLevel - minBreakDist)
            {
                m_state.Reset();
                m_state.lifecycle = DELIVERY_INVALIDATED;
                m_state.direction = DELIVERY_DIR_NEUTRAL;
                m_state.lastUpdatedTime = time[1];
                m_lastProcessedBreakCount = breakDetector.GetBreakCount();
                UpdateMetrics(structureEngine, breakDetector, high, low, close, open, time, ratesTotal, currentAtr);
                return true;
            }
            
            // Wick low below or entering originating POI zone (protectedPrice) triggers mitigation
            double mitThreshold = (m_state.protectedPrice > 0.0) ? m_state.protectedPrice : invalidationLevel;
            if (m_state.lifecycle != DELIVERY_MITIGATED && low[1] <= mitThreshold)
            {
                m_state.lifecycle = DELIVERY_MITIGATED;
                m_state.lastUpdatedTime = time[1];
                stateChanged = true;
            }

            // High price touches objective triggers objective reached
            if (m_state.lifecycle != DELIVERY_OBJECTIVE_REACHED && high[1] >= m_state.currentObjective)
            {
                m_state.lifecycle = DELIVERY_OBJECTIVE_REACHED;
                m_state.lastUpdatedTime = time[1];
                stateChanged = true;
            }
        }
        else if (m_state.direction == DELIVERY_DIR_BEARISH)
        {
            // Close above protected high plus break distance triggers invalidation (Rule 3.4)
            if (close[1] > invalidationLevel + minBreakDist)
            {
                m_state.Reset();
                m_state.lifecycle = DELIVERY_INVALIDATED;
                m_state.direction = DELIVERY_DIR_NEUTRAL;
                m_state.lastUpdatedTime = time[1];
                m_lastProcessedBreakCount = breakDetector.GetBreakCount();
                UpdateMetrics(structureEngine, breakDetector, high, low, close, open, time, ratesTotal, currentAtr);
                return true;
            }
            
            // Wick high above or entering originating POI zone (protectedPrice) triggers mitigation
            double mitThreshold = (m_state.protectedPrice > 0.0) ? m_state.protectedPrice : invalidationLevel;
            if (m_state.lifecycle != DELIVERY_MITIGATED && high[1] >= mitThreshold)
            {
                m_state.lifecycle = DELIVERY_MITIGATED;
                m_state.lastUpdatedTime = time[1];
                stateChanged = true;
            }

            // Low price touches objective triggers objective reached
            if (m_state.lifecycle != DELIVERY_OBJECTIVE_REACHED && low[1] <= m_state.currentObjective)
            {
                m_state.lifecycle = DELIVERY_OBJECTIVE_REACHED;
                m_state.lastUpdatedTime = time[1];
                stateChanged = true;
            }
        }
    }

    // --- 2. Process New Breaks Chronologically ---
    int breakCount = breakDetector.GetBreakCount();
    for (int i = m_lastProcessedBreakCount; i < breakCount; i++)
    {
        SStructureBreak sb = breakDetector.GetBreak(i);
        if (!sb.isConfirmed)
            continue;

        if (sb.breakType == BREAK_BOS)
        {
            if (sb.brokenSwing.type == SWING_HIGH) // Bullish BOS
            {
                if (structureEngine.IsBullish() && orderFlowEngine.IsBullish() && sb.strength > STRENGTH_WEAK)
                {
                    // If we have an active bullish leg running, it is replaced by this newer leg (if it breaks a new swing level)
                    if (m_state.direction == DELIVERY_DIR_BULLISH && 
                        (m_state.lifecycle == DELIVERY_ACTIVE || m_state.lifecycle == DELIVERY_OBJECTIVE_REACHED || m_state.lifecycle == DELIVERY_MITIGATED))
                    {
                        if (sb.brokenSwing.time == m_state.associatedPoiId)
                        {
                            // Skip duplicate replacement of the same swing level
                            continue;
                        }
                        m_state.lifecycle = DELIVERY_REPLACED;
                    }

                    SSwingPoint prevLow;
                    if (FindLatestSwingBefore(swingDetector, sb.time, SWING_LOW, prevLow))
                    {
                        m_state.direction = DELIVERY_DIR_BULLISH;
                        m_state.lifecycle = DELIVERY_ACTIVE;
                        m_state.originPrice = prevLow.price;
                        m_state.originTime = prevLow.time;
                        
                        // Find the index of the swing time in the chart arrays to estimate originating zone
                        int originIdx = -1;
                        for (int j = 0; j < ratesTotal; j++)
                        {
                            if (time[j] == prevLow.time)
                            {
                                originIdx = j;
                                break;
                            }
                        }
                        if (originIdx != -1)
                        {
                            int targetIdx = originIdx;
                            for (int k = 0; k < 4; k++)
                            {
                                int idx = originIdx - k;
                                if (idx >= 0 && close[idx] < open[idx])
                                {
                                    targetIdx = idx;
                                    break;
                                }
                            }
                            m_state.protectedPrice = MathMax(open[targetIdx], close[targetIdx]);
                        }
                        else
                        {
                            m_state.protectedPrice = prevLow.price;
                        }

                        m_state.invalidationLevel = prevLow.price;
                        m_state.associatedBosId = sb.time;
                        m_state.associatedDisplacementId = sb.time;
                        // Store the broken swing's creation time to prevent duplicate replacement of same swing level
                        m_state.associatedPoiId = sb.brokenSwing.time;
                        
                        // Set Objective (DOL) fallback
                        if (htfDolPrice != DBL_MAX && htfDolPrice != MNS_INVALID_PRICE)
                        {
                            m_state.currentObjective = htfDolPrice;
                        }
                        else
                        {
                            SSwingPoint prevHigh;
                            if (FindLatestSwingBefore(swingDetector, sb.time, SWING_HIGH, prevHigh))
                                m_state.currentObjective = prevHigh.price;
                            else
                                m_state.currentObjective = sb.brokenSwing.price;
                        }

                        m_state.lastUpdatedTime = sb.time;
                        stateChanged = true;
                    }
                }
            }
            else if (sb.brokenSwing.type == SWING_LOW) // Bearish BOS
            {
                if (structureEngine.IsBearish() && orderFlowEngine.IsBearish() && sb.strength > STRENGTH_WEAK)
                {
                    // If we have an active bearish leg running, it is replaced by this newer leg
                    if (m_state.direction == DELIVERY_DIR_BEARISH && 
                        (m_state.lifecycle == DELIVERY_ACTIVE || m_state.lifecycle == DELIVERY_OBJECTIVE_REACHED || m_state.lifecycle == DELIVERY_MITIGATED))
                    {
                        if (sb.brokenSwing.time == m_state.associatedPoiId)
                        {
                            // Skip duplicate replacement of the same swing level
                            continue;
                        }
                        m_state.lifecycle = DELIVERY_REPLACED;
                    }

                    SSwingPoint prevHigh;
                    if (FindLatestSwingBefore(swingDetector, sb.time, SWING_HIGH, prevHigh))
                    {
                        m_state.direction = DELIVERY_DIR_BEARISH;
                        m_state.lifecycle = DELIVERY_ACTIVE;
                        m_state.originPrice = prevHigh.price;
                        m_state.originTime = prevHigh.time;
                        
                        // Find the index of the swing time in the chart arrays to estimate originating zone
                        int originIdx = -1;
                        for (int j = 0; j < ratesTotal; j++)
                        {
                            if (time[j] == prevHigh.time)
                            {
                                originIdx = j;
                                break;
                            }
                        }
                        if (originIdx != -1)
                        {
                            int targetIdx = originIdx;
                            for (int k = 0; k < 4; k++)
                            {
                                int idx = originIdx - k;
                                if (idx >= 0 && close[idx] > open[idx])
                                {
                                    targetIdx = idx;
                                    break;
                                }
                            }
                            m_state.protectedPrice = MathMin(open[targetIdx], close[targetIdx]);
                        }
                        else
                        {
                            m_state.protectedPrice = prevHigh.price;
                        }

                        m_state.invalidationLevel = prevHigh.price;
                        m_state.associatedBosId = sb.time;
                        m_state.associatedDisplacementId = sb.time;
                        // Store the broken swing's creation time to prevent duplicate replacement of same swing level
                        m_state.associatedPoiId = sb.brokenSwing.time;
                        
                        // Set Objective (DOL) fallback
                        if (htfDolPrice != DBL_MAX && htfDolPrice != MNS_INVALID_PRICE)
                        {
                            m_state.currentObjective = htfDolPrice;
                        }
                        else
                        {
                            SSwingPoint prevLow;
                            if (FindLatestSwingBefore(swingDetector, sb.time, SWING_LOW, prevLow))
                                m_state.currentObjective = prevLow.price;
                            else
                                m_state.currentObjective = sb.brokenSwing.price;
                        }

                        m_state.lastUpdatedTime = sb.time;
                        stateChanged = true;
                    }
                }
            }
        }
        else if (sb.breakType == BREAK_CHOCH)
        {
            // Reverse CHoCH triggers archival of opposite direction leg
            if (sb.brokenSwing.type == SWING_LOW && m_state.direction == DELIVERY_DIR_BULLISH)
            {
                if (m_state.lifecycle == DELIVERY_ACTIVE || m_state.lifecycle == DELIVERY_OBJECTIVE_REACHED || m_state.lifecycle == DELIVERY_MITIGATED)
                {
                    m_state.lifecycle = DELIVERY_ARCHIVED;
                    m_state.direction = DELIVERY_DIR_NEUTRAL;
                    m_state.lastUpdatedTime = sb.time;
                    stateChanged = true;
                }
            }
            else if (sb.brokenSwing.type == SWING_HIGH && m_state.direction == DELIVERY_DIR_BEARISH)
            {
                if (m_state.lifecycle == DELIVERY_ACTIVE || m_state.lifecycle == DELIVERY_OBJECTIVE_REACHED || m_state.lifecycle == DELIVERY_MITIGATED)
                {
                    m_state.lifecycle = DELIVERY_ARCHIVED;
                    m_state.direction = DELIVERY_DIR_NEUTRAL;
                    m_state.lastUpdatedTime = sb.time;
                    stateChanged = true;
                }
            }
        }
    }
    m_lastProcessedBreakCount = breakCount;

    // --- 3. Compute Metrics & Confidence ---
    UpdateMetrics(structureEngine, breakDetector, high, low, close, open, time, ratesTotal, currentAtr);

    return stateChanged;
}

//+------------------------------------------------------------------+
//| Scans swing history to find latest swing of type before limitTime|
//+------------------------------------------------------------------+
bool CDeliveryStructureEngine::FindLatestSwingBefore(const CSwingDetector &detector, datetime limitTime, ESwingType type, SSwingPoint &outSwing) const
{
    outSwing.Reset();
    int count = detector.GetExternalSwingCount();
    
    // Scan backwards from newest confirmed swings
    for (int j = count - 1; j >= 0; j--)
    {
        SSwingPoint sw = detector.GetExternalSwing(j);
        if (sw.isConfirmed && sw.type == type && sw.time < limitTime)
        {
            outSwing = sw;
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Recalculates metrics: progress % and confidence score            |
//+------------------------------------------------------------------+
void CDeliveryStructureEngine::UpdateMetrics(
    const CStructureEngine &structureEngine,
    const CBreakDetector &breakDetector,
    const double &high[],
    const double &low[],
    const double &close[],
    const double &open[],
    const datetime &time[],
    int ratesTotal,
    double currentAtr)
{
    if (m_state.direction == DELIVERY_DIR_NEUTRAL)
    {
        m_state.progressPercent = 0.0;
        if (m_state.lifecycle != DELIVERY_INVALIDATED)
            m_state.confidence = 0.0;
        return;
    }

    // 1. Calculate Progress %
    double span = MathAbs(m_state.currentObjective - m_state.originPrice);
    if (span > 0.0)
    {
        double currentProgress = 0.0;
        if (m_state.direction == DELIVERY_DIR_BULLISH)
            currentProgress = close[1] - m_state.originPrice;
        else
            currentProgress = m_state.originPrice - close[1];

        double pct = (currentProgress / span) * 100.0;
        if (pct < 0.0) pct = 0.0;
        if (pct > 100.0) pct = 100.0;
        
        m_state.progressPercent = pct;
    }
    else
    {
        m_state.progressPercent = 0.0;
    }

    if (m_state.lifecycle == DELIVERY_OBJECTIVE_REACHED)
    {
        m_state.progressPercent = 100.0;
    }

    // 2. Calculate Confidence Score (0 to 100)
    if (m_state.lifecycle == DELIVERY_CANDIDATE)
    {
        m_state.confidence = 30.0;
    }
    else if (m_state.lifecycle == DELIVERY_ACTIVE || 
             m_state.lifecycle == DELIVERY_OBJECTIVE_REACHED || 
             m_state.lifecycle == DELIVERY_MITIGATED)
    {
        double score = 50.0; // Base score for active delivery leg

        // Booster 1: Order Flow bias alignment
        if (m_state.direction == DELIVERY_DIR_BULLISH && structureEngine.IsBullish())
            score += 15.0;
        else if (m_state.direction == DELIVERY_DIR_BEARISH && structureEngine.IsBearish())
            score += 15.0;

        // Booster 2: Strong confirming BOS breakout strength
        SStructureBreak latestBOS = breakDetector.GetLatestBOS();
        if (latestBOS.isConfirmed && latestBOS.breakType == BREAK_BOS && latestBOS.time == m_state.associatedBosId)
        {
            if (latestBOS.strength == STRENGTH_VERY_STRONG)
                score += 15.0;
            else if (latestBOS.strength == STRENGTH_STRONG)
                score += 10.0;
        }

        // Booster 3: Order flow engine confidence score is solid
        // Re-use order flow engine strength
        score += 20.0; // Assume order flow filter satisfied since updated active

        if (score > 100.0) score = 100.0;
        m_state.confidence = score;
    }
    else if (m_state.lifecycle == DELIVERY_INVALIDATED)
    {
        m_state.confidence = 0.0;
    }
}

#endif // __MNS_DELIVERY_STRUCTURE_ENGINE_MQH__
