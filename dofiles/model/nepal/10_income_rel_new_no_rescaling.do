
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Income growth by sector
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		03/17/2020

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/11/2024
===================================================================================================*/

/*===================================================================================================
	1 - LABOR INCOME GROWTH BY SECTOR (main and secondary activities for everybody)
===================================================================================================*/

sum sectorg
loc lim = r(max)

forvalues i = 1/`lim' {
	
	sum lai_m   [aw = weight] if lai_m   > 0 & lai_m   < . & sectorg == `i'
	sca sp_`i' 	= r(mean)
	sum lai_s   [aw = weight] if lai_s   > 0 & lai_s   < . & sect_secu6 == `i'
	sca ss_`i' 	= r(mean)
	
	sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . & sect_main6_s == `i'
	sca sp1_`i' = r(mean)
	sum lai_s 	[aw = fexp_s] if lai_s   > 0 & lai_s   < . & sect_secu6 == `i' 
	sca ss1_`i' = r(mean)
	
	if `i' == 1 { 
		mat var_sp0 = sp_`i' 
		mat var_sp1 = sp1_`i'
		mat list var_sp0
		mat list var_sp1
		
		mat var_ss0 = ss_`i' 
		mat var_ss1 = ss1_`i'
		mat list var_ss0
		mat list var_ss1
	}

	if `i' != 1 {
		mat var_sp0 = var_sp0 \ sp_`i'
		mat var_sp1 = var_sp1 \ sp1_`i'
		mat list var_sp0
		mat list var_sp1
		
		mat var_ss0 = var_ss0 \ ss_`i'
		mat var_ss1 = var_ss1 \ ss1_`i'
		mat list var_ss0
		mat list var_ss1
	
	}
}


/*===================================================================================================
	2 - RESCALING GROWTH TO MATCH SECTORAL MICRO RATES
===================================================================================================*/

* Matrix with differences in growth rates
mat growth_ila_rel = growth_labor_income[1..`lim',1]

mata:
M = st_matrix("var_sp0")
V = st_matrix("growth_ila_rel")
C = st_matrix("var_sp1")
G = M:*(1:+V)
H = (G:/C):-1
st_matrix("growth_ila_rel_sp_n",H)
end

mata:
M = st_matrix("var_ss0")
V = st_matrix("growth_ila_rel")
C = st_matrix("var_ss1")
G = M:*(1:+V)
H = (G:/C):-1
st_matrix("growth_ila_rel_ss_n",H)
end


* Expands income labor by sector
clonevar lai_s_s = lai_s 

forvalues i = 1/`lim' {
	replace lai_m_s = lai_m_s * (1 + growth_ila_rel_sp_n[`i',1]) if lai_m_s > 0 & sect_main6_s == `i'
	replace lai_s_s = lai_s_s * (1 + growth_ila_rel_ss_n[`i',1]) if lai_s_s > 0 & sect_secu6   == `i'
}

* Check the variations
forvalues i = 1/`lim' {
	sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . & sect_main6_s == `i'
	sca sp2_`i' = r(mean)
	sum lai_s_s [aw = fexp_s] if lai_s_s > 0 & lai_s_s < . & sect_secu6 == `i' 
	sca ss2_`i' = r(mean)
}

mat sp_n =   scalar(sp2_1)/scalar(sp_1)-1
mat sp_n = sp_n\scalar(sp2_2)/scalar(sp_2)-1
mat sp_n = sp_n\scalar(sp2_3)/scalar(sp_3)-1
mat sp_n = sp_n\scalar(sp2_4)/scalar(sp_4)-1
mat sp_n = sp_n\scalar(sp2_5)/scalar(sp_5)-1
mat sp_n = sp_n\scalar(sp2_6)/scalar(sp_6)-1

mat diff  = growth_ila_rel - sp_n
mat check = growth_ila_rel,sp_n,diff
mat list check

mat ss_n =   scalar(ss2_1)/scalar(ss_1)-1
mat ss_n = ss_n\scalar(ss2_2)/scalar(ss_2)-1
mat ss_n = ss_n\scalar(ss2_3)/scalar(ss_3)-1
mat ss_n = ss_n\scalar(ss2_4)/scalar(ss_4)-1
mat ss_n = ss_n\scalar(ss2_5)/scalar(ss_5)-1
mat ss_n = ss_n\scalar(ss2_6)/scalar(ss_6)-1

mat diff  = growth_ila_rel - ss_n
mat check = growth_ila_rel,ss_n,diff
mat list check


/*===================================================================================================
	3 - RESCALING ALL LABOR INCOMES BY THE GROWTH OF AVERAGE LABOR INCOME
===================================================================================================*/

sum	lai_m 		[aw = weight] if lai_m   > 0 & lai_m   != . & sect_main6   != .
loc tot_ila_s 	= r(mean)
sum lai_m_s 	[aw = fexp_s] if lai_m_s > 0 & lai_m_s != . & sect_main6_s != .
replace lai_m_s = `tot_ila_s' * (lai_m_s / r(mean)) if sect_main6_s != .

sum	lai_s 		[aw = weight] if lai_s   > 0 & lai_s   != . & sect_secu6   != .
loc tot_ila_s 	= r(mean)
sum lai_s_s 	[aw = fexp_s] if lai_s_s > 0 & lai_s_s != . & sect_secu6 != .
replace lai_s_s = `tot_ila_s' * (lai_s_s / r(mean)) if sectorg_s != .

loc r = rowsof(growth_labor_income)
mat growth_ila_tot = growth_labor_income[`r',1]

replace lai_m_s = lai_m_s * (1 + growth_ila_tot[1,1]) if lai_m_s > 0 & lai_m_s != . 
replace lai_s_s = lai_s_s * (1 + growth_ila_tot[1,1]) if lai_s_s > 0 & lai_s_s != . 

* Checking 
sum lai_m	[aw = weight] if lai_m   > 0 & lai_m   < . & sect_main6   != .
sca s0 		= r(mean)
sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . & sect_main6_s != .
sca s1 		= r(mean)

if abs(round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)) > 0.01 {
		di in red "WARNING: Average total labor income in main activity doesn´t match growth rate. Difference is" 
		di in red round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)
}

sum lai_s	[aw = weight] if lai_s   > 0 & lai_s   < . & sect_secu6 != .
sca s0 		= r(mean)
sum lai_s_s [aw = fexp_s] if lai_s_s > 0 & lai_s_s < . & sect_secu6 != .
sca s1 		= r(mean)

if abs(round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)) > 0.01 {
		di in red "WARNING: Average total labor income in secondary activity doesn´t match growth rate. Difference is" 
		di in red round((scalar(s1)/scalar(s0)-1),.001) - round(growth_ila_tot[1,1],.001)
}


/*===================================================================================================
	- END
===================================================================================================*/
