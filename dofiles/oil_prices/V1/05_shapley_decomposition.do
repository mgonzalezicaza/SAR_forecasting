
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

merge 1:1 country hhid pid using "${out_sim}"


**********************************************************************
* Differenciate effects
**********************************************************************

* NFP Price Effects
/*gen aux_pre = -pc_inc_pre
egen NFP_eff = rowtotal(pc_inc_sim aux_pre), m
drop aux_pre*/
gen aux_pre = -welfare_pre
egen NFP_eff = rowtotal(welfare_sim aux_pre), m
drop aux_pre

* Food Consumption Effect
gen food_eff = cons_lost_sim

* Change in non-labor income
gen aux_pre_nlai = - pc_fnlai_pre 
egen var_nlab = rowtotal(pc_fnlai_post aux_pre_nlai), m
drop aux_pre_nlai

* Change in labor income
gen aux_pre_lai = - pc_flai2_pre 
egen var_lab = rowtotal(pc_flai2_post aux_pre_lai), m
drop aux_pre_lai


**********************************************************************
* Starting from Baseline 
**********************************************************************

* Baseline income + labor income change
egen base_w_lab = rowtotal(pc_inc_pre var_lab), m
gen base_lab = base_w_lab / ratio_pre

* Baseline income + non-labor income change
egen base_w_nlab = rowtotal(pc_inc_pre var_nlab), m
gen base_nlab = base_w_nlab / ratio_pre

* Baseline income + price effects
/*egen base_w_priceNFP = rowtotal(pc_inc_pre NFP_eff), m
gen base_priceNFP = base_w_priceNFP / ratio_pre*/
egen base_w_priceNFP = rowtotal(welfare_pre NFP_eff), m
gen base_priceNFP = base_w_priceNFP

* Baseline consumption + food_eff // Already in consumption scale
*egen base_pricefood = rowtotal(welfare_pre food_eff), m


**********************************************************************
* Starting from Conflict 
**********************************************************************

* Conflict income - labor income change
gen aux_lai = - var_lab
egen conf_wo_lab = rowtotal(pc_inc_post aux_lai), m
gen conf_lab = conf_wo_lab / ratio_post
drop aux_lai

* Conflict income - non-labor income change
gen aux_nlai = - var_nlab
egen conf_wo_nlab = rowtotal(pc_inc_post aux_nlai), m
gen conf_nlab = conf_wo_nlab / ratio_post
drop aux_nlai

* Conflict income - price effects
/*gen aux_NFP = - NFP_eff
egen conf_wo_priceNFP = rowtotal(pc_inc_post aux_NFP), m
gen conf_priceNFP = conf_wo_priceNFP / ratio_post*/
gen aux_NFP = - NFP_eff
egen conf_wo_priceNFP = rowtotal(welfare_post aux_NFP), m
gen conf_priceNFP = conf_wo_priceNFP


**********************************************************************
* New Poverty rates
**********************************************************************

* Poverty lines
gen lp_83usd_s = 8.3 * 365 / 12
gen lp_42usd_s = 4.2 * 365 / 12
gen lp_30usd_s = 3.0 * 365 / 12

* Poverty
foreach welf of varlist base_lab base_nlab base_priceNFP conf_lab conf_nlab conf_priceNFP welfare_pre welfare_post welfare_sim {

	gen p_`welf'_1 = `welf' <= lp_30usd_s if `welf' != .
	gen p_`welf'_2 = `welf' <= lp_42usd_s if `welf' != .
	gen p_`welf'_3 = `welf' <= lp_83usd_s if `welf' != .
	
}

* Gini
levelsof country, local(countries)
foreach welf of varlist base_lab base_nlab base_priceNFP conf_lab conf_nlab conf_priceNFP welfare_pre welfare_post welfare_sim {
	
	gen g_`welf' = .
	
	foreach country of local countries {
		
		ineqdec0 `welf' [iw=fexp] if `welf' != . & country == "`country'"
		replace g_`welf' = r(gini) if country == "`country'"
		
	}
}


**********************************************************************
* Aggregate estimates
**********************************************************************
gen pop = 1
collapse p_* g_* (sum) pop [iw=fexp], by(country)

foreach var of varlist p_base_lab_1-g_welfare_sim {
	replace `var' = `var' * 100
}

* Poverty Effect
for any 1 2 3: gen add_inf_X = ((p_base_priceNFP_X - p_welfare_pre_X) + (p_welfare_post_X - p_conf_priceNFP_X)) / 2
for any 1 2 3: gen labor_X = ((p_base_lab_X - p_welfare_pre_X) + (p_welfare_post_X - p_conf_lab_X)) / 2
for any 1 2 3: gen nlabor_X = ((p_base_nlab_X - p_welfare_pre_X) + (p_welfare_post_X - p_conf_nlab_X)) / 2

for any 1 2 3: gen tot_diff_X = (p_welfare_post_X - p_welfare_pre_X) 
for any 1 2 3: egen explained_X = rowtotal(add_inf_X labor_X nlabor_X) 
for any 1 2 3: gen other_X = (tot_diff_X - explained_X) 


* Gini Effects
gen add_inf_g = ((g_base_priceNFP - g_welfare_pre) + (g_welfare_post - g_conf_priceNFP)) / 2
gen labor_g = ((g_base_lab - g_welfare_pre) + (g_welfare_post - g_conf_lab)) / 2
gen nlabor_g = ((g_base_nlab - g_welfare_pre) + (g_welfare_post - g_conf_nlab)) / 2

gen tot_diff_g = (g_welfare_post - g_welfare_pre) 
egen explained_g = rowtotal(add_inf_g labor_g nlabor_g) 
gen other_g = (tot_diff_g - explained_g) 


* Organize the data
ren g_welfare_* welfare_*_g
ren p_welfare_* welfare_*

keep country welfare_pre* welfare_post* welfare_sim* add_inf* labor* nlabor* tot_diff* explained* other* pop

reshape long welfare_pre welfare_post welfare_sim add_inf labor nlabor tot_diff explained other , i(country) j(pline) string

for any add_inf labor nlabor other: gen perc_X = (X / tot_diff) * 100

order pop, after(perc_other)

qui export excel using "${out}", sheet("decompositions") firstrow(variables) sheetreplace