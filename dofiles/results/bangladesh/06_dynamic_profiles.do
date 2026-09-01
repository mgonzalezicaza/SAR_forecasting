************************************************************************
* 6 - Dynamic profiles
************************************************************************

frame change processed


* 6.1 - Keep only simulated data
***********************************
gen simulation = .
forvalues a = 1/6 {
	loc simulated = data[2,`a']
	replace simulation = `simulated' if year == data[1,`a']
}

drop if simulation == 0
drop if year < ${min_sim_year}


* 6.2 - Reshape
******************
* Reshape data to calculate inter-annual changes. Please make sure you include here all the variables you will need.
keep year hhid pid fexp_* sample male urban age* h_head skilled_* unskilled_* h_size depen welfare_* lp_*usd_* poor*1 tot_lai_* pc_*_s active_* emplyd* unemplyd*

qui reshape wide *_s poor* , i(hhid pid) j(year)
	

* 6.3 - Changes in poverty and vulnerability status
******************************************************

loc init = sim_years[1,1]
di `init'


* Categories first simulated year
qui gen total`init' = 1

for any ${pline3} ${pline2} ${pline1}: qui gen old_poorX`init' = welfare_base <= X * (365/1200) if welfare_base != .
qui gen old_nonpoor`init' = welfare_base > (${pline3} * 365 / 1200) if welfare_base != .

for any ${pline3} ${pline2} ${pline1}: qui gen new_poorX`init' = poorX1`init' == 1 & old_poorX`init' == 0
for any ${pline3} ${pline2} ${pline1}: qui gen always_poorX`init' = poorX1`init' == 1 & old_poorX`init' == 1

qui gen new_nonpoor`init' = poor${pline3}1`init' == 0 & old_poor${pline3}`init' == 1
qui gen always_nonpoor`init' = poor${pline3}1`init' == 0 & old_poor${pline3}`init' == 0


* Categories for the other simulated years
loc end = sim_years[n_sim_years,1]
loc second = `init' + 1

forvalues a = `second' / `end' {
	
	loc prev = `a' - 1
	
	qui gen total`a' = 1
	
	for any ${pline3} ${pline2} ${pline1}: qui gen new_poorX`a' = poorX1`a' == 1 & poorX1`prev' == 0
	for any ${pline3} ${pline2} ${pline1}: qui gen always_poorX`a' = poorX1`a' == 1 & poorX1`prev' == 1
	
	qui gen new_nonpoor`a' = poor${pline3}1`a' == 0 & poor${pline3}1`prev' == 1
	qui gen always_nonpoor`a' = poor${pline3}1`a' == 0 & poor${pline3}1`prev' == 0

}


* Profiles
forvalues i = `init' / `end' {
	
	local categories new_poor${pline1} always_poor${pline1} new_poor${pline2} always_poor${pline2} new_poor${pline3} always_poor${pline3} new_nonpoor always_nonpoor total
	foreach kind of local categories {
				
		qui gen pop_`kind'`i' = 1 if `kind'`i' == 1
		qui gen urban_`kind'`i' = urban if `kind'`i' == 1
		qui gen h_size_`kind'`i' = h_size if `kind'`i' == 1
		qui gen depend_`kind'`i' = depen if `kind'`i' == 1
		qui gen welf_s_`kind'`i' = welfare_s`i' if `kind'`i' == 1
		*qui gen pg_`kind'`i' = pg`i' if `kind'`i' == 1
		qui gen ti_`kind'`i' = pc_inc_s`i' if `kind'`i' == 1
		qui gen li_`kind'`i' = pc_lai_s`i' if `kind'`i' == 1
		qui gen nli_`kind'`i' = pc_nlai_s`i' if `kind'`i' == 1
		qui gen hh_age_`kind'`i' = age if `kind'`i' == 1 & h_head == 1
		qui gen hh_male_`kind'`i' = male if `kind'`i' == 1 & h_head == 1
		qui gen hh_emp_`kind'`i' = emplyd_s`i' if `kind'`i' == 1 & h_head == 1
		qui gen hh_unemp_`kind'`i' = unemplyd_s`i' if `kind'`i' == 1 & h_head == 1
		qui gen hh_sk_`kind'`i' = skilled_s`i' if `kind'`i' == 1 & h_head == 1
		qui gen hh_unsk_`kind'`i' = unskilled_s`i' if `kind'`i' == 1 & h_head == 1
		qui gen age014_`kind'`i' = age014 if `kind'`i' == 1
		qui gen age1524_`kind'`i' = age1524 if `kind'`i' == 1
		qui gen age2534_`kind'`i' = age2534 if `kind'`i' == 1
		qui gen age3544_`kind'`i' = age3544 if `kind'`i' == 1
		qui gen age4554_`kind'`i' = age4554 if `kind'`i' == 1
		qui gen age5564_`kind'`i' = age5564 if `kind'`i' == 1
		qui gen age65p_`kind'`i' = age65p if `kind'`i' == 1
		qui gen male_`kind'`i' = male if `kind'`i' == 1
		qui gen female_`kind'`i' = !male if `kind'`i' == 1
		qui gen active_s_`kind'`i' = active_s`i' if `kind'`i' == 1
		qui gen emp_`kind'`i' = emplyd_s`i' if `kind'`i' == 1
		qui gen unemp_`kind'`i' = unemplyd_s`i' if `kind'`i' == 1
		qui gen sk_`kind'`i' = skilled_s`i' if `kind'`i' == 1
		qui gen unsk_`kind'`i' = unskilled_s`i' if `kind'`i' == 1
		qui gen pub_tr_`kind'`i' = pc_pubtr_s`i' if `kind'`i' == 1
		qui gen priv_tr_`kind'`i' = pc_privttr_s`i' if `kind'`i' == 1
		qui gen priv_tr_dom_`kind'`i' = pc_dom_remit_s`i' if `kind'`i' == 1
		qui gen priv_tr_int_`kind'`i' = pc_int_remit_s`i' if `kind'`i' == 1
		qui gen priv_tr_ns_`kind'`i' = pc_ns_remit_s`i' if `kind'`i' == 1
		qui gen pensions_`kind'`i' = pc_pensions_s`i' if `kind'`i' == 1
		qui gen capital_`kind'`i' = pc_capital_s`i' if `kind'`i' == 1
		qui gen otherinla_`kind'`i' = pc_otherinla_s`i' if `kind'`i' == 1 
		qui gen renta_imp_`kind'`i' = pc_renta_imp_s`i' if `kind'`i' == 1 
	}
	
	* Data collapse
	
	preserve
	qui collapse (sum) pop* (mean) *_s_* /*pg**/ urban_* h_size_* ti_* li_* nli_* hh_* pub_tr_* priv_tr_* age*_* depend_* male_* female_* sk_* unsk_* emp_* unemp_* pensions_* capital_* otherinla_* renta_imp_* [iw = fexp_s`i']
	keep *`i'
	ren *`i' *
	qui xpose, clear varname
	ren (v1 _varname) (y_`i' indicator)
	qui order indicator
	sort indicator
	tempfile results_`i'
	qui save `results_`i'', replace
	restore
}


* Merge the collapsed data
use `results_`init'', clear

forvalues a = `second' / `end' {
	qui merge 1:1 indicator using `results_`a'', nogenerate
}

tempfile dynamics
qui save `dynamics', replace

use "${country_path}\descriptives.dta", clear
append using `dynamics'

sort indicator
duplicates tag indicator, gen(tag)
egen nmis=rmiss2(y_*)
drop if tag == 1 & nmis != 0
drop tag nmis
qui export excel using "${outfile}", sheet(descriptives) firstrow(variables) sheetreplace
erase "${country_path}\descriptives.dta"