/*===================================================================================================
Project:			SAR Poverty micro-simulations - Simulating changes in the labor force participation rate
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		11/5/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/6/2024
===================================================================================================*/

* sample labor force 
gen lf_samp = (active ==1) if sample==1
sum lf_samp [aw = weight] 

* goal
note: this procedure changes the labor market structure (% inactivity, unemployment, employment by sector) according to elasticities.
mat activity = J(1,1,r(mean))
mat activity = r(mean)*(1 + growth_labor[1,1])
mat list activity

* allocate individuals according to their utility of being inactive
clonevar active_s = lf_samp
*clonevar U0 = U0_1 
*replace  U0 = U0_2 if U0 == .
gsort -active_s U0 id 
cap drop aux*

qui sum fexp_s			             if sample == 1 & lf_samp != . 
gen double aux = sum(fexp_s)/r(sum)  if sample == 1 & lf_samp != . 
replace active_s = 1	if aux <= (activity[1,1] + 10^(-23)) & sample == 1 & lf_samp !=. 
replace active_s = 0	if aux >  (activity[1,1] + 10^(-23)) & sample == 1 & lf_samp !=. 

* check
sum lf_samp [aw = weight] if sample == 1 
scalar v0 = r(mean)
sum active_s [aw = fexp_s] if sample == 1
scalar v1 = r(mean)

di scalar(v1)/scalar(v0)-1
mat list growth_labor

if abs( round((scalar(v1)/scalar(v0)-1),.001) - round(growth_labor[1,1],.001) ) > 0.01 {
	di in red "WARNING: New active population doesn´t match growth rate."
	break
}

cap drop aux*

/*===================================================================================================
	- END
===================================================================================================*/
