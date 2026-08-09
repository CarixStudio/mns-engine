//+------------------------------------------------------------------+
//|                                              CSwingDetector.mqh  |
//|                              MNS Trading Engine — Module 002     |
//|                                                                  |
//| Purpose:                                                         |
//|   Detects and maintains confirmed external and internal swing    |
//|   highs and lows from completed candles. Produces SSwingPoint    |
//|   structures consumed by every downstream engine module.         |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Detect External Swing Highs (depth 15).                      |
//|   - Detect External Swing Lows  (depth 15).                      |
//|   - Detect Internal Swing Highs (depth 5).                       |
//|   - Detect Internal Swing Lows  (depth 5).                       |
//|   - Confirm swings using strategy-defined rules.                 |
//|   - Maintain chronological swing history.                        |
//|   - Never repaint a confirmed swing.                             |
//|                                                                  |
//| Non-Responsibilities:                                            |
//|   - No chart drawing.                                            |
//|   - No trading logic.                                            |
//|   - No alerts.                                                   |
//|   - No broker interaction.                                       |
//|   - No direct MT5 market data calls (iHigh, iLow, iTime, Bars). |
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh — Root module. No other project dependencies.     |
//|                                                                  |
//| Consumed By:                                                     |
//|   CStructureEngine, CBreakEngine, CLiquidityEngine,              |
//|   CPOIEngine, CMarketStateEngine, Indicator, EA.                 |
//|                                                                  |
//| Data Contract:                                                   |
//|   Update() accepts OHLC arrays supplied by the caller.           |
//|   Arrays must be in time-series order: index 0 = newest bar.     |
//|   The caller applies ArraySetAsSeries() before passing data.     |
//|   This module never queries MT5 market data directly.            |
//|                                                                  |
//| Algorithm Source: kennystrstegy.md — Section 1, Section 2,       |
//|   Phase 1B (SwingDetector.mqh specification).                    |
//|                                                                  |
//| Confirmation Rule (from kennystrstegy.md, Phase 1B):             |
//|   External Swing High: bar[i].high is strictly greater than ALL  |
//|   highs in [i+1 .. i+15] (left/older) AND in [i-1 .. i-15]      |
//|   (right/newer). External depth = 15. Internal depth = 5.        |
//|   Evaluation begins at shift >= 2. Shift 0 = forming candle.     |
//|   Shift 1 = just closed. Shift 2 = minimum confirmation.         |
//|   Duplicate check: reject if same time AND same type exists.     |
//|                                                                  |
//| Version: 1.2                                                     |
//| Status:  Development                                             |
//+------------------------------------------------------------------+
#ifndef __MNS_SWING_DETECTOR_MQH__
#define __MNS_SWING_DETECTOR_MQH__

#include "MNSTypes.mqh"

//+------------------------------------------------------------------+
//| Strategy-defined depth constants                                 |
//| Source: kennystrstegy.md — Section 2, Phase 1B                   |
//+------------------------------------------------------------------+

/// @brief Candles required on each side to confirm an external swing.
///
/// Source: kennystrstegy.md — Section 2:
///   "Main Swing Uses: Minimum distance — 15 candles"
///   Phase 1B: "Look Left 15 candles / Look Right 15 candles"
#define MNS_SWING_EXTERNAL_DEPTH  15

/// @brief Candles required on each side to confirm an internal swing.
///
/// Source: kennystrstegy.md — Section 2:
///   "Internal Swing Uses: 5 candles"
#define MNS_SWING_INTERNAL_DEPTH   5

/// @brief Minimum shift from the forming candle before evaluating.
///
/// Source: kennystrstegy.md — Phase 1B Update():
///   "Shift 0 = Live candle. Shift 1 = Just closed. Shift 2 = Enough confirmation."
///   Always evaluate at Shift >= 2.
#define MNS_SWING_MIN_SHIFT        2

//+------------------------------------------------------------------+
//| CSwingDetector                                                   |
//+------------------------------------------------------------------+
/// @brief Detects and maintains confirmed external and internal
///        market swing points.
///
/// Maintains two independent swing histories simultaneously:
///   - External swings: confirmed over a 15-candle window each side.
///   - Internal swings: confirmed over a  5-candle window each side.
///
/// Both structures are maintained from the same price data on each
/// Update() call. Downstream modules (Structure Engine, Break Engine,
/// etc.) query each layer independently.
///
/// No MT5 market data functions are called inside this class.
/// All price data is supplied by the caller via Update().
///
/// Usage:
///   CSwingDetector detector;
///   if (!detector.Initialize()) { /* handle failure */ }
///
///   // In OnCalculate() — arrays already set as series:
///   detector.Update(high, low, time, ratesTotal, prevCalculated);
///
///   SSwingPoint latestHigh = detector.GetLatestExternalHigh();
///   SSwingPoint latestLow  = detector.GetLatestInternalLow();
///
class CSwingDetector
{
private:
    //--- Configuration (from strategy defaults, overridable in Initialize)
    int         m_externalDepth;   ///< Candles each side for external confirmation.
    int         m_internalDepth;   ///< Candles each side for internal confirmation.

    //--- External swing storage (chronological, oldest first)
    SSwingPoint m_externalSwings[];
    int         m_externalCount;

    //--- Internal swing storage (chronological, oldest first)
    SSwingPoint m_internalSwings[];
    int         m_internalCount;

    //--- Cached latest swing by direction for O(1) access
    //--- Updated every time a new swing of that type is confirmed.
    SSwingPoint m_latestExternalHigh;
    SSwingPoint m_latestExternalLow;
    SSwingPoint m_latestInternalHigh;
    SSwingPoint m_latestInternalLow;

    //--- Monotonic ID counter.
    //--- Source: kennystrstegy.md Phase 1B: "Never reuse IDs.
    //--- Future modules reference IDs."
    //--- SSwingPoint.barIndex serves as the unique identifier since
    //--- the approved SSwingPoint struct does not include an id field.
    //--- TODO: If SSwingPoint is extended with an id field in a future
    //--- revision of MNSTypes.mqh, replace barIndex-based tracking
    //--- with a monotonic id counter as specified in the strategy.

    //--- Lifecycle
    bool        m_isInitialized;   ///< True after a successful Initialize() call.
    SSwingPoint m_emptySwing;      ///< Sentinel returned for out-of-range queries.

public:
    //+------------------------------------------------------------------+
    //| Constructor                                                      |
    //+------------------------------------------------------------------+

    /// @brief Default constructor. All fields initialized to safe defaults.
    CSwingDetector()
        : m_externalDepth(MNS_SWING_EXTERNAL_DEPTH),
          m_internalDepth(MNS_SWING_INTERNAL_DEPTH),
          m_externalCount(0),
          m_internalCount(0),
          m_isInitialized(false)
    {
        m_emptySwing.Reset();
        m_latestExternalHigh.Reset();
        m_latestExternalLow.Reset();
        m_latestInternalHigh.Reset();
        m_latestInternalLow.Reset();
    }

    //+------------------------------------------------------------------+
    //| Public Interface                                                 |
    //+------------------------------------------------------------------+

    /// @brief Initializes the detector and pre-allocates swing storage.
    ///
    /// Must be called once before any call to Update().
    ///
    /// Default depths match the strategy specification:
    ///   externalDepth = 15 (kennystrstegy.md Section 2, Phase 1B)
    ///   internalDepth =  5 (kennystrstegy.md Section 2)
    ///
    /// @param externalDepth  Candles on each side for external swing
    ///                       confirmation. Minimum 1.
    /// @param internalDepth  Candles on each side for internal swing
    ///                       confirmation. Minimum 1. Must be <= externalDepth.
    ///
    /// @return True on success. False if parameters are invalid or
    ///         array allocation fails.
    bool Initialize(int externalDepth = MNS_SWING_EXTERNAL_DEPTH,
                    int internalDepth = MNS_SWING_INTERNAL_DEPTH)
    {
        if (externalDepth < 1 || internalDepth < 1)
            return false;

        if (internalDepth > externalDepth)
            return false;

        if (ArrayResize(m_externalSwings, MNS_MAX_SWINGS) != MNS_MAX_SWINGS)
            return false;

        if (ArrayResize(m_internalSwings, MNS_MAX_SWINGS) != MNS_MAX_SWINGS)
            return false;

        m_externalDepth = externalDepth;
        m_internalDepth = internalDepth;
        m_isInitialized = true;

        Reset();
        return true;
    }

    /// @brief Resets all internal state to safe defaults.
    ///
    /// Clears all confirmed swings and cached latest references.
    /// Storage arrays are retained (no reallocation).
    /// After Reset(), the detector is ready for a full history rescan.
    void Reset()
    {
        m_externalCount = 0;
        m_internalCount = 0;

        m_emptySwing.Reset();
        m_latestExternalHigh.Reset();
        m_latestExternalLow.Reset();
        m_latestInternalHigh.Reset();
        m_latestInternalLow.Reset();

        for (int i = 0; i < MNS_MAX_SWINGS; i++)
        {
            m_externalSwings[i].Reset();
            m_internalSwings[i].Reset();
        }
    }

    /// @brief Processes newly closed bars and confirms any new swings.
    ///
    /// Source: kennystrstegy.md Phase 1B — Update():
    ///   "Every closed candle: Check Swing High → Check Swing Low →
    ///    Store → Return. Never analyse the forming candle."
    ///   "Performance: Store LastProcessedBar. When New Candle? YES →
    ///    Process One Candle → Done."
    ///
    /// Arrays must be indexed as time-series (index 0 = newest bar)
    /// before this call. The caller is responsible for applying
    /// ArraySetAsSeries() or equivalent.
    ///
    /// @param high           High price array (series order, 0 = newest).
    /// @param low            Low price array (series order, 0 = newest).
    /// @param time           Open time array (series order, 0 = newest).
    /// @param ratesTotal     Total number of bars in the supplied arrays.
    /// @param prevCalculated Bars calculated on prior call (OnCalculate convention).
    ///                       Pass 0 to trigger a full history scan.
    ///
    /// @return True if at least one new swing was confirmed this call.
    bool Update(const double   &high[],
                const double   &low[],
                const datetime &time[],
                int             ratesTotal,
                int             prevCalculated)
    {
        double emptyAtr[];
        return Update(high, low, time, ratesTotal, prevCalculated, emptyAtr);
    }

    /// @brief Processes newly closed bars and confirms any new swings with ATR.
    bool Update(const double   &high[],
                const double   &low[],
                const datetime &time[],
                int             ratesTotal,
                int             prevCalculated,
                const double   &atr[])
    {
        if (!m_isInitialized)
            return false;

        //--- Minimum bars required for any confirmation:
        //--- External needs externalDepth on each side + the pivot itself.
        int minBars = (m_externalDepth * 2) + 1;
        if (ratesTotal < minBars)
            return false;

        //--- Series index boundaries
        int newestEvaluable = m_externalDepth;

        //--- Clamp newestEvaluable to strategy minimum shift.
        if (newestEvaluable < MNS_SWING_MIN_SHIFT)
            newestEvaluable = MNS_SWING_MIN_SHIFT;

        //--- Oldest bar with a full left-side window for external detection.
        int oldestEvaluable = ratesTotal - m_externalDepth - 1;

        if (oldestEvaluable < newestEvaluable)
            return false;

        //--- Determine start of scan for this call.
        int startIndex = (prevCalculated == 0) ? oldestEvaluable : newestEvaluable;

        if (startIndex > oldestEvaluable)
            startIndex = oldestEvaluable;

        bool confirmed = false;

        //--- Scan oldest → newest to maintain chronological storage order.
        for (int i = startIndex; i >= newestEvaluable; i--)
        {
            double atrVal = (ArraySize(atr) > i) ? atr[i] : 0.0;
            if (EvaluateBar(i, high, low, time, ratesTotal, atrVal))
                confirmed = true;
        }

        //--- Also evaluate bars that have enough right-side bars for internal
        //--- but not for external (indices [internalDepth .. externalDepth - 1]).
        //--- Only on full rescan to avoid redundant processing.
        if (prevCalculated == 0)
        {
            int internalOnlyStart = newestEvaluable - 1;
            int internalOnlyEnd   = m_internalDepth;

            if (internalOnlyEnd < MNS_SWING_MIN_SHIFT)
                internalOnlyEnd = MNS_SWING_MIN_SHIFT;

            for (int i = internalOnlyStart; i >= internalOnlyEnd; i--)
            {
                double atrVal = (ArraySize(atr) > i) ? atr[i] : 0.0;
                if (EvaluateInternalBar(i, high, low, time, ratesTotal, atrVal))
                    confirmed = true;
            }
        }

        return confirmed;
    }

    //+------------------------------------------------------------------+
    //| External Swing Accessors                                         |
    //+------------------------------------------------------------------+

    /// @brief Returns the number of confirmed external swings stored.
    ///
    /// Source: kennystrstegy.md Phase 1B: "int GetExternalSwingCount();"
    ///
    /// @return External swing count. Zero if none confirmed.
    int GetExternalSwingCount() const
    {
        return m_externalCount;
    }

    /// @brief Returns the confirmed external swing at the given index.
    ///
    /// Source: kennystrstegy.md Phase 1B:
    ///   "MNS_SwingPoint GetExternalSwing(int index);"
    ///
    /// Storage is chronological: index 0 = oldest, count-1 = newest.
    ///
    /// @param index  Zero-based storage index.
    ///
    /// @return Copy of the requested swing, or an empty (reset) SSwingPoint
    ///         if the index is out of range.
    ///
    /// Note: Returns by value — MQL5 does not support const reference
    ///       returns from const methods on member arrays.
    SSwingPoint GetExternalSwing(int index) const
    {
        if (index < 0 || index >= m_externalCount)
            return m_emptySwing;

        return m_externalSwings[index];
    }

    /// @brief Returns the most recently confirmed external swing high.
    ///
    /// Source: kennystrstegy.md Phase 1B:
    ///   "MNS_SwingPoint GetLatestExternalHigh();"
    ///
    /// @return Copy of the latest external high, or an empty SSwingPoint
    ///         if none has been confirmed.
    SSwingPoint GetLatestExternalHigh() const
    {
        if (!m_latestExternalHigh.isConfirmed)
            return m_emptySwing;

        return m_latestExternalHigh;
    }

    /// @brief Returns the most recently confirmed external swing low.
    ///
    /// Source: kennystrstegy.md Phase 1B:
    ///   "MNS_SwingPoint GetLatestExternalLow();"
    ///
    /// @return Copy of the latest external low, or an empty SSwingPoint
    ///         if none has been confirmed.
    SSwingPoint GetLatestExternalLow() const
    {
        if (!m_latestExternalLow.isConfirmed)
            return m_emptySwing;

        return m_latestExternalLow;
    }

    //+------------------------------------------------------------------+
    //| Internal Swing Accessors                                         |
    //+------------------------------------------------------------------+

    /// @brief Returns the number of confirmed internal swings stored.
    ///
    /// Source: kennystrstegy.md Phase 1B: "int GetInternalSwingCount();"
    ///
    /// @return Internal swing count. Zero if none confirmed.
    int GetInternalSwingCount() const
    {
        return m_internalCount;
    }

    /// @brief Returns the confirmed internal swing at the given index.
    ///
    /// Source: kennystrstegy.md Phase 1B:
    ///   "MNS_SwingPoint GetInternalSwing(int index);"
    ///
    /// @param index  Zero-based storage index.
    ///
    /// @return Copy of the requested swing, or an empty (reset) SSwingPoint
    ///         if the index is out of range.
    SSwingPoint GetInternalSwing(int index) const
    {
        if (index < 0 || index >= m_internalCount)
            return m_emptySwing;

        return m_internalSwings[index];
    }

    /// @brief Returns the most recently confirmed internal swing high.
    ///
    /// Source: kennystrstegy.md Phase 1B:
    ///   "MNS_SwingPoint GetLatestInternalHigh();"
    ///
    /// @return Copy of the latest internal high, or an empty SSwingPoint
    ///         if none has been confirmed.
    SSwingPoint GetLatestInternalHigh() const
    {
        if (!m_latestInternalHigh.isConfirmed)
            return m_emptySwing;

        return m_latestInternalHigh;
    }

    /// @brief Returns the most recently confirmed internal swing low.
    ///
    /// Source: kennystrstegy.md Phase 1B:
    ///   "MNS_SwingPoint GetLatestInternalLow();"
    ///
    /// @return Copy of the latest internal low, or an empty SSwingPoint
    ///         if none has been confirmed.
    SSwingPoint GetLatestInternalLow() const
    {
        if (!m_latestInternalLow.isConfirmed)
            return m_emptySwing;

        return m_latestInternalLow;
    }

    //+------------------------------------------------------------------+
    //| Compatibility accessors (preserve prior public API)              |
    //+------------------------------------------------------------------+

    /// @brief Returns true if any external or internal swing is confirmed.
    ///
    /// @return True when m_externalCount > 0 or m_internalCount > 0.
    bool HasConfirmedSwing() const
    {
        return (m_externalCount > 0 || m_internalCount > 0);
    }

    /// @brief Returns the total confirmed swing count across both levels.
    ///
    /// @return Sum of external and internal confirmed swing counts.
    int GetSwingCount() const
    {
        return m_externalCount + m_internalCount;
    }

    /// @brief Returns the most recently confirmed swing across both levels.
    ///
    /// Compares the last stored external and internal swings by bar index
    /// (lower barIndex = more recent in series order) and returns a copy
    /// of the newer one.
    ///
    /// @return Copy of the most recent confirmed swing, or an empty
    ///         SSwingPoint if no swings exist.
    SSwingPoint GetLatestSwing() const
    {
        bool hasExt = (m_externalCount > 0);
        bool hasInt = (m_internalCount > 0);

        if (!hasExt && !hasInt)
            return m_emptySwing;

        if (!hasExt)
            return m_internalSwings[m_internalCount - 1];

        if (!hasInt)
            return m_externalSwings[m_externalCount - 1];

        //--- Lower bar index = more recent (series order: 0 = newest).
        //--- Use local value copies — MQL5 does not support const references
        //--- to array elements inside const methods.
        SSwingPoint lastExt = m_externalSwings[m_externalCount - 1];
        SSwingPoint lastInt = m_internalSwings[m_internalCount - 1];

        return (lastExt.barIndex <= lastInt.barIndex) ? lastExt : lastInt;
    }

private:
    //+------------------------------------------------------------------+
    //| Private — Bar Evaluation                                        |
    //+------------------------------------------------------------------+

    /// @brief Evaluates a single bar for both external and internal swings.
    ///
    /// External and internal checks are performed independently.
    /// A bar may simultaneously qualify as both an external and
    /// internal swing high (or low) — both are stored separately.
    ///
    /// @param index      Bar index to evaluate (series order).
    /// @param high       High price array.
    /// @param low        Low price array.
    /// @param time       Bar time array.
    /// @param ratesTotal Total bars.
    ///
    /// @return True if at least one swing was confirmed at this bar.
    bool EvaluateBar(int             index,
                     const double   &high[],
                     const double   &low[],
                     const datetime &time[],
                     int             ratesTotal,
                     double          atrValue)
    {
        bool confirmed = false;

        //--- External checks (requires full externalDepth window on each side)
        if (IsExternalSwingHigh(index, high, ratesTotal, atrValue))
        {
            if (StoreExternal(index, high[index], time[index], SWING_HIGH))
                confirmed = true;
        }

        if (IsExternalSwingLow(index, low, ratesTotal, atrValue))
        {
            if (StoreExternal(index, low[index], time[index], SWING_LOW))
                confirmed = true;
        }

        //--- Internal checks (requires full internalDepth window on each side)
        if (IsInternalSwingHigh(index, high, ratesTotal, atrValue))
        {
            if (StoreInternal(index, high[index], time[index], SWING_HIGH))
                confirmed = true;
        }

        if (IsInternalSwingLow(index, low, ratesTotal, atrValue))
        {
            if (StoreInternal(index, low[index], time[index], SWING_LOW))
                confirmed = true;
        }

        return confirmed;
    }

    /// @brief Evaluates a single bar for internal swings only.
    bool EvaluateInternalBar(int             index,
                             const double   &high[],
                             const double   &low[],
                             const datetime &time[],
                             int             ratesTotal,
                             double          atrValue)
    {
        bool confirmed = false;

        if (IsInternalSwingHigh(index, high, ratesTotal, atrValue))
        {
            if (StoreInternal(index, high[index], time[index], SWING_HIGH))
                confirmed = true;
        }

        if (IsInternalSwingLow(index, low, ratesTotal, atrValue))
        {
            if (StoreInternal(index, low[index], time[index], SWING_LOW))
                confirmed = true;
        }

        return confirmed;
    }

    //+------------------------------------------------------------------+
    //| Private — Strategy Confirmation Rules                           |
    //+------------------------------------------------------------------+

    /// @brief Returns true if bar[index] is a confirmed External Swing High.
    ///
    /// Source: kennystrstegy.md — Phase 1B, External Swing High:
    ///   "Candidate Candle → Highest High → Look Left 15 candles →
    ///    Look Right 15 candles → Highest? YES → External Swing High"
    ///
    ///   Pseudocode: "Current High → Loop Left → Higher? → Reject →
    ///    Loop Right → Higher? → Reject → Otherwise Confirm Swing"
    ///
    /// The pivot high must be strictly greater than every high in the
    /// left window (older bars, higher series indices) and every high
    /// in the right window (newer bars, lower series indices).
    ///
    /// @param index      Candidate bar index (series order, 0 = newest).
    /// @param high       High price array (series order).
    /// @param ratesTotal Total bars for bounds checking.
    ///
    /// @return True if bar[index].high is strictly highest in the
    ///         [index-15 .. index+15] window (excluding index itself).
    bool IsExternalSwingHigh(int           index,
                             const double &high[],
                             int           ratesTotal,
                             double        atrValue) const
    {
        return IsHighestInWindow(index, high[index], high, m_externalDepth, ratesTotal, atrValue);
    }

    /// @brief Returns true if bar[index] is a confirmed External Swing Low.
    bool IsExternalSwingLow(int           index,
                            const double &low[],
                            int           ratesTotal,
                            double        atrValue) const
    {
        return IsLowestInWindow(index, low[index], low, m_externalDepth, ratesTotal, atrValue);
    }

    /// @brief Returns true if bar[index] is a confirmed Internal Swing High.
    bool IsInternalSwingHigh(int           index,
                             const double &high[],
                             int           ratesTotal,
                             double        atrValue) const
    {
        return IsHighestInWindow(index, high[index], high, m_internalDepth, ratesTotal, atrValue);
    }

    /// @brief Returns true if bar[index] is a confirmed Internal Swing Low.
    bool IsInternalSwingLow(int           index,
                            const double &low[],
                            int           ratesTotal,
                            double        atrValue) const
    {
        return IsLowestInWindow(index, low[index], low, m_internalDepth, ratesTotal, atrValue);
    }

    //+------------------------------------------------------------------+
    //| Private — Window Comparison Primitives                          |
    //+------------------------------------------------------------------+

    /// @brief Returns true if pivot is strictly greater than ALL values
    ///        in the symmetric window of size depth on each side.
    ///
    /// In MQL5 time-series indexing:
    ///   Left side  (older bars) = indices [index+1 .. index+depth]
    ///   Right side (newer bars) = indices [index-1 .. index-depth]
    ///
    /// Both windows must be fully within bounds. If any bar in either
    /// window has a value >= pivot, the candidate is rejected.
    ///
    /// Source: kennystrstegy.md Phase 1B pseudocode:
    ///   "Loop Left → Higher? → Reject → Loop Right → Higher? → Reject"
    ///
    /// @param index   Series index of the pivot bar.
    /// @param pivot   The pivot high value to compare against.
    /// @param arr     Price array to compare (high values).
    /// @param depth   Number of bars to check on each side.
    /// @param total   Total bars in arr for bounds safety.
    ///
    /// @return True if pivot is strictly the highest in the window.
    bool IsHighestInWindow(int           index,
                           double        pivot,
                           const double &arr[],
                           int           depth,
                           int           total,
                           double        atrValue) const
    {
        //--- Validate left-side bounds (older bars = higher series indices).
        if (index + depth >= total)
            return false;

        //--- Validate right-side bounds (newer bars = lower series indices).
        if (index - depth < 0)
            return false;

        double tolerance = MathMax(2.0 * _Point, 0.05 * atrValue);

        //--- Loop left: older bars (must be strictly higher or reject if equal/greater within tolerance)
        for (int j = index + 1; j <= index + depth; j++)
        {
            if (arr[j] >= pivot - tolerance)
                return false;
        }

        //--- Loop right: newer bars (pivot is the earlier swing, so allow equal right-side touches)
        for (int j = index - 1; j >= index - depth; j--)
        {
            if (arr[j] > pivot + tolerance)
                return false;
        }

        return true;
    }

    /// @brief Returns true if pivot is strictly less than ALL values
    ///        in the symmetric window of size depth on each side (with tolerance).
    bool IsLowestInWindow(int           index,
                          double        pivot,
                          const double &arr[],
                          int           depth,
                          int           total,
                          double        atrValue) const
    {
        //--- Validate left-side bounds.
        if (index + depth >= total)
            return false;

        //--- Validate right-side bounds.
        if (index - depth < 0)
            return false;

        double tolerance = MathMax(2.0 * _Point, 0.05 * atrValue);

        //--- Loop left: older bars (must be strictly lower or reject if equal/lower within tolerance)
        for (int j = index + 1; j <= index + depth; j++)
        {
            if (arr[j] <= pivot + tolerance)
                return false;
        }

        //--- Loop right: newer bars (pivot is the earlier swing, so allow equal right-side touches)
        for (int j = index - 1; j >= index - depth; j--)
        {
            if (arr[j] < pivot - tolerance)
                return false;
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| Private — Storage                                                |
    //+------------------------------------------------------------------+

    /// @brief Builds and stores a confirmed external swing.
    ///
    /// Applies duplicate protection before storage.
    ///
    /// Source: kennystrstegy.md Phase 1B — Create Swing Object:
    ///   "swing.price = High[index]; swing.time = Time[index];
    ///    swing.bar_index = index; swing.confirmed = true;
    ///    swing.active = true;"
    ///
    /// Source: Phase 1B — Duplicate Protection:
    ///   "Before storing: Check Same Time? Already Exists? Ignore.
    ///    Otherwise Save."
    ///
    /// @param index      Bar index of the confirmed swing candle.
    /// @param price      Price level (high or low of the pivot candle).
    /// @param time       Open time of the pivot candle.
    /// @param swingType  SWING_HIGH or SWING_LOW.
    ///
    /// @return True if stored. False if duplicate or at capacity.
    bool StoreExternal(int        index,
                       double     price,
                       datetime   time,
                       ESwingType swingType)
    {
        if (IsDuplicateExternal(time, swingType))
            return false;

        if (m_externalCount >= MNS_MAX_SWINGS)
            return false;

        SSwingPoint swing;
        swing.barIndex    = index;
        swing.price       = price;
        swing.time        = time;
        swing.type        = swingType;
        swing.level       = SWING_LEVEL_EXTERNAL;
        swing.isConfirmed = true;

        m_externalSwings[m_externalCount] = swing;
        m_externalCount++;

        //--- Update cached latest for O(1) retrieval.
        if (swingType == SWING_HIGH)
            m_latestExternalHigh = swing;
        else
            m_latestExternalLow = swing;

        return true;
    }

    /// @brief Builds and stores a confirmed internal swing.
    ///
    /// Source: kennystrstegy.md Phase 1B — same storage rules as external.
    ///
    /// @param index      Bar index of the confirmed swing candle.
    /// @param price      Price level.
    /// @param time       Open time of the pivot candle.
    /// @param swingType  SWING_HIGH or SWING_LOW.
    ///
    /// @return True if stored. False if duplicate or at capacity.
    bool StoreInternal(int        index,
                       double     price,
                       datetime   time,
                       ESwingType swingType)
    {
        if (IsDuplicateInternal(time, swingType))
            return false;

        if (m_internalCount >= MNS_MAX_SWINGS)
            return false;

        SSwingPoint swing;
        swing.barIndex    = index;
        swing.price       = price;
        swing.time        = time;
        swing.type        = swingType;
        swing.level       = SWING_LEVEL_INTERNAL;
        swing.isConfirmed = true;

        m_internalSwings[m_internalCount] = swing;
        m_internalCount++;

        //--- Update cached latest for O(1) retrieval.
        if (swingType == SWING_HIGH)
            m_latestInternalHigh = swing;
        else
            m_latestInternalLow = swing;

        return true;
    }

    /// @brief Returns true if an external swing at the same time and
    ///        type was already stored.
    ///
    /// Source: kennystrstegy.md Phase 1B — Duplicate Protection:
    ///   "Check Same Time? Already Exists? Ignore."
    ///
    /// Checks the most recently stored external swing. Relies on the
    /// scan direction (oldest to newest) guaranteeing that if a
    /// duplicate exists it is the last stored entry.
    ///
    /// @param time       Open time of the candidate candle.
    /// @param swingType  Swing type of the candidate.
    ///
    /// @return True if the candidate is a duplicate.
    bool IsDuplicateExternal(datetime time, ESwingType swingType) const
    {
        if (m_externalCount == 0)
            return false;

        SSwingPoint last = m_externalSwings[m_externalCount - 1];
        return (last.time == time && last.type == swingType);
    }

    /// @brief Returns true if an internal swing at the same time and
    ///        type was already stored.
    ///
    /// Source: kennystrstegy.md Phase 1B — Duplicate Protection:
    ///   "Check Same Time? Already Exists? Ignore."
    ///
    /// @param time       Open time of the candidate candle.
    /// @param swingType  Swing type of the candidate.
    ///
    /// @return True if the candidate is a duplicate.
    bool IsDuplicateInternal(datetime time, ESwingType swingType) const
    {
        if (m_internalCount == 0)
            return false;

        SSwingPoint last = m_internalSwings[m_internalCount - 1];
        return (last.time == time && last.type == swingType);
    }
};

//+------------------------------------------------------------------+
//| End of CSwingDetector.mqh                                        |
//+------------------------------------------------------------------+

#endif // __MNS_SWING_DETECTOR_MQH__
