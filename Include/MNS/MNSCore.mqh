//+------------------------------------------------------------------+
//|                                                      MNSCore.mqh |
//|                              MNS Trading Engine — Module INF-000 |
//|                                                                  |
//| Purpose:                                                         |
//|   Provides version metadata, error/success codes, global         |
//|   constants, and developer assertion checks.                     |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Define MNS_RESULT type and standard return codes.            |
//|   - Standardize global sentinel constants.                        |
//|   - Expose compile-time assertion macro (MNS_Assert).            |
//|                                                                  |
//| Dependencies:                                                    |
//|   None. This is the absolute root reference header of the engine.|
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading logic.                                          |
//|   - No hot-path allocations.                                     |
//|   - Clean API, macro-based stripping for assertions.             |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_CORE_MQH__
#define __MNS_CORE_MQH__

//+------------------------------------------------------------------+
//| Core Metadata & Versioning                                       |
//+------------------------------------------------------------------+
#define MNS_INFRASTRUCTURE_VERSION "1.0.0"
#define MNS_MODULE_INF_000         "INF-000"

//+------------------------------------------------------------------+
//| Shared Error / Success Codes (MNS_RESULT)                        |
//+------------------------------------------------------------------+
#define MNS_RESULT int

/// @brief Success code indicating normal operation.
#define MNS_S_OK             ((MNS_RESULT)0x00000000)

/// @brief Generic error code indicating execution failure.
#define MNS_E_FAIL           ((MNS_RESULT)0x80004005)

/// @brief Error code indicating one or more invalid arguments.
#define MNS_E_INVALIDARG     ((MNS_RESULT)0x80070057)

/// @brief Error code indicating memory allocation or array resize failure.
#define MNS_E_OUTOFMEMORY    ((MNS_RESULT)0x8007000E)

/// @brief Error code indicating that the called method is not implemented.
#define MNS_E_NOTIMPL        ((MNS_RESULT)0x80004001)

//+------------------------------------------------------------------+
//| Global Constants                                                 |
//+------------------------------------------------------------------+

/// @brief Sentinel value for an invalid price. Matches DBL_MAX.
#define MNS_INVALID_PRICE    1.7976931348623157e+308

/// @brief Sentinel value for an invalid index or empty index indicator.
#define MNS_INVALID_INDEX    -1

/// @brief Sentinel value for an uninitialized datetime.
#define MNS_INVALID_TIME     0

//+------------------------------------------------------------------+
//| Assertion Macro                                                  |
//+------------------------------------------------------------------+
#ifdef MNS_ASSERT_ENABLE
    /// @brief Compile-time toggleable assertion check.
    /// Halts execution and prints alert if the condition is false.
    #define MNS_Assert(expression, message) \
        if (!(expression)) { \
            Alert("MNS ASSERTION FAILED: ", message); \
            ExpertRemove(); \
        }
#else
    /// @brief Compile-time toggleable assertion check (stripped).
    #define MNS_Assert(expression, message)
#endif

#endif // __MNS_CORE_MQH__
