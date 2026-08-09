# Module 008 — POI Engine Algorithm

## 1. Overview
This document describes the step-by-step execution logic for detecting, updating, and ranking Points of Interest (OB, Breaker, Mitigation, FVG).

---

## 2. Processing Pipeline

The `Update()` method processes incoming bar data and confirmed structural events:

```
                   ┌──────────────────────────────┐
                   │    Scan for Fair Value Gaps  │
                   │        (FVGs) on candles     │
                   └──────────────┬───────────────┘
                                  │
                                  ▼
                   ┌──────────────────────────────┐
                   │   Evaluate New BOS Events    │
                   │   to Detect Order Blocks     │
                   └──────────────┬───────────────┘
                                  │
                                  ▼
                   ┌──────────────────────────────┐
                   │   Scan for Mitigation Blocks │
                   │   and Breakers on BOS/fails  │
                   └──────────────┬───────────────┘
                                  │
                                  ▼
                   ┌──────────────────────────────┐
                   │    Update POI Lifecycles     │
                   │  (Mitigations & Fills/Closes)│
                   └──────────────┬───────────────┘
                                  │
                                  ▼
                   ┌──────────────────────────────┐
                   │    Evaluate Confluence and   │
                   │      Overlapping Zones       │
                   └──────────────┬───────────────┘
                                  │
                                  ▼
                   ┌──────────────────────────────┐
                   │   Recalculate Ranking Scores │
                   │       and Priorities         │
                   └──────────────────────────────┘
```

---

## 3. Algorithm Steps

### Step 1: Scan for Fair Value Gaps (FVG)
For each new closed bar `i` (from oldest to newest, excluding forming bar 0):
- Identify closed candle sequence: `i+2` (A), `i+1` (B), `i` (C).
- **Bullish FVG**:
  - If `low[i] > high[i+2]`:
    - Calculate size: `gapSize = low[i] - high[i+2]`.
    - Retrieve config settings: `minSize = max(3 * Point, 0.10 * ATR(14))`.
    - If `gapSize >= minSize`:
      - Create FVG structure: `type = POI_FVG_BULLISH`, `lowerPrice = high[i+2]`, `upperPrice = low[i]`, `invalidationLevel = lowerPrice`, `barIndex = i+1`.
      - Check if candle `i+1` has valid displacement. If yes, flag it for scoring.
- **Bearish FVG**:
  - If `high[i] < low[i+2]`:
    - Calculate size: `gapSize = low[i+2] - high[i]`.
    - If `gapSize >= minSize`:
      - Create FVG structure: `type = POI_FVG_BEARISH`, `lowerPrice = high[i]`, `upperPrice = low[i+2]`, `invalidationLevel = upperPrice`, `barIndex = i+1`.
      - Check if candle `i+1` has valid displacement.

### Step 2: Detect Order Blocks (OB)
When `CBreakDetector::Update()` confirms a new `BOS` break:
- Get the break struct `sb`.
- Find the origin swing of the leg `originSwing` from `CSwingDetector` (Swing Low for Bullish BOS, Swing High for Bearish BOS) that occurred prior to `sb.time`.
- Scan bars from `originSwing.barIndex` forward to `sb.barIndex` to find the first candle with valid displacement (`body/range >= 65%`, `close strength >= 75%`, `range >= 1.20 * ATR`). Let's call it `dispBar`.
- If no displacement candle is found, fallback to `dispBar = originSwing.barIndex`.
- Search backwards starting at `dispBar + 1` for consecutive opposing candles (bearish for Bullish OB, bullish for Bearish OB), up to a maximum cluster size of 3.
- Establish the OB zone:
  - **Bullish OB**:
    - `lowerPrice` = lowest Low of the cluster.
    - `upperPrice` = Open of the oldest (highest) candle in the cluster.
    - `invalidationLevel = lowerPrice`.
  - **Bearish OB**:
    - `lowerPrice` = Open of the oldest (lowest) candle in the cluster.
    - `upperPrice` = highest High of the cluster.
    - `invalidationLevel = upperPrice`.
- Store the OB POI with `active = true`, `lifecycle = POI_STATE_ACTIVE`.

### Step 3: Detect Mitigation Blocks and Breakers
- **Breaker Blocks**:
  - On each tick, check all active OB POIs:
    - If a Bullish OB is breached by a candle body close below its `invalidationLevel`:
      - Set OB `active = false`, `lifecycle = POI_STATE_INVALIDATED`.
      - If a bearish BOS/CHoCH has been confirmed, convert the zone to a **Bearish Breaker**: `type = POI_BREAKER_BEARISH`, `lowerPrice = OB.lowerPrice`, `upperPrice = OB.upperPrice`, `invalidationLevel = OB.upperPrice`.
    - If a Bearish OB is breached by a candle body close above its `invalidationLevel`:
      - Set OB `active = false`, `lifecycle = POI_STATE_INVALIDATED`.
      - If a bullish BOS/CHoCH has been confirmed, convert the zone to a **Bullish Breaker**: `type = POI_BREAKER_BULLISH`, `lowerPrice = OB.lowerPrice`, `upperPrice = OB.upperPrice`, `invalidationLevel = OB.lowerPrice`.
- **Mitigation Blocks**:
  - When a BOS is confirmed, scan the range between the origin swing and the BOS:
    - Identify any opposing candles (bearish for Bullish BOS, bullish for Bearish BOS) that do not belong to the origin OB.
    - If the candle immediately following the opposing candle is a displacement candle, create a Mitigation Block POI:
      - **Bullish MB**: `type = POI_MITIGATION_BULLISH`, `lowerPrice = Low`, `upperPrice = Open`, `invalidationLevel = Low`.
      - **Bearish MB**: `type = POI_MITIGATION_BEARISH`, `lowerPrice = Open`, `upperPrice = High`, `invalidationLevel = High`.

### Step 4: Update POI Lifecycles
On each tick, evaluate active POIs against the latest closed bar (index 1):
- **Fair Value Gaps**:
  - Calculate FVG penetration:
    - Bullish: If `low[1] < upperPrice`, `penetration = upperPrice - MathMax(low[1], lowerPrice)`.
    - Bearish: If `high[1] > lowerPrice`, `penetration = MathMin(high[1], upperPrice) - lowerPrice`.
  - Calculate `fillPercent = (penetration / gapSize) * 100`.
  - If `fillPercent >= 100.0` or body close is past invalidation:
    - Set `active = false`, `lifecycle = POI_STATE_FILLED`.
  - Else if `fillPercent >= 50.0`:
    - Set `lifecycle = POI_STATE_MATERIAL_MITIGATED`.
  - Else if `fillPercent > 0.0`:
    - Set `lifecycle = POI_STATE_PARTIAL_MITIGATED`.
- **Blocks (OB, Breaker, Mitigation)**:
  - **Invalidation**: If `close[1]` closes beyond `invalidationLevel`:
    - Set `active = false`, `lifecycle = POI_STATE_INVALIDATED`.
  - **Mitigation**: If `lifecycle == POI_STATE_ACTIVE`:
    - Bullish: If `low[1] <= upperPrice` (wick touched the top of the zone):
      - Set `lifecycle = POI_STATE_PARTIAL_MITIGATED`.
    - Bearish: If `high[1] >= lowerPrice` (wick touched the bottom of the zone):
      - Set `lifecycle = POI_STATE_PARTIAL_MITIGATED`.

### Step 5: Overlapping POIs & Confluence
- Evaluate overlaps between active POIs:
  - If two POIs of the **same type and direction** overlap by $\ge 50\%$ of the smaller POI's size:
    - Merge them by expanding the first POI to cover the combined range (minimum of lower prices, maximum of upper prices).
    - Archive/deactivate the second POI (`active = false`, `lifecycle = POI_STATE_ARCHIVED`).
  - If two POIs of **different types** (e.g. Bullish OB and Bullish FVG) overlap:
    - Do not merge them.
    - Set `confluenceScore = 20.0` on both POIs to boost their quality rank.

### Step 6: Ranking and Priority
For each active POI, calculate a score (0 to 100):
- Start with the base priority score:
  - HTF OB: `65` points
  - Breaker: `60` points
  - Standalone OB: `55` points
  - Mitigation: `45` points
  - Standalone FVG: `35` points
- Add quality modifiers (up to `+35` points):
  - Freshness (Untouched): `+10` points
  - Displacement Strength of Candle B/Confirming Candle: `+10` points
  - Premium/Discount zone alignment (Bullish in Discount, Bearish in Premium): `+15` points
- Determine Priority:
  - `score >= 80`: `PRIORITY_HIGH`
  - `score >= 60`: `PRIORITY_MEDIUM`
  - `score < 60`: `PRIORITY_LOW`
