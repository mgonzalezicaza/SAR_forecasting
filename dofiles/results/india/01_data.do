
* 1.3 - Temporary file
*************************
clear
loc country = "$country"
tempfile `country'

* 1.4 - Uploading the data for each year
*************************************
loc col_years = colsof(data)
forvalues i = 1/`col_years' {
	
	local year = data[1,`i']
	
	** 1.4.1 - Actual data
	*************************
	if data[2,`i'] == 0 {
		
		* Support module - CPIs and PPPs
		qui dlw, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v${cpi_version}_M) filename(Final_CPI_PPP_to_be_used.dta)
		keep if code == "${country}" & year == `year'
		keep code year cpi${ppp} icp${ppp}
		duplicates drop
		rename code countrycode
		tempfile dlwcpi
		save `dlwcpi', replace

		* India actual data follows the same harmonized source used in model/india
		qui use "${path}/input/IND_allyears_PLFS_V1_final_v01_M_cpi_microsim.dta", clear
		keep if year == `year'
		cap gen countrycode = "${country}"
		merge m:1 year using `dlwcpi', nogen keep(1 3)

		** weight
		qui cap ren wgt fexp_s
		qui cap ren weight fexp_s
		
		* Preparing variables
		ren welfare_s2s_ppp21 welfare
		ren *_ppp21 *_ppp
		ren *_s2s* ** // pds and other schemes
		
		keep countrycode year hhid pid fexp_s welfare male urban age relationharm educat* hsize ip_* inp* ila* pds_ppp oth_schemes_ppp cpi${ppp} icp${ppp} hogarsec empstat* lstatus* occup* industry* *sk* sector_3
		
		** sample
		cap drop sample
		gen sample 		= age > 14 & age != .
		
		* Household size
		clonevar h_size = hsize
		
		* Household head
		qui gen h_head = relationharm == 1 if relationharm != .
		qui bysort hhid: egen n_heads = sum(h_head), m
		qui replace h_head = 0 if h_head == . & n_heads == 1
		drop n_heads
		
		** depen
		cap drop aux*
		cap drop depen
		qui egen aux = total((age < 15 | age > 64)), by(hhid)
		qui gen depen = aux/h_size 
		
		* Conversion factor 
		gen conv_factor = cpi$ppp * icp$ppp
		
		* convert income variables to ppp
		foreach incomevar in inp_sy2023 {
			cap drop `incomevar'_ppp
			gen `incomevar'_ppp = `incomevar' / conv_factor
		}
		ren *_sy2023_ppp *_ppp
		
		* Public transfers
		egen transfers_ppp = rowtotal(pds_ppp oth_schemes_ppp), m
		
		** welfare_s
		ren welfare welfare_s				
		
		** Skill/Unskilled classification
		/*Following the ILO skill level classification[1], we classify workers into high-skilled and low-skilled. Workers in occupations such as Managers (1), Professionals (2), and Technicians and Associate professionals (3) correspond to "High-skilled" workers, whilst workers in Elementary Occupations (9) are "low-skilled." Given the diverse nature of the intermediate categories of this classification (Clerical support (4), Service and Sales (6), Skilled Agricultural, Forestry and Fisheries (6), Craft and Related Trades (7), and Plant and Machine Operators, and Assembler (8)), we added a layer to the high/low skill classification by using educational attainment and considering those with complete secondary and above as "high-skilled", and "low-skilled" otherwise. This is regardless of the workers' economic activity sector (agriculture, industry, services). Armed forces are excluded from the microsimulation model and, hence, from this classification. The table below summarizes the skill-level classification used.*/
		gen skilled_s = sk if sample == 1

		
		** Economic sectors
		/* 1 "Agriculture, Hunting, Fishing, etc." 2 "Mining" 3 "Manufacturing" 4 "Public Utility Services" 5 "Construction" 6 "Commerce" 7 "Transport and Communications" 8 "Financial and Business Services" 9 "Public Administration" 10 "Others */
		recode industrycat10_2 (1=1 "Agriculture") (2 3 4 5 =2 "Industry") (6 7 8 9 10 =3 "Services") , gen(sect_secu)
		ren sector_3 sect_main_s
		
		* Employment/unemployment
		gen emplyd_s 	= lstatus_year == 1 if welfare != . & lstatus != .  & sample == 1
		gen unemplyd_s 	= lstatus_year == 2 if welfare != . & lstatus != .  & sample == 1
		gen active_s 	= inlist(lstatus_year,1,2) if lstatus_year != .  & sample == 1

		** occupation_s
		qui gen     occupation_s = .
		qui replace occupation_s = 0 if  active_s     == 0 
		qui replace occupation_s = 1 if  unemplyd_s   == 1  	
		qui replace occupation_s = 2 if  sect_main_s == 1 & emplyd_s == 1 & skilled_s == 1
		qui replace occupation_s = 3 if  sect_main_s == 1 & emplyd_s == 1 & skilled_s == 0
		qui replace occupation_s = 4 if  sect_main_s == 2 & emplyd_s == 1 & skilled_s == 1
		qui replace occupation_s = 5 if  sect_main_s == 2 & emplyd_s == 1 & skilled_s == 0
		qui replace occupation_s = 6 if  sect_main_s == 3 & emplyd_s == 1 & skilled_s == 1
		qui replace occupation_s = 7 if  sect_main_s == 3 & emplyd_s == 1 & skilled_s == 0
		
		gen unskilled_s = !skilled_s if skilled_s != . & sample == 1 & lstatus_year == 1 & sect_main_s != .
		
		** lai_s
		qui clonevar lai_m_s = ip_ppp
		qui clonevar lai_s_s = inp_ppp
		qui egen tot_lai_s = rowtotal(lai_m_s lai_s_s), missing
		qui replace tot_lai_s = lai_s_s if lai_m_s < 0
		
		** non-labor income
		local var "transfers"
		foreach x of local var {
			qui egen     h_`x'_s = sum(`x'_ppp) /*if hogarsec != 1*/, by(hhid) //missing
			*qui replace  h_`x'_s = . if h_`x'_s == 0
		}


		** labor relationship
		local relation_vars "empstat empstat_2"
		foreach var of local relation_vars {
			gen `var'_year = `var'
			label values `var'_year `var'
		}
		
		gen salaried_s 	= empstat_year == 1 			if emplyd_s==1
		gen self_emp 	= inlist(empstat_year,3,4) 		if emplyd_s==1 
		gen unpaid 		= empstat_year == 2 			if emplyd_s==1

		gen salaried2 	= empstat_2_year == 1 			if emplyd_s==1
		gen self_emp2 	= inlist(empstat_2_year,3,4) 	if emplyd_s==1 
		gen unpaid2		= empstat_2_year == 2 			if emplyd_s==1
		
		qui gen     labor_rel = 1 if salaried_s	== 1
		qui replace labor_rel = 2 if self_emp 	== 1
		qui replace labor_rel = 3 if unpaid   	== 1
		qui replace labor_rel = 4 if unemplyd_s == 1
		
		* Saving temporal database
		qui compress
		if `year' == data[1,1] qui save ``country'', replace
		else {
			qui append using ``country''
			qui save ``country'', replace
		}
		
	}
	
	
	** 1.4.2 - Simulated data
	****************************
	if data[2,`i'] == 1 {
			
		//if "${country}" == "IND" qui use "${path}/data/${country}_`year'_6s_dom_no_int_no_inc_no_cons_no_matching_yes_st_yes.dta", clear
		if "${country}" == "IND" qui use "${path}/data/${country}_2028_6s_dom_no_int_no_inc_no_cons_no_matching_yes_st_yes.dta", clear

		di in red "${country} `year' loaded from simulations"
		
		* Preparing variables
		cap drop year
		qui gen year = `year'
		keep countrycode year hhid pid fexp_* sample welfare_* male urban age relationharm educat* h_size depen active* emplyd_s pc_inc_* poor*1 occupation_* lai_m_s lai_s_s tot_lai_* h_transfers* h_*remit* h_pensions* h_otherinla* h_capital* h_renta_imp* labor_rel salaried_s self_emp unpaid unskilled_s skilled_s cpi${ppp} icp${ppp}
		
		cap keep if welfare_s!=.
		
		* Household head
		qui gen h_head = relationharm == 1 if relationharm != .
		qui bysort hhid: egen n_heads = sum(h_head), m
		qui replace h_head = 0 if h_head == . & n_heads == 1
		drop n_heads
		
		* Labor status
		cap drop emplyd_s
		cap drop unemplyd_s
		gen emplyd_s	= inrange(occupation_s,2,7)	if welfare_s != . & occupation_s != . & sample == 1
		gen unemplyd_s 	= occupation_s == 1  if welfare_s != . & inrange(occupation_s,1,7) & sample == 1
		
		
		* Adjusting non-labor income to make it comparable
		local nonlabor "transfers int_remit dom_remit ns_remit pensions capital otherinla renta_imp"
		foreach nli of local nonlabor  {
			qui bysort year hhid: egen aux_`nli' = sum(h_`nli'_s) if h_head != ., m
			qui replace h_`nli'_s = aux_`nli' 
			drop  aux_`nli' 
		}
		
		* Saving temporal database
		qui compress
		if `year' == data[1,1] qui save ``country'', replace
		else {
			qui cap append using ``country''
			qui save ``country'', replace
		}
	}
}
