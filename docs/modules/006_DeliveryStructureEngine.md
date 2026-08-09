# Module 006 — Delivery Structure Engine Specification

## 1. Overview
The **Delivery Structure Engine** (`CDeliveryStructureEngine`) evaluates the active directional price-delivery leg in the market. It represents the trajectory of price moving from a confirmed structural origin (protected swing / POI) toward a designated liquidity target (Objective or Draw on Liquidity / DOL).

This engine acts as the primary coordinator between Market Structure, Order Flow, and Objectives/DOL.

---

## 2. Interface / Contract

### 2.1 Inputs
The engine consumes:
1. `CSwingDetector` — Swings database (external and internal).
2. `CStructureEngine` — Market trend and phase states.
3. `CBreakDetector` — Confirmed BOS and CHoCH breaks.
4. `COrderFlowEngine` — Current order flow bias alignment.
5. Price series data (`high[]`, `low[]`, `close[]`, `open[]`, `time[]`).
6. `currentAtr` — Market volatility metric.
7. `htfDolPrice` — (Optional) High Timeframe objective or target price.

### 2.2 Outputs
The engine outputs `SDeliveryState` containing:
- `direction`: Enum (`DELIVERY_DIR_NEUTRAL`, `DELIVERY_DIR_BULLISH`, `DELIVERY_DIR_BEARISH`).
- `originPrice`: Origin swing low/high price.
- `originTime`: Time of origin swing point creation.
- `protectedPrice`: Price of the active protected swing.
- `currentObjective`: Price level of the target objective/DOL.
- `associatedBosId`: Confirming BOS break time.
- `associatedDisplacementId`: Confirming displacement bar time.
- `lifecycle`: Enum representing current lifecycle (`DELIVERY_CANDIDATE`, `DELIVERY_ACTIVE`, `DELIVERY_MITIGATED`, `DELIVERY_OBJECTIVE_REACHED`, `DELIVERY_INVALIDATED`, `DELIVERY_REPLACED`, `DELIVERY_ARCHIVED`).
- `confidence`: Confidence score (0 to 100).
- `progressPercent`: Price progress between origin and objective.
- `invalidationLevel`: Price level at which body close invalidates the leg.

---

## 3. Requirements & Rules

### 3.1 Valid Delivery Activation (Section 3.2)
A delivery leg becomes `DELIVERY_ACTIVE` when:
1. Market Structure direction is confirmed (`BULLISH` or `BEARISH`).
2. Order Flow bias agrees with the structural direction.
3. Valid displacement momentum is confirmed on the breakout candle.
4. The origin swing point remains valid (intact).
5. A designated objective/target price exists.

### 3.2 Invalidation Rules (Section 3.4)
- **Bullish Leg**: Invalidated strictly on a **confirmed candle body close** below the protected low.
- **Bearish Leg**: Invalidated strictly on a **confirmed candle body close** above the protected high.
- **Wick Breach Rule**: A wick breaching the protected price level *does not* invalidate the leg by default; only a body close does. A wick breach of the protected level triggers `DELIVERY_MITIGATED`.

### 3.3 Mitigation Rules
- Transition to `DELIVERY_MITIGATED` occurs when price retraces and a candle wick touches or goes past the invalidation level without generating a closing bar beyond it.

---

## 4. Requirement Traceability Matrix

| Requirement | Description | Status | Reference |
| :--- | :--- | :--- | :--- |
| **REQ-3.1** | Connect Market Structure, Order Flow, and DOL | ✅ Specified | kennystrategy2.md Section 3.1 |
| **REQ-3.2** | Delivery becomes active only when all conditions align | ✅ Specified | kennystrategy2.md Section 3.2 |
| **REQ-3.3** | Lifecycle states: CANDIDATE, ACTIVE, MITIGATED, OBJECTIVE_REACHED, INVALIDATED, REPLACED, ARCHIVED | ✅ Specified | kennystrategy2.md Section 3.3 |
| **REQ-3.4** | Invalidation occurs strictly on a candle body close | ✅ Specified | kennystrategy2.md Section 3.4 |
| **REQ-3.5** | Output delivery leg metrics and confidence score | ✅ Specified | kennystrategy2.md Section 3.5 |
| **REQ-3.6** | Use opposite confirmed external swing as objective fallback | ⚠️ Inferred | Engineering best practice fallback |
| **REQ-3.7** | Confidence score booster calculations | ⚠️ Inferred | Consistent with Module 003/005 scoring |
