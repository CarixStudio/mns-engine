A computer cannot "see" charts. It only understands numbers and  rules. So every concept must become deterministic.  
─── 
MNS ENGINE V1.0 
Market Structure Specification 
Principle 1 — Never Repaint 
Once a swing is confirmed, it can never move. 
No repainting. No changing history. 
─── 
1. Swing Detection 
A swing is only confirmed after the market proves it. 
Swing High 
A Swing High is confirmed when: 
Candle A has the highest High. 
At least 2 candles close after Candle A. 
Neither of those two candles makes a higher High.
Example: 
text 
Candle 1 
High = 1.2040 
Candle 2 
High = 1.2058 ← Candidate Swing High 
Candle 3 
High = 1.2052 
Candle 4 
High = 1.2048 
Swing High confirmed. 
─── 
Swing Low 
Same rule.
Lowest Low. 
Two candles afterwards. 
No lower Low. 
Confirmed. 
─── 
Why two candles? 
Because: 
One candle is too noisy. 
Three candles introduce too much delay. Two candles balance speed and reliability. 
─── 
2. Internal Swing 
Internal swings use exactly the same logic. The only difference is sensitivity. 
Main Swing 
Uses: 
Minimum distance 
text 
15 candles
Internal Swing 
Uses: 
text 
5 candles 
Therefore, 
The engine maintains: 
External Swing Structure Internal Swing Structure 
simultaneously. 
─── 
3. Higher High 
Rule 
Current confirmed Swing High > Previous confirmed Swing High ↓ 
Higher High. 
Otherwise 
↓ 
Lower High.
─── 
4. Higher Low 
Rule 
Current confirmed Swing Low > Previous confirmed Swing Low ↓ 
Higher Low. 
Otherwise 
↓ 
Lower Low. 
─── 
5. BOS 
This must follow the PDF exactly. Bullish BOS 
Requirements: 
Previous Swing High exists. Candle body closes above it. 
Not the wick. 
The candle body.
Only then 
Bullish BOS. 
─── 
Bearish BOS 
Previous Swing Low. 
Body closes below. 
Confirmed. 
─── 
Never use wick breaks for BOS. ─── 
6. CHoCH 
Exactly opposite. 
Only wick. 
If wick breaks 
↓ 
CHoCH. 
If candle closes 
↓ 
BOS. 
Simple.
─── 
7. Strong High 
Bullish Market 
Strong High 
means 
Price failed to break it. 
Weak High 
means 
Price broke it. 
─── 
Bearish Market 
Strong Low 
means 
Price failed to break it. 
Weak Low 
means 
Price broke it. 
This classification updates automatically. ─── 
8. Trend
Trend must never rely on moving averages. Only structure. 
Bullish 
Requirements 
Latest sequence 
text 
HH 
↓ 
HL 
↓ 
HH 
↓ 
HL 
Minimum: 
Two HH 
Two HL
Then 
Bullish. 
─── 
Bearish 
Latest sequence text 
LL 
↓ 
LH 
↓ 
LL 
↓ 
LH 
Minimum:
Two LL 
Two LH 
Then 
Bearish. 
Anything else 
↓ 
Transition. 
─── 
9. Market Phase 
The engine should expose text 
TRENDING 
PULLBACK 
TRANSITION 
RANGING 
Trending 
HH HL repeating.
─── 
Pullback 
Opposite internal structure. Example 
Daily 
Bullish 
15M 
Bearish 
↓ 
Pullback. 
─── 
Transition 
Recent CHoCH. 
No BOS yet. 
─── 
Range 
No HH. 
No LL. 
No clear trend. 
───
10. Swing Strength Score 
Every swing gets a score. Start 
100 points. 
Lose points for: 
Weak BOS. 
Immediate rejection. Small impulse. 
Gain points for: 
Large displacement. Large imbalance. 
Protected swing. 
Reaction multiple times. Finally 
text 
90–100 
Very Strong 
70–89 
Strong
50–69 
Average 
0–49 
Weak 
Future modules will use this score. ─── 
11. BOS Strength 
Not all BOS are equal. 
Measure 
Impulse size. 
If BOS candle 
ATR × 2 
↓ 
Strong BOS. 
ATR × 1 
↓ 
Average BOS. 
ATR below average 
↓
Weak BOS. 
This is useful for filtering low-quality moves. ─── 
12. Market Structure Object 
Every candle update should return: text 
Trend 
Bullish 
External Structure 
HH HL HH 
Internal Structure 
LL LH 
Market Phase
Pullback 
Current Swing High 1.20845 
Current Swing Low 1.20350 
Latest BOS 
Bullish 
Latest CHoCH 
None 
Structure Strength 92% 
Confidence 
95%
─── 
13. Why this approach? 
This design is: 
Deterministic: the same data always produces the same  result. 
Non-repainting: confirmed swings never change. 
Modular: later modules (Order Flow, DOL, Delivery Structure,  EA) can use the same outputs. 
Testable: each rule can be verified independently. 
Market Structure Confidence Score 
Market Structure Confidence Score (0–100%). This score would  combine factors such as swing quality, BOS strength,  displacement, and trend consistency. Later modules could ignore  setups below a configurable threshold (for example, 80%), helping  to filter out lower-quality trades and improving the overall  robustness of the system.
Let’s start with the actual Phase 1 MQL5 implementation,  The first deliverable should be the shared definitions used by every  other module. 
Phase 1A — Core Data Models 
Create a folder inside MetaTrader: 
text 
MQL5 
└── Include 
 └── MNS 
 ├── MNSTypes.mqh 
 ├── SwingDetector.mqh 
 ├── StructureEngine.mqh 
 └── MarketStructureEngine.mqh 
Start with the first file. 
File 1: MNSTypes.mqh 
cpp 
// 
+---------------------------------------------------------------
---+ 
//| MNSTypes.mqh  
 | 
//| Shared definitions for the MNS  Market Structure Engine | // 
+--------------------------------------------------------------- ---+ 
#ifndef __MNS_TYPES_MQH__ #define __MNS_TYPES_MQH__ 
//--------------------------------------------------------- // Market direction 
//--------------------------------------------------------- enum ENUM_MNS_TREND 
{ 
 MNS_TREND_UNKNOWN = 0,  MNS_TREND_BULLISH, 
 MNS_TREND_BEARISH, 
 MNS_TREND_TRANSITION, 
 MNS_TREND_RANGING 
}; 
//--------------------------------------------------------- // Market phase
//--------------------------------------------------------- enum ENUM_MNS_PHASE 
{ 
 MNS_PHASE_UNKNOWN = 0,  MNS_PHASE_TRENDING, 
 MNS_PHASE_PULLBACK, 
 MNS_PHASE_TRANSITION,  MNS_PHASE_RANGING 
}; 
//--------------------------------------------------------- // Swing type 
//--------------------------------------------------------- enum ENUM_MNS_SWING_TYPE { 
 MNS_SWING_NONE = 0, 
 MNS_SWING_HIGH, 
 MNS_SWING_LOW 
}; 
//--------------------------------------------------------- // Swing classification 
//--------------------------------------------------------- enum ENUM_MNS_STRUCTURE_TYPE {
 MNS_STRUCTURE_NONE = 0,  MNS_STRUCTURE_HH, 
 MNS_STRUCTURE_HL, 
 MNS_STRUCTURE_LH, 
 MNS_STRUCTURE_LL, 
 MNS_STRUCTURE_EQUAL_HIGH,  MNS_STRUCTURE_EQUAL_LOW }; 
//--------------------------------------------------------- // Structure-break type 
//--------------------------------------------------------- enum ENUM_MNS_BREAK_TYPE { 
 MNS_BREAK_NONE = 0, 
 MNS_BREAK_BOS, 
 MNS_BREAK_INTERNAL_BOS,  MNS_BREAK_CHOCH 
}; 
//--------------------------------------------------------- // Swing hierarchy 
//--------------------------------------------------------- enum ENUM_MNS_SWING_LEVEL {
 MNS_SWING_INTERNAL = 0,  MNS_SWING_EXTERNAL 
}; 
//--------------------------------------------------------- // Strength classification 
//--------------------------------------------------------- enum ENUM_MNS_STRENGTH { 
 MNS_STRENGTH_UNKNOWN = 0,  MNS_STRENGTH_WEAK, 
 MNS_STRENGTH_AVERAGE,  MNS_STRENGTH_STRONG,  MNS_STRENGTH_VERY_STRONG }; 
//--------------------------------------------------------- // Swing-point model 
//--------------------------------------------------------- struct MNS_SwingPoint 
{ 
 long id; 
 datetime time; 
 int bar_index; 
 double price;
 ENUM_MNS_SWING_TYPE  
swing_type; 
 ENUM_MNS_SWING_LEVEL  swing_level; 
 ENUM_MNS_STRUCTURE_TYPE  structure_type; 
 ENUM_MNS_STRENGTH strength; 
 bool confirmed; 
 bool broken; 
 bool protected_swing;  bool active; 
 double strength_score; 
 void Reset() 
 { 
 id = -1; 
 time = 0; 
 bar_index = -1; 
 price = 0.0; 
 swing_type = MNS_SWING_NONE;  swing_level = 
MNS_SWING_INTERNAL; 
 structure_type =  
MNS_STRUCTURE_NONE; 
 strength =  
MNS_STRENGTH_UNKNOWN; 
 confirmed = false; 
 broken = false; 
 protected_swing = false; 
 active = false; 
 strength_score = 0.0; 
 } 
}; 
//--------------------------------------------------------- // Structure-break model 
//--------------------------------------------------------- struct MNS_StructureBreak 
{ 
 long id; 
 datetime time; 
 int bar_index; 
 double level; 
 double close_price;
 ENUM_MNS_BREAK_TYPE type;  ENUM_MNS_TREND direction;  ENUM_MNS_SWING_LEVEL  swing_level; 
 ENUM_MNS_STRENGTH strength;  long broken_swing_id; 
 bool confirmed; 
 bool wick_only; 
 bool active; 
 double displacement;  double atr_multiple;  double strength_score; 
 void Reset() 
 { 
 id = -1; 
 time = 0; 
 bar_index = -1; 
 level = 0.0; 
 close_price = 0.0;
 type = MNS_BREAK_NONE;  direction =  
MNS_TREND_UNKNOWN; 
 swing_level =  
MNS_SWING_INTERNAL; 
 strength =  
MNS_STRENGTH_UNKNOWN;  broken_swing_id = -1; 
 confirmed = false; 
 wick_only = false; 
 active = false; 
 displacement = 0.0; 
 atr_multiple = 0.0; 
 strength_score = 0.0; 
 } 
}; 
//--------------------------------------------------------- // Complete market-state output //--------------------------------------------------------- struct MNS_MarketState 
{
 ENUM_MNS_TREND trend; 
 ENUM_MNS_PHASE phase; 
 MNS_SwingPoint latest_external_high;  MNS_SwingPoint latest_external_low; 
 MNS_SwingPoint latest_internal_high;   
What This File Does 
This file creates the common language for the system. It defines: 
Bullish, bearish, ranging and transition states. 
Internal and external swings. 
HH, HL, LH and LL classifications. 
BOS, internal BOS and CHoCH events. 
Strong and weak swing classifications. 
The complete market state that later modules will read. Helper functions for displaying data on the indicator. 
The developer should not change these names casually because  the remaining modules will depend on them. 
Phase 1 Build Order
The next files should be implemented in this order: text 
1. MNSTypes.mqh 
2. SwingDetector.mqh 
3. StructureEngine.mqh 
4. BreakDetector.mqh 
5. StrengthAnalyzer.mqh 
6. MarketStructureEngine.mqh 
7. MNSStructureIndicator.mq5 
The next implementation is SwingDetector.mqh, which will detect  confirmed internal and external swing highs and lows without  repainting. 
This module is the heart of the entire trading engine. Every other module depends on this one.
Price 
↓ 
Swing Detector ↓ 
Market Structure ↓ 
Order Flow 
↓ 
Delivery Structure ↓ 
DOL
↓ 
POI 
↓ 
Entry 
↓ 
EA 
If Swing Detection is wrong, everything is wrong. ─── 
Phase 1B 
SwingDetector.mqh 
Responsibilities 
The Swing Detector must: 
Detect External Swing Highs
Detect External Swing Lows 
Detect Internal Swing Highs 
Detect Internal Swing Lows 
Confirm swings 
Store swing history 
Never repaint 
Nothing else. 
─── 
Constructor 
cpp 
class CSwingDetector 
{ 
private: 
 MNS_SwingPoint m_externalSwings[];  MNS_SwingPoint m_internalSwings[]; 
 int m_externalDepth; 
 int m_internalDepth; 
public:
 CSwingDetector(); 
 void Initialize( 
 int externalDepth = 15,  int internalDepth = 5  ); 
 void Update(); 
}; 
─── 
Why two depths? 
External 
Large structure 
Example 
HH 
↓
HL 
↓ 
HH 
Internal 
Micro structure Example 
HH 
↓ 
HL 
↓ 
LH 
↓
LL 
↓ 
iBOS 
Both structures exist simultaneously. 
─── 
Initialization 
cpp 
void CSwingDetector::Initialize(  int externalDepth, 
 int internalDepth 
) 
{ 
 m_externalDepth = externalDepth;  m_internalDepth = internalDepth;  ArrayResize(m_externalSwings,0);
 ArrayResize(m_internalSwings,0); } 
─── 
Update() 
Every closed candle 
New Candle 
↓ 
Check Swing High 
↓ 
Check Swing Low 
↓ 
Store
↓ 
Return 
Never analyse the forming candle. Always analyse 
Shift = 2 
because 
Shift 0 
= 
Live candle 
Shift 1 
= 
Just closed 
Shift 2 
= 
Enough confirmation. 
───
External Swing High 
Algorithm 
Candidate Candle ↓ 
Highest High 
↓ 
Look Left 
15 candles 
↓ 
Look Right 
15 candles 
↓
Highest? 
↓ 
YES 
↓ 
External Swing High 
─── 
Developer function 
cpp 
bool DetectExternalHigh(int index); 
─── 
Pseudo code
Current High ↓ 
Loop Left 
↓ 
Higher? 
↓ 
Reject 
↓ 
Loop Right ↓ 
Higher?
↓ 
Reject 
↓ 
Otherwise 
Confirm Swing 
─── 
External Swing Low Exactly opposite. 
Lowest Low 
↓ 
Left 
↓
Right 
↓ 
Confirmed 
Developer function 
cpp 
bool DetectExternalLow(int index); 
─── 
Internal Swing High 
Exactly same algorithm 
except 
Depth 
= 
5 
instead of 
Developer function
cpp 
bool DetectInternalHigh(int index); 
─── 
Internal Swing Low 
Depth 
= 
Developer function 
cpp 
bool DetectInternalLow(int index); 
─── 
Create Swing Object 
When swing confirmed 
Fill
cpp 
MNS_SwingPoint swing; swing.price 
= 
High[index]; 
swing.time 
= 
Time[index]; 
swing.bar_index 
= 
index; 
swing.confirmed
= 
true; 
swing.active 
= 
true; 
─── 
Assign ID 
Every swing 
gets 
cpp 
ID 
1 
2 
3
4 
5 
Never reuse IDs. 
Future modules reference IDs. ─── 
Duplicate Protection 
Before storing 
Check 
Same Time? 
↓ 
Already Exists? 
↓ 
Ignore
Otherwise 
Save. 
─── 
Swing Storage 
Developer 
cpp 
void StoreSwing( 
 MNS_SwingPoint &swing ); 
Inside 
ArrayResize() 
↓ 
Append
↓ 
Done 
─── 
Active Swing 
Only one 
latest high 
Only one 
latest low 
Example 
cpp 
MNS_SwingPoint  
GetLatestExternalHigh(); 
MNS_SwingPoint  
GetLatestExternalLow(); 
MNS_SwingPoint  
GetLatestInternalHigh();
MNS_SwingPoint  
GetLatestInternalLow(); 
─── 
Swing History 
Developer 
cpp 
int GetExternalSwingCount(); 
int GetInternalSwingCount(); 
MNS_SwingPoint GetExternalSwing(int  index); 
MNS_SwingPoint GetInternalSwing(int  index); 
───
Performance 
Never 
loop 
10,000 candles 
every tick. 
Instead 
Store 
cpp 
LastProcessedBar When 
New Candle? 
↓ 
YES 
↓ 
Process One Candle
↓ 
Done 
This makes the engine extremely fast. 
─── 
Validation Rules 
Reject swings if: 
The price is equal to an existing confirmed swing at the same  time. 
The candle is still forming. 
There are not enough candles to the left or right. 
The candidate fails the required depth comparison. Only confirmed swings should be stored. 
─── 
Output Example 
After processing, the engine might expose:
External Swings 
High 
1.24780 
Low 
1.23920 
Internal Swings 
High 
1.24510 
Low 
1.24170 
External Count 28 
Internal Count
94 
─── 
What Comes Next 
Once the Swing Detector is complete and tested, the next module  is StructureEngine.mqh. 
That module will take these confirmed swings and automatically  classify them as: 
Higher High (HH) 
Higher Low (HL) 
Lower High (LH) 
Lower Low (LL) 
Equal High (EQH) 
Equal Low (EQL) 
It will also determine whether the market is bullish, bearish,  ranging, or in transition, providing the foundation for BOS  detection, Order Flow, Delivery Structure, and the rest of the MNS  engine.
Now we move to the module that actually gives meaning to the  swings. 
─── 
Phase 1C — StructureEngine.mqh 
Objective 
The Swing Detector only says: 
"Here are the confirmed swings." 
The Structure Engine must answer: 
Is this swing a HH? 
Is this swing a HL? 
Is this swing a LH? 
Is this swing a LL? 
Is this an Equal High? 
Is this an Equal Low? 
What is the current market trend? 
What is the market phase? 
─── 
Architecture
text 
Swing Detector 
 │ 
 ▼ 
Structure Engine 
 │ 
 ├── HH 
 ├── HL 
 ├── LH 
 ├── LL 
 ├── EQH 
 ├── EQL 
 │ 
 ▼ 
Current Market Structure 
─── 
Responsibilities 
The Structure Engine must:
Read confirmed swings. 
Compare every new swing with the previous confirmed swing  of the same type. 
Classify the structure. 
Update the trend. 
Maintain structure history. 
Expose the current state to the rest of the engine. 
─── 
Class Design 
cpp 
class CStructureEngine 
{ 
private: 
 MNS_MarketState m_state; 
public: 
 void Initialize();
 void Update(); 
 ENUM_MNS_STRUCTURE_TYPE  ClassifyHigh(); 
 ENUM_MNS_STRUCTURE_TYPE  ClassifyLow(); 
 void UpdateTrend(); 
 MNS_MarketState GetState(); 
}; 
─── 
Rule 1 — Higher High (HH) 
A confirmed Swing High is a Higher High when: text 
Current Swing High > 
Previous Swing High + Minimum Break  Distance
Example: 
text 
Previous High = 1.10250 
Current High = 1.10580 
Result = HH 
─── 
Rule 2 — Lower High (LH) 
text 
Current High < 
Previous High − Minimum Break  Distance 
Example:
text 
Previous High = 1.20540 
Current High = 1.20310 
Result = LH 
─── 
Rule 3 — Higher Low (HL) 
text 
Current Low > 
Previous Low + Minimum Break Distance 
─── 
Rule 4 — Lower Low (LL)
text 
Current Low < 
Previous Low − Minimum Break Distance 
─── 
Rule 5 — Equal High (EQH) 
One issue many retail indicators get wrong is treating tiny price  differences as new highs. 
Instead, define a tolerance. 
text 
Tolerance = 10% of current ATR 
If: 
text 
Absolute(Current High − Previous High) ≤ Tolerance
Then: 
text 
Equal High 
─── 
Rule 6 — Equal Low (EQL) 
Exactly the same logic. 
─── 
Why Use ATR? 
Markets have different volatility. 
A fixed value like 5 points works on one symbol but fails on  another. 
ATR makes the comparison adaptive. 
─── 
Trend Detection
The engine should not change trend after one HH or one LL. Require confirmation. 
Bullish Trend 
Minimum sequence: 
text 
HH 
↓ 
HL 
↓ 
HH 
↓ 
HL 
Only then:
text 
Trend = Bullish 
─── 
Bearish Trend 
Minimum sequence: text 
LL 
↓ 
LH 
↓ 
LL 
↓
LH 
Only then: 
text 
Trend = Bearish 
─── 
Transition 
If the sequence is mixed: text 
HH 
↓ 
LL 
↓ 
HL
↓ 
LH 
Return: 
text 
Transition 
─── 
Range 
If the last several swings are mostly EQH/EQL with no confirmed  trend: 
text 
Trend = Ranging 
───
Market Phase 
The Structure Engine should also return a market phase. Possible values: 
text 
Trending 
Pullback 
Transition 
Ranging 
Example: 
Higher timeframe: 
text 
Bullish 
Internal structure: 
text 
Bearish

Phase: 
text 
Pullback 
─── 
Structure Confidence 
Every update should calculate a confidence score. Example weighting: 
Factor Weight 
HH/HL sequence  
consistency 
30% 

BOS confirmation 25% Swing quality 20% Displacement 15%

strength 
Equal High/Low noise 10% 
Final output: 
text 
Confidence 
93% 
This score will later be used by the Entry Engine to filter weaker  setups. 
─── 
Public API 
Other modules should be able to call: 
cpp 
MNS_MarketState GetCurrentMarket(); bool IsBullish();

bool IsBearish(); 
bool IsTransition(); 
bool IsRanging(); 
ENUM_MNS_STRUCTURE_TYPE  GetLatestHighType(); 
ENUM_MNS_STRUCTURE_TYPE  GetLatestLowType(); 
double GetConfidenceScore(); 
─── 
Output Example 
After processing, the module might return: text 
Trend:
Bullish 
Phase: 
Trending 
Latest High: 
HH 
Latest Low: 
HL 
Confidence: 
94% 
External Structure: HH → HL → HH → HL 
Internal Structure: LH → LL 
Current State: 
Bullish Pullback
─── 
Why this module matters 
At this point, your engine no longer just detects highs and lows—it  understands the language of the market. 
Once this module is complete, we can build Phase 1D –  BreakDetector.mqh, where the engine will begin detecting: 
Break of Structure (BOS) 
Internal BOS (iBOS) 
Change of Character (CHoCH) 
using the exact MNS rules from the PDFs. That is the point where  the engine starts recognising real structural shifts rather than  simply classifying swings. 
Now we're getting into the core of Smart Money Concepts. Everything we've built so far only identifies the structure. This next  module tells us when the market has actually changed. This is where the engine starts behaving like a professional trader. 
───
Objective 
The Break Detector monitors confirmed market structure and  identifies: 
Break of Structure (BOS) 
Internal Break of Structure (iBOS) 
Change of Character (CHoCH) 
It does not decide whether to trade. It only reports structural  events. 
─── 
Architecture 
text 
Confirmed Swings 
 │ 
 ▼ 
Structure Engine 
 │ 
 ▼ 
Break Detector 
 │
 ├── BOS 
 ├── iBOS 
 ├── CHoCH 
 │ 
 ▼ 
Structure Events 
─── 
Responsibilities 
The Break Detector must: 
Monitor the latest confirmed swing highs and lows. Detect body-close BOS events. 
Detect wick-only CHoCH events. 
Detect Internal BOS from internal swings. 
Score the strength of each break. 
Store every break for historical reference. 
Never repaint. 
───
cpp 
class CBreakDetector 
{ 
private: 
 MNS_StructureBreak m_breakHistory[]; public: 
 void Initialize(); 
 void Update(); 
 bool DetectBullishBOS(); 
 bool DetectBearishBOS(); 
 bool DetectBullishIBOS(); 
 bool DetectBearishIBOS(); 
 bool DetectBullishCHOCH();
 bool DetectBearishCHOCH(); 
 MNS_StructureBreak GetLatestBreak(); }; 
─── 
Rule 1 — Bullish BOS 
Conditions: 
Previous confirmed External Swing High exists. Candle body closes above that Swing High. 
Candle is already closed. 
Break has not already been recorded. 
If all are true: 
text 
Create Bullish BOS 
───
Rule 2 — Bearish BOS Conditions: 
1. 
Previous confirmed External Swing Low exists. 2. 
Candle body closes below that Swing Low. 3. 
Candle closed. 
4.
Not previously recorded. 
Output: 
text 
Bearish BOS 
─── 
Rule 3 — Internal BOS (iBOS) 
Exactly the same rules as BOS, but using internal swing highs and  lows. 
These represent micro-structure shifts within the current trend. ─── 
Rule 4 — CHoCH 
The PDFs specify a different confirmation. 
Conditions: 
Price wicks beyond a protected swing. 
Candle body does not close beyond that level. Output: 
text 
CHoCH 
This is treated as an early warning of a possible shift, not  confirmation. 
─── 
Rule 5 — Ignore False Breaks 
Do not create a BOS if: 
Only the wick breaks the level. 
The candle is still forming. 
The body closes back inside the previous structure. The break was already detected.
─── 
Rule 6 — Break Strength 
Every detected break receives a strength score. Suggested components: 
Displacement after the break. 
Candle body size. 
ATR multiple. 
Volume (if available). 
Distance travelled before pullback. 
Classification: 
text 
90–100 Very Strong 
70–89 Strong 
50–69 Average 
0–49 Weak 
This will later help filter lower-quality setups. ───
Stored Data 
Each event should record: 
text 
Break ID 
Time 
Bar Index 
Break Type 
Direction 
Broken Swing ID 
Break Level 
Close Price 
Strength Score 
ATR Multiple 
Displacement 
─── 
Public API 
Other modules should be able to call:
cpp 
bool HasBullishBOS(); 
bool HasBearishBOS(); 
bool HasBullishIBOS(); 
bool HasBearishIBOS(); 
bool HasBullishCHOCH(); 
bool HasBearishCHOCH(); 
MNS_StructureBreak GetLatestBOS(); MNS_StructureBreak GetLatestIBOS(); MNS_StructureBreak GetLatestCHOCH(); 
───
Example Output 
text 
Latest BOS 
------------ 
Type: BOS 
Direction: Bullish Level: 1.25480 
Close: 1.25520 
Strength: 91% 
ATR: 2.1 
Latest CHoCH 
------------- 
None 
Latest iBOS 
------------ 
Bearish 
Strength: 74%
─── 
Validation Checklist 
Before a break is accepted: 
✓ Swing is confirmed. 
✓ Candle is closed. 
✓ Break satisfies BOS or CHoCH rules. 
✓ Event has not already been logged. 
✓ Strength score calculated. 
✓ Event stored in history. 
─── 
Phase 1 Status 
By this point, the engine contains: 
✅ MNSTypes – Common data structures. 
✅ SwingDetector – Non-repainting swing detection. ✅ StructureEngine – HH, HL, LH, LL classification and trend. ✅ BreakDetector – BOS, iBOS and CHoCH detection. 
These four modules form the complete Market Structure Engine.  Every later component—Order Flow, Delivery Structure, DOL, POIs, 
