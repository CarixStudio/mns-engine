# MNS Trading Engine

> A deterministic, modular Smart Money Concepts (SMC) trading engine for MetaTrader 5.

---

## Overview

The MNS Trading Engine is a professional-grade trading framework designed to convert discretionary Smart Money Concepts into deterministic, rule-based software.

Rather than combining market analysis and trade execution in a single Expert Advisor, the project separates responsibilities into independent modules.

The engine becomes the single source of truth for market analysis while different consumers (Indicators, Expert Advisors, Dashboards, APIs) utilize its output.

---

# Project Goals

- Deterministic market analysis
- Non-repainting structure detection
- Modular architecture
- Reusable trading engine
- Professional engineering standards
- Comprehensive documentation
- AI-assisted development workflow
- Production-ready MQL5 implementation

---

# Repository Structure

```
mns-engine/
│
├── docs/
│   ├── PRD.md
│   ├── Architecture.md
│   ├── TechnicalDesign.md
│   ├── Roadmap.md
│   ├── CodingStandards.md
│   ├── DevelopmentWorkflow.md
│   ├── Decisions.md
│   ├── TestingStrategy.md
│   ├── AI_PROMPTS.md
│   └── modules/
│
├── Include/
│   └── MNS/
│       └── MNSTypes.mqh
├── Experts/
│   └── MNS_TestHarness/
├── Indicators/
├── Scripts/
├── Libraries/
│
├── tools/
│   ├── build.ps1
│   ├── deploy.ps1
│   └── clean.ps1
│
├── tests/
├── assets/
├── .github/
│
├── README.md
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

---

# System Architecture

```
Market Data
      │
      ▼
Market Structure
      │
      ▼
Order Flow
      │
      ▼
Liquidity
      │
      ▼
Point of Interest
      │
      ▼
Objective
      │
      ▼
Confirmation
      │
      ▼
Entry
      │
      ▼
Risk
      │
      ▼
Expert Advisor
      │
Indicator
```

---

# Development Philosophy

The MNS Trading Engine follows a documentation-first development process.

Every module progresses through the following lifecycle:

1. Product Requirements
2. Architecture
3. Module Specification
4. AI Implementation Prompt
5. Source Code
6. Compilation
7. Testing
8. Review
9. Git Commit

---

# Core Modules

| Module | Status |
|---------|--------|
| MNSTypes | Completed |
| SwingDetector | Completed |
| StructureEngine | Completed |
| BreakDetector | Completed |
| OrderFlowEngine | Completed |
| DeliveryStructureEngine | Completed |
| LiquidityEngine | Completed |
| POIEngine | Completed |
| ObjectiveEngine | Completed |
| ConfirmationEngine | Completed |
| EntryEngine | Planned |
| RiskEngine | Planned |
| Indicator Integration | Planned |
| EA Integration | Planned |

---

# Technology Stack

- MetaTrader 5
- MQL5
- Git
- GitHub
- MetaEditor
- Visual Studio Code

---

# Documentation

| Document | Description |
|----------|-------------|
| PRD.md | Product Requirements |
| Architecture.md | System Architecture |
| TechnicalDesign.md | Technical Implementation |
| Roadmap.md | Development Plan |
| CodingStandards.md | Coding Standards |
| DevelopmentWorkflow.md | Development Lifecycle |
| Decisions.md | Engineering Decisions |
| TestingStrategy.md | Testing Process |
| AI_PROMPTS.md | AI Prompt Standard |
| RepositoryGuide.md | Repository Manual |

---

## Development Workflow

1. Develop inside VS Code.

2. Run

```powershell
.\tools\build.ps1
```

3. Open MetaEditor.

4. Press F7.

5. Open MT5.

6. Test.

7. Commit changes.

---

# Build Tools

| Script | Purpose |
|---|---|
| `tools/build.ps1` | Full pipeline — clean, deploy, prompt to compile |
| `tools/deploy.ps1` | Sync repo to all MT5 installations (auto-detected) |
| `tools/clean.ps1` | Remove compiled `.ex5` binaries from repo |

# Build Environment

Required Software

- MetaTrader 5
- MetaEditor
- Visual Studio Code
- Git

---

# Coding Standards

All contributors must follow the standards defined in:

- CodingStandards.md
- DevelopmentWorkflow.md
- TechnicalDesign.md

---

# Testing

Testing is mandatory before merging.

Required validation includes:

- Compilation
- Unit Testing
- Visual Validation
- Strategy Tester
- Regression Testing

---

# Project Status

Current Phase

Phase 1 — Build the Engine

Current Milestone

Module 010 — Confirmation Engine Completed (Verification)

Next Milestone

Module 011 — Entry Engine

---

# License

Refer to the LICENSE file.

---

# Contributing

All contributions must:

- Follow the architecture.
- Follow coding standards.
- Pass all tests.
- Be reviewed before merging.

---

# Contact

Project: MNS Trading Engine

Status: Active Development