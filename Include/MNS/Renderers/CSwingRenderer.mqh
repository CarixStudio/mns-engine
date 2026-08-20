//+------------------------------------------------------------------+
//|                                               CSwingRenderer.mqh |
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Visual controller for rendering internal and external swing    |
//|   highs/lows on the chart using MT5 arrow objects. Handles       |
//|   capping limits and automatic cleanup of historical objects.    |
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh                                                   |
//|   CSwingDetector.mqh                                             |
//|   MNSStyle.mqh                                                   |
//+------------------------------------------------------------------+
#ifndef __MNS_SWING_RENDERER_MQH__
#define __MNS_SWING_RENDERER_MQH__

#include "../MNSTypes.mqh"
#include "../CSwingDetector.mqh"
#include "../MNSStyle.mqh"

class CSwingRenderer
{
private:
    SIndicatorStyle m_style;        ///< Cached visual style configuration
    int             m_maxSwings;    ///< Capping limit for rendered swing objects
    bool            m_isInitialized; ///< Initialization guard flag

    // Helper: Returns the confirmation bar's datetime using the swing's barIndex directly.
    // SSwingPoint.barIndex is the origin bar index in time-series order (0 = newest).
    // The confirmation bar is `depth` bars more recent (lower index) than the origin.
    // This is an O(1) lookup — no linear scan required.
    datetime GetConfirmationTime(const SSwingPoint &swing, const datetime &time[], int ratesTotal, int depth)
    {
        int originIdx = swing.barIndex;
        if (originIdx < 0 || originIdx >= ratesTotal)
            return 0;

        int confirmIdx = originIdx - depth; // More recent in time-series (lower index = more recent)
        if (confirmIdx < 0 || confirmIdx >= ratesTotal)
            return 0;

        return time[confirmIdx];
    }

    // Helper: Generates a unique object name for a swing point
    string GetObjectName(const SSwingPoint &swing) const
    {
        string levelChar = (swing.level == SWING_LEVEL_EXTERNAL) ? "E" : "I";
        string typeChar  = (swing.type == SWING_HIGH) ? "H" : "L";
        return StringFormat("MNS_Swing_%s%s_%s", levelChar, typeChar, IntegerToString((long)swing.time));
    }

    // Helper: Creates or updates an arrow object on the chart
    void RenderSwing(const SSwingPoint &swing, datetime confTime, double atrVal)
    {
        string name = GetObjectName(swing);
        
        // Calculate offset buffer using 0.2 ATR(14)
        double buffer = 0.2 * atrVal;
        double price = (swing.type == SWING_HIGH) ? (swing.price + buffer) : (swing.price - buffer);

        // Determine design tokens based on level and type
        color arrowColor;
        int arrowSize;
        int arrowCode;

        if (swing.level == SWING_LEVEL_EXTERNAL)
        {
            arrowColor = (swing.type == SWING_HIGH) ? m_style.colorExtHigh : m_style.colorExtLow;
            arrowSize  = m_style.sizeExtArrow;
            arrowCode  = (swing.type == SWING_HIGH) ? m_style.codeArrowHigh : m_style.codeArrowLow;
        }
        else // SWING_LEVEL_INTERNAL
        {
            arrowColor = (swing.type == SWING_HIGH) ? m_style.colorIntHigh : m_style.colorIntLow;
            arrowSize  = m_style.sizeIntArrow;
            arrowCode  = (swing.type == SWING_HIGH) ? m_style.codeArrowHigh : m_style.codeArrowLow;
        }

        // Create the arrow object if it doesn't exist
        if (ObjectFind(0, name) < 0)
        {
            if (!ObjectCreate(0, name, OBJ_ARROW, 0, confTime, price))
            {
                Print(StringFormat("[ERROR] [CSwingRenderer] Failed to create object %s. Error code: %d", name, GetLastError()));
                return;
            }
        }
        else
        {
            // Update coordinates in case they shifted (dynamic updates)
            ObjectMove(0, name, 0, confTime, price);
        }

        // Set visual properties
        ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
        ObjectSetInteger(0, name, OBJPROP_COLOR, arrowColor);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, arrowSize);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    }

public:
    // Constructor
    CSwingRenderer() : m_maxSwings(50), m_isInitialized(false)
    {
        m_style.Reset();
    }

    // Deconstructor
    ~CSwingRenderer()
    {
        Reset();
    }

    /// @brief Initializes the Swing Renderer with custom style and limits.
    /// @param style Shared visual style configuration.
    /// @param maxSwings Max number of swings to keep rendered.
    /// @return True on success.
    bool Initialize(const SIndicatorStyle &style, int maxSwings)
    {
        m_style = style;
        m_maxSwings = (maxSwings > 0) ? maxSwings : 50;
        m_isInitialized = true;
        return true;
    }

    /// @brief Clears all swing point objects from the chart.
    void Reset()
    {
        ObjectsDeleteAll(0, "MNS_Swing_");
    }

    /// @brief Processes swing point arrays and draws/cleans chart objects.
    /// @param swingDetector Source CSwingDetector engine.
    /// @param time Chart datetime array (time-series sorted).
    /// @param ratesTotal Total chart bars.
    /// @param currentAtr Current ATR value for offset calculations.
    void Draw(const CSwingDetector &swingDetector, const datetime &time[], int ratesTotal, double currentAtr)
    {
        if (!m_isInitialized)
            return;

        // Render External Swings
        int extCount = swingDetector.GetExternalSwingCount();
        int extStartIdx = extCount - m_maxSwings;
        if (extStartIdx < 0) extStartIdx = 0;

        for (int i = 0; i < extCount; i++)
        {
            SSwingPoint swing = swingDetector.GetExternalSwing(i);
            if (!swing.isConfirmed)
                continue;

            string name = GetObjectName(swing);

            if (i < extStartIdx)
            {
                // Delete old swing objects exceeding the capping limit
                if (ObjectFind(0, name) >= 0)
                    ObjectDelete(0, name);
            }
            else
            {
                datetime confTime = GetConfirmationTime(swing, time, ratesTotal, MNS_SWING_EXTERNAL_DEPTH);
                if (confTime > 0)
                {
                    RenderSwing(swing, confTime, currentAtr);
                }
            }
        }

        // Render Internal Swings
        int intCount = swingDetector.GetInternalSwingCount();
        int intStartIdx = intCount - m_maxSwings;
        if (intStartIdx < 0) intStartIdx = 0;

        for (int i = 0; i < intCount; i++)
        {
            SSwingPoint swing = swingDetector.GetInternalSwing(i);
            if (!swing.isConfirmed)
                continue;

            string name = GetObjectName(swing);

            if (i < intStartIdx)
            {
                // Delete old swing objects exceeding the capping limit
                if (ObjectFind(0, name) >= 0)
                    ObjectDelete(0, name);
            }
            else
            {
                datetime confTime = GetConfirmationTime(swing, time, ratesTotal, MNS_SWING_INTERNAL_DEPTH);
                if (confTime > 0)
                {
                    RenderSwing(swing, confTime, currentAtr);
                }
            }
        }
    }
};

#endif // __MNS_SWING_RENDERER_MQH__
