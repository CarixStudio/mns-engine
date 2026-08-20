# MNS Trading Engine — Module 013
# Stage 3: Liquidity Pool Renderers
# AI Implementation Prompt

Version: 1.0
Status: READY — Stage 2 Complete. Begin Stage 3.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:

1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `mns-answers1.md` — Locked client decisions (38 strategy rules, formally approved).
4. `mns-answers2.md` — Final client decisions (CLIENT-Q001, CLIENT-Q002, CLIENT-Q003).
5. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
6. `Include/MNS/MNSTypes.mqh` — All shared data structures (`SLiquidityPool`, `SSwingPoint`, etc.).
7. `Include/MNS/MNSUtils.mqh` — Utility functions.
8. `Include/MNS/MNSLogger.mqh` — Logging infrastructure.
9. `Include/MNS/MNSStyle.mqh` — Centralized visual style tokens (`SIndicatorStyle`). ← NEW in Stage 2.
10. `Include/MNS/CSwingDetector.mqh` — Module 002: swing data source.
11. `Include/MNS/CStructureEngine.mqh` — Module 003: market structure source.
12. `Include/MNS/CBreakDetector.mqh` — Module 004: BOS/CHoCH source.
13. `Include/MNS/COrderFlowEngine.mqh` — Module 005: order flow state.
14. `Include/MNS/CDeliveryStructureEngine.mqh` — Module 006: active delivery state.
15. `Include/MNS/CLiquidityEngine.mqh` — Module 007: **primary data source for Stage 3**.
16. `Include/MNS/CPOIEngine.mqh` — Module 008: POI source.
17. `Include/MNS/CObjectiveEngine.mqh` — Module 009: DOL/objective source.
18. `Include/MNS/CConfirmationEngine.mqh` — Module 010: confirmation signals.
19. `Include/MNS/CEntryEngine.mqh` — Module 011: entry signals.
20. `Include/MNS/CRiskEngine.mqh` — Module 012: risk sizing.
21. `Include/MNS/Renderers/CSwingRenderer.mqh` — Stage 2 renderer (reference pattern).
22. `Include/MNS/Renderers/CStructureRenderer.mqh` — Stage 2 renderer (reference pattern).
23. `Indicators/MNS_Indicator.mq5` — Stage 1+2 shell (coordinator — read before modifying).
24. `docs/modules/013_IndicatorIntegration.md` — Module 013 functional specification.
25. `docs/modules/013_ALGORITHM.md` — Module 013 algorithm.
26. `docs/INDICATOR_SPECIFICATION.md` — Approved visual inventory.
27. `docs/indicator/UI_UX_SPECIFICATION.md` — Approved UI/UX specification.
28. `docs/modules/013_ISSUES.md` — Open issue register (read before writing any code).
29. `docs/DEFERRED.md` — Global deferred items register.
30. `docs/CLASS_DIAGRAM.md` — Design blueprint.
31. `docs/CodingStandards.md` — Coding and style guide.
32. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.

---

## ABSOLUTE RULES (Inherited from PROMPT_NEW_MODULE.md)

1. Never invent trading logic.
2. Never substitute generic SMC/ICT algorithms.
3. Every visual element must be traceable to a `CLiquidityEngine` output or locked client decision.
4. If a strategy rule is ambiguous — document it. Do NOT guess.
5. Distinguish clearly:
   - ✅ **Specified** — directly stated in strategy or locked client decision
   - ⚠️ **Inferred** — reasonable engineering inference
   - ❌ **Unknown / TODO** — not covered, do not implement
6. Write production-quality MQL5 for long-term maintenance.
7. Comment every public class and method.
8. Preserve consistency with Stage 1 and Stage 2 (`MNS_Indicator.mq5`, `CSwingRenderer.mqh`, `CStructureRenderer.mqh`).
9. **Never modify `MNS_Indicator.mq5`** except to add one `#include`, one global renderer instance, one `Initialize()` call in `OnInit()`, one `Draw()` call at the end of `OnCalculate()`, and one `Reset()` call in `OnDeinit()`.
10. Never modify core engine headers (`CSwingDetector.mqh` through `CRiskEngine.mqh`).
11. Never modify Stage 2 renderer files (`CSwingRenderer.mqh`, `CStructureRenderer.mqh`).
12. Static arrays must use `#define` or literals — never `const int`.
13. No broker API / trading calls anywhere in the indicator layer.
14. No O(N²) loops. Object creation is O(N) worst case per update — use pool `id` or `createdTime` as the unique object name key, not a scan.

---

## STAGE 2 STATUS — COMPLETE ✅

Stage 2 (`CSwingRenderer.mqh`, `CStructureRenderer.mqh`, `MNSStyle.mqh`) is done and passing.

**Build result:**
- `MNS_Indicator.mq5`: 0 errors, 0 warnings
- Tag: `v0.13.2`
- Runtime: Swing arrows and BOS/CHoCH lines rendering live on GBPUSD H1

**What Stage 2 produced (DO NOT modify these):**
- `Include/MNS/MNSStyle.mqh` — `SIndicatorStyle` struct with all visual tokens.
- `Include/MNS/Renderers/CSwingRenderer.mqh` — External + internal swing arrows.
- `Include/MNS/Renderers/CStructureRenderer.mqh` — BOS / iBOS / CHoCH trend lines + text labels.

---

## LOCKED CLIENT DECISIONS (from mns-answers1.md & mns-answers2.md)

All of the following are formally approved and must NOT be questioned or reopened:

### CLIENT-Q001 — CRT / IRL / ERL ← RESOLVED
**DECISION: OMIT as separate strategy concepts.**
- Do NOT create new engine fields or renderer classes for CRT, IRL, or ERL.
- Liquidity is rendered using `CLiquidityEngine` outputs only:
  - BSL (Buy-Side Liquidity) = `LIQUIDITY_BSL` pools above highs
  - SSL (Sell-Side Liquidity) = `LIQUIDITY_SSL` pools below lows
  - EQH / EQL = Equal pivots detected by `CLiquidityEngine` (`LIQ_SRC_EQ` source)

### CLIENT-Q002 — Historical Delivery / Objective Rendering ← RESOLVED
**DECISION: ACTIVE ONLY — no historical rendering.**
- Not relevant to Stage 3 liquidity renderer.

### CLIENT-Q003 — Core Engine Heuristics (ALL LOCKED)
| Rule | Locked Value |
|---|---|
| Session Filter | OFF by default (`UseSessionFilter = false`) |
| Liquidity buffer | 128 records (`SLiquidityPool m_pools[128]`) — already in `CLiquidityEngine` |
| EQH/EQL Tolerance | `max(3 × Point, 0.10 × ATR(14))` — already in `CLiquidityEngine` |
| Internal Swings Depth | 5 each side |
| External Swings Depth | 15 each side |
| MinimumBreakDistance | `max(2 × Point, 0.10 × ATR(14))` |

---

## STAGE 3 OBJECTIVE

Implement the liquidity pool visual rendering layer for `MNS_Indicator.mq5`.

Stage 3 draws **active BSL/SSL liquidity levels** and **EQH/EQL equal pivot markers** on
the chart using MT5 chart objects. It does NOT draw POIs, FVGs, delivery legs, or the dashboard.

### Deliverables

1. **`Include/MNS/Renderers/CLiquidityRenderer.mqh`** ← PRIMARY DELIVERABLE
   - Draws active BSL/SSL horizontal level lines on the chart.
   - Draws EQH/EQL equal pivot markers using dashed lines or dotted lines.
   - Differentiates visually between: ACTIVE pools, SWEPT pools, BROKEN pools.
   - Consumes `CLiquidityEngine` outputs only.
   - Tracks drawn objects to avoid duplication.
   - Enforces `MaxRenderedPools` cap (default 20).
   - Must extend `MNSStyle.mqh` (`SIndicatorStyle`) with any new required style fields.

2. **Update `Include/MNS/MNSStyle.mqh`**
   - Add any new style tokens needed for liquidity rendering
     (e.g. `colorBSL`, `colorSSL`, `colorEQH`, `colorEQL`, `colorSweptPool`, `widthLiqLine`, `styleLiqActive`, `styleLiqSwept`).
   - Do NOT remove or rename any existing fields — Stage 2 renderers depend on them.

3. **Update `Indicators/MNS_Indicator.mq5`**
   - Add `#include` for `CLiquidityRenderer.mqh`.
   - Declare `CLiquidityRenderer g_liquidityRenderer;` as a global object.
   - Call `g_liquidityRenderer.Initialize(style, InpMaxRenderedPools)` in `OnInit()` after existing renderer initializations.
   - Call `g_liquidityRenderer.Draw(g_liquidity, time, rates_total)` at the end of `OnCalculate()`, before `ChartRedraw()`.
   - Call `g_liquidityRenderer.Reset()` in `OnDeinit()`.
   - Add `input int InpMaxRenderedPools = 20;` alongside existing max-rendered inputs.
   - No other modifications.

---

## STAGE 3 RENDERING RULES

### Data Source: `CLiquidityEngine`

The renderer must query the engine using these public methods only:
```mql5
int GetPoolsCount() const;
bool GetPool(int index, SLiquidityPool &outPool) const;
```

The `SLiquidityPool` struct fields available to the renderer:
```mql5
struct SLiquidityPool
{
    int                 id;           // Unique pool identifier — use as object name suffix
    ELiquidityType      type;         // LIQUIDITY_BSL or LIQUIDITY_SSL
    ELiquiditySource    source;       // LIQ_SRC_SWING, LIQ_SRC_EQ, LIQ_SRC_SESSION, LIQ_SRC_DAILY, LIQ_SRC_WEEKLY
    double              level;        // Price level of the pool
    datetime            createdTime;  // Timestamp of pool creation
    int                 touchesCount; // Number of touches
    ELiquidityLifecycle lifecycle;    // LIQ_ACTIVE, LIQ_TOUCHED, LIQ_SWEPT, LIQ_BROKEN, LIQ_CONSUMED, LIQ_ARCHIVED
    double              rankingScore; // 0–100 score
    EPoolPriority       priority;     // PRIORITY_LOW, PRIORITY_MEDIUM, PRIORITY_HIGH
    bool                active;       // Active status flag
    bool                swept;        // Swept status flag
    datetime            sweptTime;    // Timestamp when swept
    datetime            brokenTime;   // Timestamp when broken
};
```

### BSL (Buy-Side Liquidity) Lines
- ✅ **Specified**: BSL sits ABOVE price — above swing highs and session highs.
- Draw a **horizontal dashed line** extending from `createdTime` rightward to the current bar.
- Color: `m_style.colorBSL` (default: a bullish/blue tone — distinct from BOS).
- Line width: `m_style.widthLiqLine` (default: 1).
- Line style: `m_style.styleLiqActive` for active pools (default: `STYLE_DASH`).
- **Swept pools** (`lifecycle == LIQ_SWEPT || swept == true`):
  - Change line style to `m_style.styleLiqSwept` (default: `STYLE_DOT`) and color to a muted/grey version.
  - The line end time should be updated to `sweptTime`.
  - ⚠️ **Inferred**: Swept pools remain briefly visible to show the sweep context, then removed when they fall outside the `MaxRenderedPools` cap.
- **Broken/Consumed/Archived pools**: Delete their chart objects immediately.

### SSL (Sell-Side Liquidity) Lines
- ✅ **Specified**: SSL sits BELOW price — below swing lows and session lows.
- Same rendering rules as BSL but:
  - Color: `m_style.colorSSL` (default: a bearish/red tone — distinct from swing low arrows).
  - Line extends from `createdTime` rightward to the current bar.

### EQH (Equal Highs) and EQL (Equal Lows)
- Source filter: `source == LIQ_SRC_EQ` — these are the equal pivot pools.
- EQH = `LIQUIDITY_BSL` with `LIQ_SRC_EQ` source.
- EQL = `LIQUIDITY_SSL` with `LIQ_SRC_EQ` source.
- Draw a **dotted horizontal line** at `level` from `createdTime` rightward.
- Color: `m_style.colorEQH` or `m_style.colorEQL` (default: lighter/more muted than BSL/SSL).
- ⚠️ **Inferred**: EQH/EQL do not have a swept visual distinction — delete when `lifecycle != LIQ_ACTIVE`.

### Priority Visual Distinction
- ⚠️ **Inferred**: Higher-priority pools render with a slightly wider line:
  - `PRIORITY_LOW` → `widthLiqLine` (default: 1)
  - `PRIORITY_MEDIUM` → `widthLiqLine + 1` (default: 2)
  - `PRIORITY_HIGH` → `widthLiqLine + 2` (default: 3)
- ⚠️ This is an engineering inference. Mark it clearly in the code with a comment: `// ⚠️ Inferred: line width scaled by priority`.

### Object Naming Convention (CRITICAL — prevents collision)
All chart objects MUST use the established MNS prefix convention:
```
"MNS_" + ObjectType + "_" + UniqueID
```

Use `pool.id` cast to string as the unique suffix. The pool `id` is stable and does not shift between bars (unlike `barIndex`).

Examples:
```
MNS_LiqBSL_42        — BSL active line for pool id 42
MNS_LiqSSL_17        — SSL active line for pool id 17
MNS_LiqEQH_88        — Equal highs line for pool id 88
MNS_LiqEQL_91        — Equal lows line for pool id 91
MNS_LiqBSL_42_Swpt   — Optional: separate swept state object if visual differs
```

### Object Lifetime
- On `Reset()` / `OnDeinit()`: delete all objects with prefix `MNS_Liq` using `ObjectsDeleteAll(0, "MNS_Liq")`.
- On a full rescan (`prevCalculated == 0`): call `Reset()` then redraw all pools.
- On incremental bar updates: update existing objects (move right endpoint), add new pools, delete broken/consumed/archived pools.
- **Do NOT** redraw objects that have not changed — check lifecycle state before touching existing objects.

### Capping
- Draw at most `MaxRenderedPools` (default 20) active pools.
- When cap is exceeded, remove the oldest (lowest `id`) objects first.
- Swept pools count toward the cap.
- Broken/Consumed/Archived pools are deleted immediately and do not count toward the cap.

---

## WHAT STAGE 3 MUST NOT DO

- ❌ Draw POI zones (Order Blocks, FVGs, Mitigation Blocks, Breaker Blocks) — that is Stage 4
- ❌ Draw Delivery leg arrows or DOL target lines — that is Stage 4
- ❌ Draw the dashboard or info panel — that is Stage 5
- ❌ Draw session boxes or premium/discount zones — that is Stage 7
- ❌ Modify any of the 12 core engine headers
- ❌ Modify Stage 2 renderer files (`CSwingRenderer.mqh`, `CStructureRenderer.mqh`)
- ❌ Modify `OnCalculate()` logic in `MNS_Indicator.mq5` other than adding `Draw()` call
- ❌ Remove or rename any existing fields in `MNSStyle.mqh`
- ❌ Add any trading execution or broker API calls
- ❌ Hardcode colors, widths, or style values inside renderer methods — use `SIndicatorStyle` only
- ❌ Use a linear scan to find a pool by time — use `pool.id` directly as the object name key

---

## MQL5 TECHNICAL CONSTRAINTS

Apply these rules in every file:

- `ArraySetAsSeries()` requires **dynamic** arrays (`double arr[]`), not static (`double arr[N]`).
- `FileSize()` and `FileTell()` return `ulong` — assign to `ulong`, not `long`.
- No `const T& x = ...` local references in const methods.
- No `const T&` return types from const methods on member arrays — return by value.
- Static array sizes must use `#define` or literal integers, never `const int`.
- `ObjectCreate()` returns `bool` — always check and log on failure with `GetLastError()`.
- `ObjectMove()` moves anchor point by index: point 0 = left anchor, point 1 = right anchor for `OBJ_TREND`.
- `OBJ_TREND` with `OBJPROP_RAY_RIGHT = true` extends infinitely right — set to `false` for bounded lines.
- `ChartRedraw()` must be called at most **once** per `OnCalculate()` call, at the end — it is already called by the indicator coordinator; do NOT add a second call inside the renderer.
- Use `OBJ_TREND` for horizontal level lines (2 anchor points, same price, different times).
- For a line extending to the "current bar", use `time[1]` (the last confirmed bar), NOT `time[0]` (forming bar).

---

## WORKFLOW

Follow every step from `docs/ai/PROMPT_NEW_MODULE.md`:

1. Read all required context files above — especially `CLiquidityEngine.mqh` and `MNSTypes.mqh` for `SLiquidityPool`.
2. Produce design documentation:
   - `docs/modules/013_STAGE_03_DESIGN.md` — object naming table, rendering pipeline, lifecycle → visual state mapping.
3. Cross-check every renderer method against the locked strategy rules and `SLiquidityPool` field contracts.
4. Update `Include/MNS/MNSStyle.mqh` — add new style fields for liquidity rendering.
5. Generate production MQL5 for `Include/MNS/Renderers/CLiquidityRenderer.mqh`.
6. Update `Indicators/MNS_Indicator.mq5` per the Deliverables section above.
7. Self-review checklist:
   - [ ] No compiler warnings (check `ArraySetAsSeries` on static arrays, `ulong` types).
   - [ ] All object names prefixed with `MNS_Liq`.
   - [ ] `pool.id` used as unique suffix — no linear time scans.
   - [ ] Broken/Consumed/Archived pools deleted immediately.
   - [ ] `MaxRenderedPools` cap enforced.
   - [ ] `ObjectsDeleteAll(0, "MNS_Liq")` called in `Reset()`.
   - [ ] `ChartRedraw()` NOT called inside the renderer (only once in indicator coordinator).
   - [ ] All style values come from `SIndicatorStyle` — none hardcoded.
   - [ ] No existing fields in `MNSStyle.mqh` were removed or renamed.
   - [ ] `MNS_Indicator.mq5` modified only per the Deliverables additions.
   - [ ] All 12 engine headers unmodified.
   - [ ] Stage 2 renderer files unmodified.
8. Present files. Instruct user to run:
   ```powershell
   .\tools\Build-And-Archive.ps1 -Module "Module013-Stage3"
   ```
9. After build passes, update `docs/modules/013_ISSUES.md` and `roadmap.md` to mark Stage 3 ✅ Complete.

---

## STAGE ROADMAP (for orientation only — do not implement future stages)

| Stage | Description | Status |
|---|---|---|
| Stage 0 | Architecture & Dependency Audit | ✅ Complete |
| Stage 1 | Indicator Shell & Lifecycle Coordinator | ✅ Complete |
| Stage 2 | Swing Point & Structure Renderers | ✅ Complete — v0.13.2 |
| **Stage 3** | **Liquidity Pool Renderers (BSL/SSL/EQH/EQL)** | 🔄 **YOU ARE HERE** |
| Stage 4 | Advanced Zone Renderers (OB/FVG/Delivery/DOL) | ⬜ Pending |
| Stage 5 | Dashboard & Info Panel | ⬜ Pending |
| Stage 6 | Configuration Binding (INF-004 integration) | ⬜ Pending |
| Stage 7 | Session Renderers & Premium/Discount Zones | ⬜ Pending |
| Stage 8 | Visual Performance Profiling | ⬜ Pending |
| Stage 9 | Integration Testing | ⬜ Pending |
| Stage 10 | Production Build & Release | ⬜ Pending |
