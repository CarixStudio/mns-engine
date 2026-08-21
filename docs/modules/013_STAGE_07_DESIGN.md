# MNS Trading Engine — Module 013
# Stage 7: Session Renderers & Premium/Discount Zones Design Document

## 1. Overview
This document specifies the design of two new visual modules under **Module 013 Indicator Integration**:
1.  **Premium & Discount Zones**: Visualizes cheap (discount) and expensive (premium) pricing zones based on the current active dealing range, separated by an Equilibrium midpoint line.
2.  **Session Shading Bands**: Renders vertical, desaturated background columns to segment trading days into distinct session blocks (Asia, London, NY, and London/NY overlap hours) using GMT.

---

## 2. Style tokens Customizations

Visual color tokens are extended in `SIndicatorStyle` inside [Include/MNS/MNSStyle.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSStyle.mqh) using desaturated, low-brightness values to maintain high contrast with candlestick wicks:

| Style Field | Token Purpose | Default Color Code |
| :--- | :--- | :--- |
| `colorZonePremium` | Premium zone background fill | `C'0x2F, 0x0A, 0x0A'` (Dark Red) |
| `colorZoneDiscount` | Discount zone background fill | `C'0x0A, 0x2A, 0x14'` (Dark Green) |
| `colorZoneEquilibrium` | Equilibrium line color | `clrGray` |
| `styleZoneEq` | Equilibrium line style | `STYLE_DASH` |
| `colorSessionAsia` | Asia session vertical shading | `C'0x05, 0x05, 0x1F'` (Dark Blue-Gray) |
| `colorSessionLondon` | London-only vertical shading | `C'0x05, 0x1F, 0x05'` (Dark Green-Gray) |
| `colorSessionNY` | NY-only vertical shading | `C'0x1F, 0x14, 0x05'` (Dark Orange-Gray) |
| `colorSessionOverlap` | London/NY overlap vertical shading | `C'0x1F, 0x05, 0x1F'` (Dark Purple-Gray) |

---

## 3. Configuration & Parameter Validation

New settings are added to `SEngineConfig` inside [Include/MNS/MNSConfig.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSConfig.mqh) and validated dynamically inside `CMNSConfig::UpdateParameter()`:

| Parameter Name | Data Type | Range Bounds | Default Value | Validation Behavior |
| :--- | :--- | :--- | :--- | :--- |
| `showZonePremium` | `bool` | `Any double` | `true` | Boolean check (val != 0.0) |
| `showZoneDiscount` | `bool` | `Any double` | `true` | Boolean check (val != 0.0) |
| `showZoneEquilibrium`| `bool` | `Any double` | `true` | Boolean check (val != 0.0) |
| `showSessions` | `bool` | `Any double` | `true` | Boolean check (val != 0.0) |
| `maxRenderedSessions`| `int` | `[3 .. 60]` | `15` | Fail on range violation |

---

## 4. Premium / Discount Zone Drawing Logic

The Premium & Discount Zones Renderer (`CZoneRenderer.mqh`) determines the active dealing range by querying the latest confirmed external swing points from `CSwingDetector`:

```mql5
SSwingPoint extHigh = swingDetector.GetLatestExternalHigh();
SSwingPoint extLow  = swingDetector.GetLatestExternalLow();
```

### Price and Time Anchors
If both swing points are confirmed, drawing anchors are computed as follows:
*   **High Price (Upper Bound)**: `highPrice = extHigh.price`
*   **Low Price (Lower Bound)**: `lowPrice = extLow.price`
*   **Equilibrium (Midpoint)**: `eqPrice = (highPrice + lowPrice) / 2.0`
*   **Start Time (Left Anchor)**: `startTime = MathMin(extHigh.time, extLow.time)`
*   **End Time (Right Anchor)**: `endTime = time[1]` (last completed bar time)

### Graphic Objects Layout

```
                        [startTime]                             [endTime]
High Boundary   --------*=======================================*-------- (highPrice)
                        |                                       |
  Premium Zone          |        MNS_Zone_Premium (Red Fill)    |
                        |                                       |
Equilibrium     --------*---------------------------------------*-------- (eqPrice)
                        |                                       |
  Discount Zone         |        MNS_Zone_Discount (Green Fill) |
                        |                                       |
Low Boundary    --------*=======================================*-------- (lowPrice)
```

1.  **`MNS_Zone_Premium`** (Rectangle): `(startTime, highPrice)` to `(endTime, eqPrice)`. Settings: `OBJPROP_FILL = true`, `OBJPROP_BACK = true`, using color `colorZonePremium`.
2.  **`MNS_Zone_Discount`** (Rectangle): `(startTime, eqPrice)` to `(endTime, lowPrice)`. Settings: `OBJPROP_FILL = true`, `OBJPROP_BACK = true`, using color `colorZoneDiscount`.
3.  **`MNS_Zone_Equilibrium`** (Trend Line): `(startTime, eqPrice)` to `(endTime, eqPrice)`. Settings: `OBJPROP_RAY_RIGHT = false`, width 1, style `styleZoneEq`, using color `colorZoneEquilibrium`.

If either swing point expires, changes, or becomes unconfirmed, the objects are immediately deleted to avoid drawing invalid ranges.

---

## 5. Non-Overlapping GMT Session Segmentation

To prevent overlapping visual glitches and render distinct shading blocks, the trading day is sliced into **four non-overlapping segments** in GMT:

1.  **Asia**: `00:00 <= hour < 08:00` GMT ➔ Titled `"Asia"`, color `colorSessionAsia`
2.  **London-Only**: `08:00 <= hour < 13:00` GMT ➔ Titled `"Lon"`, color `colorSessionLondon`
3.  **London/NY Overlap**: `13:00 <= hour < 16:00` GMT ➔ Titled `"Overlap"`, color `colorSessionOverlap`
4.  **NY-Only**: `16:00 <= hour < 21:00` GMT ➔ Titled `"NY"`, color `colorSessionNY`
5.  **Off-hours (Closed)**: `21:00 <= hour < 24:00` GMT ➔ No background shading.

### Run-Length Grouping & Gap Detection
`CSessionRenderer` scans historical bar times from oldest (`limitBars-1`) to newest (`0`) and accumulates bars of the same session type. A session block is finalized and drawn as a vertical rectangle when:
*   The evaluated session type changes from the active block.
*   A time gap exceeding `PeriodSeconds() * 1.5` occurs (e.g. weekend close), preventing the shading block from stretching across the weekend gap.

### Object Capping
The most recent `maxRenderedSessions` daily session blocks are kept on the chart. Older session rectangles exceeding this limit are automatically deleted during the update scan. All session objects are cleaned up on deinitialization or timeframe switch.

---

## 6. Indicator Dashboard Extensions

To improve client scanning visibility and explicitly highlight trade parameters, the dashboard panel (`CDashboardRenderer.mqh`) has been extended from 13 to 15 visual rows:

### Layout Alterations
*   **TP (Take Profit) Label**: The row label `Active DOL:` was renamed to `TP (DOL Target):` to explicitly present the Take Profit level.
*   **Entry Signal Label**: The row label `Entry:` was renamed to `Entry Signal:` to differentiate the trigger state from price values.
*   **New Entry Price Row**: Added `Entry Price:` row representing the exact fill level of the entry setup confirmation close.
*   **New SL Price Row**: Added `SL (Stop Loss):` row representing the calculated structural invalidation boundary.

### Row Mapping Updates
| Field Name | Source Engine Variable | Default Value | Value Color Mapping |
| :--- | :--- | :--- | :--- |
| `TP (DOL Target)` | `objectiveEngine.GetActiveDol().price` | `None` | Gold / Orange (`colorDOL` token) |
| `Entry Signal` | `entryEngine.GetActiveSignalState()` | `None` | Lime Green (Buy) / Red (Sell) / Gray (None) |
| `Entry Price` | `entryEngine.GetActiveSignal().entryPrice` | `None` | White (Active/Executed) / Gray (None) |
| `SL (Stop Loss)` | `entryEngine.GetActiveSignal().stopLoss` | `None` | Orange-Red (Active/Executed) / Gray (None) |
