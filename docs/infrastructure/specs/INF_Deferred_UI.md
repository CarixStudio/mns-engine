# Module Specification — INF-Deferred-UI (DEPRECATED & RECONCILED)

> [!WARNING]
> This specification file has been deprecated and its content has been reconciled to eliminate architectural duplication between the Infrastructure Layer and the Core Modules.
> 
> UI, graphics, settings, and rendering systems are **not** part of the Shared Infrastructure.

## Ownership Realignment

The responsibilities defined in this document have been consolidated under their respective core modules:

- **Indicator Presentation, Visuals, and Layouts** 
  → Fully owned by **[Module 013 — Indicator Integration](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/013-Indicator.md)**.
  This includes:
  - Renderer Framework (drawing interfaces)
  - Visual Rendering Engine (concrete render classes)
  - Object Manager (chart object lifecycle and cleanup)
  - Dashboard Framework (on-chart text panel)
  - Settings Manager (inputs and user-facing controls)
  - UI/Rendering Performance Optimization

- **EA Trading Dashboard, Interface, and Controls**
  → Fully owned by **[Module 014 — EA Integration](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/modules/014-EA.md)**.
  This includes:
  - Interactive on-chart EA Dashboard
  - Trade execution control panels (Auto Trading toggle, risk inputs, session rules)
  - Execution logging display

Please refer to the updated module specification files listed above for the current specifications.
