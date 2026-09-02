 
/*===================================================================================================
Project:			SAR Poverty micro-simulations
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		11/4/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  3/14/2025
===================================================================================================*/

version 17.0

cap ssc install etime
cap ssc install apoverty
cap ssc install ainequal
cap ssc install ainequal0
etime, start

clear all
clear mata
clear matrix
set more off

/*===================================================================================================
	1 - MODEL SET-UP
===================================================================================================*/

* NOTE: YOU ONLY NEED TO CHANGE THESE OPTIONS

* Globals for general paths
gl priv_path 	"C:\Users\WB539669\WBG\ESAPV Files - microsim/wb539669"
gl path  		"$priv_path\AM2026"
gl thedo    	"C:\Users\WB539669\OneDrive - WBG\Documents\GitHub\SAR_forecasting\dofiles\model\india"	// Do-files path

* Globals for country-year identification
gl cpi_version 	15
gl ppp 			2021	// Change for "yes" / "no" depending on the version
gl country 		"IND" 	// Country to upload
gl year 		2023	// Year to upload - Base year dataset
gl final_year 	2029	// Change for last simulated year

* Globals for country-specific paths
gl inputs   "${priv_path}\AM2026\input\Microsimulation_Inputs_${country}_local.xlsm" // SAVED LOCALLY
cap mkdir 	"${priv_path}\AM2026\data"
gl data_out "${priv_path}\AM2026\data"

* Parameters
gl sector_model 	6 		// Change for "3" or "6" to change intrasectoral variation
gl inc_re_scale 	"no" 	// Change for "yes"/"no" re-scale labor income using gdp
gl matching			"yes"	// Change for "yes" or "no" to activate matching for consumption to inncome ratio
gl standardization	"yes"	// Performs variables standardization before matching
gl rn_int_remitt 	"no" 	// Change for "yes" or "no" (neutral distribution) on modelling intern. remittances
gl rn_dom_remitt 	"no" 	// Change for "yes" or "no" (neutral distribution) on modelling domestic remittances
gl cons_re_scale 	"no" 	// Change for "yes"/"no" re-scale final consumption using private consumption


/*===================================================================================================
	2 - DATA UPLOAD
===================================================================================================*/

* Support module - CPIs and PPPs Anual
dlw, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v${cpi_version}_M) filename(Final_CPI_PPP_to_be_used.dta)
keep if code == "${country}" & year == ${year}
keep code year cpi${ppp} icp${ppp}
duplicates drop 
rename code countrycode
tempfile dlwcpi
save `dlwcpi', replace

* Imputed LFS data
use "${priv_path}\AM2026\input\IND_allyears_PLFS_V1_final_v01_M_cpi_microsim.dta", clear
keep if year == ${year}
		
* Merge
merge m:1 year using `dlwcpi', nogen keep(1 3)


/*===================================================================================================
	3 - LOAD PRE-DEFINED PROGRAMS
===================================================================================================*/

local files : dir "$thedo\programs" files "*.do"
foreach f of local files{
	dis in yellow "`f'"
	qui: run "$thedo\programs\\`f'"
}

/*===================================================================================================
	4 - RUN THE MODEL
===================================================================================================*/

* 1.input parameters
	run "$thedo\01_parameters.do"
* 2.prepare variables
	run "$thedo\02_variables.do"
* 3.model labor incomes by groups
	run "$thedo\03_occupation.do"
* 4.model labor incomes by skills
	run "$thedo\04_labor_income.do"
* 5.modeling population growth
	run "$thedo\05_population.do"
* 6.modeling labor activity rate
	run "$thedo\06_activity.do"
* 7.modeling unemployment rate
	run "$thedo\07_unemployment.do"
* 8.modeling changes in employment by sectors
	run "$thedo\08_struct_emp.do"
* 9.modeling labor income by sector
	run "$thedo\09_asign_labor_income.do"	
* 10.income growth by sector
	run "$thedo/$do_income.do"
* 11. total labor incomes
	run "$thedo\11_total_labor_income.do"	
* 12. total non-labor incomes
	run "$thedo\12_assign_nlai.do"
* 13. household income
	run "$thedo\13_household_income.do"
* 14. relative prices adjustment (food/nonfood)
	*run "$thedo\14_relative_prices.do"
* 15. matching income to consumption ratio
    run "$thedo\15_income_to_consumption.do"
* 16. new consumption 
	run "$thedo\16_new_consumption.do"
* 17. output database
	run "$thedo\17_output.do"

	
/*===================================================================================================
	- Quick summary
===================================================================================================*/

di in red "FOR YEAR ${model}"
sum poor11 poor21 poor31 [aw = fexp_s] if welfare_s != .
ineqdec0 welfare_s [aw = fexp_s]

sum poor1_base poor2_base poor3_base [aw = fexp_base] if welfare_base != .
ineqdec0 welfare_base [aw = fexp_base]


/*===================================================================================================
	- Display running time
===================================================================================================*/

etime


/*===================================================================================================
	- END
===================================================================================================*/
