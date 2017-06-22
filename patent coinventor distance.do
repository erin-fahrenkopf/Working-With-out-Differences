/*
///////////////////////////////////////////////patent coinventor distance
	By Erin Fahrenkopf, Tepper, CMU



	clean up assignees and add
	caluclate if move or not
	check code
	add in if prior collab or not
	look up other attributes to add from other datasets
	
Created: 		3/25/16
Last updated:   4/18/16
////////////////////////////////////////////////////////////////////////////////////////////////
*/

//////////////////////Begin
	clear
	clear matrix
	set 	more off
	log 	using "C:\Users\Erin.Tesla\Box Sync\Dissertation data\STATA work\logs\patent coinventor distance.log", text replace
	adopath + "C:\Users\Erin.Tesla\Box Sync\Dissertation data\STATA work\Functions"

	
////////grab all patents
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\disamb_no_postpolishing.dta", clear 
			keep patent unique_inventor_id appyear gyear  invseq

/////////(1)mark if pre or post move			
			merge m:1 patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\assignee by patent.dta"
			keep_matched //only keep patents that are assigneed to organizations
///////////////clean assignee
					replace organization = lower(organization)
			gen assignee = organization
			run "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\assignee cleanup_postmove org.do"
//////////////////mark if prior patent is at same assignee or different
			bysort unique_inventor_id (appyear): gen	inv_firstyr = appyear[1]
			bysort unique_inventor_id (appyear assignee): gen inv_pat_id = _n 
			bysort unique_inventor_id (appyear assignee): gen prior_ass_same = 1 if assignee == assignee[_n - 1] //mark is the patents are squential
			bysort unique_inventor_id assignee (appyear): gen first_yrassignee = appyear[1] // first_yrassignee == first yr inventor patents at the assignee this is the yr at firm move to
			bysort unique_inventor_id assignee (appyear): gen last_yrassignee = appyear[_N] // last_yrassignee == last yr inventor patents at the assignee this is the yr at firm move to
			bysort unique_inventor_id assignee (appyear inv_pat_id): gen inv_pat_ass_id = _n
			gen postmove = 1 if first_yrassignee == appyear & inv_firstyr < appyear //postmove patents
					replace postmove = 0 if postmove ==.
			gen premove = 1 if last_yrassignee == appyear & first_yrassignee < appyear //premove patents
					replace premove = 0 if premove == .
					
//////////(2) mark if single or coinvented patents
			merge m:1 patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\inventor_count.dta"
					keep_matched //all in master should match
			gen coinvented = 1 if inv_count == 2
					replace coinvented = 0 if coinvented == .
			gen single = 1 if inv_count == 1
					replace single = 0 if single == .

///////////(3) find sample of coinvented patents that occur after the inventor has had at least one single invented prior patent
/////mark prior patents and prior single invented patents for each  coinvented patent
			bysort unique_inventor_id (inv_pat_id): gen single_acc = sum(single)
			bysort unique_inventor_id (inv_pat_id): gen coinvented_ofinterest = 1 if single_acc > 0 & _n > 2 & coinvented == 1
					replace coinvented_ofinterest = 0 if coinvented_ofinterest ==.
			bysort unique_inventor_id (inv_pat_id): gen coinvented_ofinterest_acc = sum(coinvented_ofinterest )
			bysort unique_inventor_id (inv_pat_id): egen coinvented_ofinterest_tot = sum(coinvented_ofinterest )
			bysort unique_inventor_id (inv_pat_id): gen drop = 1 if coinvented_ofinterest_tot == 0 | coinvented_ofinterest_acc[_n - 1] == coinvented_ofinterest_tot[_n] 
//// keep only patents filed before and including coinvented patents of interest patent
			drop if drop == 1
	save  "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_1.dta", replace

////////////(4) create dataset of prior classifications -at this point - keep only prior single patents
			keep if single == 1 // keep single invented patents prior to coinvented patent of interest
////////match in classes
			merge 1:m patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_uspc.dta" //file goes to 2010
					keep_matched // drop patents that do not have any classes - perhaps need to filter on just the inventors that have prior classes
			duplicates drop patent mainclass_id, force //keep if looking at larger classification codes, add inventor_id if not focusing on single patents
					keep unique_inventor_id  appyear  mainclass_id 
					rename appyear appyear_single
					rename mainclass_id mainclass_id_single
			duplicates drop unique_inventor_id appyear_single mainclass_id_single, force  //agg class by yr
	save  "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_singles.dta", replace // file with classes on inventor classes
	
////////////(5) create dataset of classes on coinvented patents	
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_1.dta", clear //grab all coinvented patents and prior patents
			keep if coinvented == 1  // keep only coinvented patents
			joinby patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_uspc.dta" //file goes to 2010
			duplicates drop unique_inventor_id patent mainclass_id, force //keep if only look at larger classification codes
			bysort unique_inventor_id patent: gen total_class_patent = _N //total_class_patent = number of classes on the patent
					keep unique_inventor_id patent appyear gyear inv_firstyr mainclass_id single_acc total_class_patent  invseq premove postmove inv_pat_id 
		save  "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_doubles.dta", replace

////////////(6)calculate overlap between prior patents and coinvented patent
			joinby unique_inventor_id using  "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_singles.dta"
			keep if appyear_single <= appyear //keep classes that occur prevously
			keep if appyear - appyear_single <= 9
			duplicates drop unique_inventor_id patent mainclass_id mainclass_id_single, force // keep only one prior class and not by year
			bysort unique_inventor_id patent mainclass_id: gen total_class_inv = _N //total_class_inv = number of classes inventor has prior to coinvented patent
			gen class_match = 1 if mainclass_id_single == mainclass_id
			bysort unique_inventor_id patent: egen matchingclasses = total(class_match) //matchingclasses = number of overlap classes inventor has with coinvented patent 
			duplicates drop unique_inventor_id patent, force
					keep unique_inventor_id patent matchingclasses appyear gyear inv_firstyr single_acc total_class_patent inv_pat_id  total_class_inv invseq  premove postmove

//////////////(7) turn dataset into wide with each coinvented patent as obs					
			bysort patent: gen total_inv = _N //figure out how many inventors are on patent
			keep if total_inv == 2 //drop all coinvented patents that do not have two inventors
			bysort patent (invseq): gen pat_inv_ID = _n
			bysort patent (pat_inv_ID): gen unique_inventor_id_1 = unique_inventor_id[2]
			bysort patent (pat_inv_ID): gen matchingclasses_1 = matchingclasses[2]
			bysort patent (pat_inv_ID): gen inv_firstyr_1 = inv_firstyr[2]
			bysort patent (pat_inv_ID): gen single_acc_1 = single_acc[2]
			bysort patent (pat_inv_ID): gen total_class_inv_1 = total_class_inv[2]
			bysort patent (pat_inv_ID): gen inv_pat_id_1 = inv_pat_id[2]
			bysort patent (pat_inv_ID): gen premove_1 = premove[2]
			bysort patent (pat_inv_ID): gen postmove_1 = postmove[2]
			drop if pat_inv_ID == 2 //make unique on patent
			keep patent  unique_inventor_id* matchingclasses* inv_firstyr* single_acc* appyear gyear total_class_inv* inv_pat_id*  total_class_patent premove* postmove*
			rename appyear cited_yr
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_2.dta", replace

///////////(8) calculate distance between two coinventors - overlap only calculated if overlap and no observations if no overlap
///pull inventor 1's prior classes
			joinby unique_inventor_id  using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_singles.dta"	
			keep if appyear_single <= cited_yr
			keep if cited_yr - appyear_single <= 9
			duplicates drop patent mainclass_id_single, force
					drop appyear_single
///pull inventor 2's prior classes
					rename unique_inventor_id  unique_inventor_id_0 
					rename unique_inventor_id_1 unique_inventor_id
					rename mainclass_id_single mainclass_id_single_0
			joinby unique_inventor_id  using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_singles.dta"	
			keep if appyear_single <= cited_yr
			keep if cited_yr - appyear_single <= 9
			duplicates drop patent mainclass_id_single mainclass_id_single_0, force
					drop appyear_single
			keep if mainclass_id_single == mainclass_id_single_0
			bysort patent: gen inv_overlap_class = _N //inv_overlap_class = number of overlap prior classes between inventors
					keep inv_overlap_class patent
			duplicates drop patent, force //get rid of all the extra obs by classes 
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_3.dta", replace

//////////////////(9) calculate coinvented citations by year 
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_2.dta", clear
			merge 1:m patent using "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\citations 7510 with dates.dta" // lots of these dont have dates - INSPECT
				keep_matched
/////NOTE: last yr that I have citations for is 2010 so cannot look at yrs after 2005
			drop if citingyear == .
			keep if citingyear - cited_yr <= 5 
			collapse (count) citing, by (citingyear patent)	//aggregate by patent and yr of citing patent
					rename citing totyr_patcit //these counts seem really  high
					rename citingyear year
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance - dep var - patcits.dta", replace

///////////////(10) make dataset time series	
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_2.dta", clear
			
					*bysort unique_inventor_id unique_inventor_id_1: gen prior_coll_proxy = _n //what if other inventor is first?
					gen unique_inventor_id_1_num = subinstr(unique_inventor_id_1, "-", "",.)
							destring unique_inventor_id_1_num, replace force
					gen unique_inventor_id_num = subinstr(unique_inventor_id, "-", "",.)
							destring unique_inventor_id_num, replace force
							drop if unique_inventor_id_num == . | unique_inventor_id_1_num == .
					gen double final_ID1 = unique_inventor_id_1_num  if unique_inventor_id_1_num  < unique_inventor_id_num
							replace final_ID1 = unique_inventor_id_num if unique_inventor_id_num < unique_inventor_id_1_num 
					gen double final_ID2 = unique_inventor_id_num if unique_inventor_id_1_num  < unique_inventor_id_num
							replace final_ID2 = unique_inventor_id_1_num  if unique_inventor_id_num < unique_inventor_id_1_num 
					bysort final_ID1 final_ID2: gen prior_coll_proxy = _n 
					
			make_timeseries 6 "patent" cited_yr //make it timeseries, one obs per year for each move
			drop if year >= 2010 //seems like I can go until 2010 unless i am using citation weighted patents
			
///////////////(11) get variables together
			//add in the dep variable
			merge 1:1 patent year using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance - dep var - patcits.dta"
					//all in using should match
					drop_using //not sure why this is dropping anything but seems to just be some amount of error
					replace totyr_patcit = 0 if totyr_patcit  ==. 
			merge m:1 patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_3.dta"
			drop_using //all should match in using
			replace inv_overlap_class = 0 if inv_overlap_class ==.
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_final data.dta", replace
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_final data.dta", clear

			
			gen total_experience = matchingclasses + matchingclasses_1

			gen inv_ab_diff = abs(matchingclasses - matchingclasses_1)
			gen inv_ab_diff_pat = abs(inv_pat_id - inv_pat_id_1)
			egen min_experience = rowmin(matchingclasses matchingclasses_1)
			gen post_grant = 1 if gyear >= year
					replace post_grant = 0 if post_grant == .
			
			
			gen since_app = year - cited_yr
			gen inv_age = year - inv_firstyr 
			gen inv_age2 = inv_age*inv_age
			gen inv_age_1 = year - inv_firstyr_1
			gen inv_age2_1 = inv_age_1*inv_age_1
			*gen inv_pat_id2_1 =inv_pat_id_1*inv_pat_id_1
			*gen inv_pat_id2 = inv_pat_id*inv_pat_id
			egen inv_1_id = group(unique_inventor_id)
			
			//continuous squared variables 
			gen matchingclasses2 = matchingclasses*matchingclasses
			gen matchingclasses2_1 = matchingclasses_1*matchingclasses_1
			gen total_experience2 = total_experience*total_experience
			gen inv_overlap_class2 = inv_overlap_class* inv_overlap_class 
			gen inv_ab_diff2 = inv_ab_diff*inv_ab_diff
			
			/* //share variables - these just do not seem to make sense  
			gen share_overlap = matchingclasses / total_class_inv
			gen share_overlap_1 = matchingclasses_1 / total_class_inv_1
			gen share_experience = total_experience / (total_class_inv +total_class_inv_1)
			gen share_experience = total_experience / total_class_patent
			
			gen share_inv_overlap = inv_overlap_class / (total_class_inv + total_class_inv_1)
			
			
			gen share_inv_ab_diff = abs(share_overlap - share_overlap_1)
			gen share_inv_ab_diff = inv_ab_diff / (total_class_inv +total_class_inv_1)*/
			
			
			//move variables
			gen postmove_pat = 1 if postmove == 1 & postmove_1 == 1
					replace postmove_pat = 0 if postmove_pat == .
			gen premove_pat = 1 if premove == 1 & premove == 1
					replace premove_pat = 0 if premove_pat == .
			gen neither_pat = 1 if postmove == 0 & postmove_1 == 0 & premove == 0 & premove_1 == 0
					replace neither_pat = 0 if neither_pat == .
			
			//gen binary overlap variables
gen inv_1_dist = 1 if matchingclasses == 0 //i.	First inventor close to self 
	replace inv_1_dist = 0 if inv_1_dist == .
gen inv_2_dist = 1 if matchingclasses_1 == 0 //iii.	Second inventor close to 
	replace inv_2_dist = 0 if inv_2_dist == .
	
gen inv_1_close = 1 if inv_1_dist == 0 //i.	First inventor close to self 
	replace inv_1_close  = 0 if inv_1_close  == .
gen inv_2_close  = 1 if inv_2_dist == 0 //iii.	Second inventor close to 
	replace inv_2_close  = 0 if inv_2_close  == .
	
gen inv_inv_dist = 1 if inv_overlap_class == 0 // ii.	Distance between collaborators 
	replace inv_inv_dist = 0 if inv_inv_dist == .
gen inv_inv_close = 1 if inv_overlap_class > 0 // ii.	close between collaborators 
	replace inv_inv_close = 0 if inv_inv_close == .
	
	
gen single_inv_dist = 1 if (inv_1_dist == 1 & inv_2_dist == 0 ) | (inv_2_dist == 1 & inv_1_dist == 0) //ii.	single inventor close to self 
replace single_inv_dist  = 0 if single_inv_dist  == .

gen double_inv_dist = 1 if inv_1_dist == 1 & inv_2_dist == 1  //v.	both inventors distant to self 
replace double_inv_dist = 0 if double_inv_dist == .
gen double_inv_close = 1 if inv_1_dist == 0 & inv_2_dist == 0  // iv.	both inventors close to self 
replace double_inv_close = 0 if double_inv_close == .	
	
	gen dist_dist = 1 if double_inv_dist == 1 & inv_inv_dist == 1 // everything distant
replace dist_dist = 0 if dist_dist == .

gen close_dist = 1 if double_inv_dist == 0 & inv_inv_dist == 1 // both close to self and distant from each other - expect really good
replace close_dist = 0 if close_dist == .

gen close_close = 1 if double_inv_dist == 0 & inv_inv_dist == 0  //everything close
replace close_close = 0 if close_close == .

gen close_dist_dist = 1 if single_inv_dist == 1 & inv_inv_dist == 1 // one close to self and distant from each other 
replace close_dist_dist = 0 if close_dist_dist == .



 
 ///////////(12) sample restrictions
 drop if single_acc > 3 | single_acc_1 > 3
 drop if prior_coll_proxy > 1
 drop if year < 1975
 drop if inv_age > 30 | inv_age_1 > 30
					
save "F:\Box Sync\Prospective research\distance from self and others\data work\data files\patent coinventor distance_final data_sample.dta", replace
					
/////////prelime data investigation					
tabstat totyr_patcit  , statistics(mean sd  n max min p25 p50 p75 p90 p99)
tabstat   inv_overlap_class matchingclasses matchingclasses_1 inv_ab_diff, statistics(mean sd  n max min p25 p50 p75 p90)
tabstat inv_firstyr* single_acc* inv_pat_id*  premove* postmove* year since_app total_class_patent post_grant prior_coll_proxy, statistics(mean sd  n max min p25 p50 p75 p90)
tabstat share_overlap_1 share_overlap, statistics(mean sd  n max min p25 p50 p75 p90)

tabstat totyr_patcit matchingclasses matchingclasses_1 total_experience  inv_overlap_class* inv_ab_diff   total_class_patent inv_age* total_class_inv* inv_pat_id*  post_grant year , statistics(mean sd  n max min p25 p50 p75 p90 p99)
cor totyr_patcit matchingclasses matchingclasses_1 total_experience  inv_overlap_class* inv_ab_diff   total_class_patent inv_age* total_class_inv* inv_pat_id*  post_grant year
cor total_experience  inv_overlap_class inv_ab_diff  

//table 1
tabstat totyr_patcit matchingclasses matchingclasses_1 total_experience  inv_overlap_class inv_ab_diff   total_class_patent inv_age*  inv_pat_id* since_app post_grant year, statistics(mean sd min max  p50 n )
cor totyr_patcit matchingclasses matchingclasses_1 total_experience  inv_overlap_class inv_ab_diff   total_class_patent inv_age*  inv_pat_id* since_app post_grant year

histogram totyr_patcit
histogram matchingclasses_1 if since_app == 0
histogram matchingclasses if since_app == 0
histogram total_experience  if since_app == 0
histogram inv_overlap_class if since_app == 0
histogram inv_ab_diff if since_app == 0

gen ln_overlap = ln(inv_overlap_class +1)
gen ln_diff = ln(inv_ab_diff+1)

//table 2
tabstat matchingclasses matchingclasses_1 total_experience  inv_overlap_class inv_ab_diff inv_age inv_age_1 inv_pat_id inv_pat_id_1 year if since_app == 0, statistics(mean sd min max  p50 n )



egen mean = mean(totyr_patcit), by(inv_overlap_class )
egen tag = tag(inv_overlap_class )
twoway line mean inv_overlap_class  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag

egen mean = mean(totyr_patcit), by(matchingclasses)
egen tag = tag(matchingclasses)
twoway line mean matchingclasses  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag

egen mean = mean(totyr_patcit), by(matchingclasses_1 )
egen tag = tag(matchingclasses_1)
twoway line mean matchingclasses_1  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag

egen mean = mean(totyr_patcit), by(share_overlap)
egen tag = tag(share_overlap)
twoway line mean share_overlap  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag

egen mean = mean(totyr_patcit), by(share_overlap_1 )
egen tag = tag(share_overlap_1)
twoway line mean share_overlap_1  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag


egen mean = mean(totyr_patcit), by(inv_ab_diff)
egen tag = tag(inv_ab_diff)
twoway line mean inv_ab_diff  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag


	
	ttest totyr_patcit , by(inv_inv_dist)
ttest totyr_patcit , by(inv_1_dist )

ttest totyr_patcit , by(single_inv_dist)
ttest totyr_patcit , by(double_inv_dist )
ttest totyr_patcit , by(double_inv_close )




ttest totyr_patcit , by(dist_dist)
ttest totyr_patcit , by(close_dist )
ttest totyr_patcit , by(close_close )


graph bar matchingclasses_1 , over(premove_1, relabel(1 "post" 2 "pre"))
graph bar matchingclasses , over(premove, relabel(1 "post" 2 "pre"))
graph bar matchingclasses_1 , over(postmove_1, relabel(1 "pre" 2 "post"))
graph bar matchingclasses , over(postmove, relabel(1 "pre" 2 "post"))

graph bar totyr_patcit , over(premove_pat, relabel(1 "post" 2 "pre"))
graph bar total_experience , over(premove_pat, relabel(1 "post" 2 "pre"))
graph bar totyr_patcit , over(postmove_pat, relabel(1 "pre" 2 "post"))
graph bar total_experience , over(postmove_pat, relabel(1 "pre" 2 "post"))








//tables
//table 2
eststo m1: qui nbreg totyr_patcit  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m2: qui nbreg totyr_patcit matchingclasses matchingclasses_1  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m3: qui nbreg totyr_patcit total_experience  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m4: qui nbreg totyr_patcit c.inv_ab_diff##c.total_experience  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m5: qui nbreg totyr_patcit c.inv_overlap_class##c.total_experience     total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m6: qui nbreg totyr_patcit c.inv_ab_diff##c.total_experience c.inv_overlap_class##c.total_experience   total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)

esttab m1  m2 m3 m4 m5 m6 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps


eststo m1: qui nbreg totyr_patcit  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m2: qui nbreg totyr_patcit matchingclasses matchingclasses_1  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m3: qui nbreg totyr_patcit total_experience  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m4: qui nbreg totyr_patcit c.ln_diff##c.total_experience  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m5: qui nbreg totyr_patcit c.ln_overlap##c.total_experience     total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m6: qui nbreg totyr_patcit c.ln_diff##c.total_experience c.ln_overlap##c.total_experience   total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)

esttab m1  m2 m3 m4 m5 m6 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps


//ttest
qui nbreg totyr_patcit matchingclasses matchingclasses_1  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
nbreg totyr_patcit matchingclasses matchingclasses_1  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
nbreg totyr_patcit matchingclasses_1 matchingclasses  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
cor matchingclasses_1 matchingclasses 
test matchingclasses = matchingclasses_1 
//graph 1

eststo m2: qui nbreg totyr_patcit c.inv_overlap_class##c.total_experience     total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
*esttab m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps

label var inv_overlap_class "Co-inventor overlapping exp"
label var total_experience "Total inventor experience"

  
  quietly margins, at(total_experience=(1(1)12) inv_overlap_class = (0, .8, 3, 5))
marginsplot, noci scheme(sj) ///
 ytitle("Predicted cites") ///
  title("Cites predicted by total inventor experience") ///
  subtitle("At different values of co-inventor overlapping experience") ///
  legend( order(1 "=0" 2 "=.8 - mean" 3 "= 3" 4 "=5")) /// 
  legend( subtitle("Co-inventor overlapping experience"))

//graph 2

eststo m2: qui reg totyr_patcit  c.inv_ab_diff##c.total_experience  inv_overlap_class total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
*esttab m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps



label var inv_ab_diff "Difference in co-inventor exp"
label var total_experience "Total inventor experience"

  
  quietly margins, at(total_experience=(1(1)12) inv_ab_diff = (0, .5, 1, 3))
marginsplot, noci scheme(sj) ///
 ytitle("Predicted cites") ///
  title("Cites predicted by total inventor experience") ///
  subtitle("At different values of difference in co-inventor experience") ///
  legend( order(1 "=0" 2 "=.5 - mean" 3 "= 1" 4 "=3")) /// 
  legend( subtitle("Difference in co-inventor experience"))


//table 3


eststo m1: qui nbreg  total_experience postmove_pat  total_class_patent total_class_inv*  i.cited_yr if (postmove_pat == 1 | premove_pat == 1 ) & since_app == 0
eststo m2: qui nbreg  inv_overlap_class postmove_pat  total_class_patent total_class_inv*  i.cited_yr if (postmove_pat == 1 | premove_pat == 1 ) & since_app == 0
eststo m3: qui poisson inv_ab_diff postmove_pat  total_class_patent total_class_inv*  i.cited_yr if (postmove_pat == 1 | premove_pat == 1 ) & since_app == 0
esttab m1  m2 m3, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps

///


 
eststo m1: qui nbreg totyr_patcit  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m2: qui nbreg totyr_patcit matchingclasses matchingclasses_1 inv_overlap_class inv_ab_diff  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m3: qui nbreg totyr_patcit inv_1_close  inv_2_close inv_inv_dist single_inv_dist double_inv_dist total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m4: qui nbreg totyr_patcit c.inv_1_close##c.inv_inv_dist inv_2_close single_inv_dist  double_inv_dist  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m5: qui nbreg totyr_patcit c.inv_2_close##c.inv_inv_dist inv_1_close single_inv_dist  double_inv_dist  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m6: qui nbreg totyr_patcit inv_1_close inv_2_close c.single_inv_dist##c.inv_inv_dist   double_inv_dist  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m7: qui nbreg totyr_patcit inv_1_close inv_2_close c.double_inv_dist##c.inv_inv_dist  single_inv_dist total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
esttab  m1  m2 m3 m4 m5 m6 m7, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

eststo m1: qui nbreg totyr_patcit  total_class_patent inv_age*  inv_pat_id* total_class_inv* post_grant i.since_app i.year, vce(r)
eststo m2: qui nbreg totyr_patcit  matchingclasses matchingclasses_1 inv_overlap_class inv_ab_diff  total_class_patent inv_age*  inv_pat_id* total_class_inv* post_grant i.since_app i.year, vce(r)
eststo m3: qui nbreg totyr_patcit total_experience inv_overlap_class inv_ab_diff total_class_patent inv_age*  inv_pat_id* total_class_inv*  post_grant i.since_app i.year, vce(r)
eststo m4: qui nbreg totyr_patcit matchingclasses*  inv_overlap_class* inv_ab_diff*  total_class_patent inv_age*  inv_pat_id* total_class_inv* post_grant i.since_app i.year, vce(r)
eststo m5: qui nbreg totyr_patcit total_experience*  inv_overlap_class* inv_ab_diff*    total_class_patent inv_age* total_class_inv* inv_pat_id*  post_grant i.since_app i.year, vce(r)
esttab  m1  m2 m3 m4 m5 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


eststo m1: qui nbreg totyr_patcit  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m2: qui nbreg totyr_patcit   total_experience total_class_patent inv_age*  inv_pat_id* post_grant i.since_app i.year, vce(r)
eststo m3: qui nbreg totyr_patcit  inv_overlap_class total_class_patent inv_age*  inv_pat_id*   post_grant i.since_app i.year, vce(r)
eststo m4: qui nbreg totyr_patcit inv_ab_diff  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m5: qui nbreg totyr_patcit total_experience  inv_overlap_class inv_ab_diff    total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
esttab  m1  m2 m3 m4 m5 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

eststo m1: qui nbreg totyr_patcit  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m2: qui nbreg totyr_patcit   total_experience total_class_patent inv_age*  inv_pat_id* post_grant i.since_app i.year, vce(r)
eststo m3: qui nbreg totyr_patcit  share_inv_overlap  total_class_patent inv_age*  inv_pat_id*   post_grant i.since_app i.year, vce(r)
eststo m4: qui nbreg totyr_patcit c.share_inv_overlap##c.share_inv_overlap   total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m5: qui nbreg totyr_patcit total_experience  c.share_inv_overlap##c.share_inv_overlap   inv_ab_diff    total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
esttab  m1  m2 m3 m4 m5 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	



eststo m1: qui nbreg totyr_patcit c.inv_ab_diff##c.total_experience inv_overlap_class total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m2: qui nbreg totyr_patcit  c.inv_ab_diff##c.inv_overlap_class  total_experience  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m3: qui nbreg totyr_patcit inv_ab_diff c.inv_overlap_class##c.total_experience  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m4: qui nbreg totyr_patcit  min_experience inv_overlap_class inv_ab_diff total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m5: qui nbreg totyr_patcit   c.min_experience##c.inv_overlap_class inv_ab_diff   total_class_patent   total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m6: qui nbreg totyr_patcit c.inv_ab_diff##c.min_experience inv_overlap_class total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
esttab  m1  m2 m3 m4 m5 m6, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps

eststo m1: qui nbreg totyr_patcit  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m2: qui nbreg totyr_patcit   total_experience total_class_patent inv_age*  inv_pat_id* post_grant i.since_app i.year, vce(r)
eststo m3: qui nbreg totyr_patcit  inv_overlap_class total_class_patent inv_age*  inv_pat_id*   post_grant i.since_app i.year, vce(r)
eststo m4: qui nbreg totyr_patcit inv_ab_diff  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m5: qui nbreg totyr_patcit total_experience  inv_overlap_class inv_ab_diff    total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m6: qui nbreg totyr_patcit c.inv_ab_diff##c.total_experience inv_overlap_class total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m7: qui nbreg totyr_patcit inv_ab_diff c.inv_overlap_class##c.total_experience  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m8: qui nbreg totyr_patcit c.inv_ab_diff##c.total_experience total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m9: qui nbreg totyr_patcit   c.inv_overlap_class##c.total_experience   total_class_patent   total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
eststo m10: qui nbreg totyr_patcit   c.inv_overlap_class##c.total_experience  c.inv_ab_diff##c.total_experience  total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
esttab m1  m2 m3 m4 m5 m6 m7  m8 m9 m10, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps



eststo m2: qui reg totyr_patcit  c.inv_ab_diff##c.total_experience inv_overlap_class   total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
esttab m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps

eststo m2: qui reg totyr_patcit  c.inv_ab_diff##c.total_experience  inv_overlap_class total_class_patent inv_age*  inv_pat_id*  post_grant i.since_app i.year, vce(r)
esttab m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps


 quietly margins, at(total_experience=(1(1)12) inv_ab_diff = (0, 1, 5))
marginsplot, noci scheme(sj) ytitle("Predicted cites")

 quietly margins, at(total_experience=(1(1)12) inv_ab_diff = (0, 1, 3))
marginsplot, noci scheme(sj) ytitle("Predicted cites")


 quietly margins, at(total_experience=(1(1)12) inv_overlap_class = (0, 1, 3))
marginsplot, noci scheme(sj) ytitle("Predicted cites")


 quietly margins , at(inv_overlap_class=(1(1)7) )
marginsplot, noci scheme(sj) ytitle("Predicted cites")


 quietly margins c.inv_overlap_class#c.inv_overlap_class

marginscontplot reducyrs, ci


drop if inv_pat_id > 2 | inv_pat_id_1 > 2

//table 2
duplicates drop patent, force
reg total_experience postmove_pat premove_pat total_class_patent i.cited_yr if neither_pat == 0
reg inv_overlap_class postmove_pat premove_pat total_class_patent i.cited_yr if neither_pat == 0
reg inv_ab_diff postmove_pat premove_pat total_class_patent i.cited_yr if neither_pat == 0

reg total_experience postmove_pat  total_class_patent i.cited_yr if postmove_pat == 1 | premove_pat == 1
reg inv_overlap_class postmove_pat  total_class_patent i.cited_yr if postmove_pat == 1 | premove_pat == 1
reg inv_ab_diff postmove_pat  total_class_patent i.cited_yr if postmove_pat == 1 | premove_pat == 1

//movement
nbreg  totyr_patcit  inv_ab_diff  total_class_patent postmove postmove_1 inv_age* single_acc* inv_pat_id*  post_grant prior_coll_proxy i.since_app i.year, vce(r)
nbreg  totyr_patcit  inv_ab_diff  total_class_patent premove premove_1 inv_age* single_acc* inv_pat_id*  post_grant prior_coll_proxy i.since_app i.year, vce(r)
nbreg  totyr_patcit  inv_ab_diff  total_class_patent premove premove_1 postmove postmove_1  inv_age* single_acc* inv_pat_id*  post_grant prior_coll_proxy i.since_app i.year, vce(r)

nbreg  totyr_patcit matchingclasses matchingclasses_1 inv_overlap_class inv_ab_diff  total_class_patent postmove postmove_1 inv_age* single_acc* inv_pat_id*  post_grant prior_coll_proxy i.since_app i.year, vce(r)



close_dist





	
log close
