
*******************************************************************************************************************
*	Project:			Inflation Prices
*	Institution:		World Bank - ELCPV

*	Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
*	Creation Date:		08/08/2023

*	Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
*	Modification date: 	08/08/2023
*******************************************************************************************************************

drop _all

*******************************************************************************************************************
*	0 - SET UP
*******************************************************************************************************************

* Globals
************
gl version "AUG_8_2023"
gl path "Z:\wb520054\Micro-simulations\00_shared_by_Jaime"
gl ipc_file "base_cpi_headline_food.xlsx"

cd "$path"

gl country_name "Argentina Belize Bolivia Brazil Chile Colombia Costa_Rica Dominican_Republic Ecuador El_Salvador Guatemala Honduras Jamaica Mexico Nicaragua Panama Paraguay Peru_Disc Peru_New Suriname Trinidad_Tobago Uruguay"
gl country_code ""


*******************************************************************************************************************
* 1 - INFLATION - TOTAL
*******************************************************************************************************************

import excel "raw/${ipc_file}", sheet("Food") firstrow clear
	
* Keep only 2021 and 2022
gen year = year(date)
gen month = month(date)
keep if inrange(year,2021,2022)
	
reshape long food, i(year month) j(country) string
sort country month year
order country

gen growth = (food / food[_n-1] -1) if month == month[_n-1]
	
* keep necessary variables
collapse growth, by(country year)
	

