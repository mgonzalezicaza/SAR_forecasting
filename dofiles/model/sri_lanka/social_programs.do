 
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Simulated changes in social transfers in LKA.
Institution:		World Bank - ESAPV

Authors:			Kelly Y. Montoya
E-mail:				kmontoyamunoz@worldbank.org

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  5/28/2026
===================================================================================================*/

/*===================================================================================================
	1 - Aggregated vector of changes in programs
===================================================================================================*/

* Merge cash transfers simulated vectors
merge 1:1 hhid pid using "$priv_path\SM2026\LKA\cash_transfers\data\simulated_transfers_vectors_2019_2023", nogen

* New transfers for programs that changed
if inlist(${model},2020,2024) egen new_transfers_${model} = rowtotal(grad_allowance${model} elder_allowance${model} ckd_allowance${model} disab_allowance${model} sam_allowance${model}), m

else egen new_transfers_${model} = rowtotal(grad_allowance2024 elder_allowance2024 ckd_allowance2024 disab_allowance2024 sam_allowance2024), m

bysort hhid: egen h_new_transfers_${model} = sum(new_transfers_${model}), m
replace h_new_transfers_${model} = . if h_head != 1

* Original transfers for programs that changed
egen transfers_2019 = rowtotal(grad_allowance2019 elder_allowance2019 ckd_allowance2019 disab_allowance2019 sam_allowance2019), m

bysort hhid: egen h_transfers_2019 = sum(transfers_2019), m
replace h_transfers_2019 = . if h_head != 1


/*===================================================================================================
	2 - Convert vectos to PPP
===================================================================================================*/

gen h_new_transfers_${model}_ppp = h_new_transfers_${model} / cpi$ppp / icp$ppp
gen h_transfers_2019_ppp = h_transfers_2019 / cpi$ppp / icp$ppp

compare h_transfers h_transfers_2019_ppp // Expected result!

/*===================================================================================================
	3 - Modify the whole transfers vector
===================================================================================================*/

gen h_transfers_2019_aux = - h_transfers_2019_ppp

egen h_transfers_s = rowtotal(h_transfers h_transfers_2019_aux h_new_transfers_${model}_ppp), m


/*===================================================================================================
	- END
===================================================================================================*/
