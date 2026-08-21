//+------------------------------------------------------------------+
//|                                                    MNSConfig.mqh |
//|                              MNS Trading Engine — Module INF-004 |
//|                                                                  |
//| Purpose:                                                         |
//|   Manages configuration settings, reads parameters from files,    |
//|   and enforces validation bounds on live variables.              |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Define SEngineConfig settings data structure.                |
//|   - Manage active configuration static state.                    |
//|   - Set default strategy settings.                               |
//|   - Validate and update settings parameters dynamically.          |
//|   - Parse settings profiles from local sandbox text files.        |
//|                                                                  |
//| Dependencies:                                                    |
//|   - MNSCore.mqh                                                  |
//|   - MNSUtils.mqh                                                 |
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading logic.                                          |
//|   - Pure data layer — no visual settings panels or indicators GUI.|
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_CONFIG_MQH__
#define __MNS_CONFIG_MQH__

#include "MNSCore.mqh"
#include "MNSUtils.mqh"

//+------------------------------------------------------------------+
//| SEngineConfig Structure                                          |
//+------------------------------------------------------------------+
struct SEngineConfig
{
    int    externalDepth;
    int    internalDepth;
    double atrTolerance;
    double minBreakDistance;
    double confidenceThreshold;
    double displacementMinAtrMultiple;
    double displacementMinBodyRatio;
    double displacementMinCloseStrength;
    int    atrPeriod;
    bool   logEnable;
    int    logLevel;

    //--- Stage 6 Analytical Additions (M13-ISSUE-002, M13-ISSUE-004)
    int    gmtOffset;                 // GMT Offset in hours
    double maxSpreadPoints;           // Max spread filter
    double desiredRiskPercent;        // Desired risk percent per trade

    //--- Stage 6 Visual Capping Additions
    int    maxRenderedSwings;         // Max swing objects to render
    int    maxRenderedBreaks;         // Max BOS/CHoCH lines to render
    int    maxRenderedPools;          // Max liquidity pool lines to render
    int    maxRenderedPOIs;           // Max POI rectangles to render

    //--- Stage 6 Dashboard Layout Additions
    bool   showDashboard;             // Enable dashboard rendering
    int    dashboardX;                // X-coordinate dashboard pixel offset
    int    dashboardY;                // Y-coordinate dashboard pixel offset
    int    dashboardWidth;            // Panel width in pixels
};

//+------------------------------------------------------------------+
//| CMNSConfig Class                                                 |
//+------------------------------------------------------------------+
class CMNSConfig
{
private:
    static SEngineConfig s_config;

public:
    /// @brief Resets configuration variables to strategy defaults.
    static void SetDefaults()
    {
        s_config.externalDepth        = 15;
        s_config.internalDepth        = 5;
        s_config.atrTolerance                  = 0.0010;
        s_config.minBreakDistance              = 0.0000;
        s_config.confidenceThreshold           = 94.0;
        s_config.displacementMinAtrMultiple    = 1.20;
        s_config.displacementMinBodyRatio      = 0.65;
        s_config.displacementMinCloseStrength  = 0.75;
        s_config.atrPeriod                     = 14;
        s_config.logEnable                     = true;
        s_config.logLevel                      = 1; // MNS_LOG_INFO

        //--- Stage 6 defaults
        s_config.gmtOffset            = 0;
        s_config.maxSpreadPoints      = 50.0;
        s_config.desiredRiskPercent   = 1.0;
        s_config.maxRenderedSwings    = 50;
        s_config.maxRenderedBreaks    = 20;
        s_config.maxRenderedPools     = 20;
        s_config.maxRenderedPOIs      = 20;
        s_config.showDashboard        = true;
        s_config.dashboardX           = 20;
        s_config.dashboardY           = 20;
        s_config.dashboardWidth       = 250;
    }

    /// @brief Returns a copy of the active engine configuration.
    /// @return Active SEngineConfig struct.
    static SEngineConfig GetActive()
    {
        return s_config;
    }

    /// @brief Validates boundaries and updates configuration variables.
    /// @param name Key name of the configuration variable.
    /// @param value The value to apply.
    /// @return True if updated successfully, false on invalid key or out-of-bounds value.
    static bool UpdateParameter(string name, double value)
    {
        if (name == "externalDepth")
        {
            int val = (int)value;
            MNS_Assert(val >= 1, "UpdateParameter: externalDepth must be >= 1");
            MNS_Assert(val >= s_config.internalDepth, "UpdateParameter: externalDepth must be >= internalDepth");
            
            if (val < 1 || val < s_config.internalDepth)
                return false;
                
            s_config.externalDepth = val;
            return true;
        }
        else if (name == "internalDepth")
        {
            int val = (int)value;
            MNS_Assert(val >= 1, "UpdateParameter: internalDepth must be >= 1");
            MNS_Assert(val <= s_config.externalDepth, "UpdateParameter: internalDepth must be <= externalDepth");
            
            if (val < 1 || val > s_config.externalDepth)
                return false;
                
            s_config.internalDepth = val;
            return true;
        }
        else if (name == "atrTolerance")
        {
            MNS_Assert(value >= 0.0, "UpdateParameter: atrTolerance cannot be negative");
            if (value < 0.0)
                return false;
                
            // Direct usage of CMNSUtils to prevent compiler unused warning
            if (!CMNSUtils::IsEqual(s_config.atrTolerance, value))
            {
                s_config.atrTolerance = value;
            }
            return true;
        }
        else if (name == "minBreakDistance")
        {
            MNS_Assert(value >= 0.0, "UpdateParameter: minBreakDistance cannot be negative");
            if (value < 0.0)
                return false;
                
            if (!CMNSUtils::IsEqual(s_config.minBreakDistance, value))
            {
                s_config.minBreakDistance = value;
            }
            return true;
        }
        else if (name == "confidenceThreshold")
        {
            MNS_Assert(value >= 0.0 && value <= 100.0, "UpdateParameter: confidenceThreshold must be [0..100]");
            if (value < 0.0 || value > 100.0)
                return false;
                
            if (!CMNSUtils::IsEqual(s_config.confidenceThreshold, value))
            {
                s_config.confidenceThreshold = value;
            }
            return true;
        }
        else if (name == "displacementMinAtrMultiple")
        {
            MNS_Assert(value >= 0.0, "UpdateParameter: displacementMinAtrMultiple cannot be negative");
            if (value < 0.0)
                return false;
            s_config.displacementMinAtrMultiple = value;
            return true;
        }
        else if (name == "displacementMinBodyRatio")
        {
            MNS_Assert(value >= 0.0 && value <= 1.0, "UpdateParameter: displacementMinBodyRatio must be between 0.0 and 1.0");
            if (value < 0.0 || value > 1.0)
                return false;
            s_config.displacementMinBodyRatio = value;
            return true;
        }
        else if (name == "displacementMinCloseStrength")
        {
            MNS_Assert(value >= 0.0 && value <= 1.0, "UpdateParameter: displacementMinCloseStrength must be between 0.0 and 1.0");
            if (value < 0.0 || value > 1.0)
                return false;
            s_config.displacementMinCloseStrength = value;
            return true;
        }
        else if (name == "atrPeriod")
        {
            int val = (int)value;
            MNS_Assert(val >= 1, "UpdateParameter: atrPeriod must be >= 1");
            if (val < 1)
                return false;
            s_config.atrPeriod = val;
            return true;
        }
        else if (name == "logEnable")
        {
            s_config.logEnable = (value != 0.0);
            return true;
        }
        else if (name == "logLevel")
        {
            int val = (int)value;
            MNS_Assert(val >= 0 && val <= 4, "UpdateParameter: logLevel must be between 0 and 4");
            if (val < 0 || val > 4)
                return false;
                
            s_config.logLevel = val;
            return true;
        }
        else if (name == "gmtOffset")
        {
            int val = (int)value;
            MNS_Assert(val >= -12 && val <= 12, "UpdateParameter: gmtOffset must be [-12..12]");
            if (val < -12 || val > 12) return false;
            s_config.gmtOffset = val;
            return true;
        }
        else if (name == "maxSpreadPoints")
        {
            MNS_Assert(value >= 0.0 && value <= 500.0, "UpdateParameter: maxSpreadPoints must be [0.0..500.0]");
            if (value < 0.0 || value > 500.0) return false;
            s_config.maxSpreadPoints = value;
            return true;
        }
        else if (name == "desiredRiskPercent")
        {
            MNS_Assert(value >= 0.0 && value <= 10.0, "UpdateParameter: desiredRiskPercent must be [0.0..10.0]");
            if (value < 0.0 || value > 10.0) return false;
            s_config.desiredRiskPercent = value;
            return true;
        }
        else if (name == "maxRenderedSwings")
        {
            int val = (int)value;
            MNS_Assert(val >= 10 && val <= 500, "UpdateParameter: maxRenderedSwings must be [10..500]");
            if (val < 10 || val > 500) return false;
            s_config.maxRenderedSwings = val;
            return true;
        }
        else if (name == "maxRenderedBreaks")
        {
            int val = (int)value;
            MNS_Assert(val >= 5 && val <= 200, "UpdateParameter: maxRenderedBreaks must be [5..200]");
            if (val < 5 || val > 200) return false;
            s_config.maxRenderedBreaks = val;
            return true;
        }
        else if (name == "maxRenderedPools")
        {
            int val = (int)value;
            MNS_Assert(val >= 5 && val <= 200, "UpdateParameter: maxRenderedPools must be [5..200]");
            if (val < 5 || val > 200) return false;
            s_config.maxRenderedPools = val;
            return true;
        }
        else if (name == "maxRenderedPOIs")
        {
            int val = (int)value;
            MNS_Assert(val >= 5 && val <= 200, "UpdateParameter: maxRenderedPOIs must be [5..200]");
            if (val < 5 || val > 200) return false;
            s_config.maxRenderedPOIs = val;
            return true;
        }
        else if (name == "showDashboard")
        {
            s_config.showDashboard = (value != 0.0);
            return true;
        }
        else if (name == "dashboardX")
        {
            int val = (int)value;
            MNS_Assert(val >= 0 && val <= 2000, "UpdateParameter: dashboardX must be [0..2000]");
            if (val < 0 || val > 2000) return false;
            s_config.dashboardX = val;
            return true;
        }
        else if (name == "dashboardY")
        {
            int val = (int)value;
            MNS_Assert(val >= 0 && val <= 2000, "UpdateParameter: dashboardY must be [0..2000]");
            if (val < 0 || val > 2000) return false;
            s_config.dashboardY = val;
            return true;
        }
        else if (name == "dashboardWidth")
        {
            int val = (int)value;
            MNS_Assert(val >= 150 && val <= 500, "UpdateParameter: dashboardWidth must be [150..500]");
            if (val < 150 || val > 500) return false;
            s_config.dashboardWidth = val;
            return true;
        }
        
        return false;
    }

    /// @brief Loads settings from a standard INI formatted key-value file.
    /// @param fileName Path relative to the local MT5 MQL5\Files sandbox folder.
    /// @return True if file opened and parsed successfully, false on failures or bounds rejections.
    static bool LoadFromFile(string fileName)
    {
        int handle = FileOpen(fileName, FILE_READ | FILE_TXT | FILE_ANSI);
        if (handle == INVALID_HANDLE)
            return false;
            
        bool success = true;
        while (!FileIsEnding(handle))
        {
            string line = FileReadString(handle);
            
            StringTrimLeft(line);
            StringTrimRight(line);
            
            // Skip comments and empty lines
            if (line == "" || StringSubstr(line, 0, 1) == ";" || StringSubstr(line, 0, 1) == "#")
                continue;
                
            int eqPos = StringFind(line, "=");
            if (eqPos <= 0)
                continue;
                
            string key = StringSubstr(line, 0, eqPos);
            string valStr = StringSubstr(line, eqPos + 1);
            
            StringTrimLeft(key);
            StringTrimRight(key);
            StringTrimLeft(valStr);
            StringTrimRight(valStr);
            
            double val = StringToDouble(valStr);
            if (!UpdateParameter(key, val))
            {
                success = false;
            }
        }
        
        FileClose(handle);
        return success;
    }
};

//+------------------------------------------------------------------+
//| Static Member Variable Initialization                            |
//+------------------------------------------------------------------+
SEngineConfig CMNSConfig::s_config;

#endif // __MNS_CONFIG_MQH__
