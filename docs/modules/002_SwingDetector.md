# Module 002
# Swing Detector
Version: 1.0
Status: Development

---

# Purpose

The Swing Detector is the first analytical component of the MNS Trading Engine.

Its responsibility is to identify valid market swing points that become the foundation for every downstream module.

No other module may independently determine swing locations.

The Swing Detector is therefore the single source of truth for swing analysis.

---

# Responsibilities

The Swing Detector shall identify:

• Swing Highs

• Swing Lows

• Internal Swings

• External Swings

The exact identification rules shall follow the MNS Strategy documentation.

No heuristic or alternative swing logic shall be introduced without explicit specification.

---

# Inputs

OHLC price data

Time

Bar Index

Historical candles

---

# Outputs

Confirmed Swing High

Confirmed Swing Low

Internal Swing

External Swing

SSwingPoint structures

---

# Dependencies

MNSTypes

Only.

---

# Consumed By

Structure Engine

Break Engine

Liquidity Engine

POI Engine

Market State Engine

Indicator

EA

---

# Functional Requirements

The detector shall:

Detect candidate swing highs.

Detect candidate swing lows.

Validate swings.

Reject invalid swings.

Maintain chronological ordering.

Prevent duplicate swings.

Support internal and external structure.

Never repaint confirmed swings.

---

# Non Functional Requirements

Deterministic.

Fast.

Memory efficient.

Incremental updates only.

No chart drawing.

No trading logic.

No broker interaction.

---

# Public Interface

Initialize()

Reset()

Update()

GetLatestSwing()

GetSwing()

GetSwingCount()

---

# Data Structures

SSwingPoint

ESwingType

ESwingLevel

---

# Acceptance Criteria

Produces consistent swing locations.

Produces deterministic results.

No repainting after confirmation.

Compiles without warnings.

Passes Test Harness.

Ready for Structure Engine.
