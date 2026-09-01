# MNS Trading Engine — AI Prompt
# Testing Tier 5: Broker Interface Error Injection

You are the lead QA/software engineer for the **MNS Trading Engine**.
Your task is to implement the **Tier 5 Broker Error Injection harness** — a standalone Expert Advisor
that simulates real-world broker failures (requotes, off-quotes, latency spikes, slippage)
and verifies that `MNS_EA.mq5` recovers gracefully, never double-trades, never over-allocates
risk, and always restores consistent internal state after broker-side failures.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, open and fully read the following files in order:

1. [TestingStrategy.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TestingStrategy.md) — Full testing strategy; Tier 5 spec at lines 61–68.
2. [MNS_EA.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Experts/MNS_EA/MNS_EA.mq5) — **Read every line** of the EA coordinator. Focus on:
   - `OnTick()` execution pipeline
   - `PlaceEntryOrder()` / `ExecuteEntry()` logic
   - `ManageActivePosition()` trailing stop block
   - `CTrade` usage (`g_trade.PositionOpen`, `g_trade.PositionModify`, `g_trade.PositionClose`)
   - `GlobalVariableSet` / `GlobalVariableGet` state persistence
   - Daily drawdown guard logic
3. [CRiskEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CRiskEngine.mqh) — Position tracking and sizing. Read `ResetPositionTracking()`, `CalculateLotSize()`, `GetActivePositionInfo()`.
4. [CEntryEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CEntryEngine.mqh) — Signal state machine: `ENTRY_STATE_NONE → ACTIVE → EXECUTED`.
5. [MNSTypes.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSTypes.mqh) — All enums, structs, retcode constants.
6. [MNSTestSuite.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSTestSuite.mqh) — MNS_ASSERT macro infrastructure.
7. [MNS_StateTransitionTests.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Experts/MNS_TestHarness/MNS_StateTransitionTests.mq5) — Use as structural template; this is the most similar test to Tier 5.

---

## Goal

Create a new file:
**`Experts/MNS_TestHarness/MNS_BrokerErrorTests.mq5`**

This harness:
- Uses a **mock `CTrade` wrapper** class (`CMockTrade`) that intercepts `PositionOpen()`, `PositionModify()`, and `PositionClose()` calls and returns pre-programmed broker error codes.
- Validates that the EA coordinator's logic (extracted into testable helper functions or verified through state observation) handles each error correctly.
- Runs in `OnInit()`, prints results, returns `INIT_FAILED`.

---

## CMockTrade — Mock Trade Wrapper

Implement `class CMockTrade` that mirrors the `CTrade` interface used in `MNS_EA.mq5`:

```mql5
class CMockTrade
{
public:
    uint   m_forcedRetcode;      // Set this to force a specific return code
    bool   m_simulateLatencyMs;  // If > 0, calls Sleep(m_simulateLatencyMs)
    double m_slippagePips;       // Simulate fill price offset on success
    int    m_callCountOpen;      // Track how many times PositionOpen was called
    int    m_callCountModify;    // Track PositionModify calls
    int    m_callCountClose;     // Track PositionClose calls

    bool PositionOpen(string symbol, ENUM_ORDER_TYPE type, double vol, double price,
                      double sl, double tp, string comment);
    bool PositionModify(ulong ticket, double sl, double tp);
    bool PositionClose(ulong ticket);
    uint ResultRetcode();
};
```

---

## Error Injection Test Cases

### Group 1 — Entry Execution Failures (4 tests)

**Test B-01: Requote on Entry**
- Set `mockTrade.m_forcedRetcode = TRADE_RETCODE_REQUOTE`.
- Simulate a bullish signal that reaches the entry execution block.
- Assert: `CEntryEngine` signal state remains `ENTRY_STATE_ACTIVE` (not `EXECUTED`) after the failed fill.
- Assert: `GlobalVariable` for volume (`MNS_EA_VOL_*`) is NOT set (no phantom position logged).
- Assert: `callCountOpen == 1` (only one attempt made — no runaway retry loop).

**Test B-02: Off-Quote on Entry**
- Set `mockTrade.m_forcedRetcode = TRADE_RETCODE_PRICE_OFF`.
- Same flow as B-01.
- Assert: signal remains `ENTRY_STATE_ACTIVE`. No position GlobalVariable written.

**Test B-03: Requote Retry Exhaustion**
- Set `mockTrade.m_forcedRetcode = TRADE_RETCODE_REQUOTE` for 3 consecutive retries.
- Verify the EA coordinator does NOT retry more than `InpMaxRetries` times (e.g., 3).
- Assert: after exhaustion, signal state transitions to `ENTRY_STATE_EXPIRED` or `ENTRY_STATE_CANCELLED`.

**Test B-04: Success After Slippage**
- Set `mockTrade.m_forcedRetcode = TRADE_RETCODE_DONE` with `m_slippagePips = 2.0`.
- Assert: `CEntryEngine` transitions to `ENTRY_STATE_EXECUTED`.
- Assert: GlobalVariable for volume IS set.
- Assert: actual fill price is `requestedPrice + 2.0 * pointSize` (worse price accepted).

---

### Group 2 — Trailing Stop Modification Failures (3 tests)

**Test B-05: Requote on Trailing Stop Modify**
- With a mock open position (`ticket = 123456`), trigger a trailing stop tightening cycle.
- Set `mockTrade.m_forcedRetcode = TRADE_RETCODE_REQUOTE` on `PositionModify`.
- Assert: the EA does NOT update its `GlobalVariable` SL state (keeps the old SL value, does not pretend the move succeeded).
- Assert: `callCountModify == 1`.

**Test B-06: Off-Quote on Emergency Drawdown Exit**
- Trigger a state where daily drawdown exceeds `InpMaxDailyDrawdown`.
- Set `mockTrade.m_forcedRetcode = TRADE_RETCODE_PRICE_OFF` on `PositionClose`.
- Assert: the EA logs a warning but does NOT re-enter a new trade (drawdown guard stays active).
- Assert: `callCountClose == 1` (no retry storm on emergency closes).

**Test B-07: Partial Close Failure**
- Trigger the +1R partial close rule (50% volume close).
- Set `mockTrade.m_forcedRetcode = TRADE_RETCODE_REQUOTE`.
- Assert: `GlobalVariable` volume tracker is NOT halved (volume remains at original level since partial close failed).
- Assert: the EA does not attempt to close the remaining volume again on the same tick.

---

### Group 3 — Latency Simulation (2 tests)

**Test B-08: High Latency Entry (3000ms)**
- Set `mockTrade.m_simulateLatencyMs = 3000`.
- Verify `PositionOpen()` call completes and EA continues without hanging.
- Assert: no infinite loop, no terminal freeze. Total `OnInit()` execution time < 30 seconds.

**Test B-09: Concurrent Tick During Latency**
- Simulate that while waiting for a broker fill response, a new tick arrives with a price that would invalidate the entry (e.g., price moves past the signal's invalidation level).
- Assert: the EA re-checks the signal validity after the fill response and cancels if the entry is now stale.

---

### Group 4 — State Synchronization (2 tests)

**Test B-10: GlobalVariable Corruption Recovery**
- Manually corrupt the `MNS_EA_VOL_*` GlobalVariable by setting it to `999.99` lots (impossible value).
- Restart the harness to simulate an EA restart with corrupted state.
- Assert: the EA detects that `999.99` lots is not a valid open position (via `PositionsTotal()` check) and resets the GlobalVariable to `0.0`.

**Test B-11: No Double-Entry After MT5 Restart**
- Pre-set GlobalVariables indicating an active position exists (`MNS_EA_VOL_* = 0.10`).
- But mock `PositionsTotal()` to return `0` (position no longer open — closed during MT5 downtime).
- Assert: the EA cleans up stale GlobalVariables and does NOT open a new trade to "replace" the ghost position.

---

## Output Format

```
=== MNS BROKER ERROR INJECTION TEST RESULTS ===
[PASS] B-01: Requote on Entry — Signal stays ACTIVE, no volume GV written
[PASS] B-02: Off-Quote on Entry — Correct state preservation
[PASS] B-03: Requote Retry Exhaustion — Signal expired after 3 attempts
[PASS] B-04: Success After Slippage — Position opened, fill price offset accepted
[PASS] B-05: Requote on Trailing SL — Old SL preserved in GlobalVariable
[PASS] B-06: Off-Quote Emergency Exit — Drawdown guard active, no re-entry
[PASS] B-07: Partial Close Failure — Volume GV unchanged
[PASS] B-08: High Latency Entry — No hang, completed in < 30s
[PASS] B-09: Stale Signal After Latency — Entry cancelled correctly
[PASS] B-10: GV Corruption Recovery — Ghost volume reset to 0
[PASS] B-11: No Double-Entry After Restart — Stale GVs cleaned
Total: 11 tests | 11 PASS | 0 FAIL
=== END BROKER ERROR INJECTION RESULTS ===
```

---

## Constraints

> [!IMPORTANT]
> - Do **NOT** modify `MNS_EA.mq5` or any `Include/MNS/` file. All injection is done through the mock wrapper.
> - `CMockTrade` must match the exact function signatures used in `MNS_EA.mq5` (read it carefully first!).
> - Use `GlobalVariableSet` / `GlobalVariableDel` in tests to simulate state, and clean up each test's GlobalVariables in a `CleanupTest()` helper.
> - All tests run in `OnInit()`. Return `INIT_FAILED` at the end.

---

## Verification

```powershell
powershell.exe -ExecutionPolicy Bypass -File ./tools/Build-And-Archive.ps1 -Module "Tier5_BrokerErrorTests" -SkipGit
```
Expected: `0 errors, 0 warnings`.
