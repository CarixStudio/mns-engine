# MNS Trading Engine
# Development Roadmap
Version: 2.0
Status: Active

---

# Vision

Build a production-grade, deterministic Smart Money trading framework
through incremental, module-by-module development.

Each module must be specified, implemented, compiled, tested, and
committed before the next module begins.

No module may be skipped.

The Indicator is delivered and validated first.
The EA is built only after the Indicator is approved.

---

# Phase 0 — Foundation ✅

Establish the engineering foundation.

### Deliverables

- ✅ Repository
- ✅ Folder structure
- ✅ PRD
- ✅ Architecture
- ✅ Class diagram
- ✅ Coding standards
- ✅ Development workflow
- ✅ Testing strategy
- ✅ Build and deploy scripts
- ✅ Strategy ambiguity tracker (TODO_STRATEGY.md)

### Exit Criteria

- Documentation complete.
- Repository organized.
- Development workflow approved.
- Build pipeline operational.

Nothing in Phase 0 analyzes the market.

---

# Phase 1 — Build the Engine

Each module follows this exact workflow:

```
1. Write module specification
2. Write algorithm document
3. Write API document
4. Implement production code
5. Run build script
6. Compile in MetaEditor (0 errors, 0 warnings)
7. Extend test harness
8. Validate in MetaTrader
9. Commit to source control
10. Update roadmap status
```

---

## Module 001 — MNSTypes ✅

Shared data models.

Produces:
- Enumerations
- Structures
- Shared constants

---

## Module 002 — CSwingDetector ✅ (In Progress)

Swing detection. Single source of truth for all swing analysis.

Produces:
- External swing highs and lows (15-candle depth)
- Internal swing highs and lows (5-candle depth)

Status: Compiled. Test harness passing.
Pending: Strategy ambiguities OPEN-001 to OPEN-004 must be resolved
         before IsSwingHigh() and IsSwingLow() can be finalized.
         See docs/TODO_STRATEGY.md.

---

## Module 003 — CStructureEngine ✅

Consumes swings. Classifies market structure.

Produces:
- HH (Higher High)
- HL (Higher Low)
- LH (Lower High)
- LL (Lower Low)
- EQH (Equal High)
- EQL (Equal Low)
- Trend state
- Market phase

Status: Completed. All 75 tests passing.
Tagged: v0.0.3

---

## Module 004 — CBreakDetector ✅

Consumes structure. Detects structural breaks.

Produces:
- BOS (Break of Structure)
- iBOS (Internal Break of Structure)
- CHoCH (Change of Character)

Status: Completed. All 87 tests passing.
Tagged: v0.0.4

---

# Shared Infrastructure Layer (Active)

We have paused development of the strategy modules due to outstanding client ambiguities. We are implementing the Shared Infrastructure layer (Phase A) immediately, while UI Infrastructure (Phase B) is deferred.

### Phase A — Core Infrastructure
- [x] **INF-000 — Core Module** (`MNSCore.mqh`) — Success/error codes, global constants, and assertions.
- [ ] **INF-001 — Logging System** (`MNSLogger.mqh`) — Level-filtered log outputs and target routing.
- [ ] **INF-002 — Utility Library** (`MNSUtils.mqh`) — Pure math operations, session hours, and array helper functions.
- [ ] **INF-003 — ATR Helper** (`MNSVolatility.mqh`) — Volatility calculations operating directly on price arrays.
- [ ] **INF-004 — Configuration System** (`MNSConfig.mqh`) — Settings profiles and input validation boundaries.
- [ ] **INF-005 — Serialization** (`MNSSerializer.mqh`) — Standard interfaces for object archiving to disk.
- [ ] **INF-006 — Testing Framework** (`MNSTestSuite.mqh`) — Testing assertions and mock structures.
- [ ] **INF-007 — Performance Monitor** (`MNSProfiler.mqh`) — Telemetry profiling and microsecond metrics.

---

## Module 005 — COrderFlowEngine

Consumes market structure. Evaluates order flow state.

Produces:
- Order Flow state

---

## Module 006 — CDeliveryStructureEngine

Consumes order flow. Evaluates delivery structure.

Produces:
- Delivery state

---

## Module 007 — CLiquidityEngine

Identifies liquidity in the market (Draw on Liquidity / DOL).

Produces:
- Equal Highs (EQH)
- Equal Lows (EQL)
- Liquidity pools
- Liquidity sweeps / grabs

---

## Module 008 — CPOIEngine

Points of Interest detection.

Produces:
- Order Blocks
- Breaker Blocks
- Mitigation Blocks
- Fair Value Gaps (FVG)
- Inverse Fair Value Gaps (IFVG)
- Supply zones
- Demand zones

---

## Module 009 — CObjectiveEngine

Calculates market objectives.

---

## Module 010 — CConfirmationEngine

Detects entry confirmations.

---

## Module 011 — CEntryEngine

Identifies entry opportunities.

Produces:
- Entry models
- Confirmation signals
- Trigger candle detection

---

## Module 012 — CRiskEngine

Calculates trade risk parameters.

Produces:
- Stop Loss level
- Take Profit level
- Risk/Reward ratio
- Position size

---

## Module 013 — CIndicatorIntegration

First time the engine outputs are visible on a chart.
Connects all engine modules to the rendering layer.

---

## Module 014 — CEAIntegration

Expert Advisor integration and trade execution.

---

# Phase 2 — Testing and Validation

Do not write new features during this phase.

Activities:
- Compare indicator output against manual chart analysis
- Compare against strategy document rules
- Find discrepancies
- Fix discrepancies
- Repeat until indicator matches strategy exactly

Duration: As long as required. Weeks if necessary.

---

# Phase 3 — Engine Freeze

Once the Indicator behaves exactly as specified:

- Freeze the engine.
- No new analytical features after this point.
- Only bug fixes permitted.

This is the gate before EA development begins.

---

# Phase 4 — Expert Advisor

The EA contains almost no analysis logic.
All analysis is delegated to the frozen engine.

The EA asks the engine:

```
Trend?      → Bullish
Entry?      → Yes
SL?         → 1.0875
TP?         → 1.0940
Risk?       → 1%
→ Execute.
```

The EA is responsible for:
- Order execution
- Position management
- Broker communication
- Money management

---

# Phase 5 — EA Dashboard

Interactive on-chart panel.

Displays:
- Auto Trading ON/OFF
- Risk percentage
- Current symbol
- Spread
- Open trades
- Today's profit
- Daily drawdown
- News filter status
- Session status

---

# Phase 6 — EA Testing

- Strategy Tester (backtest)
- Forward test on demo account
- Live account (minimum risk)
- Fix issues until stable

---

# Phase 7 — Production Release

Final deliverables:

- MNSIndicator.mq5 (final)
- MNSEA.mq5 (final)
- User documentation
- Changelog
- Version 1.0

---

# Complete Build Sequence

```
Repository
      │
      ▼
Module 001 — MNSTypes
      │
      ▼
Module 002 — CSwingDetector
      │
      ▼
Module 003 — CStructureEngine
      │
      ▼
Module 004 — CBreakDetector
      │
      ▼
Module 005 — COrderFlowEngine
      │
      ▼
Module 006 — CDeliveryStructureEngine
      │
      ▼
Module 007 — CLiquidityEngine
      │
      ▼
Module 008 — CPOIEngine
      │
      ▼
Module 009 — CObjectiveEngine
      │
      ▼
Module 010 — CConfirmationEngine
      │
      ▼
Module 011 — CEntryEngine
      │
      ▼
Module 012 — CRiskEngine
      │
      ▼
Module 013 — CIndicatorIntegration
      │
      ▼
Module 014 — CEAIntegration
      │
      ▼
Testing and Validation
      │
      ▼
Engine Freeze
      │
      ▼
Expert Advisor
      │
      ▼
EA Dashboard
      │
      ▼
EA Testing
      │
      ▼
Production Release
```

---

# Release Criteria

The MNS Trading Engine is ready for release when:

- All modules compile with zero errors and zero warnings.
- All test harness assertions pass.
- Indicator output matches strategy documentation exactly.
- No repainting of confirmed structures.
- Engine outputs are deterministic.
- Documentation is complete and current.
- All source control commits are clean.