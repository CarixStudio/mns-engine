//+------------------------------------------------------------------+
//|                                           CExecutionRenderer.mqh |
//|                              MNS Trading Engine — Module 014     |
//|                                                                  |
//| Purpose:                                                         |
//|   Renders on-chart Entry, SL, and TP risk-reward projection boxes |
//+------------------------------------------------------------------+
#ifndef __MNS_EXECUTION_RENDERER_MQH__
#define __MNS_EXECUTION_RENDERER_MQH__

#include "../MNSTypes.mqh"
#include "../MNSStyle.mqh"

class CExecutionRenderer
{
private:
    bool             m_isInitialized;
    string           m_prefix;
    SIndicatorStyle  m_style;
    
    void     CreateRectangle(string name, datetime t1, double p1, datetime t2, double p2, color clr);
    void     CreateLine(string name, datetime t1, double p1, datetime t2, double p2, color clr, int width, ENUM_LINE_STYLE style);
    void     CreateLabel(string name, datetime t, double p, string text, color clr, ENUM_ANCHOR_POINT anchor);

public:
    CExecutionRenderer();
    ~CExecutionRenderer();

    bool     Initialize(string prefix = "MNS_EXEC_");
    void     Draw(EConfirmationDirection direction, 
                  double entryPrice, 
                  double stopLoss, 
                  double takeProfit, 
                  const datetime &time[], 
                  double atr14, 
                  int projectedBars,
                  double volume = 0.0,
                  double cashRisk = 0.0,
                  double cashReward = 0.0);
    void     Clear();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CExecutionRenderer::CExecutionRenderer()
    : m_isInitialized(false),
      m_prefix("MNS_EXEC_")
{
    m_style.Reset();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CExecutionRenderer::~CExecutionRenderer()
{
    Clear();
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CExecutionRenderer::Initialize(string prefix)
{
    m_prefix = prefix;
    m_style.Reset();
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Clear                                                            |
//+------------------------------------------------------------------+
void CExecutionRenderer::Clear()
{
    ObjectsDeleteAll(0, m_prefix);
}

//+------------------------------------------------------------------+
//| Draw                                                             |
//+------------------------------------------------------------------+
void CExecutionRenderer::Draw(EConfirmationDirection direction, 
                              double entryPrice, 
                              double stopLoss, 
                              double takeProfit, 
                              const datetime &time[], 
                              double atr14, 
                              int projectedBars,
                              double volume,
                              double cashRisk,
                              double cashReward)
{
    if (!m_isInitialized)
        return;

    // Safety checks
    if (direction != CONFIRM_DIR_BULLISH && direction != CONFIRM_DIR_BEARISH)
    {
        Clear();
        return;
    }

    if (entryPrice <= 0.0 || stopLoss <= 0.0 || takeProfit <= 0.0)
    {
        Clear();
        return;
    }

    if (ArraySize(time) < 1)
        return;

    // Calculate time coordinates
    int clampedBars = MathMax(5, MathMin(100, projectedBars));
    datetime t1 = time[0];
    datetime t2 = time[0] + (datetime)(clampedBars * PeriodSeconds());

    // Calculate pips and risk/reward values
    double pipSize = (_Digits == 3 || _Digits == 5) ? 10.0 * _Point : _Point;
    double tpPips = MathAbs(takeProfit - entryPrice) / pipSize;
    double slPips = MathAbs(entryPrice - stopLoss) / pipSize;
    
    double riskDistance = MathAbs(entryPrice - stopLoss);
    double rr = (riskDistance > 0.0) ? (MathAbs(takeProfit - entryPrice) / riskDistance) : 0.0;

    // Draw/Update visual elements
    string tpBoxName    = m_prefix + "TP_Box";
    string slBoxName    = m_prefix + "SL_Box";
    string entryLineName = m_prefix + "Entry_Line";
    string tpLineName   = m_prefix + "TP_Line";
    string slLineName   = m_prefix + "SL_Line";
    string entryLabelName = m_prefix + "Entry_Label";
    string tpLabelName   = m_prefix + "TP_Label";
    string slLabelName   = m_prefix + "SL_Label";

    if (direction == CONFIRM_DIR_BULLISH)
    {
        // 1. Boxes
        CreateRectangle(tpBoxName, t1, takeProfit, t2, entryPrice, m_style.colorExecutionTPBg);
        CreateRectangle(slBoxName, t1, entryPrice, t2, stopLoss, m_style.colorExecutionSLBg);
        
        // 2. Lines
        CreateLine(entryLineName, t1, entryPrice, t2, entryPrice, m_style.colorExecutionEntry, 2, STYLE_SOLID);
        CreateLine(tpLineName, t1, takeProfit, t2, takeProfit, m_style.colorExecutionTPLine, 1, STYLE_SOLID);
        CreateLine(slLineName, t1, stopLoss, t2, stopLoss, m_style.colorExecutionSLLine, 1, STYLE_SOLID);

        // 3. Text Labels (aligned outside the boxes: TP above TP line, SL below SL line)
        string currency = AccountInfoString(ACCOUNT_CURRENCY);
        if (currency == "") currency = "USD";
        
        string tpText = StringFormat("TP: %s (+%s pips / %sR)", DoubleToString(takeProfit, _Digits), DoubleToString(tpPips, 1), DoubleToString(rr, 1));
        if (cashReward > 0.0)
            tpText += StringFormat(" [Reward: %s %s]", DoubleToString(cashReward, 2), currency);
            
        string entryText = StringFormat("ENTRY: %s", DoubleToString(entryPrice, _Digits));
        if (volume > 0.0)
            entryText += StringFormat(" [Size: %s Lots]", DoubleToString(volume, 2));
            
        string slText = StringFormat("SL: %s (-%s pips)", DoubleToString(stopLoss, _Digits), DoubleToString(slPips, 1));
        if (cashRisk > 0.0)
            slText += StringFormat(" [Risk: %s %s]", DoubleToString(cashRisk, 2), currency);

        CreateLabel(tpLabelName, t2, takeProfit, tpText, m_style.colorExecutionTPLine, ANCHOR_LEFT_LOWER);
        CreateLabel(entryLabelName, t2, entryPrice, entryText, m_style.colorExecutionEntry, ANCHOR_LEFT);
        CreateLabel(slLabelName, t2, stopLoss, slText, m_style.colorExecutionSLLine, ANCHOR_LEFT_UPPER);
    }
    else // CONFIRM_DIR_BEARISH
    {
        // 1. Boxes
        CreateRectangle(tpBoxName, t1, entryPrice, t2, takeProfit, m_style.colorExecutionTPBg);
        CreateRectangle(slBoxName, t1, stopLoss, t2, entryPrice, m_style.colorExecutionSLBg);
        
        // 2. Lines
        CreateLine(entryLineName, t1, entryPrice, t2, entryPrice, m_style.colorExecutionEntry, 2, STYLE_SOLID);
        CreateLine(tpLineName, t1, takeProfit, t2, takeProfit, m_style.colorExecutionTPLine, 1, STYLE_SOLID);
        CreateLine(slLineName, t1, stopLoss, t2, stopLoss, m_style.colorExecutionSLLine, 1, STYLE_SOLID);

        // 3. Text Labels (aligned outside the boxes: TP below TP line, SL above SL line)
        string currency = AccountInfoString(ACCOUNT_CURRENCY);
        if (currency == "") currency = "USD";
        
        string tpText = StringFormat("TP: %s (+%s pips / %sR)", DoubleToString(takeProfit, _Digits), DoubleToString(tpPips, 1), DoubleToString(rr, 1));
        if (cashReward > 0.0)
            tpText += StringFormat(" [Reward: %s %s]", DoubleToString(cashReward, 2), currency);
            
        string entryText = StringFormat("ENTRY: %s", DoubleToString(entryPrice, _Digits));
        if (volume > 0.0)
            entryText += StringFormat(" [Size: %s Lots]", DoubleToString(volume, 2));
            
        string slText = StringFormat("SL: %s (-%s pips)", DoubleToString(stopLoss, _Digits), DoubleToString(slPips, 1));
        if (cashRisk > 0.0)
            slText += StringFormat(" [Risk: %s %s]", DoubleToString(cashRisk, 2), currency);

        CreateLabel(tpLabelName, t2, takeProfit, tpText, m_style.colorExecutionTPLine, ANCHOR_LEFT_UPPER);
        CreateLabel(entryLabelName, t2, entryPrice, entryText, m_style.colorExecutionEntry, ANCHOR_LEFT);
        CreateLabel(slLabelName, t2, stopLoss, slText, m_style.colorExecutionSLLine, ANCHOR_LEFT_LOWER);
    }
}

//+------------------------------------------------------------------+
//| CreateRectangle                                                  |
//+------------------------------------------------------------------+
void CExecutionRenderer::CreateRectangle(string name, datetime t1, double p1, datetime t2, double p2, color clr)
{
    if (ObjectFind(0, name) < 0)
    {
        if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2))
        {
            Print(StringFormat("[ERROR] [CExecutionRenderer] Failed to create rectangle %s. Error: %d", name, GetLastError()));
            return;
        }
    }
    else
    {
        ObjectMove(0, name, 0, t1, p1);
        ObjectMove(0, name, 1, t2, p2);
    }
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FILL, true);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| CreateLine                                                       |
//+------------------------------------------------------------------+
void CExecutionRenderer::CreateLine(string name, datetime t1, double p1, datetime t2, double p2, color clr, int width, ENUM_LINE_STYLE style)
{
    if (ObjectFind(0, name) < 0)
    {
        if (!ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2))
        {
            Print(StringFormat("[ERROR] [CExecutionRenderer] Failed to create line %s. Error: %d", name, GetLastError()));
            return;
        }
    }
    else
    {
        ObjectMove(0, name, 0, t1, p1);
        ObjectMove(0, name, 1, t2, p2);
    }
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
    ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| CreateLabel                                                      |
//+------------------------------------------------------------------+
void CExecutionRenderer::CreateLabel(string name, datetime t, double p, string text, color clr, ENUM_ANCHOR_POINT anchor)
{
    if (ObjectFind(0, name) < 0)
    {
        if (!ObjectCreate(0, name, OBJ_TEXT, 0, t, p))
        {
            Print(StringFormat("[ERROR] [CExecutionRenderer] Failed to create label %s. Error: %d", name, GetLastError()));
            return;
        }
    }
    else
    {
        ObjectMove(0, name, 0, t, p);
    }
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, m_style.fontName);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, m_style.fontSizeLabel);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

#endif // __MNS_EXECUTION_RENDERER_MQH__
