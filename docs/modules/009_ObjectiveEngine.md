# Module 009 — Objective Engine Specification

## 1. Overview

The **Objective Engine** (`CObjectiveEngine`) identifies, scores, and tracks the primary Draw on Liquidity (DOL) / market target for the MNS Trading Engine. It acts as the anchor for directional bias, supplying other engine components (like POI Engine, Confirmation Engine, and Entry Engine) with the active target price level.

---

## 2. Requirements & Rules

Conforming strictly to **[kennystrategy2.md Section 6](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/kennystrategy2.md#L645-L690)**:

### 2.1 Candidate Objectives
The engine evaluates the following candidates for market objectives:
- **Primary Liquidity Pools**:
  - External swing highs/lows (from `CSwingDetector`).
  - EQH/EQL pools (from `CLiquidityEngine`).
  - Previous Day High/Low (scanned from price/time series).
  - Previous Week High/Low (scanned from price/time series).
  - Session High/Low (scanned from price/time series for defined session hours).
  - Unmitigated swing extremes.
- **Secondary Targets (PoI / Rebalance)**:
  - Major FVG boundaries (from `CPOIEngine`).
  - Opposing POI boundaries (from `CPOIEngine`).
  - Equilibrium / Range boundaries.

### 2.2 DOL Selection Score
Every candidate is evaluated and scored out of 100 points:
1. **Direction compatibility (25 points)**: Bullish target if structure/delivery is bullish, bearish target if bearish.
2. **Liquidity strength (20 points)**: High score for EQH/EQL or external swings, lower score for internal swings, lowest for FVG/POI.
3. **HTF significance (15 points)**: High score for weekly/HTF levels, medium for daily/session levels, lower for local levels.
4. **Freshness (10 points)**: Higher score for completely untouched pools.
5. **Structural significance (10 points)**: Higher score for swings originating key breaks (BOS/CHoCH).
6. **Distance feasibility (5 points)**: Score based on distance relative to current ATR (ideal is 1x - 5x ATR).
7. **Delivery alignment (10 points)**: Target aligned with the active delivery direction.
8. **MTF alignment (5 points)**: Aligned with HTF direction if available.

- **Minimum Active Score**: A candidate must score at least **60 points** to be eligible as the active DOL. If no candidate meets this threshold, the active DOL is set to `MNS_INVALID_PRICE`.

### 2.3 DOL Replacement (Hysteresis)
To avoid constantly switching targets when slightly closer levels appear, the active DOL is only replaced when:
1. The current DOL is **consumed / hit** (swept or mitigated).
2. The **delivery direction changes**.
3. A new candidate's score exceeds the current DOL score by **>= 15 points** AND the new candidate is structurally more relevant.

---

## 3. Interface Contract

### 3.1 Inputs
- Current price data arrays (`high[]`, `low[]`, `close[]`, `open[]`, `time[]`, `ratesTotal`, `prevCalculated`).
- Swings database (`CSwingDetector`).
- Structure database (`CStructureEngine`).
- Structural breaks database (`CBreakDetector`).
- Order flow database (`COrderFlowEngine`).
- Delivery structure database (`CDeliveryStructureEngine`).
- Liquidity database (`CLiquidityEngine`).
- POI database (`CPOIEngine`).
- Current ATR value (volatility context).

### 3.2 Outputs
- Active DOL price (`double`).
- Active DOL type (`EDolType`).
- Active DOL score (`double`).
- Active DOL time (`datetime`).
- Secondary objective price/type (optional).

---

## 4. Strategy Cross-Check & Traceability

Every requirement in this specification is mapped to the strategy rules:

| Requirement | Source Reference | Classification |
|---|---|---|
| **DOL Selection Candidates** | `kennystrategy2.md` Section 6.2 | ✅ Specified |
| **Selection Scoring Components** | `kennystrategy2.md` Section 6.3 | ✅ Specified |
| **Minimum DOL Active Score (60)** | `kennystrategy2.md` Section 6.3 | ✅ Specified |
| **Replacement Hysteresis (>= 15 pts)** | `kennystrategy2.md` Section 6.4 | ✅ Specified |
| **Scanning Previous Day/Week High/Low** | Engineering Inference from candidate list | ⚠️ Inferred |
| **Calculating Distance Feasibility (relative to ATR)** | Engineering Inference for feasibility limits | ⚠️ Inferred |
| **OP opposing HTF POI boundary** | `kennystrategy2.md` Section 6.2 | ✅ Specified |
| **Opposing HTF POI score calculations** | Not detailed in Section 6.3 table | ❌ Unknown |

### Open / Unknown Items (TODOs):
- **HTF Opposing POI Score Weights**: The strategy document mentions "Opposing HTF POI boundary" as a candidate but does not specify how its structural significance weight or HTF significance weight is mapped in the selection score.
- **MTF Alignment bias**: How the higher timeframe bias (bullish/bearish) is fed to the engine since it's operating on a single chart stream.
- **Session times**: The strategy specifies "Session liquidity" but doesn't define standard hours for sessions (Tokyo/London/NY). Default hours (Tokyo 00-08, London 08-16, NY 13-21) are assumed.
