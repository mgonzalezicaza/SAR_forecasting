*===================================================================*
* Centro de Esutdios Distributivos, Laborales y Sociales (CEDLAS)   *
* Departamento de Economia                                          *
* Facultad de Ciencias Economicas                                   *
* Universidad Nacional de La Plata                                  *
*-------------------------------------------------------------------*
* COEFICIENTE DE GINI                                               *
* Martín Cicowiez                                                   *
* martin@depeco.econo.unlp.edu.ar                                   *
* Leonardo Gasparini                                                *
* leonardo@depeco.econo.unlp.edu.ar                                 *
* 22-11-2002                                                        *
* 05-04-2004                                                        *
* 20-03-2006                                                        *
*===================================================================*

capture program drop gini

* Sintaxis:
*  indices varlist [if exp] [weight]
* Ejemplo:
*  indices ipcf if ipcf>0 [w=pondera]

program define gini, rclass
  version 8.0
  syntax varlist(max=1) [if] [fweight aweight], [Reps(passthru)] [SAving(passthru)] [replace] [Dots] [bs]

* CONTROL SINTAXIS ++++++++++++++++++++++++++++++++++++++++++++++++++                                             

  if "`bs'" == "" {
    if "`reps'" != "" {
      display as error "Option reps not allowed without option bs"
      exit 198
    }
    if "`saving'" != "" {
      display as error "Option saving not allowed without option bs"
      exit 198
    }
    if "`replace'" != "" {
      display as error "Option replace not allowed without option bs"
      exit 198
    }
    if "`dots'" != "" {
      display as error "Option dots only not allowed without option bs"
      exit 198
    }
  }
  
  tokenize `varlist'

  quietly {
  
    tempvar suma sirve tmptmp i 

    preserve

* OBSERVACIONES A USAR ++++++++++++++++++++++++++++++++++++++++++++++

    * Pone un 1 en sirve si se cumple el if
    * Si `if' está vacio sirven todas
    mark `sirve' `if' 
    * Le quita el 1 a sirve si `1' es missing
    markout `sirve' `1'
    keep if `sirve' == 1

    local wt : word 2 of `exp'
    if "`wt'"=="" {
      local wt = 1
    }

* CALCULO GINI ++++++++++++++++++++++++++++++++++++++++++++++++++++++

    summarize `1' [`weight'`exp']
    * media
    local media=r(mean)
    * poblacion de referencia
    local obs=r(sum_w)

    sort `1'
    gen `tmptmp' = sum(`wt')
    gen `i' = (2*`tmptmp'-`wt'+1)/2
    gen `suma'=.
    replace `suma'=sum(`1'*(`obs'-`i'+1)*`wt')
    local gini = 1 + (1/`obs') - (2/(`media'*`obs'^2)) * `suma'[_N]

    return scalar gini = `gini'
    
  }

  display _newline as result "gini `1' = " %6.4f `gini'
    
* BOOTSTRAP +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  * ojo! si no hay observaciones para el bootstrap no lo hace
  if "`bs'" != "" & `obs' != 0 {
    display _newline as text "Bootstraping..."
    bs "hacebs_gini `varlist', w(`wt')" "r(gini)", `reps' `saving' `replace' `dots' nowarn 
    
    tempname aux1 aux2
    matrix `aux1' = e(ci_bc)
    return scalar ci_bc_ll = `aux1'[1,1]
    return scalar ci_bc_ul = `aux1'[2,1]
    matrix `aux2' = e(se)
    return scalar se = `aux2'[1,1]
    
  }

  restore
  
end




capture program drop hacebs_gini

program define hacebs_gini, rclass
  version 8.0
  syntax varlist(max=1), [Weight(string)]

  local wt="`weight'"

    display "varlist = `1'"
    display " weight = `weight'"

  summarize `1' [w=`wt']
  * media
  local media=r(mean)
  * poblacion de referencia
  local obs=r(sum_w)

* CALCULO GINI ++++++++++++++++++++++++++++++++++++++++++++++++++++++

  tempvar suma i tmptmp

  sort `1'
  gen `tmptmp' = sum(`wt')
  gen `i' = (2*`tmptmp'-`wt'+1)/2
  gen `suma'=.
  replace `suma'=sum(`1'*(`obs'-`i'+1)*`wt')
  
  local gini = 1 + (1/`obs') - (2/(`media'*`obs'^2)) * `suma'[_N]

  return scalar gini = `gini'
end



