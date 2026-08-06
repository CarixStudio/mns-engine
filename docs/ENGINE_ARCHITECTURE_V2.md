# MNS Trading Engine
# Engine Architecture v2
Version: 2.0
Status: Approved
Author: Carix Studio

---

# 1. Purpose

This document defines the complete architecture of the MNS Trading Engine.

The engine is designed as a reusable analysis framework powering both:

• MNS Indicator
• MNS Expert Advisor

The Indicator is delivered first for validation.

The EA is built only after the Indicator has been approved.

---

# 2. Architecture

                    Market Data
                         │
                         ▼
                 Core Analysis Engine
                         │
     ┌───────────────────┼────────────────────┐
     │                   │                    │
     ▼                   ▼                    ▼
 Chart Renderer    Dashboard Renderer    Alert Renderer
     │                   │                    │
     └───────────────────┴────────────────────┘
                         │
                  MNS Indicator
                         │
                  Client Validation
                         │
                  Approved Engine
                         │
                         ▼
                  MNS Expert Advisor
                         │
                  Trade Execution

---

# 3. Core Engine

The Core Engine performs all market analysis.

Responsibilities:

• Swing Detection
• Market Structure
• BOS Detection
• CHoCH Detection
• Equal High / Low Detection
• Liquidity Detection
• Order Block Detection
• Fair Value Gap Detection
• Premium / Discount Calculation
• Session Detection
• Market State Management

The Core Engine never:

• Draws objects
• Places trades
• Creates alerts

---

# 4. Rendering Layer

The Rendering Layer consumes the Core Engine state.

Responsibilities:

• Draw chart objects
• Draw labels
• Draw dashboard
• Draw zones
• Draw structure
• Update visuals

Never performs analysis.

---

# 5. Indicator Layer

Responsibilities:

• Initialize Engine

• Update Engine

• Call Renderers

• Handle User Inputs

• Refresh Chart

---

# 6. EA Layer

Responsibilities:

• Read Engine State

• Risk Management

• Position Sizing

• Trade Execution

• Position Management

• Logging

Never duplicates analysis.

---

# 7. Module Dependency

Module 001
MNSTypes

↓

Module 002
SwingDetector

↓

Module 003
StructureEngine

↓

Module 004
BOS Engine

↓

Module 005
CHoCH Engine

↓

Module 006
Liquidity Engine

↓

Module 007
POI Engine

↓

Module 008
Market State Engine

↓

Renderers

↓

Indicator

↓

EA

---

# 8. Data Flow

Price

↓

Swing Detection

↓

Structure

↓

Market State

↓

Indicator Rendering

↓

EA Decisions

---

# 9. Rendering Pipeline

Engine State

↓

Swing Renderer

↓

Structure Renderer

↓

Zone Renderer

↓

Dashboard Renderer

↓

Chart Refresh

---

# 10. Performance Rules

Incremental updates only.

No full redraw.

Reuse chart objects.

Maximum performance.

No repainting after confirmation.

---

# 11. Development Principles

Single Responsibility

Modular Design

Deterministic Behaviour

Zero Duplicate Logic

Zero Circular Dependencies

Compile Clean

Production Ready

---

# 12. Deliverables

Phase 1

Core Engine

Phase 2

Indicator

Phase 3

Client Validation

Phase 4

EA
