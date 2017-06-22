/*
/////////////////////////////////////////////// setting up base files
	By Erin Fahrenkopf, Tepper, CMU

In this file I import files into my own stata versions. The files are pulled from Lee Fleming's work:
(1) inventor unique ids: http://funglab.berkeley.edu/pub/disamb_no_postpolishing.csv
(2) cleaned assignee names, patent classifications: http://rosencrantz.berkeley.edu/
(3) citation data: https://dataverse.harvard.edu/dataset.xhtmddddl?persistentId=hdl:1902.1/15705



TO NOTE AND FIGURE OUT
- observations in the grant_assignee dataset do not match into the raw_assignee dataset using either organization or assignee_id to match them
- seems like there are patent duplicates in the raw_assignee dataset for multiple assignee locations

Created: 		11/12/15
Last updated:   1/4/16
////////////////////////////////////////////////////////////////////////////////////////////////
*/

//////////////////////Begin
	clear
	clear matrix
	set 	more off
	log 	using "C:\Users\Erin.Tesla\Box Sync\Dissertation data\STATA work\logs\distance to self 1.log", text replace
	adopath + "C:\Users\Erin.Tesla\Box Sync\Dissertation data\STATA work\Functions"

	
////////turn files into stata files

//////////////////////patent classifications
	import delimited "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_uspc.tsv.txt",clear
		//this file has classes for patents applied up to 2010
		//I use this file
					rename v1 uuid
					rename v2 patent_id
					rename v3 mainclass_id
					rename v4 subclass_id
					rename v5 sequence
			drop if _n == 1
					destring patent_id, replace force
			drop if patent_id == .
					rename patent_id patent
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_uspc.dta", replace

////////////////////patent citations - from Rosencrantz
///////////I am not currently using this file - not exactly sure why
	import delimited "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_uspatentcitation.tsv.txt",clear
					destring patent_id, replace force
			drop if patent_id == . //keep only patents that are utility
					rename patent_id patent
					destring citation_id, replace force
			drop if citation_id == .  //keep only patents that are utility
					rename citation_id citation
					split date, p("-")
					rename date1 cityear
					destring cityear, replace force //these citations go from 1943 to 2012 and there are a lot with null dates
					keep patent cityear citation category
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_uspatentcitation.dta", replace


////////////////////patent citations - from Dataverse - early yrs patent == citing and citation  == cited
///I am using this file
	use "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\citations 7599.dta", clear
					keep patent citation 
			merge m:1 patent using "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\patent.dta"
			drop_using
					destring citation, replace force
			drop if citation == .  //keep only patents that are utility
			destring patent, replace force
			drop if patent == .  //keep only patents that are utility
					keep citation patent appyear
					rename patent citing
					rename citation patent
	save "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\citations 7599 with dates.dta", replace
////////////////////patent citations - from Dataverse - later yrs
	use "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\citations 0010.dta", clear
					keep patent citation 
			merge m:1 patent using "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\patent.dta"
			drop_using
					destring citation, replace force
			drop if citation == . //keep only patents that are utility
			destring patent, replace force
			drop if patent == .  //keep only patents that are utility
					keep citation patent appyear
					rename patent citing
					rename citation patent
	save "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\citations 0010 with dates.dta", replace
			append using "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\citations 7599 with dates.dta"
					rename appyear citingyear
					bysort citing (citingyear): replace citingyear = citingyear[_n - 1] if citingyear == .
	save "C:\Users\Erin.Tesla\Box Sync\would be desktop\Straight from Dataverse\citations 7510 with dates.dta", replace //file with both early and later yrs together

/////////////////////file used to link cleaned assignee names to granted patents
//assignee files have assignees on patents applied for until 2010
	import delimited "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_assignee.tsv.txt",clear
			gen assignee_id = substr(id, 1,32)
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_assignee.dta", replace
	
////////////////////dataset linking cleaned assignee ids to patent numbers	
	import delimited "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_rawassignee.tsv.txt",clear
					destring patent_id, replace force
			drop if patent_id == . //keep only patents that are utility
					rename patent_id patent
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_rawassignee.dta", replace
	
////////////////cleaned up assignee dataset combining patent info from raw assignee, cleaned assignee and filtering on one obs per patent	
	use "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_rawassignee.dta", clear
					keep patent assignee_id organization
///////////get rid of blank assignee names in raw assignee
					drop if organization == "" | organization == "0"
/////////////	match in clean names to raw assignee
					merge m:1 assignee_id using "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_assignee.dta"
					keep_matched //all should match and ones in using that dont match are not for utility patents
							keep patent organization
					duplicates drop organization patent, force
					bysort patent: gen org_count = _n
					drop if org_count > 1
							drop org_count
					//sum org_count
					//reshape wide organization, i(patent) j(org_count)
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\assignee by patent.dta", replace
					replace organization = lower(organization)	
			gen assignee = organization
	run "C:\Users\Erin.Tesla\Box Sync\Prospective research\kt in patent data\assignee clean up updated.do"
	drop organization
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\clean assignee by patent_updated.dta", replace
	
/////////////dataset wtih granted patent attributes - like date
	import delimited "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_patent.tsv.txt",clear
					rename id patent
					split date, p("-")
					rename date1 appyear
					destring appyear, replace force //these patents go from 1975 to 2006
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_patent.dta", replace

//////////dataset with patent application attributes - dont use this 
	import delimited "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\application_application.tsv.txt",clear
					split date, p("-")
					rename date1 appyear
					destring appyear, replace force
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\app_patent.dta", replace

///////////////dataset with the inventors in raw form attached to patent numbers - use for patent inventor counts
	import delimited "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_rawinventor.tsv.txt",clear
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_rawinventor.dta", replace
					destring patent_id, replace force
			drop if patent_id == . //keep only patents that are utility
					rename patent_id patent
			collapse (count) sequence, by(patent)
					rename sequence inv_count
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\inventor_count.dta", replace

//////////cleaned inventor name dataset - do not use
	import delimited "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_inventor.tsv.txt",clear
//this file seems to have patents applied for into 2010
					rename v1 inventor_id
					rename v2 first_name
					rename v3 last_name
			drop if _n == 1
					split inventor_id, p("-")
					rename inventor_id1 id
					destring id, replace force
			drop if id == . //get rid of patents with no inventor names
save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\grant_inventor.dta", replace

///////////inventor disambiguated dataset
	import delimited "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\disamb_no_postpolishing.csv", clear
					destring patent, replace force
			drop if patent == .
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\disamb_no_postpolishing.dta", replace
//////////////////create dataset with patent dates in it
			duplicates drop patent, force
					keep patent appyear gyear applyyear //these patents go from 1975 to 2010
	save "C:\Users\Erin.Tesla\Box Sync\Prospective research\distance from self and others\patent data from httprosencrantz.berkeley.edu\patent.dta", replace


	
log close
