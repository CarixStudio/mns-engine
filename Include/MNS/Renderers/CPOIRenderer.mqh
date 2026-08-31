//+------------------------------------------------------------------+
//|                                                CPOIRenderer.mqh  |
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Visual controller for rendering POI zones (OB, Breaker, MB, FVG)|
//|   on the chart using MT5 rectangle objects. Handles capping      |
//|   limits and automatic cleanup of historical and invalid objects.|
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh                                                   |
//|   CPOIEngine.mqh                                                 |
//|   MNSStyle.mqh                                                   |
//+------------------------------------------------------------------+
#ifndef __MNS_POI_RENDERER_MQH__
#define __MNS_POI_RENDERER_MQH__

#include "../MNSTypes.mqh"
#include "../CPOIEngine.mqh"
#include "../MNSStyle.mqh"

//+------------------------------------------------------------------+
//| CPOIRenderer                                                     |
//| @brief Draws POI zones as filled rectangles on the chart.         |
//+------------------------------------------------------------------+
class CPOIRenderer
{
private:
    SIndicatorStyle m_style;           ///< Cached visual style configuration
    int             m_maxPOIs;         ///< Capping limit for rendered POI objects
    bool            m_isInitialized;    ///< Initialization guard flag

    /// @brief Generates a unique object name for a POI based on its ID and type.
    /// @param id Unique POI identifier.
    /// @param type POI type.
    /// @return The constructed chart object name.
    string GetObjectName(int id, EPoIType type) const
    {
        string typeStr = "";
        switch (type)
        {
            case POI_OB_BULLISH:         typeStr = "OBB"; break;
            case POI_OB_BEARISH:         typeStr = "OBBe"; break;
            case POI_BREAKER_BULLISH:    typeStr = "BrkB"; break;
            case POI_BREAKER_BEARISH:    typeStr = "BrkBe"; break;
            case POI_MITIGATION_BULLISH: typeStr = "MBB"; break;
            case POI_MITIGATION_BEARISH: typeStr = "MBBe"; break;
            case POI_FVG_BULLISH:        typeStr = "FVGB"; break;
            case POI_FVG_BEARISH:        typeStr = "FVGBe"; break;
            default:                     typeStr = "POI"; break;
        }
        return StringFormat("MNS_POI_%s_%d", typeStr, id);
    }

    /// @brief Generates the label object name for a POI zone.
    string GetLabelName(int id, EPoIType type) const
    {
        return StringFormat("MNS_POILbl_%d_%d", (int)type, id);
    }

    /// @brief Converts POI type to short display string.
    string GetPoiTypeLabel(EPoIType type) const
    {
        switch (type)
        {
            case POI_OB_BULLISH:         return "BULLISH OB";
            case POI_OB_BEARISH:         return "BEARISH OB";
            case POI_BREAKER_BULLISH:    return "BULLISH BRK";
            case POI_BREAKER_BEARISH:    return "BEARISH BRK";
            case POI_MITIGATION_BULLISH: return "BULLISH MB";
            case POI_MITIGATION_BEARISH: return "BEARISH MB";
            case POI_FVG_BULLISH:        return "BULLISH FVG";
            case POI_FVG_BEARISH:        return "BEARISH FVG";
            default:                     return "POI";
        }
    }

    /// @brief Checks if a POI is active or mitigated (and thus renderable).
    /// @param poi The POI definition.
    /// @return True if the POI should be drawn.
    bool IsPoiRenderable(const SPoIDefinition &poi) const
    {
        if (!poi.active && poi.lifecycle != POI_STATE_PARTIAL_MITIGATED && poi.lifecycle != POI_STATE_MATERIAL_MITIGATED)
            return false;
            
        return (poi.lifecycle == POI_STATE_ACTIVE || 
                poi.lifecycle == POI_STATE_PARTIAL_MITIGATED || 
                poi.lifecycle == POI_STATE_MATERIAL_MITIGATED);
    }

    /// @brief Renders or updates a single POI rectangle object on the chart.
    /// @param poi The POI definition.
    /// @param lastConfirmedBarTime Datetime of the last closed bar time.
    void RenderPoi(const SPoIDefinition &poi, datetime lastConfirmedBarTime)
    {
        string name = GetObjectName(poi.id, poi.type);
        
        datetime time1 = poi.createdTime;
        double   price1 = poi.upperPrice;
        datetime time2 = lastConfirmedBarTime;
        double   price2 = poi.lowerPrice;

        if (time2 < time1)
            time2 = time1;

        color    zoneColor = clrGray;
        ENUM_LINE_STYLE borderStyle = STYLE_SOLID;

        // 1. Select Color
        switch (poi.type)
        {
            case POI_OB_BULLISH:         zoneColor = m_style.colorOBBull; break;
            case POI_OB_BEARISH:         zoneColor = m_style.colorOBBear; break;
            case POI_BREAKER_BULLISH:    zoneColor = m_style.colorBreakerBull; break;
            case POI_BREAKER_BEARISH:    zoneColor = m_style.colorBreakerBear; break;
            case POI_MITIGATION_BULLISH: zoneColor = m_style.colorMBBull; break;
            case POI_MITIGATION_BEARISH: zoneColor = m_style.colorMBBear; break;
            case POI_FVG_BULLISH:        zoneColor = m_style.colorFVGBull; break;
            case POI_FVG_BEARISH:        zoneColor = m_style.colorFVGBear; break;
            default:                     break;
        }

        // 2. Select Border Style
        if (poi.type == POI_FVG_BULLISH || poi.type == POI_FVG_BEARISH)
        {
            borderStyle = STYLE_DOT; // FVGs always draw with dotted borders
        }
        else if (poi.lifecycle == POI_STATE_PARTIAL_MITIGATED || poi.lifecycle == POI_STATE_MATERIAL_MITIGATED)
        {
            borderStyle = STYLE_DOT; // Mitigated blocks change to dotted borders
        }

        // 3. Visual weight: active POI gets border width 2; mitigated gets width 1 (reduced)
        bool isActive = (poi.lifecycle == POI_STATE_ACTIVE);
        int borderWidth = isActive ? 2 : 1;

        // Create or update the rectangle
        if (ObjectFind(0, name) < 0)
        {
            if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2))
            {
                Print(StringFormat("[ERROR] [CPOIRenderer] Failed to create object %s. Error code: %d", name, GetLastError()));
                return;
            }
        }
        else
        {
            ObjectMove(0, name, 0, time1, price1);
            ObjectMove(0, name, 1, time2, price2);
        }

        // Set visual properties
        ObjectSetInteger(0, name, OBJPROP_COLOR, zoneColor);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, borderWidth);
        ObjectSetInteger(0, name, OBJPROP_STYLE, borderStyle);
        ObjectSetInteger(0, name, OBJPROP_FILL, true);       // Enable MT5 background fill
        ObjectSetInteger(0, name, OBJPROP_BACK, true);       // Draw behind candles for transparency effect
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

        // 4. Active POI label (type + price range) — only on active POIs, not mitigated
        string labelName = GetLabelName(poi.id, poi.type);
        if (isActive)
        {
            string labelText = StringFormat("%s\n%s – %s",
                GetPoiTypeLabel(poi.type),
                DoubleToString(poi.lowerPrice, _Digits),
                DoubleToString(poi.upperPrice, _Digits));

            if (ObjectFind(0, labelName) < 0)
                ObjectCreate(0, labelName, OBJ_TEXT, 0, time1, poi.upperPrice);
            else
                ObjectMove(0, labelName, 0, time1, poi.upperPrice);

            ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
            ObjectSetString(0, labelName, OBJPROP_FONT, m_style.fontName);
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, m_style.fontSizeLabel);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, zoneColor);
            ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
            ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
            ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, labelName, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
        }
        else
        {
            // Clean up label if POI became mitigated
            if (ObjectFind(0, labelName) >= 0)
                ObjectDelete(0, labelName);
        }
    }

public:
    /// @brief Constructor.
    CPOIRenderer() : m_maxPOIs(20), m_isInitialized(false)
    {
        m_style.Reset();
    }

    /// @brief Destructor.
    ~CPOIRenderer()
    {
        Reset();
    }

    /// @brief Initializes the POI Renderer with custom style and limits.
    /// @param style Shared visual style configuration.
    /// @param maxPOIs Max number of POIs to keep rendered.
    /// @return True on success.
    bool Initialize(const SIndicatorStyle &style, int maxPOIs)
    {
        m_style = style;
        m_maxPOIs = (maxPOIs > 0) ? maxPOIs : 20;
        m_isInitialized = true;
        return true;
    }

    /// @brief Clears all POI rectangle objects from the chart.
    void Reset()
    {
        ObjectsDeleteAll(0, "MNS_POI_");
        ObjectsDeleteAll(0, "MNS_POILbl_"); // Remove all POI zone labels
    }

    /// @brief Processes POI list and draws/cleans chart objects.
    /// @param poiEngine Source CPOIEngine engine.
    /// @param time Chart datetime array (time-series sorted).
    /// @param ratesTotal Total chart bars.
    void Draw(const CPOIEngine &poiEngine, const datetime &time[], int ratesTotal)
    {
        if (!m_isInitialized)
            return;

        int totalPois = poiEngine.GetPoIsCount();
        if (totalPois <= 0)
        {
            Reset();
            return;
        }

        // 1. Gather all active and mitigated POIs
        int renderableCount = 0;
        SPoIDefinition renderablePois[128];

        for (int i = 0; i < totalPois; i++)
        {
            SPoIDefinition poi;
            if (poiEngine.GetPoI(i, poi))
            {
                if (IsPoiRenderable(poi))
                {
                    renderablePois[renderableCount] = poi;
                    renderableCount++;
                }
            }
        }

        // 2. Sort renderable POIs by createdTime ascending (oldest first),
        //    using poi.id as secondary tie-breaker.
        for (int i = 0; i < renderableCount - 1; i++)
        {
            for (int j = i + 1; j < renderableCount; j++)
            {
                if (renderablePois[i].createdTime > renderablePois[j].createdTime ||
                    (renderablePois[i].createdTime == renderablePois[j].createdTime && renderablePois[i].id > renderablePois[j].id))
                {
                    SPoIDefinition temp = renderablePois[i];
                    renderablePois[i] = renderablePois[j];
                    renderablePois[j] = temp;
                }
            }
        }

        // 3. Keep track of which POI IDs are drawn this turn
        bool renderedThisTurn[128];
        for (int i = 0; i < 128; i++)
            renderedThisTurn[i] = false;

        int startIdx = 0;
        if (renderableCount > m_maxPOIs)
        {
            startIdx = renderableCount - m_maxPOIs;
        }

        datetime lastConfirmedTime = (ratesTotal > 1) ? time[1] : time[0];

        for (int i = startIdx; i < renderableCount; i++)
        {
            SPoIDefinition poi = renderablePois[i];
            RenderPoi(poi, lastConfirmedTime);
            if (poi.id >= 0 && poi.id < 128)
            {
                renderedThisTurn[poi.id] = true;
            }
        }

        // 4. Delete all objects for POI IDs that were NOT rendered this turn
        for (int i = 0; i < 128; i++)
        {
            if (!renderedThisTurn[i])
            {
                // Delete all possible visual representations for this ID
                string nameOBB   = GetObjectName(i, POI_OB_BULLISH);
                string nameOBBe  = GetObjectName(i, POI_OB_BEARISH);
                string nameBrkB  = GetObjectName(i, POI_BREAKER_BULLISH);
                string nameBrkBe = GetObjectName(i, POI_BREAKER_BEARISH);
                string nameMBB   = GetObjectName(i, POI_MITIGATION_BULLISH);
                string nameMBBe  = GetObjectName(i, POI_MITIGATION_BEARISH);
                string nameFVGB  = GetObjectName(i, POI_FVG_BULLISH);
                string nameFVGBe = GetObjectName(i, POI_FVG_BEARISH);

                if (ObjectFind(0, nameOBB) >= 0)   ObjectDelete(0, nameOBB);
                if (ObjectFind(0, nameOBBe) >= 0)  ObjectDelete(0, nameOBBe);
                if (ObjectFind(0, nameBrkB) >= 0)  ObjectDelete(0, nameBrkB);
                if (ObjectFind(0, nameBrkBe) >= 0) ObjectDelete(0, nameBrkBe);
                if (ObjectFind(0, nameMBB) >= 0)   ObjectDelete(0, nameMBB);
                if (ObjectFind(0, nameMBBe) >= 0)  ObjectDelete(0, nameMBBe);
                if (ObjectFind(0, nameFVGB) >= 0)  ObjectDelete(0, nameFVGB);
                if (ObjectFind(0, nameFVGBe) >= 0) ObjectDelete(0, nameFVGBe);
            }
        }
    }
};

#endif // __MNS_POI_RENDERER_MQH__
