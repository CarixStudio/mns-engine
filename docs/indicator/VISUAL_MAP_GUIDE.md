# MNS Trading Engine — Indicator Visual Reference Guide
This guide provides an institutional-grade mapping of the visual elements (arrows, lines, rectangles, and colors) rendered on the MetaTrader 5 chart by the MNS Indicator, explaining what each represents in terms of the underlying Strategy 3 trading rules.

---

## 1. Swing Highs & Lows (Arrows)
Swing points represent localized price pivots that define the structural boundaries of the market. The indicator distinguishes between high-timeframe (External) and low-timeframe (Internal) structure:

| Icon | Color | Location | Meaning in Strategy |
|---|---|---|---|
| **Thick Up Arrow** | **Lime Green** | Above Candle High | **Confirmed External Swing High**: The major high point of a dealing range. Forms when a high candle is flanked by two lower highs on both sides. |
| **Thick Down Arrow** | **Red** | Below Candle Low | **Confirmed External Swing Low**: The major low point of a dealing range. Forms when a low candle is flanked by two higher lows on both sides. |
| **Thin Up Arrow** | **Teal** | Above Candle High | **Confirmed Internal Swing High**: Sub-structure high representing short-term pullbacks within the major range. |
| **Thin Down Arrow** | **Purple / Magenta** | Below Candle Low | **Confirmed Internal Swing Low**: Sub-structure low representing short-term pullbacks within the major range. |

---

## 2. Market Structure Breaks (Horizontal lines with text)
Structure breaks confirm market trend direction and momentum shifts. They are drawn as horizontal levels starting at the broken swing point:

| Visual Element | Line Style | Color | Meaning in Strategy |
|---|---|---|---|
| **BOS (Bullish)** | **Dashed Line** | **Lime Green** | **Break of Structure (Bullish)**: Price has successfully closed above the last Confirmed Swing High. Confirms continuation of an uptrend. |
| **BOS (Bearish)** | **Dashed Line** | **Red** | **Break of Structure (Bearish)**: Price has successfully closed below the last Confirmed Swing Low. Confirms continuation of a downtrend. |
| **CHoCH** | **Dotted Line** | **Orange** | **Change of Character**: The first structural break in the opposite direction of the main trend. Signals a potential trend reversal. |
| **iBOS (Bullish)** | **Dashed Line** | **Teal** | **Internal BOS (Bullish)**: Break of a minor internal swing high, signaling early bullish sub-structure momentum. |
| **iBOS (Bearish)** | **Dashed Line** | **Purple** | **Internal BOS (Bearish)**: Break of a minor internal swing low, signaling early bearish sub-structure momentum. |

---

## 3. Liquidity Pools (Horizontal Levels)
Liquidity pools represent key retail order levels (stops) that institutional algorithms target for sweeps. The indicator highlights active un-swept zones and marks them as swept when wicks breach them:

| Visual Element | Line Style | Color | Meaning in Strategy |
|---|---|---|---|
| **BSL (Buy-Side)** | **Dashed Line** | **Dodger Blue** | **Buy-Side Liquidity**: Swing highs that remain unswept. Institutional buyer stops reside above this level. |
| **SSL (Sell-Side)** | **Dashed Line** | **Tomato Red** | **Sell-Side Liquidity**: Swing lows that remain unswept. Sell stops reside below this level. |
| **EQH (Equal Highs)** | **Dotted Line** | **Light Sky Blue** | **Equal Highs**: Double/triple tops (within 15% ATR). High-priority draw on liquidity. |
| **EQL (Equal Lows)** | **Dotted Line** | **Light Coral** | **Equal Lows**: Double/triple bottoms (within 15% ATR). High-priority draw on liquidity. |
| **Swept Pool** | **Dotted Line** | **Slate Gray** | **Swept Liquidity**: Historical pool where a candle wick has run past the level, showing order consumption. |

---

## 4. Points of Interest (POI) (Filled Rectangles)
Points of Interest are institutional footprint zones where traders look for entry setups. They are drawn using dark desaturated background fills to maintain high contrast with candles and wicks:

| Visual Element | Outline / Border | Fill Color | Meaning in Strategy |
|---|---|---|---|
| **Bullish OB** | **Solid Border** | **Dark Green** | **Bullish Order Block**: The cluster of bearish candles prior to a bullish displacement run that broke structure. Used for buying setups. |
| **Bearish OB** | **Solid Border** | **Dark Red** | **Bearish Order Block**: The cluster of bullish candles prior to a bearish displacement run that broke structure. Used for selling setups. |
| **Bullish Breaker** | **Solid Border** | **Dark Blue** | **Bullish Breaker Block**: A failed bearish Order Block that price swept and broke through. Becomes a support level. |
| **Bearish Breaker** | **Solid Border** | **Dark Orange-Red** | **Bearish Breaker Block**: A failed bullish Order Block that price swept and broke through. Becomes a resistance level. |
| **Bullish Mitigation**| **Solid Border** | **Dark Cyan** | **Bullish Mitigation Block**: Similar to a breaker, but forms when the preceding swing failed to sweep liquidity before breaking structure. |
| **Bearish Mitigation**| **Solid Border** | **Dark Orange** | **Bearish Mitigation Block**: Similar to a breaker, but forms when the preceding swing failed to sweep liquidity before breaking structure. |
| **Bullish FVG** | **Dotted Border** | **Dark Green (Lime)** | **Bullish Fair Value Gap**: An imbalance (gap) between the high of Candle A and low of Candle C in a 3-candle sequence. Acts as a magnet for price. |
| **Bearish FVG** | **Dotted Border** | **Dark Red** | **Bearish Fair Value Gap**: An imbalance (gap) between the low of Candle A and high of Candle C in a 3-candle sequence. Acts as a magnet for price. |

---

## 5. Delivery Legs & Draw on Liquidity (DOL)
These represent active algorithmic delivery targets and trend legs:

| Visual Element | Line Style | Color | Meaning in Strategy |
|---|---|---|---|
| **Bullish Delivery** | **Solid Line** | **Aqua / Cyan** | **Bullish Delivery Leg**: Connecting line representing an active uptrend cycle from the origin low to the current price. Dashing indicates mitigation. |
| **Bearish Delivery** | **Solid Line** | **Orange-Red** | **Bearish Delivery Leg**: Connecting line representing an active downtrend cycle from the origin high to the current price. Dashing indicates mitigation. |
| **Active DOL** | **Dotted Line** | **Gold (Labeled "DOL")** | **Draw on Liquidity**: The active target level that the engine determines price is currently drawn toward. |

---

## 6. Dashboard Panel Reference Guide
The floating status dashboard displays the real-time calculated state of the 11 core strategy engines. Text colors are dynamically updated to highlight bullish strength, bearish risk, or consolidation phases:

### 6.1 Row-by-Row Definitions

| Row Label | Displayed Value Example | Strategy Meaning |
|---|---|---|
| **Symbol/TF** | `GBPUSD, H1` | Current chart symbol and timeframe context. |
| **Trend** | `Bullish` / `Bearish` / `Transition` | The overall market trend direction calculated from swing highs and lows. |
| **Phase** | `Trending` / `Pullback` / `Range` | The current market cycle state relative to structure. |
| **Structure** | `HH` (Higher High) / `HL` (Higher Low) / `LH` / `LL` | The last confirmed swing point classification. |
| **Last BOS** | `Bullish @ 1.35712` / `None` | Price and direction of the last confirmed Break of Structure. |
| **Last CHoCH** | `Bearish @ 1.34921` / `None` | Price and direction of the last confirmed Change of Character (trend shift point). |
| **Liq Bias** | `Buy Side` / `Sell Side` / `Balanced` | Tells you whether price is magnetically drawn upwards (`Buy Side`) or downwards (`Sell Side`) based on the active target. |
| **Active DOL** | `1.35582 (Ext Swing)` / `None` | The active target level (Draw on Liquidity) price is moving toward. |
| **Active POI** | `Bullish FVG (1.36285-1.36295)` | The closest active Order Block or Fair Value Gap zone that price is interacting with. |
| **DR Zone** | `Discount` / `Premium` / `Equilibrium` | Where current price sits relative to the current 50% midpoint (Equilibrium) of the trading range. |
| **Session** | `Tokyo` / `London` / `NY` / `Overlap` | The active institutional trading session(s) based on GMT broker time. |
| **Confirmation** | `None` / `Confirmed` | Verification that all Strategy 3 rejection and confidence rules have passed. |
| **Entry** | `None` / `BUY TRIGGERED` | Execution signal state for entry orders. |

---

### 6.2 Color-Coding Key

To help you scan the dashboard in split-seconds, the text color codes map directly to strategy logic:

*   **Lime Green**: Bullish alignment, buying opportunities, or discount pricing.
    *   *Examples*: `Trend: Bullish`, `Liq Bias: Buy Side`, `DR Zone: Discount` (cheap area to buy).
*   **Red**: Bearish alignment, selling opportunities, or premium pricing.
    *   *Examples*: `Trend: Bearish`, `Liq Bias: Sell Side`, `DR Zone: Premium` (expensive area to sell).
*   **Gold / Orange**: Transition phases, warning points, or market ranges.
    *   *Examples*: `Trend: Transition`, `Last CHoCH: Bearish` (reversal warning).
*   **White / Light Gray**: Neutral, balanced, or pending states.
    *   *Examples*: `DR Zone: Equilibrium` (fair value), `Session: Tokyo`, `Entry: None`.

