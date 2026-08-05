# MNS Trading Engine

# AI Prompting Standard

Version: 1.0

Status: Approved

---

# Purpose

This document defines the standard for all AI-assisted development within the MNS Trading Engine.

Every implementation prompt shall follow this format.

The objective is to ensure consistency, reduce hallucinations, and produce production-quality code.

---

# AI Role

The AI acts as a Senior MQL5 Software Engineer.

The AI does not:

- Design architecture
- Invent trading rules
- Modify specifications
- Change engineering decisions

The AI only implements approved specifications.

---

# Required Context

Every prompt must include:

- Project overview
- Current module
- Module specification
- Dependencies
- Coding standards
- Engineering decisions
- Acceptance criteria

---

# Required Attachments

Unless otherwise stated, every implementation prompt shall include:

- PRD.md
- Architecture.md
- CodingStandards.md
- DevelopmentWorkflow.md
- Decisions.md
- Module Specification
- Previous dependent module specifications (if required)

---

# Standard Prompt Structure

Every implementation prompt shall contain the following sections.

## 1. Role

Define the AI's responsibility.

---

## 2. Project Context

Describe the project and architecture.

---

## 3. Current Module

State exactly which module is being implemented.

---

## 4. Responsibilities

List only the responsibilities of that module.

---

## 5. Dependencies

Specify required modules.

Specify forbidden dependencies.

---

## 6. Requirements

List functional requirements.

List non-functional requirements.

---

## 7. Constraints

Examples:

- No repainting
- No placeholders
- No TODO comments
- No duplicated logic
- No global state unless justified

---

## 8. Coding Standards

Reference CodingStandards.md.

---

## 9. Deliverables

Specify exactly what files must be produced.

Example

- SwingDetector.mqh
- Inline documentation
- Public interfaces
- Helper classes if required

---

## 10. Acceptance Criteria

Define measurable success.

Example

- Compiles successfully
- Zero warnings
- Unit-test ready
- Matches specification

---

## 11. Output Rules

The AI shall:

- Return complete code
- Explain implementation
- State assumptions
- Identify edge cases

The AI shall not:

- Invent trading logic
- Skip requirements
- Produce pseudocode
- Produce incomplete implementations

---

# Prompt Review Checklist

Before using a prompt verify:

- Module specification attached
- Dependencies attached
- Acceptance criteria included
- Coding standards referenced
- Deliverables clearly defined

---

# AI Review Checklist

After receiving AI output verify:

- Specification followed
- Architecture preserved
- Coding standards followed
- Zero placeholders
- Zero TODOs
- Compiles successfully
- No unnecessary complexity

---

# Escalation Rules

If the AI encounters ambiguity it shall:

Stop implementation.

List the ambiguity.

Request clarification.

The AI must never guess trading behaviour.

---

# Definition of Success

A prompt is considered successful when:

- AI produces production-ready code.
- No undocumented assumptions are made.
- The implementation matches the approved specification.
- The code compiles successfully.
- The module passes review and testing.