* MW: my changes are tagged with comments starting with "** MW"

********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************
* IV 
********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************
clear
u $main/data2/data_3

drop if zd ==.
drop if year  ==.
drop if org_id == ""
drop if bea ==.

/* gegen total = sum(number), by(inventor) */
** MW: not used

* INCLUDE THE FOLLOWING 6 LINES IF YOU DON'T WANT INTERPOLATED DATA
/* replace bea    =. if inter_bea   ==1
replace zd     =. if inter_zd    ==1
replace class  =. if inter_class ==1
replace bea    =. if inter_bea2  ==1
replace zd     =. if inter_zd2   ==1
replace class  =. if inter_class2==1 */
** MW: no changes made

gegen org_new2 = group(org_id)

* This is the number of inventors in a  firm  in a given city (in a given field and year)
g n = 1
gcollapse (sum) n, by(year zd bea org_new)

* Now the level of observation is year field city firm
* This is the total number of inventors in a city across all firms (in a given field and year)
/* gegen nn = sum(n), by(year zd bea) */
** MW: not used

* This is the share of  inventors in a firm in  a given city (in a given field and year)
/* g share = n/nn
summ n nn share, detail */
** MW: not used

* Lagged share
/* gsort zd bea org_new year
by   zd bea org_new: g share_1 = share[_n-1]
by   zd bea org_new: g n_1 = n[_n-1] */
** MW: not used

* The data are now at the year field city firm level
* This is the total number of inventors by firm in the city (in a given year and field)
* It's the same as n above
gegen r2 = sum(n), by(org_new  year zd bea)
* This is the total number of inventors in a firm across all cities in the nation (in a given year and filed)
gegen rr2 = sum(n), by(org_new  year zd )
* For each firm, field city and year, this is the total number of inventors that the firm has 
* in the nation outside the relevant city (in a year)
g DD = rr2 - r2

* This is the change over time in DD
* Note: it is non-missing only for firms that are present in a given city-field in year t-1 and t
*       If a firm is not present in year t-1, DD1 is missing

** MW: the original code generates unreproducible results, since the sort order is not unique (not sorting by city (bea))
    * ie. DD1 is different for different runs of the code
    * fix: sort also by id=_n, to get a reproducible DD1
gen id = _n
gsort zd org_new year id 
/* gsort zd org_new year */
by zd org_new: g DD1 = DD - DD[_n-1]

** MW: the line above incorrectly takes first-differences across cities, since it doesn't sort by city (bea)
    * DD = N_{sf(-c)t} is the number of inventors in a firm outside of the focal city, so we need to preserve the identity of the focal city when calculating the first-difference
gsort zd org_new bea year
by zd org_new bea: gen DD1_fix = DD - DD[_n-1]
** MW: fixed: take first difference within city, not across cities

/* by zd org_new: g DD2 = (DD - DD[_n-1]) / DD[_n-1]
by zd org_new: g DD3 = (DD - DD[_n-1]+1) / (DD[_n-1] +1)
by zd org_new: g DD4 = (DD - DD[_n-1]+0.01) / (DD[_n-1] +0.01) */
** MW: not used


* First Differences models are defined 
* Only for Obs in Contiguous years
** MW: note that this sorts by city, as well as field and firm
gsort zd bea org_new year
by zd bea org_new: g Dyear = year - year[_n-1]

replace DD1 = . if Dyear ~=1
replace DD1_fix = . if Dyear ~=1

/* replace share_1 = . if Dyear ~=1
replace n_1 = . if Dyear ~=1
replace DD2 = . if Dyear ~=1
replace DD3 = . if Dyear ~=1 */
** MW: not used

* Now I normalize  DD1 by the relevant  nationwide chnage 
g tmp8 = DD1
gegen tmp9 = sum(tmp8), by(zd year)
g iv8 = tmp8/tmp9
/* drop tmp8 tmp9 */
** MW: create fixed iv
g tmp8_fix = DD1_fix
gegen tmp9_fix = sum(tmp8_fix), by(zd year)
g iv8_fix = tmp8_fix/tmp9_fix

* * THIS IS THE TOTAL IN THE FOCAL CITY, FIELD ANF YEAR
save $main/data2/tmp1, replace

** MW: rename aggregate variables for clarity
    * this calculates the sum across all firms in city c and field f and year t
gcollapse (sum) tot_iv8=iv8 tot_iv8_fix=iv8_fix, by(year zd bea )
/* gcollapse (sum) iv8 , by(year zd bea ) */
summ
gsort year zd bea         
save $main/data2/tmp3, replace


*  THIS IS THE CHANGE IN FOCAL FIRM
clear
u $main/data2/tmp1
/* rename iv8 hh8 */
** MW: for clarity, I change the variable name below to 'IV', instead of using 'iv8' for two different variables

/* gcollapse hh8 , by(year zd bea org_new2) */
** MW: collapse is unnecessary, since data is already at year-field-city-firm level
    * use keep instead
keep year zd bea org_new2 iv8 iv8_fix tmp8 tmp9 tmp8_fix tmp9_fix DD DD1 DD1_fix

gsort year zd bea

merge m:1  year zd bea using $main/data2/tmp3
/* tab _merge */
drop _merge

* NOW I SUBTRACT THE CHANGE IN FOCAL FIRM FROM THE TOTAL SO THAT THE INSTRUMENT DOES NOT CONTAIN FOCAL FIRM

/* replace iv8 = iv8 - hh8 if hh8 ~=. */
** MW: this incorrectly assigns a nonmissing iv8 to observations with missing hh8
    * the goal is to subtract the value of the instrument for firm j from the total value
    * but the total value (from tmp3.dta) is defined for all observations, including observations with missing values of hh8 (the firm-specific term in the sum)
        * note that hh8 can be missing because observations are not consecutive years, or because the first-difference is taken across cities or firms
    * so using `replace` assigns the IV to observations where the firm-specific term is missing

** MW: corrected instrument
gen IV = tot_iv8 - iv8
gen IV_fix = tot_iv8_fix - iv8_fix

** MW: keep original version of iv, incorrectly defined for observations with missing values of iv8
gen IV_orig = tot_iv8
replace IV_orig = IV_orig - iv8 if missing(iv8)==0

** MW: 
* IV_orig takes first-difference across cities and has nonmissing values for observations with missing iv8
* IV takes first-difference across cities and is missing when iv8 is missing
* IV_fix takes first_difference only within cities and is missing when iv8 is missing

gsort bea year zd org_new2
save $main/data2/iv_data_new, replace
summ

** MW: intuition for instrument
    * calculate the number of inventors that each firm has outside of the focal city (in field f)
    * take the sum for all firms in city c
    * subtract the value for firm j
    * this is the instrument for firm j (in first-differences)