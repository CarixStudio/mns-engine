MNS Strategy 3 — Consolidated 
Locked Specification
1. Strategy architecture
The implementation remains:
text
Main Market Structure
 ↓
Order Flow
 ↓
Delivery Structure
 ↓
Liquidity
 ↓
Objective / DOL
 ↓
POI
 ↓
Entry Confirmation
 ↓
Risk Approval
 ↓
Execution
 ↓
Position Management
 ↓
Journal / Analytics
text
Main Market Structure
 ↓
Order Flow
 ↓
Delivery Structure
 ↓
Liquidity
 ↓
Objective / DOL
 ↓
POI
 ↓
Entry Confirmation
 ↓
Risk Approval
 ↓
Execution
 ↓
Position Management
 ↓
Journal / Analytics
The first PDF explicitly identifies Modules 005–
012 and asks for their mathematical rules. 
The new handoff reports Modules 001–012 as 
implemented/tested and says Stage 1 is ready 
to begin. 
───
2. Swing structure
Locked rule
Internal swings:
text
Depth = 5
5 completed candles left
Candidate candle
5 completed candles right
External swings:
text
Depth = 15
15 completed candles left
Candidate candle
15 completed candles right
Therefore, "15 candles" means:
text
15 on each side
not 15 total.
The first PDF specifically asks the developer to 
resolve whether the confirmation window is two 
candles or equal to depth and whether “15 
candles” means 15 each side or total. 
No look-ahead
The candidate exists historically at its candle, 
but it becomes confirmed only after the required 
right-hand candles exist.
Store:
cpp
originTime
confirmationTime
Never use the candidate as a confirmed swing 
before confirmation time.
───
3. Equal highs/lows
Use:
text
StructuralEqualityTolerance =
max(
 2 × Point,
 0.05 × ATR(14)
)
If multiple highs/lows within the same swing 
window fall inside that tolerance:
text
earliest = structural swing
later equal touches = liquidity 
observations
Do not generate several HH/LH or LL/HL 
structural events from one equal-price cluster.
───
4. Shift = 2
Shift = 2 does not mean swing depth.
It means:
text
Bar 0 = currently forming
Bar 1 = most recently closed
Bar 2 = safely historical/reference bar 
where required
Structural confirmation still uses the configured 
5/15 swing depth.
───
5. BOS minimum break distance
Use:
text
MinimumBreakDistance =
max(
 2 × Point,
 0.10 × ATR(14)
)
Bullish BOS:
text
Close >
SwingHigh + MinimumBreakDistance
Bearish BOS:
text
Close <
SwingLow - MinimumBreakDistance
A wick alone:
text
≠ confirmed BOS
The first PDF specifically identifies Minimum 
Break Distance as unresolved. 
───
6. CHoCH
CHoCH requires a pre-existing directional 
structure.
Bearish CHoCH
text
Current structure = bullish
AND
confirmed close below protected bullish 
low
by MinimumBreakDistance
Bullish CHoCH
text
Current structure = bearish
AND
confirmed close above protected 
bearish high
by MinimumBreakDistance
text
Current structure = bearish
AND
confirmed close above protected 
bearish high
by MinimumBreakDistance
A minor break inside a directionless range is not 
automatically CHoCH.
A wick through the protected level is:
text
warning / liquidity event
not confirmed CHoCH.
───
7. Market phase
Every timeframe maintains:
text
BULLISH
BEARISH
RANGE
TRANSITION
UNKNOWN
text
BULLISH
BEARISH
RANGE
TRANSITION
UNKNOWN
Bullish:
text
HH + HL
+
latest structural continuation bullish
+
no subsequently confirmed bearish 
CHoCH
Bearish:
text
LL + LH
+
latest structural continuation bearish
+
no subsequently confirmed bullish 
CHoCH
Transition:
text
opposite CHoCH confirmed
but
new-direction continuation/BOS not yet 
established
───
8. Displacement
For a candle:
text
Range = High - Low
Body = abs(Close - Open)
BodyRatio = Body / Range
ATRRatio = Range / ATR(14)
text
Range = High - Low
Body = abs(Close - Open)
BodyRatio = Body / Range
ATRRatio = Range / ATR(14)
Bullish close strength:
text
(Close - Low) / Range
Bearish close strength:
text
(High - Close) / Range
Standard valid displacement
text
Range >= 1.20 ATR
BodyRatio >= 0.65
Directional close strength >= 0.75
Strong
text
Range >= 1.50 ATR
BodyRatio >= 0.70
Directional close strength >= 0.80
The first PDF explicitly asks for the exact 
displacement formula. 
───
9. Order Flow
Order Flow means the confirmed direction in 
which price is successfully delivering through 
structure.
States:
text
BULLISH
BEARISH
TRANSITION_BULLISH
TRANSITION_BEARISH
NEUTRAL
text
BULLISH
BEARISH
TRANSITION_BULLISH
TRANSITION_BEARISH
NEUTRAL
Bullish Order Flow requires:
text
bullish BOS
+
bullish displacement
+
protected bullish low intact
Bearish is inverse.
Do not flip bullish → bearish from one opposing 
candle.
Use:
text
Bullish
→ protected low broken by confirmed 
bearish CHoCH
→ Transition Bearish
→ bearish continuation/BOS
→ Bearish
text
Bullish
→ protected low broken by confirmed 
bearish CHoCH
→ Transition Bearish
→ bearish continuation/BOS
→ Bearish
───
10. Delivery Structure
Delivery represents the active directional 
movement from a structural origin toward its 
objective.
Valid bullish delivery
text
Bullish structure/order flow
+
valid bullish displacement
+
protected origin
+
valid objective above price
text
Bullish structure/order flow
+
valid bullish displacement
+
protected origin
+
valid objective above price
Bearish is inverse.
Lifecycle:
text
CANDIDATE
ACTIVE
MITIGATED
OBJECTIVE_REACHED
INVALIDATED
REPLACED
ARCHIVED
───
11. Delivery mitigation — 
correction to temporary 
implementation
The new audit says the current implementation 
treats a wick touch of the invalidation price as 
mitigation and asks for final confirmation. 
Locked decision
That temporary interpretation should not
become the final rule.
Mitigation means:
text
price returns into the originating POI / 
delivery origin zone
A wick entering the originating zone may mark:
text
MITIGATION_STARTED
but:
text
Mitigation ≠ invalidation
Invalidation requires structural failure.
Bullish delivery invalidation:
text
confirmed close below protected low
by MinimumBreakDistance
Bearish inverse.
───
12. Delivery replacement
The new PDF says same-direction BOS is 
currently used as the replacement trigger and 
requests approval or replacement. 
Locked decision
Keep same-direction BOS with structural 
qualification.
A new delivery replaces the existing delivery 
when:
text
1. New BOS is confirmed.
2. BOS direction = current delivery 
direction.
3. BOS breaks a genuinely new 
structural level.
4. A newer protected swing is 
established.
5. BOS belongs to the current delivery 
sequence.
Do not replace on repeated breaks of the same 
structural level.
Use identity such as:
cpp
newBrokenSwingId != 
previousBrokenSwingId
or the equivalent existing structure identifier.
───
13. Delivery archival
The temporary implementation uses opposite￾direction CHoCH as the archival trigger. 
Locked decision
Approve it only for confirmed CHoCH.
text
Wick warning
→ no archival
Confirmed opposite CHoCH
→ invalidate active delivery
→ archive
text
Wick warning
→ no archival
Confirmed opposite CHoCH
→ invalidate active delivery
→ archive
Do not automatically establish the opposite 
delivery immediately.
Example:
text
Bullish Delivery
→ confirmed bearish CHoCH
→ Bullish Delivery archived
→ Market = Transition Bearish
→ later bearish continuation confirms
→ Bearish Delivery created
───
14. Liquidity
Buy-side liquidity
Above:
text
Swing highs
Equal highs
External highs
Previous day/week highs
Relevant session highs
Sell-side liquidity
Below:
text
Swing lows
Equal lows
External lows
Previous day/week lows
Relevant session lows
EQH/EQL tolerance
text
LiquidityTolerance =
max(
 3 × Point,
 0.10 × ATR(14)
)
Minimum:
text
2 distinct touches
Minimum separation:
text
3 closed candles
───
15. Liquidity sweep
Buy-side sweep
text
High > liquidity level
AND
candle closes back below/inside level 
tolerance
Sell-side sweep
text
Low < liquidity level
AND
candle closes back above/inside 
tolerance
text
Low < liquidity level
AND
candle closes back above/inside 
tolerance
Breakout
A breakout instead requires:
text
body close beyond level
+
MinimumBreakDistance
Swept liquidity is not deleted.
Use lifecycle:
text
ACTIVE
TOUCHED
SWEPT
BROKEN
CONSUMED
ARCHIVED
text
ACTIVE
TOUCHED
SWEPT
BROKEN
CONSUMED
ARCHIVED
───
16. Liquidity storage capacity
The new audit records the existing 128-element 
buffer as a memory decision requiring 
validation. 
Locked engineering decision
Approve:
text
128 liquidity records per symbol/
timeframe
for the current release.
When full, purge in this order:
text
Archived
→ Invalidated
→ Consumed
→ oldest Swept
→ oldest Broken
→ lowest-priority remaining historical 
pool
Do not purge:
text
current DOL
active external liquidity
active high-priority HTF pool
The number 128 is a capacity setting, not a 
market rule.
───
17. Liquidity score
Use 0–100:
text
External swing significance 25
EQH/EQL quality 20
HTF relevance 20
Touch count 10
Freshness 10
Delivery alignment 5
DOL relevance 5
Session/PDH/PDL/PWH/PWL context 
5
-------------------------------------
Total 100
───
18. POI — Order Block
Bullish OB:
text
last bearish candle/compact bearish 
cluster
immediately preceding valid bullish 
displacement
that produces confirmed bullish BOS
Execution zone:
text
Low → Open
Bearish inverse:
text
Open → High
The POI must have actual structural causation; 
not every opposing candle becomes an Order 
Block.
───
19. Breaker Block
A Breaker is a previously valid OB that:
text
fails structurally
→ opposite BOS confirms
→ zone is later approached from 
opposite side
It then becomes usable as an opposite-direction 
POI.
───
20. Mitigation Block
A Mitigation Block must:
text
belong to a confirmed displacement leg
+
remain structurally aligned
+
remain unmitigated
+
exist between displacement origin and 
structural break
It ranks below a fresh BOS-producing Order 
Block.
───
21. FVG
Bullish three-candle FVG:
text
Low[C] > High[A]
Bearish:
text
High[C] < Low[A]
Minimum:
text
FVGSize >= max(3 × Point, 0.10 ATR)
Track mitigation percentage.
text
0% untouched
1–49% partially mitigated
50–99% materially mitigated
100% filled
A filled FVG remains in historical records but is 
inactive.
───
22. Overlapping POIs
Merge only when:
text
same direction
same structural leg
overlap >= 50% of smaller zone
Otherwise preserve separately and increase 
confluence where appropriate.
───
23. POI score
The new audit specifically says liquidity strength 
5 and HTF significance 15 are currently 
hardcoded and need final confirmation. 
Locked formula
text
Structural/BOS relationship 20
Freshness 15
Displacement 15
HTF significance 15
DOL alignment 10
MTF alignment 10
Liquidity relationship 5
Premium/discount 5
Confluence 5
------------------------------------
TOTAL 100
text
Structural/BOS relationship 20
Freshness 15
Displacement 15
HTF significance 15
DOL alignment 10
MTF alignment 10
Liquidity relationship 5
Premium/discount 5
Confluence 5
------------------------------------
TOTAL 100
Therefore formally approve:
text
HTF significance = 15
Liquidity strength = 5
Classification:
text
90–100 Elite
80–89 Strong
70–79 Valid
60–69 Weak
<60 reject as standalone POI
───
24. DOL / Objective
The first PDF asks whether the objective is 
always liquidity and whether it may change 
before being reached. 
DOL means the highest-priority unresolved 
destination compatible with current delivery.
Candidate objectives:
text
External swing liquidity
EQH/EQL
Previous day/week high/low
Relevant session liquidity
Structural extreme
Major opposing liquidity
Secondary rebalance objectives such as FVG/
POI boundaries can exist, but the primary DOL 
should normally represent meaningful liquidity.
Minimum active DOL score:
text
60/100
Replacement requires either:
text
current DOL invalidated/consumed
OR
delivery direction changes
OR
new DOL exceeds current score by >= 15
and is structurally more relevant
This prevents target flickering.
───
25. Historical delivery / objective 
rendering
The new register asks whether the indicator 
should show only current delivery/objective or 
maintain complete historical rendering. 
Final decision
text
CLIENT-Q002 = Option A — Active only
Chart:
text
current active Delivery
current active DOL
text
current active Delivery
current active DOL
only.
But:
text
Journal/analytics history remains 
retained.
Do not refactor the core engines solely to draw 
every old delivery leg.
───
26. CRT / IRL / ERL
The new PDF says these visual terms exist but 
are not mathematically defined by the approved 
core strategy. 
Final decision
text
CLIENT-Q001 = Option A
Do not add independent CRT/IRL/ERL 
algorithms.
Use existing authoritative concepts:
text
Swings
Internal/external liquidity
POIs
OBs
FVGs
DOL
If earlier visual mockups contain CRT/IRL/ERL 
labels, map them to the existing MNS concepts 
or remove those labels.
───
27. Strong rejection — revised 
formal formula
The new register says the existing temporary 
rule is simply wick ratio ≥50%. 
That is insufficient on its own.
Bullish rejection
text
Range = High - Low
LowerWick =
min(Open,Close) - Low
LowerWickRatio =
LowerWick / Range
CloseLocation =
(Close-Low)/Range
Require:
text
LowerWickRatio >= 0.50
CloseLocation >= 0.70
Close > Open
Range >= 0.50 ATR(14)
and valid:
text
POI interaction
or
sell-side liquidity interaction
Bearish rejection
Inverse:
text
UpperWickRatio >= 0.50
Close in bottom 30%
Close < Open
Range >= 0.50 ATR
correct POI/liquidity context
text
UpperWickRatio >= 0.50
Close in bottom 30%
Close < Open
Range >= 0.50 ATR
correct POI/liquidity context
Strong rejection is evidence, not an independent 
entry signal.
───
28. Confirmation sequence
Before execution:
text
Valid narrative
↓
Active delivery
↓
Uncompleted DOL
↓
Valid POI
↓
Price interacts with POI
↓
Liquidity sweep or strong rejection
↓
Directional displacement
↓
CHoCH/BOS confirmation
↓
Signal confidence
↓
Risk validation
text
Valid narrative
↓
Active delivery
↓
Uncompleted DOL
↓
Valid POI
↓
Price interacts with POI
↓
Liquidity sweep or strong rejection
↓
Directional displacement
↓
CHoCH/BOS confirmation
↓
Signal confidence
↓
Risk validation
Minimum standard setup:
text
Valid POI
+
liquidity sweep/rejection
+
CHoCH or BOS
+
displacement
text
Valid POI
+
liquidity sweep/rejection
+
CHoCH or BOS
+
displacement
───
29. Entry
Default execution timeframe:
text
M5
Signal confirmation:
text
closed M5 candle
Actual entry:
text
first available market price
after confirmation candle closes
text
first available market price
after confirmation candle closes
Thus:
text
Bar 1 = confirmation
Bar 0/live price = execution
No candle-0 structural confirmation.
Default:
text
market orders
Pending orders disabled until separately 
validated.
Signal expiry:
text
5 execution candles
One signal ID:
text
maximum one execution
───
30. Multi-timeframe hierarchy
The first PDF asks which timeframes should be 
analysed together and which determine trend/
entries. 
Use:
text
W1 + D1 Macro narrative
D1 + H4 Higher-timeframe bias
H1 + M15 Setup/delivery/POI
M5 Entry confirmation
text
W1 + D1 Macro narrative
D1 + H4 Higher-timeframe bias
H1 + M15 Setup/delivery/POI
M5 Entry confirmation
Weights:
text
W1 15
D1 25
H4 25
H1 15
M15 12
M5 8
---------
100
Directional scoring:
text
Bullish +weight
Bearish -weight
Neutral 0
Transition ±0.5 weight
Permissions:
text
>= +35 = Bullish
<= -35 = Bearish
between = Neutral
Default restriction:
text
Do not take a trade opposing both D1 
and H4.
───
31. Risk
One correction is important here.
The first questions PDF asks what risk model 
should be used, but does not itself supply a 
percentage. 
So the percentages are an implementation 
decision, not something stated by that PDF.
Current configurable architecture should 
continue supporting percentage-based risk.
For the generic EA configuration:
text
risk percent must remain configurable
Do not permanently bury one percentage inside 
strategy logic.
Position sizing:
text
RiskAmount =
AccountEquity × RiskPercent
Then determine the broker-correct loss for one 
lot between Entry and SL and normalize volume 
against:
text
SYMBOL_VOLUME_MIN
SYMBOL_VOLUME_MAX
SYMBOL_VOLUME_STEP
Never hard-code Forex pip-value assumptions.
───
32. SL
For bullish:
text
SL =
StructuralInvalidationLow
-
max(2 × Point, 0.20 ATR)
Bearish inverse.
Never widen an SL after entry.
───
33. TP
Primary target:
text
active DOL
Minimum entry RR:
text
1.50R
If actual DOL offers less:
text
reject setup
text
reject setup
Do not fabricate a farther target just to force 
1.5R.
───
34. Position management defaults
Current design defaults:
text
At +1.0R
→ 50% partial close
At +1.0R
→ move stop to BE + safety offset
At +1.5R
→ begin trailing
Trailing distance
→ 1 ATR
Re-evaluation step
→ each additional 0.5R
text
At +1.0R
→ 50% partial close
At +1.0R
→ move stop to BE + safety offset
At +1.5R
→ begin trailing
Trailing distance
→ 1 ATR
Re-evaluation step
→ each additional 0.5R
These should remain configurable rather than 
embedded across multiple modules.
───
35. Sessions
The new audit records Tokyo/London/New York 
times as temporary assumptions and requires 
approval. 
Our final strategy decision
Session is not mandatory for a valid MNS trade.
Therefore:
text
UseSessionEntryFilter = false by default
The existing session windows may remain 
available for:
text
session high/low calculations
liquidity classification
display
analytics
but should not block an otherwise valid setup.
Centralize them in configuration rather than 
duplicating the times throughout scanning 
functions; the handoff specifically identifies 
session centralization as a later implementation 
task. 
───
36. News
Neither of these two PDFs defines a news filter.
So I do not want your developer to treat a news 
rule as coming from the strategy documentation.
Based on our subsequent discussion, the 
proposed production policy is:
text
High-impact scheduled news
→ block new entries around the event
Existing positions
→ continue normal risk management
Low/medium news
→ no mandatory blocking by default
Proposed initial test window:
text
15 minutes before
15 minutes after
text
15 minutes before
15 minutes after
But this should remain:
text
PROPOSED / TO BE VALIDATED
until you explicitly decide to add it as a locked 
Strategy 3 rule.
I would therefore not modify Modules 001–012 
for news at this Stage 1 handoff.
───
37. Stage 1 — critical development 
constraint
This is where the new PDF is very clear.
Stage 1 should only implement:
text
MT5 indicator shell
OnInit()
OnCalculate()
OnDeinit()
rates synchronization
core-engine coordination
clean lifecycle management
It explicitly prohibits Stage 1 from adding chart 
rendering, modifying Modules 001–012, 
changing MNSConfig, hardcoding visual styles, 
adding trading execution, or inventing missing 
strategy rules. 
Therefore your team should not now go back 
and immediately rewrite all twelve modules 
while they are implementing Stage 1.
Do this:
text
Stage 1
→ integrate existing tested core 
unchanged
Then affected later stages
→ apply these locked strategy decisions
The exit requirements are:
text
MNS_Indicator.mq5
0 errors
0 warnings
clean OnInit
correct OnCalculate engine cycle
clean OnDeinit
no memory leak
existing core tests remain passing
Those requirements are specified directly by the 
handoff. 
───
38. Final client-response sheet
Give your developer this exact block:
text
MNS STRATEGY 3
CLIENT DECISIONS — LOCKED
CLIENT-Q001 — CRT / IRL / ERL
DECISION:
OPTION A — OMIT AS SEPARATE 
CONCEPTS.
Use existing Swing, Liquidity, POI, OB, 
FVG and Objective/DOL
structures. No separate CRT/IRL/ERL 
strategy engines are required.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ OBJECTIVE
DECISION:
OPTION A — ACTIVE ONLY.
Indicator renders the currently active 
Delivery Structure and
current Objective/DOL only.
Historical state remains available 
through journals/analytics where
applicable, but no delivery/objective 
history-buffer refactor is
required for chart rendering.
CLIENT-Q003 — CORE HEURISTICS
DECISION:
OPTION B — FORMALLY LOCK / MODIFY 
SPECIFIC RULES.
SESSION:
Sessions do not determine trade 
eligibility by default.
SessionFilter = OFF.
Session hours may remain for liquidity 
classification/display and
must be centralized in configuration.
LIQUIDITY STORAGE:
128 records per symbol/timeframe 
approved as current technical cap.
Lifecycle/priority eviction required.
STRONG REJECTION:
Directional wick >= 50% of range
AND
directional close location >= 70%
AND
candle body direction agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION:
Return into the originating delivery/POI 
zone.
A wick touching an invalidation price is 
not itself delivery
invalidation.
DELIVERY INVALIDATION:
Confirmed structural close beyond the 
protected delivery level,
subject to MinimumBreakDistance.
DELIVERY REPLACEMENT:
Confirmed same-direction structurally 
relevant BOS establishing a
new protected swing and breaking a 
genuinely new structural level.
DELIVERY ARCHIVAL:
Confirmed opposite-direction CHoCH.
Wick-only warnings do not archive 
delivery.
HTF POI SCORE:
HTF significance = 15/100.
Liquidity relationship = 5/100.
Use the formally defined 100-point POI 
score.
SWINGS:
Internal = 5 left / 5 right.
External = 15 left / 15 right.
No look-ahead.
BREAK:
MinimumBreakDistance =
max(2 × Point, 0.10 × ATR(14)).
DISPLACEMENT:
Range >= 1.20 ATR
BodyRatio >= 65%
Directional close strength >= 75%.
LIQUIDITY:
EQH/EQL tolerance =
max(3 × Point, 0.10 × ATR(14)).
Sweep requires breach followed by 
close back inside.
Confirmed breakout requires body close 
beyond the level and
MinimumBreakDistance.
FVG:
Minimum size =
max(3 × Point, 0.10 × ATR(14)).
DOL:
Minimum candidate score = 60.
Replace active DOL only if invalidated/
consumed, delivery changes,
or new candidate is structurally superior 
by >=15 score points.
ENTRY:
Primary execution TF = M5.
Confirmation uses closed candle.
Execution occurs at next available 
market price.
Signal expiry = 5 execution bars.
One signal = maximum one execution.
MINIMUM RR:
1.50R.
SESSIONS:
Not mandatory for Strategy 3 entry.
NEWS:
Not defined by either source PDF.
Keep separate until formally approved.
text
MNS STRATEGY 3
CLIENT DECISIONS — LOCKED
CLIENT-Q001 — CRT / IRL / ERL
DECISION:
OPTION A — OMIT AS SEPARATE 
CONCEPTS.
Use existing Swing, Liquidity, POI, OB, 
FVG and Objective/DOL
structures. No separate CRT/IRL/ERL 
strategy engines are required.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ OBJECTIVE
DECISION:
OPTION A — ACTIVE ONLY.
Indicator renders the currently active 
Delivery Structure and
current Objective/DOL only.
Historical state remains available 
through journals/analytics where
applicable, but no delivery/objective 
history-buffer refactor is
required for chart rendering.
CLIENT-Q003 — CORE HEURISTICS
DECISION:
OPTION B — FORMALLY LOCK / MODIFY 
SPECIFIC RULES.
SESSION:
Sessions do not determine trade 
eligibility by default.
SessionFilter = OFF.
Session hours may remain for liquidity 
classification/display and
must be centralized in configuration.
LIQUIDITY STORAGE:
128 records per symbol/timeframe 
approved as current technical cap.
Lifecycle/priority eviction required.
STRONG REJECTION:
Directional wick >= 50% of range
AND
directional close location >= 70%
AND
candle body direction agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION:
Return into the originating delivery/POI 
zone.
A wick touching an invalidation price is 
not itself delivery
invalidation.
DELIVERY INVALIDATION:
Confirmed structural close beyond the 
protected delivery level,
subject to MinimumBreakDistance.
DELIVERY REPLACEMENT:
Confirmed same-direction structurally 
relevant BOS establishing a
new protected swing and breaking a 
genuinely new structural level.
DELIVERY ARCHIVAL:
Confirmed opposite-direction CHoCH.
Wick-only warnings do not archive 
delivery.
HTF POI SCORE:
HTF significance = 15/100.
Liquidity relationship = 5/100.
Use the formally defined 100-point POI 
score.
SWINGS:
Internal = 5 left / 5 right.
External = 15 left / 15 right.
No look-ahead.
BREAK:
MinimumBreakDistance =
max(2 × Point, 0.10 × ATR(14)).
DISPLACEMENT:
Range >= 1.20 ATR
BodyRatio >= 65%
Directional close strength >= 75%.
LIQUIDITY:
EQH/EQL tolerance =
max(3 × Point, 0.10 × ATR(14)).
Sweep requires breach followed by 
close back inside.
Confirmed breakout requires body close 
beyond the level and
MinimumBreakDistance.
FVG:
Minimum size =
max(3 × Point, 0.10 × ATR(14)).
DOL:
Minimum candidate score = 60.
Replace active DOL only if invalidated/
consumed, delivery changes,
or new candidate is structurally superior 
by >=15 score points.
ENTRY:
Primary execution TF = M5.
Confirmation uses closed candle.
Execution occurs at next available 
market price.
Signal expiry = 5 execution bars.
One signal = maximum one execution.
MINIMUM RR:
1.50R.
SESSIONS:
Not mandatory for Strategy 3 entry.
NEWS:
Not defined by either source PDF.
Keep separate until formally approved.
text
MNS STRATEGY 3
CLIENT DECISIONS — LOCKED
CLIENT-Q001 — CRT / IRL / ERL
DECISION:
OPTION A — OMIT AS SEPARATE 
CONCEPTS.
Use existing Swing, Liquidity, POI, OB, 
FVG and Objective/DOL
structures. No separate CRT/IRL/ERL 
strategy engines are required.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ OBJECTIVE
DECISION:
OPTION A — ACTIVE ONLY.
Indicator renders the currently active 
Delivery Structure and
current Objective/DOL only.
Historical state remains available 
through journals/analytics where
applicable, but no delivery/objective 
history-buffer refactor is
required for chart rendering.
CLIENT-Q003 — CORE HEURISTICS
DECISION:
OPTION B — FORMALLY LOCK / MODIFY 
SPECIFIC RULES.
SESSION:
Sessions do not determine trade 
eligibility by default.
SessionFilter = OFF.
Session hours may remain for liquidity 
classification/display and
must be centralized in configuration.
LIQUIDITY STORAGE:
128 records per symbol/timeframe 
approved as current technical cap.
Lifecycle/priority eviction required.
STRONG REJECTION:
Directional wick >= 50% of range
AND
directional close location >= 70%
AND
candle body direction agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION:
Return into the originating delivery/POI 
zone.
A wick touching an invalidation price is 
not itself delivery
invalidation.
DELIVERY INVALIDATION:
Confirmed structural close beyond the 
protected delivery level,
subject to MinimumBreakDistance.
DELIVERY REPLACEMENT:
Confirmed same-direction structurally 
relevant BOS establishing a
new protected swing and breaking a 
genuinely new structural level.
DELIVERY ARCHIVAL:
Confirmed opposite-direction CHoCH.
Wick-only warnings do not archive 
delivery.
HTF POI SCORE:
HTF significance = 15/100.
Liquidity relationship = 5/100.
Use the formally defined 100-point POI 
score.
SWINGS:
Internal = 5 left / 5 right.
External = 15 left / 15 right.
No look-ahead.
BREAK:
MinimumBreakDistance =
max(2 × Point, 0.10 × ATR(14)).
DISPLACEMENT:
Range >= 1.20 ATR
BodyRatio >= 65%
Directional close strength >= 75%.
LIQUIDITY:
EQH/EQL tolerance =
max(3 × Point, 0.10 × ATR(14)).
Sweep requires breach followed by 
close back inside.
Confirmed breakout requires body close 
beyond the level and
MinimumBreakDistance.
FVG:
Minimum size =
max(3 × Point, 0.10 × ATR(14)).
DOL:
Minimum candidate score = 60.
Replace active DOL only if invalidated/
consumed, delivery changes,
or new candidate is structurally superior 
by >=15 score points.
ENTRY:
Primary execution TF = M5.
Confirmation uses closed candle.
Execution occurs at next available 
market price.
Signal expiry = 5 execution bars.
One signal = maximum one execution.
MINIMUM RR:
1.50R.
SESSIONS:
Not mandatory for Strategy 3 entry.
NEWS:
Not defined by either source PDF.
Keep separate until formally approved.
text
MNS STRATEGY 3
CLIENT DECISIONS — LOCKED
CLIENT-Q001 — CRT / IRL / ERL
DECISION:
OPTION A — OMIT AS SEPARATE 
CONCEPTS.
Use existing Swing, Liquidity, POI, OB, 
FVG and Objective/DOL
structures. No separate CRT/IRL/ERL 
strategy engines are required.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ OBJECTIVE
DECISION:
OPTION A — ACTIVE ONLY.
Indicator renders the currently active 
Delivery Structure and
current Objective/DOL only.
Historical state remains available 
through journals/analytics where
applicable, but no delivery/objective 
history-buffer refactor is
required for chart rendering.
CLIENT-Q003 — CORE HEURISTICS
DECISION:
OPTION B — FORMALLY LOCK / MODIFY 
SPECIFIC RULES.
SESSION:
Sessions do not determine trade 
eligibility by default.
SessionFilter = OFF.
Session hours may remain for liquidity 
classification/display and
must be centralized in configuration.
LIQUIDITY STORAGE:
128 records per symbol/timeframe 
approved as current technical cap.
Lifecycle/priority eviction required.
STRONG REJECTION:
Directional wick >= 50% of range
AND
directional close location >= 70%
AND
candle body direction agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION:
Return into the originating delivery/POI 
zone.
A wick touching an invalidation price is 
not itself delivery
invalidation.
DELIVERY INVALIDATION:
Confirmed structural close beyond the 
protected delivery level,
subject to MinimumBreakDistance.
DELIVERY REPLACEMENT:
Confirmed same-direction structurally 
relevant BOS establishing a
new protected swing and breaking a 
genuinely new structural level.
DELIVERY ARCHIVAL:
Confirmed opposite-direction CHoCH.
Wick-only warnings do not archive 
delivery.
HTF POI SCORE:
HTF significance = 15/100.
Liquidity relationship = 5/100.
Use the formally defined 100-point POI 
score.
SWINGS:
Internal = 5 left / 5 right.
External = 15 left / 15 right.
No look-ahead.
BREAK:
MinimumBreakDistance =
max(2 × Point, 0.10 × ATR(14)).
DISPLACEMENT:
Range >= 1.20 ATR
BodyRatio >= 65%
Directional close strength >= 75%.
LIQUIDITY:
EQH/EQL tolerance =
max(3 × Point, 0.10 × ATR(14)).
Sweep requires breach followed by 
close back inside.
Confirmed breakout requires body close 
beyond the level and
MinimumBreakDistance.
FVG:
Minimum size =
max(3 × Point, 0.10 × ATR(14)).
DOL:
Minimum candidate score = 60.
Replace active DOL only if invalidated/
consumed, delivery changes,
or new candidate is structurally superior 
by >=15 score points.
ENTRY:
Primary execution TF = M5.
Confirmation uses closed candle.
Execution occurs at next available 
market price.
Signal expiry = 5 execution bars.
One signal = maximum one execution.
MINIMUM RR:
1.50R.
SESSIONS:
Not mandatory for Strategy 3 entry.
NEWS:
Not defined by either source PDF.
Keep separate until formally approved.
text
MNS STRATEGY 3
CLIENT DECISIONS — LOCKED
CLIENT-Q001 — CRT / IRL / ERL
DECISION:
OPTION A — OMIT AS SEPARATE 
CONCEPTS.
Use existing Swing, Liquidity, POI, OB, 
FVG and Objective/DOL
structures. No separate CRT/IRL/ERL 
strategy engines are required.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ OBJECTIVE
DECISION:
OPTION A — ACTIVE ONLY.
Indicator renders the currently active 
Delivery Structure and
current Objective/DOL only.
Historical state remains available 
through journals/analytics where
applicable, but no delivery/objective 
history-buffer refactor is
required for chart rendering.
CLIENT-Q003 — CORE HEURISTICS
DECISION:
OPTION B — FORMALLY LOCK / MODIFY 
SPECIFIC RULES.
SESSION:
Sessions do not determine trade 
eligibility by default.
SessionFilter = OFF.
Session hours may remain for liquidity 
classification/display and
must be centralized in configuration.
LIQUIDITY STORAGE:
128 records per symbol/timeframe 
approved as current technical cap.
Lifecycle/priority eviction required.
STRONG REJECTION:
Directional wick >= 50% of range
AND
directional close location >= 70%
AND
candle body direction agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION:
Return into the originating delivery/POI 
zone.
A wick touching an invalidation price is 
not itself delivery
invalidation.
DELIVERY INVALIDATION:
Confirmed structural close beyond the 
protected delivery level,
subject to MinimumBreakDistance.
DELIVERY REPLACEMENT:
Confirmed same-direction structurally 
relevant BOS establishing a
new protected swing and breaking a 
genuinely new structural level.
DELIVERY ARCHIVAL:
Confirmed opposite-direction CHoCH.
Wick-only warnings do not archive 
delivery.
HTF POI SCORE:
HTF significance = 15/100.
Liquidity relationship = 5/100.
Use the formally defined 100-point POI 
score.
SWINGS:
Internal = 5 left / 5 right.
External = 15 left / 15 right.
No look-ahead.
BREAK:
MinimumBreakDistance =
max(2 × Point, 0.10 × ATR(14)).
DISPLACEMENT:
Range >= 1.20 ATR
BodyRatio >= 65%
Directional close strength >= 75%.
LIQUIDITY:
EQH/EQL tolerance =
max(3 × Point, 0.10 × ATR(14)).
Sweep requires breach followed by 
close back inside.
Confirmed breakout requires body close 
beyond the level and
MinimumBreakDistance.
FVG:
Minimum size =
max(3 × Point, 0.10 × ATR(14)).
DOL:
Minimum candidate score = 60.
Replace active DOL only if invalidated/
consumed, delivery changes,
or new candidate is structurally superior 
by >=15 score points.
ENTRY:
Primary execution TF = M5.
Confirmation uses closed candle.
Execution occurs at next available 
market price.
Signal expiry = 5 execution bars.
One signal = maximum one execution.
MINIMUM RR:
1.50R.
SESSIONS:
Not mandatory for Strategy 3 entry.
NEWS:
Not defined by either source PDF.
Keep separate until formally approved.
text
MNS STRATEGY 3
CLIENT DECISIONS — LOCKED
CLIENT-Q001 — CRT / IRL / ERL
DECISION:
OPTION A — OMIT AS SEPARATE 
CONCEPTS.
Use existing Swing, Liquidity, POI, OB, 
FVG and Objective/DOL
structures. No separate CRT/IRL/ERL 
strategy engines are required.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ OBJECTIVE
DECISION:
OPTION A — ACTIVE ONLY.
Indicator renders the currently active 
Delivery Structure and
current Objective/DOL only.
Historical state remains available 
through journals/analytics where
applicable, but no delivery/objective 
history-buffer refactor is
required for chart rendering.
CLIENT-Q003 — CORE HEURISTICS
DECISION:
OPTION B — FORMALLY LOCK / MODIFY 
SPECIFIC RULES.
SESSION:
Sessions do not determine trade 
eligibility by default.
SessionFilter = OFF.
Session hours may remain for liquidity 
classification/display and
must be centralized in configuration.
LIQUIDITY STORAGE:
128 records per symbol/timeframe 
approved as current technical cap.
Lifecycle/priority eviction required.
STRONG REJECTION:
Directional wick >= 50% of range
AND
directional close location >= 70%
AND
candle body direction agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION:
Return into the originating delivery/POI 
zone.
A wick touching an invalidation price is 
not itself delivery
invalidation.
DELIVERY INVALIDATION:
Confirmed structural close beyond the 
protected delivery level,
subject to MinimumBreakDistance.
DELIVERY REPLACEMENT:
Confirmed same-direction structurally 
relevant BOS establishing a
new protected swing and breaking a 
genuinely new structural level.
DELIVERY ARCHIVAL:
Confirmed opposite-direction CHoCH.
Wick-only warnings do not archive 
delivery.
HTF POI SCORE:
HTF significance = 15/100.
Liquidity relationship = 5/100.
Use the formally defined 100-point POI 
score.
SWINGS:
Internal = 5 left / 5 right.
External = 15 left / 15 right.
No look-ahead.
BREAK:
MinimumBreakDistance =
max(2 × Point, 0.10 × ATR(14)).
DISPLACEMENT:
Range >= 1.20 ATR
BodyRatio >= 65%
Directional close strength >= 75%.
LIQUIDITY:
EQH/EQL tolerance =
max(3 × Point, 0.10 × ATR(14)).
Sweep requires breach followed by 
close back inside.
Confirmed breakout requires body close 
beyond the level and
MinimumBreakDistance.
FVG:
Minimum size =
max(3 × Point, 0.10 × ATR(14)).
DOL:
Minimum candidate score = 60.
Replace active DOL only if invalidated/
consumed, delivery changes,
or new candidate is structurally superior 
by >=15 score points.
ENTRY:
Primary execution TF = M5.
Confirmation uses closed candle.
Execution occurs at next available 
market price.
Signal expiry = 5 execution bars.
One signal = maximum one execution.
MINIMUM RR:
1.50R.
SESSIONS:
Not mandatory for Strategy 3 entry.
NEWS:
Not defined by either source PDF.
Keep separate until formally approved.
text
MNS STRATEGY 3
CLIENT DECISIONS — LOCKED
CLIENT-Q001 — CRT / IRL / ERL
DECISION:
OPTION A — OMIT AS SEPARATE 
CONCEPTS.
Use existing Swing, Liquidity, POI, OB, 
FVG and Objective/DOL
structures. No separate CRT/IRL/ERL 
strategy engines are required.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ OBJECTIVE
DECISION:
OPTION A — ACTIVE ONLY.
Indicator renders the currently active 
Delivery Structure and
current Objective/DOL only.
Historical state remains available 
through journals/analytics where
applicable, but no delivery/objective 
history-buffer refactor is
required for chart rendering.
CLIENT-Q003 — CORE HEURISTICS
DECISION:
OPTION B — FORMALLY LOCK / MODIFY 
SPECIFIC RULES.
SESSION:
Sessions do not determine trade 
eligibility by default.
SessionFilter = OFF.
Session hours may remain for liquidity 
classification/display and
must be centralized in configuration.
LIQUIDITY STORAGE:
128 records per symbol/timeframe 
approved as current technical cap.
Lifecycle/priority eviction required.
STRONG REJECTION:
Directional wick >= 50% of range
AND
directional close location >= 70%
AND
candle body direction agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION:
Return into the originating delivery/POI 
zone.
A wick touching an invalidation price is 
not itself delivery
invalidation.
DELIVERY INVALIDATION:
Confirmed structural close beyond the 
protected delivery level,
subject to MinimumBreakDistance.
DELIVERY REPLACEMENT:
Confirmed same-direction structurally 
relevant BOS establishing a
new protected swing and breaking a 
genuinely new structural level.
DELIVERY ARCHIVAL:
Confirmed opposite-direction CHoCH.
Wick-only warnings do not archive 
delivery.
HTF POI SCORE:
HTF significance = 15/100.
Liquidity relationship = 5/100.
Use the formally defined 100-point POI 
score.
SWINGS:
Internal = 5 left / 5 right.
External = 15 left / 15 right.
No look-ahead.
BREAK:
MinimumBreakDistance =
max(2 × Point, 0.10 × ATR(14)).
DISPLACEMENT:
Range >= 1.20 ATR
BodyRatio >= 65%
Directional close strength >= 75%.
LIQUIDITY:
EQH/EQL tolerance =
max(3 × Point, 0.10 × ATR(14)).
Sweep requires breach followed by 
close back inside.
Confirmed breakout requires body close 
beyond the level and
MinimumBreakDistance.
FVG:
Minimum size =
max(3 × Point, 0.10 × ATR(14)).
DOL:
Minimum candidate score = 60.
Replace active DOL only if invalidated/
consumed, delivery changes,
or new candidate is structurally superior 
by >=15 score points.
ENTRY:
Primary execution TF = M5.
Confirmation uses closed candle.
Execution occurs at next available 
market price.
Signal expiry = 5 execution bars.
One signal = maximum one execution.
MINIMUM RR:
1.50R.
SESSIONS:
Not mandatory for Strategy 3 entry.
NEWS:
Not defined by either source PDF.
Keep separate until formally approved.
text
MNS STRATEGY 3
CLIENT DECISIONS — LOCKED
CLIENT-Q001 — CRT / IRL / ERL
DECISION:
OPTION A — OMIT AS SEPARATE 
CONCEPTS.
Use existing Swing, Liquidity, POI, OB, 
FVG and Objective/DOL
structures. No separate CRT/IRL/ERL 
strategy engines are required.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ OBJECTIVE
DECISION:
OPTION A — ACTIVE ONLY.
Indicator renders the currently active 
Delivery Structure and
current Objective/DOL only.
Historical state remains available 
through journals/analytics where
applicable, but no delivery/objective 
history-buffer refactor is
required for chart rendering.
CLIENT-Q003 — CORE HEURISTICS
DECISION:
OPTION B — FORMALLY LOCK / MODIFY 
SPECIFIC RULES.
SESSION:
Sessions do not determine trade 
eligibility by default.
SessionFilter = OFF.
Session hours may remain for liquidity 
classification/display and
must be centralized in configuration.
LIQUIDITY STORAGE:
128 records per symbol/timeframe 
approved as current technical cap.
Lifecycle/priority eviction required.
STRONG REJECTION:
Directional wick >= 50% of range
AND
directional close location >= 70%
AND
candle body direction agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION:
Return into the originating delivery/POI 
zone.
A wick touching an invalidation price is 
not itself delivery
invalidation.
DELIVERY INVALIDATION:
Confirmed structural close beyond the 
protected delivery level,
subject to MinimumBreakDistance.
DELIVERY REPLACEMENT:
Confirmed same-direction structurally 
relevant BOS establishing a
new protected swing and breaking a 
genuinely new structural level.
DELIVERY ARCHIVAL:
Confirmed opposite-direction CHoCH.
Wick-only warnings do not archive 
delivery.
HTF POI SCORE:
HTF significance = 15/100.
Liquidity relationship = 5/100.
Use the formally defined 100-point POI 
score.
SWINGS:
Internal = 5 left / 5 right.
External = 15 left / 15 right.
No look-ahead.
BREAK:
MinimumBreakDistance =
max(2 × Point, 0.10 × ATR(14)).
DISPLACEMENT:
Range >= 1.20 ATR
BodyRatio >= 65%
Directional close strength >= 75%.
LIQUIDITY:
EQH/EQL tolerance =
max(3 × Point, 0.10 × ATR(14)).
Sweep requires breach followed by 
close back inside.
Confirmed breakout requires body close 
beyond the level and
MinimumBreakDistance.
FVG:
Minimum size =
max(3 × Point, 0.10 × ATR(14)).
DOL:
Minimum candidate score = 60.
Replace active DOL only if invalidated/
consumed, delivery changes,
or new candidate is structurally superior 
by >=15 score points.
ENTRY:
Primary execution TF = M5.
Confirmation uses closed candle.
Execution occurs at next available 
market price.
Signal expiry = 5 execution bars.
One signal = maximum one execution.
MINIMUM RR:
1.50R.
SESSIONS:
Not mandatory for Strategy 3 entry.
NEWS:
Not defined by either source PDF.
Keep separate until formally approved.
39. Source-of-truth hierarchy for 
the developers
I would now formally tell the team to resolve 
conflicts in this order:
text
1. Explicit original strategy rules 
supplied by client
 ↓
2. This locked Client Decision 
Specification
 ↓
3. Existing Modules 001–012 
implementation
 ↓
4. Visual mockups
 ↓
5. Developer assumptions
A visual mockup must never override strategy 
logic.
A temporary implementation heuristic must 
never override an explicitly locked rule.
And where a source remains genuinely silent, the 
developer must ask rather than invent.
The new register itself requires precisely that 
discipline: it says unresolved assumptions 
should not be silently changed after 
implementation and that any new rule should be 
formally recorded. 
Development status after 
consolidation
The three client decision groups from the new 
register are now answered:
text
Q001 ✅ Locked
Q002 ✅ Locked
Q003 ✅ Locked
text
Q001 ✅ Locked
Q002 ✅ Locked
Q003 ✅ Locked
The TODO register identified those three client 
decisions as required before Stage 4/Stage 9, 
while the Stage 1 implementation can already 
proceed. 
So your developers now have a substantially 
cleaner basis for completing the indicator 
without having to guess at those unresolved 
points.