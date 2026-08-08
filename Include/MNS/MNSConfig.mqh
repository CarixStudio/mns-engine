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
    bool   logEnable;
    int    logLevel;
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
        s_config.atrTolerance         = 0.0010;
        s_config.minBreakDistance     = 0.0000;
        s_config.confidenceThreshold  = 94.0;
        s_config.logEnable            = true;
        s_config.logLevel             = 1; // MNS_LOG_INFO
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
