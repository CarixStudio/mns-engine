# Module 004 — CBreakDetector Algorithm
Version: 1.0
Status: Approved

---

## Inputs
- Confirmed Swing Highs and Lows (from `CSwingDetector`)
- Current Trend and State (from `CStructureEngine`)
- OHLC Arrays (series order: index 0 = newest)
- Current ATR

---

## Outputs
- Updated `SStructureBreak` arrays
- State indicators for downstream modules

---

## Processing Pipeline

1. **Verify Initialization**:
   - Return false if the detector is not initialized.
   - Return false if the number of bars is less than the minimum required (e.g. 2).

2. **Determine Scan Range**:
   - To avoid $O(N^2)$ performance in hot paths, we only scan new bars since the last update.
   - `startIndex` is determined by comparing `ratesTotal` with `m_lastProcessedRatesTotal`.
   - On mid-candle ticks (`ratesTotal == m_lastProcessedRatesTotal` and `prevCalculated > 0`), `startIndex` is set to `1` to scan only the latest closed bar, avoiding redundant full-history rescans.
   - On new candle opens (`ratesTotal > m_lastProcessedRatesTotal` or `prevCalculated == 0`), `startIndex` is set to `ratesTotal - 1` to scan all unprocessed closed bars chronologically. Index 0 (live candle) is never evaluated for breaks.

3. **BOS and iBOS Detection**:
   - For every unprocessed bar `i` from oldest to newest:
     - Get the latest confirmed swing high and low at that point in time (from `CSwingDetector`'s history up to bar index `i`).
     - **External Swing High Break (Bullish BOS)**:
       - Check if `close[i] > swingHigh.price`.
       - Check if the break was already recorded for this swing high (verify `brokenSwing.time != swingHigh.time` in break history).
       - If true, log `BREAK_BOS` with direction `TREND_BULLISH`.
     - **External Swing Low Break (Bearish BOS)**:
       - Check if `close[i] < swingLow.price`.
       - Check if already recorded.
       - If true, log `BREAK_BOS` with direction `TREND_BEARISH`.
     - **Internal Swings Break (iBOS)**:
       - Perform identical checks using the internal swing arrays. If broken, log `BREAK_INTERNAL_BOS`.

4. **CHoCH Detection**:
   - If the current trend is `TREND_BULLISH`:
     - The protected swing is the latest confirmed External Swing Low.
     - If at bar `i`, `low[i] < protectedLow.price` AND `close[i] >= protectedLow.price`:
       - This is a wick-only breach.
       - Check if a CHoCH break has already been logged for this swing low.
       - If not, log `BREAK_CHOCH` with direction `TREND_BEARISH` (warning of bearish reversal).
   - If the current trend is `TREND_BEARISH`:
     - The protected swing is the latest confirmed External Swing High.
     - If at bar `i`, `high[i] > protectedHigh.price` AND `close[i] <= protectedHigh.price`:
       - This is a wick-only breach.
       - Check if a CHoCH break has already been logged for this swing high.
       - If not, log `BREAK_CHOCH` with direction `TREND_BULLISH` (warning of bullish reversal).

5. **Compute Break Strength**:
   - For each confirmed break, calculate:
     - `displacement` = `Absolute(close[i] - swing.price)`.
     - `atrMultiple` = `(high[i] - low[i]) / ATR`.
     - If `atrMultiple >= 2.0` $\implies$ `STRENGTH_STRONG` (Score 90.0).
     - Else if `atrMultiple >= 1.0` $\implies$ `STRENGTH_AVERAGE` (Score 70.0).
     - Else $\implies$ `STRENGTH_WEAK` (Score 45.0).
