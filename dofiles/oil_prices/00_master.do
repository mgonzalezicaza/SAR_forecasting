
/*===================================================================================================
Project:			Iran's Conflict Distributional Impact
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		3/24/2026

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  3/24/2026
===================================================================================================*/

drop _all
version 17.0


/*=================================================================================================*/
**# 1. Setting
/*=================================================================================================*/

* Globals for paths
gl path 			"C:\Users\wb520054\WBG\SARDATALAB - Documents\Microsimulations\SM2026"
gl data 			"C:\Users\wb520054\OneDrive - WBG\02_SAR Stats Team\Microsimulations\SM2026"
gl food_share 		"${path}\food_vectors_SAR"
gl dos 				"${path}\Oil prices\dofiles"
gl input_baseline 	"${path}\Oil prices\input\compiled_baseline_MPOweights"
gl input_conflict 	"${path}\Oil prices\input\compiled_SM2026_MPOweights"


* Other globals
gl version 		"JUN_12_2026"
gl countries 	"BGD BTN MDV NPL LKA IND"
gl v_oil = ((94/78.58)-1)*100 // Projected growth in oil prices for Q1 and Q2 of 2026 in Feb report (56.14), for March (78.58) and projected new price from Global assumptions (94). - https://www.eia.gov/outlooks/steo/report/us_oil.php, consulted on 03-17-2026, macro updated on 03-24-2026.
gl out_sim "${path}\Oil prices\output\compiled_sim_${version}"
gl out "${path}\Oil prices\output\SAR_Iran_conflict_${version}.xlsx"
gl out_mat "${path}\Oil prices\output\deco_matrix.xlsx"

cd "${path}\Oil prices\dofiles"


/*=================================================================================================*/
**# 2. Run the project
/*=================================================================================================*/

* 1. Transform Microsimulated Conflict data
	run "01_conflict_data.do"

* 2. Transform Microsimulated Baseline data
	run "02_preconflict_data.do"

* 3. Apply inflation effects
	run "03_inflation_impacts.do"

* 4. Vectors of income components
	run "04_components.do"

* 5. Shapley decomposition
	run "05_shapley_adecomp.do"
	
* 6. Profiles
	*run "06_profiles.do"
