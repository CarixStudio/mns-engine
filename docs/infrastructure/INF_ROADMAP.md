# Infrastructure Development Roadmap (INF-ROADMAP)
# MNS Trading Engine
Version: 1.0
Status: Active

---

## 1. Overview

To maintain the incremental, modular build sequence of the MNS Trading Engine, the Shared Infrastructure consists of a single execution phase (Phase A — Core Infrastructure) containing reusable technical services.

All user interface, chart rendering, settings, and visual components are deferred and fully consolidated under Module 013 (Indicator Integration) and Module 014 (EA Integration) to prevent duplicated ownership and architectural overlap.

Each module must compile cleanly (0 errors, 0 warnings) and pass all associated test assertions before moving to the next.

---

## 2. Phase A — Core Infrastructure (Build Sequence)

These modules are completely independent of trading strategy rules and are prioritized for immediate implementation.

| Module ID | Module Name | Status | Target File | Description |
| :--- | :--- | :--- | :--- | :--- |
| **INF-000** | Core Module | `[x]` Complete | `Include/MNS/MNSCore.mqh` | Versioning, assertion macro, shared results. |
| **INF-001** | Logging System | `[x]` Complete | `Include/MNS/MNSLogger.mqh` | Compile-time conditional log targets. |
| **INF-002** | Utility Library | `[x]` Complete | `Include/MNS/MNSUtils.mqh` | Array, timezone, and math helper functions. |
| **INF-003** | ATR Helper | `[x]` Complete | `Include/MNS/MNSVolatility.mqh` | Array-based Average True Range metrics. |
| **INF-004** | Configuration System | `[x]` Complete | `Include/MNS/MNSConfig.mqh` | Parsing runtime profiles and input variables. |
| **INF-005** | Serialization | `[x]` Complete | `Include/MNS/MNSSerializer.mqh` | Interfaces for state restoration. |
| **INF-006** | Testing Framework | `[/]` In Progress | `Include/MNS/MNSTestSuite.mqh` | Unit test execution macros and mock structures. |
| **INF-007** | Performance Monitor | `[ ]` Not Started | `Include/MNS/MNSProfiler.mqh` | Telemetry profiling and microsecond metrics. |

---

## 3. Infrastructure Boundaries and Transitions

The Shared Infrastructure layer is strictly responsible for providing core, low-level technical services that can be consumed by strategy and trading modules. 

### What Infrastructure Modules Are and Own:
- **INF-000 to INF-007**: Core utilities, thread-safe logging, mathematical helpers, volatility computations (ATR), underlying configuration parsing, state serialization, mock testing engines, and performance measurement services.
- **Service-Only Execution**: These modules must compile and run as independent libraries. They are completely decoupled from trading rules, order management, or GUI rendering.

### What Infrastructure Modules Explicitly DO NOT Own:
- **No Rendering or Drawing**: Infrastructure does not create, manage, or delete MT5 chart objects (lines, labels, rectangles, etc.). All visualization is owned by Module 013 (Indicator Integration).
- **No User Interfaces or GUI Settings Controls**: Infrastructure does not manage user-facing panels, control inputs, or settings widgets on charts. Underlying data services (like configuration data parsing and persistence) belong to `INF-004 Configuration System`, while Module 013 and Module 014 build their respective user-facing GUI inputs and settings controllers on top of it.
- **No Trading Logic or Signals**: Infrastructure does not evaluate order flow, market structure breaks, liquidity pools, entry confirmations, or trade execution.
- **No Standalone UI Performance/Optimization Phase**: UI and rendering-specific performance optimization is handled incrementally and directly within Module 013 (utilizing the telemetry/measurement services from `INF-007 Performance Monitor` to profile rendering latency).

### Transition to Strategy:
Shared Infrastructure ends after **INF-007 Performance Monitor** is completed, verified, and passing tests. 

Once infrastructure is frozen, development resumes with the market analysis strategy modules:
1. **Module 005 — Order Flow Engine**
2. **Module 006 — Delivery Structure Engine**
3. **Module 007 — Liquidity Engine**
4. **Module 008 — POI Engine**
5. **Module 009 — Objective Engine**
6. **Module 010 — Confirmation Engine**
7. **Module 011 — Entry Engine**
8. **Module 012 — Risk Engine**

After the risk engine is finalized, the visual layers begin:
- **Module 013 — Indicator Integration**: Owns the entire indicator presentation, rendering, and visual settings layer.
- **Module 014 — EA Integration**: Owns EA execution, trade controls, and the interactive EA dashboard.

---

## 4. Release and Acceptance Criteria

The Shared Infrastructure is considered complete and ready when:
1. **Compilation**: Every module compiles cleanly in MetaEditor64.exe with **zero errors and zero warnings**.
2. **Verification**: The infrastructure test suite passes successfully.
3. **Zero Overhead**: In production mode (logging disabled), the logging and profiling macros are completely stripped at compile-time to maintain optimal performance.
