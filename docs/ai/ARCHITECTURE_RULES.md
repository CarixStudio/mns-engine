# MNS Trading Engine
# Architecture Rules
Version: 1.0
Status: Approved

---

# Purpose

This document defines the non-negotiable architectural rules for the
MNS Trading Engine. Every module, every file, and every line of code
must comply with these rules.

Any AI assistant, developer, or reviewer working on this project must
read this document before writing or reviewing any code.

---

# Rule 1 — The Engine Is the Source of Truth

The Core Analysis Engine produces all analytical outputs.

The Indicator consumes the engine. It does not analyse the market.

The EA consumes the engine. It does not analyse the market.

No analysis logic may exist outside the engine modules.

```
Market Data
     │
     ▼
Core Analysis Engine   ← ALL analysis lives here
     │
     ├──► Indicator    ← rendering only
     │
     └──► EA           ← execution only
```

---

# Rule 2 — No Logic in the Rendering Layer

The Indicator renders engine outputs as chart objects.

It must not:
- Detect swings
- Classify structure
- Calculate levels
- Make trading decisions

If a rendering method contains an `if` on price data, it is a violation.

---

# Rule 3 — No Logic in the EA Layer

The EA executes trades based on engine signals.

It must not:
- Detect swings
- Classify structure
- Calculate levels

The EA asks the engine for state and acts on it.

---

# Rule 4 — No Direct MT5 Data Access in Engine Modules

Engine modules must not call:

- `iHigh()`, `iLow()`, `iOpen()`, `iClose()`
- `iTime()`
- `Bars()`
- Any MT5 data function

All price data is supplied by the caller (OnCalculate or OnTick) via
arrays passed as parameters to `Update()`.

This makes engine modules testable without a live MetaTrader instance.

---

# Rule 5 — No Chart Drawing in Engine Modules

Engine modules must not call:

- `ObjectCreate()`
- `ObjectSetInteger()`
- `ObjectSetDouble()`
- `ObjectDelete()`
- Any chart object function

Chart drawing belongs exclusively to the Indicator rendering layer.

---

# Rule 6 — No Broker Interaction in Engine Modules

Engine modules must not call:

- `OrderSend()`
- `PositionGet()`
- `AccountInfoDouble()`
- `SymbolInfoDouble()`
- Any trade or account function

Broker interaction belongs exclusively to the EA.

---

# Rule 7 — No Logging in Engine Modules

Engine modules must not call `Print()`, `PrintFormat()`, or `Alert()`.

Logging belongs in the test harness (`MNS_TestHarness.mq5`) only.

---

# Rule 8 — Strategy Is the Only Source of Truth for Trading Logic

Every analytical rule must be traceable to the client's strategy
document (`kennystrstegy.md`).

If a rule is not in the strategy document:
1. Do not invent it.
2. Do not use a common trading assumption.
3. Document it as an open question in `docs/TODO_STRATEGY.md`.
4. Leave a TODO in the code referencing the OPEN-xxx item.

Never use:
- Generic Smart Money Concepts not in the strategy
- ICT concepts not in the strategy
- Fractal pivot algorithms
- ZigZag logic
- Standard library swing detection

---

# Rule 9 — Modules Have Single Responsibility

Each module does exactly one thing.

| Module | Responsibility |
|---|---|
| MNSTypes | Shared data models only |
| CSwingDetector | Swing detection only |
| CStructureEngine | Structure classification only |
| CBreakDetector | Break detection only |
| CTrendEngine | Trend state only |
| CLiquidityEngine | Liquidity detection only |
| CPOIEngine | Points of interest only |
| CPremiumDiscountEngine | Premium/discount calculation only |
| CEntryEngine | Entry detection only |
| CRiskEngine | Risk calculation only |
| CTradeManager | Trade lifecycle only |

A module that does more than its single responsibility is a violation.

---

# Rule 10 — Dependencies Flow Downward Only

```
MNSTypes.mqh
     ↑
CSwingDetector.mqh
     ↑
CStructureEngine.mqh
     ↑
CBreakDetector.mqh
     ↑
...
```

Lower modules must never include or depend on higher modules.

`MNSTypes.mqh` depends on nothing.

`CSwingDetector.mqh` depends only on `MNSTypes.mqh`.

`CStructureEngine.mqh` depends on `MNSTypes.mqh` and `CSwingDetector.mqh`.

No circular dependencies are permitted.

---

# Rule 11 — No Repainting

Confirmed structures may never be modified after they are stored.

Once a swing, break, or structure label is confirmed and stored:
- Its price, time, and type are immutable.
- It may not be removed from history.
- It may not be reclassified.

Only the most recent unconfirmed candidate may change.

---

# Rule 12 — MQL5 Compatibility Constraints

MQL5 has restrictions that differ from standard C++.

The following patterns are PROHIBITED because they cause compiler errors
in MQL5:

| Prohibited Pattern | Use Instead |
|---|---|
| `const T& x = method()` (local reference to return) | `T x = method()` |
| `const T& x = arr[i]` inside a `const` method | `T x = arr[i]` |
| `const int N = 5; double arr[N];` (const int as array size) | `#define N 5` or literal |
| Returning `const T&` from a `const` method on member arrays | Return `T` by value |

These are MQL5 compiler limitations, not code quality issues.
Value copies of small structs (like SSwingPoint) are acceptable.

---

# Rule 13 — Initialize Before Update

Every engine module must enforce initialization before use.

```mql5
bool Update(...)
{
    if (!m_isInitialized)
        return false;
    ...
}
```

Modules that are called without initialization must return false or a
safe sentinel value — never crash, never access uninitialized memory.

---

# Rule 14 — The Test Harness Grows With Every Module

Every completed module adds its own test cases to `MNS_TestHarness.mq5`.

Test harness rules:
- No broker data. All test data is hard-coded.
- Tests are deterministic and repeatable.
- Each test prints PASS or FAIL.
- All previous tests continue to run after new modules are added.
- The harness returns INIT_FAILED to self-remove after a single pass.

---

# Rule 15 — Build Before Compile

The correct workflow is always:

```
1. Edit source in the repo (mns-engine/)
2. Run tools/build.ps1  ← deploys to MT5 system folders
3. Press F7 in MetaEditor
4. Verify 0 errors, 0 warnings
```

MetaEditor compiles from the MT5 system folders, not the repo.
Running build.ps1 is mandatory before every compile session.
