# Module 013 Stage 4: Advanced Zone Renderers Design

This document describes the design specifications, object naming convention, pipeline execution, and lifecycle-to-visual mapping for rendering POIs (Order Blocks, Breaker Blocks, Mitigation Blocks, FVGs), active delivery legs, and active DOL targets on MetaTrader 5 charts.

---

## 1. Object Naming Convention

All chart objects created in Stage 4 follow the MNS prefix convention:

| Category | Type / State | Object Type | Name Structure | Example | Description |
|---|---|---|---|---|---|
| **POI Zone** | `POI_OB_BULLISH` | `OBJ_RECTANGLE` | `MNS_POI_OBB_[id]` | `MNS_POI_OBB_12` | Bullish Order Block rectangle |
| **POI Zone** | `POI_OB_BEARISH` | `OBJ_RECTANGLE` | `MNS_POI_OBBe_[id]` | `MNS_POI_OBBe_7` | Bearish Order Block rectangle |
| **POI Zone** | `POI_BREAKER_BULLISH` | `OBJ_RECTANGLE` | `MNS_POI_BrkB_[id]` | `MNS_POI_BrkB_15` | Bullish Breaker Block rectangle |
| **POI Zone** | `POI_BREAKER_BEARISH` | `OBJ_RECTANGLE` | `MNS_POI_BrkBe_[id]` | `MNS_POI_BrkBe_22` | Bearish Breaker Block rectangle |
| **POI Zone** | `POI_MITIGATION_BULLISH`| `OBJ_RECTANGLE` | `MNS_POI_MBB_[id]` | `MNS_POI_MBB_8` | Bullish Mitigation Block rectangle |
| **POI Zone** | `POI_MITIGATION_BEARISH`| `OBJ_RECTANGLE` | `MNS_POI_MBBe_[id]` | `MNS_POI_MBBe_4` | Bearish Mitigation Block rectangle |
| **POI Zone** | `POI_FVG_BULLISH` | `OBJ_RECTANGLE` | `MNS_POI_FVGB_[id]` | `MNS_POI_FVGB_34` | Bullish FVG rectangle |
| **POI Zone** | `POI_FVG_BEARISH` | `OBJ_RECTANGLE` | `MNS_POI_FVGBe_[id]` | `MNS_POI_FVGBe_11` | Bearish FVG rectangle |
| **Delivery Leg**| `DELIVERY_ACTIVE` | `OBJ_TREND` | `MNS_Delivery_Leg` | `MNS_Delivery_Leg` | Single active delivery trend arrow-line |
| **DOL Target** | Active DOL price level | `OBJ_TREND` | `MNS_DOL_Target` | `MNS_DOL_Target` | Single active DOL bounded ray |
| **DOL Label**  | Active DOL price level | `OBJ_TEXT` | `MNS_DOL_Label` | `MNS_DOL_Label` | Accompanying text label at right edge |

---

## 2. Rendering Pipelines

### 2.1 POI Renderer (`CPOIRenderer::Draw`)
1. **Filtering**: Extract all POIs from `CPOIEngine` that are active or mitigated (i.e. `active == true || lifecycle == POI_STATE_PARTIAL_MITIGATED || lifecycle == POI_STATE_MATERIAL_MITIGATED`). Stale statuses (`FILLED`, `INVALIDATED`, `ARCHIVED`) are excluded.
2. **Sorting**: Sort the renderable POIs by `createdTime` ascending (oldest first).
3. **Capping**: Keep only the newest `MaxRenderedPOIs` (default 20) elements.
4. **Drawing**: Create or update rectangles extending from `createdTime` (left) to `time[1]` (right).
5. **Garbage Collection**: Construct names for all potential POI IDs (`0..127`) and delete their objects if not drawn this turn.

### 2.2 Delivery / DOL Target Renderer (`CDeliveryRenderer::Draw`)
1. **Delivery Leg**:
   - Check if `lifecycle == DELIVERY_ACTIVE` or `DELIVERY_MITIGATION_STARTED`.
   - If yes, create or update `MNS_Delivery_Leg` from `(originTime, originPrice)` to `(time[1], close[1])`.
   - If no, delete `MNS_Delivery_Leg`.
2. **DOL Target**:
   - Check if `dol.active == true` and `dol.score >= 60.0`.
   - If yes, create or update `MNS_DOL_Target` horizontal ray from `(dol.createdTime, dol.price)` to `(time[1], dol.price)` and create/update `MNS_DOL_Label` text at `(time[1], dol.price)`.
   - If no, delete both objects.

---

## 3. Lifecycle → Visual State Mapping

### 3.1 POIs
- `POI_STATE_ACTIVE`: Full color opacity (drawn behind candles using `OBJPROP_BACK = true`), normal border width (`widthPOIBorder`), solid line style.
- `POI_STATE_PARTIAL_MITIGATED` or `POI_STATE_MATERIAL_MITIGATED`: Dotted border (`STYLE_DOT`).
- `FILLED`, `INVALIDATED`, `ARCHIVED`: Deleted immediately.

### 3.2 Delivery Leg
- `DELIVERY_ACTIVE`: Thin solid trend line.
- `DELIVERY_MITIGATION_STARTED`: Thin dashed trend line (`STYLE_DASH`) to indicate the leg is under mitigation pressure.
- `DELIVERY_INVALIDATED`, `DELIVERY_REPLACED`, `DELIVERY_ARCHIVED`: Deleted immediately.
