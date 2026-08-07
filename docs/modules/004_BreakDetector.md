# Module 004 — CBreakDetector Specification
Version: 1.0
Status: Approved

---

## 1. Purpose

The Break Detector (`CBreakDetector`) monitors the confirmed swings and market state to identify trend continuation breaks (BOS), minor internal breaks (iBOS), and trend reversal warnings (CHoCH). 

Once detected, a break is logged in an immutable, append-only history. These breaks are consumed by downstream modules (Trend Engine, Liquidity Engine, POI Engine) to understand structure shifts and filter setups.

---

## 2. Responsibilities

- Monitor the latest confirmed swing highs and lows from `CSwingDetector`.
- Read trend bias from `CStructureEngine` to identify the protected swing level.
- Detect **BOS (Break of Structure)**: Candle body closes beyond a prior confirmed external swing point.
- Detect **iBOS (Internal BOS)**: Candle body closes beyond a prior confirmed internal swing point.
- Detect **CHoCH (Change of Character)**: Price wicks beyond the trend's protected swing point, but the candle body does not close beyond it (wick-only break).
- Prevent duplicate break logs (each swing point can only be broken once).
- Calculate the break strength score and classify break strength (`STRENGTH_WEAK`, `STRENGTH_AVERAGE`, `STRENGTH_STRONG`).
- Expose the break history and latest events via a public API.

---

## 3. Non-Responsibilities

- **No Chart Drawing**: Does not create chart objects, lines, or text labels.
- **No Trading Logic**: Does not place trades or manage positions.
- **No Direct MT5 Calls**: Does not call MT5 data access arrays (`iClose()`, etc.). All price arrays and indicators are supplied by the caller.

---

## 4. Inputs

- Confirmed swing points history from `CSwingDetector` (External and Internal).
- Current market trend and state from `CStructureEngine`.
- Open, High, Low, Close (OHLC) arrays of the bars (passed to `Update()`).
- ATR value at the time of the break (passed to `Update()`).

---

## 5. Outputs

- Append-only array of `SStructureBreak` events.
- Latest `BOS` structure break.
- Latest `iBOS` structure break.
- Latest `CHoCH` structure break.
- State accessors (`HasBullishBOS()`, `HasBearishBOS()`, etc.).

---

## 6. Cross-Check Against Strategy

| Requirement | Strategy Status | Classification |
|---|---|---|
| Bullish BOS requires candle body close above prior Swing High | Explicitly specified (Section 5) | ✅ Specified |
| Bearish BOS requires candle body close below prior Swing Low | Explicitly specified (Section 5) | ✅ Specified |
| iBOS follows same rules using internal swings | Explicitly specified (Section 993) | ✅ Specified |
| CHoCH requires price wicks beyond protected swing (no body close) | Explicitly specified (Section 6, 996) | ✅ Specified |
| Reject break if candle is forming (only closed bars evaluated) | Explicitly specified (Rule 5) | ✅ Specified |
| Duplicate check (do not log multiple breaks for same swing) | Explicitly specified (Rule 5) | ✅ Specified |
| Break strength score classified by ATR size of breaking candle | Explicitly specified (Section 11) | ✅ Specified |
| Protected swing definition for CHoCH | **Not explicitly defined** | ⚠️ Inferred (OPEN-009) |
| Break displacement calculation formula | **Not explicitly defined** | ⚠️ Inferred (OPEN-010) |

---

## 7. Open Ambiguities

### OPEN-009 — CHoCH Protected Swing Definition
- **Ambiguity**: Section 6 and Rule 4 state CHoCH occurs when price wicks beyond a "protected swing." The strategy does not specify what constitutes a protected swing.
- **Inference**: In a Bullish Trend, the protected swing is the latest confirmed External Swing Low. In a Bearish Trend, the protected swing is the latest confirmed External Swing High. If the trend is Transition or Ranging, there is no protected swing.

### OPEN-010 — Break Candle Displacement Definition
- **Ambiguity**: The `SStructureBreak` struct contains a `displacement` field. The strategy document mentions displacement as a strength component but does not define how to calculate it.
- **Inference**: Displacement is calculated as the absolute distance between the close of the breaking candle and the swing price level being broken.
