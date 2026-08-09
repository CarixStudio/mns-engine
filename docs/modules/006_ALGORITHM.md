# Module 006 — Delivery Structure Engine Algorithm

## 1. Overview
This document describes the step-by-step processing pipeline for evaluating price delivery legs and managing state transitions within `CDeliveryStructureEngine`.

---

## 2. Processing Pipeline

The `Update()` method operates on every closed bar:

```
                  ┌──────────────────────────────┐
                  │      Update Price Data       │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │   Check Active Invalidation   │
                  │     (Body Close Breach)      │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │    Check Active Mitigation   │
                  │      (Wick Touch Origin)     │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │   Check Objective Reached    │
                  │     (Price Touches DOL)      │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │    Evaluate New Swings &     │
                  │      Confirming Breaks       │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │    Evaluate State Flipping   │
                  │     & Replacement Rules      │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │  Update Strength, Progress,  │
                  │     & Confidence Metrics     │
                  └──────────────────────────────┘
```

---

## 3. Algorithm Steps

### Step 1: Active Leg Validation
If the active state has `lifecycle == DELIVERY_ACTIVE` or `DELIVERY_OBJECTIVE_REACHED`:
- **Invalidation Check**: Compare the latest closed candle close price against `m_state.invalidationLevel`.
  - **Bullish Leg**: If `close[1] < invalidationLevel`, transition state:
    - Set `lifecycle = DELIVERY_INVALIDATED`
    - Set `direction = DELIVERY_DIR_NEUTRAL`
  - **Bearish Leg**: If `close[1] > invalidationLevel`, transition state:
    - Set `lifecycle = DELIVERY_INVALIDATED`
    - Set `direction = DELIVERY_DIR_NEUTRAL`
- **Mitigation Check**: If not invalidated, check if price breached or touched the invalidation level using candle wicks.
  - **Bullish Leg**: If `low[1] <= invalidationLevel`, transition state:
    - Set `lifecycle = DELIVERY_MITIGATED`
  - **Bearish Leg**: If `high[1] >= invalidationLevel`, transition state:
    - Set `lifecycle = DELIVERY_MITIGATED`
- **Objective Reached Check**: Check if price touched the target objective price:
  - **Bullish Leg**: If `high[1] >= currentObjective`, set `lifecycle = DELIVERY_OBJECTIVE_REACHED`.
  - **Bearish Leg**: If `low[1] <= currentObjective`, set `lifecycle = DELIVERY_OBJECTIVE_REACHED`.

### Step 2: Evaluate Structure & Breaks for Activation
Scan newly confirmed breaks from `CBreakDetector`:
- If `breakType == BREAK_BOS`:
  - **Bullish BOS**:
    - If `structureEngine.IsBullish() && orderFlowEngine.IsBullish() && sb.strength > STRENGTH_WEAK`:
      - If current state is `DELIVERY_DIR_BULLISH` and active, mark old leg as `DELIVERY_REPLACED`.
      - Initialize new delivery state:
        - Set `direction = DELIVERY_DIR_BULLISH`
        - Set `lifecycle = DELIVERY_ACTIVE`
        - Set `originPrice = prevLow.price` (latest confirmed swing low before BOS)
        - Set `originTime = prevLow.time`
        - Set `protectedPrice = prevLow.price`
        - Set `invalidationLevel = prevLow.price`
        - Set `associatedBosId = sb.time`
        - Set `associatedDisplacementId = sb.time`
        - Set `currentObjective = htfDolPrice != MNS_INVALID_PRICE ? htfDolPrice : latestSwingHigh.price`
  - **Bearish BOS**:
    - If `structureEngine.IsBearish() && orderFlowEngine.IsBearish() && sb.strength > STRENGTH_WEAK`:
      - If current state is `DELIVERY_DIR_BEARISH` and active, mark old leg as `DELIVERY_REPLACED`.
      - Initialize new delivery state:
        - Set `direction = DELIVERY_DIR_BEARISH`
        - Set `lifecycle = DELIVERY_ACTIVE`
        - Set `originPrice = prevHigh.price` (latest confirmed swing high before BOS)
        - Set `originTime = prevHigh.time`
        - Set `protectedPrice = prevHigh.price`
        - Set `invalidationLevel = prevHigh.price`
        - Set `associatedBosId = sb.time`
        - Set `associatedDisplacementId = sb.time`
        - Set `currentObjective = htfDolPrice != MNS_INVALID_PRICE ? htfDolPrice : latestSwingLow.price`

### Step 3: Compute Progress & Confidence
- **Progress %**:
  - If `direction == DELIVERY_DIR_NEUTRAL`, progress = `0.0`.
  - For Bullish: `progressPercent = 100.0 * (close[1] - originPrice) / (currentObjective - originPrice)`
  - For Bearish: `progressPercent = 100.0 * (originPrice - close[1]) / (originPrice - currentObjective)`
  - Cap progress at `[0.0, 100.0]`. If `lifecycle == DELIVERY_OBJECTIVE_REACHED`, force `progressPercent = 100.0`.
- **Confidence Score (0-100)**:
  - If `lifecycle == DELIVERY_CANDIDATE`, confidence = `30.0`.
  - If `lifecycle == DELIVERY_ACTIVE`, base score is `50.0`.
    - Add `+20.0` points if `orderFlowEngine.GetConfidenceScore() >= 80.0`.
    - Add `+15.0` points if `structureEngine.IsBullish() / IsBearish()` trend direction matches delivery direction.
    - Add `+15.0` points if the confirming BOS breakout strength is `STRENGTH_STRONG` or `STRENGTH_VERY_STRONG`.
  - If `lifecycle == DELIVERY_OBJECTIVE_REACHED` or `DELIVERY_MITIGATED`, confidence stays at its last active value.
  - If `DELIVERY_INVALIDATED`, confidence = `0.0`.
