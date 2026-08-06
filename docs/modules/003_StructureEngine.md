# Module 003
# Structure Engine Specification
Version: 1.0
Status: Design

---

# 1. Purpose

The Structure Engine parses confirmed swings produced by the Swing Detector (`CSwingDetector`) and classifies them into market structure points:
* **Higher High (HH)**
* **Lower High (LH)**
* **Higher Low (HL)**
* **Lower Low (LL)**
* **Equal High (EQH)**
* **Equal Low (EQL)**

It also evaluates the structural sequence to determine the current trend direction (**Bullish**, **Bearish**, **Transition**, or **Ranging**) and the market phase (**Trending**, **Pullback**, **Transition**, or **Ranging**). It serves as the analytical coordinator that transforms raw pivot points into market state context.

---

# 2. Responsibilities

- Read confirmed swings from `CSwingDetector` (both External and Internal).
- Track the sequence of swing highs and low structures.
- Apply strategy rules to classify each new swing relative to the previous swing of the same type.
- Apply a dynamic Average True Range (ATR) tolerance zone (10% of ATR) to identify Equal Highs (EQH) and Equal Lows (EQL).
- Apply a "Minimum Break Distance" constraint for structural updates (details listed in Open Ambiguities).
- Update the market trend based on structured sequences.
- Compute a structure confidence score.
- Expose the classified state via a public API.

---

# 3. Non-Responsibilities

- **No Chart Rendering**: It does not draw swing lines, structure labels, or dashboards.
- **No Trading/Execution**: It does not place orders or manage trade risk.
- **No Direct MT5 Calls**: It does not call `iHigh()`, `iLow()`, `iATR()`, etc. All prices, swings, and indicator buffers are supplied by the caller.

---

# 4. Inputs

- Confirmed swing points from `CSwingDetector` (External and Internal arrays).
- Average True Range (ATR) array or value at the time of the swing.
- Minimum Break Distance configuration value.

---

# 5. Outputs

Exposes the current state via the `SMarketState` structure (defined in `MNSTypes.mqh`):
- `trend` (`bullish`, `bearish`, `transition`, `ranging`)
- `phase` (`trending`, `pullback`, `transition`, `ranging`)
- `structureType` (`HH`, `HL`, `LH`, `LL`, `EQH`, `EQL`)
- Structure confidence score (double, 0.0 to 100.0)

---

# 6. Cross-Check Against Strategy (Step 3)

| Requirement | Strategy Status | Classification |
|---|---|---|
| Current Swing High > Previous Swing High + Min Break Distance = HH | Explicitly specified (Section 754-757) | ✅ Specified |
| Current Swing High < Previous Swing High - Min Break Distance = LH | Explicitly specified (Section 764-767) | ✅ Specified |
| Current Swing Low > Previous Swing Low + Min Break Distance = HL | Explicitly specified (Section 774-777) | ✅ Specified |
| Current Swing Low < Previous Swing Low - Min Break Distance = LL | Explicitly specified (Section 779-782) | ✅ Specified |
| Absolute difference <= 10% of current ATR = EQH / EQL | Explicitly specified (Section 784-798) | ✅ Specified |
| Bullish trend requires sequence HH → HL → HH → HL | Explicitly specified (Section 806-818) | ✅ Specified |
| Bearish trend requires sequence LL → LH → LL → LH | Explicitly specified (Section 820-832) | ✅ Specified |
| Transition trend for mixed structures | Explicitly specified (Section 833-844) | ✅ Specified |
| Ranging trend if mostly EQH/EQL | Explicitly specified (Section 846-850) | ✅ Specified |
| Market Phase (Trending, Pullback, Transition, Ranging) | Explicitly specified (Section 851-868) | ✅ Specified |
| Confidence score based on weighting factors | Explicitly specified (Section 870-885) | ✅ Specified |
| Minimum Break Distance numerical value | **Not specified in document** | ❌ Unknown (OPEN-006) |
| Multi-timeframe phase evaluation rules | Section 859-868 gives a concept but not rules | ❌ Unknown (OPEN-007) |
| Numerical weighting formula for Confidence | Section 871-881 lists weights but not equations | ⚠️ Inferred (OPEN-008) |

---

# 7. Open Ambiguities (To be logged in TODO_STRATEGY.md)

### OPEN-006 — Minimum Break Distance Value
* **Ambiguity**: Rules 1-4 require a "Minimum Break Distance" to confirm a HH/LH/HL/LL break. The strategy does not specify what this value is, how it is configured (e.g. points, pips, ATR multiple), or if it defaults to 0.0.
* **Question**: What is the default value or configuration method for the Minimum Break Distance?

### OPEN-007 — Market Phase Evaluation Logic
* **Ambiguity**: Section 9 states: "Daily Bullish + 15M Bearish = Pullback". Since the engine operates on a single timeframe's caller-supplied arrays, how should it determine higher vs lower timeframe structure phase without multiple engine instances?
* **Question**: How should the phase be calculated on a single timeframe, or does the client expect multiple engine instances running in parallel?

### OPEN-008 — Structure Confidence Formula
* **Ambiguity**: Section 10 specifies weight factors (HH/HL consistency 30%, BOS confirmation 25%, Swing quality 20%, Displacement 15%, EQH/EQL noise 10%) but does not define how to compute the scores for each factor.
* **Question**: What are the specific formulas used to calculate the score for each of the 5 confidence factors?
