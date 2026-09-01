
************************************************************************
* 3 - Static Profiles
************************************************************************

** This section calculate profiles for populations according to poverty and vulnerability status. You can add more variables or more detailed status here.

* 3.1 - Variables for each profile
*************************************
local categories poor${pline3}1 poor${pline2}1 poor${pline1}1 nonpoor total
foreach kind of local categories {
			
	qui gen pop_`kind' 			= 1 				if `kind' == 1
	qui gen urban_`kind' 		= urban 			if `kind' == 1
	qui gen h_size_`kind' 		= h_size 			if `kind' == 1
	qui gen dependency_`kind' 	= depen 			if `kind' == 1
	qui gen welfare_`kind' 		= welfare_s			if `kind' == 1
	qui gen pg_`kind' 			= pg				if `kind' == 1
	qui gen ti_`kind' 			= pc_inc_s 			if `kind' == 1
	qui gen li_`kind' 			= pc_lai_s 			if `kind' == 1
	qui gen nli_`kind' 			= pc_nlai_s 		if `kind' == 1
	qui gen age014_`kind' 		= age014	 		if `kind' == 1
	qui gen age1524_`kind' 		= age1524 			if `kind' == 1
	qui gen age2534_`kind' 		= age2534 			if `kind' == 1
	qui gen age3544_`kind' 		= age3544 			if `kind' == 1
	qui gen age4554_`kind' 		= age4554 			if `kind' == 1
	qui gen age5564_`kind' 		= age5564 			if `kind' == 1
	qui gen age65p_`kind' 		= age65p 			if `kind' == 1
	qui gen male_`kind' 		= male 				if `kind' == 1
	qui gen female_`kind' 		= female 			if `kind' == 1
	qui gen inac_`kind' 		= inactive 			if `kind' == 1
	qui gen emp_`kind' 			= emplyd_s 			if `kind' == 1
	qui gen unemp_`kind' 		= unemplyd_s 		if `kind' == 1
	qui gen emp_agr_`kind' 		= emp_agr 			if `kind' == 1
	qui gen emp_ind_`kind' 		= emp_ind 			if `kind' == 1
	qui gen emp_ser_`kind' 		= emp_ser 			if `kind' == 1
	qui gen sal_`kind' 			= sal 				if `kind' == 1
	qui gen self_`kind' 		= self 				if `kind' == 1
	qui gen unpd_`kind' 		= unpd 				if `kind' == 1
	qui gen skilled_`kind' 		= skilled_s			if `kind' == 1
	qui gen unskilled_`kind' 	= unskilled_s 		if `kind' == 1
	qui gen income_`kind' 		= pc_inc_s 			if `kind' == 1
	qui gen pub_transf_`kind' 	= pc_pubtr_s	 	if `kind' == 1
	qui gen priv_transf_`kind' 	= pc_privttr_s 		if `kind' == 1
	qui gen pensions_`kind' 	= pc_pensions_s 	if `kind' == 1
	qui gen capital_`kind' 		= pc_capital_s 		if `kind' == 1
	qui gen othernli_`kind' 	= pc_otherinla_s 	if `kind' == 1 
	qui gen renta_imp_`kind' 	= pc_renta_imp_s 	if `kind' == 1 
}

	
* 3.2 - Descriptive data collapse
************************************
*** Collapse data information for the sheet "descriptives". This data is saved as a temporary file that will be merge with dynamic profiles later. This atage also saves information for MPO team.
		
preserve
* Countries names
qui wbopendata, indicator(SP.POP.TOTL) year(2019) projection clear
keep countrycode countryname
duplicates drop
tempfile countriesnames
qui save `countriesnames', replace
restore

preserve

* Descriptives
qui collapse (sum) pop* active_s (mean) participation=active_s welfare* pg pg_* pc_inc_s pc_lai_s pc_nlai_s pc_pubtr_s pc_privttr_s pc_pensions_s pc_capital_s pc_otherinla_s pc_renta_imp_s poor*1 nonpoor gini theil urban_* h_size_* ti_* li_* nli_* /*income_**/ gap_* emp* skilled* unskilled* agr_* ind_* ser_* inc* pub_transf_* priv_transf_* pensions_* capital_* othernli_* age*_* dependency_* male_* female_* unemp* inac* sal* self* unpd* [iw = fexp_s], by(year)
qui xpose, clear varname
ren _varname indicator
qui order indicator
qui replace indicator = "_year" if indicator == "year"
sort indicator
foreach var of varlist v1-v6 {
   rename `var' y_`=`var'[1]'
}
qui drop if indicator == "_year"
qui save "${country_path}\descriptives.dta", replace

* Output for MPO team
keep if inlist(indicator,"poor${pline1}1","poor${pline2}1","poor${pline3}1","gini","pg")
qui gen countrycode = "$country"
order countrycode
tempfile mpo
qui save `mpo', replace
cap use "${data_path}\poverty_SAR.dta", clear
qui drop if countrycode == "$country"
qui append using `mpo'
sort countrycode indicator
qui save "${data_path}\poverty_SAR.dta", replace

qui reshape long y_, i(countrycode indicator) j(year)
keep if inlist(indicator,"poor${pline1}1","poor${pline2}1","poor${pline3}1")
qui replace indicator = "1" if indicator == "poor${pline1}1"
qui replace indicator = "2" if indicator == "poor${pline2}1"
qui replace indicator = "3" if indicator == "poor${pline3}1"
destring indicator, replace
qui reshape wide y_, i(countrycode year) j(indicator)
ren y_* PovertyRate*
qui gen region = "SAR"
qui merge m:1 countrycode using `countriesnames', keep(1 3) nogenerate
order countrycode region countryname year PovertyRate1 PovertyRate2 PovertyRate3
la var year "Poverty line in PPP$ (per capita per day)"
la var PovertyRate1 "1 PovertyRate"
la var PovertyRate2 "2 PovertyRate"
la var PovertyRate3 "3 PovertyRate"
for any 1 2 3: qui replace PovertyRateX = PovertyRateX * 100
qui compress
qui save "${data_path}\Pov_SAR_micro.dta", replace
restore
	