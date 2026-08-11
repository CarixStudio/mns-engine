# Module 010 — Confirmation Engine Specification

The **Confirmation Engine** (`CConfirmationEngine`) acts as the gating controller for trade execution within the MNS Trading Engine. It ensures that a trade setup is only marked as active/confirmed when all mandatory structural, liquidity, and location-based rules defined by the strategy are met.

## 1. Purpose

The Confirmation Engine evaluates whether a location-based setup (price entering a high-probability Point of Interest) is validated by immediate market action on the execution timeframe (M5 by default). It protects the system from entering trades purely on a zone touch, requiring explicit rejection wicks and structural shifts before generating entry signals.

## 2. Inputs & Dependencies

The Confirmation Engine queries the states of all upstream engines on each completed bar:
1. **Swing Detector** (`CSwingDetector`) — Confirmed pivot structures.
2. **Structure Engine** (`CStructureEngine`) — Current bias, trend direction, and confidence.
3. **Break Detector** (`CBreakDetector`) — Confirmed BOS/CHoCH triggers.
4. **Order Flow Engine** (`COrderFlowEngine`) — Current order flow direction.
5. **Delivery Structure Engine** (`CDeliveryStructureEngine`) — Active delivery leg state.
6. **Liquidity Engine** (`CLiquidityEngine`) — Liquidity sweeps (BSL/SSL).
7. **POI Engine** (`CPOIEngine`) — Active POI boundaries (OB/FVG/Breakers).
8. **Objective Engine** (`CObjectiveEngine`) — Current active Draw on Liquidity (DOL) target.
9. **Price Arrays** (`high[]`, `low[]`, `close[]`, `open[]`, `time[]`) — Market data.

## 3. Outputs

* **Active Confirmation State** (`SConfirmationState`) — A data structure containing:
  - Current confirmation lifecycle state (NONE, PENDING, CONFIRMED, INVALIDATED).
  - Direction (BULLISH, BEARISH, NEUTRAL).
  - Confidence Score (0.0 to 100.0).
  - Trigger price and datetime.
  - Invalidation level.
  - IDs of associated POIs, sweeps, and structural breaks.

## 4. Strategy Rules

### 4.1 Setup Prerequisites
Before searching for entry confirmations, the following conditions must be met:
1. An active Draw on Liquidity (DOL) must exist (from `CObjectiveEngine`).
2. There must be a valid, active POI in the direction of the bias (e.g. Bullish POI for a Bullish setup).
3. Price must have touched or entered the POI zone (`low[1] <= POI.upperPrice` for bullish; `high[1] >= POI.lowerPrice` for bearish).
   - Once touched, the engine transitions from `CONFIRMATION_STATE_NONE` to `CONFIRMATION_STATE_PENDING`.

### 4.2 Mandatory Confirmation Checklist (PENDING -> CONFIRMED)
While in `CONFIRMATION_STATE_PENDING`, the setup is confirmed only when all of the following are satisfied:
1. **POI Touch**: Verified POI interaction remains active.
2. **MTF Agreement**: Trend bias from the structure engine must not oppose the setup direction.
3. **Correct Delivery Direction**: The active delivery leg must align with the setup direction (`DELIVERY_DIR_BULLISH` for bullish, `DELIVERY_DIR_BEARISH` for bearish).
4. **Liquidity Event OR Rejection**:
   - *Liquidity Sweep*: A liquidity sweep (SSL for bullish, BSL for bearish) must have occurred on or after the POI touch.
   - *Strong Rejection*: A candlestick rejection wick must occur (lower wick >= 50% of range for bullish; upper wick >= 50% of range for bearish).
5. **Structural Trigger**:
   - A Change of Character (CHoCH) or Break of Structure (BOS) in the setup direction must be confirmed on or after the POI touch.

### 4.3 Invalidation Rules
The PENDING or CONFIRMED state is invalidated (`CONFIRMATION_STATE_INVALIDATED`) immediately if:
1. A candle body closes beyond the POI's invalidation level.
2. Price body closes beyond the invalidation level of the confirming structural swing (the swing point that triggered the CHoCH/BOS).
3. The active DOL target is reached or changed direction.
4. The active POI is invalidated.
5. Signal Expiration: A confirmed signal is active for a maximum of 5 bars on the execution timeframe. If no entry occurs, it expires back to `CONFIRMATION_STATE_NONE`.
