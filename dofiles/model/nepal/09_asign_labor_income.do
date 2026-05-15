
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Assign labor income by sector
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		11/8/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/8/2024
===================================================================================================*/


/*===================================================================================================
	1 - RANDOM NUMBERS
===================================================================================================*/

capture drop aleat_ila
set seed 23081985
gen aleat_ila = uniform() if sample == 1 


/*===================================================================================================
	2 - ASIGN CONTRAFACTUAL LABOR INCOME BY SECTOR
===================================================================================================*/

*  IMPUTATION of salaried to those who come from the non-employed status in order to obtain the INCOME LINEAR PROJECTION
* Note: I will keep it by education level

sum sectorg
loc lim = r(max)
replace salaried = . if unemplyd == 1

forvalues i = 1/`lim' {
   forvalues k =1(1)2 {
	   
	   sum salaried		[aw = weight] if sectorg == `i' & sample_`k' == 1
	   sca ns_`k'_`i' = 1-r(mean)
	   
	   sum public_job	[aw = weight] if sectorg == `i' & sample_`k' == 1
	   sca pj_`k'_`i' = 1-r(mean)
   }
}

/*===================================================================================================
	3 - SALARIED - NON-SALARIED
===================================================================================================*/

* Identifies the people who change sector by education level
gen     ch_l = (occupation != occupation_s) if sample_1 == 1 & (occupation_s > 0 & occupation_s < .) & salaried == .
replace ch_l = . if ch_l == 0
gen     ch_h = (occupation != occupation_s) if sample_2 == 1 & (occupation_s > 0 & occupation_s < .) & salaried == .
replace ch_h = . if ch_h == 0

* Assigns the same salaried structure of the sector
capture drop aux_l* aux_h* 

* Creates the new salaried variable
clonevar salaried_s = salaried
replace  salaried_s = 1 if (ch_l == 1 | ch_h == 1) 

forvalues i = 1/`lim' {
	
	sum  ch_l [aw = fexp_s] if sect_main6_s== `i'
	
	if r(sum) != 0 {
		gen  aux_l_`i' = sum(fexp_s)/r(sum) if ch_l == 1 & sect_main6_s== `i'
		sort aleat_ila, stable
		replace salaried_s = 0 if  aux_l_`i' <= ns_1_`i'
		di in ye "share of self employment is ===>   ns_1_`i'  = " scalar(ns_1_`i')
		ta salaried_s [aw=fexp_s] if aux_l_`i' != .
	}

	sum  ch_h [aw = fexp_s] if occupation_s == `i'
	if r(sum) != 0 {
		gen  aux_h_`i' = sum(fexp_s)/r(sum) if ch_h == 1 & sect_main6_s== `i'
		sort aleat_ila, stable
		replace salaried_s = 0 if  aux_h_`i' <= ns_2_`i'
		di in ye "share of self employment is ===>   ns_2_`i'  = " scalar(ns_2_`i')
		ta salaried_s [aw=fexp_s] if aux_h_`i' != .
	}
}

rename ch_l ch_l_sal
rename ch_h ch_h_sal
capture drop aux_l_*
capture drop aux_h_*


/*===================================================================================================
	4 - PUBLIC - PRIVATE JOBS
===================================================================================================*/

* Identifies the people who change sector by education level
gen     ch_l = (occupation != occupation_s) if sample_1 == 1 & (occupation_s > 0 & occupation_s < .) & public_job == .
replace ch_l = . if ch_l == 0
gen     ch_h = (occupation != occupation_s) if sample_2 == 1 & (occupation_s > 0 & occupation_s < .) & public_job == .
replace ch_h = . if ch_h == 0

* Creates the new public_job variable
clonevar public_job_s = public_job
replace  public_job_s = 1 if (ch_l == 1 | ch_h == 1) 
ta public_job
ta public_job_s

forvalues i = 1/`lim' {
	
	sum  ch_l [aw = fexp_s] if sect_main6_s== `i'
	if r(sum) != 0 {
		gen  aux_l_`i' = sum(fexp_s)/r(sum) if ch_l == 1 & sect_main6_s== `i'
		sort aleat_ila, stable
		replace public_job_s = 0 if  aux_l_`i' <= pj_1_`i'
		di in ye "share of private employment is ===>   pj_1_`i'  = " scalar(pj_1_`i')
		ta public_job_s [aw=fexp_s] if aux_l_`i' != .
	}

	sum  ch_h [aw = fexp_s] if sect_main6_s== `i'
	if r(sum) != 0 {
		gen  aux_h_`i' = sum(fexp_s)/r(sum) if ch_h == 1 & sect_main6_s== `i'
		sort aleat_ila, stable
		replace public_job_s = 0 if  aux_h_`i' <= pj_2_`i'
		di in ye "share of private employment is ===>   pj_2_`i'  = " scalar(pj_2_`i')
		ta public_job_s [aw=fexp_s] if aux_h_`i' != .
	}
}

rename ch_l ch_l_pj
rename ch_h ch_h_pj
capture drop aux_l_*
capture drop aux_h_*
capture drop ch_l_sal
capture drop ch_h_sal
capture drop ch_l_pj
capture drop ch_h_pj

/*===================================================================================================
	5 - COMPUTE INCOME of simulated employed who come from other sector status
===================================================================================================*/

* Rename public_job and salaried for prediction purposes
ren (public_job public_job_s salaried salaried_s) (public_job_b public_job salaried_b salaried)


* Income estimation by education level
gen  predila_n  = .

if $m == 1 {

	* linear projection
	
	* Those who come from INACTIVITY
	mat score predila_n = b_1 if occupation == 0 & occupation_s == 2 & sample == 1, replace
	mat score predila_n = b_2 if occupation == 0 & occupation_s == 3 & sample == 1, replace
	mat score predila_n = b_3 if occupation == 0 & occupation_s == 4 & sample == 1, replace

	* Those who come from UNEMPLOYMENT
	mat score predila_n = b_1 if occupation == 1 & occupation_s == 2 & sample == 1, replace
	mat score predila_n = b_2 if occupation == 1 & occupation_s == 3 & sample == 1, replace
	mat score predila_n = b_3 if occupation == 1 & occupation_s == 4 & sample == 1, replace

	* Those who come from AGRICULTURE
	mat score predila_n = b_2 if occupation == 2 & occupation_s == 3 & sample == 1, replace
	mat score predila_n = b_3 if occupation == 2 & occupation_s == 4 & sample == 1, replace

	* Those who come from INDUSTRY
	mat score predila_n = b_1 if occupation == 3 & occupation_s == 2 & sample == 1, replace
	mat score predila_n = b_3 if occupation == 3 & occupation_s == 4 & sample == 1, replace

	* Those who come from SERVICES
	mat score predila_n = b_1 if occupation == 4 & occupation_s == 2 & sample == 1, replace
	mat score predila_n = b_2 if occupation == 4 & occupation_s == 3 & sample == 1, replace

	* Those who remain in their sector but changes their intrasectoral status   
	mat score predila_n = b_1 if occupation == 2 & occupation_s == 2 & sample == 1 & skilled_s == 1 & skilled == 0, replace
	mat score predila_n = b_2 if occupation == 3 & occupation_s == 3 & sample == 1 & skilled_s == 1 & skilled == 0, replace
	mat score predila_n = b_3 if occupation == 4 & occupation_s == 4 & sample == 1 & skilled_s == 1 & skilled == 0, replace

	mat score predila_n = b_1 if occupation == 2 & occupation_s == 2 & sample == 1 & skilled_s == 0 & skilled == 1, replace
	mat score predila_n = b_2 if occupation == 3 & occupation_s == 3 & sample == 1 & skilled_s == 0 & skilled == 1, replace
	mat score predila_n = b_3 if occupation == 4 & occupation_s == 4 & sample == 1 & skilled_s == 0 & skilled == 1, replace
		 
	*  Residuals   
	replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_1 if occupation_s == 2 & sample == 1 
	replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_2 if occupation_s == 3 & sample == 1
	replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_3 if occupation_s == 4 & sample == 1

	replace predila_n = exp(predila_n)

	* Those who mantain their employment, sectoral, and intrasectoral status
	gen     lai_m_s = .
	replace lai_m_s = lai_m if occupation == occupation_s & inrange(occupation_s,2,4) & skilled == skilled_s & lai_m != .        

	* New employed who come from other sectors, non-employed or unemployed 
	replace lai_m_s = predila_n  if inrange(occupation_s,2,4) & lai_m_s == .

}

if $m != 1 {

	* Linear projection

	* Those who come from INACTIVITY
	mat score predila_n  = b_1 if occupation == 0 & occupation_s == 2 & sample == 1, replace
	mat score predila_n  = b_1 if occupation == 0 & occupation_s == 3 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 0 & occupation_s == 4 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 0 & occupation_s == 5 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 0 & occupation_s == 6 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 0 & occupation_s == 7 & sample == 1, replace

	* Those who come from UNEMPLOYMENT
	mat score predila_n  = b_1 if occupation == 1 & occupation_s == 2 & sample == 1, replace
	mat score predila_n  = b_1 if occupation == 1 & occupation_s == 3 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 1 & occupation_s == 4 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 1 & occupation_s == 5 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 1 & occupation_s == 6 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 1 & occupation_s == 7 & sample == 1, replace

	* Those who come from SKILLED - AGRICULTURE
	mat score predila_n  = b_1 if occupation == 2 & occupation_s == 3 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 2 & occupation_s == 4 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 2 & occupation_s == 5 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 2 & occupation_s == 6 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 2 & occupation_s == 7 & sample == 1, replace

	* Those who come from UNSKILLED - AGRICULTURE
	mat score predila_n  = b_1 if occupation == 3 & occupation_s == 2 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 3 & occupation_s == 4 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 3 & occupation_s == 5 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 3 & occupation_s == 6 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 3 & occupation_s == 7 & sample == 1, replace
	 
	* Those who come from SKILLED - INDUSTRY
	mat score predila_n  = b_1 if occupation == 4 & occupation_s == 2 & sample == 1, replace
	mat score predila_n  = b_1 if occupation == 4 & occupation_s == 3 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 4 & occupation_s == 5 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 4 & occupation_s == 6 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 4 & occupation_s == 7 & sample == 1, replace

	* Those who come from UNSKILLED - INDUSTRY
	mat score predila_n  = b_1 if occupation == 5 & occupation_s == 2 & sample == 1, replace
	mat score predila_n  = b_1 if occupation == 5 & occupation_s == 3 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 5 & occupation_s == 4 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 5 & occupation_s == 6 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 5 & occupation_s == 7 & sample == 1, replace

	* Those who come from SKILLED - SERVICES
	mat score predila_n  = b_1 if occupation == 6 & occupation_s == 2 & sample == 1, replace
	mat score predila_n  = b_1 if occupation == 6 & occupation_s == 3 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 6 & occupation_s == 4 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 6 & occupation_s == 5 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 6 & occupation_s == 7 & sample == 1, replace

	* Those who come from UNSKILLED - SERVICES
	mat score predila_n  = b_1 if occupation == 7 & occupation_s == 2 & sample == 1, replace
	mat score predila_n  = b_1 if occupation == 7 & occupation_s == 3 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 7 & occupation_s == 4 & sample == 1, replace
	mat score predila_n  = b_2 if occupation == 7 & occupation_s == 5 & sample == 1, replace
	mat score predila_n  = b_3 if occupation == 7 & occupation_s == 6 & sample == 1, replace

	* Residuals   
	replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_1 if inlist(occupation_s,2,3) & sample == 1 
	replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_2 if inlist(occupation_s,4,5) & sample == 1
	replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_3 if inlist(occupation_s,6,7) & sample == 1

	replace predila_n = exp(predila_n)

	* Those who mantain their employment, sectoral, and intrasectoral status
	gen     lai_m_s = .
	replace lai_m_s = lai_m if occupation == occupation_s & inrange(occupation_s,2,7) & skilled == skilled_s & lai_m != . 
	
	* New employed who come from other sectors, non-employed or unemployed 
	replace lai_m_s = predila_n  if inrange(occupation_s,2,7) & lai_m_s == .

}

* Summ those who do not belong to the sample
replace lai_m_s = lai_m  if lai_m_s == . &  lai_m != . 

* Eliminate labor income for those who pass from employed to non-employed status 
replace lai_m_s = .  if active_s  == 1 & sample == 1 & unemplyd_s  == 1 
replace lai_m_s = .  if active_s  == 0 & sample == 1

drop predila_n aleat_ila

* Name back public_job and salaried that were changes for prediction purposes
ren (public_job_b public_job salaried_b salaried) (public_job public_job_s salaried salaried_s)


/*===================================================================================================
	- END
===================================================================================================*/