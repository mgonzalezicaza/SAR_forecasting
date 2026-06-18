
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Income growth by sector
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		03/17/2020

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/21/2024
===================================================================================================*/

/*===================================================================================================
	1 - LABOR INCOME GROWTH BY SECTOR (main and secondary activities for everybody)
===================================================================================================*/

* 3 categories sector variable
capture drop sectorg
clonevar sectorg = sect_main

sum sectorg
loc lim = r(max)

forvalues i = 1/`lim' {
	
	sum lai_m  	[aw = weight] if lai_m > 0 & lai_m < . & sectorg == `i'
	sca sp_`i' 	= r(sum) / 1000000
	sum lai_s  	[aw = weight] if lai_s > 0 & lai_s < . & sect_secu == `i' 
	sca ss_`i' 	= r(sum) / 1000000
	sca s0_`i' 	= scalar(sp_`i') + scalar(ss_`i')
	
	sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . & sect_main_s == `i'
	sca sp1_`i' = r(sum) / 1000000
	sum lai_s   [aw = fexp_s] if lai_s   > 0 &   lai_s < . & sect_secu == `i' 
	sca ss1_`i' = r(sum) / 1000000
	sca s1_`i' 	= scalar(sp1_`i') + scalar(ss1_`i')

	if `i' == 1 { 
		mat var0 = s0_`i'
		mat var1 = s1_`i'
		mat list var0
		mat list var1
	}

	if `i' != 1 {
		mat var0 = var0\s0_`i'
		mat var1 = var1\s1_`i'
		mat list var0
		mat list var1
	}
}


/*===================================================================================================
	2 - RESCALING GROWTH TO MATCH SECTORAL MACRO RATES
===================================================================================================*/

* Matrix with differences in growth rates
mat growth_ila_rel = growth_macro_data[1..`lim',1]
 
mata:
M = st_matrix("var0")
V = st_matrix("growth_ila_rel")
C = st_matrix("var1")
G = M:*(1:+V)
H = (G:/C):-1
st_matrix("growth_ila_rel_n",H)
end

* Expands income labor by sector
clonevar lai_s_s = lai_s 

forvalues i = 1/`lim'	{
   replace lai_m_s = lai_m_s * (1 + growth_ila_rel_n[`i',1]) if lai_m_s > 0 & lai_m_s != . & sect_main_s == `i'
   replace lai_s_s = lai_s_s * (1 + growth_ila_rel_n[`i',1]) if lai_s_s > 0 & lai_s_s != . & sect_secu   == `i' 
}

* Check the variations
forvalues i = 1/`lim' {
	sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . & sect_main_s == `i'
	sca sp_`i' 	= r(sum) / 1000000
	sum lai_s_s [aw = fexp_s] if lai_s_s > 0 & lai_s_s < . & sect_secu   == `i' 
	sca ss_`i' 	= r(sum) / 1000000
	sca s1_`i' 	= scalar(sp_`i') + scalar(ss_`i')
}
mat n =   scalar(s1_1)/scalar(s0_1)-1
mat n = n\scalar(s1_2)/scalar(s0_2)-1
mat n = n\scalar(s1_3)/scalar(s0_3)-1

mat diff  = growth_ila_rel - n
mat check = growth_ila_rel,n,diff
mat list check


/*===================================================================================================
	3 - RESCALING GROWTH TO MATCH TOTAL GDP RATE
===================================================================================================*/

* Re-scale the incomes in order to maintain constant the total income of the economy 
sum     lai_m   	[aw = weight] if lai_m   > 0 & lai_m != .
loc 	tot_ila_m 	= r(sum) 
sum     lai_m_s 	[aw = fexp_s] if lai_m_s > 0 & lai_m_s!=.
replace lai_m_s 	= `tot_ila_m' * (lai_m_s / r(sum)) 

sum     lai_s   	[aw = weight] if lai_s   > 0 & lai_s != .
loc 	tot_ila_s 	= r(sum)
sum     lai_s_s 	[aw = fexp_s] if lai_s_s > 0 & lai_s_s !=.
replace lai_s_s 	= `tot_ila_s' * (lai_s_s/ r(sum))

* Total GDP rescaling
loc r = rowsof(growth_macro_data) - 1
mat growth_ila_tot = growth_macro_data[`r',1]

replace lai_m_s = lai_m_s * (1 + growth_ila_tot[1,1]) if lai_m_s > 0 & lai_m_s != . 
replace lai_s_s = lai_s_s * (1 + growth_ila_tot[1,1]) if lai_s_s > 0 & lai_s_s != . 

* Checking 
sum lai_m [aw = weight] if lai_m > 0 & lai_m < . 
sca sp = r(sum) / 1000000
sum lai_s [aw = weight] if lai_s > 0 & lai_s < . 
sca ss = r(sum) / 1000000
sca s0 = scalar(sp) + scalar(ss)

sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . 
sca sp = r(sum) / 1000000
sum lai_s_s [aw = fexp_s] if lai_s_s > 0 & lai_s_s < . 
sca ss = r(sum) / 1000000
sca s1 = scalar(sp) + scalar(ss)

if abs(round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)) > 0.01 {
		di in red "WARNING: Total Income doesn´t match GDP growth rate. Difference is" 
		di in red round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)
}


/*===================================================================================================
	- END
===================================================================================================*/
