# Engineering Coding Standards

Version: 1.0

Status: Approved

Applies To:

- Entire Repository
- All Future Modules
- All AI Generated Code
- All Human Contributions

---

# 1. Purpose

This document defines the engineering standards for the MNS Trading Engine.

Every module, document, prompt, and source file must comply with these standards.

These rules exist to ensure consistency, maintainability, determinism, and production-quality software.

---

# 2. Engineering Principles

The codebase shall always be:

- Deterministic
- Modular
- Testable
- Readable
- Maintainable
- Extensible
- Production Ready

No shortcuts are permitted.

---

# 3. General Rules

Every file must have a single responsibility.

Every class must have a single responsibility.

Every function must have one clear purpose.

No duplicated logic.

No dead code.

No experimental code.

No commented-out implementations.

No placeholder functions.

No TODO comments.

No unfinished implementations.

---

# 4. Language Standards

Target Language

MQL5

Coding Style

Modern Object-Oriented Programming

Required

Classes

Structures

Enumerations

Namespaces where appropriate

Header (.mqh) separation

Implementation (.mq5) separation where practical

---

# 5. Naming Conventions

## Classes

PascalCase

Example

SwingDetector

RiskEngine

MarketStructureEngine

---

## Structures

Prefix

S

Example

SSwingPoint

SMarketState

SRiskProfile

---

## Enumerations

Prefix

E

Example

ETrend

EMarketPhase

EStructureType

---

## Functions

PascalCase

Examples

DetectSwing()

CalculateRisk()

ValidateObjective()

GetTrend()

---

## Variables

camelCase

Examples

currentTrend

lastSwing

entryPrice

riskPercent

---

## Constants

UPPER_SNAKE_CASE

Examples

MAX_SWINGS

INVALID_INDEX

DEFAULT_RISK

---

## Member Variables

Prefix

m_

Example

m_currentTrend

m_lastSwing

m_structure

---

## Boolean Variables

Prefix

is

has

can

Examples

isBullish

hasLiquidity

canTrade

---

# 6. File Naming

Classes

ClassName.mqh

Examples

SwingDetector.mqh

RiskEngine.mqh

LiquidityEngine.mqh

No spaces.

No abbreviations unless industry standard.

---

# 7. Folder Structure

src/

Include/

Experts/

Indicators/

Libraries/

Scripts/

Every module belongs in exactly one folder.

---

# 8. Documentation Standards

Every public class must include

Purpose

Responsibilities

Dependencies

Usage Notes

Every public method must include

Description

Parameters

Returns

Exceptions

Every complex algorithm must explain

Why

not only

How.

---

# 9. Function Rules

Functions should generally perform one task.

Prefer early returns.

Avoid nested conditionals where possible.

Avoid side effects.

Avoid hidden state.

Avoid global dependencies.

---

# 10. Class Rules

A class should own one concept.

Example

Correct

SwingDetector

Incorrect

SwingDetectorAndRiskManager

Classes communicate through clearly defined interfaces.

---

# 11. Error Handling

Never ignore failures.

Validate inputs.

Return meaningful status.

Protect against invalid indexes.

Protect against invalid bars.

Protect against division by zero.

Protect against null references.

Never silently fail.

---

# 12. Logging

Logs should be:

Clear

Useful

Actionable

Never spam the terminal.

Debug logging must be removable.

---

# 13. Performance Rules

Avoid unnecessary allocations.

Avoid repeated calculations.

Cache expensive operations.

Process only new bars where possible.

Avoid scanning the entire history every tick.

Optimize before adding complexity.

---

# 14. Memory Rules

Avoid unnecessary object creation.

Reuse buffers.

Avoid memory leaks.

Avoid oversized arrays.

Initialize all structures.

---

# 15. Determinism

The engine must always produce identical outputs for identical inputs.

Random behaviour is forbidden.

Time-dependent behaviour is forbidden unless explicitly required.

---

# 16. Repainting

Confirmed analysis shall never repaint.

Historical results must remain stable.

If information is provisional, it must be explicitly identified as provisional.

---

# 17. Dependencies

Lower-level modules shall never depend on higher-level modules.

Example

Allowed

SwingDetector
↓

StructureEngine

↓

LiquidityEngine

Forbidden

RiskEngine
↓

SwingDetector

---

# 18. Code Review Checklist

Before merging any module confirm:

✓ Compiles successfully

✓ Zero compiler warnings

✓ Zero placeholder code

✓ Naming standards followed

✓ Documentation complete

✓ No duplicated logic

✓ No unnecessary complexity

✓ Acceptance criteria satisfied

✓ Module tests passed

---

# 19. Git Standards

Commit messages must be descriptive.

Examples

feat: implement SwingDetector

fix: correct BOS detection

refactor: simplify StructureEngine

docs: update Architecture

Avoid commits such as

update

fix

changes

work

---

# 20. AI Generated Code

AI code is treated as first draft.

Every generated file must be:

Reviewed

Compiled

Tested

Validated

Documented

before being committed.

AI must never invent trading rules.

AI must only implement documented specifications.

---

# 21. Definition of Done

A module is complete only when:

- Specification approved
- Code generated
- Architecture reviewed
- Compiles successfully
- Passes tests
- Documentation updated
- Acceptance criteria satisfied
- Committed to Git

No module may be considered complete before all criteria are met.

---

# 22. Non-Negotiable Rules

- No repainting.
- No duplicated analysis.
- No hidden logic.
- No undocumented behaviour.
- No coupling between unrelated modules.
- No direct broker interaction outside the execution layer.
- The analysis engine is the single source of truth.
- The indicator only visualizes.
- The EA only executes.
- Every engineering decision must preserve determinism.