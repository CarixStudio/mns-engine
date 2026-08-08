# Infrastructure Product Requirements Document (INF-PRD)
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Executive Summary

This document defines the product requirements for the Shared Infrastructure layer of the MNS Trading Engine. 

As the project shifts from implementing specific market analysis strategy engines (Modules 001–004) to building the foundational codebase, the Shared Infrastructure layer will provide standard utilities, versioning, diagnostics, error handling, performance profiling, and mocking tools. 

To ensure architectural separation and predictability, all components described in this document must contain **zero trading strategy or market analysis logic**.

---

## 2. Goals and Scope

### Goals
- Establish a uniform, lightweight logging system with compile-time overhead control.
- Consolidate standard array, time, and mathematical operations into a central utility library.
- Provide a standalone, decoupled ATR calculation helper that operates directly on numeric arrays without indicator handles.
- Create a configuration system for loading runtime inputs and tuning execution parameters.
- Define standard serialization and deserialization interfaces for saving/restoring historical structures.
- Implement an isolated unit-testing framework and mocking utilities to verify calculations in dry-run scenarios.
- Build a lightweight performance profiling tool to trace execution latency and identify bottlenecks.

### Out of Scope
- Trading rules, entry conditions, and exit logic.
- Trend detection, structural breaks, or pivot calculations.
- Direct rendering of graphics, dashboard interfaces, or terminal chart alerts (fully consolidated under Module 013 — Indicator Integration and Module 014 — EA Integration).

---

## 3. Functional Requirements

### 3.1 INF-000 — Core Module
- Expose global engine constants (versioning boundaries, limit caps).
- Define shared error and result codes (`HRESULT`-style) to enforce predictable return behaviors.
- Enforce developer assertions (`MNS_Assert`) that resolve at compile-time or fail-fast in development.

### 3.2 INF-001 — Logging System
- Support five standard log levels: `DEBUG`, `INFO`, `WARNING`, `ERROR`, and `FATAL`.
- Support multiple log targets: MT5 terminal Experts tab, local files on disk, or user alerts.
- Support compile-time stripping using macro flags (e.g., `#ifndef MNS_LOG_DISABLE`) to ensure zero performance overhead in production.

### 3.3 INF-002 — Utility Library
- Provide array manipulation utilities (safe resizing, sorting, binary search, cloning).
- Provide timezone conversion functions (Broker time to GMT/EST) and daily session boundary calculations.
- Standard MQL5 overrides to prevent memory leaks in dynamic arrays.

### 3.4 INF-003 — ATR Helper
- Perform ATR calculations using raw `high[]`, `low[]`, and `close[]` price arrays.
- Avoid calling the MT5 native indicator handle `iATR()`, preventing resource leaks and execution freezes.

### 3.5 INF-004 — Configuration System
- Parse input variables, configurations, and profile setups.
- Validate configuration boundaries at runtime, failing back gracefully to default parameters on error.

### 3.6 INF-005 — Serialization Interfaces
- Define standard interfaces (`IMNSSerializable`) for archiving swing points, market structures, and break histories to files.
- Enable state loading during initialization to avoid re-calculating the entire historical bar database.

### 3.7 INF-006 — Testing Framework
- Provide isolated test verification macros (`AssertTrue`, `AssertEqual`).
- Provide mock-object models to inject synthetic market rates and confirm engine module outputs deterministically.

### 3.8 INF-007 — Performance Monitor
- Track execution time of critical paths (e.g., `Update()` loops) using high-resolution microsecond timers.
- Expose runtime telemetry and profiling metrics to detect execution spikes.

---

## 4. Non-Functional Requirements
- **Deterministic**: The utility, configuration, and performance modules must not contain state that produces unpredictable outputs.
- **Zero Allocations in Hot Paths**: All hot-path methods (run on every new bar or tick) must avoid dynamic memory allocation.
- **MQL5 Compatibility**: All class declarations must comply with MQL5 object lifecycle limitations (no circular references, pass arrays by reference).
