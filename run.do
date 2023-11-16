* set path: uncomment the following line and set the filepath for the folder containing this run.do file
*global root "[location of replication archive]"
global main "$root/data/AER_UPLOADED"
global tables "$root/output/tables"
global figures "$root/output/figures"

* Stata version control
version 13.1

* configure library environment
do "$root/code/_config.do"

* clean the data
do "$root/code/create_COMETS_Patent_ExtractForEnrico_mw.do"
* main dataset
do "$root/code/data_3_mw.do"

* event study: Figure 1
do "$root/code/reg23_mw.do"

* IV regressions: Table 1
do "$root/code/iv_new_mw.do"
do "$root/code/reg11_mw.do"

* Figure 2: distribution of estimates from same IV regression
do "$root/code/reproducible.do"

* script showing Moretti's cleaning code is unreproducible
do "$root/code/comets_reproducible.do"