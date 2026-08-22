Yes. Based on everything we've built and the client's instructions, here's the end-to-end roadmap.

---

# Phase 0 — Foundation ✅

This is where we are now.

* ✅ Repository created
* ✅ Documentation organized
* ✅ Module 001 — MNSTypes
* ✅ Test Harness
* ✅ Build scripts
* ✅ Development workflow
* ✅ TODO strategy tracker

Nothing here actually analyzes the market yet.

---

# Phase 1 — Build the Engine

This is the largest phase.

Each module follows exactly the same workflow:

1. Write module specification
2. Generate production code
3. Compile
4. Fix compile errors
5. Update test harness
6. Validate
7. Commit
8. Update TODO strategy tracker
9. Move to next module

---

## Module 001

MNSTypes

Already done.

---

## Module 002

Swing Detector

Current module.

Produces

```
SSwingPoint
```

Nothing else can exist without swings.

---

## Module 003

Structure Engine

Consumes swings.

Determines

```
HH
HL
LH
LL
```

Outputs

```
Market Structure
```

---

## Module 004

Break Engine

Consumes structure.

Finds

```
BOS

CHoCH

Internal BOS
```

---

# Shared Infrastructure Layer (Active)

We have paused development of the strategy modules due to outstanding client ambiguities. We are implementing the Shared Infrastructure layer immediately. All UI and rendering responsibilities are deferred and fully consolidated under Module 013 and Module 014 to eliminate duplicated architectural ownership.

### Core Infrastructure Modules
- [x] **INF-000 — Core Module** (`MNSCore.mqh`) — Success/error codes, global constants, and assertions.
- [x] **INF-001 — Logging System** (`MNSLogger.mqh`) — Level-filtered log outputs and target routing.
- [x] **INF-002 — Utility Library** (`MNSUtils.mqh`) — Pure math operations, session hours, and array helper functions.
- [x] **INF-003 — ATR Helper** (`MNSVolatility.mqh`) — Volatility calculations operating directly on price arrays.
- [x] **INF-004 — Configuration System** (`MNSConfig.mqh`) — Settings profiles and input validation boundaries.
- [x] **INF-005 — Serialization** (`MNSSerializer.mqh`) — Standard interfaces for object archiving to disk.
- [x] **INF-006 — Testing Framework** (`MNSTestSuite.mqh`) — Testing assertions and mock structures.
- [x] **INF-007 — Performance Monitor** (`MNSProfiler.mqh`) — Telemetry profiling and microsecond metrics.

---

## Module 005 ✅

Order Flow Engine (COrderFlowEngine)

Consumes market structure. Evaluates order flow state.

Status: Completed.
Tagged: v0.0.5

---

## Module 006 ✅

Delivery Structure Engine (CDeliveryStructureEngine)

Consumes order flow. Evaluates delivery structure.

Status: Completed.
Tagged: v0.0.6

---

## Module 007 ✅

Liquidity Engine (CLiquidityEngine)

Identifies liquidity in the market (Draw on Liquidity / DOL).

Status: Completed. All tests passing.
Tagged: v0.0.7

## Module 008 ✅

POI Engine (CPOIEngine)

Points of Interest detection (Order Blocks, Breaker Blocks, FVG, etc.).

Status: Completed. All tests passing.

---

## Module 009 ✅

Objective Engine (CObjectiveEngine)

Calculates market objectives.

Status: Completed. All tests passing.

---

## Module 010 ✅

Confirmation Engine (CConfirmationEngine)

Detects entry confirmations.

Status: Completed. All tests passing.

---

## Module 011 ✅

Entry Engine (CEntryEngine)

Identifies entry opportunities.

Status: Completed. All tests passing.
Tagged: v0.0.11

---

## Module 012 ✅

Risk Engine (CRiskEngine)

Calculates trade risk parameters.

Status: Completed. All tests passing.
Tagged: v0.0.12

---

## Module 013

Indicator Integration (CIndicatorIntegration)

First time the engine outputs are visible on a chart. Consolidates all visualization, chart rendering, Object Manager, dashboard layout, and user-facing settings UI (built on top of INF-004 Configuration System).

| Stage | Description | Status |
|---|---|---|
| Stage 0 | Architecture & Dependency Audit | ✅ Complete |
| Stage 1 | Indicator Shell & Lifecycle Coordinator | ✅ Complete — 0 errors, 0 warnings. All 11 engines initialized on GBPUSD H1. |
| Stage 2 | Swing Point & Structure Renderers | ✅ Complete — Swing arrows and BOS/CHoCH lines rendering live on chart. 0 errors, 0 warnings. |
| Stage 3 | Liquidity Pool Renderers (BSL/SSL/EQH/EQL) | ✅ Complete — Active BSL/SSL and EQH/EQL levels rendering on chart with capping and clean state transitions. |
| **Stage 4** | **Advanced Zone Renderers (OB/FVG/Delivery/DOL)** | ✅ **Complete** — OB, Breaker, MB, FVG zones rendering as filled rectangles with lifecycle transitions; active delivery leg and DOL targets rendering cleanly. |
| Stage 5 | Dashboard & Info Panel | ✅ Complete — Stacked vertical info panel displaying active states from all 11 core engines in real time. |
| Stage 6 | Configuration Binding (INF-004 integration) | ✅ Complete — Centralized dynamic loading from config profiles, bound to MT5 inputs, all 11 engines and renderers synced. |
| Stage 7 | Session Renderers & Premium/Discount Zones | ✅ Complete — Session shading bands and Premium/Discount zones rendering live. 0 errors, 0 warnings. |
| Stage 8 | Visual Performance Profiling | ✅ Complete |
| Stage 9 | Integration Testing | ⬜ Pending |
| Stage 10 | Production Build & Release | ⬜ Pending |

### Stage 4 Deliverables
- `Include/MNS/MNSStyle.mqh` — Updated with POI, Delivery, and DOL visual style tokens
- `Include/MNS/Renderers/CPOIRenderer.mqh` — POI zone visual renderer (OB/Breaker/Mitigation/FVG)
- `Include/MNS/Renderers/CDeliveryRenderer.mqh` — Active delivery leg and DOL visual renderer
- `Indicators/MNS_Indicator.mq5` — Updated coordinator to instantiate and call Stage 4 renderers
- `docs/modules/013_STAGE_04_DESIGN.md` — Stage 4 detailed design specifications

### Stage 5 Deliverables
- `Include/MNS/MNSStyle.mqh` — Updated with dashboard styling variables and default theme values
- `Include/MNS/Renderers/CDashboardRenderer.mqh` — Visual status dashboard renderer
- `Indicators/MNS_Indicator.mq5` — Updated coordinator to instantiate and call CDashboardRenderer
- `docs/modules/013_STAGE_05_DESIGN.md` — Stage 5 detailed design specifications

### Stage 6 Deliverables
- `Include/MNS/MNSConfig.mqh` — Extended `SEngineConfig`, updated `SetDefaults()`, and validation bounds in `UpdateParameter()`
- `Include/MNS/Renderers/CDashboardRenderer.mqh` — Bound layout positioning, visibility, and sizing metrics to config
- `Indicators/MNS_Indicator.mq5` — Implemented sequential loading (`SetDefaults` -> `LoadFromFile` -> Sync inputs -> Retrieve cfg) in `OnInit()`, updated dashboard checking in `OnCalculate()`
- `docs/modules/013_STAGE_06_DESIGN.md` — Stage 6 detailed design specifications

### Stage 7 Deliverables
- `Include/MNS/MNSStyle.mqh` — Extended `SIndicatorStyle` with zone and session styling tokens and default desaturated tints
- `Include/MNS/MNSConfig.mqh` — Extended `SEngineConfig` with visibility switches, validation rules, and capping parameters
- `Include/MNS/Renderers/CZoneRenderer.mqh` — Visual renderer drawing Premium/Discount filled rectangles and Equilibrium midpoint trend line anchored by external swings
- `Include/MNS/Renderers/CSessionRenderer.mqh` — Visual renderer drawing vertical session shading bands with run-length grouping, weekend stretching protection, and capping limits
- `Indicators/MNS_Indicator.mq5` — Updated coordinator to register new inputs, sync settings to config, and execute new renderers
- `docs/modules/013_STAGE_07_DESIGN.md` — Stage 7 detailed design specifications

### Stage 8 Deliverables
- `docs/modules/013_STAGE_08_DESIGN.md` — Stage 8 detailed design specifications
- `Indicators/MNS_Indicator.mq5` — Integrated performance telemetry wrappers and wired Stage 7 renderers



## Module 014

EA Integration (CEAIntegration)

Expert Advisor integration, order execution, position controls, and interactive EA trading dashboard.

---

# Phase 2 — Testing

Now you don't write new features.

You test.

For weeks if necessary.

You compare

```
Indicator

↓

Manual chart analysis

↓

Strategy document

↓

Expected result
```

Find bugs.

Fix bugs.

Repeat.

---

# Phase 3 — Freeze the Engine

Once the indicator behaves exactly like the strategy,

freeze it.

No new features.

Only bug fixes.

---

# Phase 4 — Build the EA

Now the easy part.

The EA should contain **almost no analysis logic** because you've already built and validated that in the engine.

It simply asks the engine:

```
Trend?

Bullish.

Entry?

Yes.

SL?

1.0875

TP?

1.0940

Risk?

1%

Execute.
```

The EA becomes mostly:

* order execution
* position management
* broker communication
* money management

Typically, an EA is much smaller than the engine because it's reusing the validated modules.

---

# Phase 5 — EA Dashboard

Add controls like:

```
Auto Trading ON

Risk 1%

Current Pair

Spread

Open Trades

Profit Today

Daily DD

News Filter

Session

Status
```

This dashboard is interactive because it's an Expert Advisor.

# Phase 6 — EA Testing & Backtesting

This is the phase where we validate the strategy's historical profitability and risk tolerance before deploying to a live account.

### Step 6.1 — Historical Backtesting
*   **When**: Immediately after completing Module 014 (EA Dashboard).
*   **Platform**: MetaTrader 5 Strategy Tester.
*   **Data Quality**: Every Tick based on real ticks (99.9% modeling quality).
*   **Timeframes**: GBPUSD H1 and M5 charts.
*   **Historical Range**: 3-year lookback (2023 - 2026) to test performance in different market conditions (trending, ranging, high-volatility news events).
*   **Method**: 
    1. Run the EA with the centralized `.ini` settings files.
    2. Optimize parameters (e.g., ATR multipliers, POI scores, risk sizes) using MT5's genetic optimization algorithm.

### Step 6.2 — Backtesting Performance Metrics
We will analyze the backtest results using the following criteria:
*   **Net Profit & Profit Factor**: Profit factor must be > 1.5.
*   **Max Drawdown**: Absolute drawdown must be kept below 5% (to comply with prop firm limits).
*   **Recovery Factor**: Ability of the strategy to recover from drawdown periods.
*   **Win Rate & Average R:R**: Verify that average winning trade is $\ge$ 1.5 times the average losing trade.

### Step 6.3 — Forward Testing & Demo Deployment
*   **Forward Testing**: Run the EA in the Strategy Tester on out-of-sample data (unseen price periods) to verify it wasn't curve-fitted.
*   **Demo Trading**: Attach the EA to a live Demo account (MetaQuotes-Demo) to trade in real-time forward conditions for 2–4 weeks.
*   **Live Deployment**: Move to a live account only after demo results match the backtesting model.

---

# Phase 7 — Release

Produce:

* Final Indicator
* Final EA
* Documentation
* User Guide
* Changelog
* Version 1.0 release

---

## The complete roadmap

```
Repository
      │
      ▼
Module 001
      │
      ▼
Module 002
      │
      ▼
...
      │
      ▼
Module 014
      │
      ▼
Indicator Complete
      │
      ▼
Testing & Validation
      │
      ▼
Engine Freeze
      │
      ▼
Build EA
      │
      ▼
EA Dashboard
      │
      ▼
Backtesting
      │
      ▼
Forward Testing
      │
      ▼
Production Release
```

This sequence aligns with the client's instruction: **build and validate the indicator first**, then use that proven analysis engine as the foundation for the EA. That minimizes the risk of debugging trading logic and execution logic at the same time.
