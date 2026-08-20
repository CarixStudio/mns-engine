//+------------------------------------------------------------------+
//|                                           CStructureRenderer.mqh |
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Visual controller for rendering BOS and CHoCH lines and labels |
//|   on the chart using MT5 trend lines and text objects. Handles   |
//|   capping limits and automatic cleanup of historical objects.    |
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh                                                   |
//|   CBreakDetector.mqh                                             |
//|   MNSStyle.mqh                                                   |
//+------------------------------------------------------------------+
#ifndef __MNS_STRUCTURE_RENDERER_MQH__
#define __MNS_STRUCTURE_RENDERER_MQH__

#include "../MNSTypes.mqh"
#include "../CBreakDetector.mqh"
#include "../MNSStyle.mqh"

class CStructureRenderer
{
private:
    SIndicatorStyle m_style;        ///< Cached visual style configuration
    int             m_maxBreaks;    ///< Capping limit for rendered break objects
    bool            m_isInitialized; ///< Initialization guard flag

    // Helper: Generates unique object name for a break line
    string GetLineObjectName(const SStructureBreak &brk) const
    {
        string breakTypeStr;
        switch (brk.breakType)
        {
            case BREAK_BOS:          breakTypeStr = "BOS"; break;
            case BREAK_INTERNAL_BOS: breakTypeStr = "iBOS"; break;
            case BREAK_CHOCH:        breakTypeStr = "CHOCH"; break;
            default:                 breakTypeStr = "BRK"; break;
        }
        string dirStr = (brk.brokenSwing.type == SWING_HIGH) ? "B" : "Be"; // Bullish breaks swing high, Bearish breaks swing low
        return StringFormat("MNS_BrkLine_%s_%s_%s", breakTypeStr, dirStr, IntegerToString((long)brk.time));
    }

    // Helper: Generates unique object name for a break label
    string GetLabelObjectName(const SStructureBreak &brk) const
    {
        string breakTypeStr;
        switch (brk.breakType)
        {
            case BREAK_BOS:          breakTypeStr = "BOS"; break;
            case BREAK_INTERNAL_BOS: breakTypeStr = "iBOS"; break;
            case BREAK_CHOCH:        breakTypeStr = "CHOCH"; break;
            default:                 breakTypeStr = "BRK"; break;
        }
        string dirStr = (brk.brokenSwing.type == SWING_HIGH) ? "B" : "Be";
        return StringFormat("MNS_BrkLabel_%s_%s_%s", breakTypeStr, dirStr, IntegerToString((long)brk.time));
    }

    // Helper: Creates or updates line and label objects on the chart
    void RenderBreak(const SStructureBreak &brk)
    {
        string lineName  = GetLineObjectName(brk);
        string labelName = GetLabelObjectName(brk);

        // Coordinates:
        // Start: time of the broken swing, price of the broken swing
        // End: time of the breaking candle, price of the broken swing
        datetime time1 = brk.brokenSwing.time;
        double   price = brk.brokenSwing.price;
        datetime time2 = brk.time;

        // Visual attributes selection
        color    lineColor;
        int      lineWidth;
        ENUM_LINE_STYLE lineStyle;
        string   labelText;

        bool isBullish = (brk.brokenSwing.type == SWING_HIGH); // Breaking a swing high is bullish

        if (brk.breakType == BREAK_CHOCH)
        {
            lineColor = isBullish ? m_style.colorBullishCHoCH : m_style.colorBearishCHoCH;
            lineWidth = m_style.widthCHoCHLine;
            lineStyle = m_style.styleCHoCH;
            labelText = "CHoCH";
        }
        else if (brk.breakType == BREAK_INTERNAL_BOS)
        {
            lineColor = isBullish ? m_style.colorIntHigh : m_style.colorIntLow; // Muted/internal swing colors
            lineWidth = m_style.widthBOSLine;
            lineStyle = m_style.styleBOS;
            labelText = "iBOS";
        }
        else // BREAK_BOS
        {
            lineColor = isBullish ? m_style.colorBullishBOS : m_style.colorBearishBOS;
            lineWidth = m_style.widthBOSLine;
            lineStyle = m_style.styleBOS;
            labelText = "BOS";
        }

        // --- 1. Draw/Update the Trend Line Object ---
        if (ObjectFind(0, lineName) < 0)
        {
            if (!ObjectCreate(0, lineName, OBJ_TREND, 0, time1, price, time2, price))
            {
                Print(StringFormat("[ERROR] [CStructureRenderer] Failed to create line object %s. Error code: %d", lineName, GetLastError()));
                return;
            }
        }
        else
        {
            ObjectMove(0, lineName, 0, time1, price);
            ObjectMove(0, lineName, 1, time2, price);
        }

        // Set line visual properties
        ObjectSetInteger(0, lineName, OBJPROP_COLOR, lineColor);
        ObjectSetInteger(0, lineName, OBJPROP_WIDTH, lineWidth);
        ObjectSetInteger(0, lineName, OBJPROP_STYLE, lineStyle);
        ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false); // Do not extend line infinitely right
        ObjectSetInteger(0, lineName, OBJPROP_RAY_LEFT, false);
        ObjectSetInteger(0, lineName, OBJPROP_BACK, true);       // Draw behind candles
        ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, lineName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, lineName, OBJPROP_HIDDEN, true);

        // --- 2. Draw/Update the Text Label Object ---
        if (ObjectFind(0, labelName) < 0)
        {
            if (!ObjectCreate(0, labelName, OBJ_TEXT, 0, time2, price))
            {
                Print(StringFormat("[ERROR] [CStructureRenderer] Failed to create label object %s. Error code: %d", labelName, GetLastError()));
                return;
            }
        }
        else
        {
            ObjectMove(0, labelName, 0, time2, price);
        }

        // Set label properties
        ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
        ObjectSetString(0, labelName, OBJPROP_FONT, m_style.fontName);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, m_style.fontSizeLabel);
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, lineColor);
        ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT); // Anchor text to start of the label at the right of line
        ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, labelName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
    }

public:
    // Constructor
    CStructureRenderer() : m_maxBreaks(20), m_isInitialized(false)
    {
        m_style.Reset();
    }

    // Deconstructor
    ~CStructureRenderer()
    {
        Reset();
    }

    /// @brief Initializes the Structure Renderer with custom style and limits.
    /// @param style Shared visual style configuration.
    /// @param maxBreaks Max number of breaks to keep rendered.
    /// @return True on success.
    bool Initialize(const SIndicatorStyle &style, int maxBreaks)
    {
        m_style = style;
        m_maxBreaks = (maxBreaks > 0) ? maxBreaks : 20;
        m_isInitialized = true;
        return true;
    }

    /// @brief Clears all structure break objects from the chart.
    void Reset()
    {
        ObjectsDeleteAll(0, "MNS_BrkLine_");
        ObjectsDeleteAll(0, "MNS_BrkLabel_");
    }

    /// @brief Processes structure break arrays and draws/cleans chart objects.
    /// @param breakDetector Source CBreakDetector engine.
    /// @param time Chart datetime array (time-series sorted).
    /// @param ratesTotal Total chart bars.
    void Draw(const CBreakDetector &breakDetector, const datetime &time[], int ratesTotal)
    {
        if (!m_isInitialized)
            return;

        int breakCount = breakDetector.GetBreakCount();
        int startIdx = breakCount - m_maxBreaks;
        if (startIdx < 0) startIdx = 0;

        for (int i = 0; i < breakCount; i++)
        {
            SStructureBreak brk = breakDetector.GetBreak(i);
            if (!brk.isConfirmed)
                continue;

            string lineName  = GetLineObjectName(brk);
            string labelName = GetLabelObjectName(brk);

            if (i < startIdx)
            {
                // Delete old objects exceeding the capping limit
                if (ObjectFind(0, lineName) >= 0)
                    ObjectDelete(0, lineName);
                if (ObjectFind(0, labelName) >= 0)
                    ObjectDelete(0, labelName);
            }
            else
            {
                RenderBreak(brk);
            }
        }
    }
};

#endif // __MNS_STRUCTURE_RENDERER_MQH__
