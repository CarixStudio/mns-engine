//+------------------------------------------------------------------+
//|                                             CObjectiveEngine.mqh |
//|                              MNS Trading Engine — Module 009     |
//|                                                                  |
//| Purpose:                                                         |
//|   Identifies, scores, and tracks the primary Draw on Liquidity    |
//|   (DOL) / market target for the MNS engine without broker APIs.  |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Released                                                |
//+------------------------------------------------------------------+
#ifndef __MNS_OBJECTIVE_ENGINE_MQH__
#define __MNS_OBJECTIVE_ENGINE_MQH__

#include "MNSTypes.mqh"
#include "CSwingDetector.mqh"
#include "CStructureEngine.mqh"
#include "CBreakDetector.mqh"
#include "COrderFlowEngine.mqh"
#include "CDeliveryStructureEngine.mqh"
#include "CLiquidityEngine.mqh"
#include "CPOIEngine.mqh"

//+------------------------------------------------------------------+
//| CObjectiveEngine Class                                           |
//+------------------------------------------------------------------+
class CObjectiveEngine {
  private:
    bool m_isInitialized;            ///< Lifecycle initialization watermark.
    SDolDefinition m_activeDol;      ///< Active Draw on Liquidity definition.
    SDolDefinition m_candidates[64]; ///< List of current scanned candidates.
    int m_candidatesCount;           ///< Candidate count.

    // Private helper methods
    void GatherCandidates(const CSwingDetector& swingDetector,
                          const CLiquidityEngine& liquidityEngine,
                          const CPOIEngine& poiEngine,
                          const double& high[],
                          const double& low[],
                          const double& close[],
                          const double& open[],
                          const datetime& time[],
                          int ratesTotal);
    void ScoreCandidates(const CStructureEngine& structureEngine,
                         const COrderFlowEngine& orderFlowEngine,
                         const CDeliveryStructureEngine& deliveryEngine,
                         const CSwingDetector& swingDetector,
                         const double& high[],
                         const double& low[],
                         const datetime& time[],
                         int ratesTotal,
                         double currentAtr,
                         double currentPrice);
    double CalculateCandidateScore(const SDolDefinition& candidate,
                                   const CStructureEngine& structureEngine,
                                   const COrderFlowEngine& orderFlowEngine,
                                   const CDeliveryStructureEngine& deliveryEngine,
                                   const CSwingDetector& swingDetector,
                                   const double& high[],
                                   const double& low[],
                                   const datetime& time[],
                                   int ratesTotal,
                                   double currentAtr,
                                   double currentPrice) const;
    bool IsPriceSweptToday(double price,
                           bool isBullishTarget,
                           const double& high[],
                           const double& low[],
                           const datetime& time[],
                           int ratesTotal) const;
    void AddCandidate(double price, EDolType type);

  public:
    CObjectiveEngine();
    ~CObjectiveEngine();

    /// @brief Initializes engine variables.
    /// @return True on success.
    bool Initialize();

    /// @brief Resets the engine state.
    void Reset();

    /// @brief Evaluates candidate targets, scores them, and updates the active DOL.
    /// @return True if active DOL changed.
    bool Update(const CSwingDetector& swingDetector,
                const CStructureEngine& structureEngine,
                const CBreakDetector& breakDetector,
                const COrderFlowEngine& orderFlowEngine,
                const CDeliveryStructureEngine& deliveryEngine,
                const CLiquidityEngine& liquidityEngine,
                const CPOIEngine& poiEngine,
                const double& high[],
                const double& low[],
                const double& close[],
                const double& open[],
                const datetime& time[],
                int ratesTotal,
                int prevCalculated,
                double currentAtr);

    // Query Methods
    SDolDefinition GetActiveDol() const {
        return m_activeDol;
    }
    double GetDolPrice() const {
        return m_activeDol.price;
    }
    EDolType GetDolType() const {
        return m_activeDol.type;
    }
    double GetDolScore() const {
        return m_activeDol.score;
    }
    int GetCandidateCount() const {
        return m_candidatesCount;
    }
    bool GetCandidate(int index, SDolDefinition& outCandidate) const;

    /// @brief Overrides the active DOL target for testing.
    void OverrideDol(bool active, double price, EDolType type, double score)
    {
        m_activeDol.active = active;
        m_activeDol.price = price;
        m_activeDol.type = type;
        m_activeDol.score = score;
    }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CObjectiveEngine::CObjectiveEngine()
    : m_isInitialized(false),
      m_candidatesCount(0) {
    Reset();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CObjectiveEngine::~CObjectiveEngine() {
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CObjectiveEngine::Initialize() {
    Reset();
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Reset                                                            |
//+------------------------------------------------------------------+
void CObjectiveEngine::Reset() {
    m_activeDol.Reset();
    m_activeDol.price = DBL_MAX; // MNS_INVALID_PRICE marker
    m_candidatesCount = 0;
    for (int i = 0; i < 64; i++)
        m_candidates[i].Reset();
}

//+------------------------------------------------------------------+
//| Update                                                           |
//+------------------------------------------------------------------+
bool CObjectiveEngine::Update(const CSwingDetector& swingDetector,
                              const CStructureEngine& structureEngine,
                              const CBreakDetector& breakDetector,
                              const COrderFlowEngine& orderFlowEngine,
                              const CDeliveryStructureEngine& deliveryEngine,
                              const CLiquidityEngine& liquidityEngine,
                              const CPOIEngine& poiEngine,
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

    // 1. Gather all candidates
    GatherCandidates(swingDetector, liquidityEngine, poiEngine, high, low, close, open, time, ratesTotal);

    // 2. Score candidates
    ScoreCandidates(structureEngine, orderFlowEngine, deliveryEngine, swingDetector, high, low, time, ratesTotal, currentAtr, currentPrice);

    // 3. Find the best candidate with a score >= 60
    double bestScore = 0.0;
    int bestIdx = -1;
    for (int i = 0; i < m_candidatesCount; i++) {
        if (m_candidates[i].score >= 60.0 && m_candidates[i].score > bestScore) {
            bestScore = m_candidates[i].score;
            bestIdx = i;
        }
    }

    bool changed = false;

    // 4. Handle invalidation / consumption on active DOL
    if (m_activeDol.active && m_activeDol.price != DBL_MAX) {
        bool consumed = false;
        bool dirChanged = false;

        // Check consumption: did current completed bar cross the target?
        bool isBullishTarget = (m_activeDol.type == DOL_EXTERNAL_SWING && m_activeDol.price > currentPrice) ||
                               (m_activeDol.type == DOL_EQH_EQL && m_activeDol.price > currentPrice) ||
                               (m_activeDol.type == DOL_PREV_DAY_HL && m_activeDol.price > currentPrice) ||
                               (m_activeDol.type == DOL_PREV_WEEK_HL && m_activeDol.price > currentPrice) ||
                               (m_activeDol.type == DOL_SESSION_HL && m_activeDol.price > currentPrice);

        if (isBullishTarget) {
            if (high[1] >= m_activeDol.price)
                consumed = true;
        } else {
            if (low[1] <= m_activeDol.price)
                consumed = true;
        }

        // Check direction change alignment
        EDeliveryDirection activeDelDir = deliveryEngine.GetDirection();
        if (activeDelDir != DELIVERY_DIR_NEUTRAL) {
            if (isBullishTarget && activeDelDir == DELIVERY_DIR_BEARISH)
                dirChanged = true;
            else if (!isBullishTarget && activeDelDir == DELIVERY_DIR_BULLISH)
                dirChanged = true;
        }

        if (consumed || dirChanged) {
            m_activeDol.Reset();
            m_activeDol.price = DBL_MAX;
            changed = true;
        }
    }

    // 5. Select or replace active DOL
    if (!m_activeDol.active || m_activeDol.price == DBL_MAX) {
        if (bestIdx != -1) {
            m_activeDol = m_candidates[bestIdx];
            m_activeDol.active = true;
            m_activeDol.createdTime = time[1];
            changed = true;
        }
    } else {
        // Try replacing with best candidate using hysteresis (Advantage >= 15 pts)
        if (bestIdx != -1) {
            SDolDefinition bestCand = m_candidates[bestIdx];
            if (bestCand.score >= m_activeDol.score + 15.0) {
                m_activeDol = bestCand;
                m_activeDol.active = true;
                m_activeDol.createdTime = time[1];
                changed = true;
            }
        }
    }

    return changed;
}

//+------------------------------------------------------------------+
//| Gathers candidate targets from all available engines & structures|
//+------------------------------------------------------------------+
void CObjectiveEngine::GatherCandidates(const CSwingDetector& swingDetector,
                                        const CLiquidityEngine& liquidityEngine,
                                        const CPOIEngine& poiEngine,
                                        const double& high[],
                                        const double& low[],
                                        const double& close[],
                                        const double& open[],
                                        const datetime& time[],
                                        int ratesTotal) {
    m_candidatesCount = 0;

    // 1. Gather Liquidity pools from CLiquidityEngine
    int poolCount = liquidityEngine.GetPoolsCount();
    for (int i = 0; i < poolCount; i++) {
        SLiquidityPool pool;
        if (liquidityEngine.GetPool(i, pool)) {
            if (pool.active && pool.lifecycle == LIQ_ACTIVE) {
                AddCandidate(pool.level, DOL_EQH_EQL);
            }
        }
    }

    // 2. Gather External Swings from CSwingDetector
    int extCount = swingDetector.GetExternalSwingCount();
    for (int i = 0; i < extCount; i++) {
        SSwingPoint sw = swingDetector.GetExternalSwing(i);
        if (sw.isConfirmed) {
            AddCandidate(sw.price, DOL_EXTERNAL_SWING);
        }
    }

    // 3. Scan Previous Day High/Low
    if (ratesTotal > 5) {
        MqlDateTime dt1;
        TimeToStruct(time[1], dt1);
        int dayStartIdx = -1;
        int dayEndIdx = -1;

        // Loop backwards to find day boundaries
        for (int j = 2; j < ratesTotal - 1; j++) {
            MqlDateTime dtJ;
            TimeToStruct(time[j], dtJ);
            if (dtJ.day != dt1.day) {
                if (dayStartIdx == -1) {
                    dayStartIdx = j;
                } else {
                    MqlDateTime dtStart;
                    TimeToStruct(time[dayStartIdx], dtStart);
                    if (dtJ.day != dtStart.day) {
                        dayEndIdx = j;
                        break;
                    }
                }
            }
        }

        if (dayStartIdx != -1) {
            int endIdx = (dayEndIdx != -1) ? dayEndIdx : (ratesTotal - 1);
            double maxHigh = -DBL_MAX;
            double minLow = DBL_MAX;
            for (int k = dayStartIdx; k < endIdx; k++) {
                if (high[k] > maxHigh)
                    maxHigh = high[k];
                if (low[k] < minLow)
                    minLow = low[k];
            }
            if (maxHigh != -DBL_MAX)
                AddCandidate(maxHigh, DOL_PREV_DAY_HL);
            if (minLow != DBL_MAX)
                AddCandidate(minLow, DOL_PREV_DAY_HL);
        }
    }

    // 4. Scan Session High/Low — today's London (8-16 GMT) and NY (13-21 GMT) only
    //    We restrict to the current calendar day to avoid stale multi-day session
    //    extremes influencing the active DOL target.
    if (ratesTotal > 5) {
        double lonHigh = -DBL_MAX, lonLow = DBL_MAX;
        double nyHigh = -DBL_MAX, nyLow = DBL_MAX;

        // Establish today's reference date from bar[1] (last closed bar)
        MqlDateTime refDt;
        TimeToStruct(time[1], refDt);

        // Scan backwards — cap at 300 bars for safety on M1 charts.
        // Break as soon as we step into a prior day (arrays are timeseries).
        int scanDepth = MathMin(ratesTotal - 1, 300);
        for (int j = 1; j <= scanDepth; j++) {
            MqlDateTime dt;
            TimeToStruct(time[j], dt);

            // Stop as soon as the bar belongs to a prior calendar day
            if (dt.day_of_year != refDt.day_of_year || dt.year != refDt.year)
                break;

            if (dt.hour >= 8 && dt.hour < 16) // London session
            {
                if (high[j] > lonHigh) lonHigh = high[j];
                if (low[j] < lonLow)  lonLow  = low[j];
            }
            if (dt.hour >= 13 && dt.hour < 21) // NY session
            {
                if (high[j] > nyHigh) nyHigh = high[j];
                if (low[j] < nyLow)   nyLow  = low[j];
            }
        }
        if (lonHigh != -DBL_MAX) AddCandidate(lonHigh, DOL_SESSION_HL);
        if (lonLow  !=  DBL_MAX) AddCandidate(lonLow,  DOL_SESSION_HL);
        if (nyHigh  != -DBL_MAX) AddCandidate(nyHigh,  DOL_SESSION_HL);
        if (nyLow   !=  DBL_MAX) AddCandidate(nyLow,   DOL_SESSION_HL);
    }

    // 5. Gather POI / FVG / OB midpoints from CPOIEngine
    int poiCount = poiEngine.GetPoIsCount();
    for (int i = 0; i < poiCount; i++) {
        SPoIDefinition poi;
        if (poiEngine.GetPoI(i, poi) && poi.active) {
            double midpoint = (poi.upperPrice + poi.lowerPrice) / 2.0;
            if (poi.type == POI_FVG_BULLISH || poi.type == POI_FVG_BEARISH) {
                AddCandidate(midpoint, DOL_FVG_MIDPOINT);
            } else {
                AddCandidate(midpoint, DOL_OB_MIDPOINT);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Adds a unique candidate price target                             |
//+------------------------------------------------------------------+
void CObjectiveEngine::AddCandidate(double price, EDolType type) {
    if (price == 0.0 || price == DBL_MAX)
        return;

    // Check uniqueness within small tolerance
    double epsilon = 2.0 * _Point;
    for (int i = 0; i < m_candidatesCount; i++) {
        if (m_candidates[i].type == type && MathAbs(m_candidates[i].price - price) <= epsilon) {
            return;
        }
    }

    if (m_candidatesCount < 64) {
        m_candidates[m_candidatesCount].Reset();
        m_candidates[m_candidatesCount].price = price;
        m_candidates[m_candidatesCount].type = type;
        m_candidatesCount++;
    }
}

//+------------------------------------------------------------------+
//| Scores candidates                                                |
//+------------------------------------------------------------------+
void CObjectiveEngine::ScoreCandidates(const CStructureEngine& structureEngine,
                                       const COrderFlowEngine& orderFlowEngine,
                                       const CDeliveryStructureEngine& deliveryEngine,
                                       const CSwingDetector& swingDetector,
                                       const double& high[],
                                       const double& low[],
                                       const datetime& time[],
                                       int ratesTotal,
                                       double currentAtr,
                                       double currentPrice) {
    for (int i = 0; i < m_candidatesCount; i++) {
        m_candidates[i].score = CalculateCandidateScore(m_candidates[i], structureEngine, orderFlowEngine, deliveryEngine, swingDetector, high, low, time, ratesTotal, currentAtr, currentPrice);
    }
}

//+------------------------------------------------------------------+
//| Computes candidate selection score                               |
//+------------------------------------------------------------------+
double CObjectiveEngine::CalculateCandidateScore(const SDolDefinition& candidate,
                                                 const CStructureEngine& structureEngine,
                                                 const COrderFlowEngine& orderFlowEngine,
                                                 const CDeliveryStructureEngine& deliveryEngine,
                                                 const CSwingDetector& swingDetector,
                                                 const double& high[],
                                                 const double& low[],
                                                 const datetime& time[],
                                                 int ratesTotal,
                                                 double currentAtr,
                                                 double currentPrice) const {
    double score = 0.0;
    bool isBullishTarget = (candidate.price > currentPrice);

    // 1. Direction Compatibility (25 pts)
    EDeliveryDirection delDir = deliveryEngine.GetDirection();
    EOrderFlowDirection ofDir = orderFlowEngine.GetDirection();
    ETrend trend = structureEngine.GetState().trend;

    bool isBullishBias = (delDir == DELIVERY_DIR_BULLISH) ||
                         (delDir == DELIVERY_DIR_NEUTRAL && ofDir == ORDER_FLOW_DIR_BULLISH) ||
                         (delDir == DELIVERY_DIR_NEUTRAL && ofDir == ORDER_FLOW_DIR_NEUTRAL && trend == TREND_BULLISH);

    bool isBearishBias = (delDir == DELIVERY_DIR_BEARISH) ||
                         (delDir == DELIVERY_DIR_NEUTRAL && ofDir == ORDER_FLOW_DIR_BEARISH) ||
                         (delDir == DELIVERY_DIR_NEUTRAL && ofDir == ORDER_FLOW_DIR_NEUTRAL && trend == TREND_BEARISH);

    if ((isBullishTarget && isBullishBias) || (!isBullishTarget && isBearishBias)) {
        score += 25.0;
    }

    // 2. Liquidity Strength (20 pts)
    if (candidate.type == DOL_EQH_EQL || candidate.type == DOL_EXTERNAL_SWING)
        score += 20.0;
    else if (candidate.type == DOL_UNMITIGATED_EXT || candidate.type == DOL_PREV_WEEK_HL || candidate.type == DOL_PREV_DAY_HL)
        score += 10.0;
    else
        score += 5.0; // FVG / OB / Equilibrium midpoints

    // 3. HTF Significance (15 pts)
    if (candidate.type == DOL_PREV_WEEK_HL || candidate.type == DOL_EXTERNAL_SWING)
        score += 15.0;
    else if (candidate.type == DOL_PREV_DAY_HL || candidate.type == DOL_SESSION_HL)
        score += 10.0;
    else
        score += 5.0;

    // 4. Freshness (10 pts)
    bool swept = IsPriceSweptToday(candidate.price, isBullishTarget, high, low, time, ratesTotal);
    if (swept) {
        return 0.0;
    }
    score += 10.0; // Default fresh target for offline scans.

    // 5. Structural Significance (10 pts)
    if (candidate.type == DOL_EXTERNAL_SWING || candidate.type == DOL_EQH_EQL)
        score += 10.0;
    else
        score += 5.0;

    // 6. Distance Feasibility (5 pts)
    if (currentAtr > 0.0) {
        double dist = MathAbs(candidate.price - currentPrice);
        double atrMult = dist / currentAtr;
        if (atrMult >= 1.0 && atrMult <= 5.0)
            score += 5.0;
        else if (atrMult < 1.0)
            score += 3.0;
        else if (atrMult > 5.0 && atrMult <= 10.0)
            score += 2.0;
    }

    // 7. Delivery Alignment (10 pts)
    if (deliveryEngine.GetState().lifecycle == DELIVERY_ACTIVE) {
        if ((isBullishTarget && delDir == DELIVERY_DIR_BULLISH) ||
            (!isBullishTarget && delDir == DELIVERY_DIR_BEARISH)) {
            score += 10.0;
        }
    }

    // 8. MTF Alignment (5 pts)
    score += 5.0; // Aligned default

    if (score > 100.0)
        score = 100.0;
    return score;
}

//+------------------------------------------------------------------+
//| GetCandidate by index                                            |
//+------------------------------------------------------------------+
bool CObjectiveEngine::GetCandidate(int index, SDolDefinition& outCandidate) const {
    if (index < 0 || index >= m_candidatesCount)
        return false;
    outCandidate = m_candidates[index];
    return true;
}

//+------------------------------------------------------------------+
//| Checks if the target price has already been reached/swept today  |
//+------------------------------------------------------------------+
bool CObjectiveEngine::IsPriceSweptToday(double price,
                                         bool isBullishTarget,
                                         const double& high[],
                                         const double& low[],
                                         const datetime& time[],
                                         int ratesTotal) const {
    if (ratesTotal <= 2)
        return false;

    MqlDateTime dtToday;
    TimeToStruct(time[1], dtToday);

    // Scan all bars of the current day (from index 1 backwards)
    for (int i = 1; i < ratesTotal; i++) {
        MqlDateTime dt;
        TimeToStruct(time[i], dt);
        if (dt.day != dtToday.day)
            break; // Reached previous day

        if (isBullishTarget) {
            if (high[i] >= price)
                return true;
        } else {
            if (low[i] <= price)
                return true;
        }
    }
    return false;
}

#endif // __MNS_OBJECTIVE_ENGINE_MQH__
