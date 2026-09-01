
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Modelling labor status by education skills
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri 
E-mail:				solivieri@worldbank.org
Creation Date:		11/5/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/6/2024
===================================================================================================*/

/*===================================================================================================
	1 - INDEPENDENT VARIABLES
===================================================================================================*/

cap drop region 
encode subnatid1, gen(region)

loc mnl_rhs           c.age##c.age urban ib0.male#ibn.h_head#ib0.married
*loc mnl_rhs `mnl_rhs' remitt_any depen oth_pub ib0.male#ibn.educ_lev atschool
loc mnl_rhs `mnl_rhs' remitt_any depen oth_pub ib0.male#ibn.skill_edu atschool
loc mnl_rhs `mnl_rhs' ib1.region

* Note: I had to change the model for convergence. The new model is global and the education independent variable is now skill_edu instead of educ_lev

/*===================================================================================================
	2 - MULTINOMIAL
===================================================================================================*/
/*
* skill education levels
levelsof skill_edu, loc(numb_skills)

foreach skill of numlist `numb_skills' {
	
	di in red "skill_edu == `skill'"

	sum occupation if skill_edu == `skill' 
	loc base = r(min)
	mlogit occupation `mnl_rhs'  [aw = weight] if skill_edu == `skill' & sample == 1, baseoutcome(`base')

	* residuals
	levelsof occupation if skill_edu == `skill', local(occ_cat) 
	loc rvarlist
	
	foreach sect of numlist `occ_cat' {
		loc rvarlist "`rvarlist' U`sect'_`skill'"
	}
	
	set seed 23081985
	simchoiceres `rvarlist' if skill_edu == `skill', total
}*/

sum occupation
loc base = r(min)
mlogit occupation `mnl_rhs'  [aw = weight] if sample == 1, baseoutcome(`base') difficult

* residuals
levelsof occupation, local(occ_cat) 
loc rvarlist
	
foreach sect of numlist `occ_cat' {
	loc rvarlist "`rvarlist' U`sect'"
}
	
set seed 23081985
simchoiceres `rvarlist', total


/*===================================================================================================
	- END
===================================================================================================*/
