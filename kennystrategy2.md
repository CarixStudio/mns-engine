MNS TRADING ENGINE — DEFINITIVE STRATEGY RULES  SPECIFICATION 
1. Existing Ambiguities — Final Answers 
1.1 Swing confirmation: right-side confirmation window 
Final rule: 
The right-side confirmation window must equal the configured  swing depth. 
For an external swing with: 
text 
Depth = 15 
the candidate must have: 
text 
15 completed candles to its left 
15 completed candles to its right 
For an internal swing with:
text 
Depth = 5 
the candidate must have: 
text 
5 completed candles to its left 
5 completed candles to its right 
Therefore: 
text 
External swing: 
15 left + candidate + 15 right 
Internal swing: 
5 left + candidate + 5 right 
Do not use a universal two-candle right confirmation. The previous Shift = 2 concept is separate and must not replace  swing depth.
1.2 Meaning of “15 candles” 
“15 candles” means: 
text 
15 candles on each side 
not 15 total. 
For a swing high candidate at bar i: text 
High[i] must exceed all highs: i-15 ... i-1 
AND 
High[i] must exceed all highs: i+1 ... i+15 
Likewise for a swing low:
text 
Low[i] must be below all lows: 
i-15 ... i-1 
AND 
Low[i] must be below all lows: 
i+1 ... i+15 
1.3 Equal highs / equal lows tie-breaking 
Exact equality must not automatically create multiple structural  swings. 
Use symbol-aware tolerance: 
text 
EqualityTolerance = 
max( 
 2 × SYMBOL_POINT, 
 0.05 × ATR(14) 
)
text 
abs(HighA - HighB) <= EqualityTolerance 
Two lows are considered equal if: 
text 
abs(LowA - LowB) <= EqualityTolerance 
When several candles inside the same swing window are  effectively equal: 
For swing highs: 
text 
Keep the earliest candle as the  
structural swing. 
Mark subsequent equal highs as  
liquidity touches. 
For swing lows:
text 
Keep the earliest candle as the  
structural swing. 
Mark subsequent equal lows as liquidity  touches. 
This prevents a cluster of equal highs/lows from generating fake  HH/LH/HL/LL sequences. 
1.4 Meaning of Shift = 2 
Shift = 2 must mean: 
text 
Do not use candle 0 — currently forming  candle. 
Do not use candle 1 when a logic  
specifically requires one fully completed  confirmation candle after the event. 
Begin structural search from candle 2. 
It does not define swing confirmation depth. 
Swing depth remains:
text 
Internal = 5 / 5 
External = 15 / 15 
1.5 Minimum Break Distance 
The break distance should be volatility-aware. Default: 
text 
MinimumBreakDistance = max( 
 2 × SYMBOL_POINT, 
 0.10 × ATR(14) 
) 
For bullish BOS: 
text 
Close[1] > 
BrokenSwingHigh 
+
MinimumBreakDistance 
For bearish BOS: 
text 
Close[1] < 
BrokenSwingLow 
- 
MinimumBreakDistance 
A wick through structure without the required body close is: text 
Liquidity interaction / warning 
not a confirmed BOS. 
1.6 Multi-timeframe market phase 
Each timeframe receives one of: 
text 
BULLISH 
BEARISH
RANGE 
TRANSITION 
UNKNOWN 
Bullish phase requires: 
text 
Latest confirmed external structure: HH + HL 
AND 
latest confirmed structural break is  bullish 
AND 
price has not subsequently confirmed a  bearish CHoCH 
Bearish phase requires:
text 
Latest confirmed external structure: LL + LH 
AND 
latest confirmed structural break is  bearish 
AND 
price has not subsequently confirmed a  bullish CHoCH 
Range: 
text 
No confirmed directional external BOS AND 
price contained between active external  swing boundaries
text 
Opposing CHoCH confirmed 
but 
new-direction BOS not yet confirmed 
Therefore: 
text 
Bullish 
→ bearish CHoCH 
→ Transition 
→ bearish BOS 
→ Bearish 
and vice versa. 
1.7 Market Structure Confidence 
Use a weighted 0–100 score. 
text 
External structure direction 25 Latest confirmed BOS alignment 20
Internal structure alignment 10 Order-flow alignment 15 
Displacement quality 10 
MTF agreement 10 
Active delivery alignment 5 DOL directional compatibility 5 ----------------------------------------- 
Total 100 
Each component contributes its full weight when aligned, half  when neutral/partial, and zero when conflicting. Example: 
text 
External bullish structure 25/25 
Bullish BOS 20/20 
Internal bullish 10/10 
Bullish order flow 15/15 
Strong displacement 10/10 
MTF partly aligned 5/10 
Delivery aligned 5/5 
DOL aligned 5/5 
Score = 95
Interpretation: 
text 
90–100 = Elite 
80–89 = Strong 
70–79 = Valid 
60–69 = Weak / observation only 
<60 = No trade 
Default trade threshold: 
text 
70 
1.8 CHoCH context 
A CHoCH should only occur when a prior directional condition  exists. 
Do not produce CHoCH in a completely neutral range. Bearish CHoCH: 
text 
Previous state = Bullish or Bullish 

Transition 
AND 
price closes below the protected bullish  low 
+ 
minimum break distance requirement 
Bullish CHoCH: 
text 
Previous state = Bearish or Bearish  Transition 
AND 
price closes above the protected bearish  high 
+ 
minimum break distance requirement Inside a range, breaking a minor internal level is simply:

text 
Internal structural break 
not CHoCH. 
1.9 Displacement formula 
Displacement must be measurable. For candle i: 
text 
Range = 
High[i] - Low[i] 
Body = 
abs(Close[i] - Open[i]) 
BodyRatio = 
Body / Range 
ATR ratio:
text 
ATRRatio = 
Range / ATR(14) 
Close-location strength: 
Bullish: 
text 
CloseStrength = 
(Close - Low) / Range 
Bearish: 
text 
CloseStrength = 
(High - Close) / Range 
A valid displacement candle requires: text 
Range >= 1.20 × ATR(14)
AND 
Body / Range >= 0.65 
AND 
directional CloseStrength >= 0.75 
Strong displacement: 
text 
Range >= 1.50 ATR 
BodyRatio >= 0.70 
CloseStrength >= 0.80 
Extreme displacement: 
text 
Range >= 2.00 ATR 
BodyRatio >= 0.75 
CloseStrength >= 0.85
leg. 
A displacement leg is valid if: 
text 
2–4 consecutive candles 
same direction 
combined movement >= 1.5 ATR 
and at least one candle satisfies valid displacement criteria 
─── 
2. MODULE 005 — ORDER FLOW ENGINE 
The PDF asks for the exact Order Flow definition, consumed  inputs, outputs and state-change conditions.  
2.1 Definition 
Order Flow represents: 
the currently confirmed direction in which price is successfully  delivering through structure. 
It is not based on candle colour alone. 
States:
text 
BULLISH 
BEARISH 
NEUTRAL 
TRANSITION_BULLISH 
TRANSITION_BEARISH 
Bullish Order Flow 
Requires: 
text 
1. Confirmed bullish BOS 
2. Bullish displacement associated with  the BOS 
3. Latest protected low remains intact 
Bearish Order Flow 
Requires:
text 
1. Confirmed bearish BOS 
2. Bearish displacement associated with  the BOS 
3. Latest protected high remains intact 
2.2 Inputs 
Consume: 
text 
External swings 
Internal swings 
HH / HL / LH / LL 
Protected highs/lows 
BOS 
CHoCH 
Displacement 
Current market phase 
ATR 
Candle data
2.3 Outputs 
Produce: 
cpp 
direction 
previousDirection 
state 
confidenceScore 
originSwingId 
protectedSwingId lastBOSId 
lastCHoCHId 
displacementId 
startTime 
lastUpdatedTime 
bullishStrength 
bearishStrength 
transition
confirmed 
invalidated 
2.4 Bullish → Bearish transition 
Do not immediately flip from bullish to bearish from one wick. Sequence: 
text 
Bullish Order Flow 
↓ 
Protected bullish low broken by  
confirmed bearish CHoCH 
↓ 
TRANSITION_BEARISH 
↓ 
Bearish continuation structure forms ↓ 
Bearish BOS confirms 
↓ 
BEARISH 
Reverse for bullish.
─── 
3. MODULE 006 — DELIVERY STRUCTURE ENGINE 
The PDF asks what Delivery Structure is, how it is calculated, what  validates it, and how it interacts with structure/order flow.  
3.1 Definition 
Delivery Structure represents: 
the active directional price-delivery leg from a confirmed  structural origin toward the next objective. 
It connects: 
text 
Market Structure 
+ 
Order Flow 
+ 
Displacement 
+ 
Objective/DOL
text 
Origin: 
protected low / demand POI 
Movement: 
bullish displacement 
Structural evidence: 
bullish BOS 
Objective: 
buy-side liquidity / bullish DOL 
Bearish delivery 
text 
Origin: 
protected high / supply POI 
Movement: 
bearish displacement
Structural evidence: 
bearish BOS 
Objective: 
sell-side liquidity / bearish DOL 
3.2 Valid delivery conditions 
A delivery becomes ACTIVE only when: text 
Confirmed direction 
+ 
Order Flow agrees 
+ 
Valid displacement exists 
+ 
Origin remains valid 
+ 
Destination/objective exists Optional MTF filter:
text 
HTF narrative must not strongly oppose  delivery. 
3.3 Lifecycle 
text 
CANDIDATE 
ACTIVE 
MITIGATED 
OBJECTIVE_REACHED 
INVALIDATED 
REPLACED 
ARCHIVED 
3.4 Invalidation 
Bullish delivery invalidates when: 
text 
confirmed close below delivery 
protected low 
Bearish: 
text 
confirmed close above delivery  protected high 
A wick alone does not invalidate by default. 
3.5 Outputs 
text 
Direction 
Origin price 
Origin time 
Protected price 
Current objective 
Associated BOS 
Associated displacement 
Associated POI 
Lifecycle 
Confidence 
Progress %
Invalidation level 
─── 
4. MODULE 007 — LIQUIDITY ENGINE 
The PDF specifically asks for buy-side/sell-side liquidity, EQH/EQL,  tolerance, sweeps, breakout distinction, whether swept liquidity  remains, and whether liquidity is ranked.  
4.1 Buy-side liquidity 
Buy-side liquidity exists above: 
text 
Confirmed swing highs 
Equal highs 
Previous day high 
Previous week high 
Session highs 
Unmitigated external highs 
4.2 Sell-side liquidity
text 
Confirmed swing lows 
Equal lows 
Previous day low 
Previous week low 
Session lows 
Unmitigated external lows 
4.3 EQH / EQL 
Minimum: 
text 
2 distinct touches 
Recommended stronger pool: 
text 
3+ touches 
Tolerance:
text 
LiquidityTolerance = 
max( 
 3 × SYMBOL_POINT, 
 0.10 × ATR(14) 
) 
EQH: 
text 
abs(HighA - HighB) <= tolerance 
EQL: 
text 
abs(LowA - LowB) <= tolerance 
Minimum bar separation: 
text 
3 closed candles
This prevents adjacent candles from being incorrectly classified as  separate liquidity touches. 
4.4 Sweep 
Buy-side sweep: 
text 
High breaches liquidity level 
AND 
candle closes back below: 
LiquidityLevel + tolerance 
Stronger confirmation: 
text 
next closed candle trades/continues  
lower 
Sell-side sweep:
text 
Low breaches liquidity level 
AND 
candle closes back above: 
LiquidityLevel - tolerance 
4.5 Sweep vs breakout 
Buy-side: 
text 
Sweep: 
wick above + close back below/inside 
Breakout: 
close above level + minimum break  distance 
Sell-side:
text 
Sweep: 
wick below + close back above/inside 
Breakout: 
close below level - minimum break  distance 
4.6 Swept liquidity lifecycle 
Do not delete it. 
State: 
text 
ACTIVE 
TOUCHED 
SWEPT 
BROKEN 
CONSUMED 
ARCHIVED 
Once swept:
text 
active=false 
swept=true 
Keep it for: 
text 
historical analysis 
entry confirmation 
analytics 
chart annotations 
4.7 Liquidity ranking 
Yes. 
Score 0–100. 
text 
External swing 25 EQH/EQL 20 HTF origin 20 3+ touches 10
Untouched freshness 10 
Alignment with delivery 5 
Alignment with DOL 5 
Session/PDH/PDL/PWH/PWL 5 ---------------------------------- 
Total 100 
Priority: 
text 
80–100 High 
60–79 Medium 
<60 Low 
─── 
5. MODULE 008 — POI ENGINE 
The PDF asks for exact Order Block, Breaker Block, Mitigation  Block and FVG definitions, validation/invalidation, minimum FVG  size, fill definition, overlap handling and POI priority.  
5.1 Bullish Order Block
The last bearish candle or compact bearish candle cluster  immediately before bullish displacement that causes a confirmed  bullish BOS. 
Mandatory: 
text 
1. Bearish candle/cluster 
2. Followed by valid bullish displacement 3. Displacement causes confirmed  
bullish BOS 
4. OB precedes BOS 
Default zone: 
text 
Low of OB 
to 
Open of OB 
Optional full-candle display:
text 
Low → High 
but execution zone uses: 
text 
Low → Open 
5.2 Bearish Order Block 
Reverse: 
text 
last bullish candle before bearish  displacement 
which causes confirmed bearish BOS 
Zone: 
text 
Open → High
5.3 Breaker Block 
A failed Order Block that is structurally broken and subsequently  used from the opposite side. 
Bullish breaker: 
text 
Previous bearish/supply OB 
↓ 
price closes above it 
↓ 
bullish structural confirmation 
↓ 
price returns from above 
↓ 
former supply acts as demand 
Bearish breaker is inverse. 
Mandatory: 
text 
Original valid OB 
Structural failure of that OB 
Opposite-direction BOS
Retest from opposite side 
5.4 Mitigation Block 
A mitigation block is the final opposing candle/zone in an  impulsive leg that price later revisits to rebalance outstanding  institutional exposure, without requiring that the original zone itself  caused the primary BOS. 
To prevent overclassification: 
text 
Must belong to a confirmed  
displacement leg 
Must be structurally aligned 
Must remain unmitigated 
Must be located between displacement  origin and structural break 
Priority below a valid BOS-producing Order Block. 
5.5 Fair Value Gap 
Bullish FVG using closed candles A-B-C:
text 
Low[C] > High[A] 
Gap: 
text 
High[A] → Low[C] 
Bearish: 
text 
High[C] < Low[A] 
Gap: 
text 
High[C] → Low[A] 
Candle B should preferably be displacement.

text 
MinimumFVG = 
max( 
 3 × SYMBOL_POINT, 
 0.10 × ATR(14) 
) 
For higher-quality FVG: 
text 
GapSize >= 0.20 ATR 
5.7 FVG fill 
Track percentage: 
text 
FillPercent = 
penetrationIntoGap / totalGapSize × 100 States:
text 
0% untouched 
1–49% partially mitigated 
50–99% materially mitigated 
100% filled 
An FVG becomes: 
text 
FILLED 
when price traverses the complete gap boundary. Do not delete it; archive it. 
5.8 POI invalidation 
Bullish OB: 
text 
confirmed candle close below OB low Bearish:

text 
confirmed close above OB high 
Default FVG invalidation: 
text 
100% fill 
Breaker invalidation: 
text 
close through the opposite structural  boundary 
5.9 Overlapping POIs 
Merge only if: 
text 
same direction 
same structural leg
overlap >= 50% of smaller POI 
Otherwise retain separately. 
Create a: 
text 
confluenceScore 
for overlapping independent POIs. 
Example: 
text 
Bullish OB + bullish FVG overlap 
should receive additional confidence. 
5.10 POI priority 
Default: 
text 
1. Fresh HTF Order Block causing BOS 2. Breaker Block with confirmed retest 3. OB + FVG confluence
4. Standalone fresh Order Block 
5. Mitigation Block 
6. Standalone FVG 
Score factors: 
text 
Freshness 
Timeframe 
Structural origin 
Displacement strength 
BOS relationship 
Liquidity relationship 
DOL alignment 
Premium/discount location 
MTF alignment 
Confluence 
─── 
6. MODULE 009 — OBJECTIVE / DOL ENGINE 
The PDF asks how objectives are determined, whether objective is 
6.1 Definition 
DOL = Draw on Liquidity. 
It represents: 
the highest-priority unresolved destination toward which  current delivery is expected to seek liquidity. 
6.2 Candidate objectives 
Priority candidates: 
text 
External swing liquidity 
EQH/EQL 
Previous day high/low 
Previous week high/low 
Session liquidity 
Unmitigated structural extremes 
Major FVG boundary 
Opposing HTF POI boundary 
Primary DOL should normally be liquidity. 
However, the engine may maintain secondary objectives such as:
text 
FVG rebalance 
POI mitigation 
range boundary 
6.3 DOL selection score 
text 
Direction compatibility 25 Liquidity strength 20 HTF significance 15 Freshness 10 
Structural significance 10 Distance feasibility 5 Delivery alignment 10 MTF alignment 5 -------------------------------- 
Total 100 
Choose highest valid score. 
Minimum active DOL score:
text 
60 
6.4 DOL replacement 
Yes, objective may change before being reached. Only replace when: 
text 
Current DOL invalidated/consumed OR 
delivery direction changes 
OR 
new objective score exceeds current  objective by >= 15 points 
AND 
new objective is structurally more  relevant
Do not constantly switch DOL because a slightly closer liquidity  level appears. 
Use hysteresis: 
text 
ReplacementScoreAdvantage = 15 
─── 
7. MODULE 010 — CONFIRMATION ENGINE 
The PDF asks what confirms a valid setup, mandatory vs optional  confirmations, LTF requirements, and the required BOS/CHoCH/ Liquidity/POI combination.  
7.1 Setup prerequisite 
Before looking for execution confirmation: 
text 
1. Valid MTF narrative 
2. Active delivery 
3. Active DOL 
4. Valid POI
5. Price enters/touches POI 
These establish location and narrative. 
7.2 Mandatory confirmation 
Default mandatory: 
text 
POI interaction 
+ 
Liquidity event OR rejection 
+ 
LTF structural confirmation 
A trade should not occur merely because price touches an OB. 
7.3 Preferred confirmation sequence 
For bullish: 
text 
Price enters bullish POI 
↓ 
Sell-side liquidity swept
↓ 
Bullish displacement 
↓ 
Bullish CHoCH 
↓ 
Bullish BOS 
↓ 
Entry 
Bearish inverse. 
7.4 Minimum valid combination Standard setup: 
text 
Valid POI 
+ 
Liquidity sweep/rejection + 
CHoCH or BOS 
+ 
displacement
Strong setup: 
text 
Valid POI 
+ 
liquidity sweep 
+ 
CHoCH 
+ 
BOS 
+ 
displacement/FVG 
7.5 Mandatory vs optional 
Mandatory by default: 
text 
Active POI 
MTF not opposing 
Correct delivery direction Minimum signal confidence Structural confirmation
At least one must be present: text 
Liquidity sweep 
Strong rejection 
At least one structural trigger: text 
CHoCH 
BOS 
Optional score enhancers: 
text 
FVG 
OB/FVG confluence 
Premium/discount 
Session alignment 
HTF liquidity 
Displacement strength
7.6 Lower timeframe confirmation 
Yes for standard execution. 
Recommended hierarchy: 
text 
HTF narrative 
D1 / H4 
Intermediate delivery H1 / M15 
Execution confirmation M5 
For M15 execution: 
text 
H4/H1 narrative 
M15 confirmation 
For M5 execution:
text 
H1/M15 narrative 
M5 confirmation 
The EA should not require M1 by default. 
─── 
8. MODULE 011 — ENTRY ENGINE 
The PDF asks for exact entry trigger, candle of execution, order  type, and entry invalidation.  
8.1 Exact entry trigger 
Default entry trigger: 
text 
Closed execution-timeframe candle  confirms 
CHoCH or BOS 
in expected direction 
after valid POI interaction
Entry occurs: 
text 
at first available market price 
after the confirming candle closes 
Therefore: 
text 
Signal candle = candle 1 
Execution happens on candle 0 opening/ live tick 
The strategy does not use candle 0 to confirm the signal. 
8.2 Market vs pending 
Default: 
text 
Market execution 
Pending orders remain supported but disabled by default.
Future optional: 
text 
Limit at POI refinement 
Stop above/below confirmation structure 
But Phase 1 production mode should use market entry after  confirmation. 
8.3 Entry invalidation before execution 
Cancel signal if any occurs first: 
text 
POI invalidates 
DOL changes direction 
Delivery invalidates 
MTF permission reverses 
Confirmation structure invalidates Signal expires 
RR falls below required minimum 
Spread exceeds maximum 
Risk Manager blocks trade
Default signal expiration: 
text 
5 execution-timeframe bars 
8.4 Duplicate-entry prevention 
Each signal ID may generate: 
text 
maximum 1 execution 
Store: 
text 
signal.consumed=true 
after successful execution. 
Even if the EA restarts, execution history and journal must prevent  the same signal from executing again. 
───
9. MODULE 012 — RISK ENGINE 
The PDF asks how SL/TP, risk, position sizing and active  management should work.  
9.1 Risk model 
Percentage-based. 
Default: 
text 
1.00% of account equity per trade 
Configuration: 
text 
Minimum = 0.25% 
Default = 1.00% 
Maximum = 2.00% 
Never increase risk after losses. 
No martingale. 
9.2 Stop loss
Bullish: 
text 
SL below the structural invalidation low 
Bearish: 
text 
SL above structural invalidation high 
Buffer: 
text 
StopBuffer = 
max( 
 2 × SYMBOL_POINT, 
 0.20 × ATR(14) 
) 
Bullish:
text 
SL = 
InvalidationLow - StopBuffer 
Bearish: 
text 
SL = 
InvalidationHigh + StopBuffer 
9.3 Take profit 
Primary: 
text 
Active DOL 
But trade is approved only if: 
text 
RewardRisk >= 1.50R
Calculate: 
text 
RiskDistance = 
abs(Entry - SL) 
RewardDistance = 
abs(TP - Entry) 
RR = 
RewardDistance / RiskDistance 
If DOL provides less than minimum RR: 
text 
Reject trade 
Do not artificially move TP farther simply to create 1.5R. 
9.4 Position size 
Risk amount:
text 
RiskAmount = 
AccountEquity × RiskPercent / 100 
Position size must be calculated using broker properties, not a  hard-coded pip formula. 
MT5 preferred calculation: 
cpp 
OrderCalcProfit() 
Conceptually: 
text 
Determine loss for 1.0 lot 
from Entry to SL 
Volume = 
RiskAmount / LossPerLot 
Then normalize using:
text 
SYMBOL_VOLUME_MIN 
SYMBOL_VOLUME_MAX 
SYMBOL_VOLUME_STEP 
Never round upward beyond risk tolerance. Prefer: 
text 
floor to valid volume step 
9.5 Partial close 
Default: 
text 
At +1.0R 
close 50% 
Only once unless explicitly configured otherwise.
Default: 
text 
Trigger = +1.0R 
After partial close / trigger: 
Buy: 
text 
SL = Entry + max(2 points, ATR offset) 
Sell: 
text 
SL = Entry - max(2 points, ATR offset) 
Default ATR offset: 
text 
0
so default effective buffer: 
text 
2 points 
9.7 Trailing stop 
Starts: 
text 
+1.5R 
Default: 
text 
1 ATR behind current price 
Update after: 
text 
every additional +0.5R progress
Buy: 
text 
TrailingSL = 
Bid - ATR(14) 
Sell: 
text 
TrailingSL = 
Ask + ATR(14) 
Never worsen a stop. 
Buy stop: 
text 
newSL > currentSL Sell:
text 
newSL < currentSL 
9.8 Additional active-position exit rules 
Configurable: 
text 
DOL reached 
DOL invalidated 
Delivery invalidated 
Confirmed MTF reversal 
Daily protection trigger 
A wick-only structural warning must not force an exit. ─── 
10. MULTI-TIMEFRAME ANALYSIS 
The PDF asks which timeframes should be analysed together,  which defines trend vs entry, and whether MTF should be internal 
10.1 Default timeframe hierarchy Use: 
text 
W1 
D1 
H4 
H1 
M15 
M5 
M1 optional and disabled by default. 
Macro narrative 
text 
W1 + D1 
Purpose:
text 
Macro structure 
Major liquidity 
Long-term premium/discount Major DOL 
Higher-timeframe directional bias 
text 
D1 + H4 
Purpose: 
text 
Primary directional narrative External structure 
Major delivery 
Intermediate setup
text 
H1 + M15 
Purpose: 
text 
Current delivery POI selection 
Liquidity 
Setup location 
Execution 
text 
M5 
Purpose: 
text 
Sweep 
Rejection
CHoCH 
BOS 
Displacement 
Entry 
10.2 Which timeframe defines trend? 
There is not one universal timeframe. 
The engine should define: 
text 
MacroTrend = D1/H4 consensus SetupTrend = H1/M15 consensus ExecutionFlow = M5 
Trade permission is based on weighted agreement. 
10.3 MTF scoring 
Default weights: 
text 
W1 15 
D1 25 
H4 25
H1 15 
M15 12 
M5 8 
-------- 
100 
Directional score: 
text 
Bullish timeframe = +weight 
Bearish timeframe = -weight 
Neutral = 0 
Transition = ±0.5 weight 
Example: 
text 
Net score >= +35 → Bullish permission Net score <= -35 → Bearish permission -34 to +34 → Neutral / no directional  permission 
Additional rule:
A trade cannot oppose both: 
text 
D1 
AND 
H4 
unless a dedicated reversal mode is later created. 
10.4 MTF architecture 
Use: 
text 
ONE coordinated engine 
with separate per-symbol/per-timeframe state. 
Do not run six independent strategy EAs and try to reconcile them  externally. 
Architecture: 
text 
Single CMNSContext 
↓
registered timeframe states ↓ 
per-timeframe analysis 
↓ 
MultiTimeframeEngine 
↓ 
combined narrative 
That is much safer for: 
text 
Synchronization 
Signal identity 
Risk control 
DOL coordination 
Duplicate prevention 
Journaling 
Backtesting 
─── 
11. COMPLETE TRADE STATE MACHINE
Your developer should implement the strategy as a deterministic  state machine: 
text 
NO_SETUP 
↓ 
NARRATIVE_VALID 
↓ 
DELIVERY_ACTIVE 
↓ 
DOL_SELECTED 
↓ 
POI_ACTIVE 
↓ 
PRICE_APPROACHING_POI 
↓ 
POI_TOUCHED 
↓ 
LIQUIDITY_EVENT 
↓ 
LTF_CONFIRMATION_PENDING 
↓ 
CHOCH_CONFIRMED 
↓
BOS/DISPLACEMENT_CONFIRMED ↓ 
SIGNAL_CONFIRMED 
↓ 
RISK_PENDING 
↓ 
RISK_APPROVED 
↓ 
EXECUTION_PENDING 
↓ 
FILLED 
↓ 
POSITION_ACTIVE 
↓ 
PARTIAL 
↓ 
BREAK_EVEN 
↓ 
TRAILING 
↓ 
CLOSED 
↓ 
JOURNALED 
↓ 
ANALYSED
At any pre-entry stage: 
text 
INVALIDATED 
EXPIRED 
CANCELLED 
must terminate the chain. 
─── 
12. DEFAULT STRATEGY PARAMETERS TO FREEZE Give your developer this configuration: 
text 
External Swing Depth = 15 
Internal Swing Depth = 5 
Swing left/right window = depth/depth 
Closed candle confirmation = true Use candle 0 for signals = false
ATR period = 14 
Minimum Break Distance = max(2 points, 0.10 ATR) 
Equal High/Low Tolerance = max(3 points, 0.10 ATR) 
Minimum FVG Size = 
max(3 points, 0.10 ATR) 
Displacement Range >= 1.20 ATR Displacement Body Ratio >= 65% Displacement Close Strength >= 75% 
Minimum Signal Confidence = 70% Minimum RR = 1.50R 
Default Risk = 1.00% 
Minimum Risk = 0.25% Maximum Risk = 2.00% 
Partial Profit Trigger = +1.00R
Partial Close = 50% 
Break Even Trigger = +1.00R BE Offset = 2 points 
Trailing Start = +1.50R 
Trailing Distance = 1 ATR 
Trailing Step = 0.50R 
Signal Expiry = 5 execution bars 
DOL Minimum Score = 60 
DOL Replacement Advantage = 15  points 
MTF Bull Permission >= +35 
MTF Bear Permission <= -35 
─── 
13. EXACT BUY SETUP 
Developer should be able to test this literally.
