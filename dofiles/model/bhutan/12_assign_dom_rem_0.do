
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Non-labor income / Domestic remittances
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		03/17/2020

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/21/2024
===================================================================================================*/


/*===================================================================================================
	0 - Neutral Distribution
===================================================================================================*/
	
* Growth rate according to population growth 
sum h_dom_remit	[aw = weight] if h_dom_remit > 0 & h_dom_remit <.
mat var0 		= r(sum) / 1000000
sum h_dom_remit	[aw = fexp_s] if h_dom_remit > 0 & h_dom_remit <.
mat var1 		= r(sum) / 1000000

* Target growth rate
mat growth_dom_rem = growth_capital[1,1]

* Distance matrix
mata:
M = st_matrix("var0")
C = st_matrix("var1")
V = st_matrix("growth_dom_rem")
G = M:*(1:+V)
H = (G:/C):-1
st_matrix("growth_dom_rem_adjust",H)
end

* New values for domestic remittances
gen  h_dom_remit_s = h_dom_remit * (1 + growth_dom_rem_adjust[1,1]) if h_dom_remit !=.

* Check
sum h_dom_remit		[aw = weight] if h_dom_remit   > 0 & h_dom_remit   < . 
sca s0 				= r(sum) / 1000000

sum h_dom_remit_s	[aw = fexp_s] if h_dom_remit_s > 0 & h_dom_remit_s < . 
sca s1 				= r(sum) / 1000000
		
if abs(round((scalar(s1)/scalar(s0)-1),.001) - round(growth_dom_rem[1,1],.001)) > 0.01 {
	di in red "WARNING: Domestic remittances don´t match growth rate. Difference is" 
	di in red round((scalar(s1)/scalar(s0)-1),.001) - round(growth_dom_rem[1,1],.001)
}


/*===================================================================================================
	- END
===================================================================================================*/
