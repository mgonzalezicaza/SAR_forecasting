
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Non-labor income / International remittances
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		03/17/2020

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/18/2024
===================================================================================================*/


/*===================================================================================================
	1 - Random Allocation
===================================================================================================*/

mtab1 region urban [aw = fexp_s] if h_head == 1 & h_int_remit > 0 & h_int_remit < ., sum(h_int_remit) matrix(RT) med(MED) quanty(REM) total // Mean, median, and weight
mtab1 region urban [aw = fexp_s] if h_head == 1, sum(h_int_remit) matrix(tp) quanty(TH)

* Target growth rate
mat growth_int_rem = growth_remitt[1,1]

* Increasing order of growth rates of remittances 
mata: st_order("growth_int_rem", 1, 2, "aux_rem")
loc r = rowsof(growth_int_rem)
sca r = rowsof(growth_int_rem)

forvalues i = 1(1)`r' {
	
	* Growth rate according to population growth 
	sum h_int_remit [w = weight] if h_int_remit > 0 & h_int_remit < .
	sca var0 		= r(sum) / 1000000
	sum h_int_remit [w = fexp_s] if h_int_remit > 0 & h_int_remit < .
	sca var1 		= r(sum) / 1000000
	sca mean 		= r(mean)
	sum h_head 		[w = fexp_s] 
	sca N 			= r(sum)
	sca Tr 			= scalar(var0) * (1 + aux_rem[`i',2]) - scalar(var1)
	
	if `i' == 1 {
		mat aux_tr = Tr
		if Tr > 0 mat p = 1
		if Tr < 0 mat p = 0
	}

	if `i' >  1 {
		mat aux_tr = aux_tr\Tr
		if Tr > 0 mat p = p\1
		if Tr < 0 mat p = p\0
	}

}

* Increasing order according to transfer
mat aux_rem_1 = aux_rem,aux_tr,p
mat list aux_rem_1
mata
	h = st_matrix("aux_rem_1")
	p = st_matrix("p")
	n = colsum(p)
	m = st_numscalar("r")
	c = 0
	w = cols(h)
	j = rows(h)

	if (n == m) h = sort(h,3)
	else if (n == c) h = sort(h,-3)
    else { 
		if (n < m & n > c){
			h = sort(h,-w)
			for (i=1; i<=j; i++) {
				if (i == 1 & h[i,w]== 1) g = h[i..i,i..w]
				if (i >  1 & h[i,w]== 1) g = g\h[i..i,1..w]
			}
			g = sort(g,3)

			h = sort(h,w)
			for (i=1; i<=j; i++) {
				if (i == 1 & h[i,w]== 0) t = h[i..i,i..w]
				if (i >  1 & h[i,w]== 0) t = t\h[i..i,1..w]
			}
			t = sort(t,-3)

			h = t\g
		}
    }
	
	H = st_matrix("aux_rem_1",h)
end


mat list aux_rem_1

forvalues i = 1(1)`r' {

	if `i' == 1 {

		* Growth rate according to population growth 
		sum h_int_remit [aw = weight] if h_int_remit > 0 & h_int_remit <.
		sca var0 		= r(sum)
		sum h_int_remit [aw = fexp_s] if h_int_remit > 0 & h_int_remit <.
		sca var1 		= r(sum)
		sca mean 		= r(mean)
		sum h_head 		[aw = fexp_s] 
		sca N 			= r(sum)
		sca Tr 			= scalar(var0) * (1 + aux_rem_1[`i',2]) - scalar(var1)
		di in ye "the difference is " scalar(Tr)

		if scalar(Tr) > 0 {

			** % of households which will receive the mean remittance over the gap of those who are receiving 
			mata: st_transf("Tr","MED","RT","REM","TH")

			cap drop aux2
			cap drop aux3
			gen aux2 = .		
			gen aux3 = .
		   
			qui tab region
			loc e = r(r)

			** Rural households by region	
			forvalues x = 1/`e' {
				gsort -_Iregion_`x' urban h_head id
				capture drop aux1
				gen double aux1 = sum(fexp_s)/N_r[`x',1] if h_head == 1
				replace aux2 = tr_r[`x',1] if aux1 <= SH_r[`x',1] & aux2 == .
			}

			** Urban households by region	
			forvalues x = 1/`e' {
				gsort -_Iregion_`x' -urban h_head id
				capture drop aux1
				gen double aux1 = sum(fexp_s)/N_u[`x',1] if h_head == 1
				replace aux2 = tr_u[`x',1] if aux1 <= SH_u[`x',1] & aux2 == .
			}

			* New remittances variable
			loc 	w = aux_rem_1[`i',1]
			egen    h_int_remit_`w' = rsum(h_int_remit aux2)
			replace h_int_remit_`w' = . if h_int_remit == . & aux2 == .

			* Correction & check
			sum h_int_remit 	[w = weight] if h_int_remit		> 0 & h_int_remit 	  <.
			sca var0 			= r(sum)
			sum h_int_remit_`w' [w = fexp_s] if h_int_remit_`w' > 0 & h_int_remit_`w' <.
			sca var1 			= r(sum)
			sca g_in 			= aux_rem_1[`i',2]
			mata: st_corr2("var0","var1","g_in")
			replace h_int_remit_`w' = h_int_remit_`w' *(1 + growth_inla_n[1,1]) if h_int_remit_`w' > 0 & h_int_remit_`w' <.

			sum h_int_remit_`w' [aw = fexp_s] if h_int_remit_`w' > 0 & h_int_remit_`w' <.
			sca var1 			= r(sum)
			sca Trr 			= scalar(var0)*(1 + aux_rem_1[`i',2]) - scalar(var1)
			di in ye "the difference is " scalar(Trr)
		
		} /*( close if Tr > 0 )*/ 
	  
	  
		if scalar(Tr) < 0 {

			* Growth rate of remittances from abroad according to population growth
			sum h_int_remit [aw = weight] if h_int_remit > 0 & h_int_remit <.
			sca var0 		= r(sum)
			sum h_int_remit [aw = fexp_s] if h_int_remit > 0 & h_int_remit <.
			sca var1 		= r(sum)

			* Difference between micro and macro data growth rates 
			sca g_in = aux_rem_1[`i',2]
			mata: st_corr2("var0","var1","g_in")

			* New remittances according to the new growth rate only to those who had it
			loc 	w = aux_rem_1[`i',1]
			gen     h_int_remit_`w' = h_int_remit
			replace h_int_remit_`w' = h_int_remit_`w' *(1 + growth_inla_n[1,1]) if h_int_remit_`w' > 0 & h_int_remit_`w' <.
				
			* Check
			sum h_int_remit 	[aw = weight] if h_int_remit 	 > 0 & h_int_remit 	   < .
			sca var0 			= r(sum)
			sum h_int_remit_`w' [aw = fexp_s] if h_int_remit_`w' > 0 & h_int_remit_`w' < .
			sca var1 			= r(sum)
			sca Trr 			= scalar(var0)*(1 + aux_rem_1[`i',2]) - scalar(var1)
			di in ye "the difference is =>    " scalar(Trr)
	  
		}  /*( close if Tr < 0 )*/ 
		
	} /*( close if i == 1 )*/


	if `i' >= 2 {

		loc j = aux_rem_1[`i'-1,1]

		* Growth rate of remittances from abroad according to population growth & previous remittances growth
		sum h_int_remit 	[aw = weight] if h_int_remit 	 > 0 & h_int_remit     < .
		sca var0 			= r(sum)
		sum h_int_remit_`j' [aw = fexp_s] if h_int_remit_`j' > 0 & h_int_remit_`j' < .
		sca var1 			= r(sum)
		sca mean 			= r(mean)
		sum h_head 			[aw = fexp_s] 
		sca N 				= r(sum)
		sca Tr 				= scalar(var0)*(1 + aux_rem_1[`i',2])- scalar(var1)
		di in ye "the difference is =>    " scalar(Tr)


		if scalar(Tr) > 0 {
		
			* % of households which will receives the mean remittance over the gap of those who are receiving 
			mata: st_transf("Tr","MED","RT","REM","TH")
			 
			capt drop aux2
			capt drop aux3
			gen aux2 = .		
			gen aux3 = .
			
			qui tab `region'
			loc e = r(r)
			
			** Rural households by region	
			forvalues x = 1/`e' {
				gsort -_I`region'_`x' urban h_head hid
				capture drop aux1
				gen double aux1 = sum(fexp_s)/N_r[`x',1] if h_head == 1
				replace aux2 = tr_r[`x',1] if aux1 <= SH_r[`x',1] & aux2 == .
			}
			
			** Urban households by region	
			forvalues x = 1/`e' {
				gsort -_I`region'_`x' -urban h_head hid
				capture drop aux1
				gen double aux1 = sum(fexp_s)/N_u[`x',1] if h_head == 1
				replace aux2 = tr_u[`x',1] if aux1 <= SH_u[`x',1] & aux2 == .
			}
			
			* New remittances variable
			loc 	w = aux_rem_1[`i',1]
			egen    h_int_remit_`w' = rsum(h_int_remit_`j' aux2)
			replace h_int_remit_`w' = . if h_int_remit_`j' == . & aux2 == .
			
			* Correction & check
			sum h_int_remit 	[aw = weight] if h_int_remit > 0 & h_int_remit <.
			sca var0 			= r(sum)
			sum h_int_remit_`w'	[aw = fexp_s] if h_int_remit_`w' > 0 & h_int_remit_`w' <.
			sca var1 			= r(sum)
			sca g_in 			= aux_rem_1[`i',2]
			mata: st_corr2("var0","var1","g_in")
			replace h_int_remit_`w' = h_int_remit_`w' *(1 + growth_inla_n[1,1]) if h_int_remit_`w' > 0 & h_int_remit_`w' <.
			
			sum h_int_remit_`w'	[aw = fexp_s] if h_int_remit_`w' > 0 & h_int_remit_`w' <.
			sca var1 			= r(sum)
			sca Trr 			= scalar(var0)*(1+aux_rem_1[`i',2]) - scalar(var1)
			di in ye "the difference is =>    " scalar(Trr)
			 
		} /*( close if Tr > 0 )*/ 
		   
	   
		if scalar(Tr) < 0 {

			* Growth rate of remittances from abroad according to population growth
			sum h_int_remit 	[aw = weight] if h_int_remit > 0 & h_int_remit <.
			sca var0 			= r(sum)
			sum h_int_remit		[aw = fexp_s] if h_int_remit > 0 & h_int_remit <.
			sca var1 			= r(sum)
			 
			* Difference between micro and macro data growth rates 
			sca g_in = aux_rem_1[`i',2]
			mata: st_corr2("var0","var1","g_in")
			
			* Change remittances according to the new growth rate only to those who have it in 2006
			loc 	w = aux_rem_1[`i',1]
			gen     h_int_remit_`w' = h_int_remit
			replace h_int_remit_`w' = h_int_remit_`w' *(1 + growth_inla_n[1,1]) if h_int_remit_`w' > 0 & h_int_remit_`w' <.
				
			* Check
			sum h_int_remit 	[aw = weight] if h_int_remit > 0 & h_int_remit < .
			sca var0 			= r(sum)
			sum h_int_remit_`w' [aw = fexp_s] if h_int_remit_`w' > 0 & h_int_remit_`w' < .
			sca var1 			= r(sum)
			sca Trr 			= scalar(var0)*(1 + aux_rem_1[`i',2]) - scalar(var1)
			di in ye "the difference is =>    " scalar(Trr)
	   
		} /*( close if Tr < 0 )*/ 
	  
	}/*( close if i >= 2 )*/
	
}/*( close forvalues )*/

* Identifies the variable for the scenario we are running
mata
	k = st_matrix("aux_rem")
	r = st_matrix("growth_int_rem")
	t = k[.,2]:/r
	y = k[.,1],t
	j = rows(y)
	for (i = 1; i <= j; i++) {
		if (i == 1 & y[i,2] != 1) n = 0
		if (i == 1 & y[i,2] == 1) n = 1
		if (i != 1 & y[i,2] != 1) n = n\0
		if (i != 1 & y[i,2] == 1) n = n\1
	}
	y = y,n
	j = cols(y)
	y = sort(y,-j)
	st_numscalar("v", y[1..1,1..1])
end

loc m = scalar(v)
clonevar h_int_remit_s = h_int_remit_`m'

/*===================================================================================================
	- END
===================================================================================================*/
