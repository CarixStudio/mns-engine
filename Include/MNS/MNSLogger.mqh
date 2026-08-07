//+------------------------------------------------------------------+
//|                                                     MNSLogger.mqh |
//|                              MNS Trading Engine — Module INF-001 |
//|                                                                  |
//| Purpose:                                                         |
//|   Provides uniform diagnostic logging capabilities with target    |
//|   routing, log level filtering, and compile-time macro stripping. |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Define diagnostic log levels (DEBUG, INFO, WARN, ERROR, FATAL)|
//|   - Route messages to terminal Print(), Alert(), or sandbox files.|
//|   - Enable zero runtime overhead in production via preprocessor.  |
//|                                                                  |
//| Dependencies:                                                    |
//|   - MNSCore.mqh                                                  |
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading logic.                                          |
//|   - No hot-path allocations.                                     |
//|   - Safe resource cleanup in Close().                            |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_LOGGER_MQH__
#define __MNS_LOGGER_MQH__

#include "MNSCore.mqh"

//+------------------------------------------------------------------+
//| Log Level Enumeration                                            |
//+------------------------------------------------------------------+
enum ENUM_MNS_LOG_LEVEL
{
    MNS_LOG_DEBUG = 0,
    MNS_LOG_INFO,
    MNS_LOG_WARN,
    MNS_LOG_ERROR,
    MNS_LOG_FATAL
};

//+------------------------------------------------------------------+
//| CMNSLogger Class                                                 |
//+------------------------------------------------------------------+
class CMNSLogger
{
private:
    static ENUM_MNS_LOG_LEVEL s_activeLevel;
    static string             s_logFileName;
    static int                s_fileHandle;

public:
    /// @brief Configures active log levels and optional file logging targets.
    /// @param level The minimum log level required to output a message.
    /// @param file The name of the file to log to (sandboxed in MQL5/Files/MNS_Logs/).
    static void Initialize(ENUM_MNS_LOG_LEVEL level, string file = "")
    {
        s_activeLevel = level;
        
        if (file != "")
        {
            Close(); // Close existing file handle if open
            
            s_logFileName = file;
            // FileOpen in MT5 automatically creates the parent directories in the MQL5/Files sandbox.
            s_fileHandle = FileOpen("MNS_Logs\\" + file, FILE_WRITE | FILE_SHARE_READ | FILE_TXT | FILE_ANSI);
            if (s_fileHandle == INVALID_HANDLE)
            {
                Print("[CMNSLogger] [ERROR] Failed to open log file: MNS_Logs\\", file);
            }
        }
    }
    
    /// @brief Closes any open file handles and resets states.
    static void Close()
    {
        if (s_fileHandle != INVALID_HANDLE)
        {
            FileClose(s_fileHandle);
            s_fileHandle = INVALID_HANDLE;
        }
        s_logFileName = "";
    }

    /// @brief Outputs a message at the specified log level.
    /// @param level Message log level.
    /// @param source Message source identifier (e.g. Class/Function name).
    /// @param message The diagnostic message.
    static void Log(ENUM_MNS_LOG_LEVEL level, string source, string message)
    {
        MNS_Assert(level >= MNS_LOG_DEBUG && level <= MNS_LOG_FATAL, "Invalid log level");

        if (level < s_activeLevel)
            return;
            
        string levelStr = "";
        switch (level)
        {
            case MNS_LOG_DEBUG: levelStr = "DEBUG"; break;
            case MNS_LOG_INFO:  levelStr = "INFO";  break;
            case MNS_LOG_WARN:  levelStr = "WARN";  break;
            case MNS_LOG_ERROR: levelStr = "ERROR"; break;
            case MNS_LOG_FATAL: levelStr = "FATAL"; break;
            default:            levelStr = "UNKNOWN"; break;
        }
        
        // Construct log line: [YYYY.MM.DD HH:MM:SS] [LEVEL] [SOURCE] message
        string timeStr = TimeToString(TimeLocal(), TIME_DATE | TIME_SECONDS);
        string logLine = StringFormat("[%s] [%s] [%s] %s", timeStr, levelStr, source, message);
        
        // Target 1: MT5 Experts log
        Print(logLine);
        
        // Target 2: Sandbox file on disk
        if (s_fileHandle != INVALID_HANDLE)
        {
            FileWrite(s_fileHandle, logLine);
        }
        
        // Target 3: Chart visual Alert for FATAL errors
        if (level == MNS_LOG_FATAL)
        {
            Alert(logLine);
        }
    }
};

//+------------------------------------------------------------------+
//| Static Member Variable Initialization                            |
//+------------------------------------------------------------------+
ENUM_MNS_LOG_LEVEL CMNSLogger::s_activeLevel = MNS_LOG_INFO;
string             CMNSLogger::s_logFileName = "";
int                CMNSLogger::s_fileHandle  = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Preprocessor Macro Wrapper API (Compile-time Optimization)       |
//+------------------------------------------------------------------+
#ifdef MNS_LOG_ENABLE
    #define MNS_Log(level, src, msg) CMNSLogger::Log(level, src, msg)
#else
    #define MNS_Log(level, src, msg)
#endif

#endif // __MNS_LOGGER_MQH__
