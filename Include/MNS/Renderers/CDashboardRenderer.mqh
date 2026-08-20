//+------------------------------------------------------------------+
//|                                           CDashboardRenderer.mqh |
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Visual controller for drawing the graphical dashboard card and |
//|   info rows on the chart, displaying the active states of all    |
//|   11 core engines in a desaturated, high-contrast visual style.   |
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh                                                   |
//|   MNSStyle.mqh                                                   |
//|   MNSUtils.mqh                                                   |
//|   Engines (CSwingDetector, CStructureEngine, etc.)               |
//+------------------------------------------------------------------+
#ifndef __MNS_DASHBOARD_RENDERER_MQH__
#define __MNS_DASHBOARD_RENDERER_MQH__

#include "../MNSTypes.mqh"
#include "../MNSStyle.mqh"
#include "../MNSUtils.mqh"
#include "../CSwingDetector.mqh"
#include "../CStructureEngine.mqh"
#include "../CBreakDetector.mqh"
#include "../COrderFlowEngine.mqh"
#include "../CDeliveryStructureEngine.mqh"
#include "../CLiquidityEngine.mqh"
#include "../CPOIEngine.mqh"
#include "../CObjectiveEngine.mqh"
#include "../CConfirmationEngine.mqh"
#include "../CEntryEngine.mqh"
#include "../CRiskEngine.mqh"

//+------------------------------------------------------------------+
//| CDashboardRenderer                                               |
//| @brief Renders the stacked panel rows showing engine statuses.   |
//+------------------------------------------------------------------+
class CDashboardRenderer
{
private:
    SIndicatorStyle m_style;           ///< Cached visual style configuration
    bool            m_showDashboard;   ///< Visibility switch
    int             m_xOffset;         ///< Distance from the right edge
    int             m_yOffset;         ///< Distance from the top edge
    int             m_width;           ///< Dashboard panel width
    bool            m_isInitialized;    ///< Initialization guard flag

    /// @brief Creates or updates a row of labels in the dashboard.
    /// @param index Row index (0..13).
    /// @param labelName Left-aligned label text.
    /// @param valueText Right-aligned value text.
    /// @param valueColor Color of the value text.
    void SetRowText(int index, string labelName, string valueText, color valueColor)
    {
        string lblName = StringFormat("MNS_Dash_Lbl_%d", index);
        string valName = StringFormat("MNS_Dash_Val_%d", index);

        int yPos = m_yOffset + m_style.paddingDashboard + index * m_style.rowHeightDashboard;

        // 1. Draw Left Label
        if (ObjectFind(0, lblName) < 0)
        {
            if (!ObjectCreate(0, lblName, OBJ_LABEL, 0, 0, 0))
            {
                Print(StringFormat("[ERROR] CDashboardRenderer: Failed to create label %s. Error: %d", lblName, GetLastError()));
                return;
            }
        }
        
        color lblColor = (index == 0) ? m_style.colorDashboardHeader : m_style.colorDashboardText;
        ObjectSetString(0, lblName, OBJPROP_TEXT, labelName);
        ObjectSetString(0, lblName, OBJPROP_FONT, m_style.fontNameDashboard);
        ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, m_style.fontSizeDashboard);
        ObjectSetInteger(0, lblName, OBJPROP_COLOR, lblColor);
        ObjectSetInteger(0, lblName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
        ObjectSetInteger(0, lblName, OBJPROP_XDISTANCE, m_xOffset + m_width - m_style.paddingDashboard);
        ObjectSetInteger(0, lblName, OBJPROP_YDISTANCE, yPos);
        ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER); // Both align right for left labels? No, let's align left!
        // Wait, for top-right corner, X coordinates are measured from the right edge.
        // So X distance is distance from the right edge.
        // A label placed at X = Offset + padding has its left edge at that offset.
        // If we set anchor to ANCHOR_LEFT_UPPER:
        // Left edge of the label sits at X distance from the right edge.
        // In MT5, CORNER_RIGHT_UPPER measures X positive to the LEFT from the right edge.
        // So a larger X distance means it is further to the left (further inside the chart).
        // Therefore:
        // Right side of the dashboard is at X = Offset.
        // Left side of the dashboard is at X = Offset + Width.
        // So to align text to the LEFT side of the dashboard, X distance from the right edge should be:
        //   X = Offset + Width - padding.
        // And the text anchor should be ANCHOR_LEFT_UPPER (or ANCHOR_RIGHT_UPPER if X is Offset + padding).
        // Let's verify the MT5 coordinate math:
        // Corner = CORNER_RIGHT_UPPER.
        // X distance = distance from right border of chart.
        // Offset = 20. Width = 250.
        // The background panel spans from X = 20 (right edge of card) to X = 270 (left edge of card).
        // So:
        // - Left-aligned text (labels) should sit near the left edge of the card, i.e., X = 270 - padding = 250.
        //   Anchor = ANCHOR_LEFT_UPPER.
        // - Right-aligned text (values) should sit near the right edge of the card, i.e., X = 20 + padding = 30.
        //   Anchor = ANCHOR_RIGHT_UPPER.
        // Let's double-check this:
        // Yes! Since X is measured from the right edge going leftward:
        // Left side of dashboard is at `m_xOffset + m_width`.
        // So left-aligned text should be at `m_xOffset + m_width - m_style.paddingDashboard`, anchored `ANCHOR_LEFT_UPPER`.
        // Right-aligned text should be at `m_xOffset + m_style.paddingDashboard`, anchored `ANCHOR_RIGHT_UPPER`.
        // This is perfectly correct!
        ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0, lblName, OBJPROP_XDISTANCE, m_xOffset + m_width - m_style.paddingDashboard);
        ObjectSetInteger(0, lblName, OBJPROP_YDISTANCE, yPos);
        ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, lblName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, lblName, OBJPROP_HIDDEN, true);

        // 2. Draw Right Value Label
        if (StringLen(valueText) > 0)
        {
            if (ObjectFind(0, valName) < 0)
            {
                if (!ObjectCreate(0, valName, OBJ_LABEL, 0, 0, 0))
                {
                    Print(StringFormat("[ERROR] CDashboardRenderer: Failed to create value %s. Error: %d", valName, GetLastError()));
                    return;
                }
            }
            ObjectSetString(0, valName, OBJPROP_TEXT, valueText);
            ObjectSetString(0, valName, OBJPROP_FONT, m_style.fontNameDashboard);
            ObjectSetInteger(0, valName, OBJPROP_FONTSIZE, m_style.fontSizeDashboard);
            ObjectSetInteger(0, valName, OBJPROP_COLOR, valueColor);
            ObjectSetInteger(0, valName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
            ObjectSetInteger(0, valName, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
            ObjectSetInteger(0, valName, OBJPROP_XDISTANCE, m_xOffset + m_style.paddingDashboard);
            ObjectSetInteger(0, valName, OBJPROP_YDISTANCE, yPos);
            ObjectSetInteger(0, valName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, valName, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, valName, OBJPROP_HIDDEN, true);
        }
        else
        {
            if (ObjectFind(0, valName) >= 0)
            {
                ObjectDelete(0, valName);
            }
        }
    }

    /// @brief Helper to convert DOL type enum to string.
    string GetDolTypeString(EDolType type) const
    {
        switch (type)
        {
            case DOL_EXTERNAL_SWING:  return "Ext Swing";
            case DOL_EQH_EQL:         return "EQH/EQL";
            case DOL_PREV_DAY_HL:     return "Prev Day H/L";
            case DOL_PREV_WEEK_HL:    return "Prev Week H/L";
            case DOL_SESSION_HL:      return "Session H/L";
            case DOL_UNMITIGATED_EXT: return "Unmitigated Swing";
            case DOL_FVG_MIDPOINT:    return "FVG Midpoint";
            case DOL_OB_MIDPOINT:     return "OB Midpoint";
            case DOL_EQUILIBRIUM:     return "Equilibrium";
            default:                  return "None";
        }
    }

    /// @brief Helper to convert POI type enum to string.
    string GetPoiTypeString(EPoIType type) const
    {
        switch (type)
        {
            case POI_OB_BULLISH:         return "Bullish OB";
            case POI_OB_BEARISH:         return "Bearish OB";
            case POI_BREAKER_BULLISH:    return "Bullish Breaker";
            case POI_BREAKER_BEARISH:    return "Bearish Breaker";
            case POI_MITIGATION_BULLISH: return "Bullish Mitigation";
            case POI_MITIGATION_BEARISH: return "Bearish Mitigation";
            case POI_FVG_BULLISH:        return "Bullish FVG";
            case POI_FVG_BEARISH:        return "Bearish FVG";
            default:                     return "Unknown";
        }
    }

public:
    /// @brief Constructor.
    CDashboardRenderer()
        : m_showDashboard(true),
          m_xOffset(20),
          m_yOffset(20),
          m_width(250),
          m_isInitialized(false)
    {
        m_style.Reset();
    }

    /// @brief Destructor.
    ~CDashboardRenderer()
    {
        Reset();
    }

    /// @brief Initializes the renderer with the style structure and layout inputs.
    bool Initialize(const SIndicatorStyle &style, bool showDashboard, int x, int y, int width)
    {
        m_style = style;
        m_showDashboard = showDashboard;
        m_xOffset = x;
        m_yOffset = y;
        m_width = (width > 100) ? width : 250;
        m_isInitialized = true;
        return true;
    }

    /// @brief Deletes all dashboard objects from the chart.
    void Reset()
    {
        if (ObjectFind(0, "MNS_Dash_Bg") >= 0)
        {
            ObjectDelete(0, "MNS_Dash_Bg");
        }

        for (int i = 0; i < 14; i++)
        {
            string lblName = StringFormat("MNS_Dash_Lbl_%d", i);
            string valName = StringFormat("MNS_Dash_Val_%d", i);
            if (ObjectFind(0, lblName) >= 0) ObjectDelete(0, lblName);
            if (ObjectFind(0, valName) >= 0) ObjectDelete(0, valName);
        }
    }

    /// @brief Draws or updates the dashboard graphical labels on the chart.
    void Draw(const CPOIEngine &poiEngine,
              const CDeliveryStructureEngine &deliveryEngine,
              const CObjectiveEngine &objectiveEngine,
              const CSwingDetector &swingDetector,
              const CStructureEngine &structureEngine,
              const CBreakDetector &breakDetector,
              const COrderFlowEngine &orderFlowEngine,
              const CLiquidityEngine &liquidityEngine,
              const CConfirmationEngine &confirmationEngine,
              const CEntryEngine &entryEngine,
              const CRiskEngine &riskEngine,
              const datetime &time[],
              const double &close[],
              int ratesTotal,
              datetime gmtTime)
    {
        if (!m_isInitialized)
            return;

        if (!m_showDashboard)
        {
            Reset();
            return;
        }

        // ==========================================
        // 1. RENDER BACKGROUND PANEL
        // ==========================================
        int totalRows = 14;
        int height = m_style.paddingDashboard * 2 + totalRows * m_style.rowHeightDashboard;

        if (ObjectFind(0, "MNS_Dash_Bg") < 0)
        {
            if (!ObjectCreate(0, "MNS_Dash_Bg", OBJ_RECTANGLE_LABEL, 0, 0, 0))
            {
                Print(StringFormat("[ERROR] CDashboardRenderer: Failed to create background object. Error: %d", GetLastError()));
                return;
            }
        }

        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_XDISTANCE, m_xOffset);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_YDISTANCE, m_yOffset);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_XSIZE, m_width);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_YSIZE, height);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_BGCOLOR, m_style.colorDashboardBg);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_COLOR, m_style.colorDashboardBorder);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_BACK, false); // sit on top
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_SELECTED, false);
        ObjectSetInteger(0, "MNS_Dash_Bg", OBJPROP_HIDDEN, true);

        // Current price context for calculations
        double currentPrice = (ratesTotal > 1) ? close[1] : close[0];

        // ==========================================
        // 2. GENERATE AND UPDATE ROWS
        // ==========================================

        // Row 0: Header Title
        SetRowText(0, "MNS ENGINE v1.0", "", m_style.colorDashboardHeader);

        // Row 1: Symbol/Timeframe Context
        string tfStr = "";
        switch (_Period)
        {
            case PERIOD_M1:  tfStr = "M1"; break;
            case PERIOD_M5:  tfStr = "M5"; break;
            case PERIOD_M15: tfStr = "M15"; break;
            case PERIOD_M30: tfStr = "M30"; break;
            case PERIOD_H1:  tfStr = "H1"; break;
            case PERIOD_H4:  tfStr = "H4"; break;
            case PERIOD_D1:  tfStr = "D1"; break;
            case PERIOD_W1:  tfStr = "W1"; break;
            case PERIOD_MN1: tfStr = "MN"; break;
            default:         tfStr = StringFormat("M%d", _Period); break;
        }
        string contextVal = StringFormat("%s, %s", _Symbol, tfStr);
        SetRowText(1, "Symbol/TF:", contextVal, m_style.colorDashboardValue);

        // Row 2: Trend
        ETrend trend = structureEngine.GetState().trend;
        string trendVal = "Unknown";
        color  trendCol = clrLightGray;
        switch (trend)
        {
            case TREND_BULLISH:    trendVal = "Bullish"; trendCol = clrLime; break;
            case TREND_BEARISH:    trendVal = "Bearish"; trendCol = clrRed; break;
            case TREND_RANGING:    trendVal = "Ranging"; trendCol = clrOrange; break;
            case TREND_TRANSITION: trendVal = "Transition"; trendCol = clrGold; break;
            default:               break;
        }
        SetRowText(2, "Trend:", trendVal, trendCol);

        // Row 3: Phase
        EMarketPhase phase = structureEngine.GetState().phase;
        string phaseVal = "Unknown";
        color  phaseCol = clrLightGray;
        switch (phase)
        {
            case PHASE_TRENDING:   phaseVal = "Trending"; phaseCol = clrWhite; break;
            case PHASE_PULLBACK:   phaseVal = "Pullback"; phaseCol = clrOrange; break;
            case PHASE_TRANSITION: phaseVal = "Transition"; phaseCol = clrGold; break;
            case PHASE_RANGING:    phaseVal = "Ranging"; phaseCol = clrLightGray; break;
            default:               break;
        }
        SetRowText(3, "Phase:", phaseVal, phaseCol);

        // Row 4: Structure Type
        EStructureType structType = structureEngine.GetState().structureType;
        string structVal = "None";
        color  structCol = clrLightGray;
        switch (structType)
        {
            case STRUCTURE_HH:         structVal = "HH"; structCol = clrLime; break;
            case STRUCTURE_HL:         structVal = "HL"; structCol = clrLime; break;
            case STRUCTURE_LH:         structVal = "LH"; structCol = clrRed; break;
            case STRUCTURE_LL:         structVal = "LL"; structCol = clrRed; break;
            case STRUCTURE_EQUAL_HIGH: structVal = "Equal High"; structCol = clrGold; break;
            case STRUCTURE_EQUAL_LOW:  structVal = "Equal Low"; structCol = clrGold; break;
            default:                   break;
        }
        SetRowText(4, "Structure:", structVal, structCol);

        // Row 5: Last BOS
        SStructureBreak latestBOS = breakDetector.GetLatestBOS();
        string bosVal = "None";
        color  bosCol = clrLightGray;
        if (latestBOS.isConfirmed)
        {
            bool isBull = (latestBOS.brokenSwing.type == SWING_HIGH);
            bosVal = StringFormat("%s @ %s", (isBull ? "Bullish" : "Bearish"), DoubleToString(latestBOS.price, _Digits));
            bosCol = isBull ? clrLime : clrRed;
        }
        SetRowText(5, "Last BOS:", bosVal, bosCol);

        // Row 6: Last CHoCH
        SStructureBreak latestCHoCH = breakDetector.GetLatestCHOCH();
        string chochVal = "None";
        color  chochCol = clrLightGray;
        if (latestCHoCH.isConfirmed)
        {
            bool isBull = (latestCHoCH.brokenSwing.type == SWING_HIGH);
            chochVal = StringFormat("%s @ %s", (isBull ? "Bullish" : "Bearish"), DoubleToString(latestCHoCH.price, _Digits));
            chochCol = isBull ? clrLime : clrRed;
        }
        SetRowText(6, "Last CHoCH:", chochVal, chochCol);

        // Row 7: Liquidity Bias
        SDolDefinition dol = objectiveEngine.GetActiveDol();
        bool isDolActive = (dol.active && dol.score >= 60.0 && dol.price != DBL_MAX);
        string biasVal = "Balanced";
        color  biasCol = clrOrange;
        if (isDolActive)
        {
            if (dol.price > currentPrice)
            {
                biasVal = "Buy Side";
                biasCol = clrLime;
            }
            else
            {
                biasVal = "Sell Side";
                biasCol = clrRed;
            }
        }
        SetRowText(7, "Liq Bias:", biasVal, biasCol);

        // Row 8: Active DOL
        string dolVal = "None";
        color  dolCol = clrLightGray;
        if (isDolActive)
        {
            dolVal = StringFormat("%s (%s)", DoubleToString(dol.price, _Digits), GetDolTypeString(dol.type));
            dolCol = m_style.colorDOL;
        }
        SetRowText(8, "Active DOL:", dolVal, dolCol);

        // Row 9: Active POI (Closest active POI)
        SPoIDefinition bullishPoi, bearishPoi;
        bool hasBullPoi = poiEngine.GetNearestBullishPOI(currentPrice, bullishPoi);
        bool hasBearPoi = poiEngine.GetNearestBearishPOI(currentPrice, bearishPoi);
        
        SPoIDefinition closestPoi;
        closestPoi.Reset();
        bool hasPoi = false;
        
        if (hasBullPoi && hasBearPoi)
        {
            double distBull = currentPrice - bullishPoi.upperPrice;
            double distBear = bearishPoi.lowerPrice - currentPrice;
            if (distBull <= distBear)
                closestPoi = bullishPoi;
            else
                closestPoi = bearishPoi;
            hasPoi = true;
        }
        else if (hasBullPoi)
        {
            closestPoi = bullishPoi;
            hasPoi = true;
        }
        else if (hasBearPoi)
        {
            closestPoi = bearishPoi;
            hasPoi = true;
        }

        string poiVal = "None";
        color  poiCol = clrLightGray;
        if (hasPoi)
        {
            bool isBull = (closestPoi.type == POI_OB_BULLISH || closestPoi.type == POI_BREAKER_BULLISH || 
                           closestPoi.type == POI_MITIGATION_BULLISH || closestPoi.type == POI_FVG_BULLISH);
                           
            poiVal = StringFormat("%s (%s-%s)", GetPoiTypeString(closestPoi.type), 
                                  DoubleToString(closestPoi.lowerPrice, _Digits),
                                  DoubleToString(closestPoi.upperPrice, _Digits));
            poiCol = isBull ? clrLime : clrRed;
        }
        SetRowText(9, "Active POI:", poiVal, poiCol);

        // Row 10: Dealing Range Zone (DR Zone)
        string zoneVal = "None";
        color  zoneCol = clrLightGray;
        double eq = poiEngine.GetEquilibrium(swingDetector);
        if (eq != 0.0 && eq != DBL_MAX)
        {
            EDealingRangeZone zone = poiEngine.GetDealingRangeZone(currentPrice, swingDetector);
            switch (zone)
            {
                case ZONE_PREMIUM:     zoneVal = "Premium"; zoneCol = clrRed; break;
                case ZONE_DISCOUNT:    zoneVal = "Discount"; zoneCol = clrLime; break;
                case ZONE_EQUILIBRIUM: zoneVal = "Equilibrium"; zoneCol = clrGold; break;
                default:               break;
            }
        }
        SetRowText(10, "DR Zone:", zoneVal, zoneCol);

        // Row 11: Active Sessions
        bool isTokyo  = CMNSUtils::IsInSession(gmtTime, 0, 8);
        bool isLondon = CMNSUtils::IsInSession(gmtTime, 8, 16);
        bool isNY     = CMNSUtils::IsInSession(gmtTime, 13, 21);

        string sessionVal = "";
        if (isTokyo)  sessionVal += (StringLen(sessionVal) > 0 ? " / " : "") + "Tokyo";
        if (isLondon) sessionVal += (StringLen(sessionVal) > 0 ? " / " : "") + "London";
        if (isNY)     sessionVal += (StringLen(sessionVal) > 0 ? " / " : "") + "NY";

        if (StringLen(sessionVal) == 0)
        {
            sessionVal = "Closed";
            SetRowText(11, "Session:", sessionVal, clrLightGray);
        }
        else
        {
            SetRowText(11, "Session:", sessionVal, m_style.colorDashboardValue);
        }

        // Row 12: Confirmation State
        EConfirmationState confState = confirmationEngine.GetConfirmationState();
        string confVal = "None";
        color  confCol = clrLightGray;
        switch (confState)
        {
            case CONFIRMATION_STATE_PENDING:
                confVal = "Pending";
                confCol = clrOrange;
                break;
            case CONFIRMATION_STATE_CONFIRMED:
                {
                    bool isBull = (confirmationEngine.GetDirection() == CONFIRM_DIR_BULLISH);
                    confVal = StringFormat("Confirmed (%s)", (isBull ? "Bullish" : "Bearish"));
                    confCol = isBull ? clrLime : clrRed;
                }
                break;
            case CONFIRMATION_STATE_INVALIDATED:
                confVal = "Invalidated";
                confCol = clrRed;
                break;
            default:
                break;
        }
        SetRowText(12, "Confirmation:", confVal, confCol);

        // Row 13: Entry Signal
        EEntryState entState = entryEngine.GetActiveSignalState();
        string entVal = "None";
        color  entCol = clrLightGray;
        switch (entState)
        {
            case ENTRY_STATE_ACTIVE:
                {
                    bool isBull = (entryEngine.GetActiveSignal().direction == CONFIRM_DIR_BULLISH);
                    entVal = isBull ? "Buy Triggered" : "Sell Triggered";
                    entCol = isBull ? clrLime : clrRed;
                }
                break;
            case ENTRY_STATE_EXECUTED:
                entVal = "Executed";
                entCol = clrWhite;
                break;
            case ENTRY_STATE_EXPIRED:
                entVal = "Expired";
                entCol = clrLightGray;
                break;
            case ENTRY_STATE_INVALIDATED:
                entVal = "Invalidated";
                entCol = clrRed;
                break;
            case ENTRY_STATE_CANCELLED:
                entVal = "Cancelled";
                entCol = clrOrange;
                break;
            default:
                break;
        }
        SetRowText(13, "Entry:", entVal, entCol);
    }
};

#endif // __MNS_DASHBOARD_RENDERER_MQH__
