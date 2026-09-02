
/*===================================================================================================
Project:			Labor Market Inputs for Microsimulation Tool
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		10/16/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  02/22/2025
===================================================================================================*/

* NOTE: You will need to have python installed in your device + the following packages.

*shell conda install selenium==4.21.0
*shell conda install webdriver_manager==4.0.1

drop _all
version 17.0
set timeout1 120, perm
set timeout2 400, perm


/*===================================================================================================
 	0 - SETTING
===================================================================================================*/

* Modifiable globals

** Dates
gl version 		"Sep-2-2026"
gl inflows 		"Seriestableview_4_8_2026"	//	Remittances file name, structure "Seriestableview_D_MM_YYYY"
gl date_inflows "Sep-2-2026"					//	Remittances file download date

** Paths
//gl path 		"C:\Users\wb520054\WBG\SARDATALAB - Documents\Microsimulations"
gl path 		"C:\Users\WB539669\WBG\ESAPV Files - microsim/wb539669"
gl dofiles 		"C:\Users\WB539669\OneDrive - WBG\Documents\GitHub\SAR_forecasting\dofiles\tool"	// Do-files path
gl mpo_version 	"${path}\AM2026" // Folder name
gl downloads	"C:\Users\wb539669\Downloads"		// Your downloads folder for retrieving remittances file

* Stable globals - Should not be changed
gl cpi_version 	14
gl cpi_base		2021
gl povmod 		"\\wurepliprdfs01\gpvfile\gpv\Knowledge_Learning\Pov Projection\Central Team\MFM-allvintages.dta"
gl input_master "input_MASTER.xlsx"							// Excel file read by regional tool
gl input_hhss_e	"inputs_hhss_elasticities.dta" 				// SARMD Input file for elasticities
gl input_lfs_e 	"inputs_lfs_elasticities_IND.dta" 			// SARLAB Input file for elasticities
cap mkdir		"${mpo_version}"							// Regional tool's path
cap mkdir 		"${mpo_version}\_inputs"					
gl path_mpo 	"${mpo_version}\_inputs"

cd "$path"


* Set up households surveys - HHSS
gl countries_hhss "IND" // "BGD BTN IND MDV NPL PAK LKA" // AFG does not have CPIs nor PPPs
gl init_year_hhss = 2000
gl end_year_hhss = 2022
/*
** Folders creation
foreach country of global countries_hhss {
	 cap mkdir 	"${mpo_version}/`country'"
}
*/

* Set up Labor Force Surveys
gl countries_lfs "IND" //"BGD BTN IND MDV NPL PAK LKA" 
gl init_year_lfs = 2000
gl end_year_lfs = 2022
gl quarters "q01 q02 q03 q04"

* Set up Elasticities - Countries to include and their RESPECTIVE year restriction
gl countries 	"BGD 	LKA		MDV"  
gl min_year 	"2000 	2006	2009"
gl last_year 	"2022 	2019	2019"
/*
gl countries 	"AFG 	BGD 	BTN 	IND 	MDV 	NPL 	PAK 	LKA"  
gl min_year 	"2013 	2000 	2003 	2004 	2002 	1995 	2004 	2006"
gl last_year 	"2019 	2022 	2022 	2011 	2019 	2022 	2018 	2019"
*/

/*===================================================================================================
 	1 - RUN DO FILES
===================================================================================================*/

* 1. inputs using Households Surveys
	run "$dofiles\01_inputs_hhss_IND"
	
* 2. inputs using Labor Force Surveys
	run "$dofiles\02_inputs_lfs"
	
* 3. inputs using Microsimulated data
	run "$dofiles\03_inputs_microsims"
	
* 4. merge labor inputs - hhss, lfs, and microsims
	run "$dofiles\04_merge_inputs_labor"
	
* 5. elasticities
	run "$dofiles\05_elasticities"
	
* 6. GDP and Population
	run "$dofiles\06_inputs_macro" 

* 7. Remittances
	run "$dofiles\07_exports_inflows"
	
	
/*===================================================================================================
	- END
===================================================================================================*/