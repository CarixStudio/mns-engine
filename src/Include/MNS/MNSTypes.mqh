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
#pragma once

//+------------------------------------------------------------------+
//| Constants                                                        |
//+------------------------------------------------------------------+

/// @brief Sentinel value for an uninitialized or invalid bar index.
const int MNS_INVALID_INDEX = -1;

/// @brief Sentinel value for an uninitialized or invalid price level.
const double MNS_INVALID_PRICE = 0.0;

/// @brief Sentinel value for an uninitialized datetime.
const datetime MNS_INVALID_TIME = 0;

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
        lastBOS.Reset();
        lastCHoCH.Reset();
        lastSwingHigh.Reset();
        lastSwingLow.Reset();
    }
};

//+------------------------------------------------------------------+
//| End of MNSTypes.mqh                                              |
//+------------------------------------------------------------------+
