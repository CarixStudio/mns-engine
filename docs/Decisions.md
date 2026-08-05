# MNS Trading Engine

# Engineering Decision Log

Version: 1.0

Status: Active

---

# Purpose

This document records all significant engineering and architectural decisions made throughout the development of the MNS Trading Engine.

Every major decision shall include:

- Decision ID
- Date
- Status
- Context
- Decision
- Rationale
- Consequences

This document is the historical record of why the system was designed the way it was.

---

# Decision Template

## ADR-XXX

Status:

Date:

Category:

Context

Decision

Rationale

Consequences

---

# ADR-001

Status

Accepted

Category

Architecture

Context

The project requires a reusable trading engine that can support multiple consumers.

Decision

Separate market analysis from trade execution.

Rationale

Analysis should exist independently of the Expert Advisor.

This allows the same engine to support indicators, backtesting tools, dashboards, APIs, and future trading platforms.

Consequences

- Cleaner architecture
- Better testing
- Higher reusability
- Easier maintenance

---

# ADR-002

Status

Accepted

Category

Architecture

Context

Indicators often duplicate trading logic.

Decision

The indicator shall never perform market analysis.

Rationale

The indicator exists only to visualize engine output.

Consequences

- Single source of truth
- No duplicated logic
- Easier debugging

---

# ADR-003

Status

Accepted

Category

Architecture

Context

Expert Advisors frequently contain embedded analysis logic.

Decision

The Expert Advisor shall never analyse the market.

Rationale

The EA should consume validated signals produced by the engine.

Consequences

- Easier testing
- Modular execution
- Reusable analysis engine

---

# ADR-004

Status

Accepted

Category

Engineering

Context

Different modules require market information.

Decision

Shared information shall be exchanged through common data models.

Rationale

Modules should communicate through well-defined structures rather than directly accessing each other.

Consequences

- Loose coupling
- Better maintainability
- Easier extension

---

# ADR-005

Status

Accepted

Category

Architecture

Context

Historical analysis must remain stable.

Decision

Confirmed market structure shall never repaint.

Rationale

Backtesting and live trading must produce consistent behaviour.

Consequences

- Deterministic outputs
- Reliable testing
- Predictable behaviour

---

# ADR-006

Status

Accepted

Category

Engineering

Context

The project contains many interacting systems.

Decision

Every module shall have a single responsibility.

Rationale

Smaller focused modules are easier to understand, test, and maintain.

Consequences

- Reduced complexity
- Improved readability
- Easier debugging

---

# ADR-007

Status

Accepted

Category

Development

Context

AI will assist with implementation.

Decision

AI shall implement documented specifications only.

Rationale

Business logic must come from the project documentation rather than being invented during implementation.

Consequences

- Higher consistency
- Fewer hallucinations
- Easier reviews

---

# ADR-008

Status

Accepted

Category

Quality Assurance

Context

Compiler warnings often indicate future defects.

Decision

No module may be merged with compiler warnings.

Rationale

Maintaining a warning-free codebase improves long-term reliability.

Consequences

- Cleaner code
- Easier maintenance
- Fewer hidden defects

---

# ADR-009

Status

Accepted

Category

Repository

Context

Project documentation is a core asset.

Decision

Documentation shall be version-controlled alongside the source code.

Rationale

Specifications and implementation must evolve together.

Consequences

- Better traceability
- Improved onboarding
- Accurate project history

---

# ADR-010

Status

Accepted

Category

Development

Context

Large AI-generated implementations are difficult to review.

Decision

The engine shall be implemented module by module.

Rationale

Small incremental deliveries reduce risk and simplify testing.

Consequences

- Easier reviews
- Faster debugging
- Stable progress

---

# Future Decisions

Every significant engineering decision shall be added to this document before implementation.

Previous decisions must never be deleted.

If a decision changes, create a new ADR referencing the previous one instead of editing history.