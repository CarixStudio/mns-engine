# Module 005 — COrderFlowEngine Algorithm
Version: 1.0
Status: Approved

---

## Inputs

- Swing Highs and Lows (from `CSwingDetector`)
- Trend and Phase state (from `CStructureEngine`)
- Confirmed Breaks history (from `CBreakDetector`)
- Bar OHLC values and Datetime arrays
- Current ATR

---

## Outputs

- Active `SOrderFlowState` structure
- Alignment indicators for the structure confidence score

---

## Processing Pipeline

1. **Verify Initialization**:
   - Return false if the engine is not initialized.
   - Return false if the number of bars is less than 2.

2. **Chronological Break Evaluation**:
   - Scan new breaks confirmed in `CBreakDetector` since the last update cycle:
     - Range: `i = m_lastProcessedBreakCount` to `breakDetector.GetBreakCount() - 1`.
     - For each new break `sb = breakDetector.GetBreak(i)`:
       - **If CHoCH Break (`sb.breakType == BREAK_CHOCH`)**:
         - **Bearish CHoCH** (`sb.brokenSwing.type == SWING_LOW`):
           - Trigger transition if in `BULLISH` or `TRANSITION_BULLISH` state.
           - State transitions to `ORDER_FLOW_TRANSITION_BEARISH`.
           - Set `previousDirection = direction`.
           - Set `direction = ORDER_FLOW_DIR_NEUTRAL`.
           - Set `lastCHoCHId = sb.time`.
           - Set `startTime = sb.time`.
           - Set `transition = true`, `confirmed = false`, `invalidated = false`.
           - Set `lastUpdatedTime = sb.time`.
         - **Bullish CHoCH** (`sb.brokenSwing.type == SWING_HIGH`):
           - Trigger transition if in `BEARISH` or `TRANSITION_BEARISH` state.
           - State transitions to `ORDER_FLOW_TRANSITION_BULLISH`.
           - Set `previousDirection = direction`.
           - Set `direction = ORDER_FLOW_DIR_NEUTRAL`.
           - Set `lastCHoCHId = sb.time`.
           - Set `startTime = sb.time`.
           - Set `transition = true`, `confirmed = false`, `invalidated = false`.
           - Set `lastUpdatedTime = sb.time`.
       - **If BOS Break (`sb.breakType == BREAK_BOS`)**:
         - **Bullish BOS** (`sb.brokenSwing.type == SWING_HIGH`):
           - Check displacement: must have `sb.strength > STRENGTH_WEAK`.
           - If in `ORDER_FLOW_TRANSITION_BULLISH`, verify the continuation condition: the broken swing high's confirmation time must be after the transition started (`sb.brokenSwing.time >= startTime`).
           - If eligible:
             - State transitions to `ORDER_FLOW_BULLISH`.
             - Set `direction = ORDER_FLOW_DIR_BULLISH`.
             - Set `lastBOSId = sb.time`.
             - Set `displacementId = sb.time`.
             - Set `confirmed = true`, `transition = false`, `invalidated = false`.
             - Search swing detector history to locate the latest confirmed Swing Low *before* `sb.time`. Set `originSwingId` and `protectedSwingId` to this Swing Low's time.
             - Set `lastUpdatedTime = sb.time`.
         - **Bearish BOS** (`sb.brokenSwing.type == SWING_LOW`):
           - Check displacement: must have `sb.strength > STRENGTH_WEAK`.
           - If in `ORDER_FLOW_TRANSITION_BEARISH`, verify the continuation condition: the broken swing low's confirmation time must be after the transition started (`sb.brokenSwing.time >= startTime`).
           - If eligible:
             - State transitions to `ORDER_FLOW_BEARISH`.
             - Set `direction = ORDER_FLOW_DIR_BEARISH`.
             - Set `lastBOSId = sb.time`.
             - Set `displacementId = sb.time`.
             - Set `confirmed = true`, `transition = false`, `invalidated = false`.
             - Search swing detector history to locate the latest confirmed Swing High *before* `sb.time`. Set `originSwingId` and `protectedSwingId` to this Swing High's time.
             - Set `lastUpdatedTime = sb.time`.
     - Increment `m_lastProcessedBreakCount`.

3. **Intact / Invalidation Check**:
   - Perform a defensive check on the current closed bar (index 1) to verify if the active protected swing remains unbreached:
     - **If state is `ORDER_FLOW_BULLISH`**:
       - Locate the Swing Low with time `protectedSwingId` in the swing detector.
       - Calculate `minBreakDistance = max(2 * Point, 0.10 * ATR)`.
       - If `close[1] < protectedLow.price - minBreakDistance`:
         - Set `invalidated = true`.
         - State transitions to `ORDER_FLOW_NEUTRAL`.
         - Set `direction = ORDER_FLOW_DIR_NEUTRAL`.
     - **If state is `ORDER_FLOW_BEARISH`**:
       - Locate the Swing High with time `protectedSwingId` in the swing detector.
       - Calculate `minBreakDistance = max(2 * Point, 0.10 * ATR)`.
       - If `close[1] > protectedHigh.price + minBreakDistance`:
         - Set `invalidated = true`.
         - State transitions to `ORDER_FLOW_NEUTRAL`.
         - Set `direction = ORDER_FLOW_DIR_NEUTRAL`.

4. **Dynamic Output Calculations**:
   - Update `bullishStrength` / `bearishStrength`:
     - If in `ORDER_FLOW_BULLISH` or `ORDER_FLOW_TRANSITION_BULLISH`, scan recent bars to find the latest bullish displacement candle. Calculate strength as `(High - Low) / ATR`.
     - If in `ORDER_FLOW_BEARISH` or `ORDER_FLOW_TRANSITION_BEARISH`, scan recent bars to find the latest bearish displacement candle. Calculate strength as `(High - Low) / ATR`.
   - Update `confidenceScore` (0 to 100):
     - If `state == ORDER_FLOW_NEUTRAL` $\implies$ `0.0`.
     - If in transition $\implies$ `40.0`.
     - If fully confirmed (`BULLISH` or `BEARISH`):
       - Base score: `70.0`.
       - Add `20.0` points if the latest BOS break strength is `STRENGTH_VERY_STRONG` (or `10.0` points if `STRENGTH_STRONG`).
       - Add `10.0` points if the internal trend (from `CStructureEngine`) is aligned with the active order flow direction.

5. **Expose Alignment to CStructureEngine**:
   - The caller feeds the order flow alignment back to `CStructureEngine` using `SetOrderFlowAlignment()`.
     - If order flow direction matches structure trend $\implies$ `ALIGN_ALIGNED`.
     - If order flow direction is neutral $\implies$ `ALIGN_NEUTRAL`.
     - If order flow direction opposes structure trend $\implies$ `ALIGN_CONFLICT`.
