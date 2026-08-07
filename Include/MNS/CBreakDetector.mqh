//+------------------------------------------------------------------+
//|                                              CBreakDetector.mqh  |
//|                              MNS Trading Engine — Module 004     |
//|                                                                  |
//| Purpose:                                                         |
//|   Monitors confirmed swing points and detects trend continuation |
//|   breaks (BOS), internal breaks (iBOS), and reversal warnings    |
//|   (CHoCH) on closed candles.                                     |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Detect body-close Break of Structure (BOS).                  |
//|   - Detect body-close Internal BOS (iBOS).                       |
//|   - Detect wick-only Change of Character (CHoCH) on protected     |
//|     swings based on the active trend bias.                       |
//|   - Avoid duplicate break recordings for any single swing point.  |
//|   - Classify break strength using ATR volatility sizing.          |
//|                                                                  |
//| Non-Responsibilities:                                            |
//|   - No chart rendering or drawing of break lines.                |
//|   - No trading logic, order execution, or risk management.       |
//|   - No direct MT5 database queries (iClose, iTime, etc.).        |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
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

    // Helper functions
    bool IsBreakAlreadyRecorded(datetime swingTime, EStructureBreak type) const;
    void RecordBreak(int barIndex, double price, datetime time, EStructureBreak breakType, EStrength strength, const SSwingPoint &brokenSwing);
    bool EvaluateBarForBreaks(int index, const CSwingDetector &swingDetector, const CStructureEngine &structureEngine, const double &high[], const double &low[], const double &close[], const double &open[], const datetime &time[], int ratesTotal, double currentAtr);

public:
    //+------------------------------------------------------------------+
    //| Constructor                                                      |
    //+------------------------------------------------------------------+
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
    /// @param swingDetector Confirmed swing point history.
    /// @param structureEngine Current market trend/phase state.
    /// @param high Bar high prices.
    /// @param low Bar low prices.
    /// @param close Bar close prices.
    /// @param open Bar open prices.
    /// @param time Bar open times.
    /// @param ratesTotal Total number of bars.
    /// @param prevCalculated Previously processed number of bars.
    /// @param currentAtr Current ATR value for volatility sizing.
    /// @return True if a new structural break was confirmed.
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

//+------------------------------------------------------------------+
//| Returns the break at the given zero-based chronological index    |
//+------------------------------------------------------------------+
SStructureBreak CBreakDetector::GetBreak(int index) const
{
    if (index < 0 || index >= m_breakCount)
        return m_emptyBreak;
    return m_breaks[index];
}

//+------------------------------------------------------------------+
//| Check if a swing has already been broken in the history          |
//+------------------------------------------------------------------+
bool CBreakDetector::IsBreakAlreadyRecorded(datetime swingTime, EStructureBreak type) const
{
    for (int i = 0; i < m_breakCount; i++)
    {
        if (m_breaks[i].brokenSwing.time == swingTime && m_breaks[i].breakType == type)
            return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Appends and caches a structural break                            |
//+------------------------------------------------------------------+
void CBreakDetector::RecordBreak(int barIndex, double price, datetime time, EStructureBreak breakType, EStrength strength, const SSwingPoint &brokenSwing)
{
    if (m_breakCount >= MNS_MAX_STRUCTURE_BREAKS)
        return;

    SStructureBreak sb;
    sb.barIndex = barIndex;
    sb.price = price;
    sb.time = time;
    sb.breakType = breakType;
    sb.strength = strength;
    sb.brokenSwing = brokenSwing;
    sb.isConfirmed = true;

    m_breaks[m_breakCount] = sb;
    m_breakCount++;

    // Cache latest break by type for O(1) lookup
    if (breakType == BREAK_BOS)
        m_latestBOS = sb;
    else if (breakType == BREAK_INTERNAL_BOS)
        m_latestIBOS = sb;
    else if (breakType == BREAK_CHOCH)
        m_latestCHOCH = sb;
}

//+------------------------------------------------------------------+
//| Evaluates a single bar for structural breaks                      |
//+------------------------------------------------------------------+
bool CBreakDetector::EvaluateBarForBreaks(int index, 
                                         const CSwingDetector &swingDetector, 
                                         const CStructureEngine &structureEngine, 
                                         const double &high[], 
                                         const double &low[], 
                                         const double &close[], 
                                         const double &open[], 
                                         const datetime &time[], 
                                         int ratesTotal, 
                                         double currentAtr)
{
    bool confirmed = false;

    //--- 1. Detect External Swing Breaks (BOS)
    int extSwingCount = swingDetector.GetExternalSwingCount();
    SSwingPoint latestExtHigh;
    latestExtHigh.Reset();
    SSwingPoint latestExtLow;
    latestExtLow.Reset();

    // Find the latest confirmed external swing points that occurred BEFORE the current bar
    // (In time-series order, index 0 is newest, so historical bars have larger indices: swing.barIndex > index)
    for (int j = extSwingCount - 1; j >= 0; j--)
    {
        SSwingPoint sw = swingDetector.GetExternalSwing(j);
        if (sw.barIndex > index)
        {
            if (sw.type == SWING_HIGH && !latestExtHigh.isConfirmed)
                latestExtHigh = sw;
            else if (sw.type == SWING_LOW && !latestExtLow.isConfirmed)
                latestExtLow = sw;
        }
        if (latestExtHigh.isConfirmed && latestExtLow.isConfirmed)
            break;
    }

    // Bullish External BOS (body closes above previous external high)
    if (latestExtHigh.isConfirmed && close[index] > latestExtHigh.price)
    {
        if (!IsBreakAlreadyRecorded(latestExtHigh.time, BREAK_BOS))
        {
            // Calculate Strength
            // TODO: OPEN-010 - Check displacement calculation parameters
            double candleRange = high[index] - low[index];
            double atrMultiple = (currentAtr > 0.0) ? (candleRange / currentAtr) : 0.0;
            EStrength strength = STRENGTH_WEAK;
            if (atrMultiple >= 2.0)
                strength = STRENGTH_STRONG;
            else if (atrMultiple >= 1.0)
                strength = STRENGTH_AVERAGE;

            RecordBreak(index, latestExtHigh.price, time[index], BREAK_BOS, strength, latestExtHigh);
            confirmed = true;
        }
    }

    // Bearish External BOS (body closes below previous external low)
    if (latestExtLow.isConfirmed && close[index] < latestExtLow.price)
    {
        if (!IsBreakAlreadyRecorded(latestExtLow.time, BREAK_BOS))
        {
            double candleRange = high[index] - low[index];
            double atrMultiple = (currentAtr > 0.0) ? (candleRange / currentAtr) : 0.0;
            EStrength strength = STRENGTH_WEAK;
            if (atrMultiple >= 2.0)
                strength = STRENGTH_STRONG;
            else if (atrMultiple >= 1.0)
                strength = STRENGTH_AVERAGE;

            RecordBreak(index, latestExtLow.price, time[index], BREAK_BOS, strength, latestExtLow);
            confirmed = true;
        }
    }

    //--- 2. Detect Internal Swing Breaks (iBOS)
    int intSwingCount = swingDetector.GetInternalSwingCount();
    SSwingPoint latestIntHigh;
    latestIntHigh.Reset();
    SSwingPoint latestIntLow;
    latestIntLow.Reset();

    for (int j = intSwingCount - 1; j >= 0; j--)
    {
        SSwingPoint sw = swingDetector.GetInternalSwing(j);
        if (sw.barIndex > index)
        {
            if (sw.type == SWING_HIGH && !latestIntHigh.isConfirmed)
                latestIntHigh = sw;
            else if (sw.type == SWING_LOW && !latestIntLow.isConfirmed)
                latestIntLow = sw;
        }
        if (latestIntHigh.isConfirmed && latestIntLow.isConfirmed)
            break;
    }

    // Bullish Internal BOS
    if (latestIntHigh.isConfirmed && close[index] > latestIntHigh.price)
    {
        if (!IsBreakAlreadyRecorded(latestIntHigh.time, BREAK_INTERNAL_BOS))
        {
            double candleRange = high[index] - low[index];
            double atrMultiple = (currentAtr > 0.0) ? (candleRange / currentAtr) : 0.0;
            EStrength strength = STRENGTH_WEAK;
            if (atrMultiple >= 2.0)
                strength = STRENGTH_STRONG;
            else if (atrMultiple >= 1.0)
                strength = STRENGTH_AVERAGE;

            RecordBreak(index, latestIntHigh.price, time[index], BREAK_INTERNAL_BOS, strength, latestIntHigh);
            confirmed = true;
        }
    }

    // Bearish Internal BOS
    if (latestIntLow.isConfirmed && close[index] < latestIntLow.price)
    {
        if (!IsBreakAlreadyRecorded(latestIntLow.time, BREAK_INTERNAL_BOS))
        {
            double candleRange = high[index] - low[index];
            double atrMultiple = (currentAtr > 0.0) ? (candleRange / currentAtr) : 0.0;
            EStrength strength = STRENGTH_WEAK;
            if (atrMultiple >= 2.0)
                strength = STRENGTH_STRONG;
            else if (atrMultiple >= 1.0)
                strength = STRENGTH_AVERAGE;

            RecordBreak(index, latestIntLow.price, time[index], BREAK_INTERNAL_BOS, strength, latestIntLow);
            confirmed = true;
        }
    }

    //--- 3. Detect Change of Character (CHoCH)
    // TODO: OPEN-009 - Verify if CHoCH should apply to non-trend swing points
    ETrend trend = structureEngine.GetState().trend;

    if (trend == TREND_BULLISH)
    {
        // Protected swing is the latest confirmed External Swing Low
        if (latestExtLow.isConfirmed)
        {
            // Wick goes below protected swing low, but body does not close below it
            if (low[index] < latestExtLow.price && close[index] >= latestExtLow.price)
            {
                if (!IsBreakAlreadyRecorded(latestExtLow.time, BREAK_CHOCH))
                {
                    double candleRange = high[index] - low[index];
                    double atrMultiple = (currentAtr > 0.0) ? (candleRange / currentAtr) : 0.0;
                    EStrength strength = STRENGTH_WEAK;
                    if (atrMultiple >= 2.0)
                        strength = STRENGTH_STRONG;
                    else if (atrMultiple >= 1.0)
                        strength = STRENGTH_AVERAGE;

                    RecordBreak(index, latestExtLow.price, time[index], BREAK_CHOCH, strength, latestExtLow);
                    confirmed = true;
                }
            }
        }
    }
    else if (trend == TREND_BEARISH)
    {
        // Protected swing is the latest confirmed External Swing High
        if (latestExtHigh.isConfirmed)
        {
            // Wick goes above protected swing high, but body does not close above it
            if (high[index] > latestExtHigh.price && close[index] <= latestExtHigh.price)
            {
                if (!IsBreakAlreadyRecorded(latestExtHigh.time, BREAK_CHOCH))
                {
                    double candleRange = high[index] - low[index];
                    double atrMultiple = (currentAtr > 0.0) ? (candleRange / currentAtr) : 0.0;
                    EStrength strength = STRENGTH_WEAK;
                    if (atrMultiple >= 2.0)
                        strength = STRENGTH_STRONG;
                    else if (atrMultiple >= 1.0)
                        strength = STRENGTH_AVERAGE;

                    RecordBreak(index, latestExtHigh.price, time[index], BREAK_CHOCH, strength, latestExtHigh);
                    confirmed = true;
                }
            }
        }
    }

    return confirmed;
}

//+------------------------------------------------------------------+
//| Updates break detector state with newly closed candles           |
//+------------------------------------------------------------------+
bool CBreakDetector::Update(const CSwingDetector &swingDetector, 
                            const CStructureEngine &structureEngine,
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

    // Need at least 2 bars (closed index 1, open index 0)
    if (ratesTotal < 2)
        return false;

    // Scan backwards from oldest to newest closed bars to maintain chronological break history
    int startIndex = (prevCalculated == 0 || m_lastProcessedRatesTotal == 0) ? (ratesTotal - 1) : (m_lastProcessedRatesTotal - 1);
    
    // Safety boundaries
    if (startIndex >= ratesTotal)
        startIndex = ratesTotal - 1;

    bool confirmed = false;

    // Index 0 (forming candle) is never evaluated. Scan ends at closed index 1.
    for (int i = startIndex; i >= 1; i--)
    {
        if (EvaluateBarForBreaks(i, swingDetector, structureEngine, high, low, close, open, time, ratesTotal, currentAtr))
            confirmed = true;
    }

    m_lastProcessedRatesTotal = ratesTotal;
    return confirmed;
}

#endif // __MNS_BREAK_DETECTOR_MQH__
