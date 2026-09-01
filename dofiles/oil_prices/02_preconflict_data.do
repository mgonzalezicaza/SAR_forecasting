
/*===================================================================================================
Project:			Iran's Conflict Distributional Impact - Pre-conflict Microsimulated Data
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		3/13/2026

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  3/24/2026
===================================================================================================*/


/*=================================================================================================*/
**# 1. Setting
/*=================================================================================================*/

	clear
	cap erase "${path}\Oil prices\input\compiled_baseline.dta"
	qui save "${path}\Oil prices\input\compiled_baseline", emptyok


/*=================================================================================================*/
**# 2. Microsimulated Data
/*=================================================================================================*/


foreach country of global countries { // Open loop countries
	
	di in red "`country'"
	gl country_path "${data}/`country'\Data\preconflict"
	
	* Loading the data	
	if "`country'" == "BGD" qui use "${country_path}\BGD_2026_6s_dom_yes_int_no_inc_no_cons_no_matching_yes_st_yes.dta", clear
	
	else if "`country'" == "MDV" qui use "${country_path}\MDV_2026_6s_dom_no_int_no_inc_no_cons_no_matching_yes_st_yes.dta", clear
	
	else if "`country'" == "IND" qui use "${country_path}\IND_2026_6s_dom_no_int_no_inc_no_cons_no_matching_yes_st_yes.dta", clear
	
	else if "`country'" == "NPL" qui use "${country_path}\NPL_2026_6s_dom_yes_int_yes_inc_yes_cons_no_matching_yes_st_yes.dta", clear
	
	else if "`country'" == "LKA" qui use "${country_path}\LKA_2026_6s_dom_yes_int_yes_inc_yes_cons_no_matching_yes_st_yes.dta", clear
	
	else if "`country'" == "BTN" qui use "${country_path}\BTN_2026_6s_dom_no_int_yes_inc_no_cons_yes_matching_yes_st_yes.dta", clear
	
	* Variables of interest
	cap gen code = "`country'"
	cap clonevar members = h_size
	
	if inlist("`country'","BGD","LKA") keep hhid pid code year wgt fexp_* male urban age h_head educat* members ipcf ila ila_ppp icap icap_ppp ijubi ijubi_ppp inla_otro inla_otro_ppp itranp itranp_ppp itrane itrane_ppp socialsec emplyd* empstat* industry* active* occupation* renta_imp itf itf_ppp ip ip_ppp inp inp_ppp hogarsec ii itranext_m region marital pc_inc_* sect_main* skill* unskill* unemplyd* active* sect_main6* sectorg* salaried* public_job* lai_* tot_lai* h_* aux_nlai_s  icp* cpi* depen labor_* welfare* new_ratio depen sect_secu*
	
	if "`country'"=="NPL" keep hhid pid code year weight fexp_* male urban age h_head educat* members ipcf ila ila_ppp icap icap_ppp ijubi ijubi_ppp inla_otro inla_otro_ppp itranp itranp_ppp itrane itrane_ppp socialsec emplyd* empstat* industry* active* occupation* renta_imp itf itf_ppp ip ip_ppp inp inp_ppp hogarsec ii itranext_m region marital pc_inc_* sect_main* skill* unskill* unemplyd* active* sect_main6* sectorg* salaried* public_job* lai_* tot_lai* h_* aux_nlai_s  icp* cpi* depen labor_* welfare* new_ratio depen sect_secu*
	 
	if "`country'" == "MDV" keep hhid pid code year wgt fexp_* male urban age h_head educat* members ipcf ila ila_ppp icap icap_ppp ijubi ijubi_ppp inla_otro inla_otro_ppp itranp itranp_ppp itrane itrane_ppp socialsec emplyd* empstat* industry* active* occupation* renta_imp itf itf_ppp ip ip_ppp inp inp_ppp hogarsec ii itranext_m region marital pc_inc_* sect_main* informal* formal* unemplyd* active* sect_main6* sectorg* salaried* public_job* lai_* tot_lai* h_* aux_nlai_s  icp* cpi* depen labor_* welfare* new_ratio depen sect_secu*
	
	if "`country'" == "IND" keep hhid pid code year fexp_* male urban age h_head educat* members h_size *_ppp emplyd* empstat* industry* active* occupation* hogarsec region marital pc_inc_* sect_main* skill* unskill* unemplyd* active* sect_main6* sectorg* salaried* public_job* lai_* tot_lai* h_* aux_nlai_s  icp* cpi* depen labor_* welfare* new_ratio depen sect_secu*
	
	if "`country'"=="BTN" keep hhid pid code year fexp_* male urban age h_head educat* members h_size ipcf ila ila_ppp icap icap_ppp ijubi ijubi_ppp inla_otro inla_otro_ppp itranp itranp_ppp itrane itrane_ppp emplyd* empstat* industry* active* occupation* renta_imp itf itf_ppp ip ip_ppp inp inp_ppp itranext_m region marital pc_inc_* sect_main* skill* unskill* unemplyd* active* sect_main6* sectorg* salaried* public_job* lai_* tot_lai* h_* aux_nlai_s  icp* cpi* depen labor_* welfare* new_ratio depen sect_secu*

	* Year
	qui gen baseline_yr=year
	
	* Renaming variables
	qui clonevar ypc_26 = pc_inc_s
	qui clonevar pondera_26 = fexp_s
	*qui clonevar occupation_26 = occupation_s
	if "`country'" == "MDV" qui clonevar informal_26 = informal_s
	if inlist("`country'","BGD","IND","NPL","LKA","BTN") qui clonevar informal_26 = unskilled_s
	
	*Country
	qui gen country=code
	
	* Saving 
	order country hhid pid members male age h_head urban marital labor_rel* ypc_26 pondera_* fexp_* sect_* informal_* occupation_* welfare* icp* cpi* lai_* h_* new_ratio tot_lai_* depen sect_secu*
	qui append using "${path}\Oil prices\input\compiled_baseline", force
	qui replace country = upper(country)
	drop if hogarsec == 1 & "`country'" == "IND"
	cap drop *socity
	sort country hhid pid
	qui compress
	qui save "${path}\Oil prices\input\compiled_baseline", replace
		
}


/*=================================================================================================*/
**# 3. Reweighting using MPO population
/*=================================================================================================*/

	* Load the data
	use "\\wurepliprdfs01\gpvfile\gpv\Knowledge_Learning\Pov Projection\Central Team\MFM-allvintages.dta", clear

	* Keep only the most recent data
	tab date
	gen date1=date(date,"MDY")
	egen datem= max(date1)
	keep if date1 == datem
	tab date  // Sept 8

	* Keep only SAR countries and 2026
	keep if inlist(countrycode,"BGD","BTN","IND","NPL","MDV","LKA")
	keep if year == 2026

	* Organize the variables
	keep countrycode pop
	replace pop = pop * 1000000
	ren countrycode country
	order country
	sort country

	* Merge with AM2023 data
	merge 1:m country using "${path}\Oil prices\input\compiled_baseline", nogenerate keep(3)

	* New weight
	ren pondera_26 aux_pondera_26
	bysort country: egen pop_pondera_26 = total(aux_pondera_26)
	gen pondera_26 = aux_pondera_26 * (pop / pop_pondera_26)


/*=================================================================================================*/
**# 4. Final data to be used
/*=================================================================================================*/

	* Variables used
	keep country hhid pid male age labor_rel* ypc_26 pondera_26 informal_26 occupation_* members h_head urban  educat* marital region hogarsec ip baseline_yr aux_pondera_26 welfare* icp* cpi* sect_* lai_* h_* tot_lai_* new_ratio depen sect_secu*

	* Labels
	label variable country        "Country name"
	label variable pid            "Person id"
	label variable ypc_26         "Household per capita income 2026"
	label variable aux_pondera_26 "Weighting factor 2026"
	label variable informal_26    "Simulated informal/skill status 2026"
	*label variable occupation_26  "Simulated occupation 2026"
	label variable pondera_26     "WDI population -Weighting factor 2026"
	label variable labor_rel      "Baseline: Type of employment in main occupation"

	*cap label define occupation_26 0 "inactive" 1 "unempl" 2 "agr-fml" 3 "agr-inf" 4 "ind-fml" 5 "ind-inf" 6 "ser-fml" 7"ser-inf", replace
	*cap label values occupation_26 occupation_26

	label define informal_26 1 "informal" 0 "formal", replace
	label values informal_26 informal_26

	cap drop pondera_eph_26 pondera_oficial_26 aux_pondera_26
			
	compress
	save "${path}\Oil prices\input\compiled_baseline_MPOweights", replace

	di in red "Baseline data for 2026 completed"
	