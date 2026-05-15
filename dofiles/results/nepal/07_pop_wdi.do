
/*===================================================================================================
	2 - POVMOD MACRO AND POPULATION PROJECTIONS 
===================================================================================================*/

* Load the data
use "$povmod", clear

* Keep only the most recent data
tab date
gen date1=date(date,"MDY")
egen datem= max(date1)
keep if date1 == datem
tab date

* Keep only LAC countries
keep if countrycode == "${country}"

* Keep necessary variables
keep year pop

* Save version control
qui export excel using "${outfile}", sheet(pop_wdi) firstrow(variables) sheetreplace
