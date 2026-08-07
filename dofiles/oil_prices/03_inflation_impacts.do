
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
	
	*-------------------------------------------------------------------------
	* 1. SHARE OF AGRICULTURE INCOME FROM EMPLOYERS AND SELF-EMPLOYMENT
	*-------------------------------------------------------------------------
	* 1.a Agricultural workers in self-employment(or Food Producer)
	qui gen agr_worker1 = inlist(sect_main6_s,1,2) 	& inlist(labor_rel,2,3) // Food producers (FP) main activity
	qui gen agr_worker2 = inlist(sect_secu,1,2) 	& inlist(labor_rel2,2,3) // Food producers (FP) secondary activity
	
	* 1.b Agriculture Income from main and secondary occupation self-employment 
	qui gen inagr1   = agr_worker1 * lai_m_s 
	qui gen inagr2   = agr_worker2 * lai_s_s 
	qui egen inagr   = rowtotal(inagr1 inagr2), m
	
	*1.c Household Agriculture labor income 
	qui bysort country hhid: egen inagr_h = sum(inagr)    // HH Agricultural Labor Income from FPs
	qui bysort country hhid: egen inc_h   = sum(ypc_26)   // HH Total Labor Income from FPs
	qui gen     sh_agrinc = inagr_h / inc_h if inc_h > 0  // Share of household agriculture labor income over total household income 
	qui replace sh_agrinc = 0 if inc_h == 0               // Filling the missings 
	qui replace sh_agrinc = 0 if abs(sh_agrinc) > 1  	  // Discard no plausible values addressed in the harmonization and microsimulation (previous treatment to negative incomes)

	*-------------------------------------------------------------------------
	* 2. PARAMETERS: DIFFERENTIAL INFLATION -TOTAL, FOOD AND NON-FOOD; PRODUCTION STRUCTURE; SHARE OF FOOD CONSUMPTION
	*-------------------------------------------------------------------------
	* 2.1 Merge with prices inputs
	qui merge m:1 country using "${path}\Oil prices\input\pppfactors", keep(3) nogen
	
	* 2.2 Fertilizer variation 
	qui gen v_fert = incr_ins_agr * 100

	* 2.3. Merge with food shares
	if "`country'" == "IND" qui merge m:1 hhid using "${path}\food_vectors_SAR/`country'_food_share_2023_s2s", keep(1 3) keepusing(share_food) nogen
	else if "`country'" == "BTN" qui merge 1:1 hhid pid using "${path}\food_vectors_SAR/`country'_food_share_2022_s2s", keep(1 3) keepusing(share_food) nogen
	else qui merge 1:1 hhid pid using "${path}\food_vectors_SAR/`country'_food_share", keep(1 3) keepusing(share_food) nogen

	*-------------------------------------------------------------------------
	* 3. GAINS IN INCOME AND LOSSES IN PURCHASING POWER
	*-------------------------------------------------------------------------
	* 3.1 Convert income to nominal terms
	qui gen ypc_26_curr = ypc_26 * icp2021 * cpi2021

	* 3.2 Calculate new level of consumption in nominal terms
	qui gen cpc26         = welfare_s * icp2021 * cpi2021 // Per capita nominal consumption
	qui gen cpc_food26    = share_food * cpc26            // Food consumption
	qui gen cpc_nonfood26 = cpc26 - cpc_food26            // Non-food consumption
	
	* 3.3 New required consumption level under the new inflation
	qui gen cpc26_sim = cpc_food26 * (1 + inf_food) + cpc_nonfood26 * (1 + inf_nfood) // New nominal consumption accountig for inflation
	
	* 3.4.1 Additional income for NetFP
	qui gen agrinc26          = ypc_26_curr * sh_agrinc // Initial Nominal income from agriculture
	qui gen dif_inc_cons_food = agrinc26 - cpc_food26   // Difference between income and consumption from food - Definition of NET FOOD PRODUCER HH
	qui gen change_inc        = dif_inc_cons_food * (inf_food - fr_cost_agr * ( (${v_oil} * incr_cost_agr) + (v_fert * incr_cost_fert))) if dif_inc_cons_food > 0 & country != "MDV"
	replace change_inc        =  0 if country == "MDV" // Does not apply due to the fact that the Agriculture Sector is Fishery in MDV
	qui gen change_inc_sim    = change_inc / icp2021 / cpi2021 
	
	* 3.4.2 New Income and Consumption levels from NetFP changes
	qui egen ypc_26_sim      = rowtotal(ypc_26_curr change_inc)
	qui gen pc_inc_sim       = ypc_26_sim / icp2021 / cpi2021
	qui gen inc_cons_ratio   = ypc_26_curr / cpc26
	qui gen new_cons_agr     = change_inc / inc_cons_ratio 
	qui gen new_cons_agr_sim = new_cons_agr / icp2021 / cpi2021 
	
	* 3.5 Lost in purchasing power for higher prices
	qui gen ppw_lost       = (cpc_food26 * inf_food) + (cpc_nonfood26 * inf_nfood)
	qui gen cons_lost      = - ppw_lost
	qui gen cons_lost_sim  = cons_lost / icp2021 / cpi2021
	
	* 3.6 New consumption level
	qui egen    consumption = rowtotal(cpc26 new_cons_agr cons_lost)
	qui replace consumption = . if cpc26 == .
	qui gen     welfare_sim = consumption / icp2021 / cpi2021
	
	*-------------------------------------------------------------------------
	* 4. DISTRIBUTIONAL MEASURES
	*-------------------------------------------------------------------------
	* 4.1 Common variables
	gen lp_30usd_ppp = (3.0 * 365/12)
	gen lp_42usd_ppp = (4.2 * 365/12)
	gen lp_83usd_ppp = (8.3 * 365/12)
	gen lp_170usd_ppp = (17 * 365/12)
	
	* 4.2 Quintiles (for results file)
	*qui xtile quintile = welfare_s [w = pondera_26], nq(5)
	
	* 4.3 Gini Coefficient
	qui ineqdec0 welfare_s [w=pondera_26]
	qui gen gini_0 = r(gini)
	
	* 4.4 Poverty
	for any 30 42 83 170: qui gen pov_X_0 = welfare_s <= lp_Xusd_ppp if welfare_s != .
	
	* 4.5 Poverty Gap ($4.2 USD)
	qui apoverty welfare_s [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_0 = r(pogapr_1)

	* 4.6 New Gini Coefficient
	qui ineqdec0 welfare_sim [w=pondera_26]
	qui gen gini_1 = r(gini)
	
	* 4.7  New Poverty and Vulnerability
	for any 30 42 83 170: qui gen pov_X_1 = welfare_sim <= lp_Xusd_ppp if welfare_sim != .

	* 4.8  Poverty Gap ($4.2 USD)
	qui apoverty welfare_sim [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_1 = r(pogapr_1)
	
	* 4.9  Rename Consumption aggregates
	qui ren (welfare_s) (welfare_pre)
	
	* 4.10  Merge with last data
	qui merge 1:1 country hhid pid using "${input_conflict}", keep(3) keepusing(welfare_s) nogen
	
	* 4.11  Last Gini Coefficient
	qui ineqdec0 welfare_s [w=pondera_26]
	qui gen gini_2 = r(gini)
	
	* 4.12 Last Poverty and Vulnerability
	for any 30 42 83 170: qui gen pov_X_2 = welfare_s <= lp_Xusd_ppp if welfare_s != .
	
	* 4.13  Poverty Gap ($4.2 USD)
	qui apoverty welfare_s [w=pondera] , varpl(lp_42usd_ppp) pgr
	qui gen gap_2 = r(pogapr_1)
	
	qui destring gap_*, replace
	ren welfare_s welfare_post
	
	drop if welfare_pre == . & welfare == . & welfare_post == .
	
	*-------------------------------------------------------------------------
	* 5.  SAVE country file or append it 
	*----------------------------------------------
	qui append using "${out_sim}"
	qui save "${out_sim}", replace
}


/*=================================================================================================*/
**# 3. Results at the Country Level
/*=================================================================================================*/

	qui use  "${out_sim}", clear
	gen pop = 1
	
	* a. Aggregate Poverty, Vulnerability, and Gini, and Changes in welfare measures
	preserve
	qui collapse gini_* pov_* gap_* inf_food inf_tot (sum) pop [iw=pondera_26], by(country)
	qui reshape long gini_ pov_30_ pov_42_ pov_83_ pov_170_ gap_, i(country) j(indicator)
	qui ren (gini_ gap_) (pov_gini_ pov_gap_)
	qui reshape long pov_, i(country indicator) j(value) string
	qui reshape wide pov_, i(country value) j(indicator)
	for any inf_food inf_tot: qui replace X = X * 100
	for any pov_0 pov_1 pov_2: qui replace X = X * 100 if value != "gap_"
	qui gen change = pov_2 - pov_0
	order change, before(pop)
	qui export excel using "${out}", sheet("country_aggregates") firstrow(variables) sheetreplace
	restore

	* b. Mean income by quintile
	qui for any pre sim post: gen quintile_X = .
	
	levelsof country, local(countries)
	foreach country of local countries {
		qui for any pre sim post: xtile quintile_X_`country' = welfare_X [w = pondera_26] if country == "`country'", nq(5)
		for any pre sim post: replace quintile_X = quintile_X_`country' if country == "`country'"
	}
	
	preserve
	qui collapse welfare_pre [iw = pondera_26], by(country quintile_pre)
	ren quintile_pre quintile
	tempfile welfare_pre
	save `welfare_pre'
	restore 
	
	preserve
	qui collapse welfare_sim [iw = pondera_26], by(country quintile_sim)
	ren quintile_sim quintile
	tempfile welfare_sim
	save `welfare_sim'
	restore 
	
	preserve
	qui collapse welfare_post [iw = pondera_26], by(country quintile_post)
	ren quintile_post quintile
	qui merge 1:1 country quintile using `welfare_pre', nogen
	qui merge 1:1 country quintile using `welfare_sim', nogen
	
	order country quintile welfare_pre welfare_sim welfare_post
	
	qui gen init_cons_variation = (welfare_sim / welfare_pre - 1) * 100
	qui gen tot_cons_variation = (welfare_post / welfare_pre - 1) * 100
	qui export excel using "${out}", sheet("icc") firstrow(variables) sheetreplace
	restore

	* c. Transitions
	qui gen condition_pre = ""
	qui replace condition_pre = "1. Poor at 3.0" if pov_30_0 == 1
	qui replace condition_pre = "2. Poor at 4.2" if pov_42_0 == 1 & pov_30_0 != 1
	qui replace condition_pre = "3. Poor at 8.3" if pov_83_0 == 1 & pov_42_0 != 1
	qui replace condition_pre = "4. Vulnerable" if pov_170_0 == 1 & pov_83_0 != 1
	qui replace condition_pre = "5. Non-poor Non-vulnerable" if welfare_pre > lp_170usd_ppp & welfare_pre != .

	qui gen condition_post = ""
	qui replace condition_post = "1. Poor at 3.0" if pov_30_2 == 1
	qui replace condition_post = "2. Poor at 4.2" if pov_42_2 == 1 & pov_30_2 != 1
	qui replace condition_post = "3. Poor at 8.3" if pov_83_2 == 1 & pov_42_2 != 1
	qui replace condition_post = "4. Vulnerable" if pov_170_2 == 1 & pov_83_2 != 1
	qui replace condition_post = "5. Non-poor Non-vulnerable" if welfare_post > lp_170usd_ppp & welfare_post != .

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

	qui shell "C:/Program Files/R/R-4.5.3/bin/R.exe" --vanilla <"${path}/Oil prices/dofiles/transitions.R"


/*=================================================================================================*/
**# 4. Results at the Regional Level WITH India
/*=================================================================================================*/

	qui use  "${out_sim}", clear
	gen pop = 1

	* a. Aggregate Poverty, Vulnerability, and Gini, and Changes in welfare measures
	preserve

	qui for any 0 1 2 : drop gini_X gap_X

	qui ineqdec0 welfare_pre [w=pondera_26]
	qui gen gini_0 = r(gini)
	qui ineqdec0 welfare_sim [w=pondera_26]
	qui gen gini_1 = r(gini)
	qui ineqdec0 welfare_post [w=pondera_26]
	qui gen gini_2 = r(gini)

	qui apoverty welfare_pre [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_0 = r(pogapr_1)
	qui apoverty welfare_sim [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_1 = r(pogapr_1)
	qui apoverty welfare_post [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_2 = r(pogapr_1)
	qui destring gap_*, replace
	
	qui collapse gini_* pov_* gap_* inf_food inf_tot (sum) pop [iw=pondera_26]
	qui gen country = "SAR"
	qui reshape long gini_ pov_30_ pov_42_ pov_83_ pov_170_ gap_, i(country) j(indicator)
	qui ren (gini_ gap_) (pov_gini_ pov_gap_)
	qui reshape long pov_, i(country indicator) j(value) string
	qui reshape wide pov_, i(country value) j(indicator)
	qui for any inf_food inf_tot: replace X = X * 100
	qui for any pov_0 pov_1 pov_2: replace X = X * 100 if value != "gap_"
	qui gen change = pov_2 - pov_0
	order change, before(pop)
	qui export excel using "${out}", sheet("sar_aggregates") firstrow(variables) sheetreplace
	restore

	* b. Mean income by quintile
	qui for any pre sim post: xtile quintile_X = welfare_X [w = pondera_26], nq(5)
	
	preserve
	qui collapse welfare_pre [iw = pondera_26], by(quintile_pre)
	ren quintile_pre quintile
	tempfile welfare_pre
	save `welfare_pre'
	restore 
	
	preserve
	qui collapse welfare_sim [iw = pondera_26], by(quintile_sim)
	ren quintile_sim quintile
	tempfile welfare_sim
	save `welfare_sim'
	restore 
	
	preserve
	qui collapse welfare_post [iw = pondera_26], by(quintile_post)
	ren quintile_post quintile
	qui merge 1:1 quintile using `welfare_pre', nogen
	qui merge 1:1 quintile using `welfare_sim', nogen
	
	order quintile welfare_pre welfare_sim welfare_post
	
	qui gen init_cons_variation = (welfare_sim / welfare_pre - 1) * 100
	qui gen tot_cons_variation = (welfare_post / welfare_pre - 1) * 100
	qui export excel using "${out}", sheet("icc_sar") firstrow(variables) sheetreplace
	restore
	

	* c. Transitions
	qui gen     condition_pre = ""
	qui replace condition_pre = "1. Poor at 3.0" if pov_30_0 == 1
	qui replace condition_pre = "2. Poor at 4.2" if pov_42_0 == 1 & pov_30_0 != 1
	qui replace condition_pre = "3. Poor at 8.3" if pov_83_0 == 1 & pov_42_0 != 1
	qui replace condition_pre = "4. Vulnerable" if pov_170_0 == 1 & pov_83_0 != 1
	qui replace condition_pre = "5. Non-poor Non-vulnerable" if welfare_pre > lp_170usd_ppp & welfare_pre != .

	qui gen     condition_post = ""
	qui replace condition_post = "1. Poor at 3.0" if pov_30_2 == 1
	qui replace condition_post = "2. Poor at 4.2" if pov_42_2 == 1 & pov_30_2 != 1
	qui replace condition_post = "3. Poor at 8.3" if pov_83_2 == 1 & pov_42_2 != 1
	qui replace condition_post = "4. Vulnerable" if pov_170_2 == 1 & pov_83_2 != 1
	qui replace condition_post = "5. Non-poor Non-vulnerable" if welfare_post > lp_170usd_ppp & welfare_post != .


	qui gen i = 1
	drop if welfare_pre == .

	qui collapse (sum) i [iw = pondera_26], by(condition_pre condition_post)
	qui ren i value
	qui sort condition_pre condition_post
	qui export excel using "${out}", sheet("transitions_sar") firstrow(variables) sheetreplace


/*=================================================================================================*/
**# 5. Results at the Regional Level WITHOUT India
/*=================================================================================================*/

	qui use  "${out_sim}", clear
	gen pop = 1
	drop if country == "IND"

	* a. Aggregate Poverty, Vulnerability, and Gini, and Changes in welfare measures
	preserve

	qui for any 0 1 2 : drop gini_X gap_X

	qui ineqdec0 welfare_pre [w=pondera_26]
	qui gen gini_0 = r(gini)
	qui ineqdec0 welfare_sim [w=pondera_26]
	qui gen gini_1 = r(gini)
	qui ineqdec0 welfare_post [w=pondera_26]
	qui gen gini_2 = r(gini)

	qui apoverty welfare_pre [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_0 = r(pogapr_1)
	qui apoverty welfare_sim [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_1 = r(pogapr_1)
	qui apoverty welfare_post [w=pondera_26] , varpl(lp_42usd_ppp) pgr
	qui gen gap_2 = r(pogapr_1)
	qui destring gap_*, replace
		
	qui collapse gini_* pov_* gap_* inf_food inf_tot (sum) pop [iw=pondera_26]
	qui gen country = "SAR w/o IND"
	qui reshape long gini_ pov_30_ pov_42_ pov_83_ pov_170_ gap_, i(country) j(indicator)
	qui ren (gini_ gap_) (pov_gini_ pov_gap_)
	qui reshape long pov_, i(country indicator) j(value) string
	qui reshape wide pov_, i(country value) j(indicator)
	qui for any inf_food inf_tot: replace X = X * 100
	qui for any pov_0 pov_1 pov_2: replace X = X * 100 if value != "gap_"
	qui gen change = pov_2 - pov_0
	order change, before(pop)
	qui export excel using "${out}", sheet("sar_aggregates_wo_IND") firstrow(variables) sheetreplace
	restore

	* b. Mean income by quintile
	qui for any pre sim post: xtile quintile_X = welfare_X [w = pondera_26], nq(5)
	
	preserve
	qui collapse welfare_pre [iw = pondera_26], by(quintile_pre)
	ren quintile_pre quintile
	tempfile welfare_pre
	save `welfare_pre'
	restore 
	
	preserve
	qui collapse welfare_sim [iw = pondera_26], by(quintile_sim)
	ren quintile_sim quintile
	tempfile welfare_sim
	save `welfare_sim'
	restore 
	
	preserve
	qui collapse welfare_post [iw = pondera_26], by(quintile_post)
	ren quintile_post quintile
	qui merge 1:1 quintile using `welfare_pre', nogen
	qui merge 1:1 quintile using `welfare_sim', nogen
	
	order quintile welfare_pre welfare_sim welfare_post
	
	qui gen init_cons_variation = (welfare_sim / welfare_pre - 1) * 100
	qui gen tot_cons_variation = (welfare_post / welfare_pre - 1) * 100
	qui export excel using "${out}", sheet("icc_sar_wo_IND") firstrow(variables) sheetreplace
	restore
	

	* c. Transitions
	qui gen     condition_pre = ""
	qui replace condition_pre = "1. Poor at 3.0" if pov_30_0 == 1
	qui replace condition_pre = "2. Poor at 4.2" if pov_42_0 == 1 & pov_30_0 != 1
	qui replace condition_pre = "3. Poor at 8.3" if pov_83_0 == 1 & pov_42_0 != 1
	qui replace condition_pre = "4. Vulnerable" if pov_170_0 == 1 & pov_83_0 != 1
	qui replace condition_pre = "5. Non-poor Non-vulnerable" if welfare_pre > lp_170usd_ppp & welfare_pre != .

	qui gen     condition_post = ""
	qui replace condition_post = "1. Poor at 3.0" if pov_30_2 == 1
	qui replace condition_post = "2. Poor at 4.2" if pov_42_2 == 1 & pov_30_2 != 1
	qui replace condition_post = "3. Poor at 8.3" if pov_83_2 == 1 & pov_42_2 != 1
	qui replace condition_post = "4. Vulnerable" if pov_170_2 == 1 & pov_83_2 != 1
	qui replace condition_post = "5. Non-poor Non-vulnerable" if welfare_post > lp_170usd_ppp & welfare_post != .


	qui gen i = 1
	drop if welfare_pre == .

	qui collapse (sum) i [iw = pondera_26], by(condition_pre condition_post)
	qui ren i value
	qui sort condition_pre condition_post
	qui export excel using "${out}", sheet("transitions_sar_wo_IND") firstrow(variables) sheetreplace
