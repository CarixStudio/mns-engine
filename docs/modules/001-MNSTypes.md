# Module 001 — MNSTypes

Version: 1.0

Status: Ready for Implementation

---

# Purpose

MNSTypes defines every shared data model, enumeration, constant, and value object used throughout the MNS Trading Engine.

This module acts as the common language of the engine.

No analysis, trading logic, or calculations shall exist in this module.

Its sole responsibility is to define shared types that all other modules depend upon.

---

# Responsibilities

The module shall:

- Define all engine enumerations.
- Define all shared structures.
- Define all common constants.
- Define reusable data models.
- Provide reset/default initialization methods where appropriate.
- Remain independent of every analysis module.

---

# Design Principles

- No business logic.
- No market analysis.
- No trade execution.
- No indicator drawing.
- No broker interaction.
- No chart operations.
- Deterministic.
- Immutable definitions where possible.

---

# Dependencies

None.

This is the root module of the system.

Every other module depends on MNSTypes.

---

# Dependent Modules

- SwingDetector
- StructureEngine
- MarketStructureEngine
- OrderFlowEngine
- DeliveryStructureEngine
- LiquidityEngine
- POIEngine
- ObjectiveEngine
- ConfirmationEngine
- EntryEngine
- RiskEngine
- Indicator
- Expert Advisor

---

# Public Enumerations

The module shall define:

## Trend

- Unknown
- Bullish
- Bearish
- Transition
- Ranging

---

## Market Phase

- Unknown
- Trending
- Pullback
- Transition
- Ranging

---

## Swing Type

- None
- High
- Low

---

## Swing Level

- Internal
- External

---

## Structure Type

- HH
- HL
- LH
- LL
- Equal High
- Equal Low

---

## Structure Break

- None
- BOS
- Internal BOS
- CHoCH

---

## Strength

- Unknown
- Weak
- Average
- Strong
- Very Strong

---

# Shared Data Models

The module shall define structures representing:

- Swing Point
- Structure Break
- Market State

Future modules may extend this list with additional shared models while preserving backward compatibility.

---

# Rules

MNSTypes shall never:

- Detect swings.
- Detect BOS.
- Detect CHoCH.
- Read chart data.
- Read candles.
- Open trades.
- Modify trades.
- Draw chart objects.

---

# Performance Requirements

- Zero runtime allocations where practical.
- Lightweight structures.
- Suitable for reuse across every engine update.

---

# Error Handling

No runtime processing occurs within this module.

Structures should initialize to safe default values.

---

# Acceptance Criteria

The module is complete when:

- All shared enums are defined.
- All shared structs are defined.
- Default initialization is available where required.
- No business logic exists.
- No MT5 trading functions are called.
- No chart functions are called.
- Compiles successfully without warnings.

---

# Implementation Notes

This module is the foundation of the engine.

Changes to this module may affect every other component.

Backward compatibility should be maintained whenever possible.

Any additions must be reviewed before implementation.