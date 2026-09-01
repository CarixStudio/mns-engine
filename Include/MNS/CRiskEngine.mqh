//+------------------------------------------------------------------+
//|                                                  CRiskEngine.mqh |
//|                              MNS Trading Engine — Module 012     |
//|                                                                  |
//| Purpose:                                                         |
//|   Calculates entry sizing (risk/reward, buffers, position size)   |
//|   and handles active-position tracking (partial close, trailing   |
//|   stop, emergency exits).                                        |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_RISK_ENGINE_MQH__
#define __MNS_RISK_ENGINE_MQH__

#include "MNSTypes.mqh"

//+------------------------------------------------------------------+
//| CRiskEngine Class                                                |
//+------------------------------------------------------------------+
class CRiskEngine
{
private:
    bool        m_isInitialized;        ///< Initialization status flag.
    double      m_minRiskPercent;       ///< Minimum allowed risk percent.
    double      m_maxRiskPercent;       ///< Maximum allowed risk percent.
    double      m_defaultRiskPercent;   ///< Default risk percent.
    double      m_maxDailyDrawdown;     ///< Maximum daily drawdown limit.

    // Active trade tracking states per position
    bool        m_hasPartialClosed;     ///< Track if +1.0R partial close triggered.
    int         m_lastTrailingTier;     ///< Last trailing step multiplier tier.

public:
    CRiskEngine();
    ~CRiskEngine();

    /// @brief Initializes the Risk Engine with boundary parameters.
    /// @return True on success.
    bool        Initialize(double defaultRisk = 1.0, 
                           double minRisk = 0.25, 
                           double maxRisk = 2.0, 
                           double maxDailyDrawdownPercent = 5.0);

    /// @brief Resets current active position tracking variables.
    void        ResetPositionTracking();

    /// @brief Calculates entry parameters and lot sizing before entering a position.
    /// @return SRiskSizingResult structure containing calculations.
    SRiskSizingResult SizePreTrade(EConfirmationDirection direction,
                                   double entryPrice,
                                   double invalidationLevel,
                                   double dolPrice,
                                   double atr14,
                                   double desiredRiskPercent,
                                   double accountEquity,
                                   string symbol);

    /// @brief Evaluates an active trade for trailing stops, partial closes, or emergency exits.
    /// @return SRiskManagementAction structure.
    SRiskManagementAction UpdateActiveManagement(EConfirmationDirection positionDirection,
                                                 double positionEntryPrice,
                                                 double positionCurrentVolume,
                                                 double positionOriginalSL,
                                                 double positionCurrentSL,
                                                 double currentBid,
                                                 double currentAsk,
                                                 double atr14,
                                                 EDeliveryLifecycle deliveryLifecycle,
                                                 bool isDolReached,
                                                 bool isDolInvalidated,
                                                 bool mtfReversal,
                                                 double currentDailyDrawdownPercent,
                                                 string symbol);

    /// @brief Synchronizes the partial close tracking state.
    void        SetHasPartialClosed(bool flag) { m_hasPartialClosed = flag; }

    /// @brief Returns the partial close tracking state.
    bool        GetHasPartialClosed() const { return m_hasPartialClosed; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskEngine::CRiskEngine()
    : m_isInitialized(false),
      m_minRiskPercent(0.25),
      m_maxRiskPercent(2.00),
      m_defaultRiskPercent(1.00),
      m_maxDailyDrawdown(5.0)
{
    ResetPositionTracking();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskEngine::~CRiskEngine()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CRiskEngine::Initialize(double defaultRisk, double minRisk, double maxRisk, double maxDailyDrawdownPercent)
{
    m_defaultRiskPercent = defaultRisk;
    m_minRiskPercent = minRisk;
    m_maxRiskPercent = maxRisk;
    m_maxDailyDrawdown = maxDailyDrawdownPercent;
    m_isInitialized = true;
    ResetPositionTracking();
    return true;
}

//+------------------------------------------------------------------+
//| ResetPositionTracking                                            |
//+------------------------------------------------------------------+
void CRiskEngine::ResetPositionTracking()
{
    m_hasPartialClosed = false;
    m_lastTrailingTier = -1;
}

//+------------------------------------------------------------------+
//| SizePreTrade                                                     |
//+------------------------------------------------------------------+
SRiskSizingResult CRiskEngine::SizePreTrade(EConfirmationDirection direction,
                                           double entryPrice,
                                           double invalidationLevel,
                                           double dolPrice,
                                           double atr14,
                                           double desiredRiskPercent,
                                           double accountEquity,
                                           string symbol)
{
    SRiskSizingResult result;
    result.Reset();

    if (!m_isInitialized)
        return result;

    if (direction == CONFIRM_DIR_NEUTRAL || entryPrice <= 0.0 || invalidationLevel <= 0.0 || dolPrice <= 0.0)
        return result;

    double pointSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if (pointSize <= 0.0)
        return result;

    // 1. Calculate Stop Loss Buffer
    double atrOffset = 0.20 * atr14;
    double minOffset = 2.0 * pointSize;
    double stopBuffer = MathMax(atrOffset, minOffset);

    // 2. Compute Stop Loss Level
    double sl = MNS_INVALID_PRICE;
    if (direction == CONFIRM_DIR_BULLISH)
    {
        sl = invalidationLevel - stopBuffer;
        if (sl >= entryPrice || dolPrice <= entryPrice)
            return result;
    }
    else if (direction == CONFIRM_DIR_BEARISH)
    {
        sl = invalidationLevel + stopBuffer;
        if (sl <= entryPrice || dolPrice >= entryPrice)
            return result;
    }

    // 3. Compute Risk and Reward Distances
    double riskDistance = MathAbs(entryPrice - sl);
    double rewardDistance = MathAbs(dolPrice - entryPrice);

    if (riskDistance <= 0.0 || rewardDistance <= 0.0)
        return result;

    // 4. Verify Reward-to-Risk Ratio
    double rr = rewardDistance / riskDistance;
    if (rr < 1.50)
    {
        return result; // Reject trade (approved = false)
    }

    // 5. Compute Cash Risk Amount
    double riskPercent = MathMax(m_minRiskPercent, MathMin(m_maxRiskPercent, desiredRiskPercent));
    double riskAmount = accountEquity * riskPercent / 100.0;

    // 6. Compute Position Size (Volume)
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    if (tickSize <= 0.0) tickSize = pointSize;
    if (tickValue <= 0.0) tickValue = 1.0;

    double lossPerLot = 0.0;
    double calculatedProfit = 0.0;
    ENUM_ORDER_TYPE orderAction = (direction == CONFIRM_DIR_BULLISH) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

    if (OrderCalcProfit(orderAction, symbol, 1.0, entryPrice, sl, calculatedProfit))
    {
        lossPerLot = MathAbs(calculatedProfit);
    }
    else
    {
        lossPerLot = (riskDistance / tickSize) * tickValue;
    }

    if (lossPerLot <= 0.0)
        return result;

    double volMin = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double volMax = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double volStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    if (volMin <= 0.0) volMin = 0.01;
    if (volMax <= 0.0) volMax = 100.0;
    if (volStep <= 0.0) volStep = 0.01;

    double rawVolume = riskAmount / lossPerLot;
    double steps = MathFloor(rawVolume / volStep);
    double volume = steps * volStep;

    if (volume < volMin)
    {
        return result; // Sized volume is below minimum allowable contract size. Reject to avoid exceeding risk.
    }
    
    if (volume > volMax)
        volume = volMax;

    // Ensure we do not round up beyond risk tolerance
    if (volume * lossPerLot > riskAmount && volume > volMin)
    {
        volume -= volStep;
    }

    result.approved   = true;
    result.entryPrice = entryPrice;
    result.stopLoss   = sl;
    result.takeProfit = dolPrice;
    result.volume     = volume;
    result.riskAmount = riskAmount;
    result.expectedRr = rr;

    return result;
}

//+------------------------------------------------------------------+
//| UpdateActiveManagement                                           |
//+------------------------------------------------------------------+
SRiskManagementAction CRiskEngine::UpdateActiveManagement(EConfirmationDirection positionDirection,
                                                         double positionEntryPrice,
                                                         double positionCurrentVolume,
                                                         double positionOriginalSL,
                                                         double positionCurrentSL,
                                                         double currentBid,
                                                         double currentAsk,
                                                         double atr14,
                                                         EDeliveryLifecycle deliveryLifecycle,
                                                         bool isDolReached,
                                                         bool isDolInvalidated,
                                                         bool mtfReversal,
                                                         double currentDailyDrawdownPercent,
                                                         string symbol)
{
    SRiskManagementAction action;
    action.Reset();

    if (!m_isInitialized)
        return action;

    // 1. Emergency Exits
    if (isDolReached || isDolInvalidated || 
        deliveryLifecycle == DELIVERY_INVALIDATED || 
        mtfReversal || 
        currentDailyDrawdownPercent >= m_maxDailyDrawdown)
    {
        action.closeFully = true;
        return action;
    }

    // Calculate progress in R
    double riskDistance = MathAbs(positionEntryPrice - positionOriginalSL);
    if (riskDistance <= 0.0)
        return action;

    double progressPrice = 0.0;
    if (positionDirection == CONFIRM_DIR_BULLISH)
    {
        progressPrice = currentBid - positionEntryPrice;
    }
    else if (positionDirection == CONFIRM_DIR_BEARISH)
    {
        progressPrice = positionEntryPrice - currentAsk;
    }
    else
    {
        return action;
    }

    double progressR = progressPrice / riskDistance;

    // 2. Partial Close (+1.0R)
    if (progressR >= 1.0 && !m_hasPartialClosed)
    {
        action.closePartially = true;
        
        double volStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
        if (volStep <= 0.0) volStep = 0.01;
        double rawPartialVol = positionCurrentVolume * 0.50;
        double steps = MathFloor(rawPartialVol / volStep);
        action.partialVolume = steps * volStep;
        
        m_hasPartialClosed = true;
    }

    // 3. Trailing Stop (starts at +1.5R, trailing 1.0 * ATR(14) behind, updates every +0.5R)
    if (progressR >= 1.50)
    {
        double trailingDistance = atr14;
        int currentTier = (int)MathFloor((progressR - 1.50) / 0.50);

        if (currentTier > m_lastTrailingTier || positionCurrentSL == positionOriginalSL)
        {
            double candidateSL = MNS_INVALID_PRICE;
            if (positionDirection == CONFIRM_DIR_BULLISH)
            {
                candidateSL = currentBid - trailingDistance;
                // Never worsen stop: Buy stop can only increase
                if (positionCurrentSL == MNS_INVALID_PRICE || candidateSL > positionCurrentSL)
                {
                    action.newStopLoss = candidateSL;
                    m_lastTrailingTier = currentTier;
                }
            }
            else if (positionDirection == CONFIRM_DIR_BEARISH)
            {
                candidateSL = currentAsk + trailingDistance;
                // Never worsen stop: Sell stop can only decrease
                if (positionCurrentSL == MNS_INVALID_PRICE || candidateSL < positionCurrentSL)
                {
                    action.newStopLoss = candidateSL;
                    m_lastTrailingTier = currentTier;
                }
            }
        }
    }

    return action;
}

#endif // __MNS_RISK_ENGINE_MQH__
