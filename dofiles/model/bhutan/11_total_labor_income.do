
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Total labor income
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		03/17/2020

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/21/2024
===================================================================================================*/

capture drop aux1
capture drop aux2
capture drop tot_lai_s

egen    aux1 = rsum(lai_m lai_s) , m
replace aux1 = lai_s if lai_m < 0  
replace aux1 = aux1 *-1
egen    aux2 = rsum(lai_m_s lai_s_s), m
replace aux2 = lai_s_s if lai_m_s < 0  

egen tot_lai_s = rowtotal(tot_lai aux1 aux2), missing 
drop aux1 aux2

* Checking 

if $m == 1 {
	
	sum tot_lai		[aw = weight] if tot_lai   > 0 & tot_lai   < . 
	sca s0			= r(sum) / 1000000

	sum tot_lai_s 	[aw = fexp_s] if tot_lai_s > 0 & tot_lai_s < . 
	sca s1 			= r(sum) / 1000000

	loc r = rowsof(growth_macro_data)-1
	mat growth_ila_tot = growth_macro_data[`r',1]
	
	if abs(round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)) > 0.01 {
		di in red "WARNING: Total Income doesn´t match GDP growth rate. Difference is" 
		di in red round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)
	}
}

if $m != 1 {
	
	sum tot_lai 	[aw = weight] if tot_lai   > 0 & tot_lai   < . 
	sca s0 			= r(mean)

	sum tot_lai_s 	[aw = fexp_s] if tot_lai_s > 0 & tot_lai_s < . 
	sca s1 			= r(mean)

	loc r = rowsof(growth_labor_income)
	mat growth_ila_tot = growth_labor_income[`r',1]
	
	if abs(round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)) > 0.01 {
		di in red "WARNING: Average total labor income doesn´t match growth rate. Difference is" 
		di in red round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)
	}
}

/*===================================================================================================
	- END
===================================================================================================*/
