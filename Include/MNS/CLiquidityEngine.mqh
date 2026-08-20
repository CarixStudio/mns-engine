//+------------------------------------------------------------------+
//|                                             CLiquidityEngine.mqh |
//|                              MNS Trading Engine — Module 007     |
//|                                                                  |
//| Purpose:                                                         |
//|   Identifies, tracks, and ranks liquidity pools (BSL/SSL, EQH/EQL)|
//|   and session highs/lows without using broker API series calls.  |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_LIQUIDITY_ENGINE_MQH__
#define __MNS_LIQUIDITY_ENGINE_MQH__

#include "MNSTypes.mqh"
#include "CSwingDetector.mqh"
#include "CDeliveryStructureEngine.mqh"
#include "MNSConfig.mqh"

//-------------------------------------------------------------------
/// @class CLiquidityEngine
/// @brief Detects and ranks liquidity levels (BSL, SSL, EQH, EQL).
//-------------------------------------------------------------------
class CLiquidityEngine
{
private:
    bool                m_isInitialized;            ///< Initialization watermark.
    SLiquidityPool      m_pools[128];               ///< Tracked liquidity pools.
    int                 m_poolsCount;               ///< Total tracked pools.
    int                 m_lastProcessedSwingCount;  ///< Swing count watermark.
    int                 m_gmtOffset;                ///< GMT offset configuration.

    // Private helper methods
    void                DetectDailyWeeklyLevels(const double &high[], const double &low[], const datetime &time[], int ratesTotal);
    void                DetectSessionLevels(const double &high[], const double &low[], const datetime &time[], int ratesTotal);
    void                DetectEqualPivots(const CSwingDetector &swingDetector, double currentAtr);
    void                CheckSweepsAndBreakouts(const double &high[], const double &low[], const double &close[], const datetime &time[], double currentAtr, double minBreakDistance);
    void                RankPools(const CDeliveryStructureEngine &deliveryEngine);
    int                 FindPoolIndexByLevel(double level, ELiquidityType type) const;
    void                AddOrUpdatePool(ELiquidityType type, ELiquiditySource source, double level, datetime timeVal, int initialTouches);

public:
    // Constructor / Destructor
    CLiquidityEngine()
        : m_isInitialized(false),
          m_poolsCount(0),
          m_lastProcessedSwingCount(0),
          m_gmtOffset(0)
    {
        Reset();
    }
    
    ~CLiquidityEngine() {}

    /// @brief Initializes the Liquidity Engine.
    /// @param gmtOffset GMT offset in hours.
    /// @return True on success.
    bool Initialize(int gmtOffset = 0)
    {
        m_gmtOffset = gmtOffset;
        Reset();
        m_isInitialized = true;
        return true;
    }

    /// @brief Resets the engine state.
    void Reset()
    {
        m_poolsCount = 0;
        m_lastProcessedSwingCount = 0;
        for (int i = 0; i < 128; i++)
            m_pools[i].Reset();
    }

    /// @brief Updates liquidity pools based on price action and swings.
    bool Update(const CSwingDetector &swingDetector,
                const CDeliveryStructureEngine &deliveryEngine,
                const double &high[],
                const double &low[],
                const double &close[],
                const double &open[],
                const datetime &time[],
                int ratesTotal,
                int prevCalculated,
                double currentAtr,
                double minBreakDistance);

    // Queries
    int GetPoolsCount() const { return m_poolsCount; }
    
    bool GetPool(int index, SLiquidityPool &outPool) const
    {
        if (index < 0 || index >= m_poolsCount)
            return false;
        outPool = m_pools[index];
        return true;
    }

    double GetNearestBSL(double currentPrice) const;
    double GetNearestSSL(double currentPrice) const;
};

//+------------------------------------------------------------------+
//| Updates liquidity pools and checks for sweeps                    |
//+------------------------------------------------------------------+
bool CLiquidityEngine::Update(const CSwingDetector &swingDetector,
                            const CDeliveryStructureEngine &deliveryEngine,
                            const double &high[],
                            const double &low[],
                            const double &close[],
                            const double &open[],
                            const datetime &time[],
                            int ratesTotal,
                            int prevCalculated,
                            double currentAtr,
                            double minBreakDistance)
{
    if (!m_isInitialized)
        return false;

    if (ratesTotal < 5)
        return false;

    // 1. Detect Daily / Weekly / Session Transitions
    DetectDailyWeeklyLevels(high, low, time, ratesTotal);
    DetectSessionLevels(high, low, time, ratesTotal);

    // 2. Scan swings for new levels and Equal Pivots (EQH / EQL)
    DetectEqualPivots(swingDetector, currentAtr);

    // 3. Monitor active pools for wick sweeps vs breakouts
    CheckSweepsAndBreakouts(high, low, close, time, currentAtr, minBreakDistance);

    // 4. Update rankings based on active delivery
    RankPools(deliveryEngine);

    return true;
}

//+------------------------------------------------------------------+
//| Scans swings for Equal Highs (EQH) and Equal Lows (EQL)          |
//+------------------------------------------------------------------+
void CLiquidityEngine::DetectEqualPivots(const CSwingDetector &swingDetector, double currentAtr)
{
    int swingCount = swingDetector.GetExternalSwingCount();
    if (swingCount == m_lastProcessedSwingCount)
        return;

    double tolerance = MathMax(3.0 * _Point, 0.10 * currentAtr);

    for (int i = m_lastProcessedSwingCount; i < swingCount; i++)
    {
        SSwingPoint sw = swingDetector.GetExternalSwing(i);
        if (!sw.isConfirmed)
            continue;

        // BSL/SSL pool from raw swing point (always add swing point as liquidity)
        AddOrUpdatePool(sw.type == SWING_HIGH ? LIQUIDITY_BSL : LIQUIDITY_SSL, LIQ_SRC_SWING, sw.price, sw.time, 1);

        // Check for EQH/EQL touches
        for (int j = i - 1; j >= 0; j--)
        {
            SSwingPoint prevSw = swingDetector.GetExternalSwing(j);
            if (!prevSw.isConfirmed || prevSw.type != sw.type)
                continue;

            // Touch Separation (minimum 3 closed candles)
            int sep = MathAbs(sw.barIndex - prevSw.barIndex);
            if (sep >= 3)
            {
                // Check price equality
                if (MathAbs(sw.price - prevSw.price) <= tolerance)
                {
                    double eqLevel = (sw.price + prevSw.price) / 2.0;
                    AddOrUpdatePool(sw.type == SWING_HIGH ? LIQUIDITY_BSL : LIQUIDITY_SSL, LIQ_SRC_EQ, eqLevel, sw.time, 2);
                    break;
                }
            }
        }
    }
    m_lastProcessedSwingCount = swingCount;
}

//+------------------------------------------------------------------+
//| Detects day/week transitions to establish PDH/PDL & PWH/PWL     |
//+------------------------------------------------------------------+
void CLiquidityEngine::DetectDailyWeeklyLevels(const double &high[], const double &low[], const datetime &time[], int ratesTotal)
{
    if (ratesTotal < 50)
        return;

    MqlDateTime dtCurrent, dtPrev;
    TimeToStruct(time[ratesTotal - 1], dtCurrent);
    TimeToStruct(time[ratesTotal - 2], dtPrev);

    // 1. Day Change
    if (dtCurrent.day != dtPrev.day)
    {
        double dayHigh = -1.0;
        double dayLow = DBL_MAX;
        datetime dayTime = 0;

        int targetDay = dtPrev.day;
        int targetMonth = dtPrev.mon;
        int targetYear = dtPrev.year;

        for (int j = ratesTotal - 2; j >= 0; j--)
        {
            MqlDateTime dt;
            TimeToStruct(time[j], dt);
            if (dt.day == targetDay && dt.mon == targetMonth && dt.year == targetYear)
            {
                if (high[j] > dayHigh) dayHigh = high[j];
                if (low[j] < dayLow) dayLow = low[j];
                if (dayTime == 0) dayTime = time[j];
            }
            else if (dayTime != 0)
            {
                break;
            }
        }

        if (dayHigh > 0.0)
        {
            AddOrUpdatePool(LIQUIDITY_BSL, LIQ_SRC_DAILY, dayHigh, dayTime, 1);
            AddOrUpdatePool(LIQUIDITY_SSL, LIQ_SRC_DAILY, dayLow, dayTime, 1);
        }
    }

    // 2. Week Change
    if (dtCurrent.day_of_week < dtPrev.day_of_week)
    {
        double wkHigh = -1.0;
        double wkLow = DBL_MAX;
        datetime wkTime = 0;

        int scanCount = 0;
        for (int j = ratesTotal - 2; j >= 0; j--)
        {
            MqlDateTime dt;
            TimeToStruct(time[j], dt);
            if (dt.day_of_week <= dtPrev.day_of_week)
            {
                if (high[j] > wkHigh) wkHigh = high[j];
                if (low[j] < wkLow) wkLow = low[j];
                if (wkTime == 0) wkTime = time[j];
                scanCount++;
            }
            else
            {
                break;
            }
            if (scanCount > 1000)
                break;
        }

        if (wkHigh > 0.0)
        {
            AddOrUpdatePool(LIQUIDITY_BSL, LIQ_SRC_WEEKLY, wkHigh, wkTime, 1);
            AddOrUpdatePool(LIQUIDITY_SSL, LIQ_SRC_WEEKLY, wkLow, wkTime, 1);
        }
    }
}

//+------------------------------------------------------------------+
//| Evaluates sweeps and body breakouts against active pools         |
//+------------------------------------------------------------------+
void CLiquidityEngine::CheckSweepsAndBreakouts(const double &high[], const double &low[], const double &close[], const datetime &time[], double currentAtr, double minBreakDistance)
{
    double tolerance = MathMax(3.0 * _Point, 0.10 * currentAtr);

    for (int k = 0; k < m_poolsCount; k++)
    {
        if (!m_pools[k].active)
            continue;

        if (m_pools[k].type == LIQUIDITY_BSL)
        {
            // Body Close Breakout (Rule 4.5)
            if (close[1] > m_pools[k].level + minBreakDistance)
            {
                m_pools[k].active = false;
                m_pools[k].lifecycle = LIQ_BROKEN;
                m_pools[k].brokenTime = time[1];
                m_pools[k].rankingScore = 0.0;
            }
            // Wick Sweep (Rule 4.4)
            else if (high[1] > m_pools[k].level && close[1] <= m_pools[k].level + tolerance)
            {
                m_pools[k].active = false;
                m_pools[k].swept = true;
                m_pools[k].lifecycle = LIQ_SWEPT;
                m_pools[k].sweptTime = time[1];
            }
        }
        else if (m_pools[k].type == LIQUIDITY_SSL)
        {
            // Body Close Breakout (Rule 4.5)
            if (close[1] < m_pools[k].level - minBreakDistance)
            {
                m_pools[k].active = false;
                m_pools[k].lifecycle = LIQ_BROKEN;
                m_pools[k].brokenTime = time[1];
                m_pools[k].rankingScore = 0.0;
            }
            // Wick Sweep (Rule 4.4)
            else if (low[1] < m_pools[k].level && close[1] >= m_pools[k].level - tolerance)
            {
                m_pools[k].active = false;
                m_pools[k].swept = true;
                m_pools[k].lifecycle = LIQ_SWEPT;
                m_pools[k].sweptTime = time[1];
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Ranks active liquidity pools (0 to 100)                          |
//+------------------------------------------------------------------+
void CLiquidityEngine::RankPools(const CDeliveryStructureEngine &deliveryEngine)
{
    EDeliveryDirection delDir = deliveryEngine.GetDirection();
    double dolPrice = deliveryEngine.GetState().currentObjective;

    for (int k = 0; k < m_poolsCount; k++)
    {
        if (!m_pools[k].active)
            continue;

        double score = 0.0;

        // 1. Source weight (Rule 4.7)
        if (m_pools[k].source == LIQ_SRC_SWING)
            score += 25.0;
        else if (m_pools[k].source == LIQ_SRC_EQ)
            score += 20.0;
        else if (m_pools[k].source == LIQ_SRC_DAILY || m_pools[k].source == LIQ_SRC_WEEKLY || m_pools[k].source == LIQ_SRC_SESSION)
            score += 5.0;

        // 2. Touches count
        if (m_pools[k].touchesCount >= 3)
            score += 10.0;

        // 3. Untouched freshness
        if (m_pools[k].lifecycle == LIQ_ACTIVE)
            score += 10.0;

        // 4. HTF Origin (Assumed if rank is high timeframe origin)
        if (m_pools[k].source == LIQ_SRC_DAILY || m_pools[k].source == LIQ_SRC_WEEKLY)
            score += 20.0;

        // 5. Alignment with delivery
        if ((m_pools[k].type == LIQUIDITY_BSL && delDir == DELIVERY_DIR_BULLISH) ||
            (m_pools[k].type == LIQUIDITY_SSL && delDir == DELIVERY_DIR_BEARISH))
        {
            score += 5.0;
        }

        // 6. Alignment with DOL
        if (dolPrice != 0.0 && dolPrice != DBL_MAX)
        {
            if (MathAbs(m_pools[k].level - dolPrice) < 5.0 * _Point)
                score += 5.0;
        }

        if (score > 100.0) score = 100.0;
        m_pools[k].rankingScore = score;

        // Priority Assignment
        if (score >= 80.0)
            m_pools[k].priority = PRIORITY_HIGH;
        else if (score >= 60.0)
            m_pools[k].priority = PRIORITY_MEDIUM;
        else
            m_pools[k].priority = PRIORITY_LOW;
    }
}

//+------------------------------------------------------------------+
//| Adds or increments touches of a liquidity pool                  |
//+------------------------------------------------------------------+
void CLiquidityEngine::AddOrUpdatePool(ELiquidityType type, ELiquiditySource source, double level, datetime timeVal, int initialTouches)
{
    int idx = FindPoolIndexByLevel(level, type);
    if (idx != -1)
    {
        bool isDup = false;
        for (int t = 0; t < m_pools[idx].touchesCount && t < 5; t++)
        {
            if (m_pools[idx].touchTimes[t] == timeVal)
            {
                isDup = true;
                break;
            }
        }
        if (!isDup)
        {
            int tIndex = m_pools[idx].touchesCount;
            if (tIndex < 5)
                m_pools[idx].touchTimes[tIndex] = timeVal;
            m_pools[idx].touchesCount++;
            m_pools[idx].lifecycle = LIQ_TOUCHED;
            m_pools[idx].createdTime = timeVal;
        }
        
        // Upgrade pool source to EQ if this touch confirms a multi-touch equal high/low
        if (source == LIQ_SRC_EQ)
            m_pools[idx].source = LIQ_SRC_EQ;
            
        return;
    }

    int targetIdx = m_poolsCount;
    if (m_poolsCount >= 128)
    {
        targetIdx = -1;
        int highestPriority = -1;
        datetime oldestTime = DBL_MAX;

        for (int k = 0; k < 128; k++)
        {
            if (m_pools[k].active)
                continue;

            int priority = 0;
            switch (m_pools[k].lifecycle)
            {
                case LIQ_ARCHIVED:  priority = 4; break;
                case LIQ_CONSUMED:  priority = 3; break;
                case LIQ_SWEPT:     priority = 2; break;
                case LIQ_BROKEN:    priority = 1; break;
                default:            priority = 0; break;
            }

            if (priority > highestPriority)
            {
                highestPriority = priority;
                oldestTime = m_pools[k].createdTime;
                targetIdx = k;
            }
            else if (priority == highestPriority && m_pools[k].createdTime < oldestTime)
            {
                oldestTime = m_pools[k].createdTime;
                targetIdx = k;
            }
        }

        // If no inactive pools found, evict based on lowest priority score
        if (targetIdx == -1)
        {
            double lowestScore = DBL_MAX;
            oldestTime = DBL_MAX;
            for (int k = 0; k < 128; k++)
            {
                if (m_pools[k].source == LIQ_SRC_WEEKLY)
                    continue;

                if (m_pools[k].rankingScore < lowestScore)
                {
                    lowestScore = m_pools[k].rankingScore;
                    oldestTime = m_pools[k].createdTime;
                    targetIdx = k;
                }
                else if (m_pools[k].rankingScore == lowestScore && m_pools[k].createdTime < oldestTime)
                {
                    oldestTime = m_pools[k].createdTime;
                    targetIdx = k;
                }
            }
        }

        if (targetIdx == -1)
            targetIdx = 0;
    }
    else
    {
        m_poolsCount++;
    }

    m_pools[targetIdx].Reset();
    m_pools[targetIdx].id = targetIdx;
    m_pools[targetIdx].type = type;
    m_pools[targetIdx].source = source;
    m_pools[targetIdx].level = level;
    m_pools[targetIdx].createdTime = timeVal;
    m_pools[targetIdx].touchesCount = initialTouches;
    m_pools[targetIdx].touchTimes[0] = timeVal;
    m_pools[targetIdx].active = true;
    m_pools[targetIdx].lifecycle = LIQ_ACTIVE;
}

//+------------------------------------------------------------------+
//| Finds pool matching level/type within zone tolerance            |
//+------------------------------------------------------------------+
int CLiquidityEngine::FindPoolIndexByLevel(double level, ELiquidityType type) const
{
    double zoneTolerance = 2.0 * _Point;
    for (int k = 0; k < m_poolsCount; k++)
    {
        if (m_pools[k].active && m_pools[k].type == type)
        {
            if (MathAbs(m_pools[k].level - level) <= zoneTolerance)
                return k;
        }
    }
    return -1;
}

//+------------------------------------------------------------------+
//| Returns nearest active buy-side liquidity level                  |
//+------------------------------------------------------------------+
double CLiquidityEngine::GetNearestBSL(double currentPrice) const
{
    double nearest = DBL_MAX;
    for (int k = 0; k < m_poolsCount; k++)
    {
        if (m_pools[k].active && m_pools[k].type == LIQUIDITY_BSL && m_pools[k].level > currentPrice)
        {
            if (m_pools[k].level < nearest)
                nearest = m_pools[k].level;
        }
    }
    return nearest;
}

//+------------------------------------------------------------------+
//| Returns nearest active sell-side liquidity level                 |
//+------------------------------------------------------------------+
double CLiquidityEngine::GetNearestSSL(double currentPrice) const
{
    double nearest = 0.0;
    for (int k = 0; k < m_poolsCount; k++)
    {
        if (m_pools[k].active && m_pools[k].type == LIQUIDITY_SSL && m_pools[k].level < currentPrice)
        {
            if (m_pools[k].level > nearest)
                nearest = m_pools[k].level;
        }
    }
    return nearest;
}

//+------------------------------------------------------------------+
//| Detects session transitions to establish Tokyo/London/NY pools   |
//+------------------------------------------------------------------+
void CLiquidityEngine::DetectSessionLevels(const double &high[], const double &low[], const datetime &time[], int ratesTotal)
{
    if (ratesTotal < 50)
        return;

    datetime currentGmt = time[ratesTotal - 1] - m_gmtOffset * 3600;
    datetime prevGmt = time[ratesTotal - 2] - m_gmtOffset * 3600;

    MqlDateTime dtCurrent, dtPrev;
    TimeToStruct(currentGmt, dtCurrent);
    TimeToStruct(prevGmt, dtPrev);

    // Check session close boundaries (GMT hours)
    int startHour = -1;
    int endHour = -1;

    if (dtPrev.hour < 8 && dtCurrent.hour >= 8)
    {
        startHour = 0;
        endHour = 8;
    }
    else if (dtPrev.hour < 16 && dtCurrent.hour >= 16)
    {
        startHour = 8;
        endHour = 16;
    }
    else if (dtPrev.hour < 21 && dtCurrent.hour >= 21)
    {
        startHour = 13;
        endHour = 21;
    }

    if (startHour != -1 && endHour != -1)
    {
        double sessHigh = -1.0;
        double sessLow = DBL_MAX;
        datetime sessTime = 0;

        for (int j = ratesTotal - 2; j >= 0; j--)
        {
            datetime barGmt = time[j] - m_gmtOffset * 3600;
            MqlDateTime dt;
            TimeToStruct(barGmt, dt);

            if (dt.day == dtPrev.day && dt.mon == dtPrev.mon && dt.year == dtPrev.year &&
                dt.hour >= startHour && dt.hour < endHour)
            {
                if (high[j] > sessHigh) sessHigh = high[j];
                if (low[j] < sessLow) sessLow = low[j];
                if (sessTime == 0) sessTime = time[j];
            }
            else if (dt.day != dtPrev.day || dt.hour < startHour)
            {
                if (sessTime != 0)
                    break;
            }
        }

        if (sessHigh > 0.0)
        {
            AddOrUpdatePool(LIQUIDITY_BSL, LIQ_SRC_SESSION, sessHigh, sessTime, 1);
            AddOrUpdatePool(LIQUIDITY_SSL, LIQ_SRC_SESSION, sessLow, sessTime, 1);
        }
    }
}

#endif // __MNS_LIQUIDITY_ENGINE_MQH__
