//+------------------------------------------------------------------+
//|                                                MNSSerializer.mqh |
//|                              MNS Trading Engine — Module INF-005 |
//|                                                                  |
//| Purpose:                                                         |
//|   Defines the standardized interface contract for serialization   |
//|   and deserialization of engine states across restarts.          |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Define the IMNSSerializable interface.                       |
//|                                                                  |
//| Dependencies:                                                    |
//|   - MNSCore.mqh                                                  |
//|                                                                  |
//| Rules:                                                           |
//|   - Pure abstract contract — no implementation logic.            |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_SERIALIZER_MQH__
#define __MNS_SERIALIZER_MQH__

#include "MNSCore.mqh"

//+------------------------------------------------------------------+
//| IMNSSerializable Interface                                       |
//+------------------------------------------------------------------+
class IMNSSerializable
{
public:
    /// @brief Virtual destructor to ensure clean cleanup of derived types.
    virtual ~IMNSSerializable() {}

    /// @brief Serializes the object state into a file handle.
    /// @param fileHandle Open MQL5 file handle with write permissions.
    /// @return MNS_RESULT status code (MNS_S_OK on success).
    virtual MNS_RESULT Serialize(int fileHandle) = 0;

    /// @brief Deserializes the object state from a file handle.
    /// @param fileHandle Open MQL5 file handle with read permissions.
    /// @return MNS_RESULT status code (MNS_S_OK on success).
    virtual MNS_RESULT Deserialize(int fileHandle) = 0;
};

#endif // __MNS_SERIALIZER_MQH__
