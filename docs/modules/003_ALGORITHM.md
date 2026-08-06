# Module 003
# Structure Engine Algorithm
Version: 1.0
Status: Design

---

# Purpose

This document defines the algorithm used by the Structure Engine to classify confirmed swings and update trend and phase.

---

# Inputs

- Confirmed Swings (External & Internal arrays from `CSwingDetector`)
- Current Average True Range (ATR)
- Configured Minimum Break Distance

---

# Outputs

- Market Trend (Bullish, Bearish, Transition, Ranging, Unknown)
- Market Phase (Trending, Pullback, Transition, Ranging, Unknown)
- Latest Structure High Type (HH, LH, EQH)
- Latest Structure Low Type (HL, LL, EQL)
- Structure Confidence Score

---

# Processing Pipeline

1. **Receive Update**:
   - Check if initialized.
   - Verify `CSwingDetector` has new swings since the last process run.
   
2. **Evaluate New Swings**:
   - If a new External Swing High is confirmed:
     - Compare to previous confirmed External Swing High.
     - Apply ATR Tolerance: `Tolerance = 0.10 * CurrentATR`.
     - If `Abs(Current - Previous) <= Tolerance` -> Classify as Equal High (EQH).
     - Else if `Current > Previous + MinBreakDistance` -> Classify as Higher High (HH).
     - Else if `Current < Previous - MinBreakDistance` -> Classify as Lower High (LH).
   
   - If a new External Swing Low is confirmed:
     - Compare to previous confirmed External Swing Low.
     - If `Abs(Current - Previous) <= Tolerance` -> Classify as Equal Low (EQL).
     - Else if `Current > Previous + MinBreakDistance` -> Classify as Higher Low (HL).
     - Else if `Current < Previous - MinBreakDistance` -> Classify as Lower Low (LL).

3. **Update Trend and Phase**:
   - If the sequence of confirmed swings contains:
     - Minimum `HH -> HL -> HH -> HL` -> Set Trend = Bullish, Phase = Trending.
     - Minimum `LL -> LH -> LL -> LH` -> Set Trend = Bearish, Phase = Trending.
   - If the trend is Bullish, but the internal structure starts forming Lower Lows (LL) and Lower Highs (LH) -> Set Phase = Pullback (Concept only - pending OPEN-007 specification).
   - If the sequence is mixed (e.g. HH -> LL -> HL -> LH) -> Set Trend = Transition.
   - If the last several swings are mostly EQH/EQL with no clear direction -> Set Trend = Ranging, Phase = Ranging.

4. **Compute Confidence Score**:
   - Aggregate weightings based on factors:
     - HH/HL sequence consistency: 30%
     - BOS confirmation: 25% (Calculated by Break Detector downstream)
     - Swing quality: 20%
     - Displacement strength: 15%
     - Equal High/Low noise: 10%
   - Currently, returns a default value of `94.0` pending detailed calculation formulas (OPEN-008).
