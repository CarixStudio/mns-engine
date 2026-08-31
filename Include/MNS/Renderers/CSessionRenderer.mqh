//+------------------------------------------------------------------+
//|                                             CSessionRenderer.mqh |
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Visual controller for rendering vertical shaded trading session |
//|   background bands (Asia, London, NY, Overlap) on the chart.      |
//|   Enforces session hour boundaries, handles gmt offsets, and     |
//|   applies capping limits to historical objects.                   |
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh                                                   |
//|   MNSStyle.mqh                                                   |
//|   MNSConfig.mqh                                                  |
//+------------------------------------------------------------------+
#ifndef __MNS_SESSION_RENDERER_MQH__
#define __MNS_SESSION_RENDERER_MQH__

#include "../MNSStyle.mqh"
#include "../MNSConfig.mqh"

enum ESessionType {
    SESSION_NONE,
    SESSION_ASIA,
    SESSION_LONDON,
    SESSION_OVERLAP,
    SESSION_NY
};

struct SSessionBlock {
    ESessionType type;
    datetime start;
    datetime end;
};

class CSessionRenderer
{
private:
    SIndicatorStyle m_style;          ///< Cached visual style configuration
    int             m_maxSessions;    ///< Capping limit for rendered session objects
    bool            m_isInitialized;  ///< Initialization guard flag

    // Helper to convert date to clean string representation
    string GetDateString(datetime t) const
    {
        string s = TimeToString(t, TIME_DATE);
        StringReplace(s, ".", "_");
        return s;
    }

    // Helper to get prefix string of session type
    string GetTypePrefix(ESessionType type) const
    {
        switch (type)
         {
            case SESSION_ASIA:    return "Asia";
            case SESSION_LONDON:  return "Lon";
            case SESSION_OVERLAP: return "Overlap";
            case SESSION_NY:      return "NY";
            default:              return "None";
        }
    }

    // Helper to get styling color of session type
    color GetSessionColor(ESessionType type) const
    {
        switch (type)
        {
            case SESSION_ASIA:    return m_style.colorSessionAsia;
            case SESSION_LONDON:  return m_style.colorSessionLondon;
            case SESSION_OVERLAP: return m_style.colorSessionOverlap;
            case SESSION_NY:      return m_style.colorSessionNY;
            default:              return clrBlack;
        }
    }

    // Helper to check the session type of a given time
    ESessionType GetSessionType(datetime barTime, int gmtOffset) const
    {
        datetime gmtTime = barTime - gmtOffset * 3600;
        MqlDateTime gStruct;
        TimeToStruct(gmtTime, gStruct);
        int hour = gStruct.hour;

        if (hour >= 0 && hour < 8)
            return SESSION_ASIA;
        if (hour >= 8 && hour < 13)
            return SESSION_LONDON;
        if (hour >= 13 && hour < 16)
            return SESSION_OVERLAP;
        if (hour >= 16 && hour < 21)
            return SESSION_NY;

        return SESSION_NONE; // Closed / Off-hours
    }

    // Helper: creates or updates a rectangle shading block
    void RenderSessionBlock(const SSessionBlock &block, string name)
    {
        if (ObjectFind(0, name) < 0)
        {
            if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, block.start, 0.0, block.end, 999999.0))
            {
                Print(StringFormat("[ERROR] [CSessionRenderer] Failed to create session block: %s. Error: %d", name, GetLastError()));
                return;
            }
        }
        else
        {
            ObjectMove(0, name, 0, block.start, 0.0);
            ObjectMove(0, name, 1, block.end, 999999.0);
        }

        ObjectSetInteger(0, name, OBJPROP_COLOR, GetSessionColor(block.type));
        ObjectSetInteger(0, name, OBJPROP_FILL, true);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    }

public:
    // Constructor
    CSessionRenderer() : m_maxSessions(15), m_isInitialized(false)
    {
        m_style.Reset();
    }

    // Destructor
    ~CSessionRenderer()
    {
        Reset();
    }

    /// @brief Initializes the Session Renderer.
    /// @param style Shared visual style configuration.
    /// @param maxSessions Max number of session blocks to keep rendered.
    /// @return True on success.
    bool Initialize(const SIndicatorStyle &style, int maxSessions)
    {
        m_style = style;
        m_maxSessions = (maxSessions > 0) ? maxSessions : 15;
        m_isInitialized = true;
        return true;
    }

    /// @brief Clears all session background rectangle objects from the chart.
    void Reset()
    {
        ObjectsDeleteAll(0, "MNS_Session_");
    }

    /// @brief Evaluates historical times, segments sessions, and renders vertical boxes.
    /// @param time Chart datetime array (series order).
    /// @param limitBars Total number of evaluable bars.
    void Draw(const datetime &time[], int limitBars)
    {
        if (!m_isInitialized || limitBars <= 0)
            return;

        SEngineConfig cfg = CMNSConfig::GetActive();
        if (!cfg.showSessions)
        {
            Reset();
            return;
        }

        // Group bars into contiguous session blocks
        SSessionBlock blocks[];
        int blockCount = 0;

        ESessionType currentType = SESSION_NONE;
        datetime currentStart = 0;
        datetime currentEnd = 0;

        // Scan from oldest (limitBars-1) to newest (0)
        for (int i = limitBars - 1; i >= 0; i--)
        {
            ESessionType type = GetSessionType(time[i], cfg.gmtOffset);

            // Check if a transition is needed (different session or weekend gap)
            bool transition = false;
            if (type != currentType)
            {
                transition = true;
            }
            else if (currentType != SESSION_NONE && i < limitBars - 1)
            {
                // If weekend gap or large timezone jump occurs, split
                if (time[i] - time[i + 1] > PeriodSeconds() * 1.5)
                {
                    transition = true;
                }
            }

            if (transition)
            {
                // Finalize previous block
                if (currentType != SESSION_NONE && currentStart > 0)
                {
                    int size = ArraySize(blocks);
                    if (blockCount >= size)
                    {
                        ArrayResize(blocks, size + 128);
                    }
                    blocks[blockCount].type = currentType;
                    blocks[blockCount].start = currentStart;
                    blocks[blockCount].end = currentEnd;
                    blockCount++;
                }

                // Start new block
                currentType = type;
                currentStart = time[i];
                currentEnd = time[i] + PeriodSeconds();
            }
            else
            {
                // Extend current block
                if (currentType != SESSION_NONE)
                {
                    currentEnd = time[i] + PeriodSeconds();
                }
            }
        }

        // Finalize the last block
        if (currentType != SESSION_NONE && currentStart > 0)
        {
            int size = ArraySize(blocks);
            if (blockCount >= size)
            {
                ArrayResize(blocks, size + 128);
            }
            blocks[blockCount].type = currentType;
            blocks[blockCount].start = currentStart;
            blocks[blockCount].end = currentEnd;
            blockCount++;
        }

        // Calculate index to start drawing (capping limit)
        int startIdx = blockCount - m_maxSessions;
        if (startIdx < 0)
            startIdx = 0;

        // Draw new blocks and clean up old ones
        for (int i = 0; i < blockCount; i++)
        {
            string name = "MNS_Session_" + GetTypePrefix(blocks[i].type) + "_" + GetDateString(blocks[i].start);
            if (i < startIdx)
            {
                if (ObjectFind(0, name) >= 0)
                    ObjectDelete(0, name);
            }
            else
            {
                RenderSessionBlock(blocks[i], name);
            }
        }
    }
};

#endif // __MNS_SESSION_RENDERER_MQH__
