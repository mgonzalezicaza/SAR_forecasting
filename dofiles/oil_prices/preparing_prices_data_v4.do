
/***************************************************************************
Project:			Organize databases for Food Prices Exercise
Institution:		World Bank - ELCPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		06/07/2022

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date: 	10/05/2023
***************************************************************************/

use "${path}\Oil prices\input\income_components", clear

merge 1:1 country hhid pid using "${out_sim}"

keep country hhid pid welfare_sim welfare_pre welfare_post fexp
	
di in red "${country_aux}"

**********************************************************************
* 									SAR
**********************************************************************

if "${country_aux}" == "SAR" {
	
	
	******************************************************************
	* 1. Upload Pre-conflict Data
	******************************************************************
	
	preserve
	
	use "${path}\Oil prices\input\compiled_baseline", clear
	keep country hhid pid male urban age h_head educat* depen pc_inc_* occupation_* lai_* tot_lai* h_transfers* h_*remit* h_pensions* h_otherinla* h_capital* h_renta_imp* labor_rel
	
	tempfile SAR_Baseline
	save `SAR_Baseline', replace
	restore
	
	******************************************************************
	* 2. Merge  pre-conflict data with simulated price and conflict vectors
	******************************************************************
	
	merge 1:1 country hhid pid using `SAR_Baseline', nogenerate
	
	
	******************************************************************
	* 3. Poverty and vulnerability
	******************************************************************
	
	* Poverty and vulnerability Pre
	gen poor${max_povline}1=1 if welfare_pre<=(${max_povline}*365/120)
	replace poor${max_povline}1=0 if poor${max_povline}1!=1 & pc_inc_s!=.
	
	gen poor${mid_povline}1=1 if pc_inc_s<=(${mid_povline}*365/120)
	replace poor${mid_povline}1=0 if poor${mid_povline}1!=1 & pc_inc_s!=.
	
	gen poor${min_povline}1=1 if pc_inc_s<=(${min_povline}*365/120)
	replace poor${min_povline}1=0 if poor${min_povline}1!=1 & pc_inc_s!=.

	gen upper_class=1 if pc_inc_s>(${midc_line}*365/120) & pc_inc_s!=.
	replace upper_class =0 if upper_class!=1 & pc_inc_s!=.
	
	* Poverty and vulnerability Post
	gen poor${max_povline}1_post=1 if pc_inc_post<=(${max_povline}*365/120)
	replace poor${max_povline}1_post=0 if poor${max_povline}1_post!=1 & pc_inc_post!=.
	
	gen poor${mid_povline}1_post=1 if pc_inc_post<=(${mid_povline}*365/120)
	replace poor${mid_povline}1_post=0 if poor${mid_povline}1_post!=1 & pc_inc_post!=.
	
	gen poor${min_povline}1_post=1 if pc_inc_post<=(${min_povline}*365/120)
	replace poor${min_povline}1_post=0 if poor${min_povline}1_post!=1 & pc_inc_post!=.

	gen upper_class_post=1 if pc_inc_post>(${midc_line}*365/120) & pc_inc_post!=.
	replace upper_class_post =0 if upper_class_post!=1 & pc_inc_post!=.
	
	*drop aux
	compress
	
	* Save the new data
	qui save "${inpath}\Oil_prices\Data/${country_aux}_2022.dta", replace
}


**********************************************************************
* 								Countries
**********************************************************************

else {
	
	******************************************************************
	* 1. Creating SM data
	******************************************************************
	
	preserve
	
	use "${path}\Oil prices\input\compiled_baseline", clear
	keep country hhid pid male urban age h_head educat* depen pc_inc_* occupation_* lai_* tot_lai* h_transfers* h_*remit* h_pensions* h_otherinla* h_capital* h_renta_imp* labor_rel
	
	tempfile SAR_Baseline
	save `SAR_Baseline', replace
	restore
	
	******************************************************************
	* 2. Merge oil prices data with SM 
	******************************************************************
	
	merge 1:1 country hhid pid using `SAR_Baseline', nogenerate
	
	ren ypc_sim pc_inc_post
	
	keep if country == "${country_aux}"
	
	******************************************************************
	* 3. Poverty and vulnerability
	******************************************************************
	
	* Poverty and vulnerability Pre
	gen poor${max_povline}1=1 if pc_inc_s<=(${max_povline}*365/120)
	replace poor${max_povline}1=0 if poor${max_povline}1!=1 & pc_inc_s!=.
	
	gen poor${mid_povline}1=1 if pc_inc_s<=(${mid_povline}*365/120)
	replace poor${mid_povline}1=0 if poor${mid_povline}1!=1 & pc_inc_s!=.
	
	gen poor${min_povline}1=1 if pc_inc_s<=(${min_povline}*365/120)
	replace poor${min_povline}1=0 if poor${min_povline}1!=1 & pc_inc_s!=.

	gen upper_class=1 if pc_inc_s>(${midc_line}*365/120) & pc_inc_s!=.
	replace upper_class =0 if upper_class!=1 & pc_inc_s!=.
	
	* Poverty and vulnerability Post
	gen poor${max_povline}1_post=1 if pc_inc_post<=(${max_povline}*365/120)
	replace poor${max_povline}1_post=0 if poor${max_povline}1_post!=1 & pc_inc_post!=.
	
	gen poor${mid_povline}1_post=1 if pc_inc_post<=(${mid_povline}*365/120)
	replace poor${mid_povline}1_post=0 if poor${mid_povline}1_post!=1 & pc_inc_post!=.
	
	gen poor${min_povline}1_post=1 if pc_inc_post<=(${min_povline}*365/120)
	replace poor${min_povline}1_post=0 if poor${min_povline}1_post!=1 & pc_inc_post!=.

	gen upper_class_post=1 if pc_inc_post>(${midc_line}*365/120) & pc_inc_post!=.
	replace upper_class_post =0 if upper_class_post!=1 & pc_inc_post!=.
	
	*drop aux
	compress
	
	* Save the new data
	qui save "${inpath}\Oil_prices\Data/${country_aux}_2022.dta", replace
}
