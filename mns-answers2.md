MNS Strategy 3 — Final Client 
Decisions
CLIENT-Q001 — CRT / IRL / ERL
Decision: Option A — OMIT as separate strategy 
concepts
Do not create independent CRT, IRL, or ERL 
engines.
The PDF states that CRT High/Low, CRT levels, 
IRL, and ERL are referenced visually but are not 
mathematically defined in the existing strategy/
core engines. 
Our strategy already has deterministic 
equivalents through:
text
Swing High / Swing Low
External Liquidity
Internal Liquidity
EQH / EQL
POIs
Order Blocks
FVGs
Premium / Discount
DOL / Objectives
Protected highs/lows
text
Swing High / Swing Low
External Liquidity
Internal Liquidity
EQH / EQL
POIs
Order Blocks
FVGs
Premium / Discount
DOL / Objectives
Protected highs/lows
Therefore, for the current production version:
text
CRT = DO NOT IMPLEMENT as a 
separate algorithm
IRL = DO NOT IMPLEMENT as a 
separate algorithm
ERL = DO NOT IMPLEMENT as a 
separate algorithm
If those labels appear in an earlier visual mock￾up, replace them with the authoritative MNS 
terminology.
For example:
text
Instead of "ERL High"
→ External Buy-Side Liquidity
Instead of "ERL Low"
→ External Sell-Side Liquidity
Instead of "IRL"
→ Internal Liquidity
Instead of "CRT High"
→ Confirmed structural / liquidity high
Developer instruction
Do not create:
cpp
CCRT_Engine
CIRL_Engine
CERL_Engine
Do not add new fields to CLiquidityEngine or 
CPOIEngine merely to support these labels.
Stage 4 should consume existing:
text
Swings
Liquidity Pools
POIs
FVGs
Order Blocks
DOL
Final response for Q001
text
CLIENT-Q001 = OPTION A
CRT / IRL / ERL will not exist as 
separate mathematical strategy
concepts in Strategy 3.
Existing Swing, Liquidity, POI, OB, FVG 
and DOL structures are the
authoritative representations.
No core-engine refactor is required for 
CRT/IRL/ERL.
text
CLIENT-Q001 = OPTION A
CRT / IRL / ERL will not exist as 
separate mathematical strategy
concepts in Strategy 3.
Existing Swing, Liquidity, POI, OB, FVG 
and DOL structures are the
authoritative representations.
No core-engine refactor is required for 
CRT/IRL/ERL.
───
CLIENT-Q002 — Historical Delivery 
Legs / Targets
Decision: Option A — ACTIVE ONLY
The PDF confirms that the current Delivery and 
Objective engines maintain a single active state 
and that adding historical rendering would 
require core history buffers/refactoring. 
For the live indicator, we do not need every old 
delivery leg cluttering the chart.
Display:
text
Current active delivery leg
Current active objective / DOL
Current invalidation/protected level
Current direction
Current delivery lifecycle
Do not render all old delivery paths.
Indicator behavior
Active delivery:
text
Origin 
─────────────────────►
Current delivery direction
Active DOL:
text
─────────────────────────
─── DOL
When delivery is replaced:
text
Old delivery
→ removed from active visual layer
New delivery
→ becomes visible
This does not mean historical information 
should be deleted from journals or analytics.
Separate:
text
STRATEGY STATE
→ active only
CHART RENDERING
→ active only
JOURNAL / ANALYTICS
→ retain historical events
text
STRATEGY STATE
→ active only
CHART RENDERING
→ active only
JOURNAL / ANALYTICS
→ retain historical events
That distinction is important.
Final response for Q002
text
CLIENT-Q002 = OPTION A
Indicator renders only:
- current active delivery leg
- current active target/DOL
Historical delivery legs and objectives 
do not need to remain
rendered on the chart.
Historical events may still be retained in 
journals/analytics.
Do not refactor DeliveryStructureEngine 
or ObjectiveEngine merely
to support historical chart drawings.
text
CLIENT-Q002 = OPTION A
Indicator renders only:
- current active delivery leg
- current active target/DOL
Historical delivery legs and objectives 
do not need to remain
rendered on the chart.
Historical events may still be retained in 
journals/analytics.
Do not refactor DeliveryStructureEngine 
or ObjectiveEngine merely
to support historical chart drawings.
This also avoids the historical-storage refactor 
that the TODO register says should only happen 
if historical rendering is explicitly approved. 
───
CLIENT-Q003 — Core Engine 
Heuristics
This one should be Option B: modify/lock 
specific rules.
The PDF explicitly lists seven temporary 
assumptions that are not yet final: session 
hours, liquidity buffer, strong rejection, delivery 
mitigation, delivery replacement, delivery 
archival, and HTF POI weights. 
Here are the exact final decisions.
───
1. SESSION HOURS
Decision
Sessions are not mandatory strategy filters.
The MNS strategy works from:
text
Market Structure
Order Flow
Delivery
Liquidity
DOL
POI
Displacement
Confirmation
Risk
text
Market Structure
Order Flow
Delivery
Liquidity
DOL
POI
Displacement
Confirmation
Risk
It must not require:
text
Tokyo
London
New York
for a setup to be valid.
Therefore the currently implemented hours:
text
Tokyo 00:00–08:00 GMT
London 08:00–16:00 GMT
New York 13:00–21:00 GMT
must not become hard-coded trade-permission 
rules.
The PDF itself marks these hours as an 
assumption awaiting approval. 
Final implementation
Keep session detection only for:
text
Session liquidity
Session high
Session low
Analytics
Optional display
Optional future filtering
Default:
cpp
UseSessionFilter = false;
If the current utility needs session boundaries 
for identifying session highs/lows, the existing 
boundaries may temporarily remain:
text
Tokyo 00:00–08:00 GMT
London 08:00–16:00 GMT
New York 13:00–21:00 GMT
but their function is:
text
classify market sessions
not:
text
determine whether the EA may trade
Important distinction
text
SESSION HIGH/LOW DETECTION = YES
MANDATORY SESSION TRADING FILTER 
= NO
text
SESSION HIGH/LOW DETECTION = YES
MANDATORY SESSION TRADING FILTER 
= NO
Developer implementation
Centralize them in Stage 6 as configuration, 
consistent with the document's 
recommendation to centralize session 
parameters rather than duplicate them. 
Suggested config:
cpp
struct SMNSSessionConfig
{
 bool useAsEntryFilter;
 int tokyoStartHour;
 int tokyoEndHour;
 int londonStartHour;
 int londonEndHour;
 int newYorkStartHour;
 int newYorkEndHour;
};
cpp
struct SMNSSessionConfig
{
 bool useAsEntryFilter;
 int tokyoStartHour;
 int tokyoEndHour;
 int londonStartHour;
 int londonEndHour;
 int newYorkStartHour;
 int newYorkEndHour;
};
Default:
cpp
useAsEntryFilter = false;
───
2. LIQUIDITY POOL BUFFER
Current implementation:
text
128 elements
The PDF says this was simply a memory￾management choice and needs validation. 
Decision
128 is acceptable as the maximum active 
liquidity pool store per symbol/timeframe, 
provided eviction is deterministic.
Do not simply overwrite element zero whenever 
the array fills.
Required eviction priority
When capacity = 128:
First remove:
text
1. ARCHIVED
2. INVALIDATED
3. CONSUMED
4. SWEPT oldest
5. BROKEN oldest
Never automatically remove:
text
Active HTF liquidity
Current DOL
Current external swing liquidity
Fresh EQH/EQL involved in active 
delivery
If all 128 are still active
Evict based on lowest priority score:
text
Lowest liquidity score
+
oldest creation time
+
furthest from current relevant delivery
Developer rule
text
MAX_LIQUIDITY_POOLS = 128
is approved for current production.
But this is:
text
memory capacity
not a trading rule.
It can be increased later after profiling without 
changing strategy behavior.
───
3. STRONG REJECTION
Current implementation:
text
Wick >= 50% of candle range
The PDF correctly flags this as insufficiently 
defined. 
A 50% wick by itself is too weak because it 
ignores where the candle closes and whether 
the rejection is actually directional.
Final bullish rejection
For candle i:
text
Range = High - Low
LowerWick =
min(Open, Close) - Low
Body =
abs(Close - Open)
LowerWickRatio =
LowerWick / Range
BullishCloseLocation =
(Close - Low) / Range
text
Range = High - Low
LowerWick =
min(Open, Close) - Low
Body =
abs(Close - Open)
LowerWickRatio =
LowerWick / Range
BullishCloseLocation =
(Close - Low) / Range
Strong bullish rejection requires:
text
Range > 0
AND
LowerWickRatio >= 0.50
AND
BullishCloseLocation >= 0.70
AND
Close > Open
Preferably it occurs:
text
inside / immediately after touching a 
bullish POI
OR
after sweeping sell-side liquidity
Final bearish rejection
text
UpperWick =
High - max(Open, Close)
UpperWickRatio =
UpperWick / Range
BearishCloseLocation =
(High - Close) / Range
Require:
text
UpperWickRatio >= 0.50
AND
BearishCloseLocation >= 0.70
AND
Close < Open
ATR sanity requirement
Reject extremely tiny candles as confirmation.
Require:
text
Range >= 0.50 × ATR(14)
Therefore complete strong bullish rejection:
text
Lower wick >= 50%
Close in upper 30%
Bullish body
Range >= 0.50 ATR
Correct POI/liquidity context
Bearish is inverse.
Important
Strong rejection is:
text
confirmation evidence
not:
text
automatic entry
It must still participate in the complete setup 
sequence.
───
4. DELIVERY MITIGATION
Current implementation:
text
Wick touches invalidation price
Decision: REPLACE this rule
Do not equate mitigation with touching the 
invalidation level.
Those are different concepts.
Mitigation definition
A delivery is mitigated when price returns into 
the origin POI / originating delivery zone after 
the expansion leg.
For bullish delivery:
text
Bullish expansion
→ pullback
→ price revisits bullish delivery origin / 
associated bullish POI
For bearish:
text
Bearish expansion
→ pullback
→ price revisits bearish delivery origin / 
associated bearish POI
text
Bearish expansion
→ pullback
→ price revisits bearish delivery origin / 
associated bearish POI
Trigger
A wick entering the active origin POI is enough 
to mark:
text
MITIGATION_STARTED
But it does not invalidate delivery.
Therefore:
text
wick enters origin zone
→ mitigated/touched
body closes through protected 
invalidation level
→ invalidated
Exact separation
For bullish delivery:
text
Low <= POI.upper
AND
High >= POI.lower
→ mitigation interaction
Bullish delivery remains valid unless:
text
Close <
ProtectedLow - MinimumBreakDistance
For bearish:
text
zone touched
→ mitigation
Close >
ProtectedHigh + MinimumBreakDistance
→ invalidation
text
zone touched
→ mitigation
Close >
ProtectedHigh + MinimumBreakDistance
→ invalidation
This is a very important correction.
Mitigation ≠ invalidation.
───
5. DELIVERY REPLACEMENT
Current assumption:
text
Same-direction BOS
Decision: APPROVE WITH CONDITIONS
A new same-direction BOS may replace the 
current delivery only when it establishes a new 
valid delivery structure.
For bullish delivery:
text
Current delivery = Bullish
New bullish BOS confirmed
AND
BOS originates from the active delivery 
sequence
AND
new protected low is established
AND
new delivery origin is newer than current 
origin
AND
direction remains bullish
text
Current delivery = Bullish
New bullish BOS confirmed
AND
BOS originates from the active delivery 
sequence
AND
new protected low is established
AND
new delivery origin is newer than current 
origin
AND
direction remains bullish
Then:
text
Old Delivery
→ REPLACED
→ ARCHIVED
New Delivery
→ ACTIVE
Do not replace delivery for every minor internal 
BOS.
Require:
text
BOS classification = structurally relevant 
continuation
Prefer external structure or the configured 
delivery structure level.
Prevent constant replacement
A duplicate BOS breaking the same structural 
level must not create a new delivery.
Require:
text
newBrokenSwingId != 
previousBrokenSwingId
or equivalent authoritative identity.
───
6. DELIVERY ARCHIVAL
Current assumption:
text
Opposite-direction CHoCH
Decision: APPROVE, but only confirmed CHoCH
The PDF marks this as a temporary assumption. 
The correct rule is:
text
Wick warning CHoCH
→ DO NOT ARCHIVE
Confirmed body-close CHoCH
→ invalidate active delivery
→ archive it
Bullish delivery:
text
Confirmed bearish CHoCH
breaking protected bullish low
+
MinimumBreakDistance
text
Confirmed bearish CHoCH
breaking protected bullish low
+
MinimumBreakDistance
causes:
text
ACTIVE
→ INVALIDATED
→ ARCHIVED
Bearish inverse.
This matches our broader MNS rule:
text
Wick = warning
Body close = confirmation
Important nuance
The market may enter:
text
TRANSITION
after CHoCH.
Do not automatically establish the opposite 
delivery until the opposite direction itself has 
sufficient confirmation.
Therefore:
text
Bullish Delivery
→ bearish CHoCH
→ Bullish Delivery archived
Market State
→ Transition Bearish
New Bearish Delivery
→ only after valid bearish structure/
delivery conditions
───
7. HTF POI WEIGHTS
Current hardcoded values:
text
Liquidity strength = 5
HTF significance = 15
The PDF asks whether these should be approved 
or replaced. 
Decision
Keep these values, but formally define the entire 
POI score so the numbers have context.
Use a maximum POI confidence score of:
text
100
POI scoring
text
Structural origin / BOS relationship 
20
Freshness 15
Displacement strength 15
HTF significance 15
DOL alignment 10
MTF narrative alignment 10
Liquidity strength 5
Premium / Discount location 5
POI confluence 5
-----------------------------------------------
TOTAL 100
Therefore:
text
Liquidity Strength = 5
HTF Significance = 15
are approved.
Scoring interpretation
text
90–100 Elite POI
80–89 Strong POI
70–79 Valid POI
60–69 Weak POI
<60 Reject for standalone entry
HTF significance component
Example:
text
W1 / D1 POI = 15/15
H4 POI = 13/15
H1 POI = 10/15
M15 POI = 7/15
M5 POI = 4/15
M1 POI = 2/15
text
W1 / D1 POI = 15/15
H4 POI = 13/15
H1 POI = 10/15
M15 POI = 7/15
M5 POI = 4/15
M1 POI = 2/15
The score should reflect the POI source 
timeframe, not current chart timeframe.
Liquidity component
text
Strong HTF liquidity relationship = 5/5
External liquidity = 4/5
EQH/EQL = 3/5
Session liquidity = 2/5
Internal liquidity = 1/5
No meaningful liquidity = 0/5
───
Final CLIENT-Q003 Response
Use this exact decision:
text
CLIENT-Q003 = OPTION B — MODIFY / 
FORMALLY LOCK SPECIFIC RULES
Final configuration:
text
SESSION HOURS
-------------
Session identification may retain:
Tokyo 00:00–08:00 GMT
London 08:00–16:00 GMT
New York 13:00–21:00 GMT
BUT:
Sessions are NOT mandatory trade 
filters.
SessionFilter default = OFF.
LIQUIDITY BUFFER
----------------
Maximum stored liquidity pools = 128 
per symbol/timeframe.
Eviction:
Archived → Invalidated → Consumed →
Swept → Broken →
lowest-priority oldest pool.
Do not evict active DOL or critical active 
HTF liquidity.
STRONG REJECTION
----------------
Directional wick >= 50% of candle range
AND
directional close location >= 70%
AND
directional candle body agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION
-------------------
Do NOT use wick touch of invalidation 
price.
Mitigation = price re-enters originating 
POI/delivery zone.
Wick interaction may mark mitigation/
touch.
Only confirmed structural close beyond 
protected level invalidates.
DELIVERY REPLACEMENT
--------------------
Same-direction BOS is approved ONLY 
when:
- BOS is confirmed by body close
- it represents new relevant structure
- it establishes a new protected swing
- it belongs to current delivery sequence
- it is not duplicate break of same level.
DELIVERY ARCHIVAL
-----------------
Confirmed opposite-direction CHoCH 
archives delivery.
Wick-only CHoCH warning does NOT 
archive.
Archive sequence:
ACTIVE → INVALIDATED → ARCHIVED.
HTF POI WEIGHTS
---------------
Liquidity strength = 5 points.
HTF significance = 15 points.
Approved as part of a 100-point POI 
scoring model.
text
SESSION HOURS
-------------
Session identification may retain:
Tokyo 00:00–08:00 GMT
London 08:00–16:00 GMT
New York 13:00–21:00 GMT
BUT:
Sessions are NOT mandatory trade 
filters.
SessionFilter default = OFF.
LIQUIDITY BUFFER
----------------
Maximum stored liquidity pools = 128 
per symbol/timeframe.
Eviction:
Archived → Invalidated → Consumed →
Swept → Broken →
lowest-priority oldest pool.
Do not evict active DOL or critical active 
HTF liquidity.
STRONG REJECTION
----------------
Directional wick >= 50% of candle range
AND
directional close location >= 70%
AND
directional candle body agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION
-------------------
Do NOT use wick touch of invalidation 
price.
Mitigation = price re-enters originating 
POI/delivery zone.
Wick interaction may mark mitigation/
touch.
Only confirmed structural close beyond 
protected level invalidates.
DELIVERY REPLACEMENT
--------------------
Same-direction BOS is approved ONLY 
when:
- BOS is confirmed by body close
- it represents new relevant structure
- it establishes a new protected swing
- it belongs to current delivery sequence
- it is not duplicate break of same level.
DELIVERY ARCHIVAL
-----------------
Confirmed opposite-direction CHoCH 
archives delivery.
Wick-only CHoCH warning does NOT 
archive.
Archive sequence:
ACTIVE → INVALIDATED → ARCHIVED.
HTF POI WEIGHTS
---------------
Liquidity strength = 5 points.
HTF significance = 15 points.
Approved as part of a 100-point POI 
scoring model.
text
SESSION HOURS
-------------
Session identification may retain:
Tokyo 00:00–08:00 GMT
London 08:00–16:00 GMT
New York 13:00–21:00 GMT
BUT:
Sessions are NOT mandatory trade 
filters.
SessionFilter default = OFF.
LIQUIDITY BUFFER
----------------
Maximum stored liquidity pools = 128 
per symbol/timeframe.
Eviction:
Archived → Invalidated → Consumed →
Swept → Broken →
lowest-priority oldest pool.
Do not evict active DOL or critical active 
HTF liquidity.
STRONG REJECTION
----------------
Directional wick >= 50% of candle range
AND
directional close location >= 70%
AND
directional candle body agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION
-------------------
Do NOT use wick touch of invalidation 
price.
Mitigation = price re-enters originating 
POI/delivery zone.
Wick interaction may mark mitigation/
touch.
Only confirmed structural close beyond 
protected level invalidates.
DELIVERY REPLACEMENT
--------------------
Same-direction BOS is approved ONLY 
when:
- BOS is confirmed by body close
- it represents new relevant structure
- it establishes a new protected swing
- it belongs to current delivery sequence
- it is not duplicate break of same level.
DELIVERY ARCHIVAL
-----------------
Confirmed opposite-direction CHoCH 
archives delivery.
Wick-only CHoCH warning does NOT 
archive.
Archive sequence:
ACTIVE → INVALIDATED → ARCHIVED.
HTF POI WEIGHTS
---------------
Liquidity strength = 5 points.
HTF significance = 15 points.
Approved as part of a 100-point POI 
scoring model.
text
SESSION HOURS
-------------
Session identification may retain:
Tokyo 00:00–08:00 GMT
London 08:00–16:00 GMT
New York 13:00–21:00 GMT
BUT:
Sessions are NOT mandatory trade 
filters.
SessionFilter default = OFF.
LIQUIDITY BUFFER
----------------
Maximum stored liquidity pools = 128 
per symbol/timeframe.
Eviction:
Archived → Invalidated → Consumed →
Swept → Broken →
lowest-priority oldest pool.
Do not evict active DOL or critical active 
HTF liquidity.
STRONG REJECTION
----------------
Directional wick >= 50% of candle range
AND
directional close location >= 70%
AND
directional candle body agrees
AND
range >= 0.50 ATR(14)
AND
valid POI/liquidity context.
DELIVERY MITIGATION
-------------------
Do NOT use wick touch of invalidation 
price.
Mitigation = price re-enters originating 
POI/delivery zone.
Wick interaction may mark mitigation/
touch.
Only confirmed structural close beyond 
protected level invalidates.
DELIVERY REPLACEMENT
--------------------
Same-direction BOS is approved ONLY 
when:
- BOS is confirmed by body close
- it represents new relevant structure
- it establishes a new protected swing
- it belongs to current delivery sequence
- it is not duplicate break of same level.
DELIVERY ARCHIVAL
-----------------
Confirmed opposite-direction CHoCH 
archives delivery.
Wick-only CHoCH warning does NOT 
archive.
Archive sequence:
ACTIVE → INVALIDATED → ARCHIVED.
HTF POI WEIGHTS
---------------
Liquidity strength = 5 points.
HTF significance = 15 points.
Approved as part of a 100-point POI 
scoring model.
Full Client Response Sheet
Your developer can literally put this into the 
handoff register:
text
CLIENT-Q001 — CRT / IRL / ERL
RESPONSE:
OPTION A — OMIT.
CRT, IRL and ERL are not separate 
Strategy 3 mathematical
constructs. Use the existing Swing, 
Liquidity, POI, OB, FVG and
DOL structures. Do not add independent 
CRT/IRL/ERL core logic.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ TARGET
RESPONSE:
OPTION A — ACTIVE STATE ONLY.
Render the current active delivery leg 
and current active
objective/DOL only. Historical delivery/
objective events may be
retained in journals and analytics but do 
not require historical
chart rendering or core history-buffer 
refactoring.
CLIENT-Q003 — CORE HEURISTICS
RESPONSE:
OPTION B — MODIFY / LOCK SPECIFIC 
RULES.
1. Session identification:
 Tokyo 00–08 GMT
 London 08–16 GMT
 New York 13–21 GMT
 Sessions are informational/liquidity 
classification only.
 Mandatory session entry filter = OFF 
by default.
2. Liquidity capacity:
 128 pools per symbol/timeframe.
 Deterministic lifecycle/priority eviction 
required.
3. Strong rejection:
 Wick ratio >= 50%;
 directional close >= 70%;
 body agrees with rejection;
 candle range >= 0.50 ATR(14);
 POI/liquidity context required.
4. Delivery mitigation:
 Mitigation = return into origin POI/
delivery zone.
 Wick touching invalidation price alone 
does not invalidate.
5. Delivery replacement:
 New confirmed same-direction 
structurally relevant BOS that
 establishes a new protected swing.
6. Delivery archival:
 Confirmed opposite-direction body￾close CHoCH.
 Wick warning alone does not archive.
7. HTF POI weighting:
 Liquidity strength = 5.
 HTF significance = 15.
 Both form part of the approved 100-
point POI scoring model.
text
CLIENT-Q001 — CRT / IRL / ERL
RESPONSE:
OPTION A — OMIT.
CRT, IRL and ERL are not separate 
Strategy 3 mathematical
constructs. Use the existing Swing, 
Liquidity, POI, OB, FVG and
DOL structures. Do not add independent 
CRT/IRL/ERL core logic.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ TARGET
RESPONSE:
OPTION A — ACTIVE STATE ONLY.
Render the current active delivery leg 
and current active
objective/DOL only. Historical delivery/
objective events may be
retained in journals and analytics but do 
not require historical
chart rendering or core history-buffer 
refactoring.
CLIENT-Q003 — CORE HEURISTICS
RESPONSE:
OPTION B — MODIFY / LOCK SPECIFIC 
RULES.
1. Session identification:
 Tokyo 00–08 GMT
 London 08–16 GMT
 New York 13–21 GMT
 Sessions are informational/liquidity 
classification only.
 Mandatory session entry filter = OFF 
by default.
2. Liquidity capacity:
 128 pools per symbol/timeframe.
 Deterministic lifecycle/priority eviction 
required.
3. Strong rejection:
 Wick ratio >= 50%;
 directional close >= 70%;
 body agrees with rejection;
 candle range >= 0.50 ATR(14);
 POI/liquidity context required.
4. Delivery mitigation:
 Mitigation = return into origin POI/
delivery zone.
 Wick touching invalidation price alone 
does not invalidate.
5. Delivery replacement:
 New confirmed same-direction 
structurally relevant BOS that
 establishes a new protected swing.
6. Delivery archival:
 Confirmed opposite-direction body￾close CHoCH.
 Wick warning alone does not archive.
7. HTF POI weighting:
 Liquidity strength = 5.
 HTF significance = 15.
 Both form part of the approved 100-
point POI scoring model.
text
CLIENT-Q001 — CRT / IRL / ERL
RESPONSE:
OPTION A — OMIT.
CRT, IRL and ERL are not separate 
Strategy 3 mathematical
constructs. Use the existing Swing, 
Liquidity, POI, OB, FVG and
DOL structures. Do not add independent 
CRT/IRL/ERL core logic.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ TARGET
RESPONSE:
OPTION A — ACTIVE STATE ONLY.
Render the current active delivery leg 
and current active
objective/DOL only. Historical delivery/
objective events may be
retained in journals and analytics but do 
not require historical
chart rendering or core history-buffer 
refactoring.
CLIENT-Q003 — CORE HEURISTICS
RESPONSE:
OPTION B — MODIFY / LOCK SPECIFIC 
RULES.
1. Session identification:
 Tokyo 00–08 GMT
 London 08–16 GMT
 New York 13–21 GMT
 Sessions are informational/liquidity 
classification only.
 Mandatory session entry filter = OFF 
by default.
2. Liquidity capacity:
 128 pools per symbol/timeframe.
 Deterministic lifecycle/priority eviction 
required.
3. Strong rejection:
 Wick ratio >= 50%;
 directional close >= 70%;
 body agrees with rejection;
 candle range >= 0.50 ATR(14);
 POI/liquidity context required.
4. Delivery mitigation:
 Mitigation = return into origin POI/
delivery zone.
 Wick touching invalidation price alone 
does not invalidate.
5. Delivery replacement:
 New confirmed same-direction 
structurally relevant BOS that
 establishes a new protected swing.
6. Delivery archival:
 Confirmed opposite-direction body￾close CHoCH.
 Wick warning alone does not archive.
7. HTF POI weighting:
 Liquidity strength = 5.
 HTF significance = 15.
 Both form part of the approved 100-
point POI scoring model.
text
CLIENT-Q001 — CRT / IRL / ERL
RESPONSE:
OPTION A — OMIT.
CRT, IRL and ERL are not separate 
Strategy 3 mathematical
constructs. Use the existing Swing, 
Liquidity, POI, OB, FVG and
DOL structures. Do not add independent 
CRT/IRL/ERL core logic.
CLIENT-Q002 — HISTORICAL DELIVERY 
/ TARGET
RESPONSE:
OPTION A — ACTIVE STATE ONLY.
Render the current active delivery leg 
and current active
objective/DOL only. Historical delivery/
objective events may be
retained in journals and analytics but do 
not require historical
chart rendering or core history-buffer 
refactoring.
CLIENT-Q003 — CORE HEURISTICS
RESPONSE:
OPTION B — MODIFY / LOCK SPECIFIC 
RULES.
1. Session identification:
 Tokyo 00–08 GMT
 London 08–16 GMT
 New York 13–21 GMT
 Sessions are informational/liquidity 
classification only.
 Mandatory session entry filter = OFF 
by default.
2. Liquidity capacity:
 128 pools per symbol/timeframe.
 Deterministic lifecycle/priority eviction 
required.
3. Strong rejection:
 Wick ratio >= 50%;
 directional close >= 70%;
 body agrees with rejection;
 candle range >= 0.50 ATR(14);
 POI/liquidity context required.
4. Delivery mitigation:
 Mitigation = return into origin POI/
delivery zone.
 Wick touching invalidation price alone 
does not invalidate.
5. Delivery replacement:
 New confirmed same-direction 
structurally relevant BOS that
 establishes a new protected swing.
6. Delivery archival:
 Confirmed opposite-direction body￾close CHoCH.
 Wick warning alone does not archive.
7. HTF POI weighting:
 Liquidity strength = 5.
 HTF significance = 15.
 Both form part of the approved 100-
point POI scoring model.
What the developer should NOT 
change yet
The handoff explicitly says Stage 1 must remain 
narrow: lifecycle coordination, rate 
synchronization, engine coordination, 
initialization and deinitialization—not rendering 
or strategy redesign. 
So even though we have now answered Q001–
Q003, during Stage 1 your developer should still 
obey the document:
text
DO NOT modify Modules 001–012 
during Stage 1
DO NOT add rendering during Stage 1
DO NOT modify MNSConfig during 
Stage 1
DO NOT add trading logic to the indicator
Those are explicitly listed as forbidden Stage 1 
actions. 
The proper sequence is:
text
NOW:
Stage 1 shell
THEN:
Stage 2 wiring
Stage 3 renderers
Stage 4 advanced zones
Stage 5 dashboard
Stage 6 configuration
...
Stage 9 validation
text
NOW:
Stage 1 shell
THEN:
Stage 2 wiring
Stage 3 renderers
Stage 4 advanced zones
Stage 5 dashboard
Stage 6 configuration
...
Stage 9 validation
The dependency map specifically identifies 
Q001/Q002 as affecting Stage 4 and Q003 as 
critical for Stage 9. 
One additional requirement I 
would give the developer
Add a formal document/version constant to the 
implementation, for example:
cpp
#define 
MNS_STRATEGY_SPEC_VERSION 
"S3-2026-08-11"
And record:
text
CRT / IRL / ERL = omitted
Historical Delivery Rendering = active 
only
Core Heuristics = locked to Client-Q003 
response
That way nobody later changes one of these 
rules and forgets which specification the EA/
indicator was compiled against.
With these answers, TODO-001, TODO-002 and 
TODO-003 now have client decisions, so the 
strategic questions in this register are resolved. 
The developer can proceed with Stage 1 
immediately and use these decisions when the 
affected later stages are reached. 