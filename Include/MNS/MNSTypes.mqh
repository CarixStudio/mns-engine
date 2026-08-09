//+------------------------------------------------------------------+
//|                                                     MNSTypes.mqh |
//|                              MNS Trading Engine — Module 001     |
//|                                                                  |
//| Purpose:                                                         |
//|   Defines all shared enumerations, structures, and constants     |
//|   used throughout the MNS Trading Engine.                        |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Define all engine enumerations.                              |
//|   - Define all shared data structures.                           |
//|   - Define all shared constants.                                 |
//|   - Provide safe default initialization for all structures.      |
//|                                                                  |
//| Dependencies:                                                    |
//|   None. This is the root module of the system.                   |
//|                                                                  |
//| Rules:                                                           |
//|   - No business logic.                                           |
//|   - No market analysis.                                          |
//|   - No trade execution.                                          |
//|   - No indicator drawing.                                        |
//|   - No broker interaction.                                       |
//|   - No chart operations.                                         |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_TYPES_MQH__
#define __MNS_TYPES_MQH__

#include "MNSCore.mqh"

//+------------------------------------------------------------------+
//| Version Information                                              |
//+------------------------------------------------------------------+

/// @brief MNS Trading Engine version string for logging and diagnostics.
#define MNS_ENGINE_VERSION "1.0.0"

/// @brief MNSTypes module identifier — matches the module specification number.
#define MNS_MODULE_VERSION "001"

//+------------------------------------------------------------------+
//| Constants                                                        |
//+------------------------------------------------------------------+


/// @brief Maximum number of swing points the engine retains in memory.
const int MNS_MAX_SWINGS = 500;

/// @brief Maximum number of structure breaks the engine retains in memory.
const int MNS_MAX_STRUCTURE_BREAKS = 200;

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+

//-------------------------------------------------------------------
/// @brief Represents the directional trend bias of the market.
///
/// Used by the MarketStructureEngine and consumed by downstream
/// modules to determine overall market direction.
//-------------------------------------------------------------------
enum ETrend
{
    TREND_UNKNOWN    = 0,  ///< Trend has not yet been determined.
    TREND_BULLISH    = 1,  ///< Market is forming Higher Highs and Higher Lows.
    TREND_BEARISH    = 2,  ///< Market is forming Lower Highs and Lower Lows.
    TREND_TRANSITION = 3,  ///< Market is transitioning between bullish and bearish.
    TREND_RANGING    = 4   ///< Market is oscillating without clear directional bias.
};

//-------------------------------------------------------------------
/// @brief Represents the current phase of market activity.
///
/// Used alongside ETrend to provide a more granular description
/// of where the market is within its current cycle.
//-------------------------------------------------------------------
enum EMarketPhase
{
    PHASE_UNKNOWN    = 0,  ///< Market phase has not yet been determined.
    PHASE_TRENDING   = 1,  ///< Market is in an active directional trend.
    PHASE_PULLBACK   = 2,  ///< Market is retracing within the trend.
    PHASE_TRANSITION = 3,  ///< Market is transitioning between phases.
    PHASE_RANGING    = 4   ///< Market is moving laterally without trend.
};

//-------------------------------------------------------------------
/// @brief Classifies a swing point as a high, a low, or unset.
///
/// Used by the SwingDetector to tag detected swing structures.
//-------------------------------------------------------------------
enum ESwingType
{
    SWING_NONE = 0,  ///< No swing type assigned.
    SWING_HIGH = 1,  ///< This swing point is a swing high.
    SWING_LOW  = 2   ///< This swing point is a swing low.
};

//-------------------------------------------------------------------
/// @brief Indicates whether a swing belongs to the internal or
///        external structure of the market.
///
/// Internal swings form within the context of a larger external move.
/// External swings represent the highest-timeframe structural points.
//-------------------------------------------------------------------
enum ESwingLevel
{
    SWING_LEVEL_INTERNAL = 0,  ///< Swing belongs to the internal market structure.
    SWING_LEVEL_EXTERNAL = 1   ///< Swing belongs to the external market structure.
};

//-------------------------------------------------------------------
/// @brief Classifies the relationship between consecutive swing points.
///
/// Used by the StructureEngine to track the sequence of market structure.
//-------------------------------------------------------------------
enum EStructureType
{
    STRUCTURE_NONE       = 0,  ///< No structure type assigned.
    STRUCTURE_HH         = 1,  ///< Higher High — swing high exceeded prior swing high.
    STRUCTURE_HL         = 2,  ///< Higher Low  — swing low held above prior swing low.
    STRUCTURE_LH         = 3,  ///< Lower High  — swing high failed to exceed prior swing high.
    STRUCTURE_LL         = 4,  ///< Lower Low   — swing low broke below prior swing low.
    STRUCTURE_EQUAL_HIGH = 5,  ///< Equal High  — swing high reached same level as prior high.
    STRUCTURE_EQUAL_LOW  = 6   ///< Equal Low   — swing low reached same level as prior low.
};

//-------------------------------------------------------------------
/// @brief Classifies the type of structural break detected.
///
/// Used by the MarketStructureEngine to identify significant
/// changes in market structure.
//-------------------------------------------------------------------
enum EStructureBreak
{
    BREAK_NONE         = 0,  ///< No structural break detected.
    BREAK_BOS          = 1,  ///< Break of Structure — continuation of the current trend.
    BREAK_INTERNAL_BOS = 2,  ///< Internal Break of Structure — minor break within structure.
    BREAK_CHOCH        = 3   ///< Change of Character — potential trend reversal signal.
};

//-------------------------------------------------------------------
/// @brief Represents the relative strength or conviction of a
///        structural element, signal, or confirmation.
///
/// Used across multiple engine modules to express confidence levels.
//-------------------------------------------------------------------
enum EStrength
{
    STRENGTH_UNKNOWN    = 0,  ///< Strength has not been evaluated.
    STRENGTH_WEAK       = 1,  ///< Low conviction or weak structural element.
    STRENGTH_AVERAGE    = 2,  ///< Moderate conviction or standard structural element.
    STRENGTH_STRONG     = 3,  ///< High conviction or strong structural element.
    STRENGTH_VERY_STRONG = 4  ///< Exceptional conviction or dominant structural element.
};

//-------------------------------------------------------------------
/// @brief Represents the directional bias of the order flow.
//-------------------------------------------------------------------
enum EOrderFlowDirection
{
    ORDER_FLOW_DIR_NEUTRAL = 0,  ///< No clear order flow bias.
    ORDER_FLOW_DIR_BULLISH = 1,  ///< Order flow is bullish.
    ORDER_FLOW_DIR_BEARISH = 2   ///< Order flow is bearish.
};

//-------------------------------------------------------------------
/// @brief Represents the detailed state of the order flow.
//-------------------------------------------------------------------
enum EOrderFlowState
{
    ORDER_FLOW_NEUTRAL            = 0,  ///< Neutral state.
    ORDER_FLOW_BULLISH            = 1,  ///< Confirmed bullish order flow.
    ORDER_FLOW_BEARISH            = 2,  ///< Confirmed bearish order flow.
    ORDER_FLOW_TRANSITION_BULLISH = 3,  ///< Reversal warning, transitioning bullish.
    ORDER_FLOW_TRANSITION_BEARISH = 4   ///< Reversal warning, transitioning bearish.
};

//-------------------------------------------------------------------
/// @brief Represents the directional bias of the price delivery.
//-------------------------------------------------------------------
enum EDeliveryDirection
{
    DELIVERY_DIR_NEUTRAL = 0,  ///< No active delivery bias.
    DELIVERY_DIR_BULLISH = 1,  ///< Price delivery is bullish.
    DELIVERY_DIR_BEARISH = 2   ///< Price delivery is bearish.
};

//-------------------------------------------------------------------
/// @brief Represents the lifecycle state of a delivery structure.
//-------------------------------------------------------------------
enum EDeliveryLifecycle
{
    DELIVERY_CANDIDATE          = 0,  ///< Potential delivery leg in formation.
    DELIVERY_ACTIVE             = 1,  ///< Confirmed active delivery leg.
    DELIVERY_MITIGATED          = 2,  ///< Price has mitigated the origin POI/protected level.
    DELIVERY_OBJECTIVE_REACHED  = 3,  ///< Price has hit the target liquidity/DOL level.
    DELIVERY_INVALIDATED        = 4,  ///< Price has closed beyond the invalidation level.
    DELIVERY_REPLACED           = 5,  ///< Replaced by a newer active delivery structure.
    DELIVERY_ARCHIVED           = 6   ///< Archived historical leg.
};

//-------------------------------------------------------------------
/// @brief Represents the type of liquidity pool.
//-------------------------------------------------------------------
enum ELiquidityType
{
    LIQUIDITY_NONE = 0,         ///< No liquidity pool.
    LIQUIDITY_BSL  = 1,         ///< Buy-side liquidity pool (above highs).
    LIQUIDITY_SSL  = 2          ///< Sell-side liquidity pool (below lows).
};

//-------------------------------------------------------------------
/// @brief Represents the source structure of a liquidity pool.
//-------------------------------------------------------------------
enum ELiquiditySource
{
    LIQ_SRC_SWING   = 0,        ///< Confirmed swing point.
    LIQ_SRC_EQ      = 1,        ///< Equal highs/lows.
    LIQ_SRC_SESSION = 2,        ///< Session highs/lows (London/NY/Asia).
    LIQ_SRC_DAILY   = 3,        ///< Previous day high/low (PDH/PDL).
    LIQ_SRC_WEEKLY  = 4         ///< Previous week high/low (PWH/PWL).
};

//-------------------------------------------------------------------
/// @brief Represents the lifecycle state of a liquidity pool.
//-------------------------------------------------------------------
enum ELiquidityLifecycle
{
    LIQ_ACTIVE   = 0,           ///< Active, untouched liquidity pool.
    LIQ_TOUCHED  = 1,           ///< Price touched the pool.
    LIQ_SWEPT    = 2,           ///< Liquidity pool was swept.
    LIQ_BROKEN   = 3,           ///< Liquidity pool was broken/invalidated.
    LIQ_CONSUMED = 4,           ///< Liquidity pool was completely consumed.
    LIQ_ARCHIVED = 5            ///< Archived historical pool.
};

//-------------------------------------------------------------------
/// @brief Represents the priority ranking of a liquidity pool.
//-------------------------------------------------------------------
enum EPoolPriority
{
    PRIORITY_LOW    = 0,        ///< Low priority liquidity.
    PRIORITY_MEDIUM = 1,        ///< Medium priority liquidity.
    PRIORITY_HIGH   = 2         ///< High priority liquidity.
};

//+------------------------------------------------------------------+
//| Shared Data Structures                                           |
//+------------------------------------------------------------------+

//-------------------------------------------------------------------
/// @brief Represents a confirmed swing point in the market.
///
/// A swing point is a confirmed pivot where price reversed direction.
/// Once confirmed, a swing point must never be modified or removed.
///
/// Fields:
///   barIndex   — The bar index at which the swing was confirmed.
///   price      — The exact price level of the swing point.
///   time       — The datetime of the candle that formed the swing.
///   type       — Whether this is a swing high or a swing low.
///   level      — Whether this belongs to internal or external structure.
///   isConfirmed — True only when the swing has been fully validated.
//-------------------------------------------------------------------
struct SSwingPoint
{
    int         barIndex;     ///< Bar index of the confirmed swing candle.
    double      price;        ///< Price level of the swing point.
    datetime    time;         ///< Datetime of the swing candle.
    ESwingType  type;         ///< Swing high or swing low classification.
    ESwingLevel level;        ///< Internal or external structure level.
    bool        isConfirmed;  ///< True when the swing has been fully confirmed.

    /// @brief Initializes all fields to safe default values.
    void Reset()
    {
        barIndex    = MNS_INVALID_INDEX;
        price       = MNS_INVALID_PRICE;
        time        = MNS_INVALID_TIME;
        type        = SWING_NONE;
        level       = SWING_LEVEL_INTERNAL;
        isConfirmed = false;
    }
};

//-------------------------------------------------------------------
/// @brief Represents a confirmed structural break in the market.
///
/// A structural break records an event where price has closed beyond
/// a prior swing point, signalling either trend continuation (BOS)
/// or trend reversal (CHoCH).
///
/// Fields:
///   barIndex     — The bar index at which the break was confirmed.
///   price        — The price level that was breached.
///   time         — The datetime of the candle that caused the break.
///   breakType    — Classification of the break (BOS, Internal BOS, CHoCH).
///   strength     — The relative strength or conviction of the break.
///   brokenSwing  — A copy of the swing point that was broken.
///   isConfirmed  — True only when the break has been fully validated.
//-------------------------------------------------------------------
struct SStructureBreak
{
    int            barIndex;     ///< Bar index of the candle that confirmed the break.
    double         price;        ///< Price level of the structural break.
    datetime       time;         ///< Datetime of the break candle.
    EStructureBreak breakType;   ///< Classification of the structural break.
    EStrength      strength;     ///< Relative strength of the structural break.
    SSwingPoint    brokenSwing;  ///< Copy of the swing point that was breached.
    bool           isConfirmed;  ///< True when the break has been fully confirmed.

    /// @brief Initializes all fields to safe default values.
    void Reset()
    {
        barIndex   = MNS_INVALID_INDEX;
        price      = MNS_INVALID_PRICE;
        time       = MNS_INVALID_TIME;
        breakType  = BREAK_NONE;
        strength   = STRENGTH_UNKNOWN;
        isConfirmed = false;
        brokenSwing.Reset();
    }
};

//-------------------------------------------------------------------
/// @brief Represents the complete current state of the market as
///        determined by the analysis engine.
///
/// This is the primary output structure of the MarketStructureEngine.
/// It is consumed read-only by all downstream modules including the
/// OrderFlowEngine, LiquidityEngine, POIEngine, ConfirmationEngine,
/// EntryEngine, RiskEngine, Indicator, and Expert Advisor.
///
/// Fields:
///   trend              — Current directional trend classification.
///   phase              — Current market phase classification.
///   lastBOS            — The most recently confirmed Break of Structure.
///   lastCHoCH          — The most recently confirmed Change of Character.
///   lastSwingHigh      — The most recently confirmed swing high.
///   lastSwingLow       — The most recently confirmed swing low.
///   structureType      — The current structural relationship classification.
///   isBullishStructure — True when the dominant structure is bullish.
///   isBearishStructure — True when the dominant structure is bearish.
///   isRanging          — True when the market is in a ranging condition.
///   updatedBarIndex    — Bar index of the last engine update cycle.
///   updatedTime        — Datetime of the last engine update cycle.
///   version            — Structure schema version for future compatibility.
//-------------------------------------------------------------------
struct SMarketState
{
    ETrend          trend;               ///< Current directional trend.
    EMarketPhase    phase;               ///< Current market phase.
    SStructureBreak lastBOS;             ///< Most recent confirmed BOS.
    SStructureBreak lastCHoCH;           ///< Most recent confirmed CHoCH.
    SSwingPoint     lastSwingHigh;       ///< Most recent confirmed swing high.
    SSwingPoint     lastSwingLow;        ///< Most recent confirmed swing low.
    EStructureType  structureType;       ///< Current structural classification.
    bool            isBullishStructure;  ///< True when dominant structure is bullish.
    bool            isBearishStructure;  ///< True when dominant structure is bearish.
    bool            isRanging;           ///< True when market is ranging.
    int             updatedBarIndex;     ///< Bar index of the last engine update.
    datetime        updatedTime;         ///< Datetime of the last engine update.
    uint            version;             ///< Schema version — increment when SMarketState fields change.

    /// @brief Initializes all fields to safe default values.
    void Reset()
    {
        trend              = TREND_UNKNOWN;
        phase              = PHASE_UNKNOWN;
        structureType      = STRUCTURE_NONE;
        isBullishStructure = false;
        isBearishStructure = false;
        isRanging          = false;
        updatedBarIndex    = MNS_INVALID_INDEX;
        updatedTime        = MNS_INVALID_TIME;
        version            = 1;
        lastBOS.Reset();
        lastCHoCH.Reset();
        lastSwingHigh.Reset();
        lastSwingLow.Reset();
    }
};

//-------------------------------------------------------------------
/// @brief Represents the active order flow state and metrics.
//-------------------------------------------------------------------
struct SOrderFlowState
{
    EOrderFlowDirection direction;          ///< Active directional trade bias.
    EOrderFlowDirection previousDirection;  ///< Direction before transition.
    EOrderFlowState     state;              ///< Granular state including transitions.
    double              confidenceScore;    ///< Order flow confidence (0 to 100).
    datetime            originSwingId;      ///< Time of the swing initiating the leg.
    datetime            protectedSwingId;   ///< Time of the active protected swing.
    datetime            lastBOSId;          ///< Time of the latest confirmed BOS.
    datetime            lastCHoCHId;        ///< Time of the latest transition CHoCH.
    datetime            displacementId;     ///< Time of the latest displacement break.
    datetime            startTime;          ///< Time when current state was entered.
    datetime            lastUpdatedTime;    ///< Time of the last update.
    double              bullishStrength;    ///< Volatility-scaled bullish strength.
    double              bearishStrength;    ///< Volatility-scaled bearish strength.
    bool                transition;         ///< True if in transition state.
    bool                confirmed;          ///< True if state is fully confirmed.
    bool                invalidated;        ///< True if protected swing was breached.

    /// @brief Initializes all fields to safe default values.
    void Reset()
    {
        direction         = ORDER_FLOW_DIR_NEUTRAL;
        previousDirection = ORDER_FLOW_DIR_NEUTRAL;
        state             = ORDER_FLOW_NEUTRAL;
        confidenceScore   = 0.0;
        originSwingId     = 0;
        protectedSwingId  = 0;
        lastBOSId         = 0;
        lastCHoCHId       = 0;
        displacementId    = 0;
        startTime         = 0;
        lastUpdatedTime   = 0;
        bullishStrength   = 0.0;
        bearishStrength   = 0.0;
        transition        = false;
        confirmed         = false;
        invalidated       = false;
    }
};

//-------------------------------------------------------------------
/// @brief Represents the state of the price delivery structure.
//-------------------------------------------------------------------
struct SDeliveryState
{
    EDeliveryDirection direction;               ///< Delivery direction (neutral/bullish/bearish).
    double             originPrice;             ///< Price of the origin POI or protected swing.
    datetime           originTime;              ///< Time when the origin swing was formed.
    double             protectedPrice;          ///< Price of the active protected swing.
    double             currentObjective;        ///< Price target/objective (DOL).
    datetime           associatedBosId;         ///< Time ID of the confirming BOS.
    datetime           associatedDisplacementId;///< Time ID of the confirming displacement bar.
    datetime           associatedPoiId;         ///< Time ID of the POI.
    EDeliveryLifecycle lifecycle;               ///< Current lifecycle status.
    double             confidence;              ///< Delivery confidence score (0 to 100).
    double             progressPercent;         ///< Leg progress percentage.
    double             invalidationLevel;       ///< Price level for invalidation trigger.
    datetime           lastUpdatedTime;         ///< Time of the last state update.

    /// @brief Initializes all fields to safe default values.
    void Reset()
    {
        direction                = DELIVERY_DIR_NEUTRAL;
        originPrice              = 0.0;
        originTime               = 0;
        protectedPrice           = 0.0;
        currentObjective         = 0.0;
        associatedBosId          = 0;
        associatedDisplacementId = 0;
        associatedPoiId          = 0;
        lifecycle                = DELIVERY_CANDIDATE;
        confidence               = 0.0;
        progressPercent          = 0.0;
        invalidationLevel        = 0.0;
        lastUpdatedTime          = 0;
    }
};

//-------------------------------------------------------------------
/// @brief Represents a tracked liquidity pool and its properties.
//-------------------------------------------------------------------
struct SLiquidityPool
{
    int                 id;                 ///< Unique pool identifier.
    ELiquidityType      type;               ///< BSL or SSL type.
    ELiquiditySource    source;             ///< Source type.
    double              level;              ///< Price level of the pool.
    datetime            createdTime;        ///< Timestamp of pool creation.
    int                 touchesCount;       ///< Touch count.
    datetime            touchTimes[5];      ///< Timestamps of distinct touches.
    ELiquidityLifecycle lifecycle;          ///< Lifecycle state.
    double              rankingScore;       ///< 0-100 score.
    EPoolPriority       priority;           ///< Low/Medium/High.
    bool                active;             ///< Active status flag.
    bool                swept;              ///< Swept status flag.
    datetime            sweptTime;          ///< Timestamp when swept.
    datetime            brokenTime;         ///< Timestamp when broken.

    /// @brief Initializes all fields to safe defaults.
    void Reset()
    {
        id           = 0;
        type         = LIQUIDITY_NONE;
        source       = LIQ_SRC_SWING;
        level        = 0.0;
        createdTime  = 0;
        touchesCount = 0;
        for (int i = 0; i < 5; i++)
            touchTimes[i] = 0;
        lifecycle    = LIQ_ACTIVE;
        rankingScore = 0.0;
        priority     = PRIORITY_LOW;
        active       = true;
        swept        = false;
        sweptTime    = 0;
        brokenTime   = 0;
    }
};

//+------------------------------------------------------------------+
//| End of MNSTypes.mqh                                              |
//+------------------------------------------------------------------+

#endif // __MNS_TYPES_MQH__
