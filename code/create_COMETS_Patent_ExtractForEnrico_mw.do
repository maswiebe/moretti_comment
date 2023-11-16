** MW: edit to use gtools, use m:1 instead of m:m merge

*************************************************************************
* Dan Wilson
* Program creates COMETS Patent dataset for use in Dan Wilson's Biotech Tax Rate project
*************************************************************************
*global DATE = "091715"	// Specify date to use in filenames of created data sets
/* version 13.1 */
capture log close
*log using "/data11/home/public/dan/biotech-taxrate/data/log_files/create_COMETS_Patent.$S_DATE.log", replace
clear
set more off
pause on

set seed 1

//Prepare patent citation counts data
use $main/data/patent_cite_counts, clear
gcollapse (sum) citations, by(patent_id)
sum citations, detail
save  $main/data/cite_counts, replace


//Prepare patent class data
use $main/data/patent_us_classes, clear
keep if pos==1  //keep only first listed tech class for each patent
gen class = substr(us_class, 1, strpos(us_class,"/") - 1)
destring class, replace force
drop pos us_class
save  $main/data/us_classes, replace


//Prepare organization-specific data
use $main/data/patent_assignees if org_id~="", clear
gegen org_namemode = mode(org_name), minmode by(org_id)
gegen org_norm_namemode = mode(org_norm_name), minmode by(org_id)
gegen org_typemode = mode(org_type), minmode by(org_id)
gegen org_state = mode(state), minmode by(org_id)
gegen org_country = mode(country), minmode by(org_id)
drop org_name org_norm_name org_type
rename org_namemode org_name
rename org_norm_namemode org_norm_name
rename org_typemode org_type
gegen tag=tag(org_id)
keep if tag
keep org_id org_name org_type org_norm_name org_state org_country
save $main/data/org_id_info, replace

** MW: there are multiple assignees per patent; select the modal assigned firm, or pick randomly if tied
use patent_id org_id pos using $main/data/patent_assignees, clear
gsort patent_id pos
egen org_id_mode = mode(org_id), by(patent_id)

* pick modal firm: pick randomly if multiple firms per mode
duplicates tag patent_id, gen(tag)
drop if org_id != org_id_mode & missing(org_id_mode)==0 & tag>0
gen unif = runiform() if tag>0
gegen max_unif = max(unif), by(patent_id)
keep if unif == max_unif
drop unif max_unif tag

* for multiple modes: split ties randomly (org_id_mode is missing)
gen unif = runiform() if missing(org_id_mode)
gegen max_unif = max(unif), by(patent_id)
keep if unif == max_unif
drop unif max_unif

* check
count if missing(org_id)==1 & missing(org_id_mode)==0
duplicates r patent_id

keep patent_id org_id
save $main/data/patent_assignees_unique, replace

** MW: there are multiple fields per patent; select the highest weighted field, or pick randomly if tied
use $main/data/patent_zd_cats, clear
gsort patent_id zd
gegen maxweight = max(weight), by(patent_id)
keep if weight==maxweight
gen unif = runiform()
gegen max_unif = max(unif), by(patent_id)
keep if unif == max_unif
keep patent_id zd
save $main/data/patent_zd_cats_unique, replace

///Create COMETS_patent dataset
use $main/data/patent_inventors, clear
keep patent_id last_name first_name middle_name bea_code city state postal_code country app_date
replace country="US" if country=="USA"
keep if country=="US"|country==""
drop country
gen year=substr(app_date,1,4)
destring year, replace
drop if year==.
order year

** MW: drop duplicates
duplicates drop year patent_id last_name first_name middle_name city state postal_code bea_code app_date, force
* 772 obs dropped

// Merge with data sets containing assignees, zd categories, USPTO classes, and citation counts
*rename state state_inventor

** MW: these many-to-many merges are not reproducible
* it depends on the sort order, and for patents assigned to multiple firms/fields, there are multiple rows for each patent_id
    * `merge` sorts the data, creating a random order within tied values
* this leads to different sample sizes for each run of the code
* fix: use a m:1 merge
merge m:1 patent_id using $main/data/patent_assignees_unique, keepusing(org_id) keep(1 3) nogen
/* merge m:m patent_id using $main/data/patent_assignees, keepusing(org_id) keep(1 3) nogen */

*rename state org_state
*rename country org_country
*rename state_inventor state

merge m:1 patent_id using $main/data/patent_zd_cats_unique, keepusing(zd) keep(1 3) nogenerate
/* merge m:m patent_id using $main/data/patent_zd_cats, keepusing(zd) keep(1 3) nogenerate */

merge m:1 patent_id using $main/data/cite_counts, keepusing(citations) keep(1 3) nogenerate
replace citations = 0 if citations==.  //citations==. means that patent had no citations
merge m:1 patent_id using $main/data/us_classes, keepusing(class) keep(1 3) nogenerate

// Create single variable for inventor name
egen inventor=concat(first_name middle_name last_name), punct(" ")
replace inventor=subinstr(inventor,";","",.)
replace inventor=subinstr(inventor,"/","",.)
*replace inventor=subinstr(inventor,".","",.)
replace inventor=subinstr(inventor,".","",.) if strpos(inventor,".")==1
*replace inventor=subinstr(inventor,"'","",.)
replace inventor=itrim(inventor)
replace inventor=ltrim(inventor)
replace inventor=rtrim(inventor)
drop last_name first_name middle_name 

merge m:1 org_id using $main/data/org_id_info, keepusing(org_name org_type org_norm_name org_state org_country) keep(1 3) nogen
save $main/data/COMETS_Patent_ExtractForEnrico, replace
summ
