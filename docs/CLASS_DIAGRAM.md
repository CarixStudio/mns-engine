# MNS Trading Engine
# Class Diagram
Version: 1.0
Status: Approved Foundation

---

# Purpose

This document defines every major class that will exist in the MNS Trading Engine.

It serves as the blueprint for implementation and ensures that every module has a single responsibility.

The goal is to prevent duplicated logic, circular dependencies, and architectural drift.

---

# Architecture

                    +---------------------+
                    |  IndicatorController|
                    +----------+----------+
                               |
                               |
            +------------------+------------------+
            |                                     |
            |                                     |
            ▼                                     ▼
      Core Analysis                    Rendering System
            |                                     |
            |                                     |
            ▼                                     ▼
      MarketState                     DashboardRenderer
            |                          StructureRenderer
            |                          SwingRenderer
            ▼                          ZoneRenderer
      Expert Advisor

---

# Core Layer

## CMNSEngine

Purpose

Main engine coordinator.

Responsibilities

- Initialize modules
- Execute update cycle
- Maintain engine lifecycle
- Publish current market state

Owns

- CSwingDetector
- CStructureEngine
- CBreakEngine
- CLiquidityEngine
- CPOIEngine
- CMarketStateEngine

Public Methods

Initialize()

Reset()

Update()

GetState()

Shutdown()

---

## CSwingDetector

Purpose

Detect confirmed swing highs and lows.

Responsibilities

- Detect pivots
- Confirm swings
- Store swings
- Reject invalid swings

Produces

SSwingPoint

Consumes

Price data

---

## CStructureEngine

Purpose

Build market structure from confirmed swings.

Responsibilities

- HH
- HL
- LH
- LL
- Equal High
- Equal Low

Produces

EStructureType

Consumes

CSwingDetector

---

## CBreakEngine

Purpose

Detect structural breaks.

Responsibilities

- BOS
- Internal BOS
- CHoCH

Produces

SStructureBreak

Consumes

Structure Engine

---

## CLiquidityEngine

Purpose

Detect liquidity.

Responsibilities

- Buy-side liquidity
- Sell-side liquidity
- Liquidity sweeps

Consumes

Structure

Swings

---

## CPOIEngine

Purpose

Detect Points of Interest.

Responsibilities

- Order Blocks
- Fair Value Gaps
- Premium
- Discount
- Equilibrium

Consumes

Liquidity

Structure

---

## CMarketStateEngine

Purpose

Produce one unified market state.

Produces

SMarketState

Consumes

All previous modules.

---

# Rendering Layer

Rendering classes never perform analysis.

---

## CSwingRenderer

Draws

- Swing High
- Swing Low

Consumes

SSwingPoint

---

## CStructureRenderer

Draws

- HH
- HL
- LH
- LL
- BOS
- CHoCH

Consumes

Market State

---

## CZoneRenderer

Draws

- Order Blocks
- FVG
- Liquidity
- Premium
- Discount

Consumes

POI Engine

---

## CDashboardRenderer

Draws

Dashboard

Displays

- Symbol
- Timeframe
- Trend
- Phase
- BOS
- CHoCH
- Liquidity
- Active POI

Consumes

SMarketState

---

# Indicator Layer

## CIndicatorController

Purpose

Coordinates indicator execution.

Responsibilities

Initialize engine.

Update engine.

Call renderers.

Handle user inputs.

Refresh chart.

Never performs analysis.

Never performs trade execution.

---

# EA Layer

## CEAController

Purpose

Automated trade execution.

Responsibilities

Read Market State.

Apply Risk Rules.

Manage Positions.

Execute Orders.

Never computes market structure.

Consumes

SMarketState

---

# Dependency Rules

Allowed

Engine

↓

Market State

↓

Renderer

↓

Indicator

↓

EA

Forbidden

Renderer

↓

Engine

EA

↓

Renderer

Dashboard

↓

Analysis

---

# Object Lifetime

Singleton

CMNSEngine

Persistent

All analysis modules.

Transient

Chart objects.

Dashboard objects.

---

# Update Cycle

New Tick

↓

Engine Update

↓

Market State Update

↓

Renderer Update

↓

Dashboard Refresh

↓

Chart Refresh

↓

Waiting

---

# Future Classes

CSessionEngine

CRiskEngine

CAlertEngine

CLoggingEngine

CPerformanceProfiler

Reserved for future implementation.

---

# Naming Convention

Classes

Prefix

C

Examples

CMNSEngine

CSwingDetector

CStructureRenderer

Structures

Prefix

S

Examples

SSwingPoint

SStructureBreak

SMarketState

Enumerations

Prefix

E

Examples

ETrend

EStructureType

ESwingLevel

Constants

Prefix

MNS_

Example

MNS_MAX_SWINGS

---

# Design Principles

Single Responsibility

Dependency Direction

Composition over Inheritance

Deterministic Behaviour

Stateless Rendering

Reusable Analysis Engine

Zero Duplicate Logic

Zero Circular Dependencies

Production Ready
