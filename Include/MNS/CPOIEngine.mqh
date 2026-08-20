//+------------------------------------------------------------------+
//|                                                  CPOIEngine.mqh  |
//|                              MNS Trading Engine — Module 008     |
//|                                                                  |
//| Purpose:                                                         |
//|   Identifies, tracks, and ranks Points of Interest (Order Blocks,|
//|   Breaker Blocks, Mitigation Blocks, Fair Value Gaps, and        |
//|   dealing range zones) without using broker API series calls.    |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_POI_ENGINE_MQH__
#define __MNS_POI_ENGINE_MQH__

#include "MNSTypes.mqh"
#include "CSwingDetector.mqh"
#include "CStructureEngine.mqh"
#include "CBreakDetector.mqh"
#include "CLiquidityEngine.mqh"
#include "CDeliveryStructureEngine.mqh"
#include "MNSConfig.mqh"
#include "MNSUtils.mqh"
#include "MNSVolatility.mqh"
#include "MNSLogger.mqh"

//-------------------------------------------------------------------
/// @class CPOIEngine
/// @brief Detects and ranks Points of Interest (OB, Breaker, MB, FVG).
//-------------------------------------------------------------------
class CPOIEngine
{
private:
    bool                m_isInitialized;            ///< Lifecycle initialization watermark.
    SPoIDefinition      m_pois[128];                ///< Fixed-size array of tracked POIs.
    int                 m_poisCount;                ///< Total number of tracked POIs.
    int                 m_lastProcessedBreakCount;  ///< Break count watermark.

    // Private helper methods
    void                DetectFVGs(const double &high[], const double &low[], const double &close[], const double &open[], const datetime &time[], int ratesTotal, int prevCalculated, double currentAtr);
    void                DetectOBs(const CSwingDetector &swingDetector, const CBreakDetector &breakDetector, const double &high[], const double &low[], const double &close[], const double &open[], const datetime &time[], int ratesTotal, double currentAtr);
    void                DetectMitigationBlocks(const CSwingDetector &swingDetector, const CBreakDetector &breakDetector, const double &high[], const double &low[], const double &close[], const double &open[], const datetime &time[], int ratesTotal, double currentAtr);
    void                EvaluateFailsAndBreakers(const CBreakDetector &breakDetector, const double &close[], const datetime &time[]);
    void                UpdateLifecycles(const double &high[], const double &low[], const double &close[], const datetime &time[]);
    void                EvaluateConfluence();
    void                RankPOIs(const CSwingDetector &swingDetector,
                                 const CStructureEngine &structureEngine,
                                 const CBreakDetector &breakDetector,
                                 const CLiquidityEngine &liquidityEngine,
                                 const CDeliveryStructureEngine &deliveryEngine);
    int                 FindPOIIndexByPrice(double lower, double upper, EPoIType type) const;
    void                AddOrUpdatePOI(EPoIType type, double lower, double upper, double invalidation, datetime timeVal, int barIdx, double fillPct = 0.0);

public:
    // Lifecycle
    CPOIEngine();
    ~CPOIEngine();

    /// @brief Initializes engine variables.
    /// @return True on success.
    bool                Initialize();

    /// @brief Resets the engine state.
    void                Reset();

    /// @brief Evaluates price action and structural events to find and update POIs.
    /// @param swingDetector Confirmed swings database.
    /// @param structureEngine Market trend and phase database.
    /// @param breakDetector Confirmed structural breaks database.
    /// @param liquidityEngine Tracked liquidity pools.
    /// @param deliveryEngine Active delivery structure engine.
    /// @param high price array
    /// @param low price array
    /// @param close price array
    /// @param open price array
    /// @param time array
    /// @param ratesTotal total elements in price arrays
    /// @param prevCalculated processed bars count
    /// @param currentAtr ATR value
    /// @return True if state changed.
    bool                Update(const CSwingDetector &swingDetector,
                               const CStructureEngine &structureEngine,
                               const CBreakDetector &breakDetector,
                               const CLiquidityEngine &liquidityEngine,
                               const CDeliveryStructureEngine &deliveryEngine,
                               const double &high[],
                               const double &low[],
                               const double &close[],
                               const double &open[],
                               const datetime &time[],
                               int ratesTotal,
                               int prevCalculated,
                               double currentAtr);

    // Query Methods
    int                 GetPoIsCount() const { return m_poisCount; }
    
    /// @brief Gets a POI by index.
    /// @param index POI index.
    /// @param outPoi Structure output by reference.
    /// @return True if index is valid.
    bool                GetPoI(int index, SPoIDefinition &outPoi) const;

    /// @brief Returns the nearest active bullish POI.
    /// @param currentPrice Current price.
    /// @param outPoi POI structure reference output.
    /// @return True if found.
    bool                GetNearestBullishPOI(double currentPrice, SPoIDefinition &outPoi) const;

    /// @brief Returns the nearest active bearish POI.
    /// @param currentPrice Current price.
    /// @param outPoi POI structure reference output.
    /// @return True if found.
    bool                GetNearestBearishPOI(double currentPrice, SPoIDefinition &outPoi) const;

    /// @brief Returns the Equilibrium price level of the dealing range.
    /// @param swingDetector Confirmed swings database.
    /// @return Equilibrium price level, or 0.0 if not established.
    double              GetEquilibrium(const CSwingDetector &swingDetector) const;

    /// @brief Classifies a price level as Premium, Discount, or Equilibrium.
    /// @param price The price level to evaluate.
    /// @param swingDetector Confirmed swings database.
    /// @return Zone classification (ZONE_EQUILIBRIUM, ZONE_PREMIUM, ZONE_DISCOUNT).
    EDealingRangeZone   GetDealingRangeZone(double price, const CSwingDetector &swingDetector) const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPOIEngine::CPOIEngine()
    : m_isInitialized(false),
      m_poisCount(0),
      m_lastProcessedBreakCount(0)
{
    Reset();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPOIEngine::~CPOIEngine()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CPOIEngine::Initialize()
{
    Reset();
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Reset                                                            |
//+------------------------------------------------------------------+
void CPOIEngine::Reset()
{
    m_poisCount = 0;
    m_lastProcessedBreakCount = 0;
    for (int i = 0; i < 128; i++)
        m_pois[i].Reset();
}

//+------------------------------------------------------------------+
//| Update                                                           |
//+------------------------------------------------------------------+
bool CPOIEngine::Update(const CSwingDetector &swingDetector,
                        const CStructureEngine &structureEngine,
                        const CBreakDetector &breakDetector,
                        const CLiquidityEngine &liquidityEngine,
                        const CDeliveryStructureEngine &deliveryEngine,
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

    if (ratesTotal < 5)
        return false;

    // 1. Scan for Fair Value Gaps (FVG)
    DetectFVGs(high, low, close, open, time, ratesTotal, prevCalculated, currentAtr);

    // 2. Scan for Order Blocks (OB)
    DetectOBs(swingDetector, breakDetector, high, low, close, open, time, ratesTotal, currentAtr);

    // 3. Scan for Mitigation Blocks (MB)
    DetectMitigationBlocks(swingDetector, breakDetector, high, low, close, open, time, ratesTotal, currentAtr);

    // 4. Evaluate failed OBs to convert to Breakers
    EvaluateFailsAndBreakers(breakDetector, close, time);

    // 5. Update active POI lifecycles (wick touch mitigation, close-based invalidation, FVG fills)
    UpdateLifecycles(high, low, close, time);

    // 6. Evaluate overlap and confluence
    EvaluateConfluence();

    // 7. Calculate quality scores and priority
    RankPOIs(swingDetector, structureEngine, breakDetector, liquidityEngine, deliveryEngine);

    return true;
}

//+------------------------------------------------------------------+
//| Detects Fair Value Gaps (FVGs)                                   |
//+------------------------------------------------------------------+
void CPOIEngine::DetectFVGs(const double &high[],
                            const double &low[],
                            const double &close[],
                            const double &open[],
                            const datetime &time[],
                            int ratesTotal,
                            int prevCalculated,
                            double currentAtr)
{
    // Need at least 3 bars to evaluate A-B-C sequence
    if (ratesTotal < 3)
        return;

    int startIndex = (prevCalculated == 0) ? (ratesTotal - 3) : (ratesTotal - 2);
    if (startIndex < 1) startIndex = 1;

    double minSize = MathMax(3.0 * _Point, 0.10 * currentAtr);

    // Index 0 (forming candle) is ignored. Scan ends at closed index 1.
    for (int i = startIndex; i >= 1; i--)
    {
        // Sequence: i+2 (A), i+1 (B), i (C)
        // Bullish FVG: Low[C] > High[A]
        if (low[i] > high[i + 2])
        {
            double gapSize = low[i] - high[i + 2];
            if (gapSize >= minSize)
            {
                AddOrUpdatePOI(POI_FVG_BULLISH, high[i + 2], low[i], high[i + 2], time[i + 1], i + 1, 0.0);
            }
        }
        // Bearish FVG: High[C] < Low[A]
        else if (high[i] < low[i + 2])
        {
            double gapSize = low[i + 2] - high[i];
            if (gapSize >= minSize)
            {
                AddOrUpdatePOI(POI_FVG_BEARISH, high[i], low[i + 2], low[i + 2], time[i + 1], i + 1, 0.0);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Detects Order Blocks (OBs) from confirmed BOS breaks            |
//+------------------------------------------------------------------+
void CPOIEngine::DetectOBs(const CSwingDetector &swingDetector,
                           const CBreakDetector &breakDetector,
                           const double &high[],
                           const double &low[],
                           const double &close[],
                           const double &open[],
                           const datetime &time[],
                           int ratesTotal,
                           double currentAtr)
{
    int breakCount = breakDetector.GetBreakCount();
    for (int i = m_lastProcessedBreakCount; i < breakCount; i++)
    {
        SStructureBreak sb = breakDetector.GetBreak(i);
        if (!sb.isConfirmed || sb.breakType != BREAK_BOS)
            continue;

        SEngineConfig config = CMNSConfig::GetActive();

        if (sb.brokenSwing.type == SWING_HIGH) // Bullish BOS
        {
            // Find latest confirmed external swing low before the BOS time
            SSwingPoint originLow;
            originLow.Reset();
            int extCount = swingDetector.GetExternalSwingCount();
            for (int j = extCount - 1; j >= 0; j--)
            {
                SSwingPoint sw = swingDetector.GetExternalSwing(j);
                if (sw.isConfirmed && sw.type == SWING_LOW && sw.time < sb.time)
                {
                    originLow = sw;
                    break;
                }
            }

            if (originLow.isConfirmed)
            {
                // Find first bullish displacement candle between originLow and sb.barIndex
                int dispBar = originLow.barIndex;
                for (int j = originLow.barIndex; j >= sb.barIndex; j--)
                {
                    if (j >= ratesTotal || j < 0) continue;
                    double range = high[j] - low[j];
                    if (range <= 0.0) continue;
                    double body = MathAbs(close[j] - open[j]);
                    double bodyRatio = body / range;
                    double closeStrength = (close[j] - low[j]) / range;

                    bool isDisplaced = (bodyRatio >= config.displacementMinBodyRatio) &&
                                       (closeStrength >= config.displacementMinCloseStrength) &&
                                       (range >= config.displacementMinAtrMultiple * currentAtr);
                    if (isDisplaced && close[j] > open[j])
                    {
                        dispBar = j;
                        break;
                    }
                }

                // Gather compact candle cluster preceding dispBar (max 3 bearish candles)
                int clusterStart = dispBar + 1;
                int clusterSize = 0;
                double lowestLow = DBL_MAX;
                double highestOpen = 0.0;

                for (int k = 0; k < 3; k++)
                {
                    int idx = clusterStart + k;
                    if (idx >= ratesTotal) break;
                    if (close[idx] < open[idx]) // Bearish candle
                    {
                        if (low[idx] < lowestLow) lowestLow = low[idx];
                        if (open[idx] > highestOpen) highestOpen = open[idx];
                        clusterSize++;
                    }
                    else
                    {
                        break;
                    }
                }

                if (clusterSize > 0 && lowestLow != DBL_MAX && highestOpen > 0.0)
                {
                    AddOrUpdatePOI(POI_OB_BULLISH, lowestLow, highestOpen, lowestLow, time[clusterStart], clusterStart);
                }
            }
        }
        else if (sb.brokenSwing.type == SWING_LOW) // Bearish BOS
        {
            // Find latest confirmed external swing high before the BOS time
            SSwingPoint originHigh;
            originHigh.Reset();
            int extCount = swingDetector.GetExternalSwingCount();
            for (int j = extCount - 1; j >= 0; j--)
            {
                SSwingPoint sw = swingDetector.GetExternalSwing(j);
                if (sw.isConfirmed && sw.type == SWING_HIGH && sw.time < sb.time)
                {
                    originHigh = sw;
                    break;
                }
            }

            if (originHigh.isConfirmed)
            {
                // Find first bearish displacement candle
                int dispBar = originHigh.barIndex;
                for (int j = originHigh.barIndex; j >= sb.barIndex; j--)
                {
                    if (j >= ratesTotal || j < 0) continue;
                    double range = high[j] - low[j];
                    if (range <= 0.0) continue;
                    double body = MathAbs(close[j] - open[j]);
                    double bodyRatio = body / range;
                    double closeStrength = (high[j] - close[j]) / range;

                    bool isDisplaced = (bodyRatio >= config.displacementMinBodyRatio) &&
                                       (closeStrength >= config.displacementMinCloseStrength) &&
                                       (range >= config.displacementMinAtrMultiple * currentAtr);
                    if (isDisplaced && close[j] < open[j])
                    {
                        dispBar = j;
                        break;
                    }
                }

                // Gather compact candle cluster preceding dispBar (max 3 bullish candles)
                int clusterStart = dispBar + 1;
                int clusterSize = 0;
                double highestHigh = 0.0;
                double lowestOpen = DBL_MAX;

                for (int k = 0; k < 3; k++)
                {
                    int idx = clusterStart + k;
                    if (idx >= ratesTotal) break;
                    if (close[idx] > open[idx]) // Bullish candle
                    {
                        if (high[idx] > highestHigh) highestHigh = high[idx];
                        if (open[idx] < lowestOpen) lowestOpen = open[idx];
                        clusterSize++;
                    }
                    else
                    {
                        break;
                    }
                }

                if (clusterSize > 0 && highestHigh > 0.0 && lowestOpen != DBL_MAX)
                {
                    AddOrUpdatePOI(POI_OB_BEARISH, lowestOpen, highestHigh, highestHigh, time[clusterStart], clusterStart);
                }
            }
        }
    }
    m_lastProcessedBreakCount = breakCount;
}

//+------------------------------------------------------------------+
//| Detects Mitigation Blocks (MBs) from confirmed BOS breaks       |
//+------------------------------------------------------------------+
void CPOIEngine::DetectMitigationBlocks(const CSwingDetector &swingDetector,
                                         const CBreakDetector &breakDetector,
                                         const double &high[],
                                         const double &low[],
                                         const double &close[],
                                         const double &open[],
                                         const datetime &time[],
                                         int ratesTotal,
                                         double currentAtr)
{
    // Mitigation Blocks are opposing candles in the leg that did NOT form the origin OB.
    // They are processed during BOS confirmations.
    int breakCount = breakDetector.GetBreakCount();
    for (int i = 0; i < breakCount; i++)
    {
        SStructureBreak sb = breakDetector.GetBreak(i);
        if (!sb.isConfirmed || sb.breakType != BREAK_BOS)
            continue;

        SEngineConfig config = CMNSConfig::GetActive();

        if (sb.brokenSwing.type == SWING_HIGH) // Bullish BOS
        {
            SSwingPoint originLow;
            originLow.Reset();
            int extCount = swingDetector.GetExternalSwingCount();
            for (int j = extCount - 1; j >= 0; j--)
            {
                SSwingPoint sw = swingDetector.GetExternalSwing(j);
                if (sw.isConfirmed && sw.type == SWING_LOW && sw.time < sb.time)
                {
                    originLow = sw;
                    break;
                }
            }

            if (originLow.isConfirmed)
            {
                // Scan intermediate candles between originLow and sb.barIndex
                // Excluding the candles closest to the origin (which represent the OB)
                for (int j = originLow.barIndex - 4; j >= sb.barIndex; j--)
                {
                    if (j + 1 >= ratesTotal || j < 0) continue;
                    // Check for opposing (bearish) candle followed by displacement
                    if (close[j + 1] < open[j + 1])
                    {
                        double range = high[j] - low[j];
                        if (range <= 0.0) continue;
                        double body = MathAbs(close[j] - open[j]);
                        double bodyRatio = body / range;
                        double closeStrength = (close[j] - low[j]) / range;

                        bool isDisplaced = (bodyRatio >= config.displacementMinBodyRatio) &&
                                           (closeStrength >= config.displacementMinCloseStrength) &&
                                           (range >= config.displacementMinAtrMultiple * currentAtr);
                        if (isDisplaced && close[j] > open[j])
                        {
                            // Add Mitigation Block
                            AddOrUpdatePOI(POI_MITIGATION_BULLISH, low[j + 1], open[j + 1], low[j + 1], time[j + 1], j + 1);
                        }
                    }
                }
            }
        }
        else if (sb.brokenSwing.type == SWING_LOW) // Bearish BOS
        {
            SSwingPoint originHigh;
            originHigh.Reset();
            int extCount = swingDetector.GetExternalSwingCount();
            for (int j = extCount - 1; j >= 0; j--)
            {
                SSwingPoint sw = swingDetector.GetExternalSwing(j);
                if (sw.isConfirmed && sw.type == SWING_HIGH && sw.time < sb.time)
                {
                    originHigh = sw;
                    break;
                }
            }

            if (originHigh.isConfirmed)
            {
                for (int j = originHigh.barIndex - 4; j >= sb.barIndex; j--)
                {
                    if (j + 1 >= ratesTotal || j < 0) continue;
                    if (close[j + 1] > open[j + 1]) // Opposing (bullish) candle
                    {
                        double range = high[j] - low[j];
                        if (range <= 0.0) continue;
                        double body = MathAbs(close[j] - open[j]);
                        double bodyRatio = body / range;
                        double closeStrength = (high[j] - close[j]) / range;

                        bool isDisplaced = (bodyRatio >= config.displacementMinBodyRatio) &&
                                           (closeStrength >= config.displacementMinCloseStrength) &&
                                           (range >= config.displacementMinAtrMultiple * currentAtr);
                        if (isDisplaced && close[j] < open[j])
                        {
                            // Add Mitigation Block
                            AddOrUpdatePOI(POI_MITIGATION_BEARISH, open[j + 1], high[j + 1], high[j + 1], time[j + 1], j + 1);
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Evaluates failed OBs to convert to Breaker Blocks                |
//+------------------------------------------------------------------+
void CPOIEngine::EvaluateFailsAndBreakers(const CBreakDetector &breakDetector,
                                           const double &close[],
                                           const datetime &time[])
{
    // If a confirmed opposite structural break exists (BOS or CHoCH)
    bool hasBullishBreak = breakDetector.HasBullishBOS() || breakDetector.HasBullishCHOCH();
    bool hasBearishBreak = breakDetector.HasBearishBOS() || breakDetector.HasBearishCHOCH();

    for (int k = 0; k < m_poisCount; k++)
    {
        if (!m_pois[k].active || m_pois[k].lifecycle == POI_STATE_INVALIDATED)
            continue;

        if (m_pois[k].type == POI_OB_BULLISH)
        {
            // Invalidated if close < invalidationLevel (low)
            if (close[1] < m_pois[k].invalidationLevel)
            {
                m_pois[k].active = false;
                m_pois[k].lifecycle = POI_STATE_INVALIDATED;
                m_pois[k].invalidatedTime = time[1];

                // Convert to Bearish Breaker if a bearish break was confirmed
                if (hasBearishBreak)
                {
                    AddOrUpdatePOI(POI_BREAKER_BEARISH, m_pois[k].lowerPrice, m_pois[k].upperPrice, m_pois[k].upperPrice, time[1], 1);
                }
            }
        }
        else if (m_pois[k].type == POI_OB_BEARISH)
        {
            // Invalidated if close > invalidationLevel (high)
            if (close[1] > m_pois[k].invalidationLevel)
            {
                m_pois[k].active = false;
                m_pois[k].lifecycle = POI_STATE_INVALIDATED;
                m_pois[k].invalidatedTime = time[1];

                // Convert to Bullish Breaker if a bullish break was confirmed
                if (hasBullishBreak)
                {
                    AddOrUpdatePOI(POI_BREAKER_BULLISH, m_pois[k].lowerPrice, m_pois[k].upperPrice, m_pois[k].lowerPrice, time[1], 1);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Updates active POI lifecycles                                    |
//+------------------------------------------------------------------+
void CPOIEngine::UpdateLifecycles(const double &high[],
                                  const double &low[],
                                  const double &close[],
                                  const datetime &time[])
{
    for (int k = 0; k < m_poisCount; k++)
    {
        if (!m_pois[k].active)
            continue;

        double upper = m_pois[k].upperPrice;
        double lower = m_pois[k].lowerPrice;
        double invalidation = m_pois[k].invalidationLevel;

        // FVG fill and mitigation logic
        if (m_pois[k].type == POI_FVG_BULLISH)
        {
            double gapSize = upper - lower;
            if (gapSize <= 0.0) continue;

            double penetration = 0.0;
            if (low[1] < upper)
                penetration = upper - MathMax(low[1], lower);

            double pct = (penetration / gapSize) * 100.0;
            if (pct > m_pois[k].fillPercent)
                m_pois[k].fillPercent = pct;

            // Invalidation check (100% filled, or close below lower boundary)
            if (m_pois[k].fillPercent >= 100.0 || close[1] < lower)
            {
                m_pois[k].active = false;
                m_pois[k].lifecycle = POI_STATE_FILLED;
                m_pois[k].invalidatedTime = time[1];
            }
            else if (m_pois[k].fillPercent >= 50.0)
            {
                m_pois[k].lifecycle = POI_STATE_MATERIAL_MITIGATED;
            }
            else if (m_pois[k].fillPercent > 0.0)
            {
                m_pois[k].lifecycle = POI_STATE_PARTIAL_MITIGATED;
            }
        }
        else if (m_pois[k].type == POI_FVG_BEARISH)
        {
            double gapSize = upper - lower;
            if (gapSize <= 0.0) continue;

            double penetration = 0.0;
            if (high[1] > lower)
                penetration = MathMin(high[1], upper) - lower;

            double pct = (penetration / gapSize) * 100.0;
            if (pct > m_pois[k].fillPercent)
                m_pois[k].fillPercent = pct;

            // Invalidation check (100% filled, or close above upper boundary)
            if (m_pois[k].fillPercent >= 100.0 || close[1] > upper)
            {
                m_pois[k].active = false;
                m_pois[k].lifecycle = POI_STATE_FILLED;
                m_pois[k].invalidatedTime = time[1];
            }
            else if (m_pois[k].fillPercent >= 50.0)
            {
                m_pois[k].lifecycle = POI_STATE_MATERIAL_MITIGATED;
            }
            else if (m_pois[k].fillPercent > 0.0)
            {
                m_pois[k].lifecycle = POI_STATE_PARTIAL_MITIGATED;
            }
        }
        // Blocks (OB, Breaker, Mitigation) mitigation and close-based invalidation
        else
        {
            bool isBullish = (m_pois[k].type == POI_OB_BULLISH ||
                              m_pois[k].type == POI_BREAKER_BULLISH ||
                              m_pois[k].type == POI_MITIGATION_BULLISH);

            // Invalidation
            if (isBullish)
            {
                if (close[1] < invalidation)
                {
                    m_pois[k].active = false;
                    m_pois[k].lifecycle = POI_STATE_INVALIDATED;
                    m_pois[k].invalidatedTime = time[1];
                    continue;
                }
            }
            else
            {
                if (close[1] > invalidation)
                {
                    m_pois[k].active = false;
                    m_pois[k].lifecycle = POI_STATE_INVALIDATED;
                    m_pois[k].invalidatedTime = time[1];
                    continue;
                }
            }

            // Wick Mitigation
            if (m_pois[k].lifecycle == POI_STATE_ACTIVE)
            {
                if (isBullish)
                {
                    if (low[1] <= upper) // touched top of bullish block
                    {
                        m_pois[k].lifecycle = POI_STATE_PARTIAL_MITIGATED;
                        m_pois[k].mitigatedTime = time[1];
                    }
                }
                else
                {
                    if (high[1] >= lower) // touched bottom of bearish block
                    {
                        m_pois[k].lifecycle = POI_STATE_PARTIAL_MITIGATED;
                        m_pois[k].mitigatedTime = time[1];
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Evaluates overlaps and confluence scores                         |
//+------------------------------------------------------------------+
void CPOIEngine::EvaluateConfluence()
{
    // Same type & direction merge rule: overlap >= 50% of the smaller POI
    for (int i = 0; i < m_poisCount; i++)
    {
        if (!m_pois[i].active)
            continue;

        for (int j = i + 1; j < m_poisCount; j++)
        {
            if (!m_pois[j].active)
                continue;

            // Check if same type and direction
            if (m_pois[i].type == m_pois[j].type)
            {
                double overlapLower = MathMax(m_pois[i].lowerPrice, m_pois[j].lowerPrice);
                double overlapUpper = MathMin(m_pois[i].upperPrice, m_pois[j].upperPrice);

                if (overlapLower < overlapUpper)
                {
                    double overlapSize = overlapUpper - overlapLower;
                    double sizeI = m_pois[i].upperPrice - m_pois[i].lowerPrice;
                    double sizeJ = m_pois[j].upperPrice - m_pois[j].lowerPrice;
                    double smallerSize = MathMin(sizeI, sizeJ);

                    if (smallerSize > 0.0 && (overlapSize / smallerSize) >= 0.50)
                    {
                        // Merge j into i
                        m_pois[i].lowerPrice = MathMin(m_pois[i].lowerPrice, m_pois[j].lowerPrice);
                        m_pois[i].upperPrice = MathMax(m_pois[i].upperPrice, m_pois[j].upperPrice);
                        if (m_pois[i].type == POI_OB_BULLISH || m_pois[i].type == POI_BREAKER_BULLISH || m_pois[i].type == POI_MITIGATION_BULLISH || m_pois[i].type == POI_FVG_BULLISH)
                        {
                            m_pois[i].invalidationLevel = m_pois[i].lowerPrice;
                        }
                        else
                        {
                            m_pois[i].invalidationLevel = m_pois[i].upperPrice;
                        }

                        m_pois[j].active = false;
                        m_pois[j].lifecycle = POI_STATE_ARCHIVED;
                    }
                }
            }
            // Check for confluence score boost (different type, same direction)
            else
            {
                bool isBullishI = (m_pois[i].type == POI_OB_BULLISH || m_pois[i].type == POI_BREAKER_BULLISH || m_pois[i].type == POI_MITIGATION_BULLISH || m_pois[i].type == POI_FVG_BULLISH);
                bool isBullishJ = (m_pois[j].type == POI_OB_BULLISH || m_pois[j].type == POI_BREAKER_BULLISH || m_pois[j].type == POI_MITIGATION_BULLISH || m_pois[j].type == POI_FVG_BULLISH);

                if (isBullishI == isBullishJ)
                {
                    double overlapLower = MathMax(m_pois[i].lowerPrice, m_pois[j].lowerPrice);
                    double overlapUpper = MathMin(m_pois[i].upperPrice, m_pois[j].upperPrice);

                    if (overlapLower < overlapUpper)
                    {
                        // Overlapping POIs of different type in same direction
                        // Add confidence score boost
                        m_pois[i].rankingScore = MathMin(m_pois[i].rankingScore + 10.0, 100.0);
                        m_pois[j].rankingScore = MathMin(m_pois[j].rankingScore + 10.0, 100.0);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Ranks POIs (0 to 100) and assigns priority                      |
//+------------------------------------------------------------------+
void CPOIEngine::RankPOIs(const CSwingDetector &swingDetector,
                          const CStructureEngine &structureEngine,
                          const CBreakDetector &breakDetector,
                          const CLiquidityEngine &liquidityEngine,
                          const CDeliveryStructureEngine &deliveryEngine)
{
    EDeliveryDirection delDir = deliveryEngine.GetDirection();
    double dolPrice = deliveryEngine.GetState().currentObjective;
    ETrend structureTrend = structureEngine.GetState().trend;

    // Get current period (timeframe) to determine HTF significance
    ENUM_TIMEFRAMES currentPeriod = Period();
    double tfSignificance = 10.0; // Default fallback
    if (currentPeriod == PERIOD_W1 || currentPeriod == PERIOD_MN1 || currentPeriod == PERIOD_D1)
        tfSignificance = 15.0;
    else if (currentPeriod == PERIOD_H4)
        tfSignificance = 13.0;
    else if (currentPeriod == PERIOD_H1)
        tfSignificance = 10.0;
    else if (currentPeriod == PERIOD_M15)
        tfSignificance = 7.0;
    else if (currentPeriod == PERIOD_M5)
        tfSignificance = 4.0;
    else if (currentPeriod == PERIOD_M1)
        tfSignificance = 2.0;

    for (int k = 0; k < m_poisCount; k++)
    {
        if (!m_pois[k].active)
            continue;

        double score = 0.0;
        bool isBullish = (m_pois[k].type == POI_OB_BULLISH || m_pois[k].type == POI_BREAKER_BULLISH || m_pois[k].type == POI_MITIGATION_BULLISH || m_pois[k].type == POI_FVG_BULLISH);

        // 1. Structural/BOS Relationship (20 pts)
        if (m_pois[k].type == POI_OB_BULLISH || m_pois[k].type == POI_OB_BEARISH ||
            m_pois[k].type == POI_BREAKER_BULLISH || m_pois[k].type == POI_BREAKER_BEARISH)
        {
            score += 20.0;
        }
        else if (m_pois[k].type == POI_MITIGATION_BULLISH || m_pois[k].type == POI_MITIGATION_BEARISH)
        {
            score += 15.0;
        }
        else if (m_pois[k].type == POI_FVG_BULLISH || m_pois[k].type == POI_FVG_BEARISH)
        {
            score += 10.0;
        }

        // 2. Freshness (15 pts)
        if (m_pois[k].lifecycle == POI_STATE_ACTIVE)
        {
            score += 15.0;
        }
        else if (m_pois[k].lifecycle == POI_STATE_PARTIAL_MITIGATED)
        {
            score += 10.0;
        }
        else if (m_pois[k].lifecycle == POI_STATE_MATERIAL_MITIGATED)
        {
            score += 5.0;
        }

        // 3. Displacement Strength (15 pts)
        // Find the break that occurred at the creation time of this POI
        double dispScore = 0.0;
        int breakCount = breakDetector.GetBreakCount();
        for (int i = breakCount - 1; i >= 0; i--)
        {
            SStructureBreak sb = breakDetector.GetBreak(i);
            if (sb.isConfirmed && sb.time == m_pois[k].createdTime)
            {
                if (sb.strength == STRENGTH_STRONG)
                    dispScore = 15.0;
                else if (sb.strength == STRENGTH_AVERAGE)
                    dispScore = 10.0;
                else if (sb.strength == STRENGTH_WEAK)
                    dispScore = 5.0;
                break;
            }
        }
        // Fallback: if no direct break match (e.g. FVG detected independently), check break count to find closest
        if (dispScore == 0.0 && breakCount > 0)
        {
            SStructureBreak sb = breakDetector.GetBreak(breakCount - 1);
            if (sb.isConfirmed)
            {
                if (sb.strength == STRENGTH_STRONG)
                    dispScore = 10.0;
                else if (sb.strength == STRENGTH_AVERAGE)
                    dispScore = 7.0;
                else
                    dispScore = 4.0;
            }
        }
        score += dispScore;

        // 4. HTF Significance (15 pts)
        score += tfSignificance;

        // 5. DOL Alignment (10 pts)
        if (dolPrice != 0.0 && dolPrice != DBL_MAX)
        {
            if (isBullish && dolPrice > m_pois[k].upperPrice)
                score += 10.0; // Bullish POI is below the target DOL
            else if (!isBullish && dolPrice < m_pois[k].lowerPrice)
                score += 10.0; // Bearish POI is above the target DOL
        }

        // 6. MTF Alignment (10 pts)
        if ((isBullish && structureTrend == TREND_BULLISH) || (!isBullish && structureTrend == TREND_BEARISH))
        {
            score += 10.0;
        }
        else if (structureTrend == TREND_RANGING || structureTrend == TREND_TRANSITION)
        {
            score += 5.0;
        }

        // 7. Liquidity Relationship (5 pts)
        // Check if there is an active liquidity pool close to our POI boundaries
        bool nearLiq = false;
        int poolCount = liquidityEngine.GetPoolsCount();
        double tol = 5.0 * _Point;
        for (int i = 0; i < poolCount; i++)
        {
            SLiquidityPool pool;
            if (liquidityEngine.GetPool(i, pool) && pool.active)
            {
                if (isBullish && pool.type == LIQUIDITY_SSL)
                {
                    if (MathAbs(pool.level - m_pois[k].lowerPrice) <= tol || MathAbs(pool.level - m_pois[k].upperPrice) <= tol)
                    {
                        nearLiq = true;
                        break;
                    }
                }
                else if (!isBullish && pool.type == LIQUIDITY_BSL)
                {
                    if (MathAbs(pool.level - m_pois[k].lowerPrice) <= tol || MathAbs(pool.level - m_pois[k].upperPrice) <= tol)
                    {
                        nearLiq = true;
                        break;
                    }
                }
            }
        }
        if (nearLiq)
            score += 5.0;
        else
            score += 2.0; // Minor presence

        // 8. Premium/Discount Location (5 pts)
        EDealingRangeZone zone = GetDealingRangeZone((m_pois[k].upperPrice + m_pois[k].lowerPrice) / 2.0, swingDetector);
        if ((isBullish && zone == ZONE_DISCOUNT) || (!isBullish && zone == ZONE_PREMIUM))
        {
            score += 5.0;
        }

        // 9. POI Confluence (5 pts)
        // Check if this POI overlaps by >= 50% with another active POI of different type but same direction
        bool hasConfluence = false;
        double smallerSize = m_pois[k].upperPrice - m_pois[k].lowerPrice;
        for (int j = 0; j < m_poisCount; j++)
        {
            if (j == k || !m_pois[j].active)
                continue;

            bool otherBullish = (m_pois[j].type == POI_OB_BULLISH || m_pois[j].type == POI_BREAKER_BULLISH || m_pois[j].type == POI_MITIGATION_BULLISH || m_pois[j].type == POI_FVG_BULLISH);
            if (isBullish != otherBullish || m_pois[k].type == m_pois[j].type)
                continue;

            double overlapLower = MathMax(m_pois[k].lowerPrice, m_pois[j].lowerPrice);
            double overlapUpper = MathMin(m_pois[k].upperPrice, m_pois[j].upperPrice);
            if (overlapUpper > overlapLower)
            {
                double overlapSize = overlapUpper - overlapLower;
                double otherSize = m_pois[j].upperPrice - m_pois[j].lowerPrice;
                double limit = MathMin(smallerSize, otherSize) * 0.50;
                if (overlapSize >= limit)
                {
                    hasConfluence = true;
                    break;
                }
            }
        }
        if (hasConfluence)
            score += 5.0;

        if (score > 100.0) score = 100.0;
        m_pois[k].rankingScore = score;

        // Priority assignment
        if (score >= 90.0) // 90-100 Elite
            m_pois[k].priority = PRIORITY_HIGH;
        else if (score >= 80.0) // 80-89 Strong
            m_pois[k].priority = PRIORITY_HIGH;
        else if (score >= 70.0) // 70-79 Valid
            m_pois[k].priority = PRIORITY_MEDIUM;
        else // < 70 Weak
            m_pois[k].priority = PRIORITY_LOW;
    }
}

//+------------------------------------------------------------------+
//| Adds or overwrites a POI in the fixed database                  |
//+------------------------------------------------------------------+
void CPOIEngine::AddOrUpdatePOI(EPoIType type,
                                double lower,
                                double upper,
                                double invalidation,
                                datetime timeVal,
                                int barIdx,
                                double fillPct)
{
    int idx = FindPOIIndexByPrice(lower, upper, type);
    if (idx != -1)
    {
        // POI already exists, update properties
        m_pois[idx].barIndex = barIdx;
        m_pois[idx].createdTime = timeVal;
        return;
    }

    int targetIdx = m_poisCount;
    if (m_poisCount >= 128)
    {
        // Buffer full: overwrite oldest inactive/invalidated POI
        targetIdx = -1;
        datetime oldestTime = DBL_MAX;
        for (int k = 0; k < 128; k++)
        {
            if (!m_pois[k].active && m_pois[k].createdTime < oldestTime)
            {
                oldestTime = m_pois[k].createdTime;
                targetIdx = k;
            }
        }
        if (targetIdx == -1)
            targetIdx = 0; // Fallback to index 0
    }
    else
    {
        m_poisCount++;
    }

    m_pois[targetIdx].Reset();
    m_pois[targetIdx].id = targetIdx;
    m_pois[targetIdx].type = type;
    m_pois[targetIdx].lowerPrice = lower;
    m_pois[targetIdx].upperPrice = upper;
    m_pois[targetIdx].invalidationLevel = invalidation;
    m_pois[targetIdx].createdTime = timeVal;
    m_pois[targetIdx].barIndex = barIdx;
    m_pois[targetIdx].fillPercent = fillPct;
    m_pois[targetIdx].active = true;
    m_pois[targetIdx].lifecycle = POI_STATE_ACTIVE;
}

//+------------------------------------------------------------------+
//| Finds matching POI by price and type within tolerance            |
//+------------------------------------------------------------------+
int CPOIEngine::FindPOIIndexByPrice(double lower, double upper, EPoIType type) const
{
    double zoneTolerance = 2.0 * _Point;
    for (int k = 0; k < m_poisCount; k++)
    {
        if (m_pois[k].active && m_pois[k].type == type)
        {
            if (MathAbs(m_pois[k].lowerPrice - lower) <= zoneTolerance &&
                MathAbs(m_pois[k].upperPrice - upper) <= zoneTolerance)
            {
                return k;
            }
        }
    }
    return -1;
}

//+------------------------------------------------------------------+
//| Gets a POI by index (safe getter by value)                       |
//+------------------------------------------------------------------+
bool CPOIEngine::GetPoI(int index, SPoIDefinition &outPoi) const
{
    if (index < 0 || index >= m_poisCount)
        return false;
    outPoi = m_pois[index];
    return true;
}

//+------------------------------------------------------------------+
//| Returns the nearest active bullish POI                           |
//+------------------------------------------------------------------+
bool CPOIEngine::GetNearestBullishPOI(double currentPrice, SPoIDefinition &outPoi) const
{
    outPoi.Reset();
    double nearestDist = DBL_MAX;
    int nearestIdx = -1;

    for (int k = 0; k < m_poisCount; k++)
    {
        if (!m_pois[k].active)
            continue;

        bool isBullish = (m_pois[k].type == POI_OB_BULLISH ||
                          m_pois[k].type == POI_BREAKER_BULLISH ||
                          m_pois[k].type == POI_MITIGATION_BULLISH ||
                          m_pois[k].type == POI_FVG_BULLISH);

        if (isBullish && m_pois[k].upperPrice <= currentPrice)
        {
            double dist = currentPrice - m_pois[k].upperPrice;
            if (dist < nearestDist)
            {
                nearestDist = dist;
                nearestIdx = k;
            }
        }
    }

    if (nearestIdx != -1)
    {
        outPoi = m_pois[nearestIdx];
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Returns the nearest active bearish POI                            |
//+------------------------------------------------------------------+
bool CPOIEngine::GetNearestBearishPOI(double currentPrice, SPoIDefinition &outPoi) const
{
    outPoi.Reset();
    double nearestDist = DBL_MAX;
    int nearestIdx = -1;

    for (int k = 0; k < m_poisCount; k++)
    {
        if (!m_pois[k].active)
            continue;

        bool isBearish = (m_pois[k].type == POI_OB_BEARISH ||
                           m_pois[k].type == POI_BREAKER_BEARISH ||
                           m_pois[k].type == POI_MITIGATION_BEARISH ||
                           m_pois[k].type == POI_FVG_BEARISH);

        if (isBearish && m_pois[k].lowerPrice >= currentPrice)
        {
            double dist = m_pois[k].lowerPrice - currentPrice;
            if (dist < nearestDist)
            {
                nearestDist = dist;
                nearestIdx = k;
            }
        }
    }

    if (nearestIdx != -1)
    {
        outPoi = m_pois[nearestIdx];
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Returns the Equilibrium price of the dealing range               |
//+------------------------------------------------------------------+
double CPOIEngine::GetEquilibrium(const CSwingDetector &swingDetector) const
{
    SSwingPoint extHigh = swingDetector.GetLatestExternalHigh();
    SSwingPoint extLow = swingDetector.GetLatestExternalLow();

    if (extHigh.isConfirmed && extLow.isConfirmed)
    {
        return (extHigh.price + extLow.price) / 2.0;
    }
    return 0.0;
}

//+------------------------------------------------------------------+
//| Classifies price relative to Premium/Discount dealing range      |
//+------------------------------------------------------------------+
EDealingRangeZone CPOIEngine::GetDealingRangeZone(double price, const CSwingDetector &swingDetector) const
{
    double eq = GetEquilibrium(swingDetector);
    if (eq == 0.0)
        return ZONE_EQUILIBRIUM;

    double epsilon = 0.000001; // tiny offset for exact center
    if (MathAbs(price - eq) < epsilon)
        return ZONE_EQUILIBRIUM;

    if (price > eq)
        return ZONE_PREMIUM;

    return ZONE_DISCOUNT;
}

#endif // __MNS_POI_ENGINE_MQH__
