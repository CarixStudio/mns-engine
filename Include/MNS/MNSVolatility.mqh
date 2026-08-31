//+------------------------------------------------------------------+
//|                                               MNSVolatility.mqh  |
//|                              MNS Trading Engine — Module INF-003 |
//|                                                                  |
//| Purpose:                                                         |
//|   Provides pure, array-based Average True Range (ATR) calculation|
//|   capabilities without dependencies on MT5 indicator handles.    |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Calculate True Range for individual price bars.              |
//|   - Compute smoothed ATR using Wilder's smoothing algorithm.     |
//|   - Adapt to timeseries or standard indexing directions.         |
//|                                                                  |
//| Dependencies:                                                    |
//|   - MNSCore.mqh                                                  |
//|   - MNSUtils.mqh                                                 |
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading logic.                                          |
//|   - No hot-path allocations.                                     |
//|   - Static and pure methods only.                                |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_VOLATILITY_MQH__
#define __MNS_VOLATILITY_MQH__

#include "MNSCore.mqh"

//+------------------------------------------------------------------+
//| CMNSVolatility Class                                             |
//+------------------------------------------------------------------+
class CMNSVolatility
{
public:
    /// @brief Convenient helper to calculate 14-period ATR at bar shift 1.
    /// @param high High price array
    /// @param low Low price array
    /// @param close Close price array
    /// @param ratesTotal Total elements in price arrays
    /// @return 14-period ATR value at shift 1.
    static double CalculateATR14(const double& high[],
                                 const double& low[],
                                 const double& close[],
                                 int ratesTotal)
    {
        return CalculateATR(high, low, close, 1, 14, ratesTotal);
    }

    /// @brief Calculates the Average True Range value for a specific bar index.
    /// @param high price array
    /// @param low price array
    /// @param close price array
    /// @param index the bar index to calculate for
    /// @param period the smoothing period (default 14)
    /// @param ratesTotal total elements in price arrays
    /// @return ATR value in points, or 0.0 on validation failure.
    static double CalculateATR(const double& high[],
                               const double& low[],
                               const double& close[],
                               int index,
                               int period,
                               int ratesTotal)
    {
        // --- 1. Defensive Boundary & Parameter Validations ---
        int sizeHigh  = ArraySize(high);
        int sizeLow   = ArraySize(low);
        int sizeClose = ArraySize(close);
        
        MNS_Assert(sizeHigh == ratesTotal, "CalculateATR: high array size mismatch");
        MNS_Assert(sizeLow == ratesTotal, "CalculateATR: low array size mismatch");
        MNS_Assert(sizeClose == ratesTotal, "CalculateATR: close array size mismatch");
        
        if (sizeHigh != ratesTotal || sizeLow != ratesTotal || sizeClose != ratesTotal)
            return 0.0;
            
        MNS_Assert(period > 0, "CalculateATR: period must be greater than zero");
        MNS_Assert(ratesTotal >= period + 1, "CalculateATR: ratesTotal must be at least period + 1");
        
        if (period <= 0 || ratesTotal < period + 1)
            return 0.0;
            
        MNS_Assert(index >= 0 && index < ratesTotal, "CalculateATR: index out of bounds");
        if (index < 0 || index >= ratesTotal)
            return 0.0;
            
        bool isSeries = ArrayGetAsSeries(high);
        MNS_Assert(isSeries == ArrayGetAsSeries(low) && isSeries == ArrayGetAsSeries(close),
                   "CalculateATR: arrays must have matching series orientation");
                   
        if (isSeries != ArrayGetAsSeries(low) || isSeries != ArrayGetAsSeries(close))
            return 0.0;
            
        // --- 2. Logical Time-Ordered Index Mapping ---
        // logicalRequestedIndex is the index from oldest (0) to newest (ratesTotal - 1)
        int logicalRequestedIndex = isSeries ? (ratesTotal - 1 - index) : index;
        
        MNS_Assert(logicalRequestedIndex >= period, "CalculateATR: insufficient history for requested index");
        if (logicalRequestedIndex < period)
            return 0.0;
            
        // --- 3. Compute Initial ATR (Simple Moving Average of first 'period' True Ranges) ---
        // The first True Range is calculated at logical index 1 (using close of logical index 0).
        double trSum = 0.0;
        for (int i = 1; i <= period; i++)
        {
            trSum += CalculateLogicalTR(i, isSeries, high, low, close, ratesTotal);
        }
        double prevATR = trSum / period;
        
        // --- 4. Wilder's Smoothing Recursion up to the Requested Index ---
        for (int i = period + 1; i <= logicalRequestedIndex; i++)
        {
            double tr = CalculateLogicalTR(i, isSeries, high, low, close, ratesTotal);
            prevATR = (prevATR * (period - 1) + tr) / period;
        }
        
        return prevATR;
    }

private:
    /// @brief Computes True Range at a logical index (where 0 is the oldest bar).
    /// @param logicalIndex Index in chronological order (0 to ratesTotal-1).
    /// @param isSeries Orientation of source arrays.
    /// @param high High prices.
    /// @param low Low prices.
    /// @param close Close prices.
    /// @param ratesTotal Array length.
    /// @return Computed True Range.
    static double CalculateLogicalTR(int logicalIndex,
                                     bool isSeries,
                                     const double& high[],
                                     const double& low[],
                                     const double& close[],
                                     int ratesTotal)
    {
        MNS_Assert(logicalIndex >= 1 && logicalIndex < ratesTotal, "CalculateLogicalTR: logicalIndex out of bounds");
        
        int actK     = isSeries ? (ratesTotal - 1 - logicalIndex) : logicalIndex;
        int actKPrev = isSeries ? (ratesTotal - 1 - (logicalIndex - 1)) : (logicalIndex - 1);
        
        double tr1 = high[actK] - low[actK];
        double tr2 = MathAbs(high[actK] - close[actKPrev]);
        double tr3 = MathAbs(low[actK] - close[actKPrev]);
        
        double maxTr = tr1;
        if (tr2 > maxTr) maxTr = tr2;
        if (tr3 > maxTr) maxTr = tr3;
        
        return maxTr;
    }
};

#endif // __MNS_VOLATILITY_MQH__
