
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Set-up parameters
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		11/4/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/11/2024
===================================================================================================*/

/*===================================================================================================
	1 - SETIING UP THE MODEL
===================================================================================================*/

if $sector_model == 3 {
	
	* sectorial growth rates
	gl input_gdp_sheet "input_gdp"
	gl do_income "10_income_rel"
	
}

if $sector_model == 6 {
	
	* sectorial growth rates
	gl input_gdp_sheet "input_gdp2"
	
	* do-file 10 for re-scaling options
	if "$inc_re_scale" == "yes" gl do_income "10_income_rel_new"
	else gl do_income "10_income_rel_new_no_rescaling"
	
}

* mata matrix
mata:
void st_shares(string scalar name1)
{
	real matrix M,N,P
	M = st_matrix(name1)
    N = runningsum(M[1..(rows(M)-1),1])
    P = N:/M[rows(M),1]
    st_matrix("shr",P)
}
end


/*===================================================================================================
	2 - GENERAL PARAMETERS
===================================================================================================*/

preserve

	import excel using "$inputs", sheet("input_setup") first clear

	* type of estimation
	gl national   = type_estimation[1]
	if $national == 1 gl tipo "local"
	if $national == 0 gl tipo "inter"  

	* select scenario
	gl model = model[1]
	tostring model, replace

	* sectors (by default 6 sectors with intrasectorals)
	gl m = num_sectors[1]
	
	* new weights
	if inlist(weights,1) gl weights = 1
	if inlist(weights,0) gl weights = 0

	* average labor incomes
	import excel using "$inputs", sheet("$input_gdp_sheet") first clear
	mkmat rate, mat(growth_labor_income)

	* macro data
	import excel using "$inputs", sheet("input_gdp") first clear
	mkmat rate, mat(growth_macro_data)

	* labor market
	import excel using "$inputs", sheet("input_labor") first clear
	mkmat rate, mat(growth_labor)

	* intrasectoral
	import excel using "$inputs", sheet("input_intrasectoral") first clear
	mkmat rate, mat(growth_intrasectoral)

	* non-labor incomes
	import excel using "$inputs", sheet("input_nonlabor") first clear
	mkmat rate, mat(growth_nlabor)
	
	* total population
	import excel using "$inputs", sheet("input_pop_wdi") first clear
	mkmat value, mat(growth_pop_wdi)

restore


/*===================================================================================================
	- END
===================================================================================================*/
