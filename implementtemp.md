Consuming Liquidity & POIs Before Implementation Since CLiquidityEngine (Module 007) and CPOIEngine (Module 008) are not yet implemented, the Delivery Structure Engine will support:

An optional external htfDolPrice (Draw on Liquidity) input parameter in its Update() interface.
A default fallback to the latest confirmed opposite external swing high/low from CSwingDetector as the target objective/DOL.
Standard API setters to override the objective price (OverrideObjective) or POI coordinates if needed