# Module Specification — INF-002: Utility Library
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Purpose

The Utility Library (`MNSUtils.mqh`) provides standard array processing, timezone alignments, and mathematical calculations required by various analysis modules.

---

## 2. Responsibilities

- **Array Utilities**: High-performance sorting, cloning, binary search, and safe element deletion on price/time/index arrays.
- **Timezone Helper**: Determine market session boundaries and convert broker time to GMT or EST.
- **Math Utilities**: Standard rounding to point sizes, pip conversions, and floating-point comparison overrides (within epsilon limits).

---

## 3. Public API

```cpp
class CMNSUtils
{
public:
    // --- Array Operations ---
    /// @brief Clones a double array cleanly to avoid reference copying.
    static bool ArrayCloneDouble(const double &src[], double &dst[]);
    
    /// @brief Safely removes an element from a dynamic array and shifts remaining items.
    static bool ArrayDeleteIndex(double &array[], int index);

    // --- Timezone & Session Calculations ---
    /// @brief Checks if a given time falls within a specific trading session.
    static bool IsInSession(datetime time, int sessionStartHour, int sessionEndHour);
    
    /// @brief Converts Broker Time to GMT based on the input timezone shift offset.
    static datetime BrokerTimeToGMT(datetime brokerTime, int brokerGmtOffset);

    // --- Math Helpers ---
    /// @brief Floating-point equality comparison within an epsilon boundary.
    static bool IsEqual(double a, double b, double epsilon = 0.00001);
    
    /// @brief Rounds a raw price value to the nearest chart symbol point size.
    static double RoundToPoints(double price, double pointSize);
};
```

---

## 4. Internal Architecture & Dependencies

- **File**: `Include/MNS/MNSUtils.mqh`
- **Dependencies**: `MNSCore.mqh`
- **Design Rule**: All methods must remain `static` and pure (no state variables) to enable safe utilization in parallel execution contexts.

---

## 5. Testing & Acceptance Criteria

- **Test Cases**:
  1. Confirm `IsEqual` returns true for values within `epsilon` range and false otherwise.
  2. Verify that deleting an array index shifts all subsequent elements to the left by exactly one index.
  3. Validate that `RoundToPoints(1.204567, 0.0001)` rounds correctly to `1.2046`.
- **Acceptance Criteria**:
  - standalone header compiles with 0 errors.
  - Zero dynamic allocations inside mathematical methods.
