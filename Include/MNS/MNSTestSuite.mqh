//+------------------------------------------------------------------+
//|                                                 MNSTestSuite.mqh |
//|                              MNS Trading Engine — Module INF-006 |
//|                                                                  |
//| Purpose:                                                         |
//|   Provides standardized verification assertions and test results  |
//|   aggregation/reporting utilities for the engine's testing suite.|
//|                                                                  |
//| Responsibilities:                                                |
//|   - Define assertions (AssertTrue, AssertEqualInt, AssertEqualDouble).|
//|   - Track Passed / Failed assertion counts.                      |
//|   - Format assertion output messages and reports.                |
//|                                                                  |
//| Dependencies:                                                    |
//|   - MNSCore.mqh                                                  |
//|   - MNSUtils.mqh                                                 |
//|                                                                  |
//| Rules:                                                           |
//|   - Zero trading logic.                                          |
//|   - No visual rendering or graphical components.                 |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_TEST_SUITE_MQH__
#define __MNS_TEST_SUITE_MQH__

#include "MNSUtils.mqh"

//+------------------------------------------------------------------+
//| CMNSTestSuite Class                                              |
//+------------------------------------------------------------------+
class CMNSTestSuite
{
private:
    static int s_testsPassed;
    static int s_testsFailed;

public:
    /// @brief Resets test run counters.
    static void Reset()
    {
        s_testsPassed = 0;
        s_testsFailed = 0;
    }

    /// @brief Verifies that a boolean condition is true.
    /// @param condition The condition to test.
    /// @param testName Descriptive name of the test.
    static void AssertTrue(bool condition, string testName)
    {
        if (condition)
        {
            Print("  [PASS] ", testName);
            s_testsPassed++;
        }
        else
        {
            Print("  [FAIL] ", testName, " - Expected: true, Actual: false");
            s_testsFailed++;
        }
    }

    /// @brief Verifies that two integers are equal.
    /// @param expected The expected value.
    /// @param actual The actual value.
    /// @param testName Descriptive name of the test.
    static void AssertEqualInt(int expected, int actual, string testName)
    {
        if (expected == actual)
        {
            Print("  [PASS] ", testName);
            s_testsPassed++;
        }
        else
        {
            Print("  [FAIL] ", testName, " - Expected: ", expected, ", Actual: ", actual);
            s_testsFailed++;
        }
    }

    /// @brief Verifies that two doubles are equal within epsilon range.
    /// @param expected The expected value.
    /// @param actual The actual value.
    /// @param testName Descriptive name of the test.
    /// @param epsilon Double precision tolerance limit.
    static void AssertEqualDouble(double expected, double actual, string testName, double epsilon = 0.00001)
    {
        if (CMNSUtils::IsEqual(expected, actual, epsilon))
        {
            Print("  [PASS] ", testName);
            s_testsPassed++;
        }
        else
        {
            Print("  [FAIL] ", testName, " - Expected: ", DoubleToString(expected, 8), ", Actual: ", DoubleToString(actual, 8));
            s_testsFailed++;
        }
    }

    /// @brief Prints test run statistics to log targets.
    /// @param moduleName Name of the verified module.
    static void ReportResults(string moduleName)
    {
        Print("==============================================");
        Print("  MODULE: ", moduleName);
        Print("  Passed : ", s_testsPassed);
        Print("  Failed : ", s_testsFailed);
        Print("  Total  : ", s_testsPassed + s_testsFailed);
        if (s_testsFailed == 0)
        {
            Print("  Result : ALL TESTS PASSED");
        }
        else
        {
            Print("  Result : ", s_testsFailed, " TEST(S) FAILED");
        }
        Print("==============================================");
    }

    /// @brief Returns the total number of failures.
    /// @return Count of failed assertions.
    static int GetFailedCount()
    {
        return s_testsFailed;
    }
};

//+------------------------------------------------------------------+
//| Static Member Initializations                                    |
//+------------------------------------------------------------------+
int CMNSTestSuite::s_testsPassed = 0;
int CMNSTestSuite::s_testsFailed = 0;

#endif // __MNS_TEST_SUITE_MQH__
