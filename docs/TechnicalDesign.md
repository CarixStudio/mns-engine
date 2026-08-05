# MNS Trading Engine

# Technical Design Document (TDD)

Version: 1.0

Status: Approved

---

# Purpose

This document defines the technical implementation of the MNS Trading Engine.

It specifies the source code organization, interfaces, module boundaries, dependencies, lifecycle, and implementation rules.

This document is the primary reference for software implementation.

---

# Source Tree

src/

    Include/
        MNS/

    Experts/

    Indicators/

    Libraries/

    Scripts/

---

# Engine Layers

Layer 1

Core Types

↓

Layer 2

Analysis Engine

↓

Layer 3

Decision Engine

↓

Layer 4

Execution

↓

Layer 5

Presentation

---

# Module Order

001 MNSTypes

↓

002 SwingDetector

↓

003 StructureEngine

↓

004 MarketStructureEngine

↓

005 OrderFlowEngine

↓

006 DeliveryStructureEngine

↓

007 LiquidityEngine

↓

008 POIEngine

↓

009 ObjectiveEngine

↓

010 ConfirmationEngine

↓

011 EntryEngine

↓

012 RiskEngine

↓

013 Indicator

↓

014 Expert Advisor

---

# Dependency Rules

Allowed

MNSTypes

↓

SwingDetector

↓

StructureEngine

↓

MarketStructureEngine

↓

OrderFlowEngine

↓

LiquidityEngine

↓

POIEngine

↓

ObjectiveEngine

↓

ConfirmationEngine

↓

EntryEngine

↓

RiskEngine

↓

Indicator

↓

EA

Forbidden

Higher modules depending on lower implementation details.

Circular dependencies.

Cross-module business logic.

---

# Engine Lifecycle

Initialize Engine

↓

Load History

↓

Read Candle

↓

Detect Swings

↓

Update Structure

↓

Update Trend

↓

Update Liquidity

↓

Update POIs

↓

Validate Objective

↓

Confirm Setup

↓

Generate Entry

↓

Calculate Risk

↓

Publish State

---

# Module Interface Standard

Every module shall expose:

Initialize()

Update()

Reset()

GetState()

GetDiagnostics()

No module may expose internal implementation.

---

# Shared Models

Shared models originate only from:

MNSTypes

Every module consumes shared models.

No module owns another module's data.

---

# Error Handling

Every public method returns:

Success

Failure

Reason

Undefined behaviour is prohibited.

---

# Logging

Support:

Info

Warning

Error

Debug

Logging must be removable for production builds.

---

# Performance Goals

Incremental processing

Minimal allocations

Minimal copying

Cache reusable calculations

Avoid rescanning complete history

---

# Thread Safety

Modules shall avoid hidden mutable state.

Future parallel execution should remain possible.

---

# Versioning

Every public interface must preserve backward compatibility whenever practical.

Breaking changes require documentation.

---

# Acceptance Criteria

The design is accepted when:

- Every module has a defined interface.
- Dependencies are clear.
- Lifecycle is documented.
- No circular dependencies exist.
- Architecture matches implementation.