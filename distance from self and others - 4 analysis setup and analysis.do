/*
///////////////////////////////////////////////distance from self and others - analysis setup and analysis 
	By Erin Fahrenkopf, Tepper, CMU

The code does the following:

 (1)////////////////////// identifies the appropriate sample
 (2)////////////////////// turns sample into by year	
 (3)////////////////////// grabs and variables - inde, depend, control	
 (4)////////////////////// generates additional variables
 (5)////////////////////// basic analysis
 (6)////////////////////// regression analysis	
	

Created: 		12/15/15
Last updated:   1/12/16
////////////////////////////////////////////////////////////////////////////////////////////////
*/

//////////////////////Begin
	clear
	clear matrix
	set 	more off
	log 	using "C:\Users\Erin.Tesla\Box Sync\Dissertation data\STATA work\logs\distance from self and others - generating variables .log", text replace
	adopath + "C:\Users\Erin.Tesla\Box Sync\Dissertation data\STATA work\Functions"
	
///////////////////(1)////////////////////// identifies the appropriate sample
//baseline sample
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inventor sample.dta", clear
//drop those that do not have premove classes or 
			merge 1:1 unique_inventor_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_temp1.dta"
			keep_matched // all in using should match
//drop those who move to org does not have premove classes
			merge 1:1 unique_inventor_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_temp2.dta"
			keep_matched // all in using should match
			
//////////////// (2)////////////////////// turns sample into by year				
//make one obs for first 5 yrs after first patent
			make_timeseries 5 "unique_inventor_id" first_yrassignee //make it timeseries, one obs per year for each move
			drop if year >= 2010 //seems like I can go until 2010 unless i am using citation weighted patents

//////////////// (3)////////////////////// grabs and variables - inde, depend, control	
////////inde variables
			merge 1:1 unique_inventor_id year using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_overlap_self.dta"
			drop_using //
			replace num_overlapself = 0 if num_overlapself ==.
			merge 1:1 unique_inventor_id year using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_overlap_self concentrated.dta"
			drop_using //
			replace o_post_pre = 0 if o_post_pre == .
			replace o_post_pre_1 = 0 if o_post_pre_1 == .
			merge m:1 unique_inventor_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_overlap_others.dta"
			drop_using
			replace num_overlapothers = 0 if num_overlapothers == .
			merge m:1 unique_inventor_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_overlap_other concentrated.dta"
			drop_using
					replace o_org_pre = 0 if o_org_pre == .
					replace o_org_pre_1 = 0 if o_org_pre_1 == .
			merge 1:1 unique_inventor_id year using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_postmove class.dta"
			drop_using //
			replace num_postclasses = 0 if num_postclasses == . //num_postclasses == number of postmove classes
			gen share_overlapself = num_overlapself / num_postclasses
					replace share_overlapself = 0 if share_overlapself ==.
			gen share_overlapothers = num_overlapothers / num_preclasses
///////dep variables
			merge 1:1 unique_inventor_id year using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_dep var - counts.dta"
			drop_using //
			replace totyr_pat = 0 if totyr_pat == .
			merge 1:1 unique_inventor_id year using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_dep var - patcits.dta"
			drop_using //
			replace totyr_patcit = 0 if totyr_patcit == .
			replace totyr_patcit = . if year >= 2005
//////control variables
			merge m:1 unique_inventor_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inv premove attributes.dta"
			drop_using
			gen ln_total_pats = ln( inv_totpat) // ln_total_pats == log of premove patent count, select on those that have at least one		
			merge m:1 unique_inventor_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_hiring org.dta"
			drop_using
			gen ln_firm_know_stock = ln(ass_patent_precount) //extent of premove firm knowledge stocks -->ln_firm_know_stock
			merge m:1 unique_inventor_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_inventor orig org.dta"
			drop_using //all in master should match
			egen orig_id = group(troubled_org) //dissolved firm dummy
			merge 1:1 unique_inventor_id year using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\data work\data files\distance from self and others_collab.dta"
			drop_using //
			replace collab_yr = 0 if collab_yr == .
			gen ln_prior_covinventor = ln(collab_yr  + 1)
			gen coinventor = 1 if collab_yr > 0
					replace coinventor = 0 if coinventor == .
			gen specialist = 1 if premove_HHI >.68 // for median > .44
					replace specialist = 0 if specialist == .
			gen generalist = 1 if premove_HHI < .27
					replace generalist = 0 if generalist == .
			gen time_atfirm = year - first_yrassignee // time_atfirm == year at firm
			gen inv_age = year - inv_firstyr // in_age == inventor age at time of appyear of focal patent
			gen first_yr = 1 if time_atfirm == 0 
					replace first_yr = 0 if first_yr == . 
/*  //time since dissolving
keep if ///
agg_name == "kodak" & (final_yratfirm >= 1985 & final_yratfirm >= 1990) | ///
agg_name == "kodak" & (final_yratfirm >= 1997 & final_yratfirm >= 1999) | ///
agg_name == "ibm" & (final_yratfirm >= 1993 & final_yratfirm >= 1995) | ///
agg_name == "at&t" & (final_yratfirm >= 1984 & final_yratfirm >= 1986) | ///
agg_name == "at&t" & (final_yratfirm >= 1996 & final_yratfirm >= 1998) | ///
agg_name == "boeing" & (final_yratfirm >= 1998 & final_yratfirm >= 2003) | ///
agg_name == "lucent" & (final_yratfirm >= 2001 & final_yratfirm >= 2003) | ///
agg_name == "mci" & (final_yratfirm >= 2002 & final_yratfirm >= 2004) | ///
agg_name == "compaq" & (final_yratfirm >= 2002 & final_yratfirm >= 2004) | ///
agg_name == "hp" & (final_yratfirm >= 2002 & final_yratfirm >= 2004) 
*/
			
		drop if	totyr_pat == 0
		*drop if time_atfirm > 0 
//////// (4)////////////////////// generates additional variables
tabstat totyr_pat totyr_patcit, statistics(mean sd  n max min p25 p50 p75 p90)
sum totyr_pat totyr_patcit
cor totyr_pat totyr_patcit
histogram totyr_pat  
histogram totyr_patcit  

drop if totyr_pat  > 15 |  totyr_patcit  > 500


cor  num_overlapself o_post_pre share_overlapself num_overlapothers   o_org_pre share_overlapothers

sum    share_overlapself  o_post_pre_1
tabstat    share_overlapself o_post_pre_1, statistics(mean sd  n max min p25 p50 p75 p90)
cor  num_overlapself share_overlapself  o_post_pre_1 

histogram num_overlapself 
histogram o_post_pre_1  
histogram share_overlapself  //overlap self
egen mean = mean(totyr_pat), by(share_overlapself )
egen tag = tag(share_overlapself )
twoway line mean share_overlapself  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag


egen mean = mean(totyr_pat), by(o_post_pre)
egen tag = tag(o_post_pre)
twoway line mean o_post_pre  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag


sum  share_overlapothers o_org_pre_1 
tabstat  share_overlapothers o_org_pre_1 , statistics(mean sd  n max min p25 p50 p75 p90)
cor  num_overlapothers share_overlapothers o_org_pre_1
histogram num_overlapothers
histogram o_org_pre_1  
histogram share_overlapothers //overlap others






egen mean = mean(totyr_pat), by(num_overlapothers  )
egen tag = tag(num_overlapothers )
twoway line mean num_overlapothers   if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag


egen mean = mean(totyr_pat), by(o_org_pre_1)
egen tag = tag(o_org_pre)
twoway line mean o_org_pre_1  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag


sum inv_age time_atfirm ln_prior_covinventor year ln_firm_know_stock  inv_totpat
tabstat  inv_age time_atfirm ln_prior_covinventor year ln_firm_know_stock  inv_totpat num_postclasses , statistics(mean sd  n max min p25 p50 p75 p90)
cor  inv_age time_atfirm ln_prior_covinventor year ln_firm_know_stock  inv_totpat

histogram inv_totpat
tabstat  inv_totpat , statistics(mean sd  n max min p25 p50 p75 p90)
egen mean = mean(totyr_pat), by(inv_totpat )
egen tag = tag(inv_totpat )
twoway line mean inv_totpat  if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag

drop if inv_totpat > 20 | inv_totpat < 3 

histogram premove_HHI
tabstat  premove_HHI , statistics(mean sd  n max min p25 p50 p75 p90)
egen mean = mean(totyr_pat), by(premove_HHI)
egen tag = tag(premove_HHI )
twoway line mean premove_HHI if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag

histogram num_preclasses
tabstat  num_preclasses , statistics(mean sd  n max min p25 p50 p75 p90)
egen mean = mean(totyr_pat), by(num_preclasses)
egen tag = tag(num_preclasses)
twoway line mean num_preclasses if tag, sort
*graph twoway scatter num_overlapclass appyear 
drop mean tag




sum inv_age time_atfirm coinventor year ln_firm_know_stock  inv_totpat specialist generalist
tabstat  inv_totpat num_postclasses , statistics(mean sd  n max min p25 p50 p75 p90)
cor  inv_age time_atfirm coinventor year ln_firm_know_stock  inv_totpat specialist generalist



//think i should log the o variables

///////////binary variables - basic
/////////based on quantiles	

			gen overlap_self = 1  if share_overlapself  == 1 //== 1 //>=.5 // >0
					replace overlap_self = 0 if overlap_self  == .
			gen distance_self = 1  if share_overlapself  == 0 //== 1 //>=.5 // >0
					replace distance_self = 0 if distance_self  == .		
					
			gen overlap_others = 1  if share_overlapothers  == 1
					replace overlap_others = 0 if overlap_others == .
			gen distance_others = 1 if share_overlapothers < .41
					replace distance_others = 0 if distance_others == .
			
			gen close_s_close_o = 1 if   distance_self == 0 & overlap_others == 1
					replace close_s_close_o  = 0 if close_s_close_o == .
			gen close_s_dist_o = 1 if   distance_self  == 0 & distance_others == 1
					replace close_s_dist_o = 0 if close_s_dist_o == .
			gen dist_s_close_o = 1 if   distance_self == 1 & overlap_others == 1
					replace dist_s_close_o = 0 if dist_s_close_o == .
			gen dist_s_dist_o = 1 if  distance_self == 1 & distance_others == 1
					replace dist_s_dist_o = 0 if dist_s_dist_o == .


tabstat overlap_self overlap_others distance_others, statistics(mean sd  n max min p25 p50 p75 p90)
sum overlap_self overlap_others distance_others
cor overlap_self overlap_others	distance_others

tabstat close_s_close_o close_s_dist_o dist_s_close_o dist_s_dist_o, statistics(mean sd  n max min p25 p50 p75 p90)
sum close_s_close_o close_s_dist_o dist_s_close_o dist_s_dist_o
cor close_s_close_o close_s_dist_o dist_s_close_o dist_s_dist_o	

/////////based on standard deviations
/*
			gen overlap_self = 1  if share_overlapself > (.2731132 + .3960472) 
					replace overlap_self = 0 if num_overlapself == 0
			gen overlap_others = 1  if share_overlapothers >= (1 )
					replace overlap_others = 0 if overlap_others == .
			
			gen close_s_close_o = 1 if   overlap_self == 1 & overlap_others == 1
					replace close_s_close_o  = 0 if close_s_close_o == .
			gen close_s_dist_o = 1 if   overlap_self == 1 & overlap_others == 0
					replace close_s_dist_o = 0 if close_s_dist_o == .
			gen dist_s_close_o = 1 if   overlap_self == 0 & overlap_others == 1
					replace dist_s_close_o = 0 if dist_s_close_o == .
			gen dist_s_dist_o = 1 if  overlap_self == 0 & overlap_others == 0
					replace dist_s_dist_o = 0 if dist_s_dist_o == .


tabstat overlap_self overlap_others, statistics(mean sd  n max min p25 p50 p75 p90)
sum overlap_self overlap_others
cor overlap_self overlap_others	

tabstat close_s_close_o close_s_dist_o dist_s_close_o dist_s_dist_o, statistics(mean sd  n max min p25 p50 p75 p90)
sum close_s_close_o close_s_dist_o dist_s_close_o dist_s_dist_o
cor close_s_close_o close_s_dist_o dist_s_close_o dist_s_dist_o	
*/
///////////binary variables - concentration
			gen overlap_self_o = 1  if  o_post_pre_1 > .55 //>= .55 //.19 //
					replace overlap_self_o = 0 if overlap_self_o == .
			gen distance_self_o = 1  if o_post_pre_1  == 0 //== 1 //>=.5 // >0
					replace distance_self_o = 0 if distance_self_o  == .	
			gen overlap_others_o = 1  if o_org_pre_1 >=.7
					replace overlap_others_o = 0 if overlap_others_o == .
			gen distance_others_o = 1 if  o_org_pre_1 < .08
					replace distance_others_o = 0 if distance_others_o == .
			
			gen o_close_s_close_o = 1 if   distance_self_o == 0 & distance_others_o == 0
					replace o_close_s_close_o  = 0 if o_close_s_close_o == .
			gen o_close_s_dist_o = 1 if   distance_self_o == 0 & distance_others_o == 1
					replace o_close_s_dist_o = 0 if o_close_s_dist_o == .
			gen o_dist_s_close_o = 1 if   distance_self_o == 1 & distance_others_o == 0
					replace o_dist_s_close_o = 0 if o_dist_s_close_o == .
			gen o_dist_s_dist_o = 1 if  distance_self_o == 1 & distance_others_o == 1
					replace o_dist_s_dist_o = 0 if o_dist_s_dist_o == .


tabstat overlap_self_o overlap_others_o, statistics(mean sd  n max min p25 p50 p75 p90)
sum overlap_self_o overlap_others_o
cor overlap_self_o overlap_others_o	

tabstat o_close_s_close_o o_close_s_dist_o o_dist_s_close_o o_dist_s_dist_o, statistics(mean sd  n max min p25 p50 p75 p90)
sum o_close_s_close_o o_close_s_dist_o o_dist_s_close_o o_dist_s_dist_o
cor o_close_s_close_o o_close_s_dist_o o_dist_s_close_o o_dist_s_dist_o	
///////////binary variables - in other patent data
		
////////////// (5)////////////////////// basic analysis


*******************crosstabs
*************** close to self
******* basic variables
ttest totyr_pat, by(distance_self)
ttest totyr_pat, by(overlap_self)

ttest totyr_patcit, by(distance_self)
ttest totyr_patcit, by(overlap_self)


graph bar totyr_pat , over(overlap_self, relabel(1 "Distant to self" 2 "Close to self"))
ttest totyr_patcit, by(distance_self)
graph bar totyr_patcit, over(overlap_self, relabel(1 "Distant to self" 2 "Close to self"))

******concentration variables
ttest totyr_pat, by(overlap_self_o)
graph bar totyr_pat , over(overlap_self_o, relabel(1 "Distant to self" 2 "Close to self"))
ttest totyr_patcit, by(overlap_self_o)
graph bar totyr_patcit, over(overlap_self_o, relabel(1 "Distant to self" 2 "Close to self"))

********************************* close to others
ttest totyr_pat, by(distance_others)
ttest totyr_pat, by(overlap_others)

ttest totyr_patcit, by(distance_others)
ttest totyr_patcit, by(overlap_others)

graph bar totyr_pat , over(overlap_others, relabel(1 "Distant to others" 2 "Close to others"))

graph bar totyr_pat , over(distance_others, relabel(1"Close to others"  2 "Distant to others"))
graph bar totyr_patcit , over(distance_others, relabel(1"Close to others"  2 "Distant to others"))


******************interaction
ttest totyr_pat, by(close_s_close)
ttest totyr_pat , by(dist_s_close)
ttest totyr_pat, by(close_s_dist)
graph bar totyr_pat , over(close_s_dist_o, relabel(1 "All others" 2 "Close to self & distance to others")) 


graph bar totyr_pat , over(distance_others, relabel(1 "Close to others" 2 "Distant to others")) ///
		over(distance_self, relabel(1 "Close to self" 2 "Distant to self")) ///
		ytitle("Patent productivity") ///
		title("Average num patents produced in a yr by distance from self and others") 


graph bar totyr_patcit , over(distance_others, relabel(1 "Close to others" 2 "Distant to others")) ///
		over(distance_self, relabel(1 "Close to self" 2 "Distant to self")) ///
		ytitle("Innovativeness") ///
		title("Average num citations on pats produced in a yr by distance from self and others") 		
////////////////////(6)////////////////////// regression analysis	

/////////control variables
****productivity
eststo m1: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat generalist , vce(r)
eststo m2: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat generalist i. orig_id i.year  , vce(r)
eststo m3: qui reg  totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat  generalist i. orig_id i.year  , vce(r)
eststo m4: qui nbreg   totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat generalist i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

****innovativeness
eststo m1: qui nbreg totyr_patcit  inv_age time_atfirm  ln_firm_know_stock  inv_totpat  generalist coinventor , vce(r)
eststo m2: qui nbreg totyr_patcit  inv_age time_atfirm  ln_firm_know_stock  inv_totpat  generalist coinventor i. orig_id i.year  , vce(r)
eststo m3: qui reg  totyr_patcit inv_age time_atfirm  ln_firm_know_stock  inv_totpat generalist coinventor i. orig_id i.year  , vce(r)
eststo m4: qui poisson  totyr_patcit inv_age time_atfirm  ln_firm_know_stock  inv_totpat  generalist coinventor i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	



///////testing h1
******productivity
eststo m1: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_self i. orig_id i.year  , vce(r)
eststo m2: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_self_o  i. orig_id i.year  , vce(r)
esttab  m1  m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

******innovativeness

eststo m1: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist distance_self i. orig_id i.year  , vce(r)
eststo m2: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist distance_self_o  i. orig_id i.year  , vce(r)
esttab  m1  m2, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


///////testing main effect of distance otherrs
******productivity
eststo m1: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_others i. orig_id i.year  , vce(r)
eststo m2: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_others_o  i. orig_id i.year  , vce(r)
esttab  m1  m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

******innovativeness

eststo m1: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist distance_others i. orig_id i.year  , vce(r)
eststo m2: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist distance_others_o  i. orig_id i.year  , vce(r)
esttab  m1  m2, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

///////testing Just_moved*domain_experience should be significantly positive +
******productivity
eststo m1: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist c.distance_self##c.first_yr i. orig_id i.year  , vce(r)
eststo m2: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist c.distance_self_o##c.first_yr  i. orig_id i.year  , vce(r)
esttab  m1  m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

******innovativeness

eststo m1: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist c.distance_self##c.first_yr i. orig_id i.year  , vce(r)
eststo m2: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist c.distance_self_o##c.first_yr  i. orig_id i.year  , vce(r)
esttab  m1  m2, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


////////testing Others_sameexperience on sample with domain_experience = 1 expect to be ns //seems like actually Others_sameexperience is negative
///////////////Others_sameexperience on sample with domain_experience = 0 expect to be positive 

******productivity

fvset base 1 orig_id
fvset base 1 year
 
eststo m1: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist overlap_others  i. orig_id i.year if distance_self == 1 , vce(r)
eststo m2: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist overlap_others i. orig_id i.year if distance_self == 0 , vce(r)
eststo m3: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist c.distance_others##c.distance_self i. orig_id i.year , vce(r)
esttab  m1  m2 m3 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

eststo m1: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist overlap_others_o  i. orig_id i.year if distance_self_o == 1 , vce(r)
eststo m2: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist overlap_others_o i. orig_id i.year if distance_self_o == 0 , vce(r)
eststo m3: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist c.overlap_others_o##c.distance_self_o i. orig_id i.year , vce(r)
esttab  m1  m2 m3 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

eststo m1: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_others dist_s_close i. orig_id i.year  , vce(r)
eststo m2: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist  distance_self close_s_dist i. orig_id i.year  , vce(r)
esttab  m1  m2 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

eststo m1: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_others_o o_dist_s_close_o i. orig_id i.year  , vce(r)
eststo m2: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist  distance_self_o o_close_s_dist_o i. orig_id i.year  , vce(r)
esttab  m1  m2  , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


******innovativeness
eststo m1: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist overlap_others i. orig_id i.year if distance_self == 1 , vce(r)
eststo m2: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist overlap_others  i. orig_id i.year if distance_self == 0 , vce(r)
eststo m3: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist share_overlapothers   i. orig_id i.year if distance_self == 1   , vce(r)
eststo m4: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist share_overlapothers   i. orig_id i.year if distance_self == 0 , vce(r)
eststo m5: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist c.overlap_others##c.distance_self i. orig_id i.year , vce(r)
eststo m6: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist c.share_overlapothers##c.distance_self   i. orig_id i.year , vce(r)
esttab  m1  m2 m3 m4 m5 m6, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

eststo m1: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist overlap_others_o  i. orig_id i.year if distance_self_o == 1 , vce(r)
eststo m2: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist overlap_others_o  i. orig_id i.year if distance_self_o == 0 , vce(r)
eststo m3: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist o_org_pre_1   i. orig_id i.year if distance_self_o == 1   , vce(r)
eststo m4: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist o_org_pre_1   i. orig_id i.year if distance_self_o == 0 , vce(r)
eststo m5: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist c.overlap_others_o##c.distance_self_o i. orig_id i.year , vce(r)
eststo m6: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist c.o_org_pre_1##c.distance_self_o   i. orig_id i.year , vce(r)
esttab  m1  m2 m3 m4 m5 m6, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


eststo m1: qui nbreg totyr_patcit inv_age time_atfirm coinventor  ln_firm_know_stock  inv_totpat specialist distance_others dist_s_close i. orig_id i.year  , vce(r)
eststo m2: qui nbreg totyr_patcit inv_age time_atfirm coinventor   ln_firm_know_stock  inv_totpat specialist  overlap_self close_s_dist i. orig_id i.year  , vce(r)
eststo m3: qui nbreg totyr_patcit inv_age time_atfirm coinventor   ln_firm_know_stock  inv_totpat specialist distance_self close_s_dist i. orig_id i.year   , vce(r)
eststo m4: qui nbreg totyr_patcit inv_age time_atfirm coinventor   ln_firm_know_stock  inv_totpat specialist distance_self distance_others close_s_dist i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

eststo m1: qui nbreg totyr_patcit inv_age time_atfirm coinventor   ln_firm_know_stock  inv_totpat specialist overlap_others_o o_dist_s_close_o i. orig_id i.year  , vce(r)
eststo m2: qui nbreg totyr_patcit inv_age time_atfirm coinventor   ln_firm_know_stock  inv_totpat specialist  overlap_self_o o_close_s_dist_o i. orig_id i.year  , vce(r)
eststo m3: qui nbreg totyr_patcit inv_age time_atfirm coinventor  ln_firm_know_stock  inv_totpat specialist o_org_pre_1  o_dist_s_close_o i. orig_id i.year   , vce(r)
eststo m4: qui nbreg totyr_patcit inv_age time_atfirm coinventor  ln_firm_know_stock  inv_totpat specialist o_org_pre_1  o_close_s_dist_o i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4 , b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


///////testing Others_diffexperience on sample with domain_experience = 1 expect to be positive
/////////////////////Others_diffexperience on sample with domain_experience = 0 expect to be negative
 


******productivity

fvset base 1 orig_id
fvset base 1 year
 
eststo m1: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_others i. orig_id i.year if distance_self == 1 , vce(r)
eststo m2: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_others i. orig_id i.year if distance_self == 0 , vce(r)
eststo m3: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_others_o  i. orig_id i.year if distance_self == 1  , vce(r)
eststo m4: qui poisson totyr_pat inv_age time_atfirm  ln_firm_know_stock  inv_totpat specialist distance_others_o i. orig_id i.year  if distance_self == 0 , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


******innovativeness
eststo m1: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist##distance_others i. orig_id i.year if distance_self == 1 , vce(r)
eststo m2: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist##distance_others  i. orig_id i.year if distance_self == 0 , vce(r)
eststo m3: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist distance_others_o  i. orig_id i.year if distance_self == 1   , vce(r)
eststo m4: qui nbreg totyr_patcit inv_age time_atfirm coinventor ln_firm_know_stock  inv_totpat specialist distance_others_o   i. orig_id i.year if distance_self == 0 , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


reg totyr_pat  num_overlapothers  num_overlapself 		
reg totyr_pat  num_overlapothers  num_overlapself inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year 

reg totyr_patcit  num_overlapothers  num_overlapself year
reg totyr_patcit  num_overlapothers  num_overlapself inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year 



///examine binary regressions
gen overlap_others_c = overlap_others if overlap_self == 1
replace overlap_others_c =0 if overlap_others_c  ==.

gen overlap_others_d = overlap_others if overlap_self == 0
replace overlap_others_d =0 if overlap_others_d  ==.

eststo m1: qui poisson totyr_pat inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m2: qui poisson  totyr_pat overlap_self inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m3: qui poisson  totyr_pat overlap_self overlap_others_c overlap_others_d inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m4: qui poisson  totyr_pat dist_s_dist_o close_s_dist_o dist_s_close_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


eststo m1: qui nbreg totyr_patcit  inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m2: qui nbreg totyr_patcit  overlap_self inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m3: qui nbreg totyr_patcit  overlap_self overlap_others_c overlap_others_d inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m4: qui nbreg totyr_patcit  dist_s_dist_o close_s_dist_o dist_s_close_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	
/////////continuous
gen num_overlapothers_c = share_overlapothers if overlap_self == 1
replace num_overlapothers_c =0 if num_overlapothers_c  ==.

gen num_overlapothers_d = share_overlapothers if overlap_self == 0
replace num_overlapothers_d =0 if num_overlapothers_d  ==.

eststo m1: qui poisson totyr_pat inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m2: qui poisson  totyr_pat share_overlapself inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m3: qui poisson  totyr_pat share_overlapself num_overlapothers_c num_overlapothers_d inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m4: qui poisson  totyr_pat dist_s_dist_o close_s_dist_o dist_s_close_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


eststo m1: qui nbreg totyr_patcit  inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m2: qui nbreg totyr_patcit  share_overlapself inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m3: qui nbreg totyr_patcit  share_overlapself num_overlapothers_c num_overlapothers_d inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m4: qui nbreg totyr_patcit  dist_s_dist_o close_s_dist_o dist_s_close_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	

///examine only first yr sample


eststo m1: qui poisson totyr_pat inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year if  num_postclasses > 0 , vce(r)
eststo m2: qui poisson  totyr_pat overlap_self inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  if  num_postclasses > 0 , vce(r)
eststo m3: qui poisson  totyr_pat overlap_self overlap_others_c overlap_others_d inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year if  num_postclasses > 0  , vce(r)
eststo m4: qui poisson  totyr_pat dist_s_dist_o close_s_dist_o dist_s_close_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year if  num_postclasses > 0  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


eststo m1: qui nbreg totyr_patcit  inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  if  num_postclasses > 0 , vce(r)
eststo m2: qui nbreg totyr_patcit  overlap_self inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year if  num_postclasses > 0  , vce(r)
eststo m3: qui nbreg totyr_patcit  overlap_self overlap_others_c overlap_others_d inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year if  num_postclasses > 0  , vce(r)
eststo m4: qui nbreg totyr_patcit  dist_s_dist_o close_s_dist_o dist_s_close_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year if  num_postclasses > 0  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


///////////////using concentration measures
graph bar totyr_pat , over(o_close_s_dist_o, relabel(1 "All others" 2 "Close to self & distance to others")) 


graph bar totyr_pat , over(overlap_others, relabel(1 "Distant to others" 2 "Close to others")) ///
		over(overlap_self, relabel(1 "Distant to self" 2 "Close to self")) ///
		ytitle("Patent productivity") ///
		title("Average num patents produced in a yr by distance from self and others") 


graph bar totyr_patcit , over(overlap_others_o, relabel(1 "Distant to others" 2 "Close to others")) ///
		over(overlap_self_o, relabel(1 "Distant to self" 2 "Close to self")) ///
		ytitle("Innovativeness") ///
		title("Average num citations on pats produced in a yr by distance from self and others") 	
		
gen o_overlap_others_c = overlap_others_o if overlap_self_o == 1
replace o_overlap_others_c =0 if o_overlap_others_c  ==.

gen o_overlap_others_d = overlap_others_o if overlap_self_o == 0
replace o_overlap_others_d =0 if o_overlap_others_d  ==.
		


eststo m1: qui poisson totyr_pat inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m2: qui poisson  totyr_pat overlap_self_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m3: qui poisson  totyr_pat overlap_self_o o_overlap_others_c o_overlap_others_d inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m4: qui poisson  totyr_pat o_dist_s_dist_o o_close_s_dist_o o_dist_s_close_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


eststo m1: qui nbreg totyr_patcit  inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m2: qui nbreg totyr_patcit  overlap_self_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m3: qui nbreg totyr_patcit  overlap_self_o o_overlap_others_c o_overlap_others_d inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
eststo m4: qui nbreg totyr_patcit  o_dist_s_dist_o o_close_s_dist_o o_dist_s_close_o inv_age time_atfirm ln_prior_covinventor ln_firm_know_stock  inv_totpat i. orig_id i.year  , vce(r)
esttab  m1  m2 m3 m4, b(a2) se(a2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) r2(3) ar2(3) scalars(ll N chi2  p ) nogaps	


log close















