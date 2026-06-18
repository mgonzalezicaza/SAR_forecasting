*===================================================================*
* Centro de Esutdios Distributivos, Laborales y Sociales (CEDLAS)   *
* Departamento de Economia                                          *
* Facultad de Ciencias Economicas                                   *
* Universidad Nacional de La Plata                                  *
*-------------------------------------------------------------------*
* ZHANG Y KANBUR	       JDevelopment Studies (2001)          *
* Matías Horenstein (mhorenstein@gmail.com)                         *
* Sergio Olivieri   (sergio.olivieri@gmail.com)                     *
* 10-10-2005  (Beta version)                                        *
*===================================================================*

capture program drop zk
program define zk, rclass sortpreserve
version 8.0
syntax varname [if] [in] [aw fw]  , SP(varname)
loc wei: word 2 of `exp'
marksample touse
tempvar wti btw btw1 pymed1 spaux spvar

preserve

qui{
	replace `varlist' = . if `sp' == .
	keep if `touse' 
	drop if `varlist'==.
}

if "`wei'" == ""{
	tempvar wei
	g byte `wei'= 1
}



*--------------------*
* Between	     *
*--------------------*

qui{

*Totales
so `varlist'
sum `varlist'[`weight'`exp'] if `touse'
loc ymedtot = r(mean)
loc pobtot  = r(sum_w)	
loc ytot    = r(sum)

*1º Determino la cantidad de grupos y rows de las matrices de datos
qui g `spaux' = string(`sp')
encode `spaux', g(`spvar')

sum `spvar'[`weight'`exp'] if `touse'
loc ng  = r(max)
loc rN  = r(sum_w) 

/*en el caso en que sea un solo el numero de grupos*/
if `rN'==0 |`ng' == 1 {
	loc zk    = .
	loc theil = .
	display _newline as result "ZK `varlist'    = " %6.4f `zk'
	display _newline as result "Theil `varlist' = " %6.4f `theil'
	ret sca between = .
	ret sca within  = .
	ret sca theil   = .
	ret sca zk      = .

	exit
}

*Defino matrices

mat ygmed = J(`ng',1,.)
mat ygtot = J(`ng',1,.)
mat pymed = J(`ng',1,.)
mat pytot = J(`ng',1,.)


*2º Completo las matrices de participaciones y relaciones


forv i= 1/`ng'{
		sum `varlist'[`weight'`exp'] if `touse' & `spvar'==`i'
		mat ygmed[`i', 1] = r(mean)
		mat ygtot[`i', 1] = r(sum)
		mat pymed[`i', 1] = r(mean)/`ymedtot'
		mat pytot[`i', 1] = r(sum) /`ytot'
}



loc n = rowsof(pymed)
forv i = 1/`n' {
	mat pymed[`i',1] = log( pymed[`i',1] )
}

mat btw     = pymed' * pytot 
loc between = btw[1,1]



*--------------------*
* Within	     *
*--------------------*

tempvar aux
*Defino matriz

mat sumg = J(`ng',1,.)

forv i = 1/`ng'{
		gen aux_`i'=sum((`wei'*`varlist'/ ygtot[`i',1])*ln(`varlist'/ygmed[`i',1])) if `touse' & `spvar'== `i'
		sum aux_`i'
		mat sumg[`i', 1]=r(max)
		}
	}


mat wti    = sumg' * pytot
loc within = wti[1,1]


*----------------------*
* Theil - Zhang Kanbur *
*----------------------*


loc zk    = `between'/`within'
loc theil = `between'+`within'


display _newline as result "ZK `varlist'    = " %6.4f `zk'
*display _newline as result "Theil `varlist' = " %6.4f `theil'

ret sca btw	= `between'
ret sca wth	= `within'
ret sca theil   = `theil'
ret sca zk      =  `zk'

end
