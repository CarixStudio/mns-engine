Consuming Liquidity & POIs Before Implementation Since CLiquidityEngine (Module 007) and CPOIEngine (Module 008) are not yet implemented, the Delivery Structure Engine will support:

An optional external htfDolPrice (Draw on Liquidity) input parameter in its Update() interface.
A default fallback to the latest confirmed opposite external swing high/low from CSwingDetector as the target objective/DOL.
Standard API setters to override the objective price (OverrideObjective) or POI coordinates if needed

IMPORTANT

Pure Data Arrays for Daily/Weekly and Session Boundaries To comply with Absolute Rule 6 (No Broker API calls), the engine will NOT use functions like iHigh() or iLow() to query other timeframes. Instead:

Daily/Weekly boundaries will be scanned directly from the input time[] array by checking date changes.
Session boundaries (Asia, London, NY) will be parsed using the input time[] array and converted using the gmtOffset parameter.
WARNING

Swept Liquidity is Preserved Per Section 4.6 of the strategy, swept liquidity pools will NOT be deleted from memory. They will remain in history as inactive pools with state LIQ_SWEPT or LIQ_BROKEN for historical analysis and entry confirmations.

No Wick Invalidation In accordance with Section 3.4 of the strategy, a wick alone does not invalidate a delivery leg by default. Leg invalidation is strictly triggered by a confirmed candle body close beyond the protected level.