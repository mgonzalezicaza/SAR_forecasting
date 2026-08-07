
**********************************************************************
*	Project:			Inflation Prices
*	Institution:		World Bank - ELCPV

*	Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org) based on R programs from Jaime Fernandez.
*	Creation Date:		08/02/2023

*	Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
*	Modification date: 	09/14/2023
**********************************************************************


**********************************************************************
* Load data - The 3 simulated vectors
**********************************************************************

use "${path}\Oil prices\input\income_components", clear

merge 1:1 country hhid pid using "${out_sim}", keepusing(age h_size lp_*) nogen

* Drop cases without welfare
count if welfare_pre == .
count if welfare_sim == .
count if welfare_post == .
drop if welfare_pre == . & welfare_sim == . & welfare_post == .


**********************************************************************
* Components
**********************************************************************

* Working members
for any pre sim post: gen employed_X = 1 if (inc_all_X != 0 & inc_all_X != .) & inrange(age,15,64)
for any pre sim post: replace employed_X = 1 if inc_all_X != 0 & inc_all_X != .
bysort country hhid: egen n_employed_pre = total(employed_pre)
bysort country hhid: egen n_employed_sim = total(employed_sim)
bysort country hhid: egen n_employed_post = total(employed_post)

* Non-dependants
for any pre sim post: gen non_dep_X = 1 if inrange(age,15,64)
for any pre sim post: replace non_dep_X = 1 if employed_X == 1
bysort country hhid: egen n_non_dep_pre = total(non_dep_pre)
bysort country hhid: egen n_non_dep_sim = total(non_dep_sim)
bysort country hhid: egen n_non_dep_post = total(non_dep_post)

* Labor dependency
for any pre sim post: gen depen_X = n_non_dep_X / h_size
for any pre sim post: replace depen_X = 0 if depen_X == .

* Working-people share
for any pre sim post: gen sh_empl_X = n_employed_X / n_non_dep_X
for any pre sim post: replace sh_empl_X = 0 if sh_empl_X == .

* labor income
for any pre sim post: replace pc_flai2_X = 0 if pc_flai2_X == .

for any pre post: gen ind_inc_X = inc_all_X if employed_X == 1
gen change_inc_hh = change_inc_sim / sh_empl_sim / depen_sim
egen ind_inc_sim = rowtotal(inc_all_sim change_inc_hh) if employed_sim == 1
bysort country hhid: egen lab_inc_pre  = mean(ind_inc_pre)
bysort country hhid: egen lab_inc_post = mean(ind_inc_post)
bysort country hhid: egen lab_inc_sim  = mean(ind_inc_sim)
for any pre sim post: replace lab_inc_X = 0 if lab_inc_X == . | pc_flai2_X == 0

* Check labor side
for any pre sim post: gen labor_check_X = depen_X * (sh_empl_X * lab_inc_X)
compare labor_check_pre pc_flai2_pre
*br hhid age labor_check_pre pc_flai2_pre depen_pre inc_all_pre sh_empl_pre lab_inc_pre if abs(labor_check_pre-pc_flai2_pre) > 1
compare labor_check_pre pc_flai2_pre if abs(labor_check_pre-pc_flai2_pre) > 1
drop labor_check_*

* Adjust labor incomes by the difference detected in Bangladesh (due to negative incomes)
for any pre sim post: ren lab_inc_X aux_lab_inc_X
for any pre sim post: gen diff_lab_X = diff_pc_inc_X / sh_empl_X / depen_X
for any pre sim post: egen lab_inc_X = rowtotal(aux_lab_inc_X diff_lab_X)
for any pre sim post: replace lab_inc_X = 0 if lab_inc_X == . | pc_flai2_X == 0

for any pre sim post: gen labor_check_X = depen_X * (sh_empl_X * lab_inc_X)
for any pre sim post: compare labor_check_X pc_flai2_X
*br hhid age labor_check_sim pc_flai2_sim depen_sim inc_all_sim sh_empl_sim lab_inc_sim if abs(labor_check_sim-pc_flai2_sim) > 1
compare labor_check_pre pc_flai2_pre if abs(labor_check_pre-pc_flai2_pre) > 1
*br hhid age labor_check_sim pc_flai2_sim depen_sim inc_all_sim sh_empl_sim lab_inc_sim if abs(labor_check_sim-pc_flai2_sim) > 1
drop labor_check_*

* non-labor income
for any pre sim post: replace pc_fnlai_X = 0 if pc_fnlai_X == .

* income to consumption ratio
count if ratio_pre == . // none
count if ratio_sim == . // none
count if ratio_post == . // none

count if ratio_pre == 0 // 1,217
count if ratio_sim == 0 // 1,217
count if ratio_post == 0 // 1,217
count if ratio_pre == 0 & ratio_sim == 0 & ratio_post == 0 //1,217 

* Base consumption
for any pre post: gen base_cons_X = 0
for any pre post: replace base_cons_X = welfare_X if ratio_X == 0
gen base_cons_sim = base_cons_pre

* Price Effects
*gen price_effect_pre = 1
*gen price_effect_sim = welfare_sim / welfare_post
*for any pre sim: replace price_effect_X = 0 if welfare_X == 0
for any pre post: gen cons_lost_X = 0

* Check incomes add up
for any pre sim post: egen aux_inc_X = rowtotal(pc_flai2_X pc_fnlai_X)
for any pre sim post: compare aux_inc_X pc_inc_X

* Check calculated welfare is close to microsimulated welfare
for any pre sim post: gen aux_welf_X = aux_inc_X / ratio_X if ratio_X != 0
for any pre sim post: replace aux_welf_X = base_cons_X if ratio_X == 0
for any pre sim post: egen aux2_welf_X = rowtotal(aux_welf_X cons_lost_X)
for any pre sim post: compare aux2_welf_X welfare_X
*br aux_welf_* welfare_* aux_inc_* pc_inc_* ratio_* base_cons* if abs(aux_welf_pre - welfare_pre)>1

* For Bhutan: Differences will remain due to the consumption rescaling, another factor needs to be incorporated into the decomposition to account for that
for any pre sim post: gen 		rescaling_factor_X = welfare_X / aux2_welf_X if country == "BTN"
for any pre sim post: replace 	rescaling_factor_X = 1 if country != "BTN"
drop aux_welf_*

* Check final equation
for any pre sim post: gen aux_welf_X = aux_inc_X / ratio_X if ratio_X != 0
for any pre sim post: replace aux_welf_X = base_cons_X if ratio_X == 0
for any pre sim post: replace aux_welf_X = aux_welf_X * rescaling_factor_X
for any pre sim post: egen aux3_welf_X = rowtotal(aux_welf_X cons_lost_X)
for any pre sim post: compare aux3_welf_X welfare_X
*br aux_welf_* welfare_* aux_inc_* pc_inc_* ratio_* base_cons* if abs(aux_welf_pre - welfare_pre)>1

/*
* Check calculated welfare is close to price affected welfare
gen aux_welf_sim1 = (aux_inc_post / ratio_post) if ratio_post != 0
replace aux_welf_sim1 = base_cons_post if ratio_post == 0
egen aux_welf_sim = rowtotal(aux_welf_sim1 price_effect_sim), m
compare aux_welf_sim welfare_sim
*/

**********************************************************************
* Country-level Decompositions
**********************************************************************

keep country hhid pid welfare_* pc_flai2_* pc_fnlai_* ratio_* base_cons_* cons_lost_* fexp lp_* depen_* sh_empl_* lab_inc_* pc_transfers_* pc_ns_remit_* pc_dom_remit_* pc_int_remit_* pc_pensions_* pc_capital_* pc_otherinla_* pc_renta_imp_* rescaling_factor_*

reshape long welfare pc_flai2 pc_fnlai ratio base_cons cons_lost depen sh_empl lab_inc pc_transfers pc_ns_remit pc_dom_remit pc_int_remit pc_pensions pc_capital pc_otherinla pc_renta_imp rescaling_factor, i(country hhid pid) j(scenario) string

replace scenario = "0" if scenario == "_pre"
replace scenario = "1" if scenario == "_sim"
replace scenario = "2" if scenario == "_post"
destring scenario, replace


foreach country of global countries {
	
	di in red "`country'"
	local i = 1
	
	preserve
	
	keep if country == "`country'"
	
	* Poverty headcount by scenario
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_30usd_ppp)
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_42usd_ppp)
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_83usd_ppp)
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_170usd_ppp)
	
	cap drop id
	egen id = group(hhid pid)
	
	* To avoid undefined division
	for any pc_flai pc_fnlai: replace X = 0 if ratio == 0
	replace ratio = 1  if pc_flai == 0 & pc_fnlai == 0 // To avoid undefined division
	
	for any depen sh_empl lab_inc pc_fnlai: replace X = 0 if ratio == 0
	replace ratio = 1 if (depen == 0 | sh_empl == 0 | lab_inc ==0 ) & pc_fnlai == 0 // To avoid undefined division
	
	local plines "30 42 83 170"
	foreach pline of local plines {
		
		* Big components
		adecomp welfare pc_flai pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,1), by(scenario) equation( (((c1+c2)/c3)+c4)*c5 +c6 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat big_comp = r(b)
		putexcel set "${out_mat}", sheet("deco_big_comp_`country'1") modify
		putexcel A`i' = matrix(big_comp)
		putexcel save
		
		adecomp welfare pc_flai pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,2), by(scenario) equation( (((c1+c2)/c3)+c4)*c5+c6 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat big_comp = r(b)
		putexcel set "${out_mat}", sheet("deco_big_comp_`country'2") modify
		putexcel A`i' = matrix(big_comp)
		putexcel save
			
			
		* Labor components
		adecomp welfare depen sh_empl lab_inc pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,1), by(scenario) equation( ((((c1*c2*c3)+c4)/c5)+c6)*c7 +c8 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat lab_comp = r(b)
		putexcel set "${out_mat}", sheet("lab_comp_`country'1") modify
		putexcel A`i' = matrix(lab_comp)
		putexcel save
		
		adecomp welfare depen sh_empl lab_inc pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,2), by(scenario) equation( ((((c1*c2*c3)+c4)/c5)+c6)*c7 +c8 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat lab_comp = r(b)
		putexcel set "${out_mat}", sheet("lab_comp_`country'2") modify
		putexcel A`i' = matrix(lab_comp)
		putexcel save
			
		local i = `i' + 10
	
	}
		
	restore
	
}


**********************************************************************
* Regional-level Decompositions
**********************************************************************

* SAR

di in red "SAR"

local i = 1
	
	* Poverty headcount by scenario
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_30usd_ppp)
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_42usd_ppp)
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_83usd_ppp)
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_170usd_ppp)
	
	cap drop id
	egen id = group(hhid pid)
	
	* To avoid undefined division
	for any pc_flai pc_fnlai: replace X = 0 if ratio == 0
	replace ratio = 1  if pc_flai == 0 & pc_fnlai == 0 // To avoid undefined division
	
	for any depen sh_empl lab_inc pc_fnlai: replace X = 0 if ratio == 0
	replace ratio = 1 if (depen == 0 | sh_empl == 0 | lab_inc ==0 ) & pc_fnlai == 0 // To avoid undefined division
	
	local plines "30 42 83 170"
	foreach pline of local plines {
		
		* Big components
		adecomp welfare pc_flai pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,1), by(scenario) equation( (((c1+c2)/c3)+c4)*c5 +c6 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat big_comp = r(b)
		putexcel set "${out_mat}", sheet("deco_big_comp_SAR1") modify
		putexcel A`i' = matrix(big_comp)
		putexcel save
		
		adecomp welfare pc_flai pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,2), by(scenario) equation( (((c1+c2)/c3)+c4)*c5+c6 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat big_comp = r(b)
		putexcel set "${out_mat}", sheet("deco_big_comp_SAR2") modify
		putexcel A`i' = matrix(big_comp)
		putexcel save
			
			
		* Labor components
		adecomp welfare depen sh_empl lab_inc pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,1), by(scenario) equation( ((((c1*c2*c3)+c4)/c5)+c6)*c7 +c8 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat lab_comp = r(b)
		putexcel set "${out_mat}", sheet("lab_comp_SAR1") modify
		putexcel A`i' = matrix(lab_comp)
		putexcel save
		
		adecomp welfare depen sh_empl lab_inc pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,2), by(scenario) equation( ((((c1*c2*c3)+c4)/c5)+c6)*c7 +c8 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat lab_comp = r(b)
		putexcel set "${out_mat}", sheet("lab_comp_SAR2") modify
		putexcel A`i' = matrix(lab_comp)
		putexcel save
			
	local i = `i' + 10
	
	}


* SAR without India

di in red "SAR without India"
keep if country!="IND"

local i = 1
	
	* Poverty headcount by scenario
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_30usd_ppp)
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_42usd_ppp)
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_83usd_ppp)
	for any 0 1 2: apoverty welfare [w=fexp] if scenario == X, varpl(lp_170usd_ppp)
	
	cap drop id
	egen id = group(hhid pid)
	
	* To avoid undefined division
	for any pc_flai pc_fnlai: replace X = 0 if ratio == 0
	replace ratio = 1  if pc_flai == 0 & pc_fnlai == 0 // To avoid undefined division
	
	for any depen sh_empl lab_inc pc_fnlai: replace X = 0 if ratio == 0
	replace ratio = 1 if (depen == 0 | sh_empl == 0 | lab_inc ==0 ) & pc_fnlai == 0 // To avoid undefined division
	
	local plines "30 42 83 170"
	foreach pline of local plines {
		
		* Big components
		adecomp welfare pc_flai pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,1), by(scenario) equation( (((c1+c2)/c3)+c4)*c5 +c6 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat big_comp = r(b)
		putexcel set "${out_mat}", sheet("deco_big_comp_SAR_wo_IND1") modify
		putexcel A`i' = matrix(big_comp)
		putexcel save
		
		adecomp welfare pc_flai pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,2), by(scenario) equation( (((c1+c2)/c3)+c4)*c5+c6 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat big_comp = r(b)
		putexcel set "${out_mat}", sheet("deco_big_comp_SAR_wo_IND2") modify
		putexcel A`i' = matrix(big_comp)
		putexcel save
			
			
		* Labor components
		adecomp welfare depen sh_empl lab_inc pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,1), by(scenario) equation( ((((c1*c2*c3)+c4)/c5)+c6)*c7 +c8 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat lab_comp = r(b)
		putexcel set "${out_mat}", sheet("lab_comp_SAR_wo_IND1") modify
		putexcel A`i' = matrix(lab_comp)
		putexcel save
		
		adecomp welfare depen sh_empl lab_inc pc_fnlai ratio base_cons rescaling_factor cons_lost [w=fexp] if inlist(scenario,0,2), by(scenario) equation( ((((c1*c2*c3)+c4)/c5)+c6)*c7 +c8 ) ind(fgt0) varpl(lp_`pline'usd_ppp) id(id)
		
		mat lab_comp = r(b)
		putexcel set "${out_mat}", sheet("lab_comp_SAR_wo_IND2") modify
		putexcel A`i' = matrix(lab_comp)
		putexcel save
			
	local i = `i' + 10
	
	}
	
