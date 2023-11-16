** MW: updated commands to use gtools

********************************************************************
********************************************************************
* This file reads the data used in the AER tax paper and creates 2 dataset 
* a) data.dta is a balanced rectangual dataset at the inventor-year level
* b) data_patent_level is at the patent level, like the original data
*
* zd is a broad technological area
* class is a finer technology class
* bea is a locality code: it is a consolidated metro area
*
* Codebook can be found here: https://www.kauffman.org/microsites/comets/codebook
* Or google “Zucker-Darby COMETS patent data”
* Source of data is the AER paper with Dan W. Dan made original extract 
*******************************************************************
********************************************************************



***********************************************
***********************************************
* CLEAN THE DATA
***********************************************
***********************************************
u $main/data/COMETS_Patent_ExtractForEnrico.dta, clear
compress

keep if year >1970 & year <=2007
gegen inventor_id = group(inventor)
drop if inventor_id ==.
drop if class ==.

drop if bea =="NOCOUNTRY"
drop if bea =="OTHER_USA"
drop if bea =="UNITED STATES"
destring bea, replace
drop if bea ==.
drop if bea ==0

* ZD is the broad technology class
* Here I create a ZD2 which is the numeric version 
gegen zd2 = group(zd)
tab zd zd2
drop if zd2 ==.


* MERGE WITH NBER PATENT DATA
** MW: not used
/* sort patent, stable
merge m:m patent using  $main/data/apat63_99
tab _merge
summ
drop _merge
drop if inventor_id ==. */



*****************************************************************
g N = 1
gsort inventor year bea
by inventor year: replace N = N[_n-1] + 1 if bea ~= bea[_n-1] & _n >1
gegen NN = max(N), by(inventor)
drop if NN > 3 & NN ~=.
drop N NN

g N = 1
gsort inventor year zd2
by inventor year: replace N = N[_n-1] + 1 if zd2 ~= zd2[_n-1] & _n >1
gegen NN = max(N), by(inventor year)
drop if NN > 3 & NN ~=.
drop N NN


***********************************************
**************************************
* MEASURES OF CLUSTERS DENSITY
* LEAVE OUT MEANS
* I want to measure the thickness of the labor market
* I can measure it as (a) numbner of inventors or (2) number of firms 
***************************************
***********************************************

* NUMBER OF INVENTORS
***************************
** MW: not used
/* gsort inventor_id year bea 
by inventor_id year bea: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea year)
gegen total = count(d1), by(year)
g density13 = (count -1)/(total-1)
drop count total d1 */

gsort inventor_id year bea zd 
by inventor_id year bea zd: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea zd year)
gegen total = count(d1), by(zd year)
g density14 = (count-1)/(total-1)
compress
/* save $main/data2/data_3_count, replace */
drop count total d1

/* gsort inventor_id year bea class
by inventor_id year bea class: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea class year)
gegen total = count(d1), by(class year)
g density15 = (count-1)/(total-1)
drop count total d1



gsort inventor_id year bea cat
by inventor_id year bea cat: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea cat year)
gegen total = count(d1), by(cat year)
g density20 = (count-1)/(total-1)
drop count total d1

gsort inventor_id year bea subcat
by inventor_id year bea subcat: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea subcat year)
gegen total = count(d1), by(subcat year)
g density21 = (count-1)/(total-1)
drop count total d1




* NUMBER OF FIRMS
**********************************************
gsort org_id year bea
by org_id year bea: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea year)
gegen total = count(d1), by(year)
g density13B = (count -1)/(total-1)
drop count total d1

gsort org_id year bea zd
by org_id year bea zd: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea zd year)
gegen total = count(d1), by(zd year)
g density14B = (count-1)/(total-1)
drop count total d1

gsort org_id year bea class
by org_id year bea class: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea class year)
gegen total = count(d1), by(class year)
g density15B = (count-1)/(total-1)
drop count total d1


gsort org_id year bea cat
by org_id year bea cat: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea cat year)
gegen total = count(d1), by(cat year)
g density20B = (count-1)/(total-1)
drop count total d1

gsort org_id year bea subcat
by org_id year bea subcat: g d1 = 1 if _n ==1
gegen count = count(d1), by(bea subcat year)
gegen total = count(d1), by(subcat year)
g density21B = (count-1)/(total-1)
drop count total d1 */



* I SAVE DENSITY MEASURES IN DATA FILES 
* TO BE USED LATER
***********************************************
compress
save $main/data2/data_patent_level_3, replace
summ

/* gsort bea year
gcollapse density13 density13B, by(bea year)
compress
save $main/data2/density13_3, replace
summ */

/* u $main/data2/data_patent_level_3 */
gsort bea zd2 year
gcollapse density14, by(bea zd2 year)
/* gcollapse density14 density14B, by(bea zd2 year) */
compress
save $main/data2/density14_3, replace
summ

/* u $main/data2/data_patent_level_3
gsort bea class year
gcollapse density15 density15B, by(bea class year)
compress
save $main/data2/density15_3, replace
summ




u $main/data2/data_patent_level_3
gsort bea cat year
gcollapse density20 density20B, by(bea cat year)
compress
save $main/data2/density20_3, replace
summ

u $main/data2/data_patent_level_3
gsort bea subcat year
gcollapse density21 density21B, by(bea subcat year)
compress
save $main/data2/density21_3, replace
summ



* ORGANIZATION
u $main/data2/data_patent_level_3
drop if org_id ==""
g org_N = 1 if inventor_id ~=.
gsort org_id bea year
gcollapse (sum) org_N, by(org_id org_norm_ bea year)
summ
compress
save $main/data2/organizations_3, replace */



*****************************************************
*****************************************************
* I COLLAPSE 
* THE SAMPLE BECOMES AT THE INVENTOR-YEAR LEVEL
*
* IF AN INVENTOR HAS MORE THAN ONE CITY OR SECTOR IN A GIVEN 
* YEAR, I USE MODAL CITY AND SECTOR. 
******************************************************
******************************************************
u $main/data2/data_patent_level_3
compress

* In cases where there are multiple cities, zd or classes within 1 year, pick mode
* I use  maxmode to deal with ties. Minmode does not  make a difference
egen main_bea        = mode(bea),     maxmode by(inventor_id year)
egen main_zd         = mode(zd2),     maxmode by(inventor_id year)
egen main_class      = mode(class),   maxmode by(inventor_id year)
egen main_org        = mode(org_id),  maxmode by(inventor_id year)
** MW: not used
/* egen main_cat        = mode(cat),     maxmode by(inventor_id year)
egen main_subcat     = mode(subcat),  maxmode by(inventor_id year)
egen main_org_type   = mode(org_typ), maxmode by(inventor_id year) */


* When a patent is joint, I split it equally among inventors
gegen tmp7 = count(inventor_id), by(patent_id) 
summ tmp7, detail
tab tmp7 if tmp7 <=20
g number = 1/tmp7
replace citations = citations / tmp7
drop tmp7

* Team size: number of inventors on a patent
gegen team  = count(inventor_id), by(patent_id)
summ team, detail
* indicator for solo inventor
g    team2 = (team ==1)
summ year team*

* Collapse by inventor_id year. Note that main_org main_org_type are constant within a
* inventor_id year pair. I include them in by() so that they are in the 
* collapsed data
summ
gsort inventor_id year  
compress
gcollapse main_bea main_zd main_class team team2 (sum) number citat, by(inventor_id year main_org)
/* gcollapse main_bea main_zd main_class main_cat main_subcat general original team team2 (sum) number citat, by(inventor_id year main_org main_org_type ) */



********************************************
********************************************
* I FILLIN AND INTERPOLATE SMALL GAPS
* I CREATE INDICATORS FOR INTERPOLATION THAT ALLOW ME
* TO IDENTIFY AND DROP INTERPOLATED  OBSERVATIONS
********************************************
********************************************
rename main_bea bea_code
rename main_zd zd2
rename main_class class
rename main_org org_id
** MW: not used
/* rename main_org_type org_type
rename main_cat cat
rename main_subcat subcat */

** MW: not used
/* fillin inventor_id year
summ

g inter_bea    =0
g inter_zd     =0
g inter_class  =0
g inter_bea2    =0
g inter_zd2     =0
g inter_class2  =0

* 1 YEAR GAP
gsort inventor year
by inventor: replace inter_bea = 1   if bea ==. & bea[_n-1] == bea[_n+1] & bea[_n-1] ~=.
by inventor: replace bea = bea[_n-1] if inter_bea ==1

by inventor: replace inter_zd = 1   if zd ==. & zd[_n-1] == zd[_n+1] & zd[_n-1] ~=.
by inventor: replace zd = zd[_n-1] if inter_zd ==1

by inventor: replace inter_class = 1   if class ==. & class[_n-1] == class[_n+1] & class[_n-1] ~=.
by inventor: replace class = class[_n-1] if inter_class ==1


* 2 YEAR GAP
by inventor: replace inter_bea2 = 1  if bea ==. & bea[_n-1] ==. & bea[_n-2] == bea[_n+1] & bea[_n-2] ~=.
by inventor: replace bea = bea[_n-2] if inter_bea2 ==1

by inventor: replace inter_zd2 = 1 if zd ==. & zd[_n-1] ==. & zd[_n-2] == zd[_n+1] & zd[_n-2] ~=.
by inventor: replace zd = zd[_n-2] if inter_zd2 ==1

by inventor: replace inter_class2 = 1 if class ==. & class[_n-1] ==. & class[_n-2] == class[_n+1] & class[_n-2] ~=.
by inventor: replace class = class[_n-2] if inter_class2 ==1


summ inter* 
summ bea if inter_bea ==0
summ bea if inter_bea ==1
summ class if inter_class ==0
summ class if inter_class ==1

summ bea if inter_bea2 ==0
summ bea if inter_bea2 ==1
summ class if inter_class2 ==0
summ class if inter_class2 ==1 */


*******************************************
*****************************
* MERGE MAIN DATA WITH 
* MEASURES OF CLUSTER DENSITY
*****************************
********************************************
** MW: not used
/* sum
gsort bea year
merge m:1 bea year using $main/data2/density13_3
tab _merge
drop _merge */

gsort bea zd year
merge m:1 bea zd year using $main/data2/density14_3
tab _merge
drop _merge

/* gsort bea class year
merge m:1 bea class year using $main/data2/density15_3
tab _merge
drop _merge


gsort bea cat year
merge m:1 bea cat year using $main/data2/density20_3
tab _merge
drop _merge


gsort bea subcat year
merge m:1 bea subcat year using $main/data2/density21_3
tab _merge
drop _merge */


*************************************
*************************************
* SAVE
************************************
**************************************
** MW: not used
/* g Den_bea = density13  */
g Den_bea_zd = density14 
/* g Den_bea_class = density15 
g Den_bea_cat    = density20
g Den_bea_subcat = density21

g Den_beaB = density13B
g Den_bea_zdB = density14B
g Den_bea_classB = density15B
g Den_bea_catB    = density20B
g Den_bea_subcatB = density21B */

drop density*
/* drop density* Den_bea_cat* Den_bea_subcatB* cat subcat */
drop if inventor ==.

compress
save $main/data2/data_3, replace
summ




