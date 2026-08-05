# MNS Trading Engine

# Testing Strategy

Version: 1.0

Status: Approved

---

# Purpose

This document defines the testing methodology for the MNS Trading Engine.

Testing is mandatory for every module.

No component may be merged without successful validation.

---

# Testing Objectives

Ensure the engine is:

- Correct
- Deterministic
- Stable
- Performant
- Non-repainting
- Production ready

---

# Testing Pyramid

Level 1

Unit Tests

↓

Level 2

Integration Tests

↓

Level 3

Visual Tests

↓

Level 4

Strategy Tester

↓

Level 5

Regression Tests

---

# Unit Testing

Each module shall be tested independently.

Objectives

- Verify expected outputs
- Verify boundary conditions
- Verify invalid inputs
- Verify error handling
- Verify deterministic behaviour

Examples

SwingDetector

- Detect swing highs
- Detect swing lows
- Reject invalid swings
- Handle equal highs
- Handle equal lows

RiskEngine

- Calculate lot size
- Calculate stop loss
- Calculate take profit
- Reject invalid risk values

---

# Integration Testing

Verify communication between modules.

Examples

SwingDetector

↓

StructureEngine

↓

OrderFlowEngine

↓

LiquidityEngine

Expected Result

Correct information passes through every layer.

---

# Visual Testing

Applicable to indicator modules.

Objectives

Compare engine output against the chart.

Verify

- Swing locations
- BOS
- CHoCH
- Liquidity
- POIs
- Entries

Visual output must match documented behaviour.

---

# Historical Validation

Run historical charts.

Verify

- Stability
- Determinism
- Non-repainting

Compare multiple executions.

Identical market data must produce identical results.

---

# Strategy Tester

Validate using MT5 Strategy Tester.

Required Tests

- Every Tick
- OHLC
- Visual Mode
- Multiple symbols
- Multiple timeframes

Metrics

- Trade count
- Win rate
- Drawdown
- Profit factor
- Expectancy
- Average RR

---

# Regression Testing

Whenever a new module is added:

Retest all previous modules.

Verify

- Existing behaviour unchanged
- Interfaces unchanged
- Outputs unchanged

Regression failures block merges.

---

# Performance Testing

Measure

- Execution time
- Memory usage
- CPU usage
- Tick processing time

Performance regressions must be investigated.

---

# Stress Testing

Test

- Long histories
- High volatility
- Low volatility
- News spikes
- Sparse data
- Missing candles

The engine must fail gracefully.

---

# Error Testing

Verify handling of:

- Invalid prices
- Missing bars
- Zero volume
- Invalid indices
- Empty arrays
- Broker errors

No crashes are acceptable.

---

# Acceptance Testing

Each module shall define acceptance criteria before implementation.

Acceptance tests are completed only when every requirement is satisfied.

---

# Definition of Test Complete

Testing is complete when:

- Unit tests pass
- Integration tests pass
- Visual tests pass
- Strategy Tester passes
- Regression tests pass
- Performance targets met
- No repainting observed
- Documentation updated

---

# Bug Severity

Critical

- Crash
- Wrong trades
- Repainting
- Data corruption

High

- Incorrect calculations
- Incorrect signals

Medium

- Visual issues
- Performance degradation

Low

- Documentation
- Formatting

---

# Release Criteria

No release is permitted if:

- Critical bugs exist
- High severity bugs remain unresolved
- Regression tests fail
- Modules fail compilation
- Deterministic behaviour is violated