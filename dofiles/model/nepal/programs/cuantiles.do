*===================================================================*
* cuantiles.do                                                      *
*===================================================================*

* ultima revision
* 10/1/2005
* 27/1/2006
* 4/15/2007

capture program drop cuantiles

program define cuantiles, eclass sortpreserve
  version 8.0
  syntax varlist(max=1) [aweight] [if], Ncuantiles(integer) Generate(namelist) [orden_aux(varlist)]
  tokenize `varlist'
  
  quietly {

    * cuantiles en, por ejemplo, d_ipcf
    local quanpers="`generate'"
    
    tempvar suma mipondera mivar
  
    local wt : word 2 of `exp'
    if "`wt'"=="" {
      local wt = 1
    }  

    gen `mivar'=.
    replace `mivar'=`1' `if' 
    * ojo con los missing!
    * no lo puedo hacer en la linea anterior porque la macro local if incluye la palabra "if"
    replace `mivar'=. if `1'==.
    
    sort `mivar' `orden_aux'
    
    gen `mipondera'=`wt'
    replace `mipondera'=0 if `mivar'==.     
    gen `suma'=sum(`mipondera')

    *ppquan = Personas Por Quantil
    *ppquan es el número de personas que debería tener cada quantil

    summ `mipondera', meanonly
    
    scalar ppquan = r(sum)/`ncuantiles'
    generate `quanpers'=.
    
    forvalues i=1(1)`ncuantiles' {
      display `i'
      replace `quanpers'=`i' if `suma'>(`i'-1)*ppquan & `suma'<=`i'*ppquan & `mivar'!=. 
    }
 
  }
  tabulate `quanpers' [`weight'`exp'], summ(`1')

* guarda resulatdos en una matriz
  forvalues j=1/`ncuantiles'	{
	qui sum `1' [`weight'`exp'] if `quanpers'==`j'
	if `j'==1 mat Q = r(mean)
	if `j'!=1 mat Q = Q \ r(mean)
	}
   ereturn mat Q = Q
 
end




