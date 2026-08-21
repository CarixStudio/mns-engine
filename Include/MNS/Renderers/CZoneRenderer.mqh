//+------------------------------------------------------------------+
//|                                                CZoneRenderer.mqh |
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Visual controller for rendering Premium/Discount zones and      |
//|   the Equilibrium line of the dealing range on the chart using   |
//|   MT5 rectangles and trend lines.                                |
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh                                                   |
//|   CSwingDetector.mqh                                             |
//|   MNSStyle.mqh                                                   |
//|   MNSConfig.mqh                                                  |
//+------------------------------------------------------------------+
#ifndef __MNS_ZONE_RENDERER_MQH__
#define __MNS_ZONE_RENDERER_MQH__

#include "../MNSTypes.mqh"
#include "../CSwingDetector.mqh"
#include "../MNSStyle.mqh"
#include "../MNSConfig.mqh"

class CZoneRenderer
{
private:
    SIndicatorStyle m_style;          ///< Cached visual style configuration
    bool            m_isInitialized;  ///< Initialization guard flag

    // Naming constants
    static const string PREM_OBJ_NAME;
    static const string DISC_OBJ_NAME;
    static const string EQ_OBJ_NAME;

public:
    // Constructor
    CZoneRenderer() : m_isInitialized(false)
    {
        m_style.Reset();
    }

    // Destructor
    ~CZoneRenderer()
    {
        Reset();
    }

    /// @brief Initializes the Zone Renderer with custom styles.
    /// @param style Shared visual style configuration.
    /// @return True on success.
    bool Initialize(const SIndicatorStyle &style)
    {
        m_style = style;
        m_isInitialized = true;
        return true;
    }

    /// @brief Clears all zone and equilibrium objects from the chart.
    void Reset()
    {
        if (ObjectFind(0, PREM_OBJ_NAME) >= 0)
            ObjectDelete(0, PREM_OBJ_NAME);
        if (ObjectFind(0, DISC_OBJ_NAME) >= 0)
            ObjectDelete(0, DISC_OBJ_NAME);
        if (ObjectFind(0, EQ_OBJ_NAME) >= 0)
            ObjectDelete(0, EQ_OBJ_NAME);
    }

    /// @brief Evaluates swings and draws/updates zone objects.
    /// @param swingDetector Source CSwingDetector engine.
    /// @param time Chart datetime array (series order).
    /// @param ratesTotal Total chart bars.
    void Draw(const CSwingDetector &swingDetector, const datetime &time[], int ratesTotal)
    {
        if (!m_isInitialized)
            return;

        SEngineConfig cfg = CMNSConfig::GetActive();

        // 1. Fetch latest external swing highs/lows
        SSwingPoint extHigh = swingDetector.GetLatestExternalHigh();
        SSwingPoint extLow = swingDetector.GetLatestExternalLow();

        // 2. Validate swings exist and are confirmed
        if (!extHigh.isConfirmed || !extLow.isConfirmed || ratesTotal < 2)
        {
            Reset();
            return;
        }

        // 3. Calculate anchors
        double highPrice = extHigh.price;
        double lowPrice  = extLow.price;
        double eqPrice   = (highPrice + lowPrice) / 2.0;

        datetime startTime = MathMin(extHigh.time, extLow.time);
        datetime endTime   = time[1]; // Anchored to last completed bar

        // 4. Render/Update Premium Zone
        if (cfg.showZonePremium)
        {
            if (ObjectFind(0, PREM_OBJ_NAME) < 0)
            {
                if (!ObjectCreate(0, PREM_OBJ_NAME, OBJ_RECTANGLE, 0, startTime, highPrice, endTime, eqPrice))
                {
                    Print("[ERROR] [CZoneRenderer] Failed to create Premium Zone object.");
                }
            }
            else
            {
                ObjectMove(0, PREM_OBJ_NAME, 0, startTime, highPrice);
                ObjectMove(0, PREM_OBJ_NAME, 1, endTime, eqPrice);
            }

            ObjectSetInteger(0, PREM_OBJ_NAME, OBJPROP_COLOR, m_style.colorZonePremium);
            ObjectSetInteger(0, PREM_OBJ_NAME, OBJPROP_FILL, true);
            ObjectSetInteger(0, PREM_OBJ_NAME, OBJPROP_BACK, true);
            ObjectSetInteger(0, PREM_OBJ_NAME, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, PREM_OBJ_NAME, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, PREM_OBJ_NAME, OBJPROP_HIDDEN, true);
        }
        else
        {
            if (ObjectFind(0, PREM_OBJ_NAME) >= 0)
                ObjectDelete(0, PREM_OBJ_NAME);
        }

        // 5. Render/Update Discount Zone
        if (cfg.showZoneDiscount)
        {
            if (ObjectFind(0, DISC_OBJ_NAME) < 0)
            {
                if (!ObjectCreate(0, DISC_OBJ_NAME, OBJ_RECTANGLE, 0, startTime, eqPrice, endTime, lowPrice))
                {
                    Print("[ERROR] [CZoneRenderer] Failed to create Discount Zone object.");
                }
            }
            else
            {
                ObjectMove(0, DISC_OBJ_NAME, 0, startTime, eqPrice);
                ObjectMove(0, DISC_OBJ_NAME, 1, endTime, lowPrice);
            }

            ObjectSetInteger(0, DISC_OBJ_NAME, OBJPROP_COLOR, m_style.colorZoneDiscount);
            ObjectSetInteger(0, DISC_OBJ_NAME, OBJPROP_FILL, true);
            ObjectSetInteger(0, DISC_OBJ_NAME, OBJPROP_BACK, true);
            ObjectSetInteger(0, DISC_OBJ_NAME, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, DISC_OBJ_NAME, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, DISC_OBJ_NAME, OBJPROP_HIDDEN, true);
        }
        else
        {
            if (ObjectFind(0, DISC_OBJ_NAME) >= 0)
                ObjectDelete(0, DISC_OBJ_NAME);
        }

        // 6. Render/Update Equilibrium Line
        if (cfg.showZoneEquilibrium)
        {
            if (ObjectFind(0, EQ_OBJ_NAME) < 0)
            {
                if (!ObjectCreate(0, EQ_OBJ_NAME, OBJ_TREND, 0, startTime, eqPrice, endTime, eqPrice))
                {
                    Print("[ERROR] [CZoneRenderer] Failed to create Equilibrium object.");
                }
            }
            else
            {
                ObjectMove(0, EQ_OBJ_NAME, 0, startTime, eqPrice);
                ObjectMove(0, EQ_OBJ_NAME, 1, endTime, eqPrice);
            }

            ObjectSetInteger(0, EQ_OBJ_NAME, OBJPROP_COLOR, m_style.colorZoneEquilibrium);
            ObjectSetInteger(0, EQ_OBJ_NAME, OBJPROP_STYLE, m_style.styleZoneEq);
            ObjectSetInteger(0, EQ_OBJ_NAME, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, EQ_OBJ_NAME, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(0, EQ_OBJ_NAME, OBJPROP_BACK, true);
            ObjectSetInteger(0, EQ_OBJ_NAME, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, EQ_OBJ_NAME, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, EQ_OBJ_NAME, OBJPROP_HIDDEN, true);
        }
        else
        {
            if (ObjectFind(0, EQ_OBJ_NAME) >= 0)
                ObjectDelete(0, EQ_OBJ_NAME);
        }
    }
};

// Initialize static members
const string CZoneRenderer::PREM_OBJ_NAME = "MNS_Zone_Premium";
const string CZoneRenderer::DISC_OBJ_NAME = "MNS_Zone_Discount";
const string CZoneRenderer::EQ_OBJ_NAME   = "MNS_Zone_Equilibrium";

#endif // __MNS_ZONE_RENDERER_MQH__
