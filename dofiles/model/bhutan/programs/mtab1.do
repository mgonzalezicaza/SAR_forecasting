*===================================================================*
* Centro de Esutdios Distributivos, Laborales y Sociales (CEDLAS)   *
* Departamento de Economia                                          *
* Facultad de Ciencias Economicas                                   *
* Universidad Nacional de La Plata                                  *
*-------------------------------------------------------------------*
* Federico Gutierrez						    *
* Sergio Olivieri   (solivieri@depeco.econo.unlp.edu.ar)            *
*===================================================================*
* NOTE:								    *
* This version based on mtab version 3.0 developed by		    *
* Federico Gutierrez Yale University 2007			    *
*===================================================================*

/*
Description 

	mtab1 produces one-way and two-way tables and stores the results in a matrix

Options 
	total: Includes the total in the vector of results
	vec:   Only w/ two-way table. Vectorizes the matrix of results. 
	       An NxM matrix is transformed in a NMx1 vector
	blank: Only if vec option is used. Includes a blank in the vec option

*/

capture program drop mtab1 
program define mtab1
version 8

syntax varlist(max=2) [aweight] [if] [in], Summarize(varlist) MATrix(name) [QUAnty(name) Med(name) Sd(name) MIn(name) MAx(name)] [TOTal VEC VROW BLank] 
local numvar = wordcount("`varlist'")
tokenize `varlist'


qui {
	if "`weight'"!="" { 
			  local weight = "[aw`exp']"
			  }

	tab `varlist' `weight' `if' `in'
	local row = r(r)
	if "`numvar'"=="2" local col = r(c)
    }


*tab `varlist' `weight' `if' `in', summ(`summarize')


qui {

	if "`numvar'"=="1"  {

		capture drop __er*
		tab `varlist' `weight' `if' `in', g(__er)

		local cat = `row'

		if "`if'"!=""  {
			       local if = "`if' &"
			       }
		if "`if'"==""  {
			       local if = "if"
			       }

		if "`total'"==""        {
				mat `matrix' = J(1,`cat',.)
				if "`quanty'" != ""  mat `quanty' = J(1,`cat',.)
				if "`med'"    != ""  mat `med'    = J(1,`cat',.)
				if "`sd'"     != ""  mat `sd'     = J(1,`cat',.)
				if "`min'"    != ""  mat `min'    = J(1,`cat',.)
				if "`max'"    != ""  mat `max'    = J(1,`cat',.)
					}

		if "`total'"=="total"   {
					matrix `matrix' = J(1,`cat'+1,.)
					if "`quanty'" != ""  matrix `quanty' = J(1,`cat'+1,.)
					if "`med'"    != ""  matrix `med'    = J(1,`cat'+1,.)
					if "`sd'"     != ""  matrix `sd'     = J(1,`cat'+1,.)
					if "`min'"    != ""  matrix `min'    = J(1,`cat'+1,.)
					if "`max'"    != ""  matrix `max'    = J(1,`cat'+1,.)

					sum `summarize' `weight' `if' `varlist'~=. `in' ,d
					mat `matrix'[1,`cat'+1] = r(mean)
					if "`quanty'" != ""  mat `quanty'[1,`cat'+1] = r(sum_w)
					if "`med'"    != ""  mat `med'[1,`cat'+1]    = r(p50)
					if "`sd'"     != ""  mat `sd'[1,`cat'+1]     = r(sd)
					if "`min'"    != ""  mat `min'[1,`cat'+1]    = r(min)
					if "`max'"    != ""  mat `max'[1,`cat'+1]    = r(max)
					}


		forvalues f = 1/`cat'	{
					sum `summarize' `weight' `if' __er`f'==1 `in',d
					mat `matrix'[1,`f'] = r(mean)
					if "`quanty'" != "" mat `quanty'[1,`f'] = r(sum_w)
					if "`med'"    != ""  mat `med'[1,`f']   = r(p50)
					if "`sd'"     != "" mat `sd'[1,`f']     = r(sd)
					if "`min'"    != "" mat `min'[1,`f']    = r(min)
					if "`max'"    != "" mat `max'[1,`f']    = r(max)
					}

				       
		mat `matrix' = `matrix''
		if "`quanty'" != "" mat `quanty' = `quanty''
		if "`med'"    != "" mat `med'    = `med''
		if "`sd'"     != "" mat `sd'     = `sd''
		if "`min'"    != "" mat `min'    = `min''
		if "`max'"    != "" mat `max'    = `max''
		drop __er*
				}

	if "`numvar'"=="2"  {

		if "`if'"!=""  {
			       local if = "`if' &"
			       }
		if "`if'"==""  {
			       local if = "if"
			       }

		tempvar __ax
		capture gen `__ax' = 1 if `1'!=. & `2'!=.
		if _rc== 109 capture gen `__ax' = 1 if `1'!="" & `2'!=.
			if _rc== 109 capture gen `__ax' = 1 if `1'!=. & `2'!=""
				if _rc== 109  gen `__ax' = 1 if `1'!="" & `2'!=""
			
		
	

		capture drop __1st*
		tab `1' `weight' `if' `__ax'==1 `in', g(__1st)
		local row2 = r(r)

				noisily {
				if "`row2'"!="`row'" {		      
						      display in red "error in program"
						      exit
						      }
					}


		capture drop __2nd*
		tab `2' `weight' `if' `__ax'==1 `in', g(__2nd)
		local col2 = r(r)

				noisily {
				if "`col2'"!="`col'" {		      
						      display in red "error in program"
						      exit
						      }
					}

		if "`total'"==""        {
				mat `matrix' = J(`row',`col',.)
				if "`quanty'" != "" mat `quanty' = J(`row',`col',.)
				if "`med'"    != "" mat `med'    = J(`row',`col',.)
				if "`sd'"     != "" mat `sd'     = J(`row',`col',.)
				if "`min'"    != "" mat `min'    = J(`row',`col',.)
				if "`max'"    != "" mat `max'    = J(`row',`col',.)
			}
			
		if "`total'"=="total"   {
				mat `matrix' = J(`row'+1,`col'+1,.)
				if "`quanty'" != "" mat `quanty' = J(`row'+1,`col'+1,.)
				if "`med'"    != "" mat `med'    = J(`row'+1,`col'+1,.)
				if "`sd'"     != "" mat `sd'     = J(`row'+1,`col'+1,.)
				if "`min'"    != "" mat `min'    = J(`row'+1,`col'+1,.)
				if "`max'"    != "" mat `max'    = J(`row'+1,`col'+1,.)
			}
	

		
		forvalues i = 1/`row'	{
				forvalues j = 1/`col'	{
						sum `summarize' `weight' `if' __1st`i'==1 & __2nd`j'==1 `in',d
						mat `matrix'[`i',`j'] = r(mean)
						if "`quanty'" != "" mat `quanty'[`i',`j'] = r(sum_w)
						if "`med'"    != "" mat `med'[`i',`j']    = r(p50)
						if "`sd'"     != "" mat `sd'[`i',`j']     = r(sd)
						if "`min'"    != "" mat `min'[`i',`j']    = r(min)
						if "`max'"    != "" mat `max'[`i',`j']    = r(max)

						if "`total'"=="total"   {
							sum `summarize' `weight' `if' `1'!=. & __2nd`j'==1 `in',d
							mat `matrix'[`row'+1,`j'] = r(mean)
							if "`quanty'" != "" mat `quanty'[`row'+1,`j'] = r(sum_w)
							if "`med'"    != "" mat `med'[`row'+1,`j']    = r(p50)
							if "`sd'"     != "" mat `sd'[`row'+1,`j']     = r(sd)
							if "`min'"    != "" mat `min'[`row'+1,`j']    = r(min)
							if "`max'"    != "" mat `max'[`row'+1,`j']    = r(max)
									}						
							}

				if "`total'"=="total"   {
						sum `summarize' `weight' `if' __1st`i'==1 & `2'!=. `in',d
						mat `matrix'[`i',`col'+1] = r(mean)
						if "`quanty'" != "" mat `quanty'[`i',`col'+1] = r(sum_w)
						if "`med'"    != "" mat `med'[`i',`col'+1]    = r(p50)
						if "`sd'"     != "" mat `sd'[`i',`col'+1]     = r(sd)
						if "`min'"    != "" mat `min'[`i',`col'+1]    = r(min)
						if "`max'"    != "" mat `max'[`i',`col'+1]    = r(max)
							}
					}
		
		if "`total'"=="total"   {
				sum `summarize' `weight' `if' `1'!=. & `2'!=. `in',d
				mat `matrix'[`row'+1,`col'+1] = r(mean)
				if "`quanty'" != "" mat `quanty'[`row'+1,`col'+1]  = r(sum_w)
				if "`med'"    != "" mat `med'[`row'+1,`col'+1]     = r(p50)
				if "`sd'"     != "" mat `sd'[`row'+1,`col'+1]      = r(sd)
				if "`min'"    != "" mat `min'[`row'+1,`col'+1]     = r(min)
				if "`max'"    != "" mat `max'[`row'+1,`col'+1]     = r(max)
					}
				
		

		drop __1st*
		drop __2nd*

		if "`vec'"=="vec"  {
				if "`blank'"=="blank" {
					matrix __M = J(1,`col',.)
					matrix `matrix' = [`matrix' \ __M]
					matrix `matrix' = vec(`matrix')
					local numrow = rowsof(`matrix') - 1
					matrix `matrix' = `matrix'[1..`numrow',1]
					matrix drop __M
						      }
				if "`blank'"==""      {
					matrix `matrix' = vec(`matrix')
						      }

					   }

			    }
				
   }


mat list `matrix'
if "`quanty'" != "" mat list `quanty'
if "`med'"    != "" mat list `med'
if "`sd'"     != "" mat list `sd'
if "`min'"    != "" mat list `min'
if "`max'"    != "" mat list `max'

end


