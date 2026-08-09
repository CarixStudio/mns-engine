# Module 007 — Liquidity Engine Specification

## 1. Overview
The **Liquidity Engine** (`CLiquidityEngine`) identifies, tracks, and ranks liquidity pools in the market. Liquidity represents price levels where a cluster of stop orders or pending orders resides (e.g. above highs or below lows), which act as a magnet for price movement (Draw on Liquidity / DOL).

The engine differentiates between:
- Buy-side Liquidity (BSL)
- Sell-side Liquidity (SSL)
- Equal Highs (EQH) and Equal Lows (EQL)
- Session-based and Historical (Daily/Weekly) Liquidity
- Wick Sweeps vs. Candle Body Breakouts

---

## 2. Interface / Contract

### 2.1 Inputs
The engine consumes:
1. `CSwingDetector` — Swings database (external and internal).
2. `CDeliveryStructureEngine` — Active price-delivery leg.
3. Price series data (`high[]`, `low[]`, `close[]`, `open[]`, `time[]`).
4. `currentAtr` — Average True Range for tolerance calculations.

### 2.2 Outputs
The engine exposes:
- The active and historical list of liquidity pools (`SLiquidityPool` array).
- Helper methods to query:
  - Nearest BSL and SSL levels.
  - Active EQH and EQL levels.
  - Sweeps confirmed on the latest closed bar.

---

## 3. Requirements & Rules

### 3.1 Liquidity Sources (Sections 4.1 & 4.2)
- **BSL Zones**: Swing Highs, Equal Highs (EQH), Previous Day High (PDH), Previous Week High (PWH), Session Highs (Asia/London/NY), and Unmitigated External Highs.
- **SSL Zones**: Swing Lows, Equal Lows (EQL), Previous Day Low (PDL), Previous Week Low (PWL), Session Lows (Asia/London/NY), and Unmitigated External Lows.

### 3.2 Equal Highs / Lows (EQH / EQL) Rules (Section 4.3)
- **Touches**: Minimum 2 distinct touches. A stronger pool has 3+ touches.
- **Tolerance**:
  $$\text{LiquidityTolerance} = \max(3 \times \text{SYMBOL\_POINT}, 0.10 \times \text{ATR}(14))$$
  - Highs are equal if: $|HighA - HighB| \le \text{tolerance}$
  - Lows are equal if: $|LowA - LowB| \le \text{tolerance}$
- **Touch Separation**: Minimum **3 closed candles** of separation between touches to prevent adjacent candles from being treated as separate touches.

### 3.3 Sweeps vs. Breakouts (Sections 4.4 & 4.5)
- **Sweep**:
  - **Buy-side**: Candle high breaches the BSL level, but the candle closes back below/inside `LiquidityLevel + tolerance`.
  - **Sell-side**: Candle low breaches the SSL level, but the candle closes back above/inside `LiquidityLevel - tolerance`.
  - *Stronger confirmation*: Next closed candle continues in the sweep direction (lower for BSL sweep, higher for SSL sweep).
- **Breakout**:
  - **Buy-side**: Candle body closes above `LiquidityLevel + minimum break distance`.
  - **Sell-side**: Candle body closes below `LiquidityLevel - minimum break distance`.

### 3.4 Swept Liquidity Lifecycle (Section 4.6)
- **No Deletion**: Swept liquidity must *never* be deleted from memory.
- **State Transition**: Upon sweep confirmation, set `active = false`, `swept = true`, and transition lifecycle state from `LIQ_ACTIVE` to `LIQ_SWEPT`.

### 3.5 Liquidity Ranking & Priority (Section 4.7)
- **Ranking Score (0 to 100)**:
  - External swing point source: **25 points**
  - EQH/EQL source: **20 points**
  - HTF origin: **20 points**
  - 3+ distinct touches: **10 points**
  - Untouched freshness: **10 points**
  - Delivery direction alignment: **5 points**
  - DOL alignment: **5 points**
  - Session/PDH/PDL/PWH/PWL source: **5 points**
- **Priority Grade**:
  - `80 to 100`: **High**
  - `60 to 79`: **Medium**
  - `Below 60`: **Low**
