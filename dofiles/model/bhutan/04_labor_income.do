
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Modeling labor incomes by education skills and economic sector
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		11/5/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/6/2024
===================================================================================================*/

* y vars 
loc depvar "ln_lai_m"

* x vars 
loc ols_rhs           c.age##c.age urban ib0.male##ib0.h_head
*loc ols_rhs `ols_rhs' ib0.male#ibn.educ_lev salaried public_job skilled
loc ols_rhs `ols_rhs' ib0.male#ibn.skill_edu salaried public_job skilled
loc ols_rhs `ols_rhs' ib1.region

/*
levelsof sect_main, loc(numb_sectors)
levelsof skill_edu, loc(numb_skills)

foreach sector of numlist `numb_sectors' {
	foreach skill of numlist `numb_skills' {
		
		regress `depvar' `ols_rhs' [aw = weight] if sect_main == `sector' & skill_edu == `skill' & sample == 1
		mat b_`sector'_`skill' = e(b)
		scalar sigma_`sector'_`skill' = e(rmse)	 
	}
}
*/

levelsof sect_main, loc(numb_sectors)
foreach sector of numlist `numb_sectors' {
		
	regress `depvar' `ols_rhs' [aw = weight] if sect_main == `sector' & sample == 1
	mat b_`sector' = e(b)
	scalar sigma_`sector' = e(rmse)	 
}

/*===================================================================================================
	- END
===================================================================================================*/
