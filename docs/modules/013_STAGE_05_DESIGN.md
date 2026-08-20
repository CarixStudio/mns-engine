# Module 013 Stage 5: Dashboard & Info Panel Design

This document describes the design specifications, layout math, object naming rules, and engine mappings for the graphical dashboard panel of the MNS Trading Engine Indicator.

---

## 1. Anchoring and Layout Coordinates

The dashboard panel is anchored to a configurable chart corner (default: `CORNER_RIGHT_UPPER`). 

### 1.1 Object Coordinate Offsets
For corner `CORNER_RIGHT_UPPER`:
- **Panel Top-Left (Relative to Corner)**: `(InpDashboardX, InpDashboardY)` from the right edge.
- **Background Container Size**: 
  - Width: `InpDashboardWidth` (default 250px)
  - Height: `14 * rowHeightDashboard + 2 * paddingDashboard` (default: `14 * 16 + 2 * 10 = 244px`)
- **Row Y Coordinate**:
  - `RowY(index) = InpDashboardY + paddingDashboard + (index * rowHeightDashboard)`
- **Label Name X (Left-Aligned)**:
  - `LabelX = InpDashboardX + paddingDashboard`
- **Label Value X (Right-Aligned)**:
  - `ValueX = InpDashboardX + InpDashboardWidth - paddingDashboard`
  - Anchor type: `ANCHOR_RIGHT_UPPER` (meaning the right edge of the text sits at `ValueX`).

---

## 2. Object Naming Convention

All graphical dashboard objects are prefixed with `"MNS_Dash_"` and use static unique identifiers to prevent chart cluttering:

| Object Type | Target Name | Description |
|---|---|---|
| `OBJ_RECTANGLE_LABEL` | `MNS_Dash_Bg` | Main background panel |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Header` | Header row left label |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Context` / `MNS_Dash_Val_Context` | Symbol and Timeframe context |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Trend` / `MNS_Dash_Val_Trend` | Trend row label and value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Phase` / `MNS_Dash_Val_Phase` | Market phase row label and value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Structure` / `MNS_Dash_Val_Structure` | Structure classification row label/value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_BOS` / `MNS_Dash_Val_BOS` | Last structural BOS row label/value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_CHoCH` / `MNS_Dash_Val_CHoCH` | Last structural CHoCH row label/value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Bias` / `MNS_Dash_Val_Bias` | Liquidity bias row label/value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_DOL` / `MNS_Dash_Val_DOL` | Active DOL price and type row label/value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_POI` / `MNS_Dash_Val_POI` | Closest active POI type/range row label/value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Zone` / `MNS_Dash_Val_Zone` | Dealing range zone (Prem/Disc/Eq) row label/value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Session` / `MNS_Dash_Val_Session` | Active trading session name(s) row label/value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Conf` / `MNS_Dash_Val_Conf` | Setup confirmation status row label/value |
| `OBJ_LABEL` | `MNS_Dash_Lbl_Entry` / `MNS_Dash_Val_Entry` | Opportunity entry signal row label/value |

---

## 3. Engine Output Mapping Rules

The dashboard displays 14 distinct rows, mapping directly to MNS engines:

| Row | Label Name | Engine Source | Mapping Heuristic / String Generation |
|---|---|---|---|
| **0** | `MNS ENGINE v1.0` | None | Header title (Bold font, Lime color) |
| **1** | `Symbol/TF` | Standard Symbol/Period | Format: `"[Symbol], [Timeframe]"` (e.g. `"GBPUSD, H1"`) |
| **2** | `Trend` | `CStructureEngine` | Bullish (Lime) / Bearish (Red) / Ranging (Orange) / Transition (Gold) / Unknown (Gray) |
| **3** | `Phase` | `CStructureEngine` | Trending / Pullback / Range / Transition / Unknown |
| **4** | `Structure` | `CStructureEngine` | `HH` / `HL` / `LH` / `LL` / `Equal High` / `Equal Low` / `None` |
| **5** | `Last BOS` | `CBreakDetector` | Direct query of latest BOS: e.g. `"Bullish @ 1.2704"` or `"None"` |
| **6** | `Last CHoCH` | `CBreakDetector` | Direct query of latest CHoCH: e.g. `"Bearish @ 1.2721"` or `"None"` |
| **7** | `Liq Bias` | `CObjectiveEngine` / `close[1]`| If active DOL is above price: `"Buy Side"`. If below: `"Sell Side"`. If no active DOL: `"Balanced"`. |
| **8** | `Active DOL` | `CObjectiveEngine` | If active: `"[price] ([TypeString])"` (e.g. `"1.2850 (Session High)"`). Else: `"None"`. |
| **9** | `Active POI` | `CPOIEngine` / `close[1]` | Closest active POI range: `"[TypeString] ([lower]-[upper])"` or `"None"`. |
| **10**| `DR Zone` | `CPOIEngine` / `close[1]` | `GetDealingRangeZone` rating: `"Premium"` / `"Discount"` / `"Equilibrium"` / `"None"` |
| **11**| `Session` | `gmtTime` | Tokyo (00-08), London (08-16), NY (13-21) GMT. Multiple print as `Tokyo/London` or `London/NY`. Else `"Closed"`. |
| **12**| `Confirmation` | `CConfirmationEngine` | `CONFIRMED (Bullish/Bearish)` / `PENDING` / `INVALIDATED` / `NONE` |
| **13**| `Entry` | `CEntryEngine` | `BUY TRIGGERED` / `SELL TRIGGERED` / `EXECUTED` / `EXPIRED` / `NONE` |
