u $main/data2/data_3, clear
drop if org_id == ""

gegen org_new2 = group(org_id)

g n = 1
gcollapse (sum) n, by(year zd bea org_new)

gegen nn = sum(n), by(year zd bea)

gegen r2 = sum(n), by(org_new  year zd bea)
gegen rr2 = sum(n), by(org_new  year zd )
g DD = rr2 - r2

gsort zd org_new year
by zd org_new: g DD1 = DD - DD[_n-1]

gsort zd bea org_new year
by zd bea org_new: g Dyear = year - year[_n-1]

replace DD1 = . if Dyear ~=1

g tmp8 = DD1
gegen tmp9 = sum(tmp8), by(zd year)
g iv8 = tmp8/tmp9

save $main/data2/tmp1_reprod, replace

gcollapse (sum) tot_iv8=iv8 , by(year zd bea )
save $main/data2/tmp3_reprod, replace

clear
u $main/data2/tmp1_reprod
rename iv8 hh8

keep year zd bea org_new2 hh8

merge m:1  year zd bea using $main/data2/tmp3_reprod
drop _merge

gen iv8_orig = tot_iv8
replace iv8_orig = iv8_orig - hh8 if missing(hh8)==0

save $main/data2/iv_data_new_reprod, replace