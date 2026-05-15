
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Preparing variables
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		11/4/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  5/14/2026
===================================================================================================*/

* NOTE: Be careful: check by-one-bye

/*===================================================================================================
	1 - EMPLOYMENT STATUS
===================================================================================================*/

if "${country}${year}" == "NPL2022" { // Needs adjustment in the harmonizaton

			cap drop lstatus
			gen lstatus = 1 if q09_02 == 1 | q09_03 == 1 | q09_04 == 1 | q09_05 == 1 | q09_07 == 1 
			replace lstatus = 2 if (q09_18 == 1 & inrange(q09_20,1,11)) | (q09_19 == 1 & inlist(q09_22,1,2)) 
			replace  lstatus  = 3 if (q09_18 == 1 & !inrange(q09_20,1,11)) | (q09_18 == 2 & (q09_19 == 2 | (q09_19 == 1 & !inlist(q09_22,1,2))))
		
		}

* Status
rename  lstatus_year lstatus_year_orig
gen     lstatus_year = lstatus
replace lstatus_year = 1 if  !inlist(ip,0,.) & "${country}" == "BGD"

* Employment/unemployment
gen emplyd 		= lstatus_year == 1 if welfare != . & lstatus != .
gen unemplyd 	= lstatus_year == 2 if welfare != . & lstatus != .

* Sample
cap drop sample
gen sample 		= age > 14 & age != .
cap clonevar id	= hhid
cap clonevar idh = hhid
cap clonevar idp = pid

* Skill/Unskilled classification
/*Following the ILO skill level classification[1], we classify workers into high-skilled and low-skilled. Workers in occupations such as Managers (1), Professionals (2), and Technicians and Associate professionals (3) correspond to "High-skilled" workers, whilst workers in Elementary Occupations (9) are "low-skilled." Given the diverse nature of the intermediate categories of this classification (Clerical support (4), Service and Sales (6), Skilled Agricultural, Forestry and Fisheries (6), Craft and Related Trades (7), and Plant and Machine Operators, and Assembler (8)), we added a layer to the high/low skill classification by using educational attainment and considering those with complete secondary and above as "high-skilled", and "low-skilled" otherwise. This is regardless of the workers' economic activity sector (agriculture, industry, services). Armed forces are excluded from the microsimulation model and, hence, from this classification. The table below summarizes the skill-level classification used.*/
rename occup_year occup_year_orig
qui sum occup_year_orig
if r(N) == 0 gen occup_year = occup
else gen occup_year = occup_year_orig
			
cap drop skilled
qui gen skilled = .
replace skilled = 1 if inrange(occup_year,1,3) 	| (inlist(occup_year,4,5,6,7,8,.) & inlist(educat7,5,6,7))
replace skilled = 0 if occup_year==9 			| (inlist(occup_year,4,5,6,7,8,.) & !inlist(educat7,5,6,7))
replace skilled = 0 if inrange(occup_year,4,8) 	& educat7 == .
replace skilled = . if occup_year == . & educat7 == .
gen unskilled = !skilled if skilled != .


/*===================================================================================================
	2 - INCOME VARIABLES
===================================================================================================*/

* Foreign remittances
egen itranext = rowtotal(itranext_m itranext_nm), m

* Domestic remittances
egen itranint = rowtotal(itranint_m itranint_nm), m

* Non-specified private remittances
gen itranp_ns = itran_ns

* deflate welfare // Needs to be fixed in SARMD and dlw
if "${country}${year}" == "BGD2022" {

			sum   zu_cbn [aw=wgt] 
			local mean_nat = r(mean)
			
			/*
			sum   welfare [aw=wgt] 
			local avg = r(mean)

			gen welfare_adj = welfare*`mean_nat'/zu_cbn
			sum welfare_adj [aw=wgt] 
			local avg2 = r(mean)
			replace welfare = welfare_adj*`avg'/`avg2'
			drop welfare_adj
			*/
			replace welfare = welfaredef
			
			replace pline_nat = pline_nat * (welfaredef / welfarenat)
					
		}

* Convert to real terms
foreach incomevar in welfare ila ijubi itranext itranint itranp_ns itranp itrane icap inla_otro inla renta_imp ipcf itf ip inp {
	cap drop `incomevar'_ppp
	gen `incomevar'_ppp = `incomevar' / cpi$ppp / icp$ppp
	replace `incomevar'_ppp = `incomevar'_ppp / 12 if "$country" == "NPL"
}

*replace welfare_ppp = welfare_ppp * 12
*replace ip_ppp = . if ip < 0
*replace ila_ppp = . if ila_ppp < 0

if $national == 0 {
	*Make sure this is total family income
	clonevar h_inc		= itf_ppp
	clonevar lai_m		= ip_ppp
	clonevar lai_s		= inp_ppp
	clonevar lai_orig	= ila_ppp
}


/*===================================================================================================
	3 -  LABOR MARKET VARIABLES
===================================================================================================*/

* Economic sectors
/* 1 "Agriculture, Hunting, Fishing, etc." 2 "Mining" 3 "Manufacturing" 4 "Public Utility Services" 5 "Construction" 6 "Commerce" 7 "Transport and Communications" 8 "Financial and Business Services" 9 "Public Administration" 10 "Others */
local sectors_vars "industrycat10 industrycat10_2"
foreach var of local sectors_vars {
	cap rename `var'_year `var'_year_orig
	qui sum `var'_year_orig
	if r(N) == 0 recode `var' (1=1 "Agriculture") (2 3 4 5 =2 "Industry") (6 7 8 9 10 =3 "Services") , gen(sector_`var')
	else qui recode `var'_year (1=1 "Agriculture") (2 3 4 5 =2 "Industry") (6 7 8 9 10 =3 "Services") , gen(sector_`var')
}

ren (sector_industrycat10 sector_industrycat10_2) (sect_main sect_secu)

* public job_status
rename ocusec_year ocusec_year_orig
qui sum ocusec_year_orig
if r(N) == 0 gen ocusec_year = ocusec
else gen ocusec_year = ocusec_year_orig
label values ocusec ocusec_year ocusec_year_orig ocusec

gen     public_job = 0 if emplyd == 1
replace public_job = 1 if emplyd == 1 & ocusec_year == 1

note: by definiton the public job is part of formal services sector
replace sect_main  = 3 if !inlist(sect_main, 3) & public_job ==1 & sect_main!= .
*replace sect_main6 = 5 if !inlist(sect_main6,5) & public_job ==1 & sect_main6 != .

* Primary activity
gen     sect_main6 = .
replace sect_main6 = 1 if  sect_main == 1 & emplyd == 1 & skilled == 1
replace sect_main6 = 2 if  sect_main == 1 & emplyd == 1 & skilled == 0
replace sect_main6 = 3 if  sect_main == 2 & emplyd == 1 & skilled == 1
replace sect_main6 = 4 if  sect_main == 2 & emplyd == 1 & skilled == 0
replace sect_main6 = 5 if  sect_main == 3 & emplyd == 1 & skilled == 1
replace sect_main6 = 6 if  sect_main == 3 & emplyd == 1 & skilled == 0
label var sect_main6 "main economic sector" 

* secondary activity
gen     sect_secu6 = .
replace sect_secu6 = 1 if  sect_secu == 1 & emplyd == 1 & skilled == 1
replace sect_secu6 = 2 if  sect_secu == 1 & emplyd == 1 & skilled == 0
replace sect_secu6 = 3 if  sect_secu == 2 & emplyd == 1 & skilled == 1
replace sect_secu6 = 4 if  sect_secu == 2 & emplyd == 1 & skilled == 0
replace sect_secu6 = 5 if  sect_secu == 3 & emplyd == 1 & skilled == 1
replace sect_secu6 = 6 if  sect_secu == 3 & emplyd == 1 & skilled == 0
label var sect_secu6  "secondary economic sector" 

label def sectors         	///
1 "agriculture-skilled"   	///
2 "agriculture-unskilled" 	///
3 "industry-skilled"   		///
4 "industry-unskilled" 		///
5 "services-skilled"   		///
6 "services-unskilled", replace
label values sect_main6 sect_secu6 sectors

* labor relationship
local relation_vars "empstat empstat_2"
foreach var of local relation_vars {
	rename `var'_year `var'_year_orig
	qui sum `var'_year_orig
	if r(N) == 0 gen `var'_year = `var'
	else gen `var'_year = `var'_year_orig
	label values `var'_year `var' `var'_year_orig `var'
}

gen salaried 	= empstat_year == 1 			if emplyd==1
gen self_emp 	= inlist(empstat_year,3,4) 		if emplyd==1 
gen unpaid 		= empstat_year == 2 			if emplyd==1

gen salaried2 	= empstat_2_year == 1 			if emplyd==1
gen self_emp2 	= inlist(empstat_2_year,3,4) 	if emplyd==1 
gen unpaid2		= empstat_2_year == 2 			if emplyd==1

* primary activity
gen     labor_rel = 1 if salaried == 1
replace labor_rel = 2 if self_emp == 1
replace labor_rel = 3 if unpaid   == 1
replace labor_rel = 4 if unemplyd == 1
label var labor_rel "labor relation-primary job"

* secondary activity
gen     labor_rel2 = 1 if salaried2 == 1
replace labor_rel2 = 2 if self_emp2 == 1
replace labor_rel2 = 3 if unpaid2   == 1
label var labor_rel2 "labor relation-secondary job"

label def lab_rel 	///
1 "salaried"   		///
2 "self-employd" 	///
3 "unpaid" 			///
4 "unemployed" ,replace
label values labor_rel labor_rel2 lab_rel


/*===================================================================================================
	4 - INCOME VARIABLES CHECK
===================================================================================================*/

* labor income
egen    tot_lai = rowtotal(lai_m lai_s), missing
replace tot_lai = lai_s if lai_m < 0
replace tot_lai = . if lai_orig == .
if abs(tot_lai - lai_orig) > 1 & abs(tot_lai - lai_orig) != . di in red "WARNING: Please check variables definition. tot_lai is different from lai_orig."
drop lai_orig

* total household labor incomes
egen h_lai = sum(tot_lai) if hogarsec != 1, by(id) missing

* Household size
clonevar h_size = hsize

* Non-labor incomes
gen capital_ppp		= icap_ppp
gen pensions_ppp	= ijubi_ppp
gen otherinla_ppp	= inla_otro_ppp
gen remitt_ppp		= itranp_ppp
gen int_remit_ppp	= itranext_ppp
gen dom_remit_ppp	= itranint_ppp
gen ns_remit_ppp	= itranp_ns_ppp
gen transfers_ppp	= itrane_ppp

if $national == 0 { 
	
	note: Imputed rent included
	replace renta_imp_ppp = renta_imp_ppp / h_size
	local var "capital_ppp pensions_ppp otherinla_ppp remitt_ppp int_remit_ppp dom_remit_ppp ns_remit_ppp renta_imp_ppp transfers_ppp"
	
	foreach x of local var {
		egen     h_`x' = sum(`x') if hogarsec != 1, by(id) missing
		replace  h_`x' = . if h_`x' == 0	
	}
} 

rename h_*_ppp h_*

* household income
egen mm = rowtotal(h_lai h_*_remit h_pensions h_capital h_renta_imp h_otherinla h_transfers)
replace mm = . if mm == 0 & h_inc == .
replace mm = 0 if mm < 0

gen resid = h_inc - mm
replace resid = 0 if resid < 0
drop mm

egen h_nlai = rowtotal(h_*_remit h_pensions h_capital h_renta_imp h_otherinla h_transfers resid), missing

* at household level 
local var "h_remitt h_int_remit h_dom_remit h_ns_remit h_pensions h_capital h_renta_imp h_otherinla h_nlai h_transfers resid"
foreach x of local var {
	replace  `x' = . if relationharm != 1
}
replace h_nlai   = . if h_nlai == 0


/*===================================================================================================
	5 - INDEPENDENT VARIABLES
=====================================================================================================
	gender:			    	male 
	experience:		    	age
	experience2:			age2
	education dummies:		none and infantil
							primary
							secundary
							superior
	household head:			h_head
	marital status:			married
	regional dummies:   	region	
	remittances:		    remitt_any
	other memb public job:	oth_pub
	dependency:		        depen
===================================================================================================*/
	
* education level (aggregate primary and none)
gen educ_lev = educat5 - 1
replace educ_lev = 1 if educ_lev ==0

* household head
gen h_head = (relationharm == 1)

* marital status
gen married = (marital == 1) if marital != .

* remittances domestic or abroad
cap drop aux*
gen aux  = 1 if (remitt_ppp >0 & remitt_ppp!=.)
replace	   aux  = 0 if  aux ==. 
egen       remitt_any = max(aux), by(id)
label var  remitt_any "[=1] if household receives remittances"

* other member with public salaried job
cap drop aux*
egen 	aux 	= total(public_job), by(id)
gen     oth_pub = sign(aux - public_job)
replace oth_pub = sign(aux) if missing(public_job)
lab var oth_pub "[=1] if other member with public job"

* dependency ratio
cap drop aux*
cap drop depen
egen aux = total((age < 15 | age > 64)), by(id)
gen       depen = aux/h_size 
label var depen "potential dependency"

* log main labor income
gen ln_lai_m = ln(lai_m)

/*===================================================================================================
	6 - DEPENDENT VARIABLES
===================================================================================================*/

gen active = inlist(lstatus_year,1,2) if lstatus_year != .

gen     occupation = .
replace occupation = 0 if  active     == 0          	
replace occupation = 1 if  unemplyd   == 1	    	  	
replace occupation = 2 if  sect_main == 1 & emplyd == 1 & skilled == 1
replace occupation = 3 if  sect_main == 1 & emplyd == 1 & skilled == 0
replace occupation = 4 if  sect_main == 2 & emplyd == 1 & skilled == 1
replace occupation = 5 if  sect_main == 2 & emplyd == 1 & skilled == 0
replace occupation = 6 if  sect_main == 3 & emplyd == 1 & skilled == 1
replace occupation = 7 if  sect_main == 3 & emplyd == 1 & skilled == 0
label var occupation "occupation status"

label define occup 	///
0 "inactive" 		/// 
1 "unempl"   		///
2 "agr-sk"  		/// 
3 "agr-unsk" 		///
4 "ind-sk" 			///
5 "ind-unsk" 		///
6 "ser-sk"  		///
7 "ser-unsk", replace 
label values occupation occup
	
	
/*===================================================================================================
	7 - Setting up sample 
===================================================================================================*/

local var "ln_lai_m sect_main6 sect_main sect_secu6 sect_secu occupation"

foreach x of varlist `var' {
    replace `x' = . if sample != 1
}

* education variables
gen     sample_1 = 1 if educ_lev <  3 &  sample == 1 
lab var sample_1 "low educated"
gen     sample_2 = 1 if educ_lev >= 3 &  sample == 1 
lab var sample_2 "high educated"

gen     skill_edu = 1 if sample_1 == 1
replace skill_edu = 2 if sample_2 == 1

/*===================================================================================================
	- END
===================================================================================================*/
