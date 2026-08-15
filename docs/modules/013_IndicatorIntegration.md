# Module 013 — Indicator Integration (CIndicatorIntegration)

## 1. Purpose

The **Indicator Integration** module (`CIndicatorIntegration`) acts as the complete visual representation layer of the MNS Trading Engine. It consolidates the Renderer Framework, Visual Rendering Engine, Object Manager, Dashboard Panel, and Settings Integration. It operates strictly as a stateless visualizer: it reads the computed states from the core engines and maps them directly to MT5 chart objects, performing no analysis of its own.

## 2. Component Architecture

```
                                  +------------------------------------+
                                  |         MNS Trading Engine         |
                                  |  (Modules 001 - 012 Silent State)  |
                                  +------------------------------------+
                                                    │
                                                    │ Engine Data
                                                    ▼
+──────────────────────────────────────────────────────────────────────────────────────────────────+
| MODULE 013 — Indicator Integration                                                               |
|                                                                                                  |
|  +─────────────────────────+     +─────────────────────────+     +────────────────────────────+  |
|  |     Object Manager      |     |  Visual Render Engine   |     |    Dashboard Framework     |  |
|  | (Object cache & reuse)  | ──> | (Draw Swings/BOS/POIs)  | ──> | (Header/State/Session/Exits|  |
|  +─────────────────────────+     +─────────────────────────+     +────────────────────────────+  |
|                                                   │                                              |
+───────────────────────────────────────────────────┼──────────────────────────────────────────────+
                                                    │
                                                    ▼
                                  +------------------------------------+
                                  |         MetaTrader 5 Chart         |
                                  |       (Visual Representation)      |
                                  +------------------------------------+
```

### 2.1 Object Manager (Object Cache & Reuse)
- Responsible for creating, updating, and deleting MT5 chart objects.
- **Rule**: Never delete and recreate all chart objects on every tick (which causes severe flickering and CPU spikes).
- Implement an object cache (by tracking object names). Mark objects as active or inactive, and reuse inactive objects by moving/resizing them to match new states.

### 2.2 Visual Rendering Engine
- **Swing Points**: Draws high/low arrows (`OBJ_ARROW` or `OBJ_TEXT`) above/below candles.
- **Structure Breaks**: Draws horizontal trend lines (`OBJ_TREND`) for BOS (green/red) and CHoCH (orange).
- **Liquidity Pools**: Draws horizontal dashed lines (`OBJ_TREND`) for active BSL/SSL pools.
- **POIs**: Draws semi-transparent rectangles (`OBJ_RECTANGLE`) for Order Blocks and Fair Value Gaps (FVG).
- **Zones**: Draws transparent/dotted horizontal lines (`OBJ_TREND` or `OBJ_RECTANGLE`) representing Premium/Discount equilibrium zones.

### 2.3 Dashboard Framework
- Constructs a top-right pinned information dashboard using `OBJ_RECTANGLE_LABEL` (background panel) and `OBJ_LABEL` (text fields).
- Shows:
  - Header: `MNS ENGINE vX.Y`, current symbol, and timeframe.
  - Market State: Trend bias (Bullish/Bearish/Neutral/Transition) and Phase (Trending/Pullback/Range).
  - Structure: Last Break Type (BOS/CHoCH) and broken price levels.
  - Sizing & Risks: Current active POIs and pre-trade entry signals (SL, TP, volume size).
  - Sessions: Active session highlighting (Asia, London, NY, Overlaps).

### 2.4 Settings/UI Integration
- Maps inputs directly from the user parameters (via `INF-004 Configuration System`) to toggle options:
  - `ShowDashboard` (true/false)
  - `ShowSwings` (true/false)
  - `ShowBOS` / `ShowCHoCH` (true/false)
  - `ShowLiquidity` (true/false)
  - `ShowOrderBlocks` / `ShowFVG` (true/false)
  - `ShowPremiumDiscount` (true/false)
  - Colors and font size settings.

## 3. Rendering Performance Optimization (Using INF-007)

Using measurements provided by `INF-007 Performance Monitor`, the module optimizes rendering workflows by enforcing:
1. **New Bar Redraws**: Complete visual redraw of historical objects (like swing arrows or filled POIs) occurs ONLY on the arrival of a new bar.
2. **Tick Updates**: Intraday tick updates are restricted to updating the live bar (candle 0) and refreshing the text fields of the dashboard panel.
3. **Dirty-Flagging**: Only objects whose underlying state has changed are updated on the chart.
4. **Volume Limits**: Cap the maximum number of rendered historical structure lines (e.g. limit to last 20 BOS lines) to prevent chart lag.
