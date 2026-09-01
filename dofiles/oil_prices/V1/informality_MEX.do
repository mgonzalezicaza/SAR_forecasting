
/*======================================================================
Project:			Macro-micro Simulations - Informality MEX
Institution:		World Bank - ELCPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		04/27/2022

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date: 	09/08/2023
======================================================================*/

*=======================================================================
* 	1 - Loading Non-agro data
*=======================================================================

preserve

use "${rootdatalib}\SEDLAC\MEX\MEX_${yearmex}_ENIGHNS\MEX_${yearmex}_ENIGHNS_v${master}_M\Data\Stata\noagro" , clear
	
egen ing_brutos=rowtotal(ventas_tri )
replace ing_brutos= ing_brutos*4
gen  RIF=   (ing_brutos<=2000000)  &  (reg_cont=="2" | reg_cont=="3")
gen  Act_emp=   (ing_brutos>2000000)  &  (reg_cont=="2" | reg_cont=="3")
keep folioviv foliohog numren id_trabajo RIF Act_emp
reshape wide RIF Act_emp, i(folioviv foliohog numren) j(id_trabajo) string
destring numren , replace force
tempfile a1
save `a1', replace
restore

merge m:1 folioviv foliohog numren using `a1', keep(1 3) nogen


*=======================================================================
* 2 - Informality
*=======================================================================

* Social benefits from work
gen       IMSSsub1=1    if 	medtrab_1_1=="1"  
replace   IMSSsub1=0    if 	IMSSsub1!=1
gen       ISSSTEsub1=1  if  	medtrab_2_1=="2"  |  medtrab_3_1=="3"  
replace   ISSSTEsub1=0  if  	ISSSTEsub1!=1
gen       PEMsub=1      if  	medtrab_4_1=="4"  | medtrab_4_2=="4" 
replace   PEMsub=0  	if  	PEMsub!=1
gen       Othersub1=1   if  	medtrab_5_1=="5"  | medtrab_6_1=="6"  
replace   Othersub1=0   if  	Othersub1!=1

* Other contribution to ISSSTE if worked for the government 
replace ISSSTEsub1=1     if  	Othersub1==1 & clas_emp_1==3

* Other contribution to IMSS if worked for the government 
replace IMSSsub1=1 if Othersub1==1 & (clas_emp_1==2 | clas_emp_1==4)
gen retirement=1   		 if  	pres_8_1==8 | pres_8_2==8
replace retirement=0   	 if 	retirement!=1

* Formal subordinated workers 
gen     formalsubor=1 if subor_1==1 & IMSSsub1==1 & clas_emp_1!=3 
replace formalsubor=1 if pres_8_1==8  & subor_1==1   & clas_emp_1!=3 

* Additional definitions 
replace formalsubor=1 if tipocontr_1==2 & subor_1==1
replace formalsubor=1 if pres_4_1==4 & subor_1==1 & clas_emp_1!=3 
replace formalsubor=1 if pres_3_1==3 & subor_1==1 & clas_emp_1!=3 
replace formalsubor=1 if pres_2_1==2 & subor_1==1 & clas_emp_1!=3 
replace formalsubor=0 if formalsubor!=1

local suborincomes ingresoP001 ingresoP002 ingresoP003 ingresoP004 ingresoP005 ingresoP006 ingresoP007 ingresoP008 ingresoP009  ingresoP022
egen pem_aux=rowtotal(`suborincomes')
gen PEMsubII=  pem_aux!=0 & PEMsub==1

* Federal Workers 
gen federalsubor=1 if (subor_1==1) & (ISSSTEsub1==1 | clas_emp_1==3) & formalsubor!=1 & PEMsubII!=1
replace federalsubor=0 if   federalsubor!=1

* Informal
gen informalsubor=1 if subor_1==1 & formalsubor==0 & PEMsubII==0 & federalsubor !=1 
replace informalsubor=0 if informalsubor!=1

* Self-employed workers 
gen selfemployed=1  if  (indep_1==1)
replace selfemployed=0 if selfemployed!=1

* Voluntary criteria  
gen volretirement = (segvol_1=="1")
egen inst=rowtotal(inst_*), m
gen informal_voluntary=1 if informalsubor==1 &  ((inst!=.) | volretirement==1) & segsoc=="1" 
replace  informal_voluntary=0 if informal_voluntary!=1 
gen selfemploy_voluntary=1 if selfemployed==1 & (( RIF1==1| RIF2==1) | (Act_emp1==1 | Act_emp2==1))
replace  selfemploy_voluntary=0 if selfemploy_voluntary!=1 
gen voluntary=1 if selfemploy_voluntary==1 | informal_voluntary==1
replace voluntary=0 if voluntary!=1

gen informal = (informalsubor==1 | selfemployed==1) & (voluntary==0) if sample == 1

*=======================================================================
*                                     END
*=======================================================================
