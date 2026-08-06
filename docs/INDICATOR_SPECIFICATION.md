# MNS Indicator
# Functional Specification
Version: 1.0

---

# Purpose

The MNS Indicator visualizes the analysis produced by the MNS Trading Engine.

It never executes trades.

Its purpose is to allow visual validation before EA development.

---

# Features

## Market Structure

✓ Swing High

✓ Swing Low

✓ Internal Structure

✓ External Structure

✓ Higher High

✓ Higher Low

✓ Lower High

✓ Lower Low

---

## Structure

✓ BOS

✓ Internal BOS

✓ CHoCH

✓ Equal High

✓ Equal Low

---

## Liquidity

✓ Buy-side Liquidity

✓ Sell-side Liquidity

✓ Liquidity Sweeps

---

## Points of Interest

✓ Order Blocks

✓ Fair Value Gaps

✓ Premium Zone

✓ Discount Zone

✓ Equilibrium

---

## Sessions

✓ Asian

✓ London

✓ New York

✓ Session Overlap

---

## Dashboard

Displays:

• Symbol

• Timeframe

• Trend

• Market Phase

• Structure

• Latest BOS

• Latest CHoCH

• Active POI

• Liquidity Bias

• Premium / Discount

• Session

---

## Chart Objects

Arrow

Trend Line

Rectangle

Label

Horizontal Line

Text

---

## User Inputs

Show Dashboard

Show Swings

Show BOS

Show CHoCH

Show Liquidity

Show POIs

Show FVG

Show Sessions

Dashboard Position

Font Size

Colors

---

## Alerts

Reserved for future release.

---

## Performance

No repainting.

Incremental rendering.

Object reuse.

Minimal CPU usage.

---

## Acceptance Criteria

The indicator is considered complete when:

✓ Market structure is correctly detected.

✓ Chart objects match engine output.

✓ Dashboard reflects engine state.

✓ No repainting occurs.

✓ Performance remains acceptable.

✓ Client approves visual output.

Only then does EA development begin.
