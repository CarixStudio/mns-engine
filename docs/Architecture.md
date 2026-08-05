# MNS Trading Engine

# System Architecture

Version: 1.0

---

# 1. Purpose

This document defines the software architecture of the MNS Trading Engine.

It specifies how every subsystem interacts while maintaining modularity, determinism, and extensibility.

---

# 2. Architectural Principles

The engine follows these principles:

• Deterministic
• Non-Repainting
• Modular
• Layered
• Event Driven
• Testable
• Extensible
• Single Source of Truth
• Separation of Concerns

---

# 3. High-Level Architecture

```
                Market Data
                     │
                     ▼
        Market Structure Engine
                     │
                     ▼
          Order Flow Engine
                     │
                     ▼
         Delivery Structure Engine
                     │
                     ▼
           Liquidity Engine
                     │
                     ▼
             POI Engine
                     │
                     ▼
          Objective Engine
                     │
                     ▼
         Confirmation Engine
                     │
                     ▼
            Entry Engine
                     │
                     ▼
             Risk Engine
                     │
                     ▼
          Execution Layer (EA)
                     │
             Indicator Layer
```

---

# 4. Layered Architecture

## Layer 1

Market Data

Responsibilities

- Read OHLC
- Read Tick Data
- Read Volume
- Read Time

Output

Normalized Market Data

---

## Layer 2

Analysis Engine

Contains

- Market Structure
- Order Flow
- Delivery
- Liquidity
- POI
- Objective

Produces

Market State

---

## Layer 3

Decision Engine

Contains

- Confirmation
- Entry
- Risk

Produces

Trade Decision

---

## Layer 4

Execution Layer

Contains

EA

Responsibilities

- Place Order
- Modify Order
- Close Order
- Log Trades

---

## Layer 5

Presentation Layer

Contains

Indicator

Responsibilities

Visualize Engine Output

No Trading Logic

---

# 5. Core Modules

## Market Structure Engine

Responsibilities

- Swing Detection
- HH
- HL
- LH
- LL
- BOS
- CHoCH
- Trend
- Market Phase

Consumes

OHLC

Produces

Market Structure State

---

## Order Flow Engine

Consumes

Market Structure State

Produces

Directional Bias

---

## Delivery Structure Engine

Consumes

Order Flow

Produces

Institutional Delivery Information

---

## Liquidity Engine

Consumes

Structure

Produces

Liquidity Zones

---

## POI Engine

Consumes

Liquidity

Produces

Trade Locations

---

## Objective Engine

Consumes

POI

Produces

Trade Objectives

---

## Confirmation Engine

Consumes

All Prior Modules

Produces

Confirmed Trade Setup

---

## Entry Engine

Consumes

Confirmed Setup

Produces

Entry Signal

---

## Risk Engine

Consumes

Entry Signal

Produces

SL

TP

Lot Size

Trade Parameters

---

# 6. Data Flow

Every candle update follows this order

Market Data

↓

Structure

↓

Order Flow

↓

Delivery

↓

Liquidity

↓

POI

↓

Objective

↓

Confirmation

↓

Entry

↓

Risk

↓

EA

↓

Indicator

---

# 7. Engine Contracts

Every module shall

Accept Input

↓

Process

↓

Return Output

No module may directly manipulate another module.

Communication occurs through shared data models.

---

# 8. Shared Data Models

The following structures are shared

Market State

Swing

Structure Break

Liquidity Zone

POI

Entry Signal

Trade

Risk Profile

---

# 9. Error Handling

Modules must

Fail Gracefully

Return Status

Log Errors

Avoid Undefined States

---

# 10. Performance

Target

Real-time execution

Minimal memory allocations

O(1) lookups where possible

Incremental updates

---

# 11. Testing Strategy

Every module

Compiles independently

Unit Tested

Integration Tested

Visual Tested

Backtested

---

# 12. Future Extensions

Dashboard

REST API

TradingView

Python

cTrader

FIX API

AI Analysis

Cloud Analytics

---

# 13. Design Rules

No repainting.

No duplicated analysis.

Indicator never analyzes.

EA never analyzes.

Engine owns all market intelligence.

Every module has a single responsibility.

Every decision is deterministic.

All public interfaces are documented.