# Module 011 — Entry Engine Specification

The **Entry Engine** (`CEntryEngine`) translates raw setup confirmations from `CConfirmationEngine` into trade execution entries. It manages the signal lifecycle, enforces pre-execution invalidations (such as risk-reward ratio limits and spread filters), and implements strict duplicate-entry prevention mechanisms.

## 1. Purpose

The Entry Engine is the final analytical gatekeeper before order routing. It ensures that entry signals are only generated at the first available market price immediately after a confirming candle closes. It tracks signals, ensures they expire after 5 execution-timeframe bars if unfilled, cancels them if setup parameters change (e.g., DOL target shifts or POIs invalidate), and ensures that no signal triggers more than once.

## 2. Inputs & Dependencies

The Entry Engine queries the states of all upstream modules on each bar update:
1. **Confirmation Engine** (`CConfirmationEngine`) — Checks if a setup is confirmed and reads trigger price/time/invalidation level.
2. **Objective Engine** (`CObjectiveEngine`) — Read active Draw on Liquidity (DOL) price to determine Take Profit.
3. **Structure Engine** (`CStructureEngine`) — Read MTF trend permission.
4. **Delivery Structure Engine** (`CDeliveryStructureEngine`) — Read active delivery leg status.
5. **POI Engine** (`CPOIEngine`) — Read active POI status.
6. **Price & Market Data** (`high[]`, `low[]`, `close[]`, `open[]`, `time[]`, `currentSpread`, `maxSpreadAllowed`) — Handles expiration, entry pricing, and spread filtering.
7. **Configuration System** (`INF-004 Configuration System`) — Reads default parameter settings.

## 3. Outputs

* **Active Entry Signal** (`SEntrySignal`) — A data structure containing:
  - Unique signal identifier (`id` / `triggerTime`).
  - Signal state (NONE, ACTIVE, EXECUTED, EXPIRED, INVALIDATED, CANCELLED).
  - Direction (BULLISH, BEARISH, NEUTRAL).
  - Entry price (`entryPrice`).
  - Stop Loss price (`stopLoss`).
  - Take Profit price (`takeProfit`).
  - Expiration time (`expirationTime`).
  - Confidence score (`confidenceScore`).
  - Execution status (`consumed`).

## 4. Strategy Rules

### 4.1 Exact Entry Trigger & Candle of Execution (Rule 8.1)
- The trigger is confirmed on a **closed** execution-timeframe candle (candle 1).
- Entry occurs at the **first available market price** (candle 0 opening/live tick) immediately after the confirming candle closes.
- Candle 0 is *never* used to confirm the signal.

### 4.2 Entry Invalidation before Execution (Rule 8.3)
An active signal is cancelled (`ENTRY_STATE_CANCELLED` or `ENTRY_STATE_INVALIDATED`) before execution if any of the following occur:
1. **POI Invalidation**: The associated POI is marked inactive or invalidated.
2. **DOL Shift**: The active DOL changes direction or shifts target price.
3. **Delivery Invalidation**: The active delivery leg is invalidated.
4. **MTF Permission Reverses**: The MTF directional score falls out of alignment.
5. **Confirmation Invalidation**: The Confirmation Engine reverts to `INVALIDATED`.
6. **Signal Expiration**: The signal remains unfilled for 5 execution-timeframe bars (default: 5 bars).
7. **Risk-Reward (RR) Failure**: The potential Reward-to-Risk ratio falls below `1.50R`.
   - `RiskDistance = abs(entryPrice - stopLoss)`
   - `RewardDistance = abs(takeProfit - entryPrice)`
   - `RR = RewardDistance / RiskDistance`
8. **Spread Limit Exceeded**: The current spread exceeds the configured maximum spread limit.

### 4.3 Duplicate-Entry Prevention (Rule 8.4)
- A single signal ID (associated with a unique confirmation trigger timestamp) can generate a **maximum of 1 execution**.
- Once executed, the signal is marked `consumed = true` and transitioning its state to `ENTRY_STATE_EXECUTED`.
- Signal consumption history must be preserved so that system restarts do not trigger a trade on the same historical signal.
