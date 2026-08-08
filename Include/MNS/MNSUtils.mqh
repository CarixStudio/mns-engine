//+------------------------------------------------------------------+
//|                                                     MNSUtils.mqh |
//|                              MNS Trading Engine — Module INF-002 |
//|                                                                  |
//| Purpose:                                                         |
//|   Provides high-performance array manipulation, timezone, and   |
//|   mathematical calculation utilities.                            |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Clean double array cloning with dynamic/static checks.       |
//|   - Safe index deletion and shifting for dynamic arrays.         |
//|   - Trading session hour containment checking.                   |
//|   - Broker to GMT timezone conversion.                           |
//|   - Floating-point equality comparison within epsilon.           |
//|   - Price rounding to symbol point sizes.                        |
//|                                                                  |
//| Dependencies:                                                    |
//|   - MNSCore.mqh                                                  |
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading logic.                                          |
//|   - No hot-path allocations.                                     |
//|   - All methods must remain static and pure.                     |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_UTILS_MQH__
#define __MNS_UTILS_MQH__

#include "MNSCore.mqh"

//+------------------------------------------------------------------+
//| CMNSUtils Class                                                  |
//+------------------------------------------------------------------+
class CMNSUtils
{
public:
    // --- Array Operations ---
    
    /// @brief Clones a double array cleanly to avoid reference copying.
    /// @param src Source double array.
    /// @param dst Destination double array.
    /// @return True if cloning succeeded, false otherwise.
    static bool ArrayCloneDouble(const double &src[], double &dst[])
    {
        int size = ArraySize(src);
        MNS_Assert(size >= 0, "ArrayCloneDouble: source array size cannot be negative");
        if (size < 0)
            return false;
            
        if (ArrayIsDynamic(dst))
        {
            if (ArrayResize(dst, size) < 0)
                return false;
        }
        else
        {
            MNS_Assert(ArraySize(dst) >= size, "ArrayCloneDouble: destination static array is too small");
            if (ArraySize(dst) < size)
                return false;
        }
        
        int copied = ArrayCopy(dst, src, 0, 0, WHOLE_ARRAY);
        return (copied == size);
    }
    
    /// @brief Safely removes an element from a dynamic array and shifts remaining items.
    /// @param array Target dynamic double array.
    /// @param index Zero-based index of the element to delete.
    /// @return True if deletion succeeded, false otherwise.
    static bool ArrayDeleteIndex(double &array[], int index)
    {
        MNS_Assert(ArrayIsDynamic(array), "ArrayDeleteIndex: target array must be dynamic");
        if (!ArrayIsDynamic(array))
            return false;
            
        int size = ArraySize(array);
        MNS_Assert(index >= 0 && index < size, "ArrayDeleteIndex: index out of bounds");
        if (index < 0 || index >= size)
            return false;
            
        for (int i = index; i < size - 1; i++)
        {
            array[i] = array[i + 1];
        }
        
        if (ArrayResize(array, size - 1) < 0)
            return false;
            
        return true;
    }

    // --- Timezone & Session Calculations ---
    
    /// @brief Checks if a given time falls within a specific trading session.
    /// @param time The datetime to evaluate.
    /// @param sessionStartHour The hour the session starts (0-23).
    /// @param sessionEndHour The hour the session ends (0-23).
    /// @return True if time is in session, false otherwise.
    static bool IsInSession(datetime time, int sessionStartHour, int sessionEndHour)
    {
        MNS_Assert(sessionStartHour >= 0 && sessionStartHour <= 23, "IsInSession: invalid sessionStartHour");
        MNS_Assert(sessionEndHour >= 0 && sessionEndHour <= 23, "IsInSession: invalid sessionEndHour");
        
        MqlDateTime dt;
        if (!TimeToStruct(time, dt))
            return false;
            
        int hour = dt.hour;
        
        if (sessionStartHour < sessionEndHour)
        {
            return (hour >= sessionStartHour && hour < sessionEndHour);
        }
        else if (sessionStartHour > sessionEndHour) // Spans midnight
        {
            return (hour >= sessionStartHour || hour < sessionEndHour);
        }
        else // sessionStartHour == sessionEndHour
        {
            return (hour == sessionStartHour);
        }
    }
    
    /// @brief Converts Broker Time to GMT based on the input timezone shift offset.
    /// @param brokerTime The broker server datetime.
    /// @param brokerGmtOffset The GMT offset in hours (e.g. 2 for GMT+2, -5 for EST).
    /// @return The converted GMT datetime.
    static datetime BrokerTimeToGMT(datetime brokerTime, int brokerGmtOffset)
    {
        return brokerTime - (datetime)(brokerGmtOffset * 3600);
    }

    // --- Math Helpers ---
    
    /// @brief Floating-point equality comparison within an epsilon boundary.
    /// @param a First value.
    /// @param b Second value.
    /// @param epsilon Comparison tolerance.
    /// @return True if the difference is within epsilon, false otherwise.
    static bool IsEqual(double a, double b, double epsilon = 0.00001)
    {
        return (MathAbs(a - b) <= epsilon);
    }
    
    /// @brief Rounds a raw price value to the nearest chart symbol point size.
    /// @param price The raw double price.
    /// @param pointSize The symbol's point size (e.g. 0.00001, 0.01).
    /// @return The normalized price.
    static double RoundToPoints(double price, double pointSize)
    {
        MNS_Assert(pointSize >= 0.0, "RoundToPoints: pointSize cannot be negative");
        if (pointSize <= 0.0)
            return price;
            
        int digits = (int)MathRound(-MathLog10(pointSize));
        if (digits < 0)
            digits = 0;
            
        return NormalizeDouble(MathRound(price / pointSize) * pointSize, digits);
    }
};

#endif // __MNS_UTILS_MQH__
