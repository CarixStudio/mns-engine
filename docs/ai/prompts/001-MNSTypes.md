# Prompt 001 — Implement MNSTypes

## Role

You are a Senior MQL5 Software Engineer with extensive experience building institutional-grade trading systems.

You are contributing to the MNS Trading Engine, a deterministic Smart Money Concepts framework for MetaTrader 5.

Your task is to implement the foundational shared types module.

---

# Project Context

The MNS Trading Engine separates market analysis from execution.

The engine is composed of multiple independent modules.

MNSTypes is the root dependency for every module.

It defines shared data structures, enumerations, constants, and value objects.

It contains **no business logic**.

It performs **no calculations**.

It performs **no market analysis**.

It performs **no broker interaction**.

---

# Inputs

Read and follow the attached documents exactly.

Required attachments:

- PRD.md
- Architecture.md
- TechnicalDesign.md
- CodingStandards.md
- Decisions.md
- 001-MNSTypes.md

Do not invent requirements.

---

# Responsibilities

Implement the shared definitions used by the engine.

Include:

- Enumerations
- Structures
- Shared constants
- Default initialization
- Documentation

Do not implement algorithms.

---

# Functional Requirements

Implement appropriate enums for:

- Trend
- Market Phase
- Swing Type
- Swing Level
- Structure Type
- Structure Break
- Strength

Implement reusable structures for:

- Swing Point
- Structure Break
- Market State

Design the structures so future modules can extend them without breaking compatibility.

---

# Non-Functional Requirements

The implementation must be:

- Deterministic
- Lightweight
- Modular
- Extensible
- Production ready
- Fully documented

---

# Constraints

Do not:

- Detect swings
- Detect BOS
- Detect CHoCH
- Read candles
- Access price data
- Place trades
- Draw chart objects
- Use placeholder code
- Add TODO comments
- Invent trading rules

---

# Coding Standards

Follow the project's CodingStandards.md.

Use:

- PascalCase for classes
- camelCase for variables
- Prefix enums with E
- Prefix structures with S
- Prefix member variables with m_

Every public definition must be documented.

---

# Deliverable

Produce one file only.

MNSTypes.mqh

The file must compile successfully in MetaEditor.

No warnings.

No placeholders.

No incomplete implementations.

---

# Acceptance Criteria

The implementation is complete when:

- All shared enums exist.
- All shared structs exist.
- Structures initialize safely.
- The file compiles successfully.
- No business logic exists.
- Documentation is complete.

Return only production-ready MQL5 code.