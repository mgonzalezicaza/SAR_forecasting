*===================================================================*
* Centro de Esutdios Distributivos, Laborales y Sociales (CEDLAS)   *
* Departamento de Economia                                          *
* Facultad de Ciencias Economicas                                   *
* Universidad Nacional de La Plata                                  *
*-------------------------------------------------------------------*
* SHARES                                                            *
* Martin Cicowiez                                                   *
* martin@depeco.econo.unlp.edu.ar                                   *
* Leonardo Gasparini                                                *
* leonardo@depeco.econo.unlp.edu.ar                                 *
* 16-04-2003                                                        *
* 09-03-2006                                                        *
*===================================================================*

capture program drop shares

* Sintaxis:
*  shares varlist [weight] [if exp] [, variable_total(varlist) ]
* Ejemplos:
* shares p47_*
* shares p47_* if h13==1 [w=pondera], variable_total(p47t)

program define shares, rclass
  version 8.0
  syntax varlist(min=1) [if] [fweight] [, VARiable_total(varname numeric)]

  quietly {
  
    tokenize `varlist'

    preserve

    if "`variable_total'" != "" {
      summ `variable_total' [`weight'`exp'] `if', meanonly
      local aux_suma=r(sum)
    }
    
    * creo una base de datos con las sumas
    collapse (sum) `varlist' [`weight'`exp'] `if', fast

    tempvar suma_variables suma_aux
    
    if "`variable_total'" == "" {
      * calculo la suma de las variables ingresadas
      egen `suma_variables'=rsum(`varlist')
    }
    
    if "`variable_total'" != "" {
      display "aux_suma=`aux_suma'"
      gen `suma_variables'=`aux_suma'
    }
    
    * fijo el numero de observaciones de la base de datos en 2
    set obs 2

    while "`1'" != "" {
      * calculo la participacion de cada variable en el total
      replace `1' = `1'[1] / `suma_variables'[1]*100 if _n==2
      * muestro el resultado
      noisily display as result %6.4f `1'[2] _col(10) "Share `1'" 
      * devuelvo el resultado
      return scalar shr_`1' = `1'[2]
      macro shift
    }

    egen `suma_aux'=rsum(`varlist') if _n==2

    * muestro la suma de las participaciones
    * noisily display as result %6.4f `suma_aux'[2] _col(10) "TOTAL" 
    
    restore
  }
  
 
end
