
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

* Drop cases without welfare
count if welfare_pre == .
count if welfare_post == .
drop if welfare_pre == . & welfare_post == .


**********************************************************************
* Components
**********************************************************************

* labor income
for any pc_flai2_pre pc_flai2_post: replace X = 0 if X == .

* non-labor income
for any pc_fnlai_pre pc_fnlai_post: replace X = 0 if X == .

* income to consumption ratio
count if ratio_pre == . // none
count if ratio_post == . // none

count if ratio_pre == 0 // 1,217
count if ratio_post == 0 // 1,217
count if ratio_pre == 0 & ratio_post == 0 //1,217 

* Base consumption
for any pre post: gen base_cons_X = 0
for any pre post: replace base_cons_X = welfare_X if ratio_X == 0

* Check incomes add up
for any pre post: egen aux_inc_X = rowtotal(pc_flai2_X pc_fnlai_X)
for any pre post: compare aux_inc_X pc_inc_X

* Check calculated welfare is close to projected welfare
for any pre post: gen aux_welf_X = aux_inc_X / ratio_X if ratio_X != 0
for any pre post: replace aux_welf_X = base_cons_X if ratio_X == 0

for any pre post: compare aux_welf_X welfare_X

br aux_welf_* welfare_* aux_inc_* pc_inc_* ratio_* base_cons* if abs(aux_welf_pre - welfare_pre)>10


**********************************************************************
* Keep only necessary information
**********************************************************************

keep country hhid pid welfare_pre welfare_post pc_flai2_* pc_fnlai_* ratio_* base_cons_* fexp lp_*

reshape long welfare pc_food pc_flai2 pc_fnlai ratio base_cons, i(country hhid pid) j(scenario) string

replace scenario = "0" if scenario == "_pre"
replace scenario = "1" if scenario == "_post"
destring scenario, replace

keep if country == "BGD"

for any 0 1: apoverty welfare [w=fexp] if scenario == X, varpl(lp_30usd_ppp)
for any 0 1: apoverty welfare [w=fexp] if scenario == X, varpl(lp_42usd_ppp)
for any 0 1: apoverty welfare [w=fexp] if scenario == X, varpl(lp_83usd_ppp)
 
egen id = group(hhid pid)

for any pc_flai pc_fnlai: replace X = 0 if ratio == 0
replace ratio = 1  if pc_flai == 0 & pc_fnlai == 0 // To avoid undefined division

adecomp welfare pc_flai pc_fnlai ratio base_cons [w=fexp], by(scenario) ///
		equation(((c1+c2)/c3)+c4) ind(fgt0) varpl(lp_30usd_ppp) id(id)

		
for any welfare pc_food pc_flai2 pc_fnlai ratio base_cons: replace X = . if X == 0
sum *
