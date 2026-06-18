
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Non-labor income
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		03/17/2020

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/21/2024
===================================================================================================*/

* NOTE: Each component is projected separately according to the model assumptions.

/*===================================================================================================
	1 - Capital and pensions - Apply GDP growth rate using neutral distribution
===================================================================================================*/

loc nl_incomes "remitt pensions capital"
loc lim : word count `nl_incomes'
dis `lim'

forvalues i = 1/`lim' {
	
	loc x : word `i' of `nl_incomes'

	dis as text "{hline}" _newline ///
		as text " nl income = `x'" _newline ///
		as text "{hline}" _newline

	* Growth rate according to population growth 
	sum h_`x' [aw = weight] if h_`x' > 0 & h_`x' <.
	mat var0 = r(sum) / 1000000
	sum h_`x' [aw = fexp_s] if h_`x' > 0 & h_`x' <.
	mat var1 = r(sum) / 1000000

	* Target growth rate
	mat growth_`x' = growth_nlabor[`i',1]
}

* Distance matrices
mata:
	M = st_matrix("var0")
	C = st_matrix("var1")
	V = st_matrix("growth_pensions")
	G = M:*(1:+V)
	H = (G:/C):-1
	st_matrix("growth_pensions_adjust",H)
end

mata:
	M = st_matrix("var0")
	C = st_matrix("var1")
	V = st_matrix("growth_capital")
	G = M:*(1:+V)
	H = (G:/C):-1
	st_matrix("growth_capital_adjust",H)
end

* New values for components
local nl_incomes2 "pensions capital"
foreach x of local nl_incomes2 {
	
	dis as text "`x'"
	gen  h_`x'_s = h_`x' * (1 + growth_`x'_adjust[1,1]) if h_`x' !=.
}

* Checks
local nl_incomes2 "pensions capital"
foreach x of local nl_incomes2 {
	
	sum h_`x'	[aw = weight] if h_`x' 	 > 0 & h_`x'   < . 
	sca s0 		= r(sum) / 1000000

	sum h_`x'_s [aw = fexp_s] if h_`x'_s > 0 & h_`x'_s < . 
	sca s1 		= r(sum) / 1000000

	loc r = rowsof(growth_nlabor)
	mat growth_nli = growth_nlabor[`r',1]
	
	if abs(round((scalar(s1)/scalar(s0)-1),.001) - round(growth_nli[1,1],.001)) > 0.01 {
		di in red "WARNING: `x' doesn´t match growth rate. Difference is " 
		di in red round((scalar(s1)/scalar(s0)-1),.001) - round(growth_nli[1,1],.001)
	}
}


/*===================================================================================================
	2 - Public transfers, imputed rent, other remittances, and other non-labor income - Remain constant in real terms
===================================================================================================*/

* Public transfers
gen h_transfers_s = h_transfers

* Other non-labor income 
gen h_otherinla_s = h_otherinla

* Other remittances
gen h_ns_remit_s = h_ns_remit

* Imputed rent
gen h_renta_imp_s = h_renta_imp


/*===================================================================================================
	3 - Domestic remittances - Neutral distribution or random allocation options by gdp growth
===================================================================================================*/

* Regions
capture drop region_aux
clonevar region_aux = region
levelsof region, loc(numbers)

loc reg_nw 1
foreach m of local numbers {
	
	replace region = `reg_nw' if region == `m'
	loc ++reg_nw 
}


* Dummies of regions
ta region, gen(_Iregion_)

if "${rn_dom_remitt}" == "no" {
	do "${thedo}\12_assign_dom_rem_0.do"
}

if "${rn_dom_remitt}" == "yes" {
	do "${thedo}\12_assign_dom_rem_1.do"
}


/*===================================================================================================
	4 - International remittances - Neutral distribution or random allocation options by inflows
===================================================================================================*/

* Increase/Decrease at the remittances inflows growth rate
if "${rn_int_remitt}" == "no" {
	do "${thedo}\12_assign_int_rem_0.do"
}

if "${rn_int_remitt}" == "yes" {
	do "${thedo}\12_assign_int_rem_1.do"
}

drop region
rename region_aux region
ta region


/*===================================================================================================
	5 - Total non-labor income
===================================================================================================*/

egen aux_nlai_s = rowtotal(h_*_remit_s h_pensions_s h_capital_s h_renta_imp_s h_otherinla_s h_transfers_s) if h_head == 1, missing

bysort id: egen h_nlai_s = sum(aux_nlai_s) if h_head != ., m


/*===================================================================================================
	- END
===================================================================================================*/
