*=============================================================================
* TITLE: 15 - Relative price adjustment in poverty lines
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*=============================================================================
* Created on : Mar 17, 2020
* Last update: Jan 04, 2021
*			   May 02, 2022 Kelly Y. Montoya - New poverty lines ppp2017
*=============================================================================

*=============================================================================
if "$ppp17" == "no" {
	loc pov_line = "lp_550usd_ppp lp_190usd_ppp lp_320usd_ppp"
	foreach var of local pov_line {

		clonevar `var'_s = `var'
		replace  `var'_s = `var'_s *(1 + growth_pl[1,1])
	}
}

else {
	loc pov_line = "lp_685usd_ppp lp_365usd_ppp lp_215usd_ppp"
	foreach var of local pov_line {

		clonevar `var'_s = `var'
		replace  `var'_s = `var'_s *(1 + growth_pl[1,1])
	}
}

*=============================================================================
