************************************************************************
* 5 - Transition matrix
************************************************************************

* 5.1 - Keep only simulated data
***********************************
qui gen simulation = .
forvalues a = 1/6 {
	loc simulated = data[2,`a']
	qui replace simulation = `simulated' if year == data[1,`a']
}

qui drop if simulation == 0
qui drop if year < ${min_sim_year}

* 5.2 - Reshape data to calculate transitions
************************************************
keep year hhid pid total fexp_base fexp_s welfare_base poor* nonpoor*
drop poor11 poor21 poor31
tab year
sca n_sim_years = r(r)
levelsof year, matrow(sim_years)
qui reshape wide total fexp_s poor* nonpoor, i(hhid pid fexp_base welfare_base) j(year)

* 5.3 - Baseline poverty 
***************************
for any ${pline1} ${pline2} ${pline3} : qui gen poorX1_base = welfare_base <= X * (365/1200) if welfare_base != .


* 5.4 - First simulated year
*******************************
loc init = sim_years[1,1]
di `init'

* Categories base year
qui gen prev_cat_`init' = ""
qui replace prev_cat_`init' = "Poor ${pline3}" if poor${pline3}1_base == 1
qui replace prev_cat_`init' = "Poor ${pline2}" if poor${pline2}1_base == 1
qui replace prev_cat_`init' = "Poor ${pline1}" if poor${pline1}1_base == 1
qui replace prev_cat_`init' = "Non-poor" if prev_cat_`init' == "" & welfare_base != .

* Collapse and save in temporary file
preserve 
ren *`init' *
qui collapse (sum) poor${pline1}2 poor${pline2}2 poor${pline3}2 nonpoor [iw=fexp_s], by(prev_cat_)
qui gen year = `init'
qui drop if prev_cat_ == ""
tempfile matrix_`init'
qui save `matrix_`init'', replace
restore

* 5.5 - The other simulated years
************************************
loc end = sim_years[n_sim_years,1]
di `end'
loc second = `init' + 1

forvalues a = `second' / `end' {
	
	loc previous = `a' - 1
	
	* Categories previous year
	qui gen prev_cat_`a' = ""
	qui replace prev_cat_`a' = "Poor ${pline3}" if poor${pline3}1`previous' == 1
	qui replace prev_cat_`a' = "Poor ${pline2}" if poor${pline2}1`previous' == 1
	qui replace prev_cat_`a' = "Poor ${pline1}" if poor${pline1}1`previous' == 1
	qui replace prev_cat_`a' = "Non-poor" if prev_cat_`a' == "" & poor${pline3}1`previous' != .
	
	* Collapse and save in temporary file
	preserve 
	ren *`a' *
	qui collapse (sum) poor${pline1}2 poor${pline2}2 poor${pline3}2 nonpoor [iw=fexp_s], by(prev_cat_)
	qui gen year = `a'
	qui drop if prev_cat_ == ""
	tempfile matrix_`a'
	qui save `matrix_`a'', replace
	restore
	
}


* 5.6 - Join the data and export
***********************************

use `matrix_`init'', clear
forvalues a = `second' / `end' {
	qui append using `matrix_`a''
}

order year
qui export excel using "${outfile}", sheet(matrix_categories) firstrow(variables) sheetreplace