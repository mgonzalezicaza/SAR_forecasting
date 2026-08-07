qui use  "${out_sim}", clear


* Identify new poor
for any 30 42 83 170: gen newpoor_X = 1 if pov_X_2 == 1 & pov_X_0 == 0
replace newpoor_42 = newpoor_30 if newpoor_42 == .
replace newpoor_83 = newpoor_42 if newpoor_83 == .
replace newpoor_170 = newpoor_83 if newpoor_170 == .

* New poor household
for any 30 42 83 170: gen newpoorhh_X = 1 if newpoor_X == 1 & h_head == 1 

* Calculate cash transfers
gen aux = - welfare_post
for any 30 42 83 170: egen cons_change_X = rowtotal(lp_Xusd_ppp aux) if newpoor_X == 1, m
for any 30 42 83 170: gen tot_cons_change_X = cons_change_X
sum cons_change_* [w=pondera_26]


* Aggregates by country
preserve
	collapse (sum) newpoorhh_* tot_cons_change_* (mean) cons_change_* [iw = pondera_26], by(country)
	tempfile aggregates
	save `aggregates', replace
restore

* SAR
preserve
	collapse (sum) newpoorhh_* tot_cons_change_* (mean) cons_change_* [iw = pondera_26]
	gen country = "SAR" 
	tempfile region
	save `region', replace
restore

* SAR without India
preserve
	keep if country != "IND"
	collapse (sum) newpoorhh_* tot_cons_change_* (mean) cons_change_* [iw = pondera_26]
	gen country = "SAR without IND"
	tempfile region_wo_ind
	save `region_wo_ind', replace
restore

use `aggregates', clear
append using `region'
append using `region_wo_ind'

* Variable labels
labvars ///
newpoorhh_30  "New poor households at $3.0 USD" ///
newpoorhh_42  "New poor households at $4.2 USD" ///
newpoorhh_83  "New poor households at $8.3 USD" ///
newpoorhh_170 "New vuln households at $17 USD" ///
tot_cons_change_30  "Total compensation new poor ($3.0 usd) per month" ///
tot_cons_change_42  "Total compensation new poor ($4.2 usd) per month" ///
tot_cons_change_83  "Total compensation new poor ($8.3 usd) per month" ///
tot_cons_change_170 "Total compensation new vuln ($17 usd) per month" ///
cons_change_30  "Per capita compensation new poor ($3.0 usd) per month" ///
cons_change_42  "Per capita compensation new poor ($4.2 usd) per month" ///
cons_change_83  "Per capita compensation new poor ($8.3 usd) per month" ///
cons_change_170 "Per capita compensation new vuln ($17 usd) per month", alternate

export excel using "${out}", sheet("compensation") firstrow(varlabels) sheetmodify

