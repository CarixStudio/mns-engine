# Module Specification — INF-003: ATR Helper
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Purpose

The ATR Helper (`MNSVolatility.mqh`) calculates Average True Range (ATR) directly from price arrays. This decouples volatility calculation from MT5 native indicator handles, avoiding performance freezes, buffer initialization delays, and memory leaks.

---

## 2. Responsibilities

- **True Range Calculation**: Calculate the true range of individual bars using current high/low and previous close prices.
- **ATR Smoothing**: Apply Wilders smoothing algorithm to determine the averaged range over a configurable period (default: 14).
- **Direct Processing**: Process array buffers sequentially using only standard data inputs.

---

## 3. Public API

```cpp
class CMNSVolatility
{
public:
    /// @brief Calculates the Average True Range value for a specific bar index.
    /// @param high price array
    /// @param low price array
    /// @param close price array
    /// @param index the bar index to calculate for
    /// @param period the smoothing period (default 14)
    /// @param ratesTotal total elements in price arrays
    /// @return ATR value in points, or 0.0 on validation failure.
    static double CalculateATR(const double &high[],
                               const double &low[],
                               const double &close[],
                               int index,
                               int period,
                               int ratesTotal);
};
```

---

## 4. Internal Architecture & Dependencies

- **File**: `Include/MNS/MNSVolatility.mqh`
- **Dependencies**: `MNSCore.mqh`, `MNSUtils.mqh`
- **Algorithm**:
  1. True Range ($TR$) is the maximum of:
     - $High - Low$
     - $|High - Close_{prev}|$
     - $|Low - Close_{prev}|$
  2. For the initial bar, ATR is the simple moving average of True Ranges over the period.
  3. Subsequent bars use Wilder's smoothing:
     - $ATR_{cur} = \frac{ATR_{prev} \times (Period - 1) + TR_{cur}}{Period}$

---

## 5. Testing & Acceptance Criteria

- **Test Cases**:
  1. Pass price arrays where all candles have identical range ($High - Low = 10$ points) and verify ATR equals exactly $10.0$.
  2. Confirm calculation fails and returns `0.0` if `ratesTotal` is less than `period + 1`.
  3. Verify that index offsets do not read out of array boundaries.
- **Acceptance Criteria**:
  - standalone header compiles with 0 errors.
  - No MT5 indicator handles used.
