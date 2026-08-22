# Changelog

All notable changes to this project will be documented in this file.

The format follows Keep a Changelog principles.

---

## [Unreleased]

---

## [1.0.0] - 2026-08-22

### Added
- **Module 013 (Indicator Integration) Complete**: Full chart visualization layer of the MNS Trading Engine.
- **Renderer Framework**: Individual renderers for Swings, Structure Breaks, Liquidity Pools, POIs (Order Blocks & Fair Value Gaps), Active Delivery Leg, and active Take Profit target (Draw on Liquidity).
- **Session Shading bands**: Colored non-overlapping vertical columns for Asia, London, NY, and London/NY overlap hours.
- **Premium/Discount Zones**: Desaturated horizontal range fills divided by the Equilibrium midpoint line.
- **Floating Status Dashboard**: 16-row expandable/collapsible HUD showing real-time trends, broken levels, target DOL, active POI, session, confirmation status, entry signals, entry price, and stop loss.
- **Configuration Engine Binding**: Dynamic config profile loading from custom `.ini` files synced with standard MT5 user inputs.
- **Visual Performance Telemetry**: Compile-time strippable performance monitoring macros wrapping all calculation and rendering loops.

### Fixed
- Resolved `MNS-ISSUE-002` / `M13-ISSUE-002` (Risk and spread parameters centralization).
- Resolved `MNS-ISSUE-004` / `M13-ISSUE-004` (Session GMT Offset centralization).
- Resolved `M13-ISSUE-005` (Visual theme customization).
- Resolved `M13-ISSUE-006` (Visual object capping and performance timing validation).

---


### Added

- Initial repository
- Engineering documentation
- Architecture
- Product Requirements
- Technical Design
- Development Workflow
- Coding Standards
- Testing Strategy
- AI Prompt Standards
- Module Specifications

---

## [0.1.0] - Foundation

### Added

- Repository initialized
- Documentation completed
- Project structure established