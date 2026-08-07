# Module Specification — INF-Deferred-UI: UI Infrastructure (Deferred)
# MNS Trading Engine
Version: 1.0
Status: Deferred (Pending Strategy Module Completion)

---

## 1. Overview

The UI Infrastructure manages visualization of the analysis engine outputs on MetaTrader 5 charts. These modules are documented now but **execution is deferred** until the core strategy engines are finalized.

To prevent performance lag and maintain architectural separation, the UI layer operates as a **unidirectional consumer** (it reads engine states but has zero analysis or strategy logic).

---

## 2. Deferred UI Modules

### 2.1 Renderer Framework
- **Purpose**: Defines the basic interfaces and contracts for visual chart renderers.
- **Responsibilities**:
  - Expose standardized rendering interface (`IMNSRenderer`).
  - Pass the complete market state object to rendering pipelines.
- **Interface**:
```cpp
class IMNSRenderer
{
public:
    virtual ~IMNSRenderer() {}
    virtual void Render(const MNS_MarketState &state) = 0;
    virtual void Clear() = 0;
};
```

### 2.2 Visual Rendering Engine
- **Purpose**: Implements concrete render classes for drawing market objects.
- **Responsibilities**:
  - `CSwingRenderer`: Draw swing high/low markers and labels.
  - `CStructureRenderer`: Draw BOS and CHoCH lines with appropriate label shifts.
  - `CZoneRenderer`: Highlight Order Blocks, Fair Value Gaps, and Premium/Discount ranges.

### 2.3 Object Manager
- **Purpose**: Controls direct MT5 chart object interactions, caching, and cleanup.
- **Responsibilities**:
  - Prevent object name collisions by generating unique, deterministic name hashes (e.g., `MNS_OBJ_<Timeframe>_<BarTime>_<Hash>`).
  - Pool and reuse chart objects (lines, rectangles, texts) to minimize memory allocation and chart flashing.
  - Ensure 100% cleanup of drawn objects on indicator deinitialization (`OnDeinit`).

### 2.4 Dashboard Framework
- **Purpose**: Manages layout and rendering of the on-chart text dashboard.
- **Responsibilities**:
  - Draw a floating or docked information grid.
  - Format status text (e.g., green for Bullish, red for Bearish).
  - Re-render UI text only when state values actually change (event-driven rendering).

### 2.5 Indicator UI & Settings Manager
- **Purpose**: Connects the end-user MT5 Inputs tab to the Core Engine configuration and toggle managers.
- **Responsibilities**:
  - Handle chart events (`OnChartEvent`) for interactive buttons.
  - Expose visual toggles (Show/Hide dashboard, colors, sizes, sessions).

---

## 3. Rendering Pipeline Flow

```
     [Engine State Update] (Triggered OnTick or OnCalculate)
               │
               ▼
       [Object Manager] (Checks cache & pools active visual models)
               │
      ┌────────┴────────┬─────────────────┐
      ▼                 ▼                 ▼
[Swing Renderer]   [Zone Renderer]   [Dashboard Renderer]
      │                 │                 │
      └────────┬────────┘                 │
               ▼                          ▼
      [Chart Draw Update]       [Dashboard Redraw]
               │                          │
               └────────┬─────────────────┘
                        ▼
                 [Chart Redraw]
```

---

## 4. Performance & Rendering Rules
- **No Full Redraws**: Renderers must update incrementally. Do not call `ObjectsDeleteAll` inside execution loops.
- **Wick vs Body Breaks**: Visual indicators must draw wicks and body breaks at exact candle boundaries using high-precision time values.
- **Zero Calculation**: Do not perform trend or swing math within renderer files.
