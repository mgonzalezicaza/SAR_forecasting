		
************************************************************************
* 4 - GICs
************************************************************************

* 4.1 - Calculating percentiles
**********************************
qui gen pctile_all = .
qui gen pctile_urban = .
qui gen pctile_rural = .

loc init = data[1,1]
loc end = `init' + 5

forvalues a = `init' / `end' {
	qui xtile pctile_`a' = welfare_s [w=fexp_s] if year == `a', nq(100)
	qui xtile pctile_urban_`a' = welfare_s [w=fexp_s] if year == `a' & urban == 1, nq(100)
	qui xtile pctile_rural_`a' = welfare_s [w=fexp_s] if year == `a' & rural == 1, nq(100)

	qui replace pctile_all = pctile_`a' if year == `a'
	qui replace pctile_urban = pctile_urban_`a' if year == `a'
	qui replace pctile_rural = pctile_rural_`a' if year == `a'
	drop pctile_`a' pctile_urban_`a' pctile_rural_`a'
}

* 4.2 - Mean consumption by percentile, national-level
*********************************************************
preserve
qui collapse welfare_s [iw=fexp_s], by(year pctile_all)
qui drop if pctile_all == .
qui reshape wide welfare_s, i(pctile_all) j(year)

loc sec_year = `init' + 1
forvalues a = `sec_year' / `end' {
	loc previous = `a' - 1
	qui gen r_`a' = (welfare_s`a' / welfare_s`previous' - 1) * 100
}

qui export excel using "${outfile}", sheet(GICs) firstrow(variables) sheetreplace
restore


* 4.3 - Mean consumption by percentile, urban area
*****************************************************

local areas "urban rural"
foreach area of local areas {
	preserve
	qui collapse welfare_s [iw=fexp_s], by(year pctile_`area')
	qui drop if pctile_`area' == .
	qui reshape wide welfare_s, i(pctile_`area') j(year)

	forvalues a = `sec_year' / `end' {
		loc previous = `a' - 1
		qui gen r_`a' = (welfare_s`a' / welfare_s`previous' - 1) * 100
	}

	qui export excel using "${outfile}", sheet(GICs_`area') firstrow(variables) sheetreplace
	restore
}


