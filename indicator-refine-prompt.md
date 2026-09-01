MNS INDICATOR — VISUAL REFINEMENT TASK

IMPORTANT CONTEXT

The MNS EA work is already completed. Do NOT work on, redesign, or modify the EA.

This task is ONLY to refine the existing MNS MT5 INDICATOR based on the client's observations and the supplied reference images.

CRITICAL VISUAL SCOPE

Do NOT treat the entire AI-generated reference screenshot as the specification.

The screenshot contains additional AI-generated UI concepts that are NOT requested for implementation.

For the MAIN CHART, only use the area I manually circled/marked as the visual reference.

The circled area represents the desired visual treatment of the actual chart indicator itself.

DO NOT ADD:
- AI-generated top header
- Session/Spread/News widgets
- Bottom dashboard panels
- Momentum gauges
- Displacement gauges
- Higher-timeframe panels
- Risk-management panels
- Extra legends
- Extra status cards
- Any new UI that exists only in the AI-generated mockup
- Any other decorative elements that are not part of the existing MNS indicator

The existing indicator dashboard is a SEPARATE component.

For the dashboard, use the dashboard reference that I previously annotated in green as the design target.

Therefore:

MAIN CHART
→ Refine ONLY the actual MNS chart indicator visuals in the manually circled area.

DASHBOARD
→ Refine the existing MNS indicator dashboard according to the separately annotated dashboard reference.

Do not merge the two references into one new UI.

==================================================
1. MAIN CHART VISUAL REFINEMENT
==================================================

Clean up the existing chart indicator so it resembles the manually circled reference.

The chart should prioritize the information that is actually part of the MNS indicator:

- BOS
- CHoCH
- Active POI
- DOL / Delivery Objective
- Liquidity sweep markers
- Support/liquidity markers
- Existing MNS structural markings
- Existing relevant swing/structure visuals

The objective is NOT to create more objects.

The objective is to make the existing MNS information cleaner, more readable and properly prioritized.

CURRENT/ACTIVE INFORMATION MUST HAVE MORE VISUAL WEIGHT THAN OLD HISTORICAL INFORMATION.

Avoid allowing historical markings to overwhelm the current price action.

==================================================
2. ACTIVE POI
==================================================

The Active POI should be immediately identifiable.

Maintain the existing real POI calculation.

Visually:

- Use a clean filled zone.
- Keep the POI label clear.
- Show the relevant price range where already supported.
- Make the active POI visually stronger than inactive/historical POIs.
- Do not create fake POIs merely to match the screenshot.

The visual reference shows the Active POI as a clean, restrained chart zone rather than a collection of overlapping historical rectangles.

==================================================
3. DOL / DELIVERY OBJECTIVE
==================================================

Make the active DOL clearly distinguishable from other structural levels.

The DOL should communicate the current delivery target without visually competing with every historical level.

Use the existing MNS DOL calculation.

Do NOT hardcode the reference screenshot's price values.

Do NOT create additional DOL targets simply because the AI-generated image contains them.

Only display what the actual indicator logic provides.

==================================================
4. BOS / CHoCH
==================================================

Keep BOS and CHoCH visible and readable.

They should be visually secondary to the active setup/current state.

Avoid covering the chart with excessive historical BOS/CHoCH lines.

Do not change the underlying BOS/CHoCH calculation.

This is a rendering/presentation refinement only.

==================================================
5. LIQUIDITY / SWING MARKERS
==================================================

Keep the existing MNS liquidity and swing information.

However, ensure that structural arrows/markers cannot easily be mistaken for actual trade-entry signals.

A liquidity sweep, swing, support touch, BOS or CHoCH marker is NOT automatically a BUY/SELL entry.

Do not turn every green arrow into an entry signal.

==================================================
6. ACTUAL SIGNAL VISUAL
==================================================

If the existing indicator generates a confirmed trading signal, its visual treatment must be distinguishable from structural markers.

The actual signal should only appear when the REAL MNS confirmation logic produces it.

Do not hardcode:

- BUY
- SELL
- CALL
- PUT
- confidence
- entry price
- confirmation

Do not use screenshot values as simulated data.

The engine remains the source of truth.

==================================================
7. DASHBOARD
==================================================

Refine the EXISTING dashboard separately.

Use the previously green-annotated dashboard as the visual reference.

The dashboard should have a clear hierarchy and make the current MNS state easy to understand.

Preserve the existing MNS data and calculations.

Do not add the AI-generated panels from the chart mockup.

The dashboard should remain an MNS indicator dashboard, not become an entirely new trading terminal UI.

==================================================
8. COLOR SYSTEM
==================================================

Use color semantically and consistently.

General direction:

GREEN / LIME
→ bullish / valid / positive

RED
→ bearish / negative / risk

PURPLE / MAGENTA
→ CHoCH / internal bearish structure / liquidity-related information where already defined

BLUE / TEAL
→ BOS / bullish internal or structural information where already defined

GOLD / ORANGE
→ DOL / transition / warning states where applicable

GRAY / WHITE
→ neutral or inactive information

Do not introduce colors solely because they appear in the AI-generated image.

Follow the existing MNS visual specification and the supplied references.

==================================================
9. OBJECT MANAGEMENT
==================================================

While refining the visuals, ensure the indicator does not continuously create duplicate objects.

Verify:

- stale objects are removed correctly
- historical objects are appropriately limited
- active objects update correctly
- no duplicate labels/lines appear on every tick
- chart performance remains stable
- object count does not grow uncontrollably

Do not change strategy logic to solve a rendering problem.

==================================================
10. STRICT SOURCE-OF-TRUTH RULE
==================================================

There are three different things here:

1. EXISTING MNS ENGINE
   → Source of truth for calculations and strategy state.

2. CLIENT REFERENCE / ANNOTATIONS
   → Source of truth for the desired visual presentation.

3. AI-GENERATED MOCKUP
   → ONLY a visual inspiration for the specific area I marked.

Do NOT assume every element in the AI-generated screenshot is requested.

Do NOT implement elements simply because they appear visually attractive.

==================================================
11. DO NOT HARDCode MOCKUP DATA
==================================================

Values such as:

1.36270
1.36100
1.36595
82/100
Bullish FVG
London
etc.

are examples from the reference image.

They must NOT be hardcoded.

The indicator must continue displaying the real values generated by the MNS engine.

==================================================
12. VALIDATION
==================================================

After implementation, verify:

MAIN CHART:

[ ] Only requested indicator visuals are present.
[ ] No AI-generated dashboard/UI panels were added.
[ ] Active POI is immediately visible.
[ ] Active DOL is immediately visible.
[ ] BOS is readable.
[ ] CHoCH is readable.
[ ] Liquidity/swing markers remain meaningful.
[ ] Historical clutter is reduced.
[ ] Structural arrows are not confused with trade entries.
[ ] Actual confirmed signals are visually distinct.
[ ] Existing MNS calculations remain unchanged.

DASHBOARD:

[ ] Existing dashboard has been visually refined.
[ ] Hierarchy matches the separately annotated reference.
[ ] Real MNS values are displayed.
[ ] No unnecessary AI-generated panels were added.
[ ] Colors communicate state consistently.
[ ] Current setup/state is easy to identify.

ENGINE:

[ ] No strategy rules were rewritten.
[ ] No fake values were introduced.
[ ] No mock signals were introduced.
[ ] No EA code was modified.
[ ] No TradingView work was performed.
[ ] Indicator compiles successfully.
[ ] Indicator runs correctly on MT5.

FINAL PRINCIPLE

Do not build a new trading interface.

Refine the EXISTING MNS INDICATOR.

The client's marked references define how the indicator should LOOK.

The existing MNS engine defines what the indicator should SHOW.

Keep those two responsibilities separate.