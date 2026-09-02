
/*===================================================================================================
Project:			India Microsimulations Inputs from PLFS
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		4/1/2026

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  4/1/2026
===================================================================================================*/

drop _all

/*===================================================================================================
 	0 - SETTING
===================================================================================================*/

* Set up postfile for results
tempname mypost
tempfile myresults
postfile `mypost' str12(Country) Year str40(Indicator) Value using `myresults', replace

* Modifiable globals

** Dates
gl version 		"Apr-1-2026"
gl inflows 		"Seriestableview_4_1_2026"	//	Remittances file name, structure "Seriestableview_D_MM_YYYY"
gl date_inflows "Apr-1-2026"					//	Remittances file download date

** Paths
gl path 		"C:\Users\wb539669\WBG\ESAPV Files - microsim/wb539669/AM2026"
gl dofiles 		"C:\Users\wb539669\OneDrive - WBG\Documents\GitHub\SAR_forecasting\dofiles\tool"	// Do-files path
gl mpo_version 	"${path}\" // Folder name
gl downloads	"C:\Users\wb539669\Downloads"		// Your downloads folder for retrieving remittances file

* Stable globals - Should not be changed
gl cpi_version 	14
gl cpi_base		2021
gl povmod 		"\\wurepliprdfs01\gpvfile\gpv\Knowledge_Learning\Pov Projection\Central Team\MFM-allvintages.dta"
gl input_master "input_MASTER.xlsx"							// Excel file read by regional tool
*gl input_hhss_e	"inputs_hhss_elasticities.dta" 				// SARMD Input file for elasticities
*gl input_lfs_e 	"inputs_lfs_elasticities.dta" 			// SARLAB Input file for elasticities
//cap mkdir		"${mpo_version}"							// Regional tool's path
//cap mkdir 		"${mpo_version}\_inputs"					
gl path_mpo 	"${mpo_version}\_inputs"

cd "$path"


/*===========================================================================================
	1.2 - Estimations
===========================================================================================*/

use "${path}/input/IND_CYyears_PLFS_V1_final_v01_M_cpi_microsim.dta" , clear

loc country "IND"

levelsof year, local(years)
foreach year of local years {
	
	di in red "`year'"

	** Number of workers

	* Total population
	qui sum weight [w=weight] if year == `year'
	local pop = `r(sum_w)' / 1000000
	post `mypost' ("`country'") (`year') ("Total population") (`pop')

	* Working age population
	qui sum sample [w=weight] if sample == 1 & year == `year'
	local wap = `r(sum_w)' / 1000000
	post `mypost' ("`country'") (`year') ("Working age population") (`wap')

	* Active population
	qui sum sample [w=weight] if inlist(lstatus_year,1,2) & sample == 1  & year == `year'
	local active = `r(sum_w)' / 1000000
	post `mypost' ("`country'") (`year') ("Active population") (`active')

	* Inactive population
	qui sum sample [w=weight] if lstatus_year == 3 & sample == 1  & year == `year'
	local inactive = `r(sum_w)' / 1000000
	post `mypost' ("`country'") (`year') ("Inactive population") (`inactive')

	* Workers
	qui sum sample [w=weight] if lstatus_year == 1 & sample == 1  & year == `year'
	local employed = `r(sum_w)' / 1000000
	post `mypost' ("`country'") (`year') ("Working population") (`employed')

	* Unemployed
	qui sum sample [w=weight] if lstatus_year == 2 & sample == 1  & year == `year'
	local unemployed = `r(sum_w)' / 1000000
	post `mypost' ("`country'") (`year') ("Unemployed population") (`unemployed')

	* Sectoral employment
	forvalues i = 1 / 3 {

		* Skilled
		qui sum sample [w=weight] if emp_sk_`i' == 1 & sample == 1  & year == `year'
		local emp_sk_`i' = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Skilled workers `i'") (`emp_sk_`i'')

		* Unskilled
		qui sum sample [w=weight] if emp_unsk_`i' == 1 & sample == 1 & year == `year'
		local emp_unsk_`i' = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Unskilled workers `i'") (`emp_unsk_`i'')
	}


	** Labor income (avg)

	* Total
	qui sum ip_total [w=weight] if year == `year'
	local iptot = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. income") (`iptot')

	* Skilled/Unskilled
	qui sum ip_sk [w=weight] if year == `year'
	local ip_sk = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. skilled income") (`ip_sk')

	qui sum ip_unsk [w=weight] if year == `year'
	local ip_unsk = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. unskilled income") (`ip_unsk')

	* Sectoral 
	forvalues i = 1 / 3 {
		
		* Skilled
		qui sum ip_sk_`i' [w=weight] if year == `year'
		local ip_sk_`i' = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. Skilled income `i'") (`ip_sk_`i'')
				
		* Unskilled
		qui sum ip_unsk_`i' [w=weight] if year == `year'
		local ip_unsk_`i' = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. Unskilled income `i'") (`ip_unsk_`i'')
	}

	 di in red "`year' finished successfully"

} // Close loop year


postclose `mypost'
use  `myresults', clear

compress
save "$path_mpo\inputs_hhss_IND.dta", replace
export excel using "$path_mpo/$input_master", sheet("input_hhss_IND") sheetreplace firstrow(variables)


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

use "$path_mpo\inputs_hhss_IND.dta", clear
append using `macrodata'
sort Country Year Indicator
save "$path_mpo\inputs_hhss_elasticities_IND", replace

/*===================================================================================================
	- END
===================================================================================================*/
