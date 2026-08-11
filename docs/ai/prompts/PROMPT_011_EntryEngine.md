## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, you must inspect the following repository files:
1. `kennystrstegy.md` — The Strategy Document (Source of Truth).
2. `kennystrategy2.md` — Kenny's Strategy Document (Source of Truth).
3. `Include/MNS/MNSCore.mqh` — Core metadata, assertions, and result codes.
4. `Include/MNS/MNSTypes.mqh` — Shared Data Structures.
5. `Include/MNS/CSwingDetector.mqh` — Preceding swing engine dependency.
6. `Include/MNS/CStructureEngine.mqh` — Trend and structure dependency.
7. `Include/MNS/CBreakDetector.mqh` — Structure breaks dependency.
8. `Include/MNS/COrderFlowEngine.mqh` — Order flow direction dependency.
9. `Include/MNS/CDeliveryStructureEngine.mqh` — Delivery leg status dependency.
10. `Include/MNS/CLiquidityEngine.mqh` — Liquidity sweep dependency.
11. `Include/MNS/CPOIEngine.mqh` — POI state dependency.
12. `Include/MNS/CObjectiveEngine.mqh` — Draw on Liquidity (DOL) target dependency.
13. `Include/MNS/CConfirmationEngine.mqh` — Setup confirmation state dependency.
14. `docs/modules/011_EntryEngine.md` — This module's Specification.
15. `docs/modules/011_ALGORITHM.md` — This module's Algorithm.
16. `docs/modules/011_API.md` — This module's Class API.
17. `docs/CLASS_DIAGRAM.md` — Design Blueprint.
18. `docs/CodingStandards.md` — Coding and style guide.
19. `docs/TODO_STRATEGY.md` — Active strategy ambiguities tracker.
20. `docs/Roadmap.md` — Project roadmap.

---

## Instructions for CEntryEngine Implementation

You must implement the `CEntryEngine` class inside `Include/MNS/CEntryEngine.mqh`.

### 1. Requirements Checklist
- **Closed Candle Trigger**: Verify that signals are generated ONLY when the confirming execution-timeframe candle is closed (evaluated at index 1). Candle 0 (live candle) is never used to confirm setup state.
- **Pre-execution Invalidation**: Automatically invalidate or cancel the active signal before execution if:
  - The Confirmation Engine shifts out of `CONFIRMATION_STATE_CONFIRMED` state.
  - The associated POI deactivates or gets invalidated.
  - The active DOL price changes, or the Risk-Reward ratio drops below `1.50R`.
  - The active delivery leg becomes invalidated.
  - The current market spread exceeds `maxSpreadPoints`.
- **Signal Expiration**: The active entry signal has a hard expiration of 5 bars on the execution timeframe.
- **Duplicate Prevention**:
  - Store a history array of consumed/executed signals `m_consumedSignals` of type `datetime` (capped at 128 elements).
  - A signal ID (which is the trigger timestamp `triggerTime`) must never trigger more than once. If a signal was already executed, do not generate it again.
- **Defensive Design**: Guard against division by zero in Risk-to-Reward calculations. Verify that price ranges are positive and handle invalid indexes safely.

### 2. MQL5 Restrictions
- No references to local variables as references (`const T& x = ...` is invalid).
- Methods returning const structures must return them **by value** (e.g. `SEntrySignal GetActiveSignal() const` is correct; `const SEntrySignal& GetActiveSignal() const` is invalid in MQL5).
- Do not use `const int` for static array sizes. Use `#define` or literals (e.g., `#define MNS_MAX_CONSUMED_SIGNALS 128`).
- Keep inclusion guard: `#ifndef __MNS_ENTRY_ENGINE_MQH__`.

### 3. Log Output
- Use the shared logging module `CLogger` to write diagnostic information when:
  - A signal is generated.
  - A signal is invalidated (specifying the reason, e.g. "POI Invalidation", "DOL target shift", "RR filter failed", "Spread filter failed").
  - A signal is expired.
  - A signal is executed (consumed).
