//+------------------------------------------------------------------+
//|                                           CDashboardRenderer.mqh |
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Visual controller for drawing the graphical dashboard card and |
//|   info rows on the chart, displaying the active states of all    |
//|   11 core engines in a desaturated, high-contrast visual style.   |
//|   Supports interactive dragging, collapse/expand, lock/unlock,   |
//|   show/hide, position reset, and multi-chart instance safety.    |
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
    bool            m_showDashboard;   ///< Input setting switch
    int             m_xOffset;         ///< Distance from the left edge (pixels)
    int             m_yOffset;         ///< Distance from the top edge (pixels)
    int             m_width;           ///< Dashboard panel width (pixels)
    bool            m_isInitialized;   ///< Initialization guard flag

    // Interactive states
    bool            m_isLocked;        ///< Drag lock state
    bool            m_isCollapsed;     ///< Collapsed HUD state
    bool            m_isVisible;       ///< Visibility switch
    bool            m_isDragging;      ///< True if currently dragging
    int             m_dragDx;          ///< Drag X offset from mouse down
    int             m_dragDy;          ///< Drag Y offset from mouse down
    bool            m_essentialsOnly;  ///< True to hide intermediate narrative rows

    /// @brief Resolves a collision-safe object name by appending ChartID.
    string GetObjName(string baseName) const
    {
        return StringFormat("%s_%I64d", baseName, ChartID());
    }

    /// @brief Creates a rectangle label object on the chart.
    void CreateRect(string name, color bgColor, color borderColor, int width, int height)
    {
        string objName = GetObjName(name);
        if (ObjectFind(0, objName) < 0)
        {
            if (!ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
            {
                Print(StringFormat("[ERROR] CDashboardRenderer: Failed to create rect %s. Error: %d", objName, GetLastError()));
                return;
            }
        }
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, m_xOffset);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, m_yOffset);
        ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, borderColor);
        ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, objName, OBJPROP_BACK, false); // sit on top
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
    }

    /// @brief Creates a text label object on the chart.
    void CreateLabel(string name, string text, color txtColor, string font, int fontSize, ENUM_ANCHOR_POINT anchor)
    {
        string objName = GetObjName(name);
        bool isNew = false;
        if (ObjectFind(0, objName) < 0)
        {
            if (!ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0))
            {
                Print(StringFormat("[ERROR] CDashboardRenderer: Failed to create label %s. Error: %d", objName, GetLastError()));
                return;
            }
            isNew = true;
        }
        if (isNew)
        {
            ObjectSetString(0, objName, OBJPROP_TEXT, text);
        }
        ObjectSetString(0, objName, OBJPROP_FONT, font);
        ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, txtColor);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, anchor);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
    }

    /// @brief Creates an interactive button object on the chart.
    void CreateButton(string name, string text, int width, int height, string font, int fontSize, color bgColor, color txtColor)
    {
        string objName = GetObjName(name);
        if (ObjectFind(0, objName) < 0)
        {
            if (!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, 0))
            {
                Print(StringFormat("[ERROR] CDashboardRenderer: Failed to create button %s. Error: %d", objName, GetLastError()));
                return;
            }
        }
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        ObjectSetString(0, objName, OBJPROP_FONT, font);
        ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
        ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, txtColor);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_STATE, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
    }

    /// @brief Sets object visibility without destroying it.
    void SetObjectVisibility(string name, bool visible)
    {
        string objName = GetObjName(name);
        if (ObjectFind(0, objName) >= 0)
        {
            ObjectSetInteger(0, objName, OBJPROP_TIMEFRAMES, visible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
        }
    }

    /// @brief Helper to delete a chart object safely.
    void DeleteObject(string name)
    {
        string objName = GetObjName(name);
        if (ObjectFind(0, objName) >= 0)
        {
            ObjectDelete(0, objName);
        }
    }

    /// @brief Updates value label text and color.
    void UpdateRowText(string nameSuffix, string valueText, color valueColor)
    {
        string valName = GetObjName("MNS_DASH_VAL_" + nameSuffix);
        if (ObjectFind(0, valName) >= 0)
        {
            ObjectSetString(0, valName, OBJPROP_TEXT, valueText);
            ObjectSetInteger(0, valName, OBJPROP_COLOR, valueColor);
        }
    }

    /// @brief Hides all detail info rows (used when collapsed or hidden).
    void HideDetailRows()
    {
        // Section headers
        SetObjectVisibility("MNS_DASH_SEC_MARKET", false);
        SetObjectVisibility("MNS_DASH_SEC_SETUP", false);
        SetObjectVisibility("MNS_DASH_SEC_SIGNAL", false);
        SetObjectVisibility("MNS_DASH_SEC_FILTERS", false);
        // Rows
        SetObjectVisibility("MNS_DASH_LBL_SYMBOL", false);
        SetObjectVisibility("MNS_DASH_VAL_SYMBOL", false);
        SetObjectVisibility("MNS_DASH_LBL_TREND", false);
        SetObjectVisibility("MNS_DASH_VAL_TREND", false);
        SetObjectVisibility("MNS_DASH_LBL_PHASE", false);
        SetObjectVisibility("MNS_DASH_VAL_PHASE", false);
        SetObjectVisibility("MNS_DASH_LBL_STRUCTURE", false);
        SetObjectVisibility("MNS_DASH_VAL_STRUCTURE", false);
        SetObjectVisibility("MNS_DASH_LBL_BOS", false);
        SetObjectVisibility("MNS_DASH_VAL_BOS", false);
        SetObjectVisibility("MNS_DASH_LBL_CHOCH", false);
        SetObjectVisibility("MNS_DASH_VAL_CHOCH", false);
        SetObjectVisibility("MNS_DASH_LBL_BIAS", false);
        SetObjectVisibility("MNS_DASH_VAL_BIAS", false);
        SetObjectVisibility("MNS_DASH_LBL_DOL", false);
        SetObjectVisibility("MNS_DASH_VAL_DOL", false);
        SetObjectVisibility("MNS_DASH_LBL_POI", false);
        SetObjectVisibility("MNS_DASH_VAL_POI", false);
        SetObjectVisibility("MNS_DASH_LBL_ZONE", false);
        SetObjectVisibility("MNS_DASH_VAL_ZONE", false);
        SetObjectVisibility("MNS_DASH_LBL_SESSION", false);
        SetObjectVisibility("MNS_DASH_VAL_SESSION", false);
        SetObjectVisibility("MNS_DASH_LBL_CONFIRMATION", false);
        SetObjectVisibility("MNS_DASH_VAL_CONFIRMATION", false);
        SetObjectVisibility("MNS_DASH_LBL_ENTRY", false);
        SetObjectVisibility("MNS_DASH_VAL_ENTRY", false);
        SetObjectVisibility("MNS_DASH_LBL_ENTRY_PRICE", false);
        SetObjectVisibility("MNS_DASH_VAL_ENTRY_PRICE", false);
        SetObjectVisibility("MNS_DASH_LBL_SL", false);
        SetObjectVisibility("MNS_DASH_VAL_SL", false);
    }

    /// @brief Shows all detail info rows (used when expanded).
    void ShowDetailRows()
    {
        // Section headers always visible when expanded
        SetObjectVisibility("MNS_DASH_SEC_MARKET", true);
        SetObjectVisibility("MNS_DASH_SEC_SETUP", true);
        SetObjectVisibility("MNS_DASH_SEC_SIGNAL", true);
        SetObjectVisibility("MNS_DASH_SEC_FILTERS", !m_essentialsOnly); // Filters only in full mode
        // Rows
        SetObjectVisibility("MNS_DASH_LBL_SYMBOL", true);
        SetObjectVisibility("MNS_DASH_VAL_SYMBOL", true);
        SetObjectVisibility("MNS_DASH_LBL_TREND", true);
        SetObjectVisibility("MNS_DASH_VAL_TREND", true);
        SetObjectVisibility("MNS_DASH_LBL_PHASE", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_VAL_PHASE", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_LBL_STRUCTURE", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_VAL_STRUCTURE", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_LBL_BOS", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_VAL_BOS", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_LBL_CHOCH", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_VAL_CHOCH", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_LBL_BIAS", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_VAL_BIAS", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_LBL_DOL", true);
        SetObjectVisibility("MNS_DASH_VAL_DOL", true);
        SetObjectVisibility("MNS_DASH_LBL_POI", true);
        SetObjectVisibility("MNS_DASH_VAL_POI", true);
        SetObjectVisibility("MNS_DASH_LBL_ZONE", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_VAL_ZONE", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_LBL_SESSION", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_VAL_SESSION", !m_essentialsOnly);
        SetObjectVisibility("MNS_DASH_LBL_CONFIRMATION", true);
        SetObjectVisibility("MNS_DASH_VAL_CONFIRMATION", true);
        SetObjectVisibility("MNS_DASH_LBL_ENTRY", true);
        SetObjectVisibility("MNS_DASH_VAL_ENTRY", true);
        SetObjectVisibility("MNS_DASH_LBL_ENTRY_PRICE", true);
        SetObjectVisibility("MNS_DASH_VAL_ENTRY_PRICE", true);
        SetObjectVisibility("MNS_DASH_LBL_SL", true);
        SetObjectVisibility("MNS_DASH_VAL_SL", true);
    }

    /// @brief Positions a row of labels horizontally inside the panel.
    void SetRowPosition(string nameSuffix, int yPos)
    {
        string lblName = GetObjName("MNS_DASH_LBL_" + nameSuffix);
        string valName = GetObjName("MNS_DASH_VAL_" + nameSuffix);

        ObjectSetInteger(0, lblName, OBJPROP_XDISTANCE, m_xOffset + m_style.paddingDashboard);
        ObjectSetInteger(0, lblName, OBJPROP_YDISTANCE, yPos);

        ObjectSetInteger(0, valName, OBJPROP_XDISTANCE, m_xOffset + m_width - m_style.paddingDashboard);
        ObjectSetInteger(0, valName, OBJPROP_YDISTANCE, yPos);
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
          m_isInitialized(false),
          m_isLocked(false),
          m_isCollapsed(false),
          m_isVisible(true),
          m_isDragging(false),
          m_dragDx(0),
          m_dragDy(0),
          m_essentialsOnly(false)
    {
        m_style.Reset();
    }

    /// @brief Destructor.
    ~CDashboardRenderer()
    {
        Reset();
    }

    /// @brief Initializes the renderer with the style structure and layout inputs.
    bool Initialize(const SIndicatorStyle &style, bool showDashboard, int x, int y, int width, bool essentialsOnly = false)
    {
        SEngineConfig cfg = CMNSConfig::GetActive();
        m_style = style;
        m_showDashboard = cfg.showDashboard;
        m_width = (cfg.dashboardWidth > 100) ? cfg.dashboardWidth : 250;
        m_essentialsOnly = essentialsOnly;
        m_isInitialized = true;
        
        m_isLocked = false;
        m_isCollapsed = false;
        m_isVisible = cfg.showDashboard;
        m_isDragging = false;
        m_dragDx = 0;
        m_dragDy = 0;

        // GlobalVariable prefix for this chart's persisted state
        string prefix = StringFormat("MNS_DASH_%I64d_%s_%d_", ChartID(), _Symbol, _Period);

        // Set initial offsets — safe fallback values until first valid chart size is available
        // Default: top-left corner with padding (will be clamped to top-right on first Draw if chartWidth > 0)
        m_xOffset = 20;
        m_yOffset = cfg.dashboardY;

        // Restore persisted position only if chart dimensions are available and position is on-screen
        int initChartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        if (initChartWidth > 0)
        {
            // Try to restore saved X
            if (GlobalVariableCheck(prefix + "X"))
            {
                int savedX = (int)GlobalVariableGet(prefix + "X");
                if (savedX >= 0 && savedX <= initChartWidth - m_width)
                    m_xOffset = savedX;
                else
                    m_xOffset = MathMax(0, initChartWidth - m_width - cfg.dashboardX); // right-anchored default
            }
            else
            {
                m_xOffset = MathMax(0, initChartWidth - m_width - cfg.dashboardX); // right-anchored default
            }
        }
        else
        {
            // chartWidth not ready — skip GlobalVariable restore entirely;
            // UpdateObjectPositions() will clamp + write-back on first valid frame.
        }

        // Restore Y (independent of chartWidth)
        if (GlobalVariableCheck(prefix + "Y"))
        {
            int savedY = (int)GlobalVariableGet(prefix + "Y");
            if (savedY >= 0)
                m_yOffset = savedY;
        }
        if (GlobalVariableCheck(prefix + "COLLAPSED"))
            m_isCollapsed = (GlobalVariableGet(prefix + "COLLAPSED") > 0.5);
        if (GlobalVariableCheck(prefix + "LOCKED"))
            m_isLocked = (GlobalVariableGet(prefix + "LOCKED") > 0.5);
        if (GlobalVariableCheck(prefix + "VISIBLE"))
            m_isVisible = (GlobalVariableGet(prefix + "VISIBLE") > 0.5);

        // Apply input setting override
        m_isVisible = m_showDashboard && m_isVisible;

        // Clean up any orphaned components
        Reset();

        // Enable chart mouse move events
        ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

        // Build visual layout
        RedrawLayout();

        return true;
    }

    /// @brief Clears all dashboard objects from the chart.
    void Reset()
    {
        ChartSetInteger(0, CHART_MOUSE_SCROLL, true);

        DeleteObject("MNS_DASH_PANEL");
        DeleteObject("MNS_DASH_HEADER");
        DeleteObject("MNS_DASH_TITLE");
        DeleteObject("MNS_DASH_BTN_LOCK");
        DeleteObject("MNS_DASH_BTN_COLLAPSE");
        DeleteObject("MNS_DASH_BTN_HIDE");
        DeleteObject("MNS_DASH_BTN_RESET");
        DeleteObject("MNS_DASH_BTN_RESTORE");

        DeleteObject("MNS_DASH_LBL_SYMBOL");
        DeleteObject("MNS_DASH_VAL_SYMBOL");
        DeleteObject("MNS_DASH_LBL_TREND");
        DeleteObject("MNS_DASH_VAL_TREND");
        DeleteObject("MNS_DASH_LBL_PHASE");
        DeleteObject("MNS_DASH_VAL_PHASE");
        DeleteObject("MNS_DASH_LBL_STRUCTURE");
        DeleteObject("MNS_DASH_VAL_STRUCTURE");
        DeleteObject("MNS_DASH_LBL_BOS");
        DeleteObject("MNS_DASH_VAL_BOS");
        DeleteObject("MNS_DASH_LBL_CHOCH");
        DeleteObject("MNS_DASH_VAL_CHOCH");
        DeleteObject("MNS_DASH_LBL_BIAS");
        DeleteObject("MNS_DASH_VAL_BIAS");
        DeleteObject("MNS_DASH_LBL_DOL");
        DeleteObject("MNS_DASH_VAL_DOL");
        DeleteObject("MNS_DASH_LBL_POI");
        DeleteObject("MNS_DASH_VAL_POI");
        DeleteObject("MNS_DASH_LBL_ZONE");
        DeleteObject("MNS_DASH_VAL_ZONE");
        DeleteObject("MNS_DASH_LBL_SESSION");
        DeleteObject("MNS_DASH_VAL_SESSION");
        DeleteObject("MNS_DASH_LBL_CONFIRMATION");
        DeleteObject("MNS_DASH_VAL_CONFIRMATION");
        DeleteObject("MNS_DASH_LBL_ENTRY");
        DeleteObject("MNS_DASH_VAL_ENTRY");
        DeleteObject("MNS_DASH_LBL_ENTRY_PRICE");
        DeleteObject("MNS_DASH_VAL_ENTRY_PRICE");
        DeleteObject("MNS_DASH_LBL_SL");
        DeleteObject("MNS_DASH_VAL_SL");
        // Section header labels
        DeleteObject("MNS_DASH_SEC_MARKET");
        DeleteObject("MNS_DASH_SEC_SETUP");
        DeleteObject("MNS_DASH_SEC_SIGNAL");
        DeleteObject("MNS_DASH_SEC_FILTERS");
    }

    /// @brief Cleans up terminal global variables associated with this chart.
    void DeleteGlobalVariables()
    {
        string prefix = StringFormat("MNS_DASH_%I64d_%s_%d_", ChartID(), _Symbol, _Period);
        GlobalVariableDel(prefix + "X");
        GlobalVariableDel(prefix + "Y");
        GlobalVariableDel(prefix + "COLLAPSED");
        GlobalVariableDel(prefix + "LOCKED");
        GlobalVariableDel(prefix + "VISIBLE");
    }

    /// @brief Returns the height of the dashboard panel.
    int GetCurrentHeight() const
    {
        if (m_isCollapsed)
            return 22 + m_style.paddingDashboard;
        // 4 section headers × 14px + rows × rowHeight + top/bottom padding + reset button
        int numRows    = m_essentialsOnly ? 8 : 15;
        int numHeaders = 4;  // MARKET STATE, ACTIVE SETUP, SIGNAL, FILTERS
        int headerH    = 14; // px per section header
        return 22 + m_style.paddingDashboard
               + numHeaders * headerH
               + numRows * m_style.rowHeightDashboard
               + m_style.paddingDashboard + 18 + m_style.paddingDashboard;
    }

    /// @brief Ensures all layout objects are created and formatted.
    void EnsureObjectsExist()
    {
        // 1. Restore Button
        CreateButton("MNS_DASH_BTN_RESTORE", "MNS", 40, 18, m_style.fontNameDashboard, m_style.fontSizeDashboard, C'40, 40, 40', m_style.colorDashboardText);

        // 2. Main Background Panel
        CreateRect("MNS_DASH_PANEL", m_style.colorDashboardBg, m_style.colorDashboardBorder, m_width, this.GetCurrentHeight());

        // 3. Header Background Panel
        CreateRect("MNS_DASH_HEADER", C'36, 36, 36', m_style.colorDashboardBorder, m_width, 22);

        // 4. Header Title
        CreateLabel("MNS_DASH_TITLE", "⁞⁞ MNS ENGINE v1.0", m_style.colorDashboardHeader, m_style.fontNameDashboard, m_style.fontSizeDashboard + 1, ANCHOR_LEFT_UPPER);

        // 5. Header Control Buttons (Explicit text buttons instead of emojis)
        CreateButton("MNS_DASH_BTN_LOCK", m_isLocked ? "UNLOCK" : "LOCK", 50, 18, m_style.fontNameDashboard, m_style.fontSizeDashboard, C'40, 40, 40', m_style.colorDashboardText);
        CreateButton("MNS_DASH_BTN_COLLAPSE", m_isCollapsed ? "FULL" : "HUD", 45, 18, m_style.fontNameDashboard, m_style.fontSizeDashboard, C'40, 40, 40', m_style.colorDashboardText);
        CreateButton("MNS_DASH_BTN_HIDE", "HIDE", 35, 18, m_style.fontNameDashboard, m_style.fontSizeDashboard, C'40, 40, 40', m_style.colorDashboardText);

        // 6a. Section Header Labels (grouped layout separators)
        color secHeaderColor = C'100, 100, 60'; // Muted amber/gold — subtle but readable
        CreateLabel("MNS_DASH_SEC_MARKET",  "-- MARKET STATE --",  secHeaderColor, m_style.fontNameDashboard, m_style.fontSizeDashboard - 1, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_SEC_SETUP",   "-- ACTIVE SETUP --",  secHeaderColor, m_style.fontNameDashboard, m_style.fontSizeDashboard - 1, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_SEC_SIGNAL",  "-- SIGNAL --",        secHeaderColor, m_style.fontNameDashboard, m_style.fontSizeDashboard - 1, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_SEC_FILTERS", "-- FILTERS --",       secHeaderColor, m_style.fontNameDashboard, m_style.fontSizeDashboard - 1, ANCHOR_LEFT_UPPER);

        // 6b. Detail rows (labels)
        CreateLabel("MNS_DASH_LBL_SYMBOL", "Symbol/TF:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_TREND", "Trend:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_PHASE", "Phase:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_STRUCTURE", "Structure:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_BOS", "Last BOS:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_CHOCH", "Last CHoCH:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_BIAS", "Liq Bias:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_DOL", "TP (DOL):", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_POI", "Active POI:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_ZONE", "DR Zone:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_SESSION", "Session:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_CONFIRMATION", "Confirmation:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_ENTRY", "Entry Signal:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_ENTRY_PRICE", "Entry Price:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);
        CreateLabel("MNS_DASH_LBL_SL", "Stop Loss:", m_style.colorDashboardText, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_LEFT_UPPER);

        // 7. Detail values (default initial texts to avoid empty labels showing default MT5 "Label" text)
        CreateLabel("MNS_DASH_VAL_SYMBOL", "N/A", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_TREND", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_PHASE", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_STRUCTURE", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_BOS", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_CHOCH", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_BIAS", "Balanced", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_DOL", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_POI", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_ZONE", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_SESSION", "Closed", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_CONFIRMATION", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_ENTRY", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_ENTRY_PRICE", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);
        CreateLabel("MNS_DASH_VAL_SL", "None", m_style.colorDashboardValue, m_style.fontNameDashboard, m_style.fontSizeDashboard, ANCHOR_RIGHT_UPPER);

        // 8. Bottom Reset Button
        CreateButton("MNS_DASH_BTN_RESET", "Reset Position", m_width - m_style.paddingDashboard * 2, 18, m_style.fontNameDashboard, m_style.fontSizeDashboard, C'40, 40, 40', m_style.colorDashboardText);
    }

    /// @brief Reposition all panel objects relative to current offsets.
    void UpdateObjectPositions()
    {
        if (!m_isInitialized) return;

        // Ensure offsets are within valid chart boundaries.
        // During indicator initialization inside OnInit(), ChartGetInteger(0, CHART_WIDTH_IN_PIXELS)
        // often returns 0, causing default offset calculations to go negative (off-screen).
        // This dynamic clamp corrects the offsets as soon as a valid chart size is available.
        int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
        int panelHeight = this.GetCurrentHeight();

        if (chartWidth > 0 && chartHeight > 0)
        {
            bool clamped = false;
            if (m_xOffset < 0 || m_xOffset > chartWidth - m_width)
            {
                m_xOffset = MathMax(0, chartWidth - m_width - 20);
                clamped = true;
            }
            if (m_yOffset < 0 || m_yOffset > chartHeight - panelHeight)
            {
                m_yOffset = MathMax(0, 20);
                clamped = true;
            }
            // Write back corrected position to GlobalVariable so corrupted off-screen value is replaced
            if (clamped)
            {
                string prefix = StringFormat("MNS_DASH_%I64d_%s_%d_", ChartID(), _Symbol, _Period);
                GlobalVariableSet(prefix + "X", (double)m_xOffset);
                GlobalVariableSet(prefix + "Y", (double)m_yOffset);
            }
        }

        // If hidden, restore button sits at top-right by default
        if (!m_isVisible)
        {
            string restoreBtnName = GetObjName("MNS_DASH_BTN_RESTORE");
            ObjectSetInteger(0, restoreBtnName, OBJPROP_XDISTANCE, chartWidth - 50);
            ObjectSetInteger(0, restoreBtnName, OBJPROP_YDISTANCE, 20);
            return;
        }

        // Panel & Header
        ObjectSetInteger(0, GetObjName("MNS_DASH_PANEL"), OBJPROP_XDISTANCE, m_xOffset);
        ObjectSetInteger(0, GetObjName("MNS_DASH_PANEL"), OBJPROP_YDISTANCE, m_yOffset);
        ObjectSetInteger(0, GetObjName("MNS_DASH_HEADER"), OBJPROP_XDISTANCE, m_xOffset);
        ObjectSetInteger(0, GetObjName("MNS_DASH_HEADER"), OBJPROP_YDISTANCE, m_yOffset);

        // Header Title
        ObjectSetInteger(0, GetObjName("MNS_DASH_TITLE"), OBJPROP_XDISTANCE, m_xOffset + m_style.paddingDashboard);
        ObjectSetInteger(0, GetObjName("MNS_DASH_TITLE"), OBJPROP_YDISTANCE, m_yOffset + 4);

        // Controls (Realignment of larger text buttons in the header)
        ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_LOCK"), OBJPROP_XDISTANCE, m_xOffset + m_width - 136);
        ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_LOCK"), OBJPROP_YDISTANCE, m_yOffset + 2);

        ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_COLLAPSE"), OBJPROP_XDISTANCE, m_xOffset + m_width - 84);
        ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_COLLAPSE"), OBJPROP_YDISTANCE, m_yOffset + 2);

        ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_HIDE"), OBJPROP_XDISTANCE, m_xOffset + m_width - 37);
        ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_HIDE"), OBJPROP_YDISTANCE, m_yOffset + 2);

        // Detail rows (if expanded)
        if (!m_isCollapsed)
        {
            int y      = m_yOffset + 22 + m_style.paddingDashboard;
            int rH     = m_style.rowHeightDashboard;
            int secH   = 14; // Section header height in pixels
            int pad    = m_style.paddingDashboard;
            int secX   = m_xOffset + pad;

            if (m_essentialsOnly)
            {
                // --- GROUP 1: MARKET STATE ---
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_MARKET"), OBJPROP_XDISTANCE, secX);
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_MARKET"), OBJPROP_YDISTANCE, y);
                y += secH;
                SetRowPosition("SYMBOL", y);       y += rH;
                SetRowPosition("TREND",  y);        y += rH;

                // --- GROUP 2: ACTIVE SETUP ---
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_SETUP"), OBJPROP_XDISTANCE, secX);
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_SETUP"), OBJPROP_YDISTANCE, y);
                y += secH;
                SetRowPosition("DOL", y);           y += rH;
                SetRowPosition("POI", y);           y += rH;

                // --- GROUP 3: SIGNAL ---
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_SIGNAL"), OBJPROP_XDISTANCE, secX);
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_SIGNAL"), OBJPROP_YDISTANCE, y);
                y += secH;
                SetRowPosition("CONFIRMATION", y);  y += rH;
                SetRowPosition("ENTRY",        y);  y += rH;
                SetRowPosition("ENTRY_PRICE",  y);  y += rH;
                SetRowPosition("SL",           y);  y += rH;

                // Reset Button
                ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_RESET"), OBJPROP_XDISTANCE, m_xOffset + pad);
                ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_RESET"), OBJPROP_YDISTANCE, y + pad);
            }
            else
            {
                // --- GROUP 1: MARKET STATE ---
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_MARKET"), OBJPROP_XDISTANCE, secX);
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_MARKET"), OBJPROP_YDISTANCE, y);
                y += secH;
                SetRowPosition("SYMBOL",    y);     y += rH;
                SetRowPosition("TREND",     y);     y += rH;
                SetRowPosition("PHASE",     y);     y += rH;
                SetRowPosition("STRUCTURE", y);     y += rH;
                SetRowPosition("BOS",       y);     y += rH;
                SetRowPosition("CHOCH",     y);     y += rH;
                SetRowPosition("BIAS",      y);     y += rH;

                // --- GROUP 2: ACTIVE SETUP ---
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_SETUP"), OBJPROP_XDISTANCE, secX);
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_SETUP"), OBJPROP_YDISTANCE, y);
                y += secH;
                SetRowPosition("DOL",  y);          y += rH;
                SetRowPosition("POI",  y);          y += rH;
                SetRowPosition("ZONE", y);          y += rH;

                // --- GROUP 3: SIGNAL ---
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_SIGNAL"), OBJPROP_XDISTANCE, secX);
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_SIGNAL"), OBJPROP_YDISTANCE, y);
                y += secH;
                SetRowPosition("CONFIRMATION", y);  y += rH;
                SetRowPosition("ENTRY",        y);  y += rH;
                SetRowPosition("ENTRY_PRICE",  y);  y += rH;
                SetRowPosition("SL",           y);  y += rH;

                // --- GROUP 4: FILTERS ---
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_FILTERS"), OBJPROP_XDISTANCE, secX);
                ObjectSetInteger(0, GetObjName("MNS_DASH_SEC_FILTERS"), OBJPROP_YDISTANCE, y);
                y += secH;
                SetRowPosition("SESSION", y);       y += rH;

                // Reset Button
                ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_RESET"), OBJPROP_XDISTANCE, m_xOffset + pad);
                ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_RESET"), OBJPROP_YDISTANCE, y + pad);
            }
        }
    }

    /// @brief Redraws panel borders, detail row visibilities, and sizes.
    void RedrawLayout()
    {
        if (!m_isInitialized) return;

        EnsureObjectsExist();

        if (!m_isVisible)
        {
            SetObjectVisibility("MNS_DASH_PANEL", false);
            SetObjectVisibility("MNS_DASH_HEADER", false);
            SetObjectVisibility("MNS_DASH_TITLE", false);
            SetObjectVisibility("MNS_DASH_BTN_LOCK", false);
            SetObjectVisibility("MNS_DASH_BTN_COLLAPSE", false);
            SetObjectVisibility("MNS_DASH_BTN_HIDE", false);
            SetObjectVisibility("MNS_DASH_BTN_RESET", false);
            HideDetailRows();

            // Show restore button
            SetObjectVisibility("MNS_DASH_BTN_RESTORE", true);
            
            // Trigger redraw
            string restoreBtnName = GetObjName("MNS_DASH_BTN_RESTORE");
            int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
            ObjectSetInteger(0, restoreBtnName, OBJPROP_XDISTANCE, chartWidth - 50);
            ObjectSetInteger(0, restoreBtnName, OBJPROP_YDISTANCE, 20);
            return;
        }

        // Hide restore button
        SetObjectVisibility("MNS_DASH_BTN_RESTORE", false);

        // Update panel size
        string panelName = GetObjName("MNS_DASH_PANEL");
        ObjectSetInteger(0, panelName, OBJPROP_YSIZE, this.GetCurrentHeight());

        // Header and core layout visible
        SetObjectVisibility("MNS_DASH_PANEL", true);
        SetObjectVisibility("MNS_DASH_HEADER", true);
        SetObjectVisibility("MNS_DASH_TITLE", true);
        SetObjectVisibility("MNS_DASH_BTN_LOCK", true);
        SetObjectVisibility("MNS_DASH_BTN_COLLAPSE", true);
        SetObjectVisibility("MNS_DASH_BTN_HIDE", true);

        // Update button texts
        ObjectSetString(0, GetObjName("MNS_DASH_BTN_LOCK"), OBJPROP_TEXT, m_isLocked ? "UNLOCK" : "LOCK");
        ObjectSetString(0, GetObjName("MNS_DASH_BTN_COLLAPSE"), OBJPROP_TEXT, m_isCollapsed ? "FULL" : "HUD");

        if (m_isCollapsed)
        {
            HideDetailRows();
            SetObjectVisibility("MNS_DASH_BTN_RESET", false);
        }
        else
        {
            ShowDetailRows();
            SetObjectVisibility("MNS_DASH_BTN_RESET", true);
        }

        UpdateObjectPositions();
    }

    /// @brief Toggle dashboard visibility.
    void SetVisible(bool visible)
    {
        m_isVisible = visible;
        string prefix = StringFormat("MNS_DASH_%I64d_%s_%d_", ChartID(), _Symbol, _Period);
        GlobalVariableSet(prefix + "VISIBLE", m_isVisible ? 1.0 : 0.0);
        RedrawLayout();
        ChartRedraw(0);
    }

    /// @brief Get dashboard visibility.
    bool IsVisible() const { return m_isVisible; }

    /// @brief Toggle dashboard lock.
    void SetLocked(bool locked)
    {
        m_isLocked = locked;
        string prefix = StringFormat("MNS_DASH_%I64d_%s_%d_", ChartID(), _Symbol, _Period);
        GlobalVariableSet(prefix + "LOCKED", m_isLocked ? 1.0 : 0.0);
        RedrawLayout();
        ChartRedraw(0);
    }

    /// @brief Get dashboard lock status.
    bool IsLocked() const { return m_isLocked; }

    /// @brief Toggle dashboard collapsed state.
    void SetCollapsed(bool collapsed)
    {
        m_isCollapsed = collapsed;
        string prefix = StringFormat("MNS_DASH_%I64d_%s_%d_", ChartID(), _Symbol, _Period);
        GlobalVariableSet(prefix + "COLLAPSED", m_isCollapsed ? 1.0 : 0.0);
        RedrawLayout();
        ChartRedraw(0);
    }

    /// @brief Get dashboard collapsed state.
    bool IsCollapsed() const { return m_isCollapsed; }

    /// @brief Set offsets manually.
    void SetPosition(int x, int y)
    {
        m_xOffset = x;
        m_yOffset = y;
        string prefix = StringFormat("MNS_DASH_%I64d_%s_%d_", ChartID(), _Symbol, _Period);
        GlobalVariableSet(prefix + "X", (double)m_xOffset);
        GlobalVariableSet(prefix + "Y", (double)m_yOffset);
        UpdateObjectPositions();
        ChartRedraw(0);
    }

    /// @brief Get current position coordinates.
    void GetPosition(int &x, int &y) const
    {
        x = m_xOffset;
        y = m_yOffset;
    }

    /// @brief Restores the dashboard to the default top-right corner.
    void ResetPosition()
    {
        SEngineConfig cfg = CMNSConfig::GetActive();
        int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        m_xOffset = chartWidth - m_width - cfg.dashboardX;
        m_yOffset = cfg.dashboardY;
        m_isCollapsed = false;
        m_isLocked = false;
        m_isVisible = true;

        string prefix = StringFormat("MNS_DASH_%I64d_%s_%d_", ChartID(), _Symbol, _Period);
        GlobalVariableSet(prefix + "X", (double)m_xOffset);
        GlobalVariableSet(prefix + "Y", (double)m_yOffset);
        GlobalVariableSet(prefix + "COLLAPSED", 0.0);
        GlobalVariableSet(prefix + "LOCKED", 0.0);
        GlobalVariableSet(prefix + "VISIBLE", 1.0);

        RedrawLayout();
        ChartRedraw(0);
    }

    /// @brief Processes interactive UI actions from chart events.
    void HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if (!m_isInitialized)
            return;

        string prefix = StringFormat("MNS_DASH_%I64d_%s_%d_", ChartID(), _Symbol, _Period);

        // 1. Handle Restore Button (when hidden)
        if (!m_isVisible)
        {
            if (id == CHARTEVENT_OBJECT_CLICK && sparam == GetObjName("MNS_DASH_BTN_RESTORE"))
            {
                SetVisible(true);
                ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_RESTORE"), OBJPROP_STATE, false);
            }
            return;
        }

        // 2. Handle Expand/Collapse, Lock, Hide, Reset button clicks
        if (id == CHARTEVENT_OBJECT_CLICK)
        {
            string clickedName = sparam;
            if (clickedName == GetObjName("MNS_DASH_BTN_LOCK"))
            {
                m_isLocked = !m_isLocked;
                GlobalVariableSet(prefix + "LOCKED", m_isLocked ? 1.0 : 0.0);
                ObjectSetString(0, GetObjName("MNS_DASH_BTN_LOCK"), OBJPROP_TEXT, m_isLocked ? "UNLOCK" : "LOCK");
                ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_LOCK"), OBJPROP_STATE, false);
                ChartRedraw(0);
            }
            else if (clickedName == GetObjName("MNS_DASH_BTN_COLLAPSE"))
            {
                m_isCollapsed = !m_isCollapsed;
                GlobalVariableSet(prefix + "COLLAPSED", m_isCollapsed ? 1.0 : 0.0);
                ObjectSetString(0, GetObjName("MNS_DASH_BTN_COLLAPSE"), OBJPROP_TEXT, m_isCollapsed ? "FULL" : "HUD");
                ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_COLLAPSE"), OBJPROP_STATE, false);
                RedrawLayout();
                ChartRedraw(0);
            }
            else if (clickedName == GetObjName("MNS_DASH_BTN_HIDE"))
            {
                SetVisible(false);
                ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_HIDE"), OBJPROP_STATE, false);
            }
            else if (clickedName == GetObjName("MNS_DASH_BTN_RESET"))
            {
                ResetPosition();
                ObjectSetInteger(0, GetObjName("MNS_DASH_BTN_RESET"), OBJPROP_STATE, false);
            }
        }

        // 3. Handle Dragging via Mouse Move
        if (id == CHARTEVENT_MOUSE_MOVE)
        {
            int mouseX = (int)lparam;
            int mouseY = (int)dparam;
            int mouseState = (int)sparam;
            bool leftButtonPressed = (mouseState & 1) == 1;

            if (leftButtonPressed)
            {
                if (m_isLocked)
                {
                    if (m_isDragging)
                    {
                        m_isDragging = false;
                        ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
                    }
                    return;
                }

                if (!m_isDragging)
                {
                    // Drag handle is the header area (Y offset to Y offset + 22)
                    if (mouseX >= m_xOffset && mouseX <= m_xOffset + m_width &&
                        mouseY >= m_yOffset && mouseY <= m_yOffset + 22)
                    {
                        m_isDragging = true;
                        m_dragDx = mouseX - m_xOffset;
                        m_dragDy = mouseY - m_yOffset;
                        ChartSetInteger(0, CHART_MOUSE_SCROLL, false); // Disable chart scrolling during drag
                    }
                }
                else
                {
                    // Update positions
                    int newX = mouseX - m_dragDx;
                    int newY = mouseY - m_dragDy;

                    int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
                    int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
                    int height = this.GetCurrentHeight();

                    newX = MathMax(0, MathMin(newX, chartWidth - m_width));
                    newY = MathMax(0, MathMin(newY, chartHeight - height));

                    m_xOffset = newX;
                    m_yOffset = newY;

                    GlobalVariableSet(prefix + "X", (double)m_xOffset);
                    GlobalVariableSet(prefix + "Y", (double)m_yOffset);

                    UpdateObjectPositions();
                    ChartRedraw(0);
                }
            }
            else
            {
                if (m_isDragging)
                {
                    m_isDragging = false;
                    ChartSetInteger(0, CHART_MOUSE_SCROLL, true); // Re-enable chart scrolling
                }
            }
        }

        // 4. Handle Chart Resize Boundary Clamping
        if (id == CHARTEVENT_CHART_CHANGE)
        {
            int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
            int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
            int height = this.GetCurrentHeight();

            bool adjusted = false;
            if (m_xOffset > chartWidth - m_width)
            {
                m_xOffset = MathMax(0, chartWidth - m_width);
                adjusted = true;
            }
            if (m_yOffset > chartHeight - height)
            {
                m_yOffset = MathMax(0, chartHeight - height);
                adjusted = true;
            }

            if (adjusted)
            {
                GlobalVariableSet(prefix + "X", (double)m_xOffset);
                GlobalVariableSet(prefix + "Y", (double)m_yOffset);
                UpdateObjectPositions();
                ChartRedraw(0);
            }
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

        SEngineConfig cfg = CMNSConfig::GetActive();
        m_width = cfg.dashboardWidth;
        m_showDashboard = cfg.showDashboard;

        // If hidden or not shown, ensure cleaned up and return
        if (!m_isVisible)
        {
            RedrawLayout();
            return;
        }

        // Dynamically correct coordinates if they were initialized off-screen
        // (common when OnInit runs and chart dimensions are reported as 0)
        int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
        int panelHeight = this.GetCurrentHeight();
        bool positionCorrected = false;

        if (chartWidth > 0 && chartHeight > 0)
        {
            if (m_xOffset < 0 || m_xOffset > chartWidth - m_width)
            {
                m_xOffset = MathMax(0, chartWidth - m_width - cfg.dashboardX);
                positionCorrected = true;
            }
            if (m_yOffset < 0 || m_yOffset > chartHeight - panelHeight)
            {
                m_yOffset = MathMax(0, cfg.dashboardY);
                positionCorrected = true;
            }
        }

        // Make sure all layout objects exist
        EnsureObjectsExist();

        if (positionCorrected)
        {
            UpdateObjectPositions();
        }

        // Current price context for calculations
        double currentPrice = (ratesTotal > 1) ? close[1] : close[0];

        // ------------------------------------------
        // Data Extraction
        // ------------------------------------------

        // Timeframe string conversion
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

        // Trend
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

        // Phase
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

        // Structure Type
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

        // Last BOS
        SStructureBreak latestBOS = breakDetector.GetLatestBOS();
        string bosVal = "None";
        color  bosCol = clrLightGray;
        if (latestBOS.isConfirmed)
        {
            bool isBull = (latestBOS.brokenSwing.type == SWING_HIGH);
            bosVal = StringFormat("%s @ %s", (isBull ? "Bullish" : "Bearish"), DoubleToString(latestBOS.price, _Digits));
            bosCol = isBull ? clrLime : clrRed;
        }

        // Last CHoCH
        SStructureBreak latestCHoCH = breakDetector.GetLatestCHOCH();
        string chochVal = "None";
        color  chochCol = clrLightGray;
        if (latestCHoCH.isConfirmed)
        {
            bool isBull = (latestCHoCH.brokenSwing.type == SWING_HIGH);
            chochVal = StringFormat("%s @ %s", (isBull ? "Bullish" : "Bearish"), DoubleToString(latestCHoCH.price, _Digits));
            chochCol = isBull ? clrLime : clrRed;
        }

        // Active DOL
        SDolDefinition dol = objectiveEngine.GetActiveDol();
        bool isDolActive = (dol.active && dol.score >= 60.0 && dol.price != DBL_MAX);
        string dolVal = "None";
        color  dolCol = clrLightGray;
        if (isDolActive)
        {
            dolVal = StringFormat("%s (%s)", DoubleToString(dol.price, _Digits), GetDolTypeString(dol.type));
            dolCol = m_style.colorDOL;
        }

        // Liquidity Bias (Inferred from active DOL)
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

        // Active POI (Closest active POI)
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

        // DR Zone
        string zoneVal = "None";
        color  zoneCol = clrLightGray;
        double eq = poiEngine.GetEquilibrium(deliveryEngine);
        if (eq != 0.0 && eq != DBL_MAX)
        {
            EDealingRangeZone zone = poiEngine.GetDealingRangeZone(currentPrice, deliveryEngine);
            switch (zone)
            {
                case ZONE_PREMIUM:     zoneVal = "Premium"; zoneCol = clrRed; break;
                case ZONE_DISCOUNT:    zoneVal = "Discount"; zoneCol = clrLime; break;
                case ZONE_EQUILIBRIUM: zoneVal = "Equilibrium"; zoneCol = clrGold; break;
                default:               break;
            }
        }

        // Session
        bool isTokyo  = CMNSUtils::IsInSession(gmtTime, 0, 8);
        bool isLondon = CMNSUtils::IsInSession(gmtTime, 8, 16);
        bool isNY     = CMNSUtils::IsInSession(gmtTime, 13, 21);

        string sessionVal = "";
        if (isTokyo)  sessionVal += (StringLen(sessionVal) > 0 ? "/" : "") + "Tokyo";
        if (isLondon) sessionVal += (StringLen(sessionVal) > 0 ? "/" : "") + "London";
        if (isNY)     sessionVal += (StringLen(sessionVal) > 0 ? "/" : "") + "NY";

        if (StringLen(sessionVal) == 0)
        {
            sessionVal = "Closed";
        }

        // Confirmation State
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

        // Entry Signal
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

        // ------------------------------------------
        // Render Execution
        // ------------------------------------------
        // Extract exact Entry Price and SL values if a signal is active or has been executed
        SEntrySignal activeSig = entryEngine.GetActiveSignal();
        string entryPriceVal = "None";
        color  entryPriceCol = clrLightGray;
        string slVal = "None";
        color  slCol = clrLightGray;

        if (entState == ENTRY_STATE_ACTIVE || entState == ENTRY_STATE_EXECUTED)
        {
            entryPriceVal = DoubleToString(activeSig.entryPrice, _Digits);
            entryPriceCol = clrWhite;
            slVal = DoubleToString(activeSig.stopLoss, _Digits);
            slCol = clrOrangeRed;
        }

        if (m_isCollapsed)
        {
            // Collapsed HUD title updates showing desaturated state
            string breakState = latestBOS.isConfirmed ? "BOS" : (latestCHoCH.isConfirmed ? "CHoCH" : "NONE");
            string hudText = StringFormat("⁞⁞ MNS | %s | %s | %s | %s", tfStr, trendVal, breakState, sessionVal);
            StringToUpper(hudText);
            ObjectSetString(0, GetObjName("MNS_DASH_TITLE"), OBJPROP_TEXT, hudText);
        }
        else
        {
            // Standard Title
            ObjectSetString(0, GetObjName("MNS_DASH_TITLE"), OBJPROP_TEXT, "⁞⁞ MNS ENGINE v1.0");

            // Update row value labels
            UpdateRowText("SYMBOL", StringFormat("%s, %s", _Symbol, tfStr), m_style.colorDashboardValue);
            UpdateRowText("TREND", trendVal, trendCol);
            UpdateRowText("PHASE", phaseVal, phaseCol);
            UpdateRowText("STRUCTURE", structVal, structCol);
            UpdateRowText("BOS", bosVal, bosCol);
            UpdateRowText("CHOCH", chochVal, chochCol);
            UpdateRowText("BIAS", biasVal, biasCol);
            UpdateRowText("DOL", dolVal, dolCol);
            UpdateRowText("POI", poiVal, poiCol);
            UpdateRowText("ZONE", zoneVal, zoneCol);
            UpdateRowText("SESSION", sessionVal, m_style.colorDashboardValue);
            UpdateRowText("CONFIRMATION", confVal, confCol);
            UpdateRowText("ENTRY", entVal, entCol);
            UpdateRowText("ENTRY_PRICE", entryPriceVal, entryPriceCol);
            UpdateRowText("SL", slVal, slCol);
        }
    }
};

#endif // __MNS_DASHBOARD_RENDERER_MQH__
