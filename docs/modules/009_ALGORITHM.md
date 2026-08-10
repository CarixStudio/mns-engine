# Module 009 — Objective Engine Algorithm

## 1. Candidate Gathering Pipeline

On each engine update:

### 1.1 Extracting Liquidity & Swing Candidates
1. **EQH/EQL Pools**: Query the `CLiquidityEngine` for all active liquidity pools. Identify their price levels and types (EQH = Bullish target, EQL = Bearish target).
2. **External Swings**: Query the `CSwingDetector` for the latest confirmed external swing points.
   - External swing highs act as Bullish targets.
   - External swing lows act as Bearish targets.

### 1.2 Extrapolating Higher-Timeframe & Session Boundaries
Without using broker APIs, scan the price history (`high[]`, `low[]`, `time[]`) starting from index 1 (closed bar) backwards:
1. **Previous Day High/Low (PDH/PDL)**:
   - Identify the previous calendar day (based on `time[]` changes).
   - Find the range of indices spanning that day.
   - Extract the highest high and lowest low of that range.
2. **Previous Week High/Low (PWH/PWL)**:
   - Identify the start and end of the previous calendar week.
   - Find the range of indices spanning that week.
   - Extract the highest high and lowest low.
3. **Session High/Low**:
   - For configured session times (e.g., London 08:00 - 16:00, NY 13:00 - 21:00, Tokyo 00:00 - 08:00):
   - Find the candles corresponding to these hours on the previous completed session.
   - Extract their highs and lows.

### 1.3 Secondary Objectives
1. **FVG Midpoints**: Query `CPOIEngine` for active `POI_FVG_BULLISH` and `POI_FVG_BEARISH` zones and compute their 50% midpoint price.
2. **Order Block Midpoints (Consequent Encroachment)**: Query `CPOIEngine` for active `POI_OB_BULLISH` and `POI_OB_BEARISH` zones and calculate their 50% midpoint price.

---

## 2. Multi-Factor Selection Scoring

Each candidate `C` is evaluated against the current market state and assigned a score (0 to 100):

| Component | Max Points | Scoring Conditions |
|---|---|---|
| **Direction Compatibility** | 25 | +25 if target is bullish (price > current) and current trend/delivery is bullish (or bearish target and bearish direction). 0 if opposite. |
| **Liquidity Strength** | 20 | +20 for EQH/EQL or external swings; +10 for internal swings/PDH/PDL; +5 for FVG/POI boundaries. |
| **HTF Significance** | 15 | +15 for weekly high/low or HTF swings; +10 for daily/session highs/lows; +5 for internal/local levels. |
| **Freshness** | 10 | +10 if untouched; +5 if partially mitigated/swept; +2 if heavily tested. |
| **Structural Significance** | 10 | +10 if target aligns with the origin of a confirmed BOS or CHoCH. |
| **Distance Feasibility** | 5 | +5 if distance from current price is between `1.0 * ATR` and `5.0 * ATR`; +3 if `< 1.0 * ATR` (near); +2 if `5.0 - 10.0 * ATR` (far); 0 if `> 10.0 * ATR` (unfeasible). |
| **Delivery Alignment** | 10 | +10 if aligned with the active delivery leg direction (`CDeliveryStructureEngine`). |
| **MTF Alignment** | 5 | +5 if aligned with HTF bias (if passed). |

---

## 3. Selection & Hysteresis Replacement Logic

1. **Discard Low Scores**: Candidates with a score $< 60$ are discarded.
2. **No Active DOL**:
   - If `m_currentDolPrice == MNS_INVALID_PRICE`, select the candidate with the highest valid score.
3. **Active DOL Exists**:
   - **Evaluate Consumption / Invalidity**:
     - Bullish DOL: If the high price of the current completed bar (index 1) $\ge$ DOL price, the target is consumed.
     - Bearish DOL: If the low price of the current completed bar (index 1) $\le$ DOL price, the target is consumed.
     - Direction Change: If the delivery engine direction changes (e.g. from Bullish to Bearish delivery, or vice versa), the active DOL is invalidated.
   - **Replacement Decision**:
     - If the active DOL is consumed or invalidated, clear it and select the new best candidate (if score $\ge 60$).
     - If the active DOL remains valid, compare it with the new `bestCandidate`:
       - If `bestScore >= activeScore + 15.0` AND `bestCandidate.type` has higher structural or liquidity significance (e.g., transitioning from an FVG boundary to an EQH pool), replace the active DOL with the new candidate.
       - Otherwise, maintain the current active DOL.
