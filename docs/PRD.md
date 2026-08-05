# Product Requirements Document (PRD)

# MNS Trading Engine

Version: 1.0

Status: Draft

Project Codename: MNS Engine

---

# 1. Executive Summary

The MNS Trading Engine is a deterministic market analysis engine designed to transform discretionary Smart Money Concepts (SMC) into programmable trading logic.

Unlike traditional Expert Advisors that combine analysis and execution, the MNS Engine separates market analysis from trade execution. The engine becomes the single source of truth for market state, while indicators visualize the engine output and Expert Advisors execute trades based on validated signals.

The product will provide a modular architecture capable of supporting:

- Market Structure Analysis
- Order Flow Analysis
- Liquidity Detection
- Point of Interest Identification
- Objective Validation
- Entry Confirmation
- Risk Management
- Automated Trade Execution

The engine must remain deterministic, modular, testable, extensible, and non-repainting.

---

# 2. Vision

Build a professional-grade trading framework capable of consistently interpreting market structure according to predefined rules.

The system should become the core analysis engine that powers multiple interfaces, including:

- MT5 Indicators
- MT5 Expert Advisors
- Future Dashboards
- Backtesting Tools
- AI-assisted Analysis
- Future Multi-platform Implementations

---

# 3. Problem Statement

Current Smart Money trading is highly discretionary.

Different traders identify different:

- Swing Points
- BOS
- CHoCH
- Liquidity
- Order Blocks

leading to inconsistent decisions.

The objective of the MNS Engine is to eliminate ambiguity by converting every trading rule into deterministic logic.

---

# 4. Product Goals

The product shall:

- Eliminate subjective market interpretation.
- Produce deterministic market structure.
- Never repaint confirmed structure.
- Separate analysis from execution.
- Support modular expansion.
- Produce identical outputs from identical market data.
- Provide reusable components for future systems.

---

# 5. Product Scope

## In Scope

Market Structure

Swing Detection

Internal Structure

External Structure

Trend Classification

Market Phase Detection

Break of Structure (BOS)

Change of Character (CHoCH)

Liquidity Detection

Order Flow

Delivery Structure

Point of Interest Detection

Objective Validation

Trade Confirmation

Risk Calculation

Trade Execution

Trade Management

Indicator Visualization

Strategy Testing

Performance Logging

---

## Out of Scope

Machine Learning

News Trading

High Frequency Trading

Copy Trading

Portfolio Management

Broker Management

Cloud Synchronization

Social Trading

---

# 6. Target Users

Primary Users

Professional Traders

Institutional Traders

Smart Money Traders

Algorithmic Traders

Trading Educators

Secondary Users

Researchers

Developers

Quantitative Analysts

---

# 7. Product Overview

The system consists of three independent layers.

Layer 1

Analysis Engine

Responsible for interpreting market data.

Produces deterministic market state.

Layer 2

Visualization

Responsible for displaying analysis.

No trading logic.

Layer 3

Execution

Responsible for placing and managing trades.

Consumes engine outputs.

---

# 8. Functional Requirements

## 8.1 Market Structure Engine

The engine shall:

- Detect confirmed swing highs.
- Detect confirmed swing lows.
- Maintain internal structure.
- Maintain external structure.
- Detect Higher Highs.
- Detect Higher Lows.
- Detect Lower Highs.
- Detect Lower Lows.
- Detect BOS.
- Detect CHoCH.
- Classify trend.
- Classify market phase.
- Produce confidence scores.
- Produce structure strength.

---

## 8.2 Order Flow Engine

The engine shall:

- Detect bullish order flow.
- Detect bearish order flow.
- Track directional continuation.
- Detect transitions.

---

## 8.3 Liquidity Engine

The engine shall identify:

- Equal Highs
- Equal Lows
- Buy-side Liquidity
- Sell-side Liquidity
- Liquidity Sweeps

---

## 8.4 Point of Interest Engine

The engine shall identify valid trading locations based on preceding analysis modules.

---

## 8.5 Objective Engine

The engine shall validate trade objectives using engine outputs.

---

## 8.6 Confirmation Engine

The engine shall determine whether a trade setup satisfies all required confirmation criteria before signalling execution.

---

## 8.7 Entry Engine

The engine shall generate trade signals only after all prerequisite analysis modules have validated a setup.

---

## 8.8 Risk Engine

The engine shall support:

- Position sizing
- Stop Loss calculation
- Take Profit calculation
- Break Even
- Partial Close
- Trailing Stop
- Risk/Reward validation

---

## 8.9 Indicator

The indicator shall:

Display engine outputs visually.

The indicator shall not perform market analysis independently.

---

## 8.10 Expert Advisor

The Expert Advisor shall:

Consume outputs from the analysis engine.

Validate execution requirements.

Place trades.

Manage open positions.

Record trade events.

The EA shall not duplicate market analysis logic.

---

# 9. Non-Functional Requirements

The system shall be:

Deterministic

Modular

Extensible

Testable

Maintainable

High Performance

Non-Repainting

Object-Oriented

Fully Documented

Version Controlled

---

# 10. User Stories

As a trader,

I want consistent market structure so that I receive identical analysis from identical market data.

As a trader,

I want objective trade validation so that discretionary decisions are minimized.

As a developer,

I want modular components so that future features can be implemented without modifying unrelated systems.

As a researcher,

I want deterministic outputs so that historical testing remains reliable.

---

# 11. Constraints

The project will initially target MetaTrader 5.

Implementation language:

MQL5

All trading decisions must be rule-based.

No repainting is permitted.

Analysis modules must remain independent.

---

# 12. Risks

Incorrect interpretation of trading specifications.

Overly coupled modules.

Performance degradation on lower timeframes.

Specification changes during development.

Broker execution differences.

---

# 13. Success Metrics

The product shall:

Compile successfully.

Pass unit testing.

Produce deterministic outputs.

Never repaint confirmed structures.

Successfully complete historical backtests.

Successfully execute automated trades according to engine signals.

---

# 14. Milestones

Phase 1

Core Data Models

Phase 2

Market Structure Engine

Phase 3

Order Flow Engine

Phase 4

Liquidity Engine

Phase 5

Point of Interest Engine

Phase 6

Objective Engine

Phase 7

Confirmation Engine

Phase 8

Entry Engine

Phase 9

Risk Engine

Phase 10

Indicator

Phase 11

Expert Advisor

Phase 12

Backtesting

Phase 13

Optimization

---

# 15. Acceptance Criteria

The product is considered complete when:

- All modules compile without errors.
- Analysis modules produce deterministic outputs.
- Confirmed structures never repaint.
- Indicator accurately visualizes engine output.
- EA executes trades solely from engine signals.
- Historical testing completes successfully.
- Documentation is complete.
- Codebase passes review.

---

# 16. Future Roadmap

Future versions may include:

Multi-Timeframe Analysis

Python Backtesting Engine

REST API

Web Dashboard

Trade Journal

Analytics Dashboard

TradingView Adapter

cTrader Adapter

Broker Analytics

Machine Learning Research Modules

---

# Appendix A

Core Terminology

BOS

CHoCH

HH

HL

LH

LL

Liquidity

Order Flow

Delivery Structure

POI

Objective

Confirmation

Risk Management

Trade Management

---

# Appendix B

Project Documents

Architecture.md

TechnicalDesign.md

ModuleSpecifications.md

DevelopmentWorkflow.md

CodingStandards.md

TestingStrategy.md

AI_PROMPTS.md

Roadmap.md