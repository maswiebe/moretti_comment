clear
set sortseed 1
version 13.1
* set processors 1
    * uncomment if using stata MP
* sorting algorithm depends on sortseed, version, and processors
    * https://www.statalist.org/forums/forum/general-stata-discussion/general/1611662-setting-version-seed-and-sortseed-not-sufficient-for-reproducibility

local N 500
* store coefficient and t-statistic
matrix bt = J(`N',2,.)

forval i = 1/`N' {
    do "$root/code/iv_reproducible.do"
  
    u $main/data2/data_3, clear
    gegen org_new2 = group(org_id) if org_id ~= ""
    * generate new dataset where the IV is defined using a random ordering of cities
        * taking first-difference across randomly ordered cities

    gegen total = sum(number), by(inventor)
    drop if org_id == ""
    * need to drop missing firm obs after generating total (not before), otherwise merge is different
    keep if total  >=3.25

    g x   = log(Den_bea_zd    )
    g y = log(number)

    merge m:1   bea year zd org_new2 using  $main/data2/iv_data_new_reprod

    gsort inventor year
    by inventor: g Dy    = y - y[_n-1]
    by inventor: g Dx    = x - x[_n-1]
    by inventor: g Dyear = year - year[_n-1]
    keep if Dyear ==1
    keep if Dy ~=. & Dx ~=. & iv8_orig ~=.

    qui ivreghdfe Dy (Dx=iv8_orig), absorb(year zd class zd2#year class#year org_new) cluster(bea)

    matrix bt[`i',1] = _b[Dx]
    matrix bt[`i',2] = _b[Dx]/_se[Dx]
    di "Iteration: `i'"
}

svmat bt
keep bt*
save "$figures/reprod_output.dta", replace

set scheme plotplainblind

tw (hist bt1, xaxis(1) freq color(sea%30) xline(0.0491, lcolor(sea) axis(1) lpattern("_"))) (hist bt2, xaxis(2) freq color(vermillion%30) xline(3.41, lcolor(vermillion) axis(2) lpattern("-"))), legend(order(1 "Coefficient" 2 "T-statistic") pos(6) rows(1)) xtitle("Coefficient", axis(1)) xtitle("T-statistic", axis(2)) 
graph export "$figures/reprod_bt.png", replace
graph export "$figures/reprod_bt.pdf", replace