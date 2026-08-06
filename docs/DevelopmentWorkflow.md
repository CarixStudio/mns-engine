# MNS Trading Engine

# Development Workflow

Version: 1.0

Status: Approved

---

# Purpose

This document defines the official software development lifecycle for the MNS Trading Engine.

Every feature, module, bug fix, and enhancement shall follow this workflow.

No implementation may bypass any stage.

---

# Core Philosophy

The engine is built specification-first.

Documentation drives implementation.

Implementation drives testing.

Testing drives release.

---

# Development Lifecycle

```
Client Specification
        │
        ▼
Product Documentation
        │
        ▼
Module Specification
        │
        ▼
AI Implementation Prompt
        │
        ▼
Code Generation
        │
        ▼
Architecture Review
        │
        ▼
Compile
        │
        ▼
Fix Compilation Errors
        │
        ▼
Static Code Review
        │
        ▼
Visual Testing
        │
        ▼
Strategy Tester
        │
        ▼
Regression Testing
        │
        ▼
Git Commit
        │
        ▼
Release
```

---

# Phase 1 — Specification

Before writing code:

- Review client requirements
- Update PRD if necessary
- Update Architecture if required
- Complete Module Specification
- Define Acceptance Criteria

No coding begins without an approved specification.

---

# Phase 2 — AI Prompt Preparation

Each implementation requires a dedicated prompt.

The prompt shall include:

- Module context
- Responsibilities
- Inputs
- Outputs
- Dependencies
- Acceptance criteria
- Coding standards
- Implementation constraints

AI shall never infer undocumented trading logic.

---

# Phase 3 — Code Generation

The AI generates production-quality MQL5 code.

Requirements:

- Complete implementation
- No implementation placeholders
- Fully documented
- Standards compliant

TODOs are permitted ONLY for rules that are missing or ambiguous in
the strategy document. Every such TODO must:

1. Be documented in docs/TODO_STRATEGY.md with its OPEN-xxx identifier.
2. Include a comment citing the exact missing rule.
3. Be resolved before the module is marked complete.

TODOs that represent missing implementation (as opposed to missing
strategy specification) are not permitted.

---

# Phase 4 — Architecture Review

Review:

- Responsibilities
- Dependencies
- Public interfaces
- Code organization
- Naming
- Compliance with architecture

Reject implementations that violate design principles.

---

# Phase 5 — Compilation

Compile in MetaEditor.

Requirements:

- Zero errors
- Zero warnings

Compilation failures must be resolved before testing.

---

# Phase 6 — Static Review

Verify:

- Readability
- Maintainability
- Complexity
- Naming
- Documentation
- Performance

Remove unnecessary code.

---

# Phase 7 — Functional Testing

Validate module behaviour.

Confirm:

- Expected outputs
- Edge cases
- Invalid inputs
- Boundary conditions

---

# Phase 8 — Visual Validation

Where applicable:

- Attach indicator
- Compare drawings
- Verify market structure
- Confirm signals

Engine outputs must match the specification.

---

# Phase 9 — Strategy Tester

Execute historical testing.

Validate:

- Consistency
- Determinism
- Stability
- Execution behaviour

---

# Phase 10 — Regression Testing

Confirm existing functionality remains unchanged.

Every completed module must continue working after new modules are added.

---

# Phase 11 — Git Commit

Commit only after:

- Tests pass
- Review complete
- Documentation updated

Commit message examples:

feat: implement SwingDetector

fix: correct BOS validation

refactor: simplify RiskEngine

docs: update Architecture

---

# Pull Request Checklist

Every merge must confirm:

- Documentation updated
- Specification satisfied
- Coding standards followed
- Zero compiler warnings
- Tests passed
- Acceptance criteria met

---

# Bug Workflow

Bug Report

↓

Reproduce

↓

Root Cause Analysis

↓

Fix

↓

Compile

↓

Test

↓

Regression Test

↓

Commit

↓

Release

---

# Feature Workflow

Specification

↓

Architecture

↓

Module Design

↓

AI Prompt

↓

Implementation

↓

Compile

↓

Test

↓

Review

↓

Merge

---

# AI Usage Policy

AI is an implementation assistant.

AI does not define architecture.

AI does not invent trading rules.

AI does not modify specifications.

Every AI-generated output must be reviewed by a developer before acceptance.

---

# Definition of Complete

A feature is complete only when:

- Specification approved
- Implementation complete
- Architecture reviewed
- Compiles successfully
- Tests passed
- Documentation updated
- Accepted into source control

No exceptions.