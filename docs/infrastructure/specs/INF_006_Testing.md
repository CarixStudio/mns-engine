# Module Specification — INF-006: Testing Framework
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Purpose

The Testing Framework (`MNSTestSuite.mqh`) provides standardized verification assertions and mock structures. It enables writing unit tests that execute independently of live broker connections and real-time market data.

---

## 2. Responsibilities

- **Test Assertions**: Expose robust comparison methods (`AssertTrue`, `AssertEqualDouble`, `AssertEqualInt`) that print diagnostic details on failure.
- **Mock Data Engine**: Provide static mock buffers for generating synthetic candle charts, helping decouple core engines from the terminal's live charts during testing.
- **Result Aggregation**: Track and output cumulative statistics (Passed, Failed, Total Runs).

---

## 3. Public API

```cpp
class CMNSTestSuite
{
private:
    static int s_testsPassed;
    static int s_testsFailed;

public:
    /// @brief Resets test run counters.
    static void Reset();

    /// @brief Verifies that a boolean condition is true.
    static void AssertTrue(bool condition, string testName);

    /// @brief Verifies that two integers are equal.
    static void AssertEqualInt(int expected, int actual, string testName);

    /// @brief Verifies that two doubles are equal within epsilon range.
    static void AssertEqualDouble(double expected, double actual, string testName, double epsilon = 0.00001);

    /// @brief Prints test run statistics to log targets.
    static void ReportResults(string moduleName);
    
    /// @brief Returns the total number of failures.
    static int GetFailedCount() { return s_testsFailed; }
};
```

---

## 4. Internal Architecture & Dependencies

- **File**: `Include/MNS/MNSTestSuite.mqh`
- **Dependencies**: `MNSCore.mqh`, `MNSUtils.mqh`
- **Diagnostic Output**: When an assertion fails, the output must print: `[FAIL] <testName> - Expected: <exp>, Actual: <act>`.

---

## 5. Testing & Acceptance Criteria

- **Test Cases**:
  1. Confirm that failing assertions increment the failed counter.
  2. Confirm that `AssertEqualDouble` returns success when two values differ by less than `0.00001`.
  3. Verify that test statistics are logged to the terminal correctly.
- **Acceptance Criteria**:
  - Standalone header compiles cleanly.
  - Compilation outputs no unused variable warnings.
