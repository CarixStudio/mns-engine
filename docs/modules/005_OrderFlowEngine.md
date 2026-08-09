# Module 005 — COrderFlowEngine Specification
Version: 1.0
Status: Approved

---

## 1. Purpose

The Order Flow Engine (`COrderFlowEngine`) consumes the market structure states and breaks to identify the active directional order flow (Bullish, Bearish, Neutral, or in transition). It determines whether the market is successfully delivering in a specific direction or if the structure is transitioning.

This module is a downstream consumer in the engine architecture, and its output is used by the Delivery Structure Engine, Liquidity Engine, POI Engine, and the market structure confidence score calculations.

---

## 2. Responsibilities

- Consume confirmed swings, trends, and breaks from `CSwingDetector`, `CStructureEngine`, and `CBreakDetector`.
- Evaluate and maintain the active Order Flow state: `BULLISH`, `BEARISH`, `NEUTRAL`, `TRANSITION_BULLISH`, or `TRANSITION_BEARISH`.
- Identify transitions cleanly: do not immediately flip order flow direction on wicks; enforce the confirmed transition state-machine sequence.
- Determine the origin swing and the current protected swing boundary that must remain intact.
- Calculate the Order Flow confidence score and directional strength.
- Maintain a deterministic and historical record of Order Flow state changes to prevent repainting.

---

## 3. Non-Responsibilities

- **No Chart Drawing**: Does not create chart objects, lines, or annotations.
- **No Trading Logic**: Does not place trades or manage risk parameters.
- **No Direct MT5 Calls**: Does not call MT5 data access arrays (`iClose()`, etc.). All inputs are supplied by the caller or dependency modules.

---

## 4. Inputs

- Swings list from `CSwingDetector` (External and Internal).
- Trend, phase, and structure types from `CStructureEngine`.
- Confirmed BOS, iBOS, and CHoCH breaks from `CBreakDetector`.
- Open, High, Low, Close (OHLC) arrays of the bars.
- ATR values.

---

## 5. Outputs

- Active `SOrderFlowState` structure containing:
  - `direction`: Active directional bias (`ORDER_FLOW_DIR_BULLISH`, `ORDER_FLOW_DIR_BEARISH`, or `ORDER_FLOW_DIR_NEUTRAL`).
  - `previousDirection`: Direction before the latest transition began.
  - `state`: Granular state (`ORDER_FLOW_NEUTRAL`, `ORDER_FLOW_BULLISH`, `ORDER_FLOW_BEARISH`, `ORDER_FLOW_TRANSITION_BULLISH`, `ORDER_FLOW_TRANSITION_BEARISH`).
  - `confidenceScore`: A rating from 0 to 100 representing the alignment confidence.
  - `originSwingId`: Datetime of the swing point that originated the current leg.
  - `protectedSwingId`: Datetime of the active protected swing.
  - `lastBOSId`: Datetime of the latest confirming BOS.
  - `lastCHoCHId`: Datetime of the latest transition-inducing CHoCH.
  - `displacementId`: Datetime of the displacement candle associated with the latest BOS.
  - `startTime`: Datetime when the current state was entered.
  - `lastUpdatedTime`: Datetime of the last calculation update.
  - `bullishStrength` / `bearishStrength`: Volatility-scaled strength values.
  - `transition` / `confirmed` / `invalidated` flags.

---

## 6. Cross-Check Against Strategy

| Requirement | Strategy Status | Classification |
|---|---|---|
| Bullish Order Flow requires confirmed bullish BOS | Explicitly specified (Section 2.1) | ✅ Specified |
| Bullish Order Flow requires bullish displacement with the BOS | Explicitly specified (Section 2.1) | ✅ Specified |
| Bullish Order Flow requires latest protected low remains intact | Explicitly specified (Section 2.1) | ✅ Specified |
| Bearish Order Flow requires confirmed bearish BOS | Explicitly specified (Section 2.1) | ✅ Specified |
| Bearish Order Flow requires bearish displacement with the BOS | Explicitly specified (Section 2.1) | ✅ Specified |
| Bearish Order Flow requires latest protected high remains intact | Explicitly specified (Section 2.1) | ✅ Specified |
| Bullish to Bearish transition starts with break of protected low by confirmed bearish CHoCH | Explicitly specified (Section 2.4) | ✅ Specified |
| Bearish to Bullish transition starts with break of protected high by confirmed bullish CHoCH | Explicitly specified (Section 2.4) | ✅ Specified |
| Order flow transitions from TRANSITION_BEARISH to BEARISH when a bearish BOS confirms | Explicitly specified (Section 2.4) | ✅ Specified |
| Order flow transitions from TRANSITION_BULLISH to BULLISH when a bullish BOS confirms | Explicitly specified (Section 2.4) | ✅ Specified |
| Confidence score, strength, and ID mappings | **Not explicitly defined** | ⚠️ Inferred (OPEN-011) |
| Continuation BOS validation | **Not explicitly defined** | ⚠️ Inferred (OPEN-012) |

---

## 7. Open Ambiguities

### OPEN-011 — Order Flow Confidence and Strength Formulas
- **Ambiguity**: Section 2.3 lists `confidenceScore`, `bullishStrength`, and `bearishStrength` as outputs but does not specify their calculation formulas.
- **Inference**:
  - `confidenceScore` is 40.0 for transition states, 0.0 for neutral. For fully confirmed bullish/bearish states, it starts at 70.0, adding 20.0 points if the latest BOS is `STRENGTH_VERY_STRONG` (or 10.0 points if `STRENGTH_STRONG`), and adding 10.0 points if the internal swing trend is aligned with the order flow.
  - `bullishStrength` is the ATR-normalized range of the latest bullish displacement candle when in a bullish/transition state, and 0.0 otherwise.
  - `bearishStrength` is the ATR-normalized range of the latest bearish displacement candle when in a bearish/transition state, and 0.0 otherwise.

### OPEN-012 — Continuation BOS Validation
- **Ambiguity**: The strategy states that transition goes to BEARISH when a "bearish BOS confirms". However, the CHoCH break of the protected low itself can be logged as a bearish BOS.
- **Inference**: To prevent the reversal break itself from immediately establishing a bearish trend, the confirmed bearish BOS that ends `TRANSITION_BEARISH` must break a swing low that was formed *after* the transition began (i.e. `brokenSwing.time >= transitionStartTime`). This guarantees that a new continuation swing low has formed and been broken.

---

*This file is maintained by the lead software architect.*
