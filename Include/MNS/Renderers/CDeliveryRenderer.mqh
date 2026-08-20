//+------------------------------------------------------------------+
//|                                             CDeliveryRenderer.mqh|
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Visual controller for drawing the single active price-delivery  |
//|   leg and active Draw on Liquidity (DOL) target level.           |
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh                                                   |
//|   CDeliveryStructureEngine.mqh                                   |
//|   CObjectiveEngine.mqh                                           |
//|   MNSStyle.mqh                                                   |
//+------------------------------------------------------------------+
#ifndef __MNS_DELIVERY_RENDERER_MQH__
#define __MNS_DELIVERY_RENDERER_MQH__

#include "../MNSTypes.mqh"
#include "../CDeliveryStructureEngine.mqh"
#include "../CObjectiveEngine.mqh"
#include "../MNSStyle.mqh"

//+------------------------------------------------------------------+
//| CDeliveryRenderer                                                |
//| @brief Draws active delivery leg and Draw on Liquidity target.   |
//+------------------------------------------------------------------+
class CDeliveryRenderer
{
private:
    SIndicatorStyle m_style;           ///< Cached visual style configuration
    bool            m_isInitialized;    ///< Initialization guard flag

    const string    m_deliveryObjectName; ///< Name of the delivery leg trend line ("MNS_Delivery_Leg")
    const string    m_dolObjectName;      ///< Name of the DOL trend line ray ("MNS_DOL_Target")
    const string    m_dolLabelName;       ///< Name of the DOL text label ("MNS_DOL_Label")

    /// @brief Clears the delivery leg object.
    void ClearDelivery()
    {
        if (ObjectFind(0, m_deliveryObjectName) >= 0)
        {
            ObjectDelete(0, m_deliveryObjectName);
        }
    }

    /// @brief Clears the DOL target level and label.
    void ClearDol()
    {
        if (ObjectFind(0, m_dolObjectName) >= 0)
        {
            ObjectDelete(0, m_dolObjectName);
        }
        if (ObjectFind(0, m_dolLabelName) >= 0)
        {
            ObjectDelete(0, m_dolLabelName);
        }
    }

public:
    /// @brief Constructor.
    CDeliveryRenderer() 
        : m_isInitialized(false),
          m_deliveryObjectName("MNS_Delivery_Leg"),
          m_dolObjectName("MNS_DOL_Target"),
          m_dolLabelName("MNS_DOL_Label")
    {
        m_style.Reset();
    }

    /// @brief Destructor.
    ~CDeliveryRenderer()
    {
        Reset();
    }

    /// @brief Initializes the renderer with the style structure.
    /// @param style Shared visual style configuration.
    /// @return True on success.
    bool Initialize(const SIndicatorStyle &style)
    {
        m_style = style;
        m_isInitialized = true;
        return true;
    }

    /// @brief Deletes all rendering objects from the chart.
    void Reset()
    {
        ClearDelivery();
        ClearDol();
    }

    /// @brief Draws or cleans up active delivery leg and DOL targets.
    /// @param deliveryEngine Active delivery structure engine.
    /// @param objectiveEngine Active DOL selection engine.
    /// @param time Chart datetime array.
    /// @param close Chart close price array.
    /// @param ratesTotal Total chart bars.
    void Draw(const CDeliveryStructureEngine &deliveryEngine,
              const CObjectiveEngine &objectiveEngine,
              const datetime &time[],
              const double &close[],
              int ratesTotal)
    {
        if (!m_isInitialized)
            return;

        datetime lastConfirmedTime = (ratesTotal > 1) ? time[1] : time[0];
        double lastClosePrice = (ratesTotal > 1) ? close[1] : close[0];

        // ==========================================
        // 1. RENDER ACTIVE DELIVERY LEG
        // ==========================================
        SDeliveryState delState = deliveryEngine.GetState();

        bool isDeliveryActive = (delState.lifecycle == DELIVERY_ACTIVE || delState.lifecycle == DELIVERY_MITIGATED);

        if (isDeliveryActive && delState.direction != DELIVERY_DIR_NEUTRAL)
        {
            datetime startT = delState.originTime;
            double   startP = delState.originPrice;
            datetime endT   = lastConfirmedTime;
            double   endP   = lastClosePrice;

            if (endT < startT)
                endT = startT;

            color           lineColor = clrGray;
            ENUM_LINE_STYLE lineStyle = STYLE_SOLID;

            if (delState.direction == DELIVERY_DIR_BULLISH)
            {
                lineColor = m_style.colorDeliveryBull;
            }
            else if (delState.direction == DELIVERY_DIR_BEARISH)
            {
                lineColor = m_style.colorDeliveryBear;
            }

            if (delState.lifecycle == DELIVERY_MITIGATED)
            {
                lineStyle = STYLE_DASH; // Dashing shows leg is under pressure
            }

            if (ObjectFind(0, m_deliveryObjectName) < 0)
            {
                if (!ObjectCreate(0, m_deliveryObjectName, OBJ_TREND, 0, startT, startP, endT, endP))
                {
                    Print(StringFormat("[ERROR] [CDeliveryRenderer] Failed to create delivery object. Error: %d", GetLastError()));
                }
            }
            else
            {
                ObjectMove(0, m_deliveryObjectName, 0, startT, startP);
                ObjectMove(0, m_deliveryObjectName, 1, endT, endP);
            }

            ObjectSetInteger(0, m_deliveryObjectName, OBJPROP_COLOR, lineColor);
            ObjectSetInteger(0, m_deliveryObjectName, OBJPROP_STYLE, lineStyle);
            ObjectSetInteger(0, m_deliveryObjectName, OBJPROP_WIDTH, m_style.widthDeliveryLine);
            ObjectSetInteger(0, m_deliveryObjectName, OBJPROP_RAY_RIGHT, false); // Bounded segment
            ObjectSetInteger(0, m_deliveryObjectName, OBJPROP_BACK, false);     // Draw on top of candles
            ObjectSetInteger(0, m_deliveryObjectName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, m_deliveryObjectName, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, m_deliveryObjectName, OBJPROP_HIDDEN, true);
        }
        else
        {
            ClearDelivery();
        }

        // ==========================================
        // 2. RENDER ACTIVE DOL TARGET
        // ==========================================
        SDolDefinition dol = objectiveEngine.GetActiveDol();

        bool isDolActive = (dol.active && dol.score >= 60.0 && dol.price != DBL_MAX);

        if (isDolActive)
        {
            datetime startT = dol.createdTime;
            double   targetP = dol.price;
            datetime endT   = lastConfirmedTime;

            if (endT < startT)
                endT = startT;

            // Draw/Update trend line ray
            if (ObjectFind(0, m_dolObjectName) < 0)
            {
                if (!ObjectCreate(0, m_dolObjectName, OBJ_TREND, 0, startT, targetP, endT, targetP))
                {
                    Print(StringFormat("[ERROR] [CDeliveryRenderer] Failed to create DOL trend object. Error: %d", GetLastError()));
                }
            }
            else
            {
                ObjectMove(0, m_dolObjectName, 0, startT, targetP);
                ObjectMove(0, m_dolObjectName, 1, endT, targetP);
            }

            ObjectSetInteger(0, m_dolObjectName, OBJPROP_COLOR, m_style.colorDOL);
            ObjectSetInteger(0, m_dolObjectName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, m_dolObjectName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, m_dolObjectName, OBJPROP_RAY_RIGHT, false); // Bounded line ray
            ObjectSetInteger(0, m_dolObjectName, OBJPROP_BACK, false);
            ObjectSetInteger(0, m_dolObjectName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, m_dolObjectName, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, m_dolObjectName, OBJPROP_HIDDEN, true);

            // Draw/Update DOL label text
            if (ObjectFind(0, m_dolLabelName) < 0)
            {
                if (!ObjectCreate(0, m_dolLabelName, OBJ_TEXT, 0, endT, targetP))
                {
                    Print(StringFormat("[ERROR] [CDeliveryRenderer] Failed to create DOL label object. Error: %d", GetLastError()));
                }
            }
            else
            {
                ObjectMove(0, m_dolLabelName, 0, endT, targetP);
            }

            ObjectSetString(0, m_dolLabelName, OBJPROP_TEXT, "DOL");
            ObjectSetString(0, m_dolLabelName, OBJPROP_FONT, m_style.fontName);
            ObjectSetInteger(0, m_dolLabelName, OBJPROP_FONTSIZE, m_style.fontSizeLabel);
            ObjectSetInteger(0, m_dolLabelName, OBJPROP_COLOR, m_style.colorDOL);
            ObjectSetInteger(0, m_dolLabelName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
            ObjectSetInteger(0, m_dolLabelName, OBJPROP_BACK, false);
            ObjectSetInteger(0, m_dolLabelName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, m_dolLabelName, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, m_dolLabelName, OBJPROP_HIDDEN, true);
        }
        else
        {
            ClearDol();
        }
    }
};

#endif // __MNS_DELIVERY_RENDERER_MQH__
