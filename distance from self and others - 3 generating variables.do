/*
///////////////////////////////////////////////distance from self and others - generating variables 
	By Erin Fahrenkopf, Tepper, CMU

/////////////////////////(1) create base datasets with inventor patents - premove 
/////////////////////////(2) create base datasets with inventor patents - postmove 
/////////////////////////(3) create base dataset with postmove org premove patents
/////////////////////////(4) generate dependent variables
/////////////////////////(5) generate independent variables - distance to self
/////////////////////////(6) generate independent variables - distance to others
/////////////////////////(7) generate control variables

///TODO - add in control sample to calculation of dep, control and possibly the inde variables

Created: 		12/9/15
Last updated:   3/25/16
////////////////////////////////////////////////////////////////////////////////////////////////
*/

//////////////////////Begin
	clear
	clear matrix
	set 	more off
	log 	using "C:\Users\Erin.Tesla\Box Sync\Dissertation data\STATA work\logs\distance from self and others - generating variables .log", text replace
	adopath + "C:\Users\Erin.Tesla\Box Sync\Dissertation data\STATA work\Functions"

	

 	
/////////////////////////(1) create base datasets with inventor patents - premove
//grab sample
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inventor sample.dta", clear
////pull inventor's other patents
			merge 1:m unique_inventor_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\disamb_no_postpolishing.dta"
			keep_matched //all in master should match
					keep unique_inventor_id first_yrassignee first_postmove_ass patent appyear
			bysort unique_inventor_id (appyear): gen inv_firstyr = appyear[1] //inv_firstyr == inventor first yr of patenting
			keep if appyear <= first_yrassignee //keep only patents prior to first patent at assignee 
			merge m:1 patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\assignee by patent.dta"
			keep_matched //all in master should match
					gen assignee = organization
///////////clean up assignee names a little more than disambiguation
			run "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\assignee cleanup_postmove org.do"
			drop if assignee == first_postmove_ass
			bysort unique_inventor_id: gen inv_totpat = _N //inv_totpat== total # of patents premove
////////////////keep those that are 10 yrs prior to move yr
			keep if (first_yrassignee - appyear) <= 10
					keep  unique_inventor_id first_yrassignee first_postmove_ass appyear patent inv_firstyr inv_totpat
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv premove pat.dta", replace
			duplicates drop unique_inventor_id , force
					drop patent appyear
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv premove attributes.dta", replace

/////////////////////////(2) create base datasets with inventor patents - postmove 
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inventor sample.dta", clear
//pull all inventors patents
			merge 1:m unique_inventor_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\disamb_no_postpolishing.dta"
			keep_matched //all in master should match
					keep unique_inventor_id first_yrassignee first_postmove_ass patent appyear
//keep only postmove patents
			keep if appyear >= first_yrassignee
//keep only those at the move to firm
			merge m:1 patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\assignee by patent.dta"
			keep_matched //all in master should match
					gen assignee = organization
///////////clean up assignee names a little more than disambiguation
			run "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\assignee cleanup_postmove org.do"
			keep if assignee == first_postmove_ass
//keep those that are 5 yrs after first patent at move to firm
			keep if (appyear - first_yrassignee) <= 5
			bysort unique_inventor_id: gen inv_postmovepat = _N //inv_postmovepat== total # of patents postmove
			*sum inv_postmovepat //this should be greater or equal to 2 but it is not --> did not filter on the length of time at the dest firm before
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv postmove pat.dta", replace

/////////////////////////(3) create base dataset with postmove org premove patents
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_move to firms' patents.dta", clear

/////////////////////////(4) generate dependent variables
//simple -  annual count of post move patents for 5 yrs after move
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv postmove pat.dta", clear
			collapse (count) patent, by (unique_inventor_id appyear)
					rename patent totyr_pat
					rename appyear year
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_dep var - counts.dta", replace
//citation weighted - weigh patents by citations in next 5 yrs (maybe could try with 10 yrs too) 
//use all post move patents and their appyr 
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv postmove pat.dta", clear
//grab all citations and aggregate
			joinby patent using "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\citations 7510 with dates.dta"
//NOTE: last yr that I have citations for is 2010 so cannot look at yrs after 2005
			keep if cityear - appyear <= 5 
			collapse (count) patent, by (unique_inventor_id appyear)	//aggregate by inventor and yr of citing patent
					rename patent totyr_patcit //these counts seem really  high
					rename appyear year
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_dep var - patcits.dta", replace

/////////////////////////(5) generate independent variables - distance to self
////////////////////get all premove patents' classifications
//use premove patents 
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv premove pat.dta", clear
			//this drops all the patents that do not have classifications
			joinby patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_uspc.dta" //file goes to 2010
			duplicates drop unique_inventor_id patent mainclass_id, force
			bysort unique_inventor_id mainclass_id: gen num_inclass = _N //num_inclass == count of patents in each classification for inventor's premove patents
			bysort unique_inventor_id: gen total_preclasses = _N //total_preclasses == count of classifications any inventor pre-move patent falls into
			duplicates drop  unique_inventor_id mainclass_id, force //unique set of classes per inventor for each class inventor is in
			bysort unique_inventor_id: gen num_preclasses = _N //num_preclasses == num unique premove classes inventor has patented in
			gen pj_pre = num_inclass/ total_preclasses // pj_pre = class share that the class makes up for the inventor
			bysort unique_inventor_id: egen sum_pj_pre2 = sum(pj_pre*pj_pre) //sum_pj_pre2 == HHI premove classes
					keep unique_inventor_id first_yrassignee first_postmove_ass mainclass_id num_preclasses num_inclass pj_pre sum_pj_pre2
					rename mainclass_id premove_class
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv premove pat w class.dta", replace
			duplicates drop unique_inventor_id, force
					keep unique_inventor_id num_preclasses first_yrassignee first_postmove_ass sum_pj_pre2
					rename sum_pj_pre2 premove_HHI
					*tabstat premove_HHI, statistics(mean sd  n max min p25 p50 p75 p90)
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_temp1.dta", replace
////////////////////get all postmove patents' classifications
//use post move patents and do by yr
//do the same thing for the postmove patents by yr
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv postmove pat.dta", clear
			//this keeps only patents that have classifications
			joinby patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_uspc.dta"
			duplicates drop unique_inventor_id patent mainclass_id, force
			bysort unique_inventor_id appyear mainclass_id: gen num_inclasspost = _N //num_inclasspost == count of patents in each classification for inventor's postmove patents
			bysort unique_inventor_id appyear: gen total_postclasses = _N //total_postclasses == count of classifications any inventor post-move patent falls into in a year
			duplicates drop  unique_inventor_id appyear mainclass_id, force //unique set of classes that inventor patents in a yr
			bysort unique_inventor_id appyear: gen num_postclasses = _N //num_postclasses == num postmove classes inventor has patented in
			gen pj_post = num_inclasspost/ total_postclasses  //pj_post = class share that the class makes up for the inventor
			bysort unique_inventor_id appyear: egen sum_pj_post2 = sum(pj_post*pj_post)
					keep unique_inventor_id first_yrassignee first_postmove_ass mainclass_id num_postclasses num_inclasspost appyear pj_post sum_pj_post2
					rename mainclass_id postmove_class
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv postmove pat w class.dta", replace
			duplicates drop unique_inventor_id appyear, force 
					keep unique_inventor_id appyear num_postclasses
					rename appyear year
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_postmove class.dta", replace
////////generate overlap - basic count
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv postmove pat w class.dta", clear
					rename postmove_class premove_class // change so i can merge
			merge m:1 unique_inventor_id premove_class using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv premove pat w class.dta"
			keep_matched //keep only classes that are the same pre and most move
			collapse (count) num_overlapself = num_inclasspost , by(unique_inventor_id appyear) //num_overlapself == # class overlap pre-post move 
					rename appyear year
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_overlap_self.dta", replace
//////////generate overlap - given concentration
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv postmove pat w class.dta", clear
					rename postmove_class premove_class
			merge m:1 unique_inventor_id premove_class using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv premove pat w class.dta"
			keep_matched //keep only classes that are the same pre and most move
			duplicates drop unique_inventor_id appyear, force //keep one obs per inventor inventor, if no class overlap then o_post_pre = 0
			bysort unique_inventor_id appyear: egen sum_pj_post_pre = sum(pj_post*pj_pre)
			gen o_post_pre = sum_pj_post_pre / sum_pj_post2 //CHECK IF DENOMINATOR SHOULD BE ZERO
			gen o_post_pre_1 = sum_pj_post_pre / ((sum_pj_post2*sum_pj_pre2)^.5) //CHECK IF DENOMINATOR SHOULD BE ZERO
					keep unique_inventor_id appyear o_post_pre o_post_pre_1 
					rename appyear year 
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_overlap_self concentrated.dta", replace
//////////generate overlap - fancy overlap
//look at ideal methodology.doc write-up for calculation

/////////////////////////(6) generate independent variables - distance to others 
//use premove patent at firm move to  and grab their classifications
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_move to firms' patents.dta", clear
			joinby patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_uspc.dta"
			duplicates drop unique_inventor_id patent mainclass_id, force
//mark count of patents in each classification
			bysort unique_inventor_id mainclass_id: gen num_inclassorg = _N //num_inclassorg == count of patents in each classification for inventor's move to org
			bysort unique_inventor_id: gen total_orgclasses = _N //total_orgclasses == count of classifications any inventor post-move's org's patent falls into 
			duplicates drop  unique_inventor_id mainclass_id, force //unique set of classes per inventor move
//mark number of different classifications
			bysort unique_inventor_id: gen num_orgclasses = _N //num_orgclasses == num premove class org has patented in
			gen pj_org = num_inclassorg / total_orgclasses  //pj_org = class share that the class makes up for the inventor
			bysort unique_inventor_id: egen sum_pj_org2 = sum(pj_org*pj_org)
					keep unique_inventor_id first_postmove_ass mainclass_id num_orgclasses num_inclassorg pj_org sum_pj_org2
					rename mainclass_id org_class
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv org pat w class.dta", replace
			duplicates drop unique_inventor_id, force
					keep unique_inventor_id num_orgclasses
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_temp2.dta", replace
////////generate overlap - basic count
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv org pat w class.dta", clear
					rename org_class premove_class // change so i can merge
			merge 1:1 unique_inventor_id premove_class using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv premove pat w class.dta"
			keep_matched //keep only classes that are the same premove for inventor and for move to org
			collapse (count) num_overlapothers = num_inclassorg, by(unique_inventor_id) //num_overlapothers == # class overlap inventor premove and move to org premove
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_overlap_others.dta", replace
////////generate overlap - given concentration
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv org pat w class.dta", clear
					rename org_class premove_class // change so i can merge
			merge m:1 unique_inventor_id premove_class using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv premove pat w class.dta"
			keep_matched //keep only classes that are the same premove for inventor and for move to org
			bysort unique_inventor_id: egen sum_pj_org_pre = sum(pj_org*pj_pre)
			gen o_org_pre = sum_pj_org_pre / sum_pj_pre2
			gen o_org_pre_1 = sum_pj_org_pre / ((sum_pj_org2*sum_pj_pre2)^.5) //CHECK IF DENOMINATOR SHOULD BE ZERO
			duplicates drop unique_inventor_id, force
					keep unique_inventor_id  o_org_pre  o_org_pre_1 
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_overlap_other concentrated.dta", replace
//////////generate overlap - fancy overlap
//look at ideal methodology.doc write-up for calculation

/////////////////////////(7) generate control variables
//////////postmove annual collaboration
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv postmove pat.dta", clear
	*append using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_control pat.dta"
			merge m:1 patent using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\inventor_count.dta"
			keep_matched //all in master should match
					replace inv_count = inv_count - 1
			collapse (sum) collab_yr = inv_count, by(unique_inventor_id appyear)
					keep unique_inventor_id appyear collab_yr
					rename appyear year
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_collab.dta", replace
///////////hiring firm extent premove knowledge stocks
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_move to firms' patents.dta", clear
			duplicates drop unique_inventor_id, force
					keep unique_inventor_id ass_patent_precount ass_patent_postcount
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_hiring org.dta", replace




log close

