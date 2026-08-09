# Module 007 — Liquidity Engine Algorithm

## 1. Overview
This document describes the step-by-step execution logic for detecting, tracking, and ranking liquidity pools, as well as checking for sweeps vs. breakouts.

---

## 2. Processing Pipeline

The `Update()` method processes incoming bar data:

```
                  ┌──────────────────────────────┐
                  │      Update Price Data       │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │  Scan for Daily/Weekly/      │
                  │        Session Levels        │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │   Evaluate Sweeps/Breakouts  │
                  │       on Active Pools        │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │  Process New Confirmed       │
                  │     Swings from Detector     │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │      Detect EQH / EQL        │
                  │   (Multi-Touch Alignment)    │
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

### Step 1: Scan Historical & Session Levels
- **Previous Day High/Low (PDH/PDL)**:
  - Detect day transition (`TimeDay(time[i]) != TimeDay(time[i-1])`).
  - Extract the highest high and lowest low of the completed day.
  - Create BSL and SSL pools with source `LIQ_SRC_DAILY` and price levels set to PDH/PDL.
- **Previous Week High/Low (PWH/PWL)**:
  - Detect week transition.
  - Extract highest/lowest prices of the completed week.
  - Create BSL and SSL pools with source `LIQ_SRC_WEEKLY` and price levels set to PWH/PWL.
- **Session Highs/Lows**:
  - Scan NY, London, and Asia sessions using broker timezone and `IsInSession()`.
  - Record the high/low of each session as soon as the session closes.
  - Create pools with source `LIQ_SRC_SESSION`.

### Step 2: Evaluate Sweeps and Breakouts on Active Pools
For each active pool (`lifecycle == LIQ_ACTIVE` or `LIQ_TOUCHED`):
- **Buy-side Pool (BSL)**:
  - **Sweep**: If `high[1] > pool.level` AND `close[1] <= pool.level + tolerance`:
    - Set `lifecycle = LIQ_SWEPT`
    - Set `active = false`, `swept = true`, `sweptTime = time[1]`
  - **Breakout**: If `close[1] > pool.level + minBreakDistance`:
    - Set `lifecycle = LIQ_BROKEN`
    - Set `active = false`, `brokenTime = time[1]`
- **Sell-side Pool (SSL)**:
  - **Sweep**: If `low[1] < pool.level` AND `close[1] >= pool.level - tolerance`:
    - Set `lifecycle = LIQ_SWEPT`
    - Set `active = false`, `swept = true`, `sweptTime = time[1]`
  - **Breakout**: If `close[1] < pool.level - minBreakDistance`:
    - Set `lifecycle = LIQ_BROKEN`
    - Set `active = false`, `brokenTime = time[1]`

### Step 3: Equal Highs / Equal Lows (EQH / EQL) Detection
When a new swing point is confirmed:
- Scan previous confirmed swings of the same type within a lookback window (e.g., last 50 external swings).
- For each prior swing, check equality within the dynamic tolerance window:
  - `Tolerance = max(3 * Point, 0.10 * ATR)`
  - `abs(HighA - HighB) <= Tolerance` (for EQH) or `abs(LowA - LowB) <= Tolerance` (for EQL)
- Verify Touch Separation:
  - The bar index difference between the touches must be `|barIndexA - barIndexB| >= 3`.
- If a match is found:
  - If a pool already exists for this level, increment `touchesCount` and record the touch time.
  - If not, create a new pool of type `LIQ_SRC_EQ` with `touchesCount = 2`.

### Step 4: Ranking & Priority Computation
For each pool, calculate its score (0 to 100):
- Start at `0.0`.
- If `source == LIQ_SRC_SWING` (External): `+25` points.
- If `source == LIQ_SRC_EQ`: `+20` points.
- If `touchesCount >= 3`: `+10` points.
- If `active` (untouched freshness): `+10` points.
- If `source == LIQ_SRC_SESSION` or `LIQ_SRC_DAILY` or `LIQ_SRC_WEEKLY`: `+5` points.
- If pool direction matches `CDeliveryStructureEngine::GetDirection()`: `+5` points.
- If pool level is within the objective pathway (Draw on Liquidity): `+5` points.
- Map score to Priority:
  - `score >= 80`: `PRIORITY_HIGH`
  - `score >= 60`: `PRIORITY_MEDIUM`
  - `score < 60`: `PRIORITY_LOW`
