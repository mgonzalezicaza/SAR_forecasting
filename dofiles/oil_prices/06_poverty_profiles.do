
/*========================================================================
Project:			Results - Poverty Simulations Food Prices Exercise
Institution:		World Bank - ELCPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		06/10/2022

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date: 	09/14/2023
========================================================================*/

drop _all
etime, start


***************************************************
* Globals - Please check these globals carefully 
***************************************************

* Paths
global rootdatalib "S:\Datalib"
gl inpath "Z:\public\Stats_Team\PLBs\23. Poverty projections simulations\LAC_Inputs_Regional_Microsims\FY2024\04_Microsims_SM2022_vSM2024"
*gl inpath2 "Z:\public\Stats_Team\PLBs\23. Poverty projections simulations\LAC_Inputs_Regional_Microsims\FY2023\03_Microsims_AM2021" // BOL
gl outpath "Z:\public\Stats_Team\PLBs\23. Poverty projections simulations\LAC_Inputs_Regional_Microsims\FY2024\04_Microsims_SM2022_vSM2024\Oil_prices"
gl lac_food "Z:\wb520054\Micro-simulations\food_fuel_prices\Outputs\lac_compiled_SM2024_sim_MAR_20_2024.dta"

* Poverty and vulnerability thresholds - Change if necessary multiplying the original value by 100
gl min_povline 30
gl mid_povline 42
gl max_povline 83

* Countries 
gl countries "BGD MDV SAR"

* IMPORTANT: Some countries have data restrictions. Please check the name file and years before running.

foreach country of global countries {
  
	gl country_aux "`country'"
	
	
	************************
	* 0 - Set Output file
	************************
	
	gl outfile "Results_`country'_food.xlsx"
	
	
	**************************************************************
	* 1 - Prepare Food Prices data (only family income changes)
	**************************************************************
    
	qui do "Z:\wb520054\Micro-simulations\food_fuel_prices\Dofiles\preparing_prices_data_v4.do"
	
	
 
 
	****************************
	* 2 - Load simulated data
	****************************

	use "${inpath}\Oil_prices\Data/`country'_2022.dta", clear
	
	* Keep only necessary variables
	keep country id pid hombre urbano edad jefe nivel depen pc_inc_s poor*1 vuln middle_class upper_class occupation_s tot_lai* h_transfers_s h_remesas_s h_pensions_s h_otherinla_s h_capital_s h_renta_imp_s labor_rel *_post *pondera*
	
	
	******************
	* 3 - Variables
	******************
	
	cap qui gen total = 1 
	qui replace total = . if pc_inc_s == .
	qui gen sample = inrange(edad,15,64)
	qui bysort country id: egen h_size = count(pid) 
	ren pondera_22 fexp_s
	
	
	* Income gap
	***************
	*** This is necessary for the sheet Poverty and Inequality
	
	qui for any ${max_povline} ${mid_povline} ${min_povline} : cap drop lp_Xusd_s
	qui for any ${max_povline} ${mid_povline} ${min_povline} : qui gen  lp_Xusd_s = X*365/1200
	
	cap drop lp_${vuln_line}usd_s
	qui gen lp_${vuln_line}usd_s = ${vuln_line}*365/1200
	
	qui for any ${max_povline} ${mid_povline} ${min_povline} : gen gap_X_post = (lp_Xusd_s - pc_inc_post) / lp_Xusd_s * 100 if poorX1_post == 1 // Post inflation
	qui for any ${max_povline} ${mid_povline} ${min_povline} : replace gap_X_post = 0 if poorX1_post == 0 // Post inflation
	
	qui for any ${max_povline} ${mid_povline} ${min_povline} : gen gap_X_pre = (lp_Xusd_s - pc_inc_s) / lp_Xusd_s * 100 if poorX1 == 1 // Pre inflation
	qui for any ${max_povline} ${mid_povline} ${min_povline} : replace gap_X_pre = 0 if poorX1 == 0 // Pre inflation
	
	qui gen gap_vuln_post = (lp_${vuln_line}usd_s - pc_inc_post) / lp_${vuln_line}usd_s * 100 if vuln_post == 1 // Post inflation
	qui replace gap_vuln_post = 0 if vuln_post == 0 // Post inflation
	
	qui gen gap_vuln_pre = (lp_${vuln_line}usd_s - pc_inc_s) / lp_${vuln_line}usd_s * 100 if vuln == 1 // Pre inflation
	qui replace gap_vuln_pre = 0 if vuln == 0 // Pre inflation
	
	
	* Distribution categories 
	****************************
	*** This identifies changes along the whole distribution. We calculate poverty status using the upper poverty line and the old status defined previously.
	
	qui gen new_inpov = poor${max_povline}1_post == 1 & poor${max_povline}1 == 0
	qui gen always_inpov = poor${max_povline}1_post == 1 & poor${max_povline}1 == 1
	qui gen new_invul = vuln_post == 1 & vuln == 0
	qui gen always_invul = vuln_post == 1 & vuln == 1
	qui gen new_inmc = middle_class_post == 1 & middle_class == 0
	qui gen always_inmc = middle_class_post == 1 & middle_class == 1
	qui gen new_inuc = upper_class_post == 1 & upper_class == 0
	qui gen always_inuc = upper_class_post == 1 & upper_class == 1
	
	
	* Market structure
	*********************
	*** This part creates the Labor Market variables necessary for Labor market summary stats for total population and for the next loop. You can add more variables here.
	
	qui gen population = 1
	qui gen pea = occupation_s != 0 if sample == 1 & occupation_s !=.
	qui gen participation = occupation_s != 0 if sample == 1 & occupation_s !=.
	qui gen unemployed = occupation_s == 1 if sample == 1 & occupation_s !=.
	qui gen employed = !inlist(occupation_s,0,1) if sample == 1 & occupation_s !=.
	qui gen inactive = occupation_s == 0 if sample == 1 & occupation_s !=.
	qui gen sal = labor_rel == 1 if employed == 1 & !inlist(labor_rel,4,.)
	qui gen self = labor_rel == 2 if employed == 1 & !inlist(labor_rel,4,.)
	qui gen unpd = labor_rel == 3 if employed == 1 & !inlist(labor_rel,4,.)
	qui gen emp_agr = inlist(occupation_s,2,3) if sample == 1 & employed == 1
	qui gen emp_ind = inlist(occupation_s,4,5) if sample == 1 & employed == 1
	qui gen emp_ser = inlist(occupation_s,6,7) if sample == 1 & employed == 1
	qui gen informal = inlist(occupation_s,3,5,7) if sample == 1 & employed == 1
	qui gen agr_infor = occupation_s == 3 if sample == 1 & emp_agr == 1
	qui gen ind_infor = occupation_s == 5 if sample == 1 & emp_ind == 1
	qui gen ser_infor = occupation_s == 7 if sample == 1 & emp_ser == 1

	
	* Population Disaggregations
	*******************************
	*** For now, the disaggregations correspond to Gender, Area, Age Range, and Education level. You can create more disaggregations and add them in the loop.
	
	qui gen female = hombre == 0
	qui gen male = hombre == 1
	
	qui gen urbal = urbano == 1
	qui gen rural = urbano == 0
	
	qui gen age014 = inrange(edad,0,14)
	qui gen age1524 = inrange(edad,15,24)
	qui gen age2534 = inrange(edad,25,34)
	qui gen age3544 = inrange(edad,35,44)
	qui gen age4554 = inrange(edad,45,54)
	qui gen age5564 = inrange(edad,55,64)
	qui gen age65p = edad > 64 if edad != .
	
	
	qui gen unskilled = nivel < 4 if nivel != .
	qui gen skilled = nivel >= 4 if nivel != .
	
	foreach var of varlist female male urban rural age1524 age2534 age3544 age4554 age5564 skilled unskilled {
		qui gen pop_`var' = total if `var' == 1
		qui gen participation_`var' = participation if `var' == 1
		qui gen unemployed_`var' = unemployed if `var' == 1
		qui gen employed_`var' = employed if `var' == 1
		qui gen inactive_`var' = inactive if `var' == 1
		qui gen sal_`var' = sal if `var' == 1
		qui gen self_`var' = self if `var' == 1
		qui gen unpd_`var' = unpd if `var' == 1
		qui gen emp_agr_`var' = emp_agr if `var' == 1
		qui gen emp_ind_`var' = emp_ind if `var' == 1
		qui gen emp_ser_`var' = emp_ser if `var' == 1
		qui gen informal_`var' = informal if `var' == 1
		qui gen agr_infor_`var' = agr_infor if `var' == 1
		qui gen ind_infor_`var' = ind_infor if `var' == 1
		qui gen ser_infor_`var' = ser_infor if `var' == 1
	}
			
	* Per capita income
	*********************
	*** This section calculate all source of income at the per capita level. Sources of income included: Total family income, Labor income, Non-labor income, Public transfers, Private transfers, Pensions, Capital, Other non-labor income.
	
	* Labor income
	qui bysort country id: egen h_lai_s = sum(tot_lai_s) if jefe != . , m 
	qui gen pc_lai_s = h_lai_s / h_size
	replace pc_lai_s = . if pc_inc_s == .
	replace pc_lai_s = 0 if pc_inc_s != . & pc_lai_s == .
	qui gen lai_share = pc_lai_s / pc_inc_s
	qui bysort country id: egen h_lai_share = mean(lai_share)
	qui replace lai_share = h_lai_share if lai_share == . & pc_lai_s != .
	qui gen pc_lai_post = pc_inc_post * lai_share
	
	* Non-labor income
	local nonlabor "transfers remesas pensions capital otherinla renta_imp"
			foreach nli of local nonlabor  {
				qui bysort country id: egen aux_`nli' = sum(h_`nli'_s) if jefe != ., m
				qui replace h_`nli'_s = aux_`nli' 
				drop  aux_`nli' 
			}
			
	for any transfers remesas pensions capital otherinla renta_imp: qui gen pc_X_s = h_X_s / h_size if jefe != .
	
	qui egen h_nlai_s = rowtotal(h_transfers_s h_remesas_s h_pensions_s h_capital_s h_otherinla_s h_renta_imp_s) if jefe != . , m
	qui gen pc_nlai_s = h_nlai_s / h_size
	replace pc_nlai_s = . if pc_inc_s == .
	replace pc_nlai_s = 0 if pc_inc_s != . & pc_nlai_s == .
	
	egen test_inc = rowtotal(pc_lai_s pc_nlai_s), m
	compare pc_inc_s test_inc
	drop test_inc
	
	for any transfers remesas pensions capital otherinla renta_imp: qui replace pc_X_s = 0 if pc_X_s == . & pc_nlai_s != .
				
	qui gen pc_pubtr_s = pc_transfers_s
	qui gen pc_privttr_s = pc_remesas_s
	
	qui gen nlai_share = pc_nlai_s / pc_inc_s
	qui gen pc_nlai_post = pc_inc_post * nlai_share
	
	qui gen pubtr_share = pc_pubtr_s / pc_inc_s
	qui gen pc_pubtr_post = pc_inc_post * pubtr_share
	
	qui gen privttr_share = pc_privttr_s / pc_inc_s
	qui gen pc_privttr_post = pc_inc_post * privttr_share
	
	qui gen pensions_share = pc_pensions_s / pc_inc_s
	qui gen pc_pensions_post = pc_inc_post * pensions_share
	 
	qui gen othernli_share = pc_otherinla_s / pc_inc_s
	qui gen pc_othernli_post = pc_inc_post * othernli_share

	qui gen capital_share = pc_capital_s / pc_inc_s
	qui gen pc_capital_post = pc_inc_post * capital_share
	
	qui gen renta_imp_share = pc_renta_imp_s / pc_inc_s
	qui gen pc_renta_imp_post = pc_inc_post * renta_imp_share
	
	
	* Inequality 
	***************
	*** This section calculates inequality measures.
	
	qui ainequal pc_inc_s [w=fexp_s]
	qui gen gini = r(gini_1)
	qui gen theil = r(theil_1)
	
	qui ainequal pc_inc_post [w=fexp_s]
	qui gen gini_post = r(gini_1)
	qui gen theil_post = r(theil_1)
		
	qui destring gini* theil*, replace
		
		
	* Dynamic Profiles
	*********************
	*** This section calculate profiles for populations according to changes in poverty and vulnerability status. You can add more variables or more detailed status here. Poverty cut-off: "max_povline"
	
	local categories new_inpov always_inpov new_invul always_invul new_inmc always_inmc new_inuc always_inuc total 
	foreach kind of local categories {
	    qui gen pop_`kind' = 1 if `kind' == 1
	    qui gen urban_`kind' = urbano if `kind' == 1
		qui gen h_size_`kind' = h_size if `kind' == 1
		qui gen dependency_`kind' = depen if `kind' == 1
		qui gen hhead_age_`kind' = edad if `kind' == 1 & jefe == 1
		qui gen hhead_male_`kind' = hombre if `kind' == 1 & jefe == 1
		qui gen hhead_emp_`kind' = employed if `kind' == 1 & jefe == 1
		qui gen hhead_emp_agr_`kind' = emp_agr if `kind' == 1 & jefe == 1
		qui gen hhead_emp_ind_`kind' = emp_ind if `kind' == 1 & jefe == 1
		qui gen hhead_emp_ser_`kind' = emp_ser if `kind' == 1 & jefe == 1
		qui gen hhead_inac_`kind' = inactive if `kind' == 1 & jefe == 1
		qui gen hhead_sal_`kind' = sal if `kind' == 1 & jefe == 1
		qui gen hhead_self_`kind' = self if `kind' == 1 & jefe == 1
		qui gen hhead_unpd_`kind' = unpd if `kind' == 1 & jefe == 1
		qui gen hhead_unemp_`kind' = unemployed if `kind' == 1 & jefe == 1
		qui gen hhead_inf_`kind' = informal if `kind' == 1 & jefe == 1
		qui gen hhead_skilled_`kind' = skilled if `kind' == 1 & jefe == 1
		qui gen hhead_unskilled_`kind' = unskilled if `kind' == 1 & jefe == 1
		qui gen age014_`kind' = age014 if `kind' == 1
		qui gen age1524_`kind' = age1524 if `kind' == 1
		qui gen age2534_`kind' = age2534 if `kind' == 1
		qui gen age3544_`kind' = age3544 if `kind' == 1
		qui gen age4554_`kind' = age4554 if `kind' == 1
		qui gen age5564_`kind' = age5564 if `kind' == 1
		qui gen age65p_`kind' = age65p if `kind' == 1
		qui gen male_`kind' = hombre if `kind' == 1
		qui gen female_`kind' = !hombre if `kind' == 1
		qui gen inac_`kind' = inactive if `kind' == 1
		qui gen emp_`kind' = employed if `kind' == 1
		qui gen emp_agr_`kind' = emp_agr if `kind' == 1
		qui gen emp_ind_`kind' = emp_ind if `kind' == 1
		qui gen emp_ser_`kind' = emp_ser if `kind' == 1
		qui gen sal_`kind' = sal if `kind' == 1
		qui gen self_`kind' = self if `kind' == 1
		qui gen unpd_`kind' = unpd if `kind' == 1
		qui gen unemp_`kind' = unemployed if `kind' == 1
		qui gen inf_`kind' = informal if `kind' == 1
		qui gen skilled_`kind' = skilled if `kind' == 1
		qui gen unskilled_`kind' = unskilled if `kind' == 1
	}
	
	
	* Income Dynamics
	********************
	*** This section calculate income for populations according to changes in poverty and vulnerability status. Poverty cut-off: "max_povline"
	
	local categories new_inpov always_inpov new_invul always_invul new_inmc always_inmc new_inuc always_inuc total 
	foreach kind of local categories {
		
		* SM 2022
		qui gen ti_`kind'_s = pc_inc_s if `kind' == 1
		qui gen li_`kind'_s = pc_lai_s if `kind' == 1
		qui gen nli_`kind'_s = pc_nlai_s if `kind' == 1
		qui gen pub_transf_`kind'_s = pc_pubtr_s if `kind' == 1
		qui gen priv_transf_`kind'_s = pc_privttr_s if `kind' == 1
		qui gen pensions_`kind'_s = pc_pensions_s if `kind' == 1
		qui gen capital_`kind'_s = pc_capital_s if `kind' == 1
		qui gen othernli_`kind'_s = pc_otherinla_s if `kind' == 1 
		qui gen renta_imp_`kind'_s = pc_renta_imp_s if `kind' == 1 
		
		* Post-inflation
		qui gen ti_`kind'_post = pc_inc_post if `kind' == 1
		qui gen li_`kind'_post = pc_lai_post if `kind' == 1
		qui gen nli_`kind'_post = pc_nlai_post if `kind' == 1
		qui gen pub_transf_`kind'_post = pc_pubtr_post if `kind' == 1
		qui gen priv_transf_`kind'_post = pc_privttr_post if `kind' == 1
		qui gen pensions_`kind'_post = pc_pensions_post if `kind' == 1
		qui gen capital_`kind'_post = pc_capital_post if `kind' == 1
		qui gen othernli_`kind'_post = pc_othernli_post if `kind' == 1 
		qui gen renta_imp_`kind'_post = pc_renta_imp_post if `kind' == 1 
	}
	
	
	
	* Static Profiles - Pre-inflation
	************************************
	*** This section calculate profiles for populations according to simulated and vulnerability status. You can add more variables or more detailed status here.
	
	cap drop pop_total urban_total h_size_total dependency_total ti_total li_total nli_total income_total pub_transf_total priv_transf_total pensions_total capital_total othernli_total age*_total *male_total emp_total unemp_total inf_total skilled_total unskilled_total inac_total sal_total self_total unpd_total emp_agr_total emp_ind_total emp_ser_total
	
		local categories poor${max_povline}1 poor${mid_povline}1 poor${min_povline}1 vuln middle_class upper_class poor${max_povline}1_post poor${mid_povline}1_post poor${min_povline}1_post vuln_post middle_class_post upper_class_post
	foreach kind of local categories {
	    qui gen pop_`kind' = 1 if `kind' == 1
	    qui gen urban_`kind' = urbano if `kind' == 1
		qui gen h_size_`kind' = h_size if `kind' == 1
		qui gen dependency_`kind' = depen if `kind' == 1
		qui gen age014_`kind' = age014 if `kind' == 1
		qui gen age1524_`kind' = age1524 if `kind' == 1
		qui gen age2534_`kind' = age2534 if `kind' == 1
		qui gen age3544_`kind' = age3544 if `kind' == 1
		qui gen age4554_`kind' = age4554 if `kind' == 1
		qui gen age5564_`kind' = age5564 if `kind' == 1
		qui gen age65p_`kind' = age65p if `kind' == 1
		qui gen male_`kind' = hombre if `kind' == 1
		qui gen female_`kind' = !hombre if `kind' == 1
		qui gen inac_`kind' = inactive if `kind' == 1
		qui gen emp_`kind' = employed if `kind' == 1
		qui gen emp_agr_`kind' = emp_agr if `kind' == 1
		qui gen emp_ind_`kind' = emp_ind if `kind' == 1
		qui gen emp_ser_`kind' = emp_ser if `kind' == 1
		qui gen sal_`kind' = sal if `kind' == 1
		qui gen self_`kind' = self if `kind' == 1
		qui gen unpd_`kind' = unpd if `kind' == 1
		qui gen unemp_`kind' = unemployed if `kind' == 1
		qui gen inf_`kind' = informal if `kind' == 1
		qui gen skilled_`kind' = skilled if `kind' == 1
		qui gen unskilled_`kind' = unskilled if `kind' == 1
	}
	
	
	* SM 2022
	local categories poor${max_povline}1 poor${mid_povline}1 poor${min_povline}1 vuln middle_class upper_class 
	foreach kind of local categories {
		qui gen ti_`kind'_s = pc_inc_s if `kind' == 1
		qui gen li_`kind'_s = pc_lai_s if `kind' == 1
		qui gen nli_`kind'_s = pc_nlai_s if `kind' == 1
		qui gen income_`kind'_s = pc_inc_s if `kind' == 1
		qui gen pub_transf_`kind'_s = pc_pubtr_s if `kind' == 1
		qui gen priv_transf_`kind'_s = pc_privttr_s if `kind' == 1
		qui gen pensions_`kind'_s = pc_pensions_s if `kind' == 1
		qui gen capital_`kind'_s = pc_capital_s if `kind' == 1
		qui gen othernli_`kind'_s = pc_otherinla_s if `kind' == 1 
		qui gen renta_imp_`kind'_s = pc_renta_imp_s if `kind' == 1 
	}
	
	* Post-inflation
	local categories poor${max_povline}1_post poor${mid_povline}1_post poor${min_povline}1_post vuln_post middle_class_post upper_class_post
	foreach kind of local categories {
		qui gen ti_`kind' = pc_inc_post if `kind' == 1
		qui gen li_`kind' = pc_lai_post if `kind' == 1
		qui gen nli_`kind' = pc_nlai_post if `kind' == 1
		qui gen income_`kind' = pc_inc_post if `kind' == 1
		qui gen pub_transf_`kind' = pc_pubtr_post if `kind' == 1
		qui gen priv_transf_`kind' = pc_privttr_post if `kind' == 1
		qui gen pensions_`kind' = pc_pensions_post if `kind' == 1
		qui gen capital_`kind' = pc_capital_post if `kind' == 1
		qui gen othernli_`kind' = pc_othernli_post if `kind' == 1 
		qui gen renta_imp_`kind' = pc_renta_imp_post if `kind' == 1 
	}
		
		
	* 2.1.3 - Descriptive data collapse
	**************************************
	*** Collapse data information for the sheet "descriptives".
	
	preserve
	qui collapse (sum) pop* pea (mean) pc_inc_* pc_lai_* pc_nlai_* pc_pubtr_* pc_privttr_* pc_pensions_* pc_capital_* pc_othernli_* pc_otherinla_* pc_renta_imp_* poor*1* vuln* middle_class* upper_class* gini* theil* urban_* h_size_* ti_* li_* nli_* hhead_* income_* gap_* participation* unemployed* employed* emp_* informal* agr_* ind_* ser_* pub_transf_* priv_transf_* pensions_* capital_* othernli_* renta_imp_* age*_* dependency_* male_* female_* skilled_* unskilled_* unemp_* inf_* inac* sal* self* unpd* [iw = fexp_s]
	qui xpose, clear varname
	ren (v1 _varname) (value indicator)
	qui order indicator
	sort indicator
	qui export excel using "$outpath/${outfile}", sheet(descriptives) firstrow(variables) sheetreplace
	restore
		
		
	* 2.1.4 - Transition matrices 
	********************************
	
	* Deciles
	qui xtile decile_s = pc_inc_s [w=fexp_s], nq(10)
	qui xtile decile_post = pc_inc_post [w=fexp_s], nq(10)
		
	qui gen stay = decile_s == decile_post
	qui gen up = decile_s < decile_post
	qui gen down = decile_s > decile_post
		
	preserve
	qui collapse stay up down [iw=fexp_s], by(decile_s)
	qui drop if decile_s == .
	qui for any stay up down: replace X = X * 100
	qui export excel using "$outpath/${outfile}", sheet(transition_matrix) firstrow(variables) sheetreplace
	restore
	
	* Categories
	qui gen prev_cat = ""
	
	qui replace prev_cat = "Poor" if poor${max_povline}1 == 1 & prev_cat == ""
	qui replace prev_cat = "Vulnerable" if vuln == 1 & prev_cat == ""
	qui replace prev_cat = "Middle Class" if middle_class == 1 & prev_cat == ""
	qui replace prev_cat = "Upper Class" if upper_class == 1 & prev_cat == ""
		
	preserve
	qui collapse (sum) poor${max_povline}1_post vuln_post middle_class_post upper_class_post [iw=fexp_s], by(prev_cat)
	qui drop if prev_cat == ""
	qui export excel using "$outpath/${outfile}", sheet(matrix_categories) firstrow(variables) sheetreplace
	restore
		
		
	* 2.1.5 - GICs 
	*****************
	
	qui gen ann_inc_s = pc_inc_s * 12
	qui gen ann_inc_post = pc_inc_post * 12
	
	qui xtile pctile_s = ann_inc_s [w=fexp_s], nq(100)
	qui xtile pctile_post = ann_inc_post [w=fexp_s], nq(100)
	
	preserve
	keep country id pid ann_inc_s ann_inc_post pctile_* fexp_s
	qui reshape long ann_inc pctile, i(country id pid) j(simulation) string
	qui collapse ann_inc [iw=fexp_s], by(simulation pctile)
	qui drop if pctile == .
	qui reshape wide ann_inc, i(pctile) j(simulation) string
	gen change = (ann_inc_post / ann_inc_s - 1) * 100
	qui export excel using "$outpath/${outfile}", sheet(GICs) firstrow(variables) sheetmodify
	restore
	
	di in red "`country' ended successfully"
}


**************************************************************************
* Display running time	
etime
**************************************************************************

**************************************************************************
* END
**************************************************************************
