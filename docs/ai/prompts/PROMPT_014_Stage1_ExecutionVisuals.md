# Module 014 — EA Integration
# Stage 1: Execution Visuals (Risk/Reward Projection)
# AI Implementation Prompt

Version: 1.0
Status: READY — Design Approved. Begin Stage 1.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, inspect the following repository files:
1. [MNSStyle.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSStyle.mqh) — For visual style token architecture.
2. [MNSConfig.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSConfig.mqh) — For settings parameters.
3. [014_STAGE_01_DESIGN.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/014_STAGE_01_DESIGN.md) — The visual design specifications.
4. [MNS_Indicator.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Indicators/MNS_Indicator.mq5) — Indicator lifecycle and coordination.

---

## ABSOLUTE RULES
1. **Zero Color Collisions**: Fills for Risk and Reward regions must be dark, desaturated background blocks that allow candlesticks/wicks to render cleanly over them.
2. **Strict Time Limits**: Projections must only extend into the future chart space (to the right of `time[0]`), never stretching back into historical bars.
3. **State Isolation**: Visuals must clean up immediately (`Clear()`) if no entry signal is active and no trade is running.
4. **Compile Hygiene**: Ensure both the indicator and the test harness compile with 0 errors and 0 warnings.

---

## STAGE 1 DELIVERABLES

### 1. Update [MNSStyle.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSStyle.mqh)
Add style properties to the `SIndicatorStyle` structure and initialize them in the `Reset()` method:
* `color colorExecutionEntry` (default `clrGold`)
* `color colorExecutionTPBg` (default `C'0x0C, 0x22, 0x11'`)
* `color colorExecutionSLBg` (default `C'0x26, 0x0C, 0x0C'`)
* `color colorExecutionTPLine` (default `clrLime`)
* `color colorExecutionSLLine` (default `clrRed`)

### 2. Update [MNSConfig.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSConfig.mqh)
Add execution projected bars count parameter to `CMNSConfig` (internal storage variable, validation, default binding):
* Config key: `executionProjectedBars`
* Type: `int`
* Default value: `20`
* Validation: Must be between `5` and `100` (clamp/fail-safe if violated).

### 3. Create `Include/MNS/Renderers/CExecutionRenderer.mqh`
Implement the execution visuals renderer class. It should draw the projection box using MT5 GUI objects (`OBJ_RECTANGLE`, `OBJ_TREND`, `OBJ_TEXT`) with the prefix namespace `"MNS_EXEC_"`.

Use this class skeleton:
```mql5
//+------------------------------------------------------------------+
//|                                           CExecutionRenderer.mqh |
//|                              MNS Trading Engine — Module 014     |
//|                                                                  |
//| Purpose:                                                         |
//|   Renders on-chart Entry, SL, and TP risk-reward projection boxes |
//+------------------------------------------------------------------+
#ifndef __MNS_EXECUTION_RENDERER_MQH__
#define __MNS_EXECUTION_RENDERER_MQH__

#include "../MNSTypes.mqh"
#include "../MNSStyle.mqh"

class CExecutionRenderer
{
private:
    bool     m_isInitialized;
    string   m_prefix;
    
    void     CreateRectangle(string name, datetime t1, double p1, datetime t2, double p2, color clr);
    void     CreateLine(string name, datetime t1, double p1, datetime t2, double p2, color clr, int width, ENUM_LINE_STYLE style);
    void     CreateLabel(string name, datetime t, double p, string text, color clr, ENUM_ANCHOR_POINT anchor);

public:
    CExecutionRenderer();
    ~CExecutionRenderer();

    bool     Initialize(string prefix = "MNS_EXEC_");
    void     Draw(EConfirmationDirection direction, 
                  double entryPrice, 
                  double stopLoss, 
                  double takeProfit, 
                  const datetime &time[], 
                  double atr14, 
                  int projectedBars);
    void     Clear();
};
#endif
```

### 4. Update [MNS_Indicator.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Indicators/MNS_Indicator.mq5)
* Include `#include <MNS/Renderers/CExecutionRenderer.mqh>`.
* Declare a file-scope renderer instance: `CExecutionRenderer g_executionRenderer;`
* Initialize it in `OnInit()` and clear it in `OnDeinit()`.
* In `OnCalculate()`, check if `g_entry.HasActiveSignal()` is true:
  * If true: retrieve the entry setup details (`EConfirmationDirection direction`, `entryPrice`, `stopLoss`, `takeProfit` or `dolPrice`) and call `g_executionRenderer.Draw(direction, entryPrice, stopLoss, takeProfit, time, currentAtr, cfg.executionProjectedBars)`.
  * If false: call `g_executionRenderer.Clear()`.

---

## SELF-REVIEW CHECKLIST
- [ ] Code compiles with 0 errors and 0 warnings.
- [ ] All created objects use the `"MNS_EXEC_"` namespace prefix.
- [ ] Rectangles are filled, marked as background objects (`OBJPROP_BACK = true`), and borders are hidden.
- [ ] Text labels show the price, the distance in pips, and the R:R ratio for TP.
- [ ] When the entry signal disappears, all execution graphics are immediately cleaned from the chart.
