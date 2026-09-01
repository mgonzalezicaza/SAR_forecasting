************************************************************************
* 2 - General variables for tables 
************************************************************************

* Total population
qui gen total = 1

* Conversion factor
qui sum cpi${ppp} 
replace cpi${ppp} = r(mean) if cpi${ppp} == .
qui sum icp${ppp} 
replace icp${ppp} = r(mean) if icp${ppp} == .

qui gen pline_nat_ppp = pline_nat / cpi${ppp} / icp${ppp} 

* Poverty headcount and gap
*** This is necessary for the sheet Poverty and Inequality
cap drop lp_*usd_s
qui for any ${pline3} ${pline2} ${pline1} : gen lp_Xusd_s = (X / 100) * (365 / 12)
qui for any ${pline3} ${pline2} ${pline1} : gen poorX1 = welfare_s <= lp_Xusd_s if welfare_s != .
qui for any ${pline3} ${pline2} ${pline1} : gen gap_X = (lp_Xusd_s - welfare_s) / lp_Xusd_s * 100 if poorX1 == 1
qui for any ${pline3} ${pline2} ${pline1} : replace gap_X = 0 if poorX1 == 0
apoverty welfare_s [aw = fexp_s] if welfare_s != ., varpl(pline_nat_ppp) h igr gen(poor_nat)

*** This is necessary for the profiles
qui for any ${pline3} ${pline2} ${pline1} : gen poorX2 = welfare_s <= lp_Xusd_s if welfare_s != .
replace poor${pline3}2 = 0 if poor${pline2}1 == 1
replace poor${pline2}2 = 0 if poor${pline1}1 == 1
qui gen nonpoor = poor${pline3}1 == 0 if welfare_s != .


* Prosperity Gap
qui gen welfare_aux = welfare_s
replace welfare_aux = . if welfare_aux < 0    
replace welfare_aux = (${prs_gp} * 365 / 12) / 100 if welfare_aux < ((${prs_gp} * 365 / 12) / 100)
gen pg = (${prs_gp} * 365 / 12) / welfare_aux
drop welfare_aux

* Market structure
*** This part creates the Labor Market variables necessary for Labor market summary stats. You can add more variables here.
qui replace occupation_s = . if pc_inc_s == . | sample != 1
qui gen inactive = active_s == 0 if sample == 1 & active_s !=.

qui gen sal = salaried_s 	== 1 if emplyd_s == 1 & !inlist(labor_rel,4,.)
qui gen self = self_emp 	== 1 if emplyd_s == 1 & !inlist(labor_rel,4,.)
qui gen unpd = unpaid 		== 1 if emplyd_s == 1 & !inlist(labor_rel,4,.)
	
qui gen emp_agr = inlist(occupation_s,2,3) if sample == 1 & inrange(occupation_s,2,7)
qui gen emp_ind = inlist(occupation_s,4,5) if sample == 1 & inrange(occupation_s,2,7)
qui gen emp_ser = inlist(occupation_s,6,7) if sample == 1 & inrange(occupation_s,2,7)

qui gen agr_unsk = occupation_s == 3 if sample == 1 & emp_agr == 1
qui gen ind_unsk = occupation_s == 5 if sample == 1 & emp_ind == 1
qui gen ser_unsk = occupation_s == 7 if sample == 1 & emp_ser == 1

qui gen inc 		= lai_m_s if emplyd_s 		== 1
qui gen inc_sk 		= lai_m_s if unskilled_s 	== 0
qui gen inc_unsk 	= lai_m_s if unskilled_s 	== 1

qui gen inc_agr = lai_m_s if emp_agr == 1
qui gen inc_ind = lai_m_s if emp_ind == 1
qui gen inc_ser = lai_m_s if emp_ser == 1

qui gen inc_agr_sk 		= lai_m_s if unskilled_s == 0 & emp_agr == 1
qui gen inc_agr_unsk 	= lai_m_s if unskilled_s == 1 & emp_agr == 1
qui gen inc_ind_sk 		= lai_m_s if unskilled_s == 0 & emp_ind == 1
qui gen inc_ind_unsk 	= lai_m_s if unskilled_s == 1 & emp_ind == 1
qui gen inc_ser_sk 		= lai_m_s if unskilled_s == 0 & emp_ser == 1
qui gen inc_ser_unsk 	= lai_m_s if unskilled_s == 1 & emp_ser == 1


* Population Disaggregations
*** For now, the disaggregations correspond to Gender, Area, Age Range, and Education level. You can create more disaggregations and add them in the loop.
		
cap qui gen female = male == 0
cap qui gen rural = urban == 0
		
cap qui gen age014 = inrange(age,0,14)
cap qui gen age1524 = inrange(age,15,24)
cap qui gen age2534 = inrange(age,25,34)
cap qui gen age3544 = inrange(age,35,44)
cap qui gen age4554 = inrange(age,45,54)
cap qui gen age5564 = inrange(age,55,64)
cap qui gen age65p = age > 64 if age != .
		
		
foreach var of varlist female male urban rural age1524 age2534 age3544 age4554 age5564 skilled_s unskilled_s {
	qui gen pop_`var' = total if `var' == 1
}
			
				
* Per capita income
*** This section calculate all source of income at the per capita level. Sources of income included: Total family income, Labor income, Non-labor income, Public transfers, Private transfers, Pensions, Capital, Other non-labor income.
qui bysort year hhid: egen h_lai_s = sum(tot_lai_s) if h_head != . , m 
qui gen pc_lai_s = h_lai_s / h_size
replace pc_lai_s = . if pc_inc_s == .
replace pc_lai_s = 0 if pc_inc_s != . & pc_lai_s == .

for any transfers int_remit dom_remit ns_remit pensions capital otherinla renta_imp: qui gen pc_X_s = h_X_s / h_size if h_head != .

qui egen h_nlai_s = rowtotal(h_transfers_s h_int_remit_s h_dom_remit_s h_ns_remit_s h_pensions_s h_capital_s h_otherinla_s h_renta_imp_s) if h_head != . , m
qui gen pc_nlai_s = h_nlai_s / h_size
qui replace pc_nlai_s = . if pc_inc_s == .
qui replace pc_nlai_s = 0 if pc_inc_s != . & pc_nlai_s == .

for any transfers int_remit dom_remit ns_remit pensions capital otherinla renta_imp: qui replace pc_X_s = 0 if pc_X_s == . & pc_nlai_s != .
			
qui gen pc_pubtr_s = pc_transfers_s
qui egen pc_privttr_s = rowtotal(pc_int_remit_s pc_dom_remit_s pc_ns_remit_s)
		
		
* Inequality 
*** This section calculates inequality measures.
qui gen gini = ""
qui gen theil = ""

loc init = data[1,1]
loc end = `init' + 5

forvalues a = `init'/ `end' {
	qui ainequal welfare_s [w=fexp_s] if year == `a'
	qui replace gini = r(gini_1)  if year == `a'
	qui replace theil = r(theil_1)  if year == `a'
}
		
qui destring gini theil, replace


* Save for future reference
frame copy default processed