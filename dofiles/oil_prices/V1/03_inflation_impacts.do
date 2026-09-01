
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

* Necessary files
clear
save "${out_sim}", replace emptyok // Simulated data

* Prices inputs
import excel "${path}\Oil prices\input\pppfactors.xlsx", sheet("parameters") firstrow case(lower) clear
save "${path}\Oil prices\input\pppfactors", replace


/*=================================================================================================*/
**# 2. Country-level Simulation
/*=================================================================================================*/


foreach country of global countries {
	
	* a - Loading the data
	qui use "${input_baseline}", clear
	
	di in red "`country'"
	keep if country == "`country'"
	
	* b. Common variables
	
	qui gen agr_worker1 = inlist(sect_main_s,1,2) & inlist(labor_rel,2,3) // Food producers (FP)
	qui gen agr_worker2 = inlist(sect_main6_s,1,2) & inlist(labor_rel,2,3) // Food producers (FP)
	
	qui gen inagr1 = agr_worker1 * lai_m_s // Income from FP, replaced new_X by lai_m_s
	qui gen inagr2 = agr_worker2 * lai_s_s // Income from FP, replaced new_X by lai_m_s
	qui egen inagr = rowtotal(inagr1 inagr2), m
	qui egen inc_all = rowtotal(lai_m_s lai_s_s), m
	
	qui bysort country hhid: egen inagr_h = sum(inagr) // HH Income from FPs
	qui bysort country hhid: egen inc_h = sum(inc_all) // HH Income from FPs
	qui gen sh_agrinc = inagr_h / inc_h if inc_h > 0 // Share of HH from NFPs
	qui replace sh_agrinc = 0 if inc_h == 0 // Filling the missings
	gen lp_30usd_ppp = (3.0 * 365/12)
	gen lp_42usd_ppp = (4.2 * 365/12)
	gen lp_83usd_ppp = (8.3 * 365/12)
	
	* c. Quintiles (for results file)
	qui xtile quintile = welfare_s [w = pondera_26], nq(5)
	
	* d. Gini Coefficient
	qui ineqdec0 welfare_s [w=pondera_26]
	qui gen gini_0 = r(gini)
	
	* e. Poverty
	for any 30 42 83: qui gen pov_X_0 = welfare_s <= lp_Xusd_ppp if welfare_s != .
	
	* f. Poverty Gap ($4.2 USD)
	qui apoverty welfare_s [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_0 = r(pogapr_1)

	* g. Merge with prices inputs
	qui merge m:1 country using "${path}\Oil prices\input\pppfactors", keep(3) nogen
	
	* h. Fertilizer variation 
	qui gen v_fert = incr_ins_agr * 100

	* i. Merge with food shares
	qui merge 1:1 hhid pid using "${path}\food_vectors_SAR/BGD_food_share", keep(1 3) keepusing(food_share) nogen

	* j. Convert income to nominal terms
	qui gen ypc_26_curr = ypc_26 * icp2021 * cpi2021

	* k. Calculate new level of consumption in nominal terms
	qui gen cpc26 = welfare_s * icp2021 * cpi2021 // Per capita nominal consumption
	qui gen cpc_food26 = food_share * cpc26 / 100 // Food consumption
	qui gen cpc_nonfood26 = cpc26 - cpc_food26 // Non-food consumption
	
	* l. New required consumption level under the new inflation
	qui gen cpc26_sim = cpc_food26 * (1 + inf_food) + cpc_nonfood26 * (1 + inf_nfood) // New nominal consumption accountig for inflation
	
	* m. Lost in purchasing power for higher prices
	qui gen ppw_lost = (cpc_food26 * inf_food) + (cpc_nonfood26 * inf_nfood)
	
	* n. Additional income for NFP
	qui gen agrinc26 = ypc_26_curr * sh_agrinc // Initial Nominal income from agriculture
	qui gen dif_inc_cons_food = agrinc26 - cpc_food26 // Difference between income and consumption from food
	qui gen change_inc = dif_inc_cons_food * (inf_food - fr_cost_agr * ( (${v_oil} * incr_cost_agr) + (v_fert * incr_cost_fert))) if dif_inc_cons_food > 0
	
	* o. New Income and Consumption levels from NFP changes
	qui egen ypc_26_sim = rowtotal(ypc_26_curr change_inc)
	
	qui gen inc_cons_ratio = ypc_26_curr / cpc26
	qui gen new_cons_agr = change_inc / inc_cons_ratio
	
	qui gen pc_inc_sim = ypc_26_sim / icp2021 / cpi2021
	
	* p. New consumption level
	qui gen cons_lost = - ppw_lost
	qui gen cons_lost_sim = (- ppw_lost) / icp2021 / cpi2021
	qui egen consumption_sim = rowtotal(cpc26 new_cons_agr cons_lost)
	qui replace consumption_sim = . if cpc26 == .
	
	* q. Convert to real terms
	qui gen welfare_sim = consumption_sim / icp2021 / cpi2021

	* r. New Gini Coefficient
	qui ineqdec0 welfare_sim [w=pondera_26]
	qui gen gini_1 = r(gini)
	
	* s. New Poverty and Vulnerability
	for any 30 42 83: qui gen pov_X_1 = welfare_sim <= lp_Xusd_ppp if welfare_sim != .

	* t. Poverty Gap ($4.2 USD)
	qui apoverty welfare_sim [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_1 = r(pogapr_1)
	
	* u. Rename Consumption aggregates
	qui ren (welfare_s) (welfare_pre)
	
	* v. Merge with last data
	qui merge 1:1 country hhid pid using "${input_conflict}", keep(3) keepusing(welfare_s) nogen
	
	* w. Last Gini Coefficient
	qui ineqdec0 welfare_s [w=pondera_26]
	qui gen gini_2 = r(gini)
	
	* x. Last Poverty and Vulnerability
	for any 30 42 83: qui gen pov_X_2 = welfare_s <= lp_Xusd_ppp if welfare_s != .
	
	* y. Poverty Gap ($4.2 USD)
	qui apoverty welfare_s [w=pondera] , varpl(lp_42usd_ppp) pgr
	qui gen gap_2 = r(pogapr_1)
	
	qui destring gap_*, replace
	
	* z. save country file or append it 
	qui append using "${out_sim}"
	qui save "${out_sim}", replace
}


/*=================================================================================================*/
**# 3. Results at the Country Level
/*=================================================================================================*/

	qui use  "${out_sim}", clear

	* a. Aggregate Poverty, Vulnerability, and Gini, and Changes in welfare measures
	preserve
	qui collapse gini_* pov_* gap_* inf_food inf_tot [iw=pondera_26], by(country)
	qui reshape long gini_ pov_30_ pov_42_ pov_83_ gap_, i(country) j(indicator)
	qui ren (gini_ gap_) (pov_gini_ pov_gap_)
	qui reshape long pov_, i(country indicator) j(value) string
	qui reshape wide pov_, i(country value) j(indicator)
	for any inf_food inf_tot: qui replace X = X * 100
	for any pov_0 pov_1 pov_2: qui replace X = X * 100 if value != "gap_"
	qui gen change = pov_1 - pov_0
	qui export excel using "${out}", sheet("country_aggregates") firstrow(variables) sheetreplace
	restore

	* b. Mean income by quintile
	preserve
	qui collapse welfare_pre welfare_sim [iw = pondera_26], by(country quintile)
	qui gen cons_variation = (welfare_sim / welfare_pre - 1) * 100
	qui export excel using "${out}", sheet("icc") firstrow(variables) sheetreplace
	restore

	* c. Transitions
	qui gen condition_pre = ""
	qui replace condition_pre = "1. Poor at 3.0" if pov_30_0 == 1
	qui replace condition_pre = "2. Poor at 4.2" if pov_42_0 == 1 & pov_30_0 != 1
	qui replace condition_pre = "3. Poor at 8.3" if pov_83_0 == 1 & pov_42_0 != 1
	qui replace condition_pre = "4. Non-poor" if welfare_pre > lp_83usd_ppp & welfare_pre != .

	qui gen condition_post = ""
	qui replace condition_post = "1. Poor at 3.0" if pov_30_1 == 1
	qui replace condition_post = "2. Poor at 4.2" if pov_42_1 == 1 & pov_30_1 != 1
	qui replace condition_post = "3. Poor at 8.3" if pov_83_1 == 1 & pov_42_1 != 1
	qui replace condition_post = "4. Non-poor" if welfare_sim > lp_83usd_ppp & welfare_sim != .

	qui gen i = 1
	drop if welfare_pre == .

	preserve
	qui collapse (sum) i [iw = pondera_26], by(country condition_pre condition_post)
	qui ren i value
	qui gen value_m = value / 1000000
	qui sort country condition_pre condition_post
	qui export excel using "${out}", sheet("transitions") firstrow(variables) sheetreplace
	restore

	qui keep if condition_pre != condition_post
	qui collapse (sum) i [iw = pondera_26], by(country condition_pre condition_post)
	qui ren i value
	qui gen value_m = value / 1000000
	qui export excel using "${out}", sheet("transitions2") firstrow(variables) sheetreplace
	save "${path}\Oil prices\output\transitions.dta", replace

	qui shell "C:/Program Files/R/R-4.5.2/bin/R.exe" --vanilla <"${path}/Oil prices/dofiles/transitions.R"


/*=================================================================================================*/
**# 3. Results at the Regional Level
/*=================================================================================================*/

	qui use  "${out_sim}", clear

	* a. Aggregate Poverty, Vulnerability, and Gini, and Changes in welfare measures
	preserve

	qui for any 0 1 2 : drop gini_X gap_X

	qui ineqdec0 welfare_pre [w=pondera_26]
	qui gen gini_0 = r(gini)
	qui ineqdec0 welfare_sim [w=pondera_26]
	qui gen gini_1 = r(gini)
	qui ineqdec0 welfare_s [w=pondera_26]
	qui gen gini_2 = r(gini)

	qui apoverty welfare_pre [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_0 = r(pogapr_1)
	qui apoverty welfare_sim [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_1 = r(pogapr_1)
	qui apoverty welfare_s [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_2 = r(pogapr_1)
	qui destring gap_*, replace
		
	qui collapse gini_* pov_* gap_* inf_food inf_tot [iw=pondera_26]
	qui gen country = "SAR"
	qui reshape long gini_ pov_30_ pov_42_ pov_83_ gap_, i(country) j(indicator)
	qui ren (gini_ gap_) (pov_gini_ pov_gap_)
	qui reshape long pov_, i(country indicator) j(value) string
	qui reshape wide pov_, i(country value) j(indicator)
	qui for any inf_food inf_tot: replace X = X * 100
	qui for any pov_0 pov_1 pov_2: replace X = X * 100 if value != "gap_"
	qui gen change = pov_1 - pov_0
	qui export excel using "${out}", sheet("sar_aggregates") firstrow(variables) sheetreplace
	restore

	* b. Mean income by quintile
	preserve
	qui drop quintile
	qui xtile quintile = welfare_pre [w = pondera_26], nq(5)
	qui collapse welfare_pre welfare_sim [iw = pondera_26], by(quintile)
	qui gen cons_variation = (welfare_sim / welfare_pre - 1) * 100
	qui export excel using "${out}", sheet("icc_sar") firstrow(variables) sheetreplace
	restore

	* c. Transitions
	qui gen condition_pre = ""
	qui replace condition_pre = "1. Poor at 3.0" if pov_30_0 == 1
	qui replace condition_pre = "2. Poor at 4.2" if pov_42_0 == 1  & pov_30_0 != 1
	qui replace condition_pre = "3. Poor at 8.3" if pov_83_0 == 1  & pov_42_0 != 1
	qui replace condition_pre = "4. Non-poor" if welfare_pre > lp_83usd_ppp & welfare_pre != .

	qui gen condition_post = ""
	qui replace condition_post = "1. Poor at 3.0" if pov_30_1 == 1
	qui replace condition_post = "2. Poor at 4.2" if pov_42_1 == 1  & pov_30_1 != 1
	qui replace condition_post = "3. Poor at 8.3" if pov_83_1 == 1  & pov_42_1 != 1
	qui replace condition_post = "4. Non-poor" if welfare_sim > lp_83usd_ppp & welfare_sim != .

	qui gen i = 1
	drop if welfare_pre == .

	qui collapse (sum) i [iw = pondera_26], by(condition_pre condition_post)
	qui ren i value
	qui sort condition_pre condition_post
	qui export excel using "${out}", sheet("transitions_sar") firstrow(variables) sheetreplace
