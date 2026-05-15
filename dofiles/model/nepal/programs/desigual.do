*===================================================================*
* Centro de Esutdios Distributivos, Laborales y Sociales (CEDLAS)   *
* Departamento de Economia                                          *
* Facultad de Ciencias Economicas                                   *
* Universidad Nacional de La Plata                                  *
*-------------------------------------------------------------------*
* MEDIDAS DE DESIGUALDAD                                            *
* Martín Cicowiez                                                   *
* martin@depeco.econo.unlp.edu.ar                                   *
* Leonardo Gasparini                                                *
* leonardo@depeco.econo.unlp.edu.ar                                 *
* 22-11-2002                                                        *
* 19-04-2004                                                        *
* 21-04-2006                                                        *
* 05-07-2007                                                        *
*===================================================================*

capture program drop desigual

* Sintaxis:
*  desigual varlist [if exp] [weight]
* Ejemplo:
*  desigual ipcf if ipcf>0 [w=pondera]

program define desigual, rclass byable(recall)
  version 8.0
  syntax varlist(max=1) [if] [fweight] [, tipo_reporte(integer 0)]
  tokenize `varlist'

* CONTROL SINTAXIS ++++++++++++++++++++++++++++++++++++++++++++++++++

  if `tipo_reporte' <0 | `tipo_reporte' >1 {
    display as error "La opcion tipo_reporte solo admite los valores 0,1"
    exit 198
  }


  quietly {
  
    preserve

    * pongo un 1 en sirve si se cumple el if
    * si `if' está vacio sirven todas
    marksample sirve 
    * le quito el 1 a sirve si `1' es missing
    markout `sirve' `1'
    keep if `sirve' == 1

    local wt : word 2 of `exp'
    if "`wt'"=="" {
      local wt = 1
    }

    * ordeno las observaciones de < a > segun `1'
    sort `1'

    summarize `1' [`weight'`exp']
    * media
    local media=r(mean)
    * poblacion de referencia
    local obs=r(sum_w)
    * desvio estandar
    local std=r(sd)

    * salir si no hay observaciones
    if `obs'==0 exit

* VARIABLES TEMPORALES ++++++++++++++++++++++++++++++++++++++++++++++

    tempvar suma tmptmp i indice_nombre indice_valor aux
    gen `suma'=.
    gen `aux'=.

*---------------------------------------------------------*
* Coeficiente de Gini                                     *
*---------------------------------------------------------*

    gen `tmptmp' = sum(`wt') 
    gen `i' = (2*`tmptmp'-`wt'+1)/2 
    replace `suma'=sum(`1'*(`obs'-`i'+1)*`wt') 
    local gini = 1 + (1/`obs') - (2/(`media'*`obs'^2)) * `suma'[_N]

*---------------------------------------------------------*
* Indice de Theil                                         *
*---------------------------------------------------------*

    replace `suma' = sum(`wt'*(`1'/`media')*ln(`1'/`media')) 
    local theil = (1/`obs')*`suma'[_N]

*---------------------------------------------------------*
* Coeficiente de Variacion                                *
*---------------------------------------------------------*

   local cv=`std'/`media'

*---------------------------------------------------------*
* Coeficiente de Atkinson                                 *
*---------------------------------------------------------*

** epsilon = 0.5
    local epsilon=0.5
    replace `aux'=`1'^(1-`epsilon')*`wt' 
    replace `suma'=sum(`aux') 
    local atk_e05 = 1 - ( (`suma'[_N]/`obs') ^ (1/(1-`epsilon')) ) / `media'

** epsilon = 1.0
    means `1' [`weight'`exp'] 
    local atk_e1 = 1 - r(mean_g)/`media'

** epsilon = 2.0    
    local epsilon=2
    replace `aux'=`1'^(1-`epsilon')*`wt' 
    replace `suma'=sum(`aux') 
    local atk_e2 = 1 - ( (`suma'[_N]/`obs') ^ (1/(1-`epsilon')) ) / `media'

*---------------------------------------------------------*
* Indice de Entropia Generalizado                         *
*---------------------------------------------------------*

*** theta = 0.000 1
    local theta=0.0001
    replace `suma'=sum( `wt' * (`1'/`media')^`theta' ) 
    local ge_0 = ( `suma'[_N]/`obs' - 1 ) / (`theta'*(`theta'-1))

*** theta = 0.9999
    local theta=0.9999
    replace `suma'=sum( `wt' * (`1'/`media')^`theta' ) 
    local ge_1 = ( `suma'[_N]/`obs' - 1 ) / (`theta'*(`theta'-1))
    
*** theta = 2
    local theta=2
    replace `suma'=sum( `wt' * (`1'/`media')^`theta' ) 
    local ge_2 = ( `suma'[_N]/`obs' - 1 ) / (`theta'*(`theta'-1))


* GENERACION REPORTE ++++++++++++++++++++++++++++++++++++++++++++++++

    restore

    gen `indice_valor'=.
    label variable `indice_valor' "`1'"

    replace `indice_valor' = `gini' if _n==1
    replace `indice_valor' = `theil' if _n==2
    replace `indice_valor' = `cv' if _n==3
    replace `indice_valor' = `atk_e05' if _n==4
    replace `indice_valor' = `atk_e1' if _n==5
    replace `indice_valor' = `atk_e2' if _n==6
    replace `indice_valor' = `ge_0' if _n==7
    replace `indice_valor' = `ge_1' if _n==8
    replace `indice_valor' = `ge_2' if _n==9

    gen `indice_nombre'=.
    label variable `indice_nombre' "Medidas de Desigualdad"
    replace `indice_nombre'=_n if `indice_valor' !=. /*if _n<=8*/

    label define `indice_nombre' /*
    */ 1 "Coeficiente de Gini" /*
    */ 2 "Indice de Theil" /*
    */ 3 "Coeficiente de Variacion" /*
    */ 4 "Coeficiente de Atkinson (e=0.5)" /*
    */ 5 "Coeficiente de Atkinson (e=1.0)" /*
    */ 6 "Coeficiente de Atkinson (e=2.0)" /* 
    */ 7 "Indice de Entropia Generalizado (c=0.0)" /*     
    */ 8 "Indice de Entropia Generalizado (c=1.0)" /*     
    */ 9 "Indice de Entropia Generalizado (c=2.0)" 

    label values `indice_nombre' `indice_nombre'

    *noisily tabdisp `indice_nombre', cellvar(`indice_valor') concise format(%6.4f)

    return scalar gini = `gini'
    return scalar theil = `theil'
    return scalar cv = `cv'
    return scalar atk_e05 = `atk_e05'
    return scalar atk_e1 = `atk_e1'
    return scalar atk_e2 = `atk_e2'
    return scalar ge_0 = `ge_0'    
    return scalar ge_1 = `ge_1'    
    return scalar ge_2 = `ge_2'
   



*---------------------------------------------------------*
* Participacion de cada decil                             *
*---------------------------------------------------------*

    tempvar first share sum_ing ing_total decil
    cuantiles `1' [w=`wt'] `if', ncuantiles(10) generate(`decil')
    
    egen `sum_ing'=sum(`1'*`wt'), by(`decil')
    summ `1' [fw=`wt'] `if'
    scalar `ing_total'=r(sum)
    bysort `decil': gen `first'=`decil' if _n==_N
    gen `share'=(`sum_ing'/`ing_total')*100 if `first'!=.

    preserve
    keep if `first'!=.
    local i=1
    while `i'<=10 {
      *noisily display in yellow "share decil " %2.0f `i' " = " %7.4f `share'[`i']
      local dec_`i'=`share'[`i']
      local i=`i'+1
    }  
    restore

*---------------------------------------------------------*
* Cociente ingresos decil 10 / decil 1                    *
*---------------------------------------------------------*

    summ `1' [fw=`wt'] if `decil'==10
    local media_d10=r(mean)
    summ `1' [fw=`wt']  if `decil'==1
    local media_d1=r(mean)
    local ratd10d1=`media_d10'/`media_d1'
    *noisily display "y_d10/y_d1 = " `ratd10d1'

*---------------------------------------------------------*
* Cociente ingresos percentil 90 / percentil 10           *
*---------------------------------------------------------*

    tempvar percentil
    cuantiles `1' [w=`wt'] `if', ncuantiles(100) generate(`percentil')

    summ `1' [fw=`wt'] if `percentil'==90
    local media_p90=r(mean)
    summ `1' [fw=`wt']  if `percentil'==10
    local media_p10=r(mean)
    local ratp90p10= `media_p90'/`media_p10'
    *noisily display "y_p90/y_p10 = " `ratp90p10'

*---------------------------------------------------------*
* Cociente ingresos percentil 95 / percentil 5            *
*---------------------------------------------------------*

    summ `1' [fw=`wt'] if `percentil'==95
    local media_p95=r(mean)
    summ `1' [fw=`wt'] if `percentil'==5
    local media_p5=r(mean)

    local ratp95p5 = `media_p95'/`media_p5'
    *noisily display "y_p95/y_p5 = " `ratp95p5'


*---------------------------------------------------------*
* Cociente ingresos percentil 95 / percentil 50           *
*---------------------------------------------------------*

    summ `1' [fw=`wt']  if `percentil'==50
    local media_p50=r(mean)
    local ratp95p50 = `media_p95'/`media_p50'
    *noisily display "y_p95/y_p50 = " `ratp95p50'

*---------------------------------------------------------*
* Cociente ingresos percentil 50 / percentil 5           *
*---------------------------------------------------------*

    local ratp50p5 = `media_p50'/`media_p5'
    *noisily display "y_p50/y_p5 = " `ratp50p5'

*---------------------------------------------------------*
* Cociente ingresos percentil 95 / percentil 80           *
*---------------------------------------------------------*

    summ `1' [fw=`wt']  if `percentil'==80
    local media_p80=r(mean)
    local ratp95p80 = `media_p95'/`media_p80'
    *noisily display "y_p95/y_p80 = " `ratp95p80'


* GENERACION REPORTE ++++++++++++++++++++++++++++++++++++++++++++++++

    tempvar indice1_nombre indice1_valor indice2_nombre indice2_valor

    gen `indice1_valor'=.
    label variable `indice1_valor' "`1'"
    replace `indice1_valor' = `dec_1' if _n==1
    replace `indice1_valor' = `dec_2' if _n==2
    replace `indice1_valor' = `dec_3' if _n==3
    replace `indice1_valor' = `dec_4' if _n==4
    replace `indice1_valor' = `dec_5' if _n==5
    replace `indice1_valor' = `dec_6' if _n==6
    replace `indice1_valor' = `dec_7' if _n==7
    replace `indice1_valor' = `dec_8' if _n==8
    replace `indice1_valor' = `dec_9' if _n==9
    replace `indice1_valor' = `dec_10' if _n==10

    gen `indice1_nombre'=.
    label variable `indice1_nombre' "Participaciones en el Ingreso"
    replace `indice1_nombre'=_n if `indice1_valor' !=. 

    label define `indice1_nombre' /*
    */  1 "                     Decil  1" /*
    */  2 "                     Decil  2" /*
    */  3 "                     Decil  3" /*
    */  4 "                     Decil  4" /*
    */  5 "                     Decil  5" /*
    */  6 "                     Decil  6" /* 
    */  7 "                     Decil  7" /*     
    */  8 "                     Decil  8" /*
    */  9 "                     Decil  9" /*    
    */ 10 "                     Decil 10" 

    label values `indice1_nombre' `indice1_nombre'

    *noisily tabdisp `indice1_nombre', cellvar(`indice1_valor') concise format(%6.4f) 


    gen `indice2_valor'=.
    label variable `indice2_valor' "`1'"
    replace `indice2_valor' = `ratd10d1' if _n==1
    replace `indice2_valor' = `ratp90p10' if _n==2
    replace `indice2_valor' = `ratp95p5' if _n==3
    replace `indice2_valor' = `ratp95p50' if _n==4
    replace `indice2_valor' = `ratp50p5' if _n==5
    replace `indice2_valor' = `ratp95p80' if _n==6


    gen `indice2_nombre'=.
    label variable `indice2_nombre' "Cocientes de Ingresos"
    replace `indice2_nombre'=_n if `indice2_valor' !=. 

    label define `indice2_nombre' /*
    */ 1 "    Decil 10 / Decil 1     " /*    
    */ 2 "Percentil 90 / Percentil 10" /*    
    */ 3 "Percentil 95 / Percentil 5" /*    
    */ 4 "Percentil 95 / Percentil 50" /*    
    */ 5 "Percentil 50 / Percentil 5" /*    
    */ 6 "Percentil 95 / Percentil 80" 
    
    label values `indice2_nombre' `indice2_nombre'

    *noisily tabdisp `indice2_nombre', cellvar(`indice2_valor') concise format(%6.4f)  

    return scalar d1 = `dec_1'
    return scalar d2 = `dec_2'
    return scalar d3 = `dec_3'
    return scalar d4 = `dec_4'
    return scalar d5 = `dec_5'
    return scalar d6 = `dec_6'    
    return scalar d7 = `dec_7'
    return scalar d8 = `dec_8'
    return scalar d9 = `dec_9'
    return scalar d10 = `dec_10'
    return scalar ratd10d1 = `ratd10d1' 
    return scalar ratp90p10 = `ratp90p10'
    return scalar ratp95p5 = `ratp95p5'
    return scalar ratp95p50 = `ratp95p50'
    return scalar ratp50p5 = `ratp50p5'
    return scalar ratp95p80 = `ratp95p80'
    
  }

* REPORTE DE RESULTADOS +++++++++++++++++++++++++++++++++++++++++++++

*** tipo reporte=0 ***

  if `tipo_reporte'==0 {
      tabdisp `indice1_nombre', cellvar(`indice1_valor') concise format(%6.4f)   
      tabdisp `indice2_nombre', cellvar(`indice2_valor') concise format(%6.4f)  
      tabdisp `indice_nombre', cellvar(`indice_valor') concise format(%6.4f)
  }

*** tipo reporte=1 ***

  if `tipo_reporte'==1 {
      display as result _newline %6.4f `dec_1' _col(10) "Decil 1" /*
      */ _newline %6.4f `dec_2' _col(10) "Decil 2" /*
      */ _newline %6.4f `dec_3' _col(10) "Decil 3" /*    
      */ _newline %6.4f `dec_4' _col(10) "Decil 4" /*
      */ _newline %6.4f `dec_5' _col(10) "Decil 5" /*
      */ _newline %6.4f `dec_6' _col(10) "Decil 6" /*
      */ _newline %6.4f `dec_7' _col(10) "Decil 7" /*
      */ _newline %6.4f `dec_8' _col(10) "Decil 8" /*
      */ _newline %6.4f `dec_9' _col(10) "Decil 9" /*
      */ _newline %6.4f `dec_10' _col(10) "Decil 10" /*
      */ _newline(2) %6.4f `ratd10d1' _col(10) "Decil 10 / Decil 1" /* 
      */ _newline %6.4f `ratp90p10' _col(10) "Percentil 90 / Percentil 10" /*
      */ _newline %6.4f `ratp95p5' _col(10) "Percentil 95 / Percentil 5" /*
      */ _newline %6.4f `ratp95p50' _col(10) "Percentil 95 / Percentil 50" /*
      */ _newline %6.4f `ratp50p5' _col(10) "Percentil 50 / Percentil 5" /*
      */ _newline %6.4f `ratp95p80' _col(10) "Percentil 95 / Percentil 80" /*
      */ _newline(2) %6.4f `gini' _col(10) "Coeficiente de Gini" /*
      */ _newline %6.4f `theil' _col(10) "Indice de Theil" /*
      */ _newline %6.4f `cv' _col(10) "Coeficiente de Variacion" /*
      */ _newline %6.4f `atk_e05' _col(10) "Coeficiente de Atkinson (e=0.5)" /*
      */ _newline %6.4f `atk_e1' _col(10) "Coeficiente de Atkinson (e=1.0)" /*
      */ _newline %6.4f `atk_e2' _col(10) "Coeficiente de Atkinson (e=2.0)" /*
      */ _newline %6.4f `ge_0' _col(10) "Indice de Entropia Generalizado (c=0.0)" /*
      */ _newline %6.4f `ge_1' _col(10) "Indice de Entropia Generalizado (c=1.0)" /*
      */ _newline %6.4f `ge_2' _col(10) "Indice de Entropia Generalizado (c=2.0)"    
  }    

end



