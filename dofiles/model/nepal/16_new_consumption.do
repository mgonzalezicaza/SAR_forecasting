
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Household simulated consumption
Institution:		World Bank - ESAPV

Author:				Kelly Montoya
E-mail:				kmontoyamunoz@worldbank.org
Creation Date:		12/10/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  2/19/2025
===================================================================================================*/

* New cosumption
gen welfare_s = pc_inc_s / new_ratio
replace welfare_s = welfare_base * (1 + growth_cons) if new_ratio <= 0

* Rescaling using macro private consumption
if "$cons_re_scale" == "yes" {

	/*sum welfare_base [aw = h_fexp_base]
	loc base = r(mean)
	sum welfare_s [aw=h_fexp_s]
	loc sim = r(mean)

	replace welfare_s = welfare_s * ((`base' * (1 + growth_cons)) / `sim')
	*/
	
	sum	welfare_base [aw = fexp_base]
	loc base = r(mean)
	sum welfare_s [aw = fexp_s]
	replace welfare_s = `base' * (welfare_s / r(mean))

	replace welfare_s = welfare_s * (1 + growth_cons) 

	* Checking 
	sum welfare_base [aw = fexp_base]
	sca s0 = r(mean)
	sum welfare_s [aw = fexp_s]
	sca s1 = r(mean)

	if abs(round((scalar(s1)/scalar(s0)-1),.001) - round(growth_cons,.001)) > 0.01 {
			di in red "WARNING: Average per capita consumption doesn´t match macro growth rate. Difference is" 
			di in red round((scalar(s1)/scalar(s0)-1),.001) - round(growth_cons,.001)
	}


}


/*===================================================================================================
	- END
===================================================================================================*/
