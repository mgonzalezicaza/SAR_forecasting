
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Household income
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		03/17/2020

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/18/2024
===================================================================================================*/


/*===================================================================================================
	1 - Labor income
===================================================================================================*/

* Observed 
gen     h_lai_obs = h_lai * -1
replace h_lai_obs = . if h_lai_obs == 0 

* Projected
egen    h_lai_s = sum(tot_lai_s) if h_head != ., by(id) m 


/*===================================================================================================
	2 - Non-labor income
===================================================================================================*/

* Observed
bysort id: egen aux_nlai = sum(h_nlai), m
cap drop h_nlai
gen h_nlai = aux_nlai
drop aux_nlai

gen     h_nlai_obs = h_nlai * -1
replace h_nlai_obs = . if h_nlai_obs == 0 

* Projected
egen     h_inc_s = rowtotal(h_inc h_lai_obs h_lai_s h_nlai_obs h_nlai_s) if h_head != ., missing 
replace  h_inc_s = 0 if h_inc_s < 0
replace  h_inc_s = . if h_inc == .

* Per capita
gen       pc_inc_s = h_inc_s/ h_size
label var pc_inc_s "Per capita family income" 


/*===================================================================================================
	- END
===================================================================================================*/
