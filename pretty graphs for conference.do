//////////////////////////////////////co-inventor count density graph
use "F:\Box Sync\Prospective research\distance from self and others\temp.dta", clear
label var inv_count "Co-inventor count"
			
			histogram  inv_count if inv_count <=8 & appyear >= 1975 & appyear <=2005 , ///
			discrete frac  /*(start=1)*/ ///
					ytitle("Share total patents") ///
		title("Distribution of US patents by co-inventor count") ///
		subtitle("All granted patents 1975 - 2005") ///
		xlabel(1(1)8)

			*drop if inv_count > 8 | 
///////////////////////////////////average # of co-inventors across time with standard deviations
drop if appyear <1975 | appyear > 2005
egen mean = mean(inv_count), by(appyear)
egen sd = sd(inv_count), by(appyear)
bysort appyear: gen n = _N
gen top = mean + invttail(n-1,0.025)*(sd / sqrt(n))
gen bottom = mean - invttail(n-1,0.025)*(sd / sqrt(n))
bysort appyear: gen tag = 1 if _n == 1 
label var appyear "Year"
graph twoway (line mean appyear) if tag == 1, ///
		title("Average co-inventor count on a US patent by application year") ///
		subtitle("All granted patents 1975 - 2005") ///
		ytitle("Co-inventor count per patent") ///
xlabel(1975(10)2005)


drop mean tag top bottom
//////////////////////////////////two moderating effects graphs


use "F:\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_final data_sample.dta", clear

//graph 1

eststo m2: qui nbreg totyr_patcit c.inv_overlap_class##c.total_experience     total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
*esttab m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps

label var inv_overlap_class "Co-inventor expertise overlap"
label var total_experience "Total expertise in dyad"

  
  quietly margins, at(total_experience=(1(1)12) inv_overlap_class = (0, .8, 3, 5))
marginsplot, noci scheme(sj) ///
 ytitle("Predicted annual citations") ///
  title("Cites predicted by total expertise in co-inventor dyad") ///
  subtitle("At different extents of expertise overlap") ///
  legend( order(1 "None" 2 "at .8 - mean" 3 "at 3" 4 "at 5")) /// 
  legend( subtitle("Extent of expertise overlap"))

//graph 2

eststo m2: qui reg totyr_patcit  c.inv_ab_diff##c.total_experience  inv_overlap_class total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
*esttab m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps



label var inv_ab_diff "Disparity in expertise level"

  
  quietly margins, at(total_experience=(1(1)12) inv_ab_diff = (0, .5, 1, 3))
marginsplot, noci scheme(sj) ///
 ytitle("Predicted annual cites") ///
  title("Cites predicted by total expertise in co-inventor dyad") ///
  subtitle("At different extents of disparity in expertise level") ///
  legend( order(1 "None" 2 "at .5 - mean" 3 "at 1" 4 "at 3")) /// 
  legend( subtitle("Extent of disparity in expertise level"))
