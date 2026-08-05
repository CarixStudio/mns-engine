//+------------------------------------------------------------------+
//|                                            MNS_TestHarness.mq5  |
//|                              MNS Trading Engine — Test Harness   |
//|                                                                  |
//| Purpose:                                                         |
//|   Validates that MNSTypes compiles correctly and all shared      |
//|   structures initialize to safe default values.                  |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Include MNSTypes.mqh and verify compilation.                 |
//|   - Instantiate and reset all shared structures.                 |
//|   - Log structure field defaults to the terminal.                |
//|   - Confirm no business logic or market analysis is present.     |
//|                                                                  |
//| Dependencies:                                                    |
//|   MNSTypes.mqh                                                   |
//|                                                                  |
//| Rules:                                                           |
//|   - No trading logic.                                            |
//|   - No indicator drawing.                                        |
//|   - No chart operations beyond logging.                          |
//|                                                                  |
//| Version: 1.0                                                     |
//| Status:  Development                                             |
//+------------------------------------------------------------------+
#property copyright "MNS Trading Engine"
#property version   "1.00"
#property strict

#include "..\\..\\Include\\MNS\\MNSTypes.mqh" // Resolved from Experts/MNS_TestHarness/ → ../../Include/MNS/

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== MNS Test Harness ===");
    Print("Engine Version : ", MNS_ENGINE_VERSION);
    Print("Module Version : ", MNS_MODULE_VERSION);
    Print("-----------------------");

    //--- Validate SSwingPoint default initialization
    SSwingPoint swing;
    swing.Reset();
    Print("[SSwingPoint]");
    Print("  barIndex    = ", swing.barIndex);
    Print("  price       = ", swing.price);
    Print("  time        = ", swing.time);
    Print("  type        = ", EnumToString(swing.type));
    Print("  level       = ", EnumToString(swing.level));
    Print("  isConfirmed = ", swing.isConfirmed);
    Print("-----------------------");

    //--- Validate SStructureBreak default initialization
    SStructureBreak structBreak;
    structBreak.Reset();
    Print("[SStructureBreak]");
    Print("  barIndex    = ", structBreak.barIndex);
    Print("  price       = ", structBreak.price);
    Print("  time        = ", structBreak.time);
    Print("  breakType   = ", EnumToString(structBreak.breakType));
    Print("  strength    = ", EnumToString(structBreak.strength));
    Print("  isConfirmed = ", structBreak.isConfirmed);
    Print("-----------------------");

    //--- Validate SMarketState default initialization
    SMarketState state;
    state.Reset();
    Print("[SMarketState]");
    Print("  trend              = ", EnumToString(state.trend));
    Print("  phase              = ", EnumToString(state.phase));
    Print("  structureType      = ", EnumToString(state.structureType));
    Print("  isBullishStructure = ", state.isBullishStructure);
    Print("  isBearishStructure = ", state.isBearishStructure);
    Print("  isRanging          = ", state.isRanging);
    Print("  updatedBarIndex    = ", state.updatedBarIndex);
    Print("  updatedTime        = ", state.updatedTime);
    Print("  version            = ", state.version);
    Print("-----------------------");

    Print("=== MNSTypes validation complete ===");

    //--- Remove the EA from the chart after logging — test is single-pass
    return INIT_FAILED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("MNS_TestHarness deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Intentionally empty.
    // This harness runs its validation in OnInit only.
}

//+------------------------------------------------------------------+
//| End of MNS_TestHarness.mq5                                       |
//+------------------------------------------------------------------+
