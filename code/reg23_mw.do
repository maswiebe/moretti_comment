* MW: my changes are tagged with comments starting with "** MW"

********************************************************************
********************************************************************
********************************************************************
* MOVERS - LEADS AND LAGS
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
drop if year  ==.
drop if zd ==.
drop if bea ==.

gegen total = sum(number), by(inventor)
keep if total  >=3.25

* INCLUDE THE FOLLOWING 6 LINES IF YOU DON'T WANT INTERPOLATED DATA
** MW: I skipped interpolation
/* replace bea    =. if inter_bea   ==1
replace zd     =. if inter_zd    ==1
replace class  =. if inter_class ==1
replace bea    =. if inter_bea2  ==1
replace zd     =. if inter_zd2   ==1
replace class  =. if inter_class2==1 */


* CLUSTER SIZE
g y = log(number)
g x   = log(Den_bea_zd    )
gegen cluster1               = group(bea zd)
keep if y~=. & zd ~=. & class ~=. & year ~=. & inventor ~=. & cluster1 ~=. & bea ~=.

** MW: not used
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


gegen org_new2 = group(org_id) if org_id ~= ""



********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************

* NUMBER OF PATENTS IN A YEAR
/* g y = log(number) */

* CITATIONS
* To avoid dropping the 0's, I add 0.00001
/* g y2 = log(citations+0.00001)
g y3 = log( (citations+0.00001) / number) */

* SPECIALIZATION
*g y4 = 1-general

* NUMBER OF FIRMS
/* g x3  = log(Den_bea_zdB) */


***********************
***********************
* DEFINE STAR INVENTORS
***********************
***********************
/* keep if total  >=3.25 */



********************************************************************
********************************************************************
********************************************************************
* NEW VARIABLES
********************************************************************
********************************************************************
********************************************************************

**MW: not used
/* gegen cluster1               = group(bea zd) */
/* gegen cluster0               = group(bea zd year) */
/* gegen cluster2               = group(bea ) */
gegen cluster_bea_year       = group(bea year)
/* gegen cluster_bea_zd_year    = group(bea zd year) */
/* gegen cluster_bea_class_year = group(bea class year) */
gegen cluster_zd_year        = group(zd year)
gegen cluster_bea_class      = group(bea class)
gegen cluster_class_year     = group(class year)
gegen org_new                = group(org_id)
/* gegen cluster_org_year       = group(org_new year)
gegen org_size               = count(inventor), by(org_new year)
gegen lab_size              = count(inventor), by(org_new year bea) */



********************************************************************
********************************************************************
********************************************************************
* REGRESSIONS
********************************************************************
********************************************************************
********************************************************************
/* keep if y~=. & zd ~=. & class ~=. & year ~=. & inventor ~=. & cluster1 ~=. & bea ~=. */
/* summ y y2 y3  x
summ number, detail
summ x Den_bea_zd , detail
tab zd */


************************************************************************
************************************************************************

*preserve

* Mover dummy
rename bea_code bea
gsort inventor year
by inventor : g  bea_m1 = bea[_n-1]
by inventor : g  year_m1 = year[_n-1]
g       move = 0
replace move = 1 if bea ~= bea_m1 & bea ~=. & bea_m1 ~=.



* Indicator for cases where an inventor is in a different city  relative
* to last year she was observed, and last year observed is more than 1 year ago
* In these case, the exact time of the move in unknown
g dyear = year - year_m1
g large_gap = 1 if move ==1 & dyear >1
* Assign this dummy to all years when an inventor is observed
gegen gapp = max(large_gap), by(inventor)
drop large_gap dyear

g move_year = year if move ==1
* Total number of moves by inventor
gegen nn1 = total(move), by(inventor)


* move_year1 is year of first observed move
* It is defined only for those who move once
gegen move_year1 = min(move_year),  by(inventor)
*drop move_year
replace move_year1 = . if nn>1
* Time since move
g tt = year - move_year1

* Keep only movers, when time of the move is exactly identified
* For coding simplicity, I keep those who move once
keep if nn1 ==1 
drop if gapp ==1


* Mean x in the 5 years before the move and the five years after the move
gegen tmp_mm = mean(x) if tt >= -5 & tt <=-1, by(inventor)
gegen tmp_pp = mean(x) if tt >= 1  & tt <= 5, by(inventor)

* tmp_mm and tmp_pp are constants, but they are defined only in the 5 years 
* before the move and the 5 years after the move, repsctively. To run the regression, 
* I assign tmp_mm and tmp_pp to an entire inventor life so that they are not missing
gegen tmp_m = max(tmp_mm),  by(inventor)
gegen tmp_p = max(tmp_pp),  by(inventor)
drop tmp_pp tmp_mm


* Now I interact the average x in the years before and after the move with
* indicators for numbeer of years since the move 
g m1 = (tt==-1)
g m2 = (tt==-2)
g m3 = (tt==-3)
g m4 = (tt==-4)
g m5 = (tt==-5)

g p1 = (tt==1)
g p2 = (tt==2)
g p3 = (tt==3)
g p4 = (tt==4)
g p5 = (tt==5)

/* drop x_p* x_m* */
g  x_m1 = tmp_m*m1
g  x_m2 = tmp_m*m2
g  x_m3 = tmp_m*m3
g  x_m4 = tmp_m*m4
g  x_m5 = tmp_m*m5
g  x_p1 = tmp_p*p1
g  x_p2 = tmp_p*p2
g  x_p3 = tmp_p*p3
g  x_p4 = tmp_p*p4
g  x_p5 = tmp_p*p5

*** MW:
* t=0 indicator
g p0 = (tt==0)
g x_p0 = tmp_p*p0

set scheme plotplainblind

* Stata error on linux: only first subscript renders correctly
* https://www.statalist.org/forums/forum/general-stata-discussion/general/1568841-how-to-fix-subscripts-in-stata-graphs
*lab var x_m5 "{&beta}{subscript:-5}"
* AER changed from unicode to latex, see his code below

lab var x_m5 "{&beta}(-5)"
lab var x_m4 "{&beta}(-4)"
lab var x_m3 "{&beta}(-3)"
lab var x_m2 "{&beta}(-2)"
lab var x_m1 "{&beta}(-1)"
lab var x_p0 "{&beta}(0)"
lab var x_p1 "{&beta}(1)"
lab var x_p2 "{&beta}(2)"
lab var x_p3 "{&beta}(3)"
lab var x_p4 "{&beta}(4)"
lab var x_p5 "{&beta}(5)"
lab var x "{&beta}(0)"

* original regression
reghdfe y x_p5 x_p4 x_p3 x_p2 x_p1 x x_m1 x_m2 x_m3 x_m4 x_m5 ,absorb(year bea zd class cluster1 cluster_bea_class cluster_zd_year cluster_class_year inventor cluster_bea_year org_new  ) vce(cluster cluster1)  
est sto m1
coefplot, drop(_cons) vert order(x_m5 x_m4 x_m3 x_m2 x_m1 x x_p1 x_p2 x_p3 x_p4 x_p5)
gen x_orig = x
gen esample_orig = e(sample)
distinct inventor if esample_orig
* 3k inventors in the event study

* fixed regression
replace x = x_p0
* need to use same variable to plot side-by-side
reghdfe y x_p5 x_p4 x_p3 x_p2 x_p1 x x_m1 x_m2 x_m3 x_m4 x_m5 ,absorb(year bea zd class cluster1 cluster_bea_class cluster_zd_year cluster_class_year inventor cluster_bea_year org_new  ) vce(cluster cluster1)  
est sto m2
coefplot, drop(_cons) vert order(x_m5 x_m4 x_m3 x_m2 x_m1 x x_p1 x_p2 x_p3 x_p4 x_p5)

* combined
coefplot (m1, label(Original)) (m2, label(Corrected)), drop(_cons) vert order(x_m5 x_m4 x_m3 x_m2 x_m1 x x_p1 x_p2 x_p3 x_p4 x_p5) legend(pos(6) rows(1))
graph export "$figures/es_dis.pdf", replace
graph export "$figures/es_dis.png", replace

*** 
gegen esample_count = count(inventor_id) if esample_orig, by(inventor_id)
su esample_count
* estimation sample includes inventors with 2-24 observations

*bro inventor year x_m5 x_m4 x_m3 x_m2 x_m1 x x_p1 x_p2 x_p3 x_p4 x_p5 tt move_year esample_count if esample_orig
* no restriction on time gap between observations

* do any inventors contribute to the regression but have 0s for all time indicators?
egen xcount_temp = rowtotal(x_m5 x_m4 x_m3 x_m2 x_m1 x_p1 x_p2 x_p3 x_p4 x_p5)
gegen xcount = total(xcount_temp), by(inventor)
su xcount if esample_orig ,d
* no


*--------------------------------
* mixing up leads and lags: below, b1 is the left-most coefficient, but Moretti uses x_p5 (t+5); and b11 is the rightmost coefficient, but Moretti uses x_m5 (t-5)

/* * Regression
eststo: reghdfe y x_p5 x_p4 x_p3 x_p2 x_p1 x x_m1 x_m2 x_m3 x_m4 x_m5 ,absorb(year bea zd class cluster1 cluster_bea_class cluster_zd_year cluster_class_year inventor cluster_bea_year org_new  ) vce(cluster cluster1)  
eststo clear

g b1 = _b[x_p5]
g b2 = _b[x_p4]
g b3 = _b[x_p3]
g b4 = _b[x_p2]
g b5 = _b[x_p1]
g b6 = _b[x]
g b7 = _b[x_m1]
g b8 = _b[x_m2]
g b9 = _b[x_m3]
g b10= _b[x_m4]
g b11= _b[x_m5]
g se1  =_se[x_p5]
g se2  =_se[x_p4]
g se3  =_se[x_p3]
g se4  =_se[x_p2]
g se5  =_se[x_p1]
g se6  =_se[x]
g se7  =_se[x_m1]
g se8  =_se[x_m2]
g se9  =_se[x_m3]
g se10 =_se[x_m4]
g se11 =_se[x_m5]


lincom x_p5 
g bb1  = r(estimate)
g sse1 = r(se)
lincom x_p5 + x_p4 
g bb2  = r(estimate)
g sse2 = r(se)
lincom x_p5 + x_p4 + x_p3 
g bb3  = r(estimate)
g sse3 = r(se)
lincom  x_p5 + x_p4 + x_p3 + x_p2 
g bb4  = r(estimate)
g sse4 = r(se)
lincom x_p5 + x_p4 + x_p3 + x_p2 + x_p1 
g bb5 = r(estimate)
g sse5 = r(se)
lincom x_p5 + x_p4 + x_p3 + x_p2 + x_p1 + x 
g bb6  = r(estimate)
g sse6 = r(se)
lincom x_p5 + x_p4 + x_p3 + x_p2 + x_p1 + x + x_m1 
g bb7  = r(estimate)
g sse7 = r(se)
lincom x_p5 + x_p4 + x_p3 + x_p2 + x_p1 + x + x_m1 + x_m2 
g bb8  = r(estimate)
g sse8 = r(se)
lincom x_p5 + x_p4 + x_p3 + x_p2 + x_p1 + x + x_m1 + x_m2 + x_m3 
g bb9  = r(estimate)
g sse9 = r(se)
lincom x_p5 + x_p4 + x_p3 + x_p2 + x_p1 + x + x_m1 + x_m2 + x_m3 + x_m4 
g bb10  = r(estimate)
g sse10 = r(se)
lincom x_p5 + x_p4 + x_p3 + x_p2 + x_p1 + x + x_m1 + x_m2 + x_m3 + x_m4 + x_m5
g bb11  = r(estimate)
g sse11 = r(se)

keep if _n==1
keep b1-b11 se1-se11 bb* sse*
save $main/data2/beta1_move, replace


clear
u $main/data2/beta1_move
g n=_n
reshape long b se bb sse, i(n) j(j)
g t = j-6
g upper = b + 1.96*se
g lower = b - 1.96*se


line  b upper lower t , legend(off) lpattern(solid dot  dot)  lcolor(black black black)     xlabel(-5 "{&beta}{sub:5}" -4 "{&beta}{sub:4}" -3 "{&beta}{sub:3}" -2 "{&beta}{sub:2}" -1 "{&beta}{sub:1}" 0 "{&beta}{sub:0}" 1 "{&beta}{sub:-1}" 2 "{&beta}{sub:-2}" 3 "{&beta}{sub:-3}" 4 "{&beta}{sub:-4}" 5 "{&beta}{sub:-5}" ) saving(fig1_m,replace)
graph export fig1_m.pdf, replace
! mv -f beta1_move.dta tables23/
! mv -f fig1_m.pdf tables23/
! mv -f fig1_m.gph tables23/

drop upper lower
g upper = bb + 1.96*sse
g lower = bb - 1.96*sse



line  bb upper lower t , legend(off) lpattern(solid dot  dot)  lcolor(black black black) yscale(range(-0.2 0.8)) ylabel(-0.2 0 0.2 0.4 0.6 0.8) xlabel(-5 "{&mu}{sub:5}" -4 "{&mu}{sub:4}" -3 "{&mu}{sub:3}" -2 "{&mu}{sub:2}" -1 "{&mu}{sub:1}" 0 "{&mu}{sub:0}" 1 "{&mu}{sub:-1}" 2 "{&mu}{sub:-2}" 3 "{&mu}{sub:-3}" 4 "{&mu}{sub:-4}" 5 "{&mu}{sub:-5}" ) saving(fig1b_m,replace)
graph export fig1b_m.pdf, replace
! mv -f fig1b_m.pdf tables23/
! mv -f fig1b_m.gph tables23/



restore */


