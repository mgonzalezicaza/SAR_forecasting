
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Simulating changes in the unemployment rate
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		11/5/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/6/2024
===================================================================================================*/

* sample unemployment rate 
gen aux = unemplyd / lf_samp 
sum aux [aw = weight] if lf_samp == 1

* goal
mat unemploy = r(mean)*(1 + growth_labor[2,1])
mat list unemploy

* allocate individuals according to their probability of being unemployed
gen unemplyd_s = unemplyd if active_s == 1
*clonevar U1 = U1_1 
*replace  U1 = U1_2 if U1 == .
gsort -unemplyd_s U1 id 
cap drop aux*

qui sum fexp_s			            if active_s == 1 
gen double aux = sum(fexp_s)/r(sum) if active_s == 1 
replace unemplyd_s = 1			    if aux <= (unemploy[1,1] + epsfloat()) & active_s == 1 
replace unemplyd_s = 0			    if aux >  (unemploy[1,1] + epsfloat()) & active_s == 1 

* simulating: employment status
gen     emplyd_s = emplyd  if active_s  == 1
replace emplyd_s = 1       if unemplyd_s == 0 & active_s == 1
replace emplyd_s = 0       if unemplyd_s == 1 & active_s == 1
tab emplyd_s active_s

* check 
capt drop aux
gen     aux = unemplyd / lf_samp 
sum aux [aw = weight] if lf_samp == 1 
scalar v0 = r(mean)

cap drop aux
gen     aux = unemplyd_s / active_s 
sum aux [aw = fexp_s] if active_s == 1 
scalar v1 = r(mean)

di scalar(v1)/scalar(v0)-1
mat list growth_labor

if abs( round((scalar(v1)/scalar(v0)-1),.001) - round(growth_labor[2,1],.001) ) > 0.01 {
	di in red "WARNING: New unemployed population doesn´t match growth rate."
	break
}

drop aux*

/*===================================================================================================
	- END
===================================================================================================*/
