# MNS Trading Engine — Backtesting & Optimization Roadmap
## Target: Building a Premium "Gold Mine" EA

This document establishes the end-to-end backtesting, optimization, and validation methodology for the MNS EA. It guides the quantitative validation phase to maximize profitability, control drawdowns, and prevent curve-fitting.

---

## 1. Backtesting Parameters & Setup

### 1.1 MetaTrader 5 Strategy Tester Configuration
To achieve institutional-grade validation, the Strategy Tester must be configured as follows:

| Setting | Selection | Justification |
| :--- | :--- | :--- |
| **Model** | `Every tick based on real ticks` | Crucial for correct execution of POI mitigation and spreads |
| **Execution** | `100 ms random delay` | Simulates real broker latency and execution slippage |
| **Deposit** | `$10,000 USD` (or match prop firm size) | Realistic starting equity for scaling |
| **Leverage** | `1:100` (or match broker specs) | standard leverage for risk modeling |
| **Symbols** | `GBPUSD`, `EURUSD`, `XAUUSD` | Major pairs and Gold (highest liquidity and clean structures) |
| **Timeframe** | `H1` (Swing/Structure), `M5` (Execution) | Multi-timeframe execution alignment |
| **Optimization** | `Genetic Algorithm` | Rapidly parses parameter spaces with thousands of combinations |

---

## 2. Parameter Optimization Ranges

These settings will be optimized sequentially to prevent dimensionality explosion (optimizing 15+ variables at once):

### Phase A: Core Structural Engine (H1 Structure Sensitivity)
| Parameter | Default | Step Range | Optimize Step |
| :--- | :--- | :--- | :--- |
| `InpExternalDepth` | 15 | 10 → 40 | 2 |
| `InpInternalDepth` | 5 | 3 → 12 | 1 |
| `InpMinBreakDistance` | 0.0pt | 0 → 50pt | 5pt |

### Phase B: Entry & Proximity Rules (Trade Entry Precision)
| Parameter | Default | Step Range | Optimize Step |
| :--- | :--- | :--- | :--- |
| `InpConfidenceThreshold` | 94.0 | 75.0 → 98.0 | 2.0 |
| `InpAtrTolerance` | 0.0010 | 0.0005 → 0.0025 | 0.0002 |
| `InpDisplacementMinAtrMult` | 1.20 | 0.80 → 2.00 | 0.10 |
| `InpDisplacementMinBodyRatio`| 0.65 | 0.50 → 0.85 | 0.05 |
| `InpDisplacementMinCloseStr` | 0.75 | 0.60 → 0.90 | 0.05 |

### Phase C: Risk & Operational Rules (Money Management)
| Parameter | Default | Step Range | Optimize Step |
| :--- | :--- | :--- | :--- |
| `InpTrailingStop` | true | true / false | Boolean |
| `InpPartialClose` | true | true / false | Boolean |
| `InpFridayCloseHour` | 21 | 18 → 22 | 1 |

---

## 3. Backtesting Sequence (Preventing Curve-Fitting)

To ensure the EA performs robustly in live market conditions and is not over-optimized (curve-fitted) to history, we follow a strict **Walk-Forward Analysis (WFA)** protocol:

```
[ 3-Year Historical Period: 2023 - 2026 ]
 ├── [ Year 2023 - 2025: In-Sample Optimization ] ──► Find top 5 setting profiles
 └── [ Year 2025 - 2026: Out-of-Sample Validation ] ─► Test top 5 settings on unseen data
```

1. **In-Sample Run (IS)**: Run the optimization on 70% of the historical data (e.g. 2 years). Record the top 5 setting sets ranked by **Sharpe Ratio** and **Recovery Factor**.
2. **Out-of-Sample Run (OOS)**: Run the top 5 sets on the remaining 30% of unseen historical data.
   * *Pass Criteria*: The OOS performance must achieve a profit factor > 1.3 and maximum equity drawdown within 1.5x of the IS drawdown.
   * *Fail Criteria*: If OOS degrades by more than 50% compared to IS, the parameter set is rejected as over-fitted.

---

## 4. Key Performance Indicators (KPIs)

A "Gold Mine" settings profile must meet or exceed these thresholds:

*   **Profit Factor**: $\ge 1.50$ (Gross Profit / Gross Loss)
*   **Max Daily Drawdown**: $\le 3.0\%$ (Strict prop firm safety margin)
*   **Max Total Equity Drawdown**: $\le 6.0\%$
*   **Recovery Factor**: $\ge 3.0$ (Net Profit / Max Drawdown)
*   **Sharpe Ratio**: $\ge 1.8$ (Risk-adjusted returns)
*   **Average Win to Loss Ratio (R:R)**: $\ge 2.0$

---

## 5. Stress Testing & Monte Carlo Simulations

Before going live, the chosen settings profile will undergo stress testing:

1. **Spread Stressing**: Run backtests with a fixed simulated spread increased by 1.5x to 2x average spread.
2. **Slippage Stressing**: Verify that the EA remains profitable when entry slippage is introduced on market orders.
3. **Random Trade Dropout**: Randomly skip 10% of execution signals to ensure that overall profitability does not depend on a single "lucky" trade.
