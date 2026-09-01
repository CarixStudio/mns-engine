# Module 012 — Risk Engine (CRiskEngine)

## 1. Purpose

The **Risk Engine** (`CRiskEngine`) is responsible for calculating pre-trade risk parameters (Stop Loss with buffers, Risk-to-Reward ratio verification, position size calculation based on account equity and broker contract details) and active-position risk management (partial closes at +1.0R, trailing stop adjustments starting at +1.5R, and position emergency exits based on strategy invalidations).

## 2. Requirements & Strategy Rules

### 2.1 Risk Model & Limits (Section 9.1)
- Risk is percentage-based and calculated using account equity.
- **Limits**:
  - Minimum Risk: `0.25%`
  - Default Risk: `1.00%`
  - Maximum Risk: `2.00%`
- Never increase risk after losses (no martingale or risk recovery multipliers).

### 2.2 Stop Loss Buffer (Section 9.2)
- Stop Loss (SL) is placed beyond the structural invalidation level with an ATR-based and point-based buffer:
  $$\text{StopBuffer} = \max(2 \times \text{SYMBOL\_POINT}, 0.20 \times \text{ATR}(14))$$
- **Bullish (Buy)**:
  $$\text{SL} = \text{InvalidationLow} - \text{StopBuffer}$$
- **Bearish (Sell)**:
  $$\text{SL} = \text{InvalidationHigh} + \text{StopBuffer}$$

### 2.3 Take Profit & Risk-Reward Check (Section 9.3)
- Primary Take Profit (TP) is the active Draw on Liquidity (DOL) target.
- Trade is approved ONLY if the Reward-to-Risk ratio satisfies:
  $$\text{RR} = \frac{\text{RewardDistance}}{\text{RiskDistance}} \ge 1.50\text{R}$$
  where:
  - $\text{RiskDistance} = |\text{EntryPrice} - \text{SL}|$
  - $\text{RewardDistance} = |\text{TakeProfit} - \text{EntryPrice}|$
- If the DOL target yields $\text{RR} < 1.50\text{R}$, the trade is **rejected**.
- Never artificially inflate or move the TP farther simply to satisfy the $1.50\text{R}$ requirement.

### 2.4 Position Sizing (Section 9.4)
- Calculate cash risk:
  $$\text{RiskAmount} = \text{AccountEquity} \times \frac{\text{RiskPercent}}{100}$$
- Calculate position size (Volume) using broker-defined contract properties.
- **Calculation Formula**:
  $$\text{Volume} = \frac{\text{RiskAmount}}{\text{LossPerLot}}$$
  where $\text{LossPerLot}$ is the loss in deposit currency for a standard 1.0 lot trade from EntryPrice to SL (evaluated via MT5's `OrderCalcProfit` or manual backup calculation using tick values).
- Normalize the volume using `SYMBOL_VOLUME_MIN`, `SYMBOL_VOLUME_MAX`, and `SYMBOL_VOLUME_STEP`.
- **Rounding**: Never round volume upward beyond the risk tolerance limit. Always perform a floor operation to the nearest valid volume step:
  $$\text{NormalizedVolume} = \text{floor}\left(\frac{\text{Volume}}{\text{Step}}\right) \times \text{Step}$$

### 2.5 Active Position Management (Section 9.5, 9.7, 9.8)
- **Partial Close**:
  - Triggered at $+1.0\text{R}$ progress (when price moves by $1.0 \times \text{RiskDistance}$ in the direction of the trade).
  - Close **50%** of the active position volume.
  - Triggered exactly **once** per position.
- **Trailing Stop**:
  - Activation: Starts once price reaches $+1.5\text{R}$ progress.
  - Trailing Distance: $1 \times \text{ATR}(14)$ behind the current price.
  - Frequency: Update stop level only after every additional $+0.5\text{R}$ progress.
  - Stop Movement constraint: **Never worsen a stop** (stops can only move in the direction of profit).
- **Emergency Exits**:
  - Exit position immediately if:
    - DOL target is reached or invalidated.
    - Delivery structure is invalidated.
    - Confirmed HTF/MTF reversal occurs.
    - Daily protection triggers (max daily drawdown limit reached).
  - A wick-only structural warning must **not** force an exit.

## 3. Inputs & Outputs

### 3.1 Pre-Trade Sizing Inputs
- `direction` (Bullish/Bearish confirmation direction)
- `entryPrice` (Trigger execution price)
- `invalidationLevel` (Structural low/high from confirmation)
- `dolPrice` (Active DOL target price)
- `atr14` (Current 14-period ATR value)
- `riskPercent` (Desired risk percentage, bounded between 0.25% and 2.00%)
- `accountEquity` (Current account equity)
- `symbol` (Symbol name)

### 3.2 Pre-Trade Sizing Outputs (`SRiskSizingResult`)
- `approved` (True if RR >= 1.50R, else false)
- `stopLoss` (Stop loss price with buffer)
- `takeProfit` (Take profit price matching DOL)
- `volume` (Floored lot size matching risk percentage)
- `riskAmount` (Expected loss in account currency)
- `expectedRr` (Calculated reward-to-risk ratio)

### 3.3 Active Sizing Inputs
- `positionDirection` (Bullish/Bearish)
- `positionEntryPrice` (Actual entry price)
- `positionCurrentVolume` (Active position volume)
- `positionCurrentStopLoss` (Current stop loss price)
- `invalidationLevel` (Updated structural invalidation level)
- `currentBid` / `currentAsk` (Current market prices)
- `atr14` (Current ATR value)
- `deliveryLifecycle` (Active delivery leg state)
- `isDolReached` / `isDolInvalidated` (Active DOL status)
- `mtfReversal` (MTF direction bias reversal status)
- `dailyDrawdownPercent` (Current daily drawdown percentage)

### 3.4 Active Sizing Outputs (`SRiskManagementAction`)
- `closeFully` (True if emergency exit or DOL reached)
- `closePartially` (True if +1.0R reached and not yet partially closed)
- `partialVolume` (Lots to close, i.e., 50% of current volume)
- `newStopLoss` (New stop loss price if trailing or moving to break-even)

## 4. State Recovery & Synchronization

To handle situations where the Expert Advisor restarts (e.g., terminal crash, server reboot, or timeframe changes) and must rebuild its memory of active positions:
- The `CRiskEngine` exposes getter/setter methods:
  - `SetHasPartialClosed(bool flag)`
  - `GetHasPartialClosed()`
- On startup or state recovery, the EA scans open positions on the account. If it detects that a position's current volume is less than or equal to half of its original sized volume, it identifies the position as having already been partially closed.
- The EA calls `g_riskEngine.SetHasPartialClosed(true)` to synchronize the engine's internal tracker, preventing duplicate partial close signals and preserving correct trailing stop thresholds.

