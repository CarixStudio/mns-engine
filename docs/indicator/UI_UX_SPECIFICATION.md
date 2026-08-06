# MNS Trading Engine
# Indicator UI/UX Specification
Version: 1.0
Status: Approved Foundation

---

# 1. Philosophy

The indicator is not a signal provider.

It is a visualization layer for the MNS Trading Engine.

Every visual element must represent a computed state from the engine.

The UI must never contain logic.

The UI only renders data.

---

# 2. Design Principles

The interface should be:

- Minimal
- Professional
- Institutional
- High contrast
- Fast
- Non-obstructive

Avoid:

❌ Giant labels

❌ Random colors

❌ Clutter

❌ Repainting objects

---

# 3. Layout

Chart

+------------------------------------------------------------+
|                                                            |
|                    Market Structure                        |
|                                                            |
|        HH                  BOS                             |
|                                                            |
|                 █████████ Order Block                      |
|                                                            |
|                         CHoCH                              |
|                                                            |
|------------------------------------------------------------|
|                                              Dashboard     |
|                                              ┌──────────┐  |
|                                              │ Trend    │  |
|                                              │ Phase    │  |
|                                              │ Bias     │  |
|                                              │ Session  │  |
|                                              └──────────┘  |
+------------------------------------------------------------+

Dashboard anchored to top-right.

---

# 4. Dashboard

Default Width

250 px

Default Height

Auto

Padding

10 px

Border Radius

4 px

Background

Dark Gray

Opacity

85%

Border

1 px

---

# 5. Dashboard Sections

Header

MNS ENGINE

Version

Current Symbol

Current Timeframe

---

Market State

Trend

Bullish

Bearish

Transition

Ranging

---

Phase

Trending

Pullback

Transition

Range

---

Structure

HH

HL

LH

LL

---

Last BOS

Bullish

Bearish

None

---

Last CHoCH

Bullish

Bearish

None

---

Liquidity

Buy Side

Sell Side

Balanced

---

POI

Current active POI

---

Premium / Discount

Premium

Discount

Equilibrium

---

Trading Session

Asia

London

New York

Overlap

---

# 6. Chart Objects

Swing High

Arrow

Above candle

Swing Low

Arrow

Below candle

BOS

Horizontal line

Green

CHoCH

Horizontal line

Orange

Equal High

Dashed line

Equal Low

Dashed line

Order Block

Rectangle

Fair Value Gaps

Rectangle

Liquidity

Horizontal level

Premium Discount

Range Fill

---

# 7. Color Palette

Bullish

Lime

Bearish

Red

Neutral

Gray

Structure

White

Dashboard

Dark Gray

Background

Transparent

Text

White

Warning

Orange

Information

Blue

---

# 8. Fonts

Default MT5 Font

Size

10

Header

Bold

---

# 9. User Inputs

Show Dashboard

true

Show Swings

true

Show BOS

true

Show CHoCH

true

Show Liquidity

true

Show Order Blocks

true

Show FVG

true

Show Premium Discount

true

Dashboard Position

Top Right

---

# 10. Performance

Dashboard updates only when a new bar forms.

Chart objects are reused.

Never recreate objects every tick.

Never delete all objects every refresh.

Update only changed objects.

---

# 11. Rendering Rules

Rendering layer reads engine state.

Rendering layer never performs analysis.

Rendering layer never modifies engine data.

Rendering layer must remain stateless.

---

# 12. Future Expansion

Dashboard Alerts

Multi-timeframe Summary

Trade Statistics

Risk Meter

EA Status

AI Commentary

Reserved for future releases.
