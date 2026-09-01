
/*===================================================================================================
Project:			Iran's Conflict Distributional Impact - Pre-conflict Microsimulated Data
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		3/13/2026

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  3/24/2026
===================================================================================================*/


/*=================================================================================================*/
**# 1. Conflict Data
/*=================================================================================================*/

use "${path}\Oil prices\input\compiled_SM2026_MPOweights", clear

	* labor income
	qui egen inc_all_s = rowtotal(lai_m_s lai_s_s), m
	qui bysort country hhid: egen inc_h = sum(inc_all_s) // HH Income from FPs
	qui gen pc_flai_s = inc_h / h_size if h_head != .
	
	* non-labor income
	local nonlabor "transfers ns_remit dom_remit int_remit pensions capital otherinla renta_imp"
	foreach nli of local nonlabor  {
		qui bysort hhid: egen aux_`nli' = sum(h_`nli'_s) if h_head != ., m
		qui replace h_`nli'_s = aux_`nli' 
		drop  aux_`nli' 
		qui gen pc_`nli'_s = h_`nli'_s / h_size if h_head != .
	}
	
	qui egen h_nlai_s2 = rowtotal(h_transfers_s h_ns_remit_s h_dom_remit_s h_int_remit_s h_pensions_s h_capital_s h_otherinla_s h_renta_imp_s) if h_head != . , m
	
	qui gen pc_fnlai_s = h_nlai_s2 / h_size if h_head != .
	
	ren pondera_26 fexp_s
	ren ypc_26 pc_inc_s
	ren new_ratio ratio_s
	
	* check
	egen check = rowtotal(pc_flai_s pc_fnlai_s), m
	egen check_nli_s = rowtotal(pc_transfers_s pc_ns_remit_s pc_dom_remit_s pc_int_remit_s pc_pensions_s pc_capital_s pc_otherinla_s pc_renta_imp_s), m
	
	compare check_nli_s pc_fnlai_s
	ta country if check_nli_s-pc_fnlai_s>1 & check_nli_s-pc_fnlai_s!=.
	
	compare check pc_inc_s
	ta country if abs(check-pc_inc_s)>1 & check-pc_inc_s!=.
	 
	gen diff_pc_inc_s = pc_inc_s - check if abs(check-pc_inc_s)>0 & !inlist(pc_inc_s,.)
	sum diff_pc_inc_s, d
	
	egen pc_flai2_s = rowtotal(pc_flai_s diff_pc_inc_s)
	
	egen check2 = rowtotal(pc_flai2_s pc_fnlai_s), m
	compare check2 pc_inc_s

	* setting up the file
	keep country hhid pid fexp_s pc_inc_s pc_flai* pc_fnlai_s pc_transfers_s pc_ns_remit_s pc_dom_remit_s pc_int_remit_s pc_pensions_s pc_capital_s pc_otherinla_s pc_renta_imp_s welfare_s ratio_s depen occupation_s inc_all_s diff_pc_inc_s
	
	ren *_s *_post


	la var fexp_post 			"Simulated weight"
	la var pc_inc_post			"Simulated conflict per-capita total family income"
	la var pc_flai_post			"Simulated conflict per-capita family labor income"
	la var pc_fnlai_post		"Simulated conflict per-capita family non-labor income"
	la var pc_transfers_post	"Simulated conflict per-capita public transfers income"
	la var pc_ns_remit_post		"Simulated conflict per-capita undefined private transfers income"
	la var pc_dom_remit_post	"Simulated conflict per-capita domestic transfers income"
	la var pc_int_remit_post	"Simulated conflict per-capita international transfers income"
	la var pc_pensions_post		"Simulated conflict per-capita pensions income"
	la var pc_capital_post		"Simulated conflict per-capita capital income"
	la var pc_otherinla_post	"Simulated conflict per-capita other non-labor income"
	la var pc_renta_imp_post	"Simulated conflict per-capita family imputed rent"

	duplicates report country hhid pid
	compress
	save "${path}\Oil prices\input\income_components_conflict", replace


/*=================================================================================================*/
**# 2. Baseline Data
/*=================================================================================================*/

use "${path}\Oil prices\input\compiled_baseline_MPOweights", clear

	* labor income
	qui egen inc_all_s = rowtotal(lai_m_s lai_s_s), m
	qui bysort country hhid: egen inc_h = sum(inc_all_s) // HH Income from FPs
	qui gen pc_flai_s = inc_h / h_size if h_head != .
	
	* non-labor income
	local nonlabor "transfers ns_remit dom_remit int_remit pensions capital otherinla renta_imp"
	foreach nli of local nonlabor  {
		qui bysort hhid: egen aux_`nli' = sum(h_`nli'_s) if h_head != ., m
		qui replace h_`nli'_s = aux_`nli' 
		drop  aux_`nli' 
		qui gen pc_`nli'_s = h_`nli'_s / h_size if h_head != .
	}
	
	qui egen h_nlai_s2 = rowtotal(h_transfers_s h_ns_remit_s h_dom_remit_s h_int_remit_s h_pensions_s h_capital_s h_otherinla_s h_renta_imp_s) if h_head != . , m
	
	qui gen pc_fnlai_s = h_nlai_s2 / h_size if h_head != .
	
	ren pondera_26 fexp_s
	ren ypc_26 pc_inc_s
	ren new_ratio ratio_s
	
	* check
	egen check = rowtotal(pc_flai_s pc_fnlai_s), m
	egen check_nli_s = rowtotal(pc_transfers_s pc_ns_remit_s pc_dom_remit_s pc_int_remit_s pc_pensions_s pc_capital_s pc_otherinla_s pc_renta_imp_s), m
	
	compare check_nli_s pc_fnlai_s
	ta country if check_nli_s-pc_fnlai_s>1 & check_nli_s-pc_fnlai_s!=.
	
	compare check pc_inc_s
	ta country if abs(check-pc_inc_s)>1 & check-pc_inc_s!=.
	 
	gen diff_pc_inc_s = pc_inc_s - check if abs(check-pc_inc_s)>0 & !inlist(pc_inc_s,.)
	sum diff_pc_inc_s, d
	
	egen pc_flai2_s = rowtotal(pc_flai_s diff_pc_inc_s)
	
	egen check2 = rowtotal(pc_flai2_s pc_fnlai_s), m
	compare check2 pc_inc_s
	
	* setting up the file
	keep country hhid pid fexp_s pc_inc_s pc_flai* pc_fnlai_s pc_transfers_s pc_ns_remit_s pc_dom_remit_s pc_int_remit_s pc_pensions_s pc_capital_s pc_otherinla_s pc_renta_imp_s welfare_s ratio_s depen occupation_s inc_all_s diff_pc_inc_s
	
	ren *_s *_pre


	la var fexp_pre 		"Simulated weight"
	la var pc_inc_pre		"Simulated pre-conflict per-capita total family income"
	la var pc_flai_pre		"Simulated pre-conflict per-capita family labor income"
	la var pc_fnlai_pre		"Simulated pre-conflict per-capita family non-labor income"
	la var pc_transfers_pre	"Simulated pre-conflict per-capita public transfers income"
	la var pc_ns_remit_pre	"Simulated pre-conflict per-capita undefined private transfers income"
	la var pc_dom_remit_pre	"Simulated pre-conflict per-capita domestic transfers income"
	la var pc_int_remit_pre	"Simulated pre-conflict per-capita international transfers income"
	la var pc_pensions_pre	"Simulated pre-conflict per-capita pensions income"
	la var pc_capital_pre	"Simulated pre-conflict per-capita capital income"
	la var pc_otherinla_pre	"Simulated pre-conflict per-capita other non-labor income"
	la var pc_renta_imp_pre	"Simulated pre-conflict per-capita family imputed rent"

	duplicates report country hhid pid
	compress
	save "${path}\Oil prices\input\income_components_preconflict", replace

	

/*=================================================================================================*/
**# 3. Initial Impact
/*=================================================================================================*/

qui use  "${out_sim}", clear

	* labor income
	cap drop inc_h
	qui egen inc_all_s = rowtotal(lai_m_s lai_s_s), m
	qui bysort country hhid: egen inc_h = sum(inc_all_s) // HH Income from FPs
	qui gen aux_pc_flai_s = inc_h / h_size if h_head != .
	qui egen pc_flai_s = rowtotal(aux_pc_flai_s change_inc_sim)
	
	* non-labor income
	local nonlabor "transfers ns_remit dom_remit int_remit pensions capital otherinla renta_imp"
	foreach nli of local nonlabor  {
		qui bysort hhid: egen aux_`nli' = sum(h_`nli'_s) if h_head != ., m
		qui replace h_`nli'_s = aux_`nli' 
		drop  aux_`nli' 
		qui gen pc_`nli'_s = h_`nli'_s / h_size if h_head != .
	}
	
	qui egen h_nlai_s2 = rowtotal(h_transfers_s h_ns_remit_s h_dom_remit_s h_int_remit_s h_pensions_s h_capital_s h_otherinla_s h_renta_imp_s) if h_head != . , m
	
	qui gen pc_fnlai_s = h_nlai_s2 / h_size if h_head != .
	
	ren pondera_26 fexp_s
	ren ypc_26_sim pc_inc_s
	ren new_ratio ratio_s
	
	* check
	egen check = rowtotal(pc_flai_s pc_fnlai_s), m
	egen check_nli_s = rowtotal(pc_transfers_s pc_ns_remit_s pc_dom_remit_s pc_int_remit_s pc_pensions_s pc_capital_s pc_otherinla_s pc_renta_imp_s), m
	
	compare check_nli_s pc_fnlai_s
	ta country if check_nli_s-pc_fnlai_s>1 & check_nli_s-pc_fnlai_s!=.
	
	compare check pc_inc_sim
	ta country if abs(check-pc_inc_sim)>1 & check-pc_inc_sim!=.
	 
	gen diff_pc_inc_s = pc_inc_sim - check if abs(check-pc_inc_sim)>0 & !inlist(pc_inc_sim,.) & change_inc_sim == .
	sum diff_pc_inc_s, d
	
	egen pc_flai2_s = rowtotal(pc_flai_s diff_pc_inc_s)
	
	egen check2 = rowtotal(pc_flai2_s pc_fnlai_s), m
	compare check2 pc_inc_sim
	
	* setting up the file
	keep country hhid pid fexp_s pc_inc_sim pc_flai* pc_fnlai_s pc_transfers_s pc_ns_remit_s pc_dom_remit_s pc_int_remit_s pc_pensions_s pc_capital_s pc_otherinla_s pc_renta_imp_s welfare_s ratio_s depen occupation_s diff_pc_inc_s cons_lost_sim inc_all_s change_inc_sim
	
	ren *_s *_sim


	la var fexp_sim			"Simulated weight"
	la var pc_inc_sim		"Simulated init-conflict per-capita total family income"
	la var pc_flai_sim		"Simulated init-conflict per-capita family labor income"
	la var pc_fnlai_sim		"Simulated init-conflict per-capita family non-labor income"
	la var pc_transfers_sim	"Simulated init-conflict per-capita public transfers income"
	la var pc_ns_remit_sim	"Simulated init-conflict per-capita undefined private transfers income"
	la var pc_dom_remit_sim	"Simulated init-conflict per-capita domestic transfers income"
	la var pc_int_remit_sim	"Simulated init-conflict per-capita international transfers income"
	la var pc_pensions_sim	"Simulated init-conflict per-capita pensions income"
	la var pc_capital_sim	"Simulated init-conflict per-capita capital income"
	la var pc_otherinla_sim	"Simulated init-conflict per-capita other non-labor income"
	la var pc_renta_imp_sim	"Simulated init-conflict per-capita family imputed rent"

	duplicates report country hhid pid
	compress
	save "${path}\Oil prices\input\income_components_initconflict", replace


/*=================================================================================================*/
**# 3. Merge Data
/*=================================================================================================*/

use "${path}\Oil prices\input\income_components_preconflict", clear
merge 1:1 country hhid pid using "${path}\Oil prices\input\income_components_initconflict", nogenerate
merge 1:1 country hhid pid using "${path}\Oil prices\input\income_components_conflict", nogenerate

clonevar fexp = fexp_post 
order country hhid pid fexp

compress
save "${path}\Oil prices\input\income_components", replace


* Checks poverty
gen lp_83usd_s = 8.3 * 365 / 12
gen lp_42usd_s = 4.2 * 365 / 12
gen lp_30usd_s = 3.0 * 365 / 12

foreach linea in 83 42 30 {
	gen poverty_`linea'_pre=(welfare_pre<=lp_`linea'usd_s) if welfare_pre != .
	gen poverty_`linea'_sim=(welfare_sim<=lp_`linea'usd_s) if welfare_sim != .
	gen poverty_`linea'_post=(welfare_post<=lp_`linea'usd_s) if welfare_post != .
}

collapse poverty* [iw=fexp] if welfare_post!=., by(country) 
