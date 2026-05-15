# SAR_forecasting - Project under construction

**SAR Regional model - Microsimulation do-files.**

This project adapts the LAC microsimulation model to SAR countries by differentiating labor market changes by skill level and translating income changes into consumption impacts to forecast country-level poverty, inequality, and other distributive indicators. See the LAC technical paper here: https://documentsinternal.worldbank.org/search/34100000. 

**Note 1:** The do-files that generate the Microsimulation tool information can be found in the *tool* sub-folder. The country-specific dofiles that runs the model are stored in the *model* sub-folder. The *results* folder contains a set of do-files that generate summary statistics using the microsimulated databases. Every set of do-files in each folder runs through their specific *00_master.do* dofile-

**Note 2:** The current version of the do-files are specific to the  _Spring Meetings 2026_ round of Microsimulations.

**Note 3:** The _programs_ folder includes subprograms in MATA that are essential for running the simulations. Please do NOT modify them. 
