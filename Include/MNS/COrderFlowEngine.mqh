//+------------------------------------------------------------------+
//|                                             COrderFlowEngine.mqh |
//|                              MNS Trading Engine — Module 005     |
//|                                                                  |
//| Purpose:                                                         |
//|   Consumes market structure and breaks to track directional      |
//|   order flow state-machine transitions and alignment scores.     |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Evaluate and track EOrderFlowState state changes.            |
//|   - Dynamically identify protected swing low/high boundaries.    |
//|   - Perform defensive intact validation checks.                  |
//|   - Calculate order flow confidence score and strengths.        |
//|                                                                  |
//| Non-Responsibilities:                                            |
//|   - No chart object drawing or rendering (deferred to Module 013).|
//|   - No order execution or risk sizing calculations.              |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_ORDER_FLOW_ENGINE_MQH__
#define __MNS_ORDER_FLOW_ENGINE_MQH__

#include "MNSTypes.mqh"
#include "CSwingDetector.mqh"
#include "CStructureEngine.mqh"
#include "CBreakDetector.mqh"
#include "MNSConfig.mqh"

//-------------------------------------------------------------------
/// @class COrderFlowEngine
/// @brief Analyzes market breaks to determine the active order flow.
//-------------------------------------------------------------------
class COrderFlowEngine
{
private:
    bool            m_isInitialized;           ///< Initialization flag.
    SOrderFlowState m_state;                   ///< Current active state.
    int             m_lastProcessedBreakCount; ///< Break count watermark.

    // Private helper methods
    void UpdateStrengthsAndConfidence(const CStructureEngine &structureEngine, const CBreakDetector &breakDetector, const double &high[], const double &low[], const double &close[], const double &open[], const datetime &time[], int ratesTotal, double currentAtr);
    bool FindLatestSwingBefore(const CSwingDetector &detector, datetime limitTime, ESwingType type, SSwingPoint &outSwing) const;

public:
    //+------------------------------------------------------------------+
    //| Constructor                                                      |
    //+------------------------------------------------------------------+
    COrderFlowEngine()
        : m_isInitialized(false),
          m_lastProcessedBreakCount(0)
    {
        m_state.Reset();
    }

    //+------------------------------------------------------------------+
    //| Destructor                                                       |
    //+------------------------------------------------------------------+
    ~COrderFlowEngine() {}

    /// @brief Initializes the Order Flow Engine.
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

    /// @brief Evaluates new breaks and updates order flow state.
    /// @param swingDetector Swings database reference.
    /// @param structureEngine Structure engine reference.
    /// @param breakDetector Break detector reference.
    /// @param high Bar high prices.
    /// @param low Bar low prices.
    /// @param close Bar close prices.
    /// @param open Bar open prices.
    /// @param time Bar times.
    /// @param ratesTotal Total bars on chart.
    /// @param prevCalculated Previously processed bars.
    /// @param currentAtr Current ATR value.
    /// @return True if order flow state changed.
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

    /// @brief Determines alignment state with structure trend.
    /// @param trend Current trend from structure engine.
    /// @return ALIGN_ALIGNED, ALIGN_NEUTRAL, or ALIGN_CONFLICT.
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

//+------------------------------------------------------------------+
//| Updates order flow state from newly confirmed breaks             |
//+------------------------------------------------------------------+
bool COrderFlowEngine::Update(const CSwingDetector &swingDetector, 
                            const CStructureEngine &structureEngine,
                            const CBreakDetector &breakDetector,
                            const double &high[],
                            const double &low[],
                            const double &close[],
                            const double &open[],
                            const datetime &time[],
                            int ratesTotal,
                            int prevCalculated,
                            double currentAtr)
{
    if (!m_isInitialized)
        return false;

    if (ratesTotal < 2)
        return false;

    int breakCount = breakDetector.GetBreakCount();
    bool stateChanged = false;

    if (breakCount == m_lastProcessedBreakCount)
    {
        // No new breaks. Perform defensive intact validation checks.
        bool wasModified = false;
        
        if (m_state.state == ORDER_FLOW_BULLISH && m_state.protectedSwingId != 0)
        {
            SSwingPoint protectedLow;
            if (FindLatestSwingBefore(swingDetector, m_state.lastUpdatedTime + 1, SWING_LOW, protectedLow))
            {
                if (protectedLow.time == m_state.protectedSwingId)
                {
                    double minBreakDistance = MathMax(2.0 * _Point, 0.10 * currentAtr);
                    if (close[1] < protectedLow.price - minBreakDistance)
                    {
                        m_state.Reset();
                        m_state.invalidated = true;
                        m_state.lastUpdatedTime = time[1];
                        wasModified = true;
                        stateChanged = true;
                    }
                }
            }
        }
        else if (m_state.state == ORDER_FLOW_BEARISH && m_state.protectedSwingId != 0)
        {
            SSwingPoint protectedHigh;
            if (FindLatestSwingBefore(swingDetector, m_state.lastUpdatedTime + 1, SWING_HIGH, protectedHigh))
            {
                if (protectedHigh.time == m_state.protectedSwingId)
                {
                    double minBreakDistance = MathMax(2.0 * _Point, 0.10 * currentAtr);
                    if (close[1] > protectedHigh.price + minBreakDistance)
                    {
                        m_state.Reset();
                        m_state.invalidated = true;
                        m_state.lastUpdatedTime = time[1];
                        wasModified = true;
                        stateChanged = true;
                    }
                }
            }
        }
        
        if (wasModified)
        {
            UpdateStrengthsAndConfidence(structureEngine, breakDetector, high, low, close, open, time, ratesTotal, currentAtr);
        }
        return wasModified;
    }

    // Process new breaks chronologically
    for (int i = m_lastProcessedBreakCount; i < breakCount; i++)
    {
        SStructureBreak sb = breakDetector.GetBreak(i);
        if (!sb.isConfirmed)
            continue;

        // 1. Process CHoCH transitions
        if (sb.breakType == BREAK_CHOCH)
        {
            if (sb.brokenSwing.type == SWING_LOW) // Bearish CHoCH breaks protected low
            {
                if (m_state.state == ORDER_FLOW_BULLISH || m_state.state == ORDER_FLOW_TRANSITION_BULLISH)
                {
                    m_state.previousDirection = m_state.direction;
                    m_state.direction = ORDER_FLOW_DIR_NEUTRAL;
                    m_state.state = ORDER_FLOW_TRANSITION_BEARISH;
                    m_state.lastCHoCHId = sb.time;
                    m_state.startTime = sb.time;
                    m_state.transition = true;
                    m_state.confirmed = false;
                    m_state.invalidated = false;
                    m_state.lastUpdatedTime = sb.time;
                    stateChanged = true;
                }
            }
            else if (sb.brokenSwing.type == SWING_HIGH) // Bullish CHoCH breaks protected high
            {
                if (m_state.state == ORDER_FLOW_BEARISH || m_state.state == ORDER_FLOW_TRANSITION_BEARISH)
                {
                    m_state.previousDirection = m_state.direction;
                    m_state.direction = ORDER_FLOW_DIR_NEUTRAL;
                    m_state.state = ORDER_FLOW_TRANSITION_BULLISH;
                    m_state.lastCHoCHId = sb.time;
                    m_state.startTime = sb.time;
                    m_state.transition = true;
                    m_state.confirmed = false;
                    m_state.invalidated = false;
                    m_state.lastUpdatedTime = sb.time;
                    stateChanged = true;
                }
            }
        }
        // 2. Process BOS structural breaks
        else if (sb.breakType == BREAK_BOS)
        {
            if (sb.brokenSwing.type == SWING_HIGH) // Bullish BOS
            {
                // Must be a displacement break (Rule 2.1)
                if (sb.strength > STRENGTH_WEAK)
                {
                    bool eligible = false;
                    if (m_state.state == ORDER_FLOW_NEUTRAL)
                    {
                        eligible = true;
                    }
                    else if (m_state.state == ORDER_FLOW_BULLISH)
                    {
                        eligible = true;
                    }
                    else if (m_state.state == ORDER_FLOW_TRANSITION_BULLISH)
                    {
                        // Enforce continuation swing validation (OPEN-012)
                        if (sb.brokenSwing.time >= m_state.startTime)
                            eligible = true;
                    }

                    if (eligible)
                    {
                        m_state.direction = ORDER_FLOW_DIR_BULLISH;
                        m_state.state = ORDER_FLOW_BULLISH;
                        m_state.lastBOSId = sb.time;
                        m_state.displacementId = sb.time;
                        m_state.confirmed = true;
                        m_state.transition = false;
                        m_state.invalidated = false;
                        
                        // Set origin and protected swings to the latest swing low before this BOS
                        SSwingPoint prevLow;
                        if (FindLatestSwingBefore(swingDetector, sb.time, SWING_LOW, prevLow))
                        {
                            m_state.originSwingId = prevLow.time;
                            m_state.protectedSwingId = prevLow.time;
                        }
                        
                        m_state.lastUpdatedTime = sb.time;
                        stateChanged = true;
                    }
                }
            }
            else if (sb.brokenSwing.type == SWING_LOW) // Bearish BOS
            {
                // Must be a displacement break (Rule 2.1)
                if (sb.strength > STRENGTH_WEAK)
                {
                    bool eligible = false;
                    if (m_state.state == ORDER_FLOW_NEUTRAL)
                    {
                        eligible = true;
                    }
                    else if (m_state.state == ORDER_FLOW_BEARISH)
                    {
                        eligible = true;
                    }
                    else if (m_state.state == ORDER_FLOW_TRANSITION_BEARISH)
                    {
                        // Enforce continuation swing validation (OPEN-012)
                        if (sb.brokenSwing.time >= m_state.startTime)
                            eligible = true;
                    }

                    if (eligible)
                    {
                        m_state.direction = ORDER_FLOW_DIR_BEARISH;
                        m_state.state = ORDER_FLOW_BEARISH;
                        m_state.lastBOSId = sb.time;
                        m_state.displacementId = sb.time;
                        m_state.confirmed = true;
                        m_state.transition = false;
                        m_state.invalidated = false;
                        
                        // Set origin and protected swings to the latest swing high before this BOS
                        SSwingPoint prevHigh;
                        if (FindLatestSwingBefore(swingDetector, sb.time, SWING_HIGH, prevHigh))
                        {
                            m_state.originSwingId = prevHigh.time;
                            m_state.protectedSwingId = prevHigh.time;
                        }
                        
                        m_state.lastUpdatedTime = sb.time;
                        stateChanged = true;
                    }
                }
            }
        }
    }

    m_lastProcessedBreakCount = breakCount;

    // After processing breaks, verify if the new protected swing was subsequently broken on index 1
    if (m_state.state == ORDER_FLOW_BULLISH && m_state.protectedSwingId != 0)
    {
        SSwingPoint protectedLow;
        if (FindLatestSwingBefore(swingDetector, m_state.lastUpdatedTime + 1, SWING_LOW, protectedLow))
        {
            if (protectedLow.time == m_state.protectedSwingId)
            {
                double minBreakDistance = MathMax(2.0 * _Point, 0.10 * currentAtr);
                if (close[1] < protectedLow.price - minBreakDistance)
                {
                    m_state.Reset();
                    m_state.invalidated = true;
                    m_state.lastUpdatedTime = time[1];
                    stateChanged = true;
                }
            }
        }
    }
    else if (m_state.state == ORDER_FLOW_BEARISH && m_state.protectedSwingId != 0)
    {
        SSwingPoint protectedHigh;
        if (FindLatestSwingBefore(swingDetector, m_state.lastUpdatedTime + 1, SWING_HIGH, protectedHigh))
        {
            if (protectedHigh.time == m_state.protectedSwingId)
            {
                double minBreakDistance = MathMax(2.0 * _Point, 0.10 * currentAtr);
                if (close[1] > protectedHigh.price + minBreakDistance)
                {
                    m_state.Reset();
                    m_state.invalidated = true;
                    m_state.lastUpdatedTime = time[1];
                    stateChanged = true;
                }
            }
        }
    }

    // Calculate updated metrics
    UpdateStrengthsAndConfidence(structureEngine, breakDetector, high, low, close, open, time, ratesTotal, currentAtr);

    return stateChanged;
}

//+------------------------------------------------------------------+
//| Scans swing history to find latest swing of type before limitTime|
//+------------------------------------------------------------------+
bool COrderFlowEngine::FindLatestSwingBefore(const CSwingDetector &detector, datetime limitTime, ESwingType type, SSwingPoint &outSwing) const
{
    outSwing.Reset();
    int count = detector.GetExternalSwingCount();
    
    // Scan backwards from newest confirmed swings (largest indices)
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
//| Recalculates metrics: strengths and alignment confidence score  |
//+------------------------------------------------------------------+
void COrderFlowEngine::UpdateStrengthsAndConfidence(
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
    m_state.bullishStrength = 0.0;
    m_state.bearishStrength = 0.0;
    m_state.confidenceScore = 0.0;

    if (m_state.state == ORDER_FLOW_NEUTRAL)
        return;

    // 1. Calculate Strength: find largest displacement candle in active direction in last 20 bars
    int scanCount = MathMin(20, ratesTotal - 2); // Exclude live bar 0 and require at least closed bars
    SEngineConfig config = CMNSConfig::GetActive();
    
    for (int j = 1; j <= scanCount; j++)
    {
        double range = high[j] - low[j];
        if (range <= 0.0 || currentAtr <= 0.0) continue;
        
        double body = MathAbs(close[j] - open[j]);
        double bodyRatio = body / range;
        
        bool isBullishCandle = (close[j] > open[j]);
        double closeStrength = 0.0;
        if (isBullishCandle)
            closeStrength = (close[j] - low[j]) / range;
        else
            closeStrength = (high[j] - close[j]) / range;

        // Apply strict strategy-defined displacement thresholds
        bool isDisplaced = (bodyRatio >= config.displacementMinBodyRatio) && 
                           (closeStrength >= config.displacementMinCloseStrength) &&
                           (range >= config.displacementMinAtrMultiple * currentAtr);
                           
        if (isDisplaced)
        {
            double str = range / currentAtr;
            if (isBullishCandle && (m_state.state == ORDER_FLOW_BULLISH || m_state.state == ORDER_FLOW_TRANSITION_BULLISH))
            {
                if (str > m_state.bullishStrength)
                    m_state.bullishStrength = str;
            }
            else if (!isBullishCandle && (m_state.state == ORDER_FLOW_BEARISH || m_state.state == ORDER_FLOW_TRANSITION_BEARISH))
            {
                if (str > m_state.bearishStrength)
                    m_state.bearishStrength = str;
            }
        }
    }

    // 2. Calculate Confidence Score (0 to 100) (OPEN-011)
    if (m_state.transition)
    {
        m_state.confidenceScore = 40.0;
    }
    else if (m_state.confirmed)
    {
        double score = 70.0; // Base score

        // Add score booster based on the latest BOS strength
        SStructureBreak latestBOS = breakDetector.GetLatestBOS();
        if (latestBOS.isConfirmed && latestBOS.breakType == BREAK_BOS)
        {
            if (latestBOS.strength == STRENGTH_VERY_STRONG)
                score += 20.0;
            else if (latestBOS.strength == STRENGTH_STRONG)
                score += 10.0;
        }

        // Add score booster for internal structural trend alignment
        if (m_state.state == ORDER_FLOW_BULLISH && structureEngine.IsBullish())
            score += 10.0;
        else if (m_state.state == ORDER_FLOW_BEARISH && structureEngine.IsBearish())
            score += 10.0;

        m_state.confidenceScore = score;
    }
}

#endif // __MNS_ORDER_FLOW_ENGINE_MQH__
