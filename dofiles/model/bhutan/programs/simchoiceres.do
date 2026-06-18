*! Simulated choice residuals : v.1.2 Stas Kolenikov
capture program drop simchoiceres
capture program define simchoiceres
   version 9

   // only supports -mlogit-
   if "`e(cmd)'" ~= "mlogit" error 301

   // # of categories == # of residuals to be created
   local K=e(k_out)

   syntax newvarlist(min=`K' max=`K') [if] [in], [seed(str) TOTalutility ///
           GReatest(str) NEXTGReatest(str) ]

   if "`nextgreatest'"!="" & ("`greatest'"=="" | "`totalutility'"=="") {
      di as err "nextgreatest() option requires greatest() and totalutility options"
      exit 198
   }
   if "`greatest'" != "" confirm new variable `greatest'
   if "`nextgreatest'" != "" confirm new variable `nextgreatest'

   // check that all variables in the `newvarlist' are unique -- I thought Stata would do it
   forvalues k=1/`K' {
      confirm new variable `: word `k' of `varlist''
   }

   if "`seed'" != "" set seed `seed'

   marksample touse, novar

   quietly {

   // get the list of possible outcomes
   forvalues k=1/`K' {
      local out`k' = el( e(out), 1, `k')
   }

   // create the testbed variables
   forvalues k=1/`K' {
      tempvar res`k' chosen`k' prob`k' util`k' Uchosen`k'

      // future residual
      gen double `res`k'' = .

      // dummy for chosen `k'-th category
      gen byte `chosen`k'' = (`e(depvar)'== `out`k'') if `touse' & e(sample)

      // probability of the `k'-th outcome
      predict `prob`k'' if `touse' , pr outcome(`out`k'')

      // utility of the `k'-th outcome
      predict `util`k'' if `touse' , xb outcome(`out`k'')
   }

   // in e(sample), generate GEV shifted by -ln(Prob) for the chosen alternative
   forvalues k=1/`K' {
      sum `prob`k''
      count if `touse' & e(sample) & `chosen`k''
      replace `res`k'' = -ln(`prob`k'') - ln( -ln( uniform() ) ) if `touse' & e(sample) & `chosen`k''
      // `chosen`k'' would suffice, actually
   }

   // generalize the value of the chosen residual for the chosen alternative
   tempvar reschosen
   gen double `reschosen' = .
   forvalues k=1/`K' {
      replace `reschosen' = `res`k'' if `touse' & e(sample) & `chosen`k''
   }

   // compute fixed part of utility of the chosen alternative
   tempvar Vchosen
   gen double `Vchosen' = .
   forvalues k=1/`K' {
      replace `Vchosen' = `util`k'' if `touse' & e(sample) & `chosen`k''
      // `chosen`k'' would suffice, actually
   }

   // compute delta fixed part of utility wrt to the chosen one
   forvalues k=1/`K' {
      tempvar V_against`k'
      gen double `V_against`k'' = `Vchosen' - `util`k'' if `touse' & e(sample)
   }

   // in e(sample), generate GEV shifted down for the non-chosen alternative
   forvalues k=1/`K' {
      replace `res`k'' = -ln( exp( -`V_against`k'' - `reschosen') - ln(uniform()) ) if `touse' & e(sample) & !`chosen`k''
      // !`chosen`k'' would suffice, actually
   }

   // outside of e(sample), generate the basic extreme value things
   forvalues k=1/`K' {
      replace `res`k'' = - ln( -ln( uniform() ) ) if `touse' & !e(sample)
   }

   // assert that the highest utility is indeed the chosen alternative
   forvalues k=1/`K' {
      assert (`util`k'' + `res`k'' <= `Vchosen' + `reschosen') | !(`touse' & e(sample))
   }

   // match the temp variables back to the variables to be generated
   nobreak {
     forvalues k=1/`K' {
        if "`totalutility'" == "" {
          // fill in with simulated residuals
          cap gen `: word `k' of `typlist'' `: word `k' of `varlist'' = `res`k'' if `touse'
		  CleanUp _rc
          lab var `: word `k' of `varlist'' "Simulated residual for alternative `out`k''"
        }
        else {
          // fill in with total utility
          cap gen `: word `k' of `typlist'' `: word `k' of `varlist'' = `util`k''+`res`k'' if `touse'
          CleanUp _rc
          lab var `: word `k' of `varlist'' "Simulated utility for alternative `out`k''"
        }
        * note `: word `k' of `varlist'' : "The original command was: `e(cmdline)'"
     }
     if "`greatest'"!="" {
        cap noi qui gen `greatest' = `Vchosen' + `reschosen'
        label var `greatest' "Simulated utility of the chosen outcome"
     }
     if "`nextgreatest'"!="" {
        // way more work ahead to create the second largest utility
        // only comes here when all the total utilities are created
        forvalues k=1/`K' {
           drop `util`k''
           qui gen double `util`k'' = `: word `k' of `varlist'' if `touse' & !`chosen`k''
           local sortedlist `sortedlist' `util`k''
        }
        cap noi qui egen `nextgreatest' = rowmax( `sortedlist' )
        CleanUp _rc
        label var `nextgreatest' "Simulated utility of the second best outcome"
     }
   } // end of nobreak

   } // end of quietly

end

capture program drop CleanUp
capture program define CleanUp
   syntax anything
   // actually, that's the return code

   if `anything' {
      // problem generating new variables
      forvalues k=1/`K' {
         cap drop `: word `k' of `varlist''
      }
      cap drop `greatest'
      cap drop `nextgreatest'
      exit `anything'
   }
   else {
      // do nothing, everything's fine!
   }

end

exit

History:
v.1.0 -- basic functionality
v.1.1 -- bug report, older version incompatibility -- used e(k_eq), should've used e(k_out) -- fixed
v.1.2 -- debug option;
         better management of memory problems;
         fixed the bug with outcomes
         added greatest and nextgreatest options
