//+------------------------------------------------------------------+
//|                                          CConfirmationEngine.mqh |
//|                              MNS Trading Engine — Module 010     |
//|                                                                  |
//| Purpose:                                                         |
//|   Implements the Confirmation Engine to validate setups and      |
//|   manage trade entry filters.                                    |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Evaluate POI touches and transition state to PENDING.        |
//|   - Check mandatory MTF and Delivery Direction alignments.       |
//|   - Check liquidity sweep and rejection wick criteria.           |
//|   - Validate structural triggers (CHoCH/BOS).                    |
//|   - Calculate setup quality confidence scores.                   |
//|   - Monitor invalidation and signal expiration.                  |
//|                                                                  |
//| Version: 1.0                                                     |
//+------------------------------------------------------------------+
#ifndef __MNS_CONFIRMATION_ENGINE_MQH__
#define __MNS_CONFIRMATION_ENGINE_MQH__

#include "MNSCore.mqh"
#include "MNSTypes.mqh"
#include "MNSUtils.mqh"
#include "CSwingDetector.mqh"
#include "CStructureEngine.mqh"
#include "CBreakDetector.mqh"
#include "COrderFlowEngine.mqh"
#include "CDeliveryStructureEngine.mqh"
#include "CLiquidityEngine.mqh"
#include "CPOIEngine.mqh"
#include "CObjectiveEngine.mqh"

//+------------------------------------------------------------------+
//| Class CConfirmationEngine                                        |
//+------------------------------------------------------------------+
class CConfirmationEngine {
  private:
    bool m_isInitialized;       ///< Initialization state flag.
    SConfirmationState m_state; ///< Active confirmation state details.

    // Tracking Variables
    bool m_hasTouchedPoi;          ///< POI touched tracker.
    datetime m_poiTouchTime;       ///< Timestamp of POI touch.
    int m_activePoiId;             ///< ID of the touched POI.
    EPoIType m_activePoiType;      ///< Type of the touched POI.
    double m_poiInvalidationLevel; ///< POI boundary invalidation.

    bool m_hasLiquiditySweep; ///< Liquidity swept tracker.
    datetime m_sweepTime;     ///< Timestamp of the sweep.
    int m_sweepPoolId;        ///< ID of the swept pool.

    double m_minConfidence;        ///< Threshold for validation (default: 60.0).
    double m_minDisplacementRatio; ///< Threshold for displacement (default: 1.5).

    // Internal checkers
    bool EvaluatePoiInteraction(const CPOIEngine& poiEngine, const double& high[], const double& low[], int ratesTotal);
    bool EvaluateLiquiditySweep(const CLiquidityEngine& liquidityEngine, datetime sinceTime);
    bool EvaluateStrongRejection(const double& high[], const double& low[], const double& close[], const double& open[], double currentAtr) const;
    bool EvaluateStructuralTrigger(const CBreakDetector& breakDetector, datetime sinceTime, EStructureBreak& outBreakType, double& outBreakPrice, datetime& outBreakTime) const;

    double CalculateConfidence(const CStructureEngine& structureEngine,
                               const CPOIEngine& poiEngine,
                               const double& high[],
                               const double& low[],
                               const double& close[],
                               const double& open[],
                               const datetime& time[],
                               int ratesTotal,
                               double currentAtr,
                               EConfirmationDirection dir) const;

  public:
    CConfirmationEngine();
    ~CConfirmationEngine();

    /// @brief Initializes engine variables.
    /// @return True on success.
    bool Initialize();

    /// @brief Resets the engine state and trackers.
    void Reset();

    /// @brief Updates confirmation checklist and validates setups.
    /// @return True on successful state change.
    bool Update(const CSwingDetector& swingDetector,
                const CStructureEngine& structureEngine,
                const CBreakDetector& breakDetector,
                const COrderFlowEngine& orderFlowEngine,
                const CDeliveryStructureEngine& deliveryEngine,
                const CLiquidityEngine& liquidityEngine,
                const CPOIEngine& poiEngine,
                const CObjectiveEngine& objectiveEngine,
                const double& high[],
                const double& low[],
                const double& close[],
                const double& open[],
                const datetime& time[],
                int ratesTotal,
                int prevCalculated,
                double currentAtr);

    /// @brief Gets the active confirmation state structure.
    SConfirmationState GetState() const {
        return m_state;
    }

    /// @brief Gets the active confirmation state enum.
    EConfirmationState GetConfirmationState() const {
        return m_state.state;
    }

    /// @brief Gets the active confirmation direction.
    EConfirmationDirection GetDirection() const {
        return m_state.direction;
    }

    /// @brief Gets the confirmation confidence score.
    double GetConfidenceScore() const {
        return m_state.confidenceScore;
    }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CConfirmationEngine::CConfirmationEngine() : m_isInitialized(false) {
    Reset();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CConfirmationEngine::~CConfirmationEngine() {
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CConfirmationEngine::Initialize() {
    m_minConfidence = 60.0;
    m_minDisplacementRatio = 1.5;
    m_isInitialized = true;
    Reset();
    return true;
}

//+------------------------------------------------------------------+
//| Reset                                                            |
//+------------------------------------------------------------------+
void CConfirmationEngine::Reset() {
    m_state.Reset();
    m_hasTouchedPoi = false;
    m_poiTouchTime = 0;
    m_activePoiId = 0;
    m_activePoiType = POI_NONE;
    m_poiInvalidationLevel = MNS_INVALID_PRICE;

    m_hasLiquiditySweep = false;
    m_sweepTime = 0;
    m_sweepPoolId = 0;
}

//+------------------------------------------------------------------+
//| Update                                                           |
//+------------------------------------------------------------------+
bool CConfirmationEngine::Update(const CSwingDetector& swingDetector,
                                 const CStructureEngine& structureEngine,
                                 const CBreakDetector& breakDetector,
                                 const COrderFlowEngine& orderFlowEngine,
                                 const CDeliveryStructureEngine& deliveryEngine,
                                 const CLiquidityEngine& liquidityEngine,
                                 const CPOIEngine& poiEngine,
                                 const CObjectiveEngine& objectiveEngine,
                                 const double& high[],
                                 const double& low[],
                                 const double& close[],
                                 const double& open[],
                                 const datetime& time[],
                                 int ratesTotal,
                                 int prevCalculated,
                                 double currentAtr) {
    if (!m_isInitialized)
        return false;

    if (ratesTotal < 5)
        return false;

    double currentPrice = close[1];
    datetime currentTime = time[1];
    bool stateChanged = false;

    // --- 1. Evaluate Invalidation & Expiration on Active Setup ---
    if (m_state.state == CONFIRMATION_STATE_PENDING || m_state.state == CONFIRMATION_STATE_CONFIRMED) {
        bool invalidate = false;

        // A. POI Invalidation (POI deactivated or closed beyond invalidation level)
        SPoIDefinition activePoi;
        activePoi.Reset();
        bool poiExists = false;
        int poiCount = poiEngine.GetPoIsCount();
        for (int i = 0; i < poiCount; i++) {
            SPoIDefinition tempPoi;
            if (poiEngine.GetPoI(i, tempPoi) && tempPoi.id == m_activePoiId) {
                activePoi = tempPoi;
                poiExists = true;
                break;
            }
        }
        if (!poiExists || !activePoi.active || activePoi.lifecycle == POI_STATE_INVALIDATED) {
            invalidate = true;
        }

        // B. Body Close past POI Invalidation Level
        if (m_state.direction == CONFIRM_DIR_BULLISH) {
            if (currentPrice < m_poiInvalidationLevel)
                invalidate = true;
        } else if (m_state.direction == CONFIRM_DIR_BEARISH) {
            if (currentPrice > m_poiInvalidationLevel)
                invalidate = true;
        }

        // C. DOL Invalidation (Target hit or changed direction)
        double dolPrice = objectiveEngine.GetDolPrice();
        if (dolPrice == DBL_MAX || dolPrice == MNS_INVALID_PRICE) {
            invalidate = true;
        } else {
            SDolDefinition activeDol = objectiveEngine.GetActiveDol();
            if (m_state.direction == CONFIRM_DIR_BULLISH && activeDol.price < currentPrice) {
                invalidate = true;
            } else if (m_state.direction == CONFIRM_DIR_BEARISH && activeDol.price > currentPrice) {
                invalidate = true;
            }
        }

        // D. Body Close past Confirming Structure Invalidation Level (only for CONFIRMED signals)
        if (m_state.state == CONFIRMATION_STATE_CONFIRMED) {
            if (m_state.direction == CONFIRM_DIR_BULLISH && currentPrice < m_state.invalidationLevel) {
                invalidate = true;
            } else if (m_state.direction == CONFIRM_DIR_BEARISH && currentPrice > m_state.invalidationLevel) {
                invalidate = true;
            }

            // E. Expiration check (5 bars limit on execution timeframe)
            int barsPassed = 0;
            for (int k = 1; k < ratesTotal; k++) {
                if (time[k] == m_state.triggerTime) {
                    barsPassed = k - 1;
                    break;
                }
            }
            if (barsPassed >= 5) {
                Reset();
                return true;
            }
        }

        if (invalidate) {
            Reset();
            m_state.state = CONFIRMATION_STATE_INVALIDATED;
            return true;
        }
    }

    // --- 2. Evaluate POI Touch / Entry (NONE -> PENDING) ---
    if (m_state.state == CONFIRMATION_STATE_NONE || m_state.state == CONFIRMATION_STATE_INVALIDATED) {
        int poiCount = poiEngine.GetPoIsCount();
        for (int i = 0; i < poiCount; i++) {
            SPoIDefinition poi;
            if (poiEngine.GetPoI(i, poi) && poi.active && poi.lifecycle != POI_STATE_INVALIDATED) {
                bool touched = false;
                EConfirmationDirection dir = CONFIRM_DIR_NEUTRAL;

                if (poi.type == POI_OB_BULLISH || poi.type == POI_BREAKER_BULLISH || poi.type == POI_MITIGATION_BULLISH || poi.type == POI_FVG_BULLISH) {
                    if (low[1] <= poi.upperPrice && high[1] >= poi.lowerPrice) {
                        touched = true;
                        dir = CONFIRM_DIR_BULLISH;
                    }
                } else if (poi.type == POI_OB_BEARISH || poi.type == POI_BREAKER_BEARISH || poi.type == POI_MITIGATION_BEARISH || poi.type == POI_FVG_BEARISH) {
                    if (high[1] >= poi.lowerPrice && low[1] <= poi.upperPrice) {
                        touched = true;
                        dir = CONFIRM_DIR_BEARISH;
                    }
                }

                if (touched) {
                    m_state.Reset();
                    m_state.state = CONFIRMATION_STATE_PENDING;
                    m_state.direction = dir;
                    m_state.hasPoiInteraction = true;
                    m_state.associatedPoiId = poi.id;
                    m_state.associatedPoiType = poi.type;

                    m_activePoiId = poi.id;
                    m_activePoiType = poi.type;
                    m_poiTouchTime = currentTime;
                    m_poiInvalidationLevel = poi.invalidationLevel;

                    m_hasTouchedPoi = true;
                    m_hasLiquiditySweep = false;
                    m_sweepTime = 0;
                    m_sweepPoolId = 0;

                    stateChanged = true;
                    break;
                }
            }
        }
    }

    // --- 3. Evaluate Validation Checklist (PENDING -> CONFIRMED) ---
    if (m_state.state == CONFIRMATION_STATE_PENDING) {
        EConfirmationDirection dir = m_state.direction;

        // A. MTF Agreement
        ETrend trend = structureEngine.GetState().trend;
        bool mtfAlign = false;
        if (dir == CONFIRM_DIR_BULLISH && trend != TREND_BEARISH)
            mtfAlign = true;
        else if (dir == CONFIRM_DIR_BEARISH && trend != TREND_BULLISH)
            mtfAlign = true;

        // B. Delivery Direction Alignment
        EDeliveryDirection delDir = deliveryEngine.GetDirection();
        bool delAlign = false;
        if (dir == CONFIRM_DIR_BULLISH && delDir == DELIVERY_DIR_BULLISH)
            delAlign = true;
        else if (dir == CONFIRM_DIR_BEARISH && delDir == DELIVERY_DIR_BEARISH)
            delAlign = true;

        // C. Liquidity Sweep OR Strong Rejection
        if (!m_hasLiquiditySweep) {
            m_hasLiquiditySweep = EvaluateLiquiditySweep(liquidityEngine, m_poiTouchTime);
        }

        bool hasRejection = EvaluateStrongRejection(high, low, close, open, currentAtr);
        bool sweepOrReject = m_hasLiquiditySweep || hasRejection;

        // D. Structural Trigger (CHoCH or BOS)
        EStructureBreak breakType = BREAK_NONE;
        double breakPrice = MNS_INVALID_PRICE;
        datetime breakTime = MNS_INVALID_TIME;
        bool structuralTrigger = EvaluateStructuralTrigger(breakDetector, m_poiTouchTime, breakType, breakPrice, breakTime);

        if (mtfAlign && delAlign && sweepOrReject && structuralTrigger) {
            m_state.state = CONFIRMATION_STATE_CONFIRMED;
            m_state.triggerPrice = currentPrice;
            m_state.triggerTime = currentTime;
            m_state.breakPrice = breakPrice;
            m_state.breakTime = breakTime;
            m_state.hasChochTrigger = (breakType == BREAK_CHOCH);
            m_state.hasBosTrigger = (breakType == BREAK_BOS || breakType == BREAK_INTERNAL_BOS);
            m_state.hasLiquidityEvent = m_hasLiquiditySweep;
            m_state.hasStrongRejection = hasRejection;
            m_state.associatedSweepId = m_sweepPoolId;

            SStructureBreak sb;
            int breakCount = breakDetector.GetBreakCount();
            for (int k = 0; k < breakCount; k++) {
                sb = breakDetector.GetBreak(k);
                if (sb.time == breakTime) {
                    m_state.invalidationLevel = sb.brokenSwing.price;
                    break;
                }
            }
            if (m_state.invalidationLevel == MNS_INVALID_PRICE) {
                m_state.invalidationLevel = m_poiInvalidationLevel;
            }

            m_state.confidenceScore = CalculateConfidence(structureEngine, poiEngine, high, low, close, open, time, ratesTotal, currentAtr, dir);
            stateChanged = true;
        }
    }

    return stateChanged;
}

//+------------------------------------------------------------------+
//| EvaluateLiquiditySweep                                           |
//+------------------------------------------------------------------+
bool CConfirmationEngine::EvaluateLiquiditySweep(const CLiquidityEngine& liquidityEngine, datetime sinceTime) {
    int poolCount = liquidityEngine.GetPoolsCount();
    for (int i = 0; i < poolCount; i++) {
        SLiquidityPool pool;
        if (liquidityEngine.GetPool(i, pool)) {
            if (pool.swept && pool.sweptTime >= sinceTime) {
                if (m_state.direction == CONFIRM_DIR_BULLISH && pool.type == LIQUIDITY_SSL) {
                    m_sweepPoolId = pool.id;
                    m_sweepTime = pool.sweptTime;
                    return true;
                } else if (m_state.direction == CONFIRM_DIR_BEARISH && pool.type == LIQUIDITY_BSL) {
                    m_sweepPoolId = pool.id;
                    m_sweepTime = pool.sweptTime;
                    return true;
                }
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| EvaluateStrongRejection                                          |
//+------------------------------------------------------------------+
bool CConfirmationEngine::EvaluateStrongRejection(const double& high[],
                                                  const double& low[],
                                                  const double& close[],
                                                  const double& open[],
                                                  double currentAtr) const {
    double range = high[1] - low[1];
    if (range <= 0.0)
        return false;

    // Sanity check: Reject extremely tiny candles as confirmation
    if (range < 0.50 * currentAtr)
        return false;

    if (m_state.direction == CONFIRM_DIR_BULLISH) {
        double lowerWick = MathMin(open[1], close[1]) - low[1];
        double lowerWickRatio = lowerWick / range;
        double closeLocation = (close[1] - low[1]) / range;

        if (lowerWickRatio >= 0.50 && closeLocation >= 0.70 && close[1] > open[1]) {
            return true;
        }
    } else if (m_state.direction == CONFIRM_DIR_BEARISH) {
        double upperWick = high[1] - MathMax(open[1], close[1]);
        double upperWickRatio = upperWick / range;
        double closeLocation = (high[1] - close[1]) / range;

        if (upperWickRatio >= 0.50 && closeLocation >= 0.70 && close[1] < open[1]) {
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| EvaluateStructuralTrigger                                        |
//+------------------------------------------------------------------+
bool CConfirmationEngine::EvaluateStructuralTrigger(const CBreakDetector& breakDetector,
                                                    datetime sinceTime,
                                                    EStructureBreak& outBreakType,
                                                    double& outBreakPrice,
                                                    datetime& outBreakTime) const {
    int breakCount = breakDetector.GetBreakCount();
    for (int i = 0; i < breakCount; i++) {
        SStructureBreak sb = breakDetector.GetBreak(i);
        if (sb.isConfirmed && sb.time >= sinceTime) {
            if (m_state.direction == CONFIRM_DIR_BULLISH) {
                if (sb.brokenSwing.type == SWING_HIGH && (sb.breakType == BREAK_CHOCH || sb.breakType == BREAK_BOS || sb.breakType == BREAK_INTERNAL_BOS)) {
                    outBreakType = sb.breakType;
                    outBreakPrice = sb.price;
                    outBreakTime = sb.time;
                    return true;
                }
            } else if (m_state.direction == CONFIRM_DIR_BEARISH) {
                if (sb.brokenSwing.type == SWING_LOW && (sb.breakType == BREAK_CHOCH || sb.breakType == BREAK_BOS || sb.breakType == BREAK_INTERNAL_BOS)) {
                    outBreakType = sb.breakType;
                    outBreakPrice = sb.price;
                    outBreakTime = sb.time;
                    return true;
                }
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| CalculateConfidence                                              |
//+------------------------------------------------------------------+
double CConfirmationEngine::CalculateConfidence(const CStructureEngine& structureEngine,
                                                const CPOIEngine& poiEngine,
                                                const double& high[],
                                                const double& low[],
                                                const double& close[],
                                                const double& open[],
                                                const datetime& time[],
                                                int ratesTotal,
                                                double currentAtr,
                                                EConfirmationDirection dir) const {
    double score = 60.0;

    // 1. POI Confluence (+10 pts)
    SPoIDefinition activePoi;
    activePoi.Reset();
    bool poiExists = false;
    int poiCount = poiEngine.GetPoIsCount();
    for (int i = 0; i < poiCount; i++) {
        SPoIDefinition tempPoi;
        if (poiEngine.GetPoI(i, tempPoi) && tempPoi.id == m_activePoiId) {
            activePoi = tempPoi;
            poiExists = true;
            break;
        }
    }
    if (poiExists && (activePoi.type == POI_OB_BULLISH || activePoi.type == POI_OB_BEARISH)) {
        for (int i = 0; i < poiCount; i++) {
            SPoIDefinition otherPoi;
            if (poiEngine.GetPoI(i, otherPoi) && otherPoi.active && (otherPoi.type == POI_FVG_BULLISH || otherPoi.type == POI_FVG_BEARISH)) {
                if (otherPoi.lowerPrice < activePoi.upperPrice && otherPoi.upperPrice > activePoi.lowerPrice) {
                    score += 10.0;
                    break;
                }
            }
        }
    }

    // 2. Premium / Discount (+10 pts)
    SSwingPoint lastHigh = structureEngine.GetState().lastSwingHigh;
    SSwingPoint lastLow = structureEngine.GetState().lastSwingLow;
    if (lastHigh.isConfirmed && lastLow.isConfirmed && lastHigh.price > lastLow.price) {
        double range = lastHigh.price - lastLow.price;
        double currentPrice = close[1];
        double pct = (currentPrice - lastLow.price) / range;
        if (dir == CONFIRM_DIR_BULLISH && pct < 0.50) {
            score += 10.0;
        } else if (dir == CONFIRM_DIR_BEARISH && pct > 0.50) {
            score += 10.0;
        }
    }

    // 3. Session Alignment (tiered: up to +10 pts)
    //    London/NY overlap (13-16 GMT) = highest-quality liquidity window: +10
    //    London-only (08-13 GMT) or NY-only (16-21 GMT)                   : +7
    //    Tokyo (00-08 GMT) — thinner liquidity                            : +4
    //    Off-hours (21-00 GMT)                                            : +0
    MqlDateTime dt;
    TimeToStruct(time[1], dt);
    if (dt.hour >= 13 && dt.hour < 16) {
        score += 10.0; // London/NY overlap — peak institutional activity
    } else if ((dt.hour >= 8 && dt.hour < 13) || (dt.hour >= 16 && dt.hour < 21)) {
        score += 7.0;  // London-only or NY-only
    } else if (dt.hour >= 0 && dt.hour < 8) {
        score += 4.0;  // Tokyo session — reduced but still active
    }
    // 21:00–00:00 GMT: off-hours, no session bonus

    // 4. Displacement Conviction (+10 pts)
    int breakBarIdx = -1;
    for (int k = 1; k < ratesTotal; k++) {
        if (time[k] == m_state.breakTime) {
            breakBarIdx = k;
            break;
        }
    }
    if (breakBarIdx != -1 && currentAtr > 0.0) {
        double bodySize = MathAbs(close[breakBarIdx] - open[breakBarIdx]);
        double ratio = bodySize / currentAtr;
        if (ratio >= 2.0) {
            score += 10.0;
        }
    }

    if (score > 100.0)
        score = 100.0;
    return score;
}

#endif // __MNS_CONFIRMATION_ENGINE_MQH__
