*** Moretti's cleaning code is unreproducible
* this excerpt from create_COMETS_Patent_ExtractForEnrico.do produces a different sample each time
* this is caused by the many-to-many merges
    * `merge` sorts the data, and `sort` randomly orders the data, producing a different sorting within tied values each time
* if the code was reproducible, the distribution of patents in field='computer science' should be a singleton
    * but here we get a different number each time
* this unreproducibility leads to slightly different sample sizes and results in Table 3, Figure 6, and Table 5

clear
set sortseed 1
local N 20
matrix zd_count = J(`N',1,.)

forval i = 1/`N' {
///Create COMETS_patent dataset
use patent_id country app_date using $main/data/patent_inventors, clear
keep if country=="US"|country==""|country=="USA"
drop if missing(app_date)

merge m:m patent_id using $main/data/patent_assignees, keepusing(org_id) keep(1 3) nogen

merge m:m patent_id using $main/data/patent_zd_cats, keepusing(zd) keep(1 3) nogenerate

count if zd == "com"
matrix zd_count[`i',1] = r(N)
di "Iteration: `i'"
}

svmat zd_count
keep zd_count1

set scheme plotplainblind

hist zd_count1, title("Computer science patents") xtitle("") bin(20) freq 

graph export "$figures/comet_reprod.png", replace
graph export "$figures/comet_reprod.pdf", replace