
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Matching income to consumption ratio
Institution:		World Bank - ESAPV

Author:				Kelly Montoya
E-mail:				kmontoyamunoz@worldbank.org
Creation Date:		12/10/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  2/19/2025
===================================================================================================*/


/*===================================================================================================
	1 - SETTING MATCHING VARIABLES
===================================================================================================*/

* Renaming
rename (weight    skilled      occupation      sect_main      ipcf_ppp		welfare_ppp) ///
       (fexp_base skilled_base occupation_base sect_main_base pc_inc_base	welfare_base)
	     
* Private cosumption growth
loc r = rowsof(growth_macro_data)
gen growth_cons = growth_macro_data[`r',1]

* Ventiles
xtile vtile = welfare_base [w = fexp_base] if h_head == 1, nq(20)

* Sample
gen hh_sample = 1 if !mi(region) & !mi(vtile) & !mi(age) & !mi(urban) & !mi(fexp_base) & !mi(h_size) & h_head == 1
/*
* Compute household-level weights
gen h_fexp_base = fexp_base * h_size if h_head == 1
gen h_fexp_s 	= fexp_s 	* h_size if h_head == 1
*/
* Original income/consumption ratio
gen orig_ratio = pc_inc_base / welfare_base


/*===================================================================================================
	2 - MATCHING
===================================================================================================*/

if "$matching" == "yes" {
	
	save "${data_out}\simulated.dta", replace
	
	* Filter households sample
	keep if hh_sample == 1

	* Variables standardization
	if "$standardization" == "yes" 	for any age h_size pc_inc_s pc_inc_base: egen z_X = std(X)
	else 							for any age h_size pc_inc_s pc_inc_base: gen z_X = X

	* Prepare receiver dataset (samp.b)
	preserve
	gen id_rec = _n  
	keep idh idp id_rec region vtil urban age h_size pc_inc_s welfare_base orig_ratio z_age z_h_size z_pc_inc_s
	tempfile receiver
	save `receiver'
	restore

	* Prepare donor dataset (samp.a)
	preserve
	gen id_don = _n  
	keep idh idp id_don region vtil urban age h_size pc_inc_base orig_ratio z_age z_h_size z_pc_inc_base
	ren (z_age z_h_size z_pc_inc_base orig_ratio) (don_z_age don_z_h_size don_z_pc_inc_s ratio)
	tempfile donor
	save `donor'
	restore

	* Cartesian join of receiver and donor datasets
	use `receiver', clear
	joinby region vtil urban using `donor', unmatched(master) 
	drop _m

	* Euclidean distance for each pair
	gen dist = 0
	foreach var of varlist age h_size pc_inc_s {
		gen dist_`var' = (z_`var' - don_z_`var')^2
		replace dist = dist + dist_`var'
		drop dist_`var'
	}
	replace dist = sqrt(dist)

	* Find the nearest donor for each receiver
	bysort id_rec (dist): keep if _n == 1

	* New ratio
	gen new_ratio = ratio if abs((orig_ratio - ratio)/orig_ratio) <= 0.2
	replace new_ratio = orig_ratio if new_ratio == .
	
	* Save new ratio
	keep idh new_ratio
	tempfile ratio
	save `ratio', replace
	
	* Merge with original simulated database
	use "${data_out}\simulated.dta", clear
	merge m:1 idh using `ratio'

}

else {
	
	* New ratio
	gen new_ratio = orig_ratio 
	
}


/*===================================================================================================
	- END
===================================================================================================*/
