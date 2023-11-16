********************************************************************
********************************************************************
********************************************************************
* IV --  BASELINE  
********************************************************************
********************************************************************
********************************************************************


********************************************************************
********************************************************************
********************************************************************
* READ DATA
********************************************************************
********************************************************************
********************************************************************
clear
u $main/data2/data_3
drop if zd ==.
drop if year  ==.
drop if bea ==.

gegen total = sum(number), by(inventor)

* INCLUDE THE FOLLOWING 6 LINES IF YOU DON'T WANT INTERPOLATED DATA
** MW: I skipped interpolation
/* replace bea    =. if inter_bea   ==1
replace zd     =. if inter_zd    ==1
replace class  =. if inter_class ==1
replace bea    =. if inter_bea2  ==1
replace zd     =. if inter_zd2   ==1
replace class  =. if inter_class2==1 */



* CLUSTER SIZE 
g x   = log(Den_bea_zd    )
/* gsort inventor year
by inventor : g  x_m1 = x[_n-1]
by inventor : g  x_m2 = x[_n-2]
by inventor : g  x_m3 = x[_n-3]
by inventor : g  x_m4 = x[_n-4]
by inventor : g  x_m5 = x[_n-5]
by inventor : g  x_p1 = x[_n+1]
by inventor : g  x_p2 = x[_n+2]
by inventor : g  x_p3 = x[_n+3]
by inventor : g  x_p4 = x[_n+4]
by inventor : g  x_p5 = x[_n+5] */
** MW: not used



gegen org_new2 = group(org_id) if org_id ~= ""



********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************

* NUMBER OF PATENTS IN A YEAR
g y = log(number)

* CITATIONS
* To avoid dropping the 0's, I add 0.00001
/* g y2 = log(citations+0.00001)
g y3 = log( (citations+0.00001) / number)  */
** MW: not used

* SPECIALIZATION
*g y4 = 1-general

* NUMBER OF FIRMS
/* g x3  = log(Den_bea_zdB)  */
** MW: not used

***********************
***********************
* DEFINE STAR INVENTORS
***********************
***********************
keep if total  >=3.25



********************************************************************
********************************************************************
********************************************************************
* NEW VARIABLES
********************************************************************
********************************************************************
********************************************************************
gegen cluster1               = group(bea zd)
gegen cluster10       = group(bea )
gegen cluster_zd_year        = group(zd year)
gegen cluster_class_year     = group(class year)
gegen cluster_bea_year       = group(bea year)
gegen cluster_bea_class      = group(bea class)

/* gegen cluster0               = group(bea zd year)
gegen cluster2               = group(bea )
gegen cluster_bea_zd_year    = group(bea zd year)
gegen cluster_bea_class_year = group(bea class year)
gegen cluster_zd_year        = group(zd year)
gegen cluster_class_year     = group(class year)
gegen org_new                = group(org_id)
gegen cluster_org_year       = group(org_new year)
gegen org_size               = count(inventor), by(org_new year)
gegen lab_size              = count(inventor), by(org_new year bea) */
** MW: not used


********************************************************************
********************************************************************
********************************************************************
* REGRESSIONS
********************************************************************
********************************************************************
********************************************************************
keep if y~=. & zd ~=. & class ~=. & year ~=. & inventor ~=. & cluster1 ~=. & bea ~=.
/* summ y y2 y3  x 
summ number, detail
summ x Den_bea_zd , detail
tab zd */


***************************************
*MODELS IN DIFFERENCES and IV
***************************************
/* preserve */

** MW: 
preserve
collapse total, by(inventor)
su total,d
* average lifetime patents: 7.7
restore

drop if org_id == ""
gsort org_new2 bea year zd
merge m:1   bea year zd org_new2 using  $main/data2/iv_data_new
/* drop _merge */
/* g IV = iv8 */
** MW renamed in iv_new_mw.do

gsort inventor year
by inventor: g Dy    = y - y[_n-1]
by inventor: g Dx    = x - x[_n-1]
by inventor: g Dyear = year - year[_n-1]
/* by inventor: g Dbea  = 1 if bea_code == bea_code[_n-1] 
by inventor: g Dy_2    = y - y[_n-2]
by inventor: g Dx_2    = x - x[_n-2]
by inventor: g Dyear_2 = year - year[_n-2]
by inventor: g Dbea_2  = 1 if bea_code == bea_code[_n-2]
by inventor: g Dx_m1 = x[_n-1] - x[_n-2]
by inventor: g Dx_m2 = x[_n-2] - x[_n-3]
by inventor: g Dx_m3 = x[_n-3] - x[_n-2] */
** MW: not used

* Models in first differences should only include observations in contiguous years
keep if Dyear ==1
keep if Dy ~=. & Dx ~=. & IV_orig ~=.
** MW: my IV_orig is the original IV
/* keep if Dy ~=. & Dx ~=. & IV ~=. */

** MW: compare sample with consecutive observations (Dyear==1) to Table 3 sample
preserve
collapse total, by(inventor)
su total,d
** MW: 
* average lifetime patents: 8.2
* sample with consecutive observations has slightly more productive inventors (8.2 vs 7.7 lifetime patents)
restore


* MODELS WITH LAGS: THEY CAN BE COMPARED TO f.e. MODELS BUT CAN'T USE IV's
/* eststo: reghdfe  Dy Dx Dx_m1 Dx_m2 Dx_m3 ,        absorb(year  )  vce(cluster cluster10)
lincom Dx + Dx_m1 + Dx_m2 + Dx_m3
eststo: reghdfe  Dy Dx Dx_m1 Dx_m2 Dx_m3 ,            absorb(year zd )  vce(cluster cluster10)
lincom Dx + Dx_m1 + Dx_m2 + Dx_m3
eststo: reghdfe  Dy Dx Dx_m1 Dx_m2 Dx_m3 ,            absorb(year zd class )  vce(cluster cluster10)
lincom Dx + Dx_m1 + Dx_m2 + Dx_m3
eststo: reghdfe  Dy Dx Dx_m1 Dx_m2 Dx_m3 ,            absorb(year zd class org_new)  vce(cluster cluster10)
lincom Dx + Dx_m1 + Dx_m2 + Dx_m3
eststo: reghdfe  Dy Dx Dx_m1 Dx_m2 Dx_m3 ,            absorb(year zd class org_new cluster_zd_year )  vce(cluster cluster10)
lincom Dx + Dx_m1 + Dx_m2 + Dx_m3
eststo: reghdfe  Dy Dx Dx_m1 Dx_m2 Dx_m3 ,            absorb(year zd class org_new cluster_zd_year cluster_class_year )  vce(cluster cluster10)
lincom Dx + Dx_m1 + Dx_m2 + Dx_m3
esttab using tables11/table29.tex, se  compress replace star(* 0.10 ** 0.05 *** 0.01)
esttab using tables11/table29, se  compress replace star(* 0.10 ** 0.05 *** 0.01)
eststo clear */

lab var Dy ""
lab var Dx "$\Delta$ log size"
lab var IV "IV"
lab var IV_orig "IV"
lab var IV_fix "IV"

* OLS
/* qui reghdfe  Dy Dx, absorb(year                  )  vce(cluster cluster10)
eststo ols1
qui reghdfe  Dy Dx, absorb(year  zd              )  vce(cluster cluster10)
eststo ols2
qui reghdfe  Dy Dx, absorb(year  zd class        )  vce(cluster cluster10)
eststo ols3
qui reghdfe  Dy Dx, absorb(year  zd class org_new)  vce(cluster cluster10)
eststo ols4
qui reghdfe  Dy Dx, absorb(year  zd class cluster_zd_year                    org_new)  vce(cluster cluster10)
eststo ols5
qui reghdfe  Dy Dx, absorb(year  zd class cluster_zd_year cluster_class_year org_new)  vce(cluster cluster10)
eststo ols6
esttab ols*, se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f)
esttab ols* using "$tables/t5_ols.tex", se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f) */

est clear
*-------
* 2SLS: original instrument
qui ivreghdfe Dy (Dx =IV_orig), absorb(year                   ) cluster(cluster10) 
eststo oiv1
qui ivreghdfe Dy (Dx =IV_orig), absorb(year   zd              ) cluster(cluster10)
eststo oiv2
qui ivreghdfe Dy (Dx =IV_orig), absorb(year   zd class        ) cluster(cluster10)
eststo oiv3
qui ivreghdfe Dy (Dx =IV_orig), absorb(year zd class org_new) cluster(cluster10)
eststo oiv4
qui ivreghdfe Dy (Dx =IV_orig), absorb(year zd class cluster_zd_year org_new ) cluster(cluster10)
eststo oiv5
qui ivreghdfe Dy (Dx =IV_orig), absorb(year zd class cluster_zd_year cluster_class_year org_new) cluster(cluster10)
eststo oiv6
esttab oiv*, se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f)
esttab oiv* using "$tables/t5_iv_orig.tex", se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f)
esttab oiv* using "$tables/t5_iv_orig_nostar.tex", se label compress replace nomtitle nocons b(%9.4f) nostar

* First Stage: original instrument
qui reghdfe Dx IV_orig, absorb(year                   ) cluster(cluster10) 
eststo ofs1
estadd scalar fstat e(F)
qui reghdfe Dx IV_orig, absorb(year   zd              ) cluster(cluster10)
eststo ofs2
estadd scalar fstat e(F)
qui reghdfe Dx IV_orig, absorb(year   zd class        ) cluster(cluster10)
eststo ofs3
estadd scalar fstat e(F)
qui reghdfe Dx IV_orig, absorb(year zd class org_new) cluster(cluster10)
eststo ofs4
estadd scalar fstat e(F)
qui reghdfe Dx IV_orig, absorb(year zd class cluster_zd_year org_new ) cluster(cluster10)
eststo ofs5
estadd scalar fstat e(F)
qui reghdfe Dx IV_orig, absorb(year zd class cluster_zd_year cluster_class_year org_new) cluster(cluster10)
eststo ofs6
estadd scalar fstat e(F)
esttab ofs*, se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f) scalars(N "fstat F-statistic") sfmt(%9.2fc)
esttab ofs* using "$tables/t5_fs_orig.tex", se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f) scalars(N "fstat F-statistic") sfmt(%9.2fc)
esttab ofs* using "$tables/t5_fs_orig_nostar.tex", se label compress replace nomtitle nocons b(%9.4f) scalars(N "fstat F-statistic") sfmt(%9.2fc) nostar

*-------
* 2SLS: corrected instrument
qui ivreghdfe Dy (Dx =IV_fix), absorb(year                   ) cluster(cluster10) 
eststo niv1
qui ivreghdfe Dy (Dx =IV_fix), absorb(year   zd              ) cluster(cluster10)
eststo niv2
qui ivreghdfe Dy (Dx =IV_fix), absorb(year   zd class        ) cluster(cluster10)
eststo niv3
qui ivreghdfe Dy (Dx =IV_fix), absorb(year zd class org_new) cluster(cluster10)
eststo niv4
qui ivreghdfe Dy (Dx =IV_fix), absorb(year zd class cluster_zd_year org_new ) cluster(cluster10)
eststo niv5
qui ivreghdfe Dy (Dx =IV_fix), absorb(year zd class cluster_zd_year cluster_class_year org_new) cluster(cluster10)
eststo niv6
esttab niv*, se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f)
esttab niv* using "$tables/t5_iv_fix.tex", se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f)
esttab niv* using "$tables/t5_iv_fix_nostar.tex", se label compress replace nomtitle nocons b(%9.4f) nostar

* First Stage: corrected instrument
qui reghdfe Dx IV_fix, absorb(year                 ) vce(cluster cluster10)
eststo nfs1
estadd scalar fstat e(F)
estadd local year "Yes"
qui reghdfe Dx IV_fix, absorb(year zd              ) vce(cluster cluster10)
eststo nfs2
estadd scalar fstat e(F)
estadd local year "Yes"
estadd local field "Yes"
qui reghdfe Dx IV_fix, absorb(year zd class        ) vce(cluster cluster10)
eststo nfs3
estadd scalar fstat e(F)
estadd local year "Yes"
estadd local field "Yes"
estadd local class "Yes"
qui reghdfe Dx IV_fix, absorb(year zd class org_new) vce(cluster cluster10)
eststo nfs4
estadd scalar fstat e(F)
estadd local year "Yes"
estadd local field "Yes"
estadd local class "Yes"
estadd local firm "Yes"
qui reghdfe Dx IV_fix, absorb(year zd class cluster_zd_year org_new) vce(cluster cluster10)
eststo nfs5
estadd scalar fstat e(F)
estadd local year "Yes"
estadd local field "Yes"
estadd local class "Yes"
estadd local firm "Yes"
estadd local fieldyear "Yes"
qui reghdfe Dx IV_fix, absorb(year zd class cluster_zd_year cluster_class_year org_new) vce(cluster cluster10)
eststo nfs6
estadd scalar fstat e(F)
estadd local year "Yes"
estadd local field "Yes"
estadd local class "Yes"
estadd local firm "Yes"
estadd local fieldyear "Yes"
estadd local classyear "Yes"
esttab nfs*, se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f) scalars(N "fstat F-statistic" "year Year" "field Field" "class Class" "firm Firm" "fieldyear Field $\times$ year" "classyear Class $\times$ year") sfmt(%9.2fc)
esttab nfs* using "$tables/t5_fs_fix.tex", se label compress replace star(* 0.10 ** 0.05 *** 0.01) nomtitle nocons b(%9.4f) scalars(N "fstat F-statistic" "year Year" "field Field" "class Class" "firm Firm" "fieldyear Field $\times$ year" "classyear Class $\times$ year") sfmt(%9.2fc)
esttab nfs* using "$tables/t5_fs_fix_nostar.tex", se label compress replace nomtitle nocons b(%9.4f) scalars(N "fstat F-statistic" "year Year" "field Field" "class Class" "firm Firm" "fieldyear Field $\times$ year" "classyear Class $\times$ year") sfmt(%9.2fc) nostar

*** combine tables
*include "https://raw.githubusercontent.com/steveofconnell/PanelCombine/master/PanelCombine.do"
panelcombine, use($tables/t5_iv_orig.tex $tables/t5_fs_orig.tex $tables/t5_iv_fix.tex $tables/t5_fs_fix.tex)  columncount(6) paneltitles("2SLS: original" "First stage: original" "2SLS: corrected" "First stage: corrected") save($tables/t5_combined.tex)

panelcombine, use($tables/t5_iv_orig_nostar.tex $tables/t5_fs_orig_nostar.tex $tables/t5_iv_fix_nostar.tex $tables/t5_fs_fix_nostar.tex)  columncount(6) paneltitles("2SLS (original)" "First stage (original)" "2SLS (corrected)" "First stage (corrected)") save($tables/t5_combined_nostar.tex)
* put FEs on last panel
* manually add one horizontal line to separate the FEs


*---

* EXOGENEITY TESTS
* XXX FSTAT
/* reghdfe  Dy Dx v1, absorb(year                  )  vce(cluster cluster10)
test v1
reghdfe  Dy Dx v2, absorb(year  zd              )  vce(cluster cluster10)
test v2
reghdfe  Dy Dx v3, absorb(year  zd class        )  vce(cluster cluster10)
test v3
reghdfe  Dy Dx v4, absorb(year  zd class org_new)  vce(cluster cluster10)
test v4
reghdfe  Dy Dx v5, absorb(year  zd class cluster_zd_year                    org_new)  vce(cluster cluster10)
test v5
reghdfe  Dy Dx v6, absorb(year  zd class cluster_zd_year cluster_class_year org_new)  vce(cluster cluster10)
test v6
drop v1 v2 v3 v4 v5 v6


restore */