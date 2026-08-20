//+------------------------------------------------------------------+
//|                                                     MNSStyle.mqh |
//|                              MNS Trading Engine — Module 013     |
//|                                                                  |
//| Purpose:                                                         |
//|   Centralizes all visual style tokens (colors, line styles,      |
//|   font settings, size defaults) to ensure a unified design       |
//|   theme and avoid hardcoding visual constants inside renderers.  |
//|                                                                  |
//| Dependencies:                                                    |
//|   None.                                                          |
//+------------------------------------------------------------------+
#ifndef __MNS_STYLE_MQH__
#define __MNS_STYLE_MQH__

//-------------------------------------------------------------------
//| SIndicatorStyle Struct                                          |
////-------------------------------------------------------------------
struct SIndicatorStyle {
    //--- Color Palette
    color colorExtHigh; ///< Color for External Swing Highs (Bullish/Lime)
    color colorExtLow;  ///< Color for External Swing Lows (Bearish/Red)
    color colorIntHigh; ///< Color for Internal Swing Highs (Muted Bullish/Teal)
    color colorIntLow;  ///< Color for Internal Swing Lows (Muted Bearish/Magenta)

    color colorBullishBOS;   ///< Color for Bullish BOS (Lime)
    color colorBearishBOS;   ///< Color for Bearish BOS (Red)
    color colorBullishCHoCH; ///< Color for Bullish CHoCH (Orange/Warning)
    color colorBearishCHoCH; ///< Color for Bearish CHoCH (Orange/Warning)

    //--- Sizes and Widths
    int sizeExtArrow;   ///< Size of External Swing arrows (default 2)
    int sizeIntArrow;   ///< Size of Internal Swing arrows (default 1)
    int widthBOSLine;   ///< Width of BOS trend lines (default 1)
    int widthCHoCHLine; ///< Width of CHoCH trend lines (default 1)

    //--- Typography
    string fontName;   ///< Font name (default MT5 Font "Arial")
    int fontSizeLabel; ///< Font size for text labels (default 9)

    //--- Symbol Codes (Wingdings)
    int codeArrowHigh; ///< Wingdings code for high swing (default 233 - Up Arrow)
    int codeArrowLow;  ///< Wingdings code for low swing (default 234 - Down Arrow)

    //--- Line Styles
    ENUM_LINE_STYLE styleBOS;   ///< Line style for BOS (STYLE_DASH)
    ENUM_LINE_STYLE styleCHoCH; ///< Line style for CHoCH (STYLE_DOT)

    //--- Liquidity Pool Styling
    color colorBSL;               ///< Color for BSL active line (DodgerBlue)
    color colorSSL;               ///< Color for SSL active line (Tomato)
    color colorEQH;               ///< Color for EQH active line (LightSkyBlue)
    color colorEQL;               ///< Color for EQL active line (LightCoral)
    color colorSweptPool;         ///< Color for Swept pools (Gray)
    int widthLiqLine;             ///< Line width for BSL/SSL/EQH/EQL (default 1)
    ENUM_LINE_STYLE styleLiqActive; ///< Line style for active BSL/SSL pools (STYLE_DASH)
    ENUM_LINE_STYLE styleLiqSwept;  ///< Line style for swept pools (STYLE_DOT)

    //--- POI Zone Colors
    color colorOBBull;        ///< Bullish Order Block (MediumSpringGreen)
    color colorOBBear;        ///< Bearish Order Block (Crimson)
    color colorBreakerBull;   ///< Bullish Breaker Block (DeepSkyBlue)
    color colorBreakerBear;   ///< Bearish Breaker Block (OrangeRed)
    color colorMBBull;        ///< Bullish Mitigation Block (DarkCyan)
    color colorMBBear;        ///< Bearish Mitigation Block (DarkOrange)
    color colorFVGBull;       ///< Bullish FVG (LimeGreen)
    color colorFVGBear;       ///< Bearish FVG (OrangeRed)
    int   widthPOIBorder;     ///< POI rectangle border width (default 1)

    //--- Delivery Leg Colors
    color colorDeliveryBull;  ///< Active bullish delivery leg (Aqua)
    color colorDeliveryBear;  ///< Active bearish delivery leg (OrangeRed)
    int   widthDeliveryLine;  ///< Delivery leg line width (default 1)

    //--- DOL Target
    color colorDOL;           ///< Active DOL horizontal level (Gold)

    /// @brief Resets the style structure to safe default premium theme values.
    void Reset() {
        // Default premium theme colors (matching UI/UX spec: Lime/Red/Orange/Gray)
        colorExtHigh = clrLime;
        colorExtLow = clrRed;
        colorIntHigh = clrTeal;
        colorIntLow = clrDarkMagenta;

        colorBullishBOS = clrLime;
        colorBearishBOS = clrRed;
        colorBullishCHoCH = clrOrange;
        colorBearishCHoCH = clrOrange;

        // Default widths and sizes
        sizeExtArrow = 2;
        sizeIntArrow = 1;
        widthBOSLine = 1;
        widthCHoCHLine = 1;

        // Typography settings
        fontName = "Arial";
        fontSizeLabel = 9;

        // Arrow codes (Wingdings: 233 is Up Arrow, 234 is Down Arrow)
        codeArrowHigh = 233;
        codeArrowLow = 234;

        // Line styles
        styleBOS = STYLE_DASH;
        styleCHoCH = STYLE_DOT;

        // Liquidity default styles
        colorBSL = clrDodgerBlue;
        colorSSL = clrTomato;
        colorEQH = clrLightSkyBlue;
        colorEQL = clrLightCoral;
        colorSweptPool = clrSlateGray;
        widthLiqLine = 1;
        styleLiqActive = STYLE_DASH;
        styleLiqSwept = STYLE_DOT;

        // POI default styles (dark desaturated tints to ensure high candle/wick contrast)
        colorOBBull = C'0x0A, 0x2A, 0x14';       // Dark green
        colorOBBear = C'0x2F, 0x0A, 0x0A';       // Dark red
        colorBreakerBull = C'0x0A, 0x1A, 0x2E';   // Dark blue
        colorBreakerBear = C'0x2E, 0x14, 0x0A';   // Dark orange-red
        colorMBBull = C'0x0A, 0x24, 0x24';        // Dark cyan
        colorMBBear = C'0x2E, 0x1A, 0x0A';        // Dark orange
        colorFVGBull = C'0x0E, 0x30, 0x0E';       // Dark FVG green
        colorFVGBear = C'0x30, 0x0E, 0x0E';       // Dark FVG red
        widthPOIBorder = 1;

        // Delivery default styles
        colorDeliveryBull = clrAqua;
        colorDeliveryBear = clrOrangeRed;
        widthDeliveryLine = 1;

        // DOL default style
        colorDOL = clrGold;
    }
};

#endif // __MNS_STYLE_MQH__
