
/*==============================================================================================
Project:			Simulations Results file for MPO. SAR Countries.

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Institution:		World Bank Group - ESAPV

Date:				05/17/2022
Last update: 		4/21/2026
================================================================================================

MASTER.DO

Descrption: Runs all the do-files in the project

==============================================================================================*/

drop _all
frame reset
version 17.0 
*cap net install etime
*cap net install dm31, from(http://www.stata.com/stb/stb26)
etime, start

/*==============================================================================================
 	0 - Globals - Please check these globals carefully 
==============================================================================================*/

* Paths
gl path 		"C:\Users\WB539669\WBG\ESAPV Files - microsim/AM2026"
gl data_path  	"$path/input"
gl thedo    	"C:\Users\WB539669\OneDrive - WBG\Documents\GitHub\SAR_forecasting\dofiles\results\india"	// Do-files path

gl avail_data 	"C:\Users\WB539669\WBG\ESAPV Files - microsim\_inputs/Data availability by country.xlsx"
gl povmod 	  "\\wurepliprdfs01\gpvfile\gpv\Knowledge_Learning\Pov Projection\Central Team\MFM-allvintages.dta"

* Output file
gl country_path "${path}/"
gl outfile "${country_path}\Results_${country}_local.xlsm"

* Other globals 
gl country 		"IND" 	// AFG BGD BTN IND MDV NPL PAK LKA
gl cpi_version 	15
gl min_sim_year 2023 	// Please check this twice - Dynamic stats
gl ppp 			2021	// Change for "yes" / "no" depending on the version

* Poverty and vulnerability thresholds - Change if necessary multiplying the original value by 100
gl pline1 /*190 215*/ 300
gl pline2 /*320 365*/ 420
gl pline3 /*550 685*/ 830
gl prs_gp /*nnn 25*/ 28

cap ssc install dm31

/*==============================================================================================
 	1 - Set up simulated and actual data input files 
==============================================================================================*/

* IMPORTANT: Some countries have data restrictions. Please check the name file and years before running.

* Data availability input 
import excel "${avail_data}", sheet("Sheet1") cellrange(A1:G9) clear
qui keep if inlist(A,"Country","${country}")
for any B C D E F G: qui replace X = "0" if X == "ok"
for any B C D E F G: qui replace X = "1" if X == "sim"
qui destring B-G, replace
mkmat B-G, mat(data) 

run "${thedo}\01_data.do"
run "${thedo}\02_variables.do"
run "${thedo}\03_static_profiles.do"
run "${thedo}\04_gics.do"
run "${thedo}\05_transition_matrix.do"
run "${thedo}\06_dynamic_profiles.do"
run "${thedo}\07_pop_wdi.do"

* Display running time	
etime

/*==============================================================================================
  - END
==============================================================================================*/
