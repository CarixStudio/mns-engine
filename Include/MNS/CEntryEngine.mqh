//+------------------------------------------------------------------+
//|                                                 CEntryEngine.mqh |
//|                              MNS Trading Engine — Module 011     |
//|                                                                  |
//| Purpose:                                                         |
//|   Identifies entry opportunities, filters them by spread & RR,   |
//|   handles expirations/invalidations, and prevents duplicate      |
//|   executions.                                                    |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_ENTRY_ENGINE_MQH__
#define __MNS_ENTRY_ENGINE_MQH__

#include "MNSTypes.mqh"
#include "CConfirmationEngine.mqh"
#include "CObjectiveEngine.mqh"
#include "CStructureEngine.mqh"
#include "CDeliveryStructureEngine.mqh"
#include "CPOIEngine.mqh"

#define MNS_MAX_CONSUMED_SIGNALS 128

//+------------------------------------------------------------------+
//| CEntryEngine Class                                               |
//+------------------------------------------------------------------+
class CEntryEngine {
  private:
    bool m_isInitialized;                                      ///< Initialization status flag.
    SEntrySignal m_activeSignal;                               ///< Current active entry signal.
    datetime m_consumedSignals[MNS_MAX_CONSUMED_SIGNALS];      ///< History of consumed signal timestamps.
    int m_consumedCount;                                       ///< Count of historical signals.
    double m_maxSpreadPoints;                                  ///< Maximum allowed spread in points.

    // Private helper methods
    bool IsSignalAlreadyConsumed(datetime signalId) const;
    bool AddConsumedSignal(datetime signalId);

  public:
    CEntryEngine();
    ~CEntryEngine();

    /// @brief Initializes the Entry Engine with default parameters.
    /// @return True on success.
    bool Initialize(double maxSpreadPoints = 50.0);

    /// @brief Resets the engine state.
    void Reset();

    /// @brief Evaluates active signals and monitors new confirmation triggers on each bar.
    /// @return True if a state change occurred.
    bool Update(const CConfirmationEngine& confirmationEngine,
                const CObjectiveEngine& objectiveEngine,
                const CStructureEngine& structureEngine,
                const CDeliveryStructureEngine& deliveryEngine,
                const CPOIEngine& poiEngine,
                const double& high[],
                const double& low[],
                const double& close[],
                const double& open[],
                const datetime& time[],
                int ratesTotal,
                int prevCalculated,
                double currentSpreadPoints);

    // Query Methods
    SEntrySignal GetActiveSignal() const {
        return m_activeSignal;
    }
    EEntryState GetActiveSignalState() const {
        return m_activeSignal.state;
    }
    bool HasActiveSignal() const {
        return m_activeSignal.state == ENTRY_STATE_ACTIVE;
    }

    /// @brief Marks the active signal as consumed/executed.
    /// @return True on success.
    bool MarkSignalConsumed();

    /// @brief Alias method to mark active signal as executed.
    bool SetActiveSignalExecuted() { return MarkSignalConsumed(); }

    /// @brief Checks if a specific signal ID was already consumed.
    bool IsConsumed(datetime signalId) const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CEntryEngine::CEntryEngine()
    : m_isInitialized(false),
      m_consumedCount(0),
      m_maxSpreadPoints(50.0) {
    m_activeSignal.Reset();
    Reset();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CEntryEngine::~CEntryEngine() {
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CEntryEngine::Initialize(double maxSpreadPoints) {
    m_maxSpreadPoints = maxSpreadPoints;
    m_isInitialized = true;
    Reset();
    return true;
}

//+------------------------------------------------------------------+
//| Reset                                                            |
//+------------------------------------------------------------------+
void CEntryEngine::Reset() {
    m_activeSignal.Reset();
    // Do NOT clear m_consumedSignals history here to prevent duplicates across resets
}

//+------------------------------------------------------------------+
//| Update                                                           |
//+------------------------------------------------------------------+
bool CEntryEngine::Update(const CConfirmationEngine& confirmationEngine,
                          const CObjectiveEngine& objectiveEngine,
                          const CStructureEngine& structureEngine,
                          const CDeliveryStructureEngine& deliveryEngine,
                          const CPOIEngine& poiEngine,
                          const double& high[],
                          const double& low[],
                          const double& close[],
                          const double& open[],
                          const datetime& time[],
                          int ratesTotal,
                          int prevCalculated,
                          double currentSpreadPoints) {
    if (!m_isInitialized)
        return false;

    if (ratesTotal < 5)
        return false;

    double currentPrice = close[1];
    bool stateChanged = false;

    // --- 1. Evaluate/Track Existing Signal ---
    if (m_activeSignal.state == ENTRY_STATE_ACTIVE) {
        bool invalidate = false;
        EEntryState newState = ENTRY_STATE_INVALIDATED;

        // A. Confirmation Engine Invalidation
        if (confirmationEngine.GetConfirmationState() != CONFIRMATION_STATE_CONFIRMED) {
            invalidate = true;
            newState = ENTRY_STATE_INVALIDATED;
        }

        // B. POI Invalidation
        if (!invalidate) {
            bool poiExists = false;
            SPoIDefinition activePoi;
            activePoi.Reset(); // Ensure activePoi is initialized before conditional read below.
            int poiCount = poiEngine.GetPoIsCount();
            for (int i = 0; i < poiCount; i++) {
                SPoIDefinition tempPoi;
                if (poiEngine.GetPoI(i, tempPoi) && tempPoi.id == m_activeSignal.associatedPoiId) {
                    activePoi = tempPoi;
                    poiExists = true;
                    break;
                }
            }
            if (!poiExists || !activePoi.active || activePoi.lifecycle == POI_STATE_INVALIDATED) {
                invalidate = true;
                newState = ENTRY_STATE_INVALIDATED;
            }
        }

        // C. DOL Target Invalidation / RR Invalidation
        if (!invalidate) {
            double dolPrice = objectiveEngine.GetDolPrice();
            if (dolPrice == DBL_MAX || dolPrice == MNS_INVALID_PRICE) {
                invalidate = true;
                newState = ENTRY_STATE_INVALIDATED;
            } else {
                SDolDefinition activeDol = objectiveEngine.GetActiveDol();
                if (MathAbs(m_activeSignal.takeProfit - activeDol.price) > 0.00001) {
                    double riskDist = MathAbs(m_activeSignal.entryPrice - m_activeSignal.stopLoss);
                    double rewardDist = MathAbs(activeDol.price - m_activeSignal.entryPrice);
                    double rr = (riskDist > 0.0) ? (rewardDist / riskDist) : 0.0;
                    if (riskDist == 0.0 || rr < 1.50) {
                        invalidate = true;
                        newState = ENTRY_STATE_CANCELLED;
                    } else {
                        m_activeSignal.takeProfit = activeDol.price;
                    }
                }
            }
        }

        // D. Delivery Invalidation
        if (!invalidate) {
            if (deliveryEngine.GetState().lifecycle == DELIVERY_INVALIDATED) {
                invalidate = true;
                newState = ENTRY_STATE_INVALIDATED;
            }
        }

        // E. MTF Trend Bias Reversal
        if (!invalidate) {
            ETrend trend = structureEngine.GetState().trend;
            bool mtfAlign = false;
            if (m_activeSignal.direction == CONFIRM_DIR_BULLISH && trend != TREND_BEARISH)
                mtfAlign = true;
            else if (m_activeSignal.direction == CONFIRM_DIR_BEARISH && trend != TREND_BULLISH)
                mtfAlign = true;

            if (!mtfAlign) {
                invalidate = true;
                newState = ENTRY_STATE_INVALIDATED;
            }
        }

        // F. Expiration (5 bars)
        if (!invalidate) {
            int triggerIdx = -1;
            for (int k = 1; k < ratesTotal; k++) {
                if (time[k] == m_activeSignal.triggerTime) {
                    triggerIdx = k;
                    break;
                }
            }
            if (triggerIdx == -1 || (triggerIdx - 1) >= 5) {
                invalidate = true;
                newState = ENTRY_STATE_EXPIRED;
            }
        }

        // G. Spread Check
        if (!invalidate) {
            if (currentSpreadPoints > m_maxSpreadPoints) {
                invalidate = true;
                newState = ENTRY_STATE_CANCELLED;
            }
        }

        // H. Risk-Reward Check
        if (!invalidate) {
            double riskDist = MathAbs(m_activeSignal.entryPrice - m_activeSignal.stopLoss);
            double rewardDist = MathAbs(m_activeSignal.takeProfit - m_activeSignal.entryPrice);
            double rr = (riskDist > 0.0) ? (rewardDist / riskDist) : 0.0;
            if (riskDist == 0.0 || rr < 1.50) {
                invalidate = true;
                newState = ENTRY_STATE_CANCELLED;
            }
        }

        if (invalidate) {
            m_activeSignal.state = newState;
            stateChanged = true;
            return true;
        }
    }

    // --- 2. Revert Cleared States to NONE ---
    if (m_activeSignal.state == ENTRY_STATE_INVALIDATED ||
        m_activeSignal.state == ENTRY_STATE_EXPIRED ||
        m_activeSignal.state == ENTRY_STATE_CANCELLED ||
        m_activeSignal.state == ENTRY_STATE_EXECUTED) {
        if (confirmationEngine.GetConfirmationState() != CONFIRMATION_STATE_CONFIRMED) {
            m_activeSignal.Reset();
            stateChanged = true;
        }
    }

    // --- 3. Evaluate New Entry Signal ---
    if (m_activeSignal.state == ENTRY_STATE_NONE) {
        if (confirmationEngine.GetConfirmationState() == CONFIRMATION_STATE_CONFIRMED) {
            datetime triggerTime = confirmationEngine.GetState().triggerTime;

            // Duplicate prevention
            if (!IsSignalAlreadyConsumed(triggerTime)) {
                double triggerPrice = confirmationEngine.GetState().triggerPrice;
                double invalidationLevel = confirmationEngine.GetState().invalidationLevel;
                double dolPrice = objectiveEngine.GetDolPrice();

                // RR check
                double riskDist = MathAbs(triggerPrice - invalidationLevel);
                double rewardDist = MathAbs(dolPrice - triggerPrice);
                double rr = (riskDist > 0.0) ? (rewardDist / riskDist) : 0.0;

                bool isRrValid = (riskDist > 0.0 && rr >= 1.50);
                bool isSpreadValid = (currentSpreadPoints <= m_maxSpreadPoints);

                if (isRrValid && isSpreadValid) {
                    m_activeSignal.Reset();
                    m_activeSignal.id = triggerTime;
                    m_activeSignal.state = ENTRY_STATE_ACTIVE;
                    m_activeSignal.direction = confirmationEngine.GetDirection();
                    m_activeSignal.entryPrice = triggerPrice;
                    m_activeSignal.stopLoss = invalidationLevel;
                    m_activeSignal.takeProfit = dolPrice;
                    m_activeSignal.triggerTime = triggerTime;
                    m_activeSignal.expirationTime = triggerTime + 5 * PeriodSeconds();
                    m_activeSignal.confidenceScore = confirmationEngine.GetConfidenceScore();
                    m_activeSignal.consumed = false;
                    m_activeSignal.associatedPoiId = confirmationEngine.GetState().associatedPoiId;
                    m_activeSignal.associatedSweepId = confirmationEngine.GetState().associatedSweepId;

                    stateChanged = true;
                }
            }
        }
    }

    return stateChanged;
}

//+------------------------------------------------------------------+
//| MarkSignalConsumed                                               |
//+------------------------------------------------------------------+
bool CEntryEngine::MarkSignalConsumed() {
    if (m_activeSignal.state != ENTRY_STATE_ACTIVE)
        return false;

    m_activeSignal.consumed = true;
    m_activeSignal.state = ENTRY_STATE_EXECUTED;
    AddConsumedSignal(m_activeSignal.id);
    return true;
}

//+------------------------------------------------------------------+
//| IsConsumed                                                       |
//+------------------------------------------------------------------+
bool CEntryEngine::IsConsumed(datetime signalId) const {
    return IsSignalAlreadyConsumed(signalId);
}

//+------------------------------------------------------------------+
//| IsSignalAlreadyConsumed                                          |
//+------------------------------------------------------------------+
bool CEntryEngine::IsSignalAlreadyConsumed(datetime signalId) const {
    for (int i = 0; i < m_consumedCount; i++) {
        if (m_consumedSignals[i] == signalId)
            return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| AddConsumedSignal                                                |
//+------------------------------------------------------------------+
bool CEntryEngine::AddConsumedSignal(datetime signalId) {
    if (IsSignalAlreadyConsumed(signalId))
        return false;

    if (m_consumedCount < MNS_MAX_CONSUMED_SIGNALS) {
        m_consumedSignals[m_consumedCount] = signalId;
        m_consumedCount++;
        return true;
    } else {
        // Shift left
        for (int i = 0; i < MNS_MAX_CONSUMED_SIGNALS - 1; i++) {
            m_consumedSignals[i] = m_consumedSignals[i + 1];
        }
        m_consumedSignals[MNS_MAX_CONSUMED_SIGNALS - 1] = signalId;
        return true;
    }
}

#endif // __MNS_ENTRY_ENGINE_MQH__
