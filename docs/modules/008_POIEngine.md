# Module 008 — POI Engine Specification

## 1. Overview
The **POI Engine** (`CPOIEngine`) identifies, tracks, and ranks Points of Interest (POIs) in the market. A Point of Interest represents a price zone where institutional order flow or liquidity imbalances reside (e.g. Order Blocks, Breaker Blocks, Mitigation Blocks, and Fair Value Gaps). These zones serve as primary entry locations when combined with confirmation signals.

The engine differentiates between:
- Bullish and Bearish Order Blocks (OB)
- Bullish and Bearish Breaker Blocks (BB)
- Bullish and Bearish Mitigation Blocks (MB)
- Bullish and Bearish Fair Value Gaps (FVG)
- Premium, Discount, and Equilibrium Zones

---

## 2. Interface / Contract

### 2.1 Inputs
The engine consumes:
1. `CSwingDetector` — Confirmed swings database (external and internal).
2. `CStructureEngine` — Market trend and phase states.
3. `CBreakDetector` — Confirmed structural breaks (BOS, CHoCH).
4. `CLiquidityEngine` — Tracked liquidity levels (for ranking).
5. `CDeliveryStructureEngine` — Active price-delivery leg.
6. Price series data (`high[]`, `low[]`, `close[]`, `open[]`, `time[]`).
7. `currentAtr` — Average True Range for size validation and quality scoring.

### 2.2 Outputs
The engine exposes:
- The active and historical list of POIs (`SPoIDefinition` array).
- Helper methods to query:
  - Active Bullish and Bearish POIs.
  - Nearest POIs to the current price.
  - Premium/Discount zone classification of the current price or any POI.
  - Confluence of overlapping POIs.

---

## 3. Requirements & Rules

### 3.1 Order Blocks (OB) Rules (Sections 5.1 & 5.2)
- **Bullish OB**: The last bearish candle (or compact bearish candle cluster) immediately before a bullish displacement candle that causes a confirmed bullish BOS.
  - *Mandatory*:
    1. Preceded by a bearish candle or cluster of bearish candles.
    2. Followed by a valid bullish displacement candle (body/range >= 65%, close strength >= 75%, range >= 1.20 * ATR).
    3. The displacement candle initiates a leg that causes a confirmed bullish BOS.
    4. The OB candle(s) must precede the BOS.
  - *Zone*: Lowest Low of the OB candle/cluster to the Open of the oldest (highest) candle in the OB candle/cluster. (Wick Low to Open).
  - *Invalidation*: A confirmed candle body close below the OB low.
- **Bearish OB**: The last bullish candle (or cluster) immediately before a bearish displacement candle that causes a confirmed bearish BOS.
  - *Zone*: Open of the oldest (lowest) candle in the OB candle/cluster to the highest High of the OB candle/cluster. (Open to Wick High).
  - *Invalidation*: A confirmed candle body close above the OB high.

### 3.2 Breaker Blocks (BB) Rules (Section 5.3)
- **Definition**: A failed Order Block that is structurally broken and subsequently used from the opposite side.
- **Bullish Breaker**:
  - Starts as a valid Bearish OB (supply zone).
  - Price invalidates the Bearish OB with a body close above its high.
  - Bullish structural confirmation occurs (bullish BOS or CHoCH in the opposite direction).
  - *Zone*: The full candle range of the failed Bearish OB (Low to High).
  - *Invalidation*: A confirmed candle body close below the breaker's low.
- **Bearish Breaker**:
  - Starts as a valid Bullish OB (demand zone).
  - Price invalidates the Bullish OB with a body close below its low.
  - Bearish structural confirmation occurs (bearish BOS or CHoCH).
  - *Zone*: The full candle range of the failed Bullish OB (Low to High).
  - *Invalidation*: A confirmed candle body close above the breaker's high.

### 3.3 Mitigation Blocks (MB) Rules (Section 5.4)
- **Definition**: The final opposing candle/zone in an impulsive leg that price later revisits to rebalance institutional exposure, without requiring the zone itself to cause the primary BOS.
- **Rules to prevent overclassification**:
  1. Must belong to a confirmed displacement leg.
  2. Must be structurally aligned (located between the displacement origin and the structural break/BOS).
  3. Must remain unmitigated.
  4. Priority ranks below a valid BOS-producing Order Block.
- **Bullish Mitigation Block**:
  - The last bearish candle in the bullish impulsive leg between the origin swing low and the BOS.
  - *Zone*: Low of the candle to Open of the candle.
  - *Invalidation*: A confirmed candle close below its low.
- **Bearish Mitigation Block**:
  - The last bullish candle in the bearish impulsive leg between the origin swing high and the BOS.
  - *Zone*: Open of the candle to High of the candle.
  - *Invalidation*: A confirmed candle close above its high.

### 3.4 Fair Value Gaps (FVG) Rules (Sections 5.5, 5.7, 5.8)
- **Candle Sequence**: Closed candles A-B-C (A is oldest, B is middle, C is newest).
  - **Bullish FVG**: `Low[C] > High[A]`. Gap range: `High[A]` (lower boundary) to `Low[C]` (upper boundary).
  - **Bearish FVG**: `High[C] < Low[A]`. Gap range: `High[C]` (lower boundary) to `Low[A]` (upper boundary).
- **Displacement**: Candle B should preferably have valid displacement (if it does, quality score is increased).
- **Minimum Size**:
  $$\text{MinimumFVG} = \max(3 \times \text{SYMBOL\_POINT}, 0.10 \times \text{ATR}(14))$$
  Gaps smaller than this are ignored.
- **Higher Quality FVG**: Gap size must be $\ge 0.20 \times \text{ATR}(14)$.
- **Fill Tracking**:
  $$\text{FillPercent} = \frac{\text{penetrationIntoGap}}{\text{totalGapSize}} \times 100$$
  - `0%`: Untouched.
  - `1 - 49%`: Partially mitigated.
  - `50 - 99%`: Materially mitigated.
  - `100%`: Filled (transition to state `POI_STATE_FILLED`, archive it).
- **Invalidation**: 100% fill (meaning a candle traverses the complete gap boundary).

### 3.5 Dealing Range Zones (Premium, Discount, Equilibrium) (Section 5.10)
- **Equilibrium**: The exact 50% price level of the active external dealing range:
  $$\text{Equilibrium} = \frac{\text{LatestExternalHigh} + \text{LatestExternalLow}}{2.0}$$
- **Discount**: Price levels strictly below Equilibrium. (Bullish setups must reside in Discount).
- **Premium**: Price levels strictly above Equilibrium. (Bearish setups must reside in Premium).

### 3.6 Overlapping POIs & Confluence (Section 5.9)
- **Merge Criteria**: Merge overlapping POIs ONLY if they share the same direction, same structural leg, and the overlap is $\ge 50\%$ of the smaller POI's size.
- **Confluence Score**: If POIs overlap but do not meet the merge criteria, retain them separately and compute a confluence score (e.g. Bullish OB + Bullish FVG overlap increases confidence score).

### 3.7 POI Priority Ranking (Section 5.10)
- **Base Priority**:
  1. Fresh HTF Order Block causing BOS (Score: 90-100, Priority: High)
  2. Breaker Block with confirmed retest (Score: 80-89, Priority: High)
  3. OB + FVG Confluence (Score: 70-79, Priority: Medium)
  4. Standalone fresh Order Block (Score: 60-69, Priority: Medium)
  5. Mitigation Block (Score: 50-59, Priority: Low)
  6. Standalone FVG (Score: < 50, Priority: Low)
- **Quality Score Boosters / Penalties (0-100 total)**:
  - Freshness (Untouched): `+10` points
  - Displacement strength of confirming candle: `+10` points
  - Premium/Discount alignment (Discount for Bullish, Premium for Bearish): `+10` points
  - Alignment with Active Delivery leg direction: `+10` points
  - Alignment with active Draw on Liquidity (DOL) level: `+10` points

---

## 4. Cross-Check Against Strategy Source of Truth

| Requirement | Strategy Document | Status | Notes |
|---|---|---|---|
| Bullish OB (Bearish candle before BOS displacement) | `kennystrategy2.md` Section 5.1 | ✅ Specified | Direct strategy rule |
| Bearish OB (Bullish candle before BOS displacement) | `kennystrategy2.md` Section 5.2 | ✅ Specified | Direct strategy rule |
| OB Invalidation via Candle Close | `kennystrategy2.md` Section 5.8 | ✅ Specified | Close below OB low / close above OB high |
| OB Zone (Low to Open) | `kennystrategy2.md` Section 5.1 | ✅ Specified | Default execution zone uses Low to Open |
| Breaker Block Definition and Zone | `kennystrategy2.md` Section 5.3 | ✅ Specified | Failed OB broken, range is full candle Low to High |
| Mitigation Block Definition | `kennystrategy2.md` Section 5.4 | ✅ Specified | opposing candle in leg, priority below OB |
| FVG Candle Sequence A-B-C | `kennystrategy2.md` Section 5.5 | ✅ Specified | Direct formula |
| Minimum FVG Size | `kennystrategy2.md` Section 5.5 | ✅ Specified | max(3 * point, 0.1 * ATR) |
| FVG Fill States | `kennystrategy2.md` Section 5.7 | ✅ Specified | 0%, 1-49%, 50-99%, 100% states |
| Overlapping POIs Merge Rule | `kennystrategy2.md` Section 5.9 | ✅ Specified | Merge if same dir, same leg, >= 50% overlap |
| POI Priority Ranking Order | `kennystrategy2.md` Section 5.10 | ✅ Specified | 1. HTF OB, 2. Breaker, 3. OB+FVG, 4. Standalone OB, 5. Mitigation, 6. Standalone FVG |
| Premium / Discount Location | `kennystrategy2.md` Section 5.10 | ✅ Inferred | Dealing range 50% threshold is standard SMC inference |
| Confluence Score Weights | `kennystrategy2.md` Section 5.10 | ⚠️ Inferred | Priority base scores and modifiers are engineered for mathematical ranking consistency |
| Inverse FVG (IFVG) | `docs/Roadmap.md` | ❌ Unknown | Mentioned in roadmap but undefined in strategy. NOT implemented. |
