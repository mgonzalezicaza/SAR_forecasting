
/*===================================================================================================
Project:			Microsimulations Inputs from Labor Force Surveys, PPP
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		10/31/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date: 	10/31/2024
===================================================================================================*/

drop _all

/*===================================================================================================
	0 - SETTING
===================================================================================================*/

* Set up postfile for results
tempname mypost
tempfile myresults
postfile `mypost' str12(Country) Year str40(Indicator) Value using `myresults', replace


/*===================================================================================================
	1 - LABOR FORCE SURVEYS DATA
===================================================================================================*/

foreach country of global countries_lfs { // Open loop countries
	
	foreach year of numlist ${init_year_lfs} / ${end_year_lfs} { // Open loop year
		
		if !inlist("`country'`year'","BGD2005","BGD2010","BGD2013","BGD2015","BGD2016","BGD2022") /// 
		 & !inlist("`country'`year'","BTN2018","BTN2019","BTN2020") /// 
		 & !inlist("`country'`year'","IND2020","IND2021","IND2022","IND2023","IND2024","IND2025") /// 
		 & !inlist("`country'`year'","NPL2017") /// 
		 & !inlist("`country'`year'","PAK2013","PAK2017","PAK2018","PAK2020") /// 
		 & !inlist("`country'`year'","LKA2019","LKA2020","LKA2021","LKA2022") ///
		 continue
		else {
		
		
		/*===========================================================================================
			1.1 - Loading the data
		===========================================================================================*/
		
		* Support module - CPIs and PPPs
		cap dlw, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v${cpi_version}_M) filename(Final_CPI_PPP_to_be_used.dta)
		keep if code == "`country'" & year == `year'
		keep code year cpi${cpi_base} icp${cpi_base}
		rename code countrycode
		tempfile dlwcpi
		save `dlwcpi', replace
		
		* SARLAB data
		cap dlw, count("`country'") y(`year') t(sarlab) clear 
		if !_rc {
			di in red "`country' `year' loaded in datalibweb"
			tempfile `country'
			save ``country'', replace
		}
		if _rc {
			di in red "`country' `year' NOT loaded in datalibweb"
			continue
		}		
		
		
		* Merge
		use ``country''
		merge m:1 countrycode year using `dlwcpi', nogen keep(1 3)
			
		
		* Defining population of reference 
		cap drop sample
		qui gen sample = age > 14 & age != .

			
		* Skill/Unskilled classification
		* Important!!! check this definition for all countries
		cap rename  lstatus_year lstatus_year_orig
		gen     lstatus_year = lstatus
		replace lstatus_year = 1 if  !inlist(wage_nc,0,.)
		
		cap rename occup_year occup_year_orig
		qui sum occup_year_orig
		if r(N) == 0 gen occup_year = occup
		else gen occup_year = occup_year_orig
		
		qui cap drop skilled
		qui gen skilled = .
		replace skilled = 1 if inrange(occup_year,1,3) 	| (inlist(occup_year,4,5,6,7,8,.) & inlist(educat7,5,6,7))
		replace skilled = 0 if occup_year==9 			| (inlist(occup_year,4,5,6,7,8,.) & !inlist(educat7,5,6,7))
		replace skilled = 0 if inrange(occup_year,4,8) 	& educat7 == .

		
		* Sector main occupation
		cap rename industrycat10_year industrycat10_year_orig
		qui sum industrycat10_year_orig
		if r(N) == 0 recode industrycat10 (1=1 "Agriculture") (2 3 4 5 =2 "Industry") (6 7 8 9 10 =3 "Services") , gen(sector_3)
		else qui recode industrycat10_year (1=1 "Agriculture") (2 3 4 5 =2 "Industry") (6 7 8 9 10 =3 "Services") , gen(sector_3)
		

		* Labor income - skilled/unskilled by sector and total
		qui gen ip_ppp = wage_nc / cpi${cpi_base} / icp${cpi_base} // Labor income main activity ppp
		for any 1 2 3: qui gen ip_sk_X 	 = ip_ppp if sample == 1 & lstatus_year == 1 & sector_3 == X & sk == 1
		for any 1 2 3: qui gen ip_unsk_X = ip_ppp if sample == 1 & lstatus_year == 1 & sector_3 == X & sk == 0
		qui gen ip_total = ip_ppp if sample == 1 & lstatus_year == 1 
		qui gen ip_sk 	 = ip_ppp if sample == 1 & lstatus_year == 1 & sk == 1 
		qui gen ip_unsk  = ip_ppp if sample == 1 & lstatus_year == 1 & sk == 0

		
		* Number of workers - skilled/unskilled by sector
		for any 1 2 3: qui gen emp_sk_X 	= (sample == 1 & lstatus_year == 1 & sector_3 == X & sk == 1)
		for any 1 2 3: qui gen emp_unsk_X 	= (sample == 1 & lstatus_year == 1 & sector_3 == X & sk == 0)
				
		
		/*===========================================================================================
			1.2 - Estimations
		===========================================================================================*/
		
		
		** Number of workers

		* Total population
		qui sum weight [w=weight]
		local pop = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Total population") (`pop')

		* Working age population
		qui sum sample [w=weight] if sample == 1
		local wap = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Working age population") (`wap')

		* Active population
		qui sum sample [w=weight] if inlist(lstatus_year,1,2) & sample == 1
		local active = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Active population") (`active')

		* Inactive population
		qui sum sample [w=weight] if lstatus_year == 3 & sample == 1
		local inactive = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Inactive population") (`inactive')

		* Workers
		qui sum sample [w=weight] if lstatus_year == 1 & sample == 1
		local employed = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Working population") (`employed')

		* Unemployed
		qui sum sample [w=weight] if lstatus_year == 2 & sample == 1 
		local unemployed = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Unemployed population") (`unemployed')

		* Sectoral employment
		forvalues i = 1 / 3 {

			* Skilled
			qui sum sample [w=weight] if emp_sk_`i' == 1 & sample == 1 
			local emp_sk_`i' = `r(sum_w)' / 1000000
			post `mypost' ("`country'") (`year') ("Skilled workers `i'") (`emp_sk_`i'')

			* Unskilled
			qui sum sample [w=weight] if emp_unsk_`i' == 1 & sample == 1 
			local emp_unsk_`i' = `r(sum_w)' / 1000000
			post `mypost' ("`country'") (`year') ("Unskilled workers `i'") (`emp_unsk_`i'')
		}


		** Labor income (avg)

		* Total
		qui sum ip_total [w=weight]
		local iptot = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. income") (`iptot')
		
		* Skilled/Unskilled
		qui sum ip_sk [w=weight] 
		local ip_sk = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. skilled income") (`ip_sk')

		qui sum ip_unsk [w=weight] 
		local ip_unsk = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. unskilled income") (`ip_unsk')

		* Sectoral 
		forvalues i = 1 / 3 {
			
			* Skilled
			qui sum ip_sk_`i' [w=weight]
			local ip_sk_`i' = `r(mean)'
			post `mypost' ("`country'") (`year') ("Avg. Skilled income `i'") (`ip_sk_`i'')
					
			* Unskilled
			qui sum ip_unsk_`i' [w=weight] 
			local ip_unsk_`i' = `r(mean)'
			post `mypost' ("`country'") (`year') ("Avg. Unskilled income `i'") (`ip_unsk_`i'')
		}

		di in red "`country' - `year' finished successfully"

		}
		
	} // Close loop year	
	
} // Close loop countries


postclose `mypost'
use  `myresults', clear

compress
save "$path_mpo\inputs_lfs.dta", replace
export excel using "$path_mpo/$input_master", sheet("input_lfs") sheetreplace firstrow(variables)


/*===================================================================================================
 	2 - MPO DATA
===================================================================================================*/

* Loading the MPO data
use "$povmod", clear

* Keep only countries of interest
keep if inlist(countrycode,"AFG","BGD","BTN","IND","MDV","NPL","PAK","LKA") 

* Keep last version
tab date
gen date1=date(date,"MDY")
egen datem= max(date1)
keep if date1 == datem
tab date

* Keep variables of interest
keep year countrycode pop privconstant gdpconstant agriconstant indusconstant servconstant

ren *constant Value*
ren pop Valuepop

reshape long Value, i(country year) j(Indicator) string
ren (countrycode year) (Country Year)

order Country Year Indicator Value
sort Country Year Indicator Value

tempfile macrodata
save `macrodata', replace


/*===================================================================================================
 	3 - ELASTICITIES INPUTS
===================================================================================================*/

use "$path_mpo\inputs_lfs.dta", clear
append using `macrodata'
sort Country Year Indicator
save "$path_mpo/$input_lfs_e", replace

/*===================================================================================================
	- END
===================================================================================================*/
