
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Non-labor income / International remittances
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
sum h_int_remit	[aw = weight] if h_int_remit > 0 & h_int_remit <.
mat var0 		= r(sum) / 1000000
sum h_int_remit	[aw = fexp_s] if h_int_remit > 0 & h_int_remit <.
mat var1 		= r(sum) / 1000000

* Target growth rate
mat growth_int_rem = growth_remitt[1,1]

* Distance matrix
mata:
M = st_matrix("var0")
C = st_matrix("var1")
V = st_matrix("growth_int_rem")
G = M:*(1:+V)
H = (G:/C):-1
st_matrix("growth_int_rem_adjust",H)
end

* New values for remittances
gen  h_int_remit_s = h_int_remit * (1 + growth_int_rem_adjust[1,1]) if h_int_remit !=.

* Check
sum h_int_remit		[aw = weight] if h_int_remit   > 0 & h_int_remit   < . 
sca s0 				= r(sum) / 1000000

sum h_int_remit_s	[aw = fexp_s] if h_int_remit_s > 0 & h_int_remit_s < . 
sca s1 				= r(sum) / 1000000
		
if abs(round((scalar(s1)/scalar(s0)-1),.001) - round(growth_int_rem[1,1],.001)) > 0.01 {
	di in red "WARNING: International remittances don´t match growth rate. Difference is" 
	di in red round((scalar(s1)/scalar(s0)-1),.001) - round(growth_int_rem[1,1],.001)
}


/*===================================================================================================
	- END
===================================================================================================*/
