# MNS Trading Engine — AI Prompt
# Testing Tier 4: Deterministic Regression Testing (Historical Replay)

You are the lead QA/software engineer for the **MNS Trading Engine**.
Your task is to implement the **Tier 4 Deterministic Regression Harness** — a standalone Expert Advisor
that replays pre-recorded historical market events through the full MNS engine pipeline,
hashes the resulting `SConfirmationState` output structs, and compares them against a stored baseline.

Any deviation from the baseline = regression = the test fails.

---

## REQUIRED CONTEXT FILES (Read These First!)

Before writing any code, open and fully read the following files in order:

1. [TestingStrategy.md](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/docs/TestingStrategy.md) — Full testing strategy; Tier 4 spec at lines 56–59.
2. [MNSTypes.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSTypes.mqh) — `SConfirmationState`, `SSignalResult`, `SRiskSizingResult`, `SMNSConfig`. Read **every field** so you know exactly what to hash.
3. [MNSTestSuite.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSTestSuite.mqh) — Test assertion macros.
4. [MNSCore.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/MNSCore.mqh) — Engine bootstrap + globals.
5. [CConfirmationEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CConfirmationEngine.mqh) — Final signal confirmation output; this is the output we will hash.
6. [CSwingDetector.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CSwingDetector.mqh) — First stage in the DAG pipeline.
7. [CStructureEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CStructureEngine.mqh) — Second stage.
8. [CBreakDetector.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CBreakDetector.mqh) — Third stage.
9. [CLiquidityEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CLiquidityEngine.mqh) — Fourth stage.
10. [CPOIEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CPOIEngine.mqh) — Fifth stage; largest and most complex file.
11. [CObjectiveEngine.mqh](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Include/MNS/CObjectiveEngine.mqh) — Sixth stage.
12. [MNS_StateTransitionTests.mq5](file:///c:/Users/CarixStudio/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/mns-engine/Experts/MNS_TestHarness/MNS_StateTransitionTests.mq5) — Existing Tier 2 harness; use as structural template.

---

## Goal

Create a new file:
**`Experts/MNS_TestHarness/MNS_RegressionTests.mq5`**

The harness:
- Embeds 3 synthetic historical market scenarios as hardcoded arrays inside the file.
- Runs each scenario through the full MNS engine pipeline (Swing → Structure → Break → Liquidity → POI → Objective → Confirmation).
- Hashes the final `SConfirmationState` output using a deterministic rolling hash function.
- Compares the computed hash to a pre-baked `EXPECTED_HASH_*` constant defined in the file.
- Prints PASS/FAIL per scenario.
- Returns `INIT_FAILED` to self-remove.

---

## Hashing Function

Implement a deterministic `uint HashConfirmationState(SConfirmationState &state)` function that:
- XOR-folds all boolean fields (e.g., `state.isValid`, `state.isBullish`, `state.hasLiquidity`) as bits.
- XOR-folds all double fields (cast to `uint` via `MathRound(value * 100000)`) as integers.
- XOR-folds all integer/enum fields directly.
- Returns a single `uint` hash.

This must be **deterministic**: identical inputs → identical hash, every time.

---

## Embedded Historical Scenarios

### Scenario R-01: "Brexit Flash Crash" (2016-06-24 00:00 UTC)
- Simulate a sharp drop: 27 consecutive bearish candles, each closing 30 pips lower than the previous.
- Starting price: `GBPUSD 1.4800`.
- Spread fixed at `3 points` throughout.
- **Expected Engine Output:** Bearish BOS confirmed, liquidity sweep detected below prior equal lows, bearish FVG formed in the drop zone.
- Hardcode `EXPECTED_HASH_R01 = 0xXXXXXXXX` (computed on first successful run, then baked in).

### Scenario R-02: "SNB Peg Removal" (2015-01-15 09:30 UTC)
- Simulate a V-shaped shock: 10 candles plummeting 3000 pips followed by an immediate 2000-pip recovery.
- Starting price: `EURCHF 1.2005`.
- Spread expands to 150 points during the shock candles.
- **Expected Engine Output:** ATR spike detected; POI engine must NOT create any zones during spread > 100 points candles. Recovery structure must create a bullish CHoCH.
- Hardcode `EXPECTED_HASH_R02 = 0xXXXXXXXX`.

### Scenario R-03: "COVID Open Gap" (2020-03-09 Monday open)
- Simulate a Monday gap open: previous Friday close at `USOIL 41.00`, Sunday open at `USOIL 31.00` (gap of 1000 points / $10.00).
- Run 50 candles of consolidation after the gap open.
- **Expected Engine Output:** Gap zone marked as a valid FVG. Swing low established at gap open. Structure engine registers bearish CHoCH from the Friday close level.
- Hardcode `EXPECTED_HASH_R03 = 0xXXXXXXXX`.

> [!NOTE]
> On first run, the test will output the computed hashes to the journal log.
> Copy those hash values into the `EXPECTED_HASH_*` constants and re-run.
> Only after baking in the expected hashes does the test become a true regression gate.

---

## Baseline Management

Add an `input bool InpRecordBaseline = false;` parameter.
- When `true`: the harness runs all scenarios, prints computed hashes to the journal, and writes them to `MQL5\Files\MNS_RegressionBaseline.txt` using `FileWrite()`.
- When `false` (default): the harness reads `MQL5\Files\MNS_RegressionBaseline.txt` using `FileRead()` and compares against those baselines.

This allows you to update the baseline file whenever the engine intentionally changes.

---

## Output Format

```
=== MNS REGRESSION TEST RESULTS ===
[PASS] R-01: Brexit Flash Crash — Hash 0xA3F71C22 matches baseline
[PASS] R-02: SNB Peg Removal   — Hash 0x9D84E451 matches baseline
[FAIL] R-03: COVID Gap Open    — Hash 0xCCCC1234 ≠ expected 0xB2A09FF1 (REGRESSION DETECTED)
Total: 3 scenarios | 2 PASS | 1 FAIL
=== END REGRESSION TEST RESULTS ===
```

---

## Constraints

> [!IMPORTANT]
> - Do **NOT** modify any file under `Include/MNS/`. All test data is embedded in the harness.
> - Use only `ArrayResize()` + manual `for`-loop fill to construct synthetic candle arrays. No `CopyRates()`.
> - The hash function must be self-contained (no external hashing libraries).
> - The baseline file path must use: `string path = "MNS_RegressionBaseline.txt";` with `FILE_WRITE | FILE_TXT`.
> - Compile with `#include <MNS/MNSCore.mqh>` only.

---

## Verification

```powershell
powershell.exe -ExecutionPolicy Bypass -File ./tools/Build-And-Archive.ps1 -Module "Tier4_RegressionTests" -SkipGit
```
Expected: `0 errors, 0 warnings`.
