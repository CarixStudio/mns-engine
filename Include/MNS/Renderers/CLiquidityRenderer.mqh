//+------------------------------------------------------------------+
//|                                           CLiquidityRenderer.mqh |
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Visual controller for rendering active BSL/SSL levels and      |
//|   EQH/EQL equal pivot markers on the chart using MT5 trend lines. |
//|   Handles capping limits and automatic cleanup of historical      |
//|   and invalid objects.                                           |
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh                                                   |
//|   CLiquidityEngine.mqh                                           |
//|   MNSStyle.mqh                                                   |
//+------------------------------------------------------------------+
#ifndef __MNS_LIQUIDITY_RENDERER_MQH__
#define __MNS_LIQUIDITY_RENDERER_MQH__

#include "../MNSTypes.mqh"
#include "../CLiquidityEngine.mqh"
#include "../MNSStyle.mqh"

//+------------------------------------------------------------------+
//| CLiquidityRenderer                                               |
//| @brief Draws active BSL/SSL and EQH/EQL levels on the chart.      |
//+------------------------------------------------------------------+
class CLiquidityRenderer
{
private:
    SIndicatorStyle m_style;           ///< Cached visual style configuration
    int             m_maxPools;        ///< Capping limit for rendered liquidity pool objects
    bool            m_isInitialized;    ///< Initialization guard flag

    /// @brief Generates a unique object name for a pool based on its ID, type, and source.
    /// @param id Unique pool identifier.
    /// @param type Liquidity type (BSL or SSL).
    /// @param source Liquidity source (EQ or other).
    /// @return The constructed chart object name.
    string GetObjectName(int id, ELiquidityType type, ELiquiditySource source) const
    {
        string prefix = "MNS_Liq";
        string typeStr = "";
        
        if (source == LIQ_SRC_EQ)
        {
            typeStr = (type == LIQUIDITY_BSL) ? "EQH" : "EQL";
        }
        else
        {
            typeStr = (type == LIQUIDITY_BSL) ? "BSL" : "SSL";
        }
        
        return StringFormat("%s%s_%d", prefix, typeStr, id);
    }

    /// @brief Generates the label object name for a liquidity pool.
    /// @param id Unique pool identifier.
    /// @param type Liquidity type.
    /// @param source Liquidity source.
    /// @return The constructed label object name.
    string GetLabelName(int id, ELiquidityType type, ELiquiditySource source) const
    {
        string typeStr = "";
        if (source == LIQ_SRC_EQ)
            typeStr = (type == LIQUIDITY_BSL) ? "EQH" : "EQL";
        else
            typeStr = (type == LIQUIDITY_BSL) ? "BSL" : "SSL";
        return StringFormat("MNS_LiqLbl%s_%d", typeStr, id);
    }

    /// @brief Checks if a pool is active on the chart.
    /// @param pool The liquidity pool structure.
    /// @return True if the pool is active (LIQ_ACTIVE or LIQ_TOUCHED).
    bool IsPoolActive(const SLiquidityPool &pool) const
    {
        if (pool.source == LIQ_SRC_EQ)
        {
            return (pool.lifecycle == LIQ_ACTIVE || pool.lifecycle == LIQ_TOUCHED);
        }
        return (pool.active || pool.lifecycle == LIQ_ACTIVE || pool.lifecycle == LIQ_TOUCHED);
    }

    /// @brief Checks if a pool is swept on the chart.
    /// @param pool The liquidity pool structure.
    /// @return True if the pool is swept.
    bool IsPoolSwept(const SLiquidityPool &pool) const
    {
        if (pool.source == LIQ_SRC_EQ)
        {
            return false;
        }
        return (pool.lifecycle == LIQ_SWEPT || pool.swept);
    }

    /// @brief Renders or updates a single liquidity pool object on the chart.
    /// @param pool The liquidity pool structure.
    /// @param lastConfirmedBarTime Datetime of the last closed bar time.
    void RenderPool(const SLiquidityPool &pool, datetime lastConfirmedBarTime)
    {
        string name = GetObjectName(pool.id, pool.type, pool.source);
        
        datetime time1 = pool.createdTime;
        double   price = pool.level;
        
        bool isSwept = IsPoolSwept(pool);
        datetime time2 = isSwept ? pool.sweptTime : lastConfirmedBarTime;
        if (time2 < time1)
            time2 = time1;

        color lineColor;
        ENUM_LINE_STYLE lineStyle;
        
        // ⚠️ Inferred: line width scaled by priority
        int lineWidth = m_style.widthLiqLine;
        if (pool.priority == PRIORITY_MEDIUM)
            lineWidth += 1;
        else if (pool.priority == PRIORITY_HIGH)
            lineWidth += 2;

        // Determine colors and styles
        if (isSwept)
        {
            lineColor = m_style.colorSweptPool;
            lineStyle = m_style.styleLiqSwept;
        }
        else if (pool.source == LIQ_SRC_EQ)
        {
            lineColor = (pool.type == LIQUIDITY_BSL) ? m_style.colorEQH : m_style.colorEQL;
            lineStyle = STYLE_DOT; // Equal pivots drawn as dotted lines
        }
        else
        {
            lineColor = (pool.type == LIQUIDITY_BSL) ? m_style.colorBSL : m_style.colorSSL;
            lineStyle = m_style.styleLiqActive;
        }

        // Create or move the trend line
        if (ObjectFind(0, name) < 0)
        {
            if (!ObjectCreate(0, name, OBJ_TREND, 0, time1, price, time2, price))
            {
                Print(StringFormat("[ERROR] [CLiquidityRenderer] Failed to create object %s. Error code: %d", name, GetLastError()));
                return;
            }
        }
        else
        {
            ObjectMove(0, name, 0, time1, price);
            ObjectMove(0, name, 1, time2, price);
        }

        // Set visual properties
        ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, lineWidth);
        ObjectSetInteger(0, name, OBJPROP_STYLE, lineStyle);
        ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
        ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);       // Draw behind candles
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

        // --- Draw/Update the inline name label ---
        string labelName = GetLabelName(pool.id, pool.type, pool.source);
        string labelText = "";
        if (isSwept)
            labelText = "Swept";
        else if (pool.source == LIQ_SRC_EQ)
            labelText = (pool.type == LIQUIDITY_BSL) ? "EQH" : "EQL";
        else
            labelText = (pool.type == LIQUIDITY_BSL) ? "BSL" : "SSL";

        if (ObjectFind(0, labelName) < 0)
            ObjectCreate(0, labelName, OBJ_TEXT, 0, time2, price);
        else
            ObjectMove(0, labelName, 0, time2, price);

        ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
        ObjectSetString(0, labelName, OBJPROP_FONT, m_style.fontName);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, m_style.fontSizeLabel);
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, lineColor);
        ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
        ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
        ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, labelName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
    }

public:
    /// @brief Constructor.
    CLiquidityRenderer() : m_maxPools(20), m_isInitialized(false)
    {
        m_style.Reset();
    }

    /// @brief Destructor.
    ~CLiquidityRenderer()
    {
        Reset();
    }

    /// @brief Initializes the Liquidity Renderer with custom style and limits.
    /// @param style Shared visual style configuration.
    /// @param maxPools Max number of active/swept pools to keep rendered.
    /// @return True on success.
    bool Initialize(const SIndicatorStyle &style, int maxPools)
    {
        m_style = style;
        m_maxPools = (maxPools > 0) ? maxPools : 20;
        m_isInitialized = true;
        return true;
    }

    /// @brief Clears all liquidity pool objects from the chart.
    void Reset()
    {
        ObjectsDeleteAll(0, "MNS_Liq");    // covers MNS_LiqBSL_, MNS_LiqSSL_, MNS_LiqEQH_, MNS_LiqEQL_
        ObjectsDeleteAll(0, "MNS_LiqLbl"); // covers all inline name labels
    }

    /// @brief Processes liquidity pools and draws/cleans chart objects.
    /// @param liquidityEngine Source CLiquidityEngine engine.
    /// @param time Chart datetime array (time-series sorted).
    /// @param ratesTotal Total chart bars.
    void Draw(const CLiquidityEngine &liquidityEngine, const datetime &time[], int ratesTotal)
    {
        if (!m_isInitialized)
            return;

        int totalPools = liquidityEngine.GetPoolsCount();
        if (totalPools <= 0)
        {
            Reset();
            return;
        }

        // 1. Gather all active and swept pools
        int renderableCount = 0;
        SLiquidityPool renderablePools[128];

        for (int i = 0; i < totalPools; i++)
        {
            SLiquidityPool pool;
            if (liquidityEngine.GetPool(i, pool))
            {
                if (IsPoolActive(pool) || IsPoolSwept(pool))
                {
                    renderablePools[renderableCount] = pool;
                    renderableCount++;
                }
            }
        }

        // 2. Sort renderable pools by createdTime ascending (oldest first), 
        //    using pool.id as secondary sort key.
        for (int i = 0; i < renderableCount - 1; i++)
        {
            for (int j = i + 1; j < renderableCount; j++)
            {
                if (renderablePools[i].createdTime > renderablePools[j].createdTime ||
                    (renderablePools[i].createdTime == renderablePools[j].createdTime && renderablePools[i].id > renderablePools[j].id))
                {
                    SLiquidityPool temp = renderablePools[i];
                    renderablePools[i] = renderablePools[j];
                    renderablePools[j] = temp;
                }
            }
        }

        // 3. Keep track of which pools are drawn this turn
        bool renderedThisTurn[128];
        for (int i = 0; i < 128; i++)
            renderedThisTurn[i] = false;

        int startIdx = 0;
        if (renderableCount > m_maxPools)
        {
            startIdx = renderableCount - m_maxPools;
        }

        datetime lastConfirmedTime = (ratesTotal > 1) ? time[1] : time[0];

        for (int i = startIdx; i < renderableCount; i++)
        {
            SLiquidityPool pool = renderablePools[i];
            RenderPool(pool, lastConfirmedTime);
            if (pool.id >= 0 && pool.id < 128)
            {
                renderedThisTurn[pool.id] = true;
            }
        }

        // 4. Delete all objects for pool IDs that were NOT rendered this turn
        //    (this automatically cleans up broken, archived, or capped-out pools)
        for (int i = 0; i < 128; i++)
        {
            if (!renderedThisTurn[i])
            {
                // Delete all possible visual representations for this ID
                string nameBSL = GetObjectName(i, LIQUIDITY_BSL, LIQ_SRC_SWING);
                string nameSSL = GetObjectName(i, LIQUIDITY_SSL, LIQ_SRC_SWING);
                string nameEQH = GetObjectName(i, LIQUIDITY_BSL, LIQ_SRC_EQ);
                string nameEQL = GetObjectName(i, LIQUIDITY_SSL, LIQ_SRC_EQ);

                if (ObjectFind(0, nameBSL) >= 0) ObjectDelete(0, nameBSL);
                if (ObjectFind(0, nameSSL) >= 0) ObjectDelete(0, nameSSL);
                if (ObjectFind(0, nameEQH) >= 0) ObjectDelete(0, nameEQH);
                if (ObjectFind(0, nameEQL) >= 0) ObjectDelete(0, nameEQL);
            }
        }
    }
};

#endif // __MNS_LIQUIDITY_RENDERER_MQH__
