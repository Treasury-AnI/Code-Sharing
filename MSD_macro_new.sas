
*********************************************************************************************************************************
Creates Clean and censored MSD spell dataset and removes overlaping spells in the dataset
*********************************************************************************************************************************;

%macro create_MSD_SPELL;

data msd_spel; set msd.msd_spell;
%* Formating dates and sensoring;
	format startdate enddate spellfrom spellto date9.;
	spellfrom=input(compress(msd_spel_spell_start_date,"-"),yymmdd10.);
	spellto=input(compress(msd_spel_spell_end_date,"-"),yymmdd10.);
	if spellfrom<"&sensor"d;
	if spellfrom<"01Jan1993"d then spellfrom="01Jan1993"d;* BDD left censor;
	if spellto>"&sensor"d then spellto="&sensor"d;
	if spellto=. then spellto="&sensor"d;
	startdate=spellfrom;
	enddate=spellto;
%* TRANSLATING POST REFORM SERVF INTO PRE REFORM FOR OLD TIME SERIES******;

	if msd_spel_prewr3_servf_code='' then prereform=put(msd_spel_servf_code, $bengp_pre2013wr.); 
	else prereform=put(msd_spel_prewr3_servf_code,$bengp_pre2013wr.);	

* applying wider groupings;
if prereform in ("Domestic Purposes related benefits", "Widow's Benefit","Sole Parent Support ") then ben='dpb';
else if prereform in ("Invalid's Benefit", "Supported Living Payment related") then ben='ib';
else if prereform in ("Unemployment Benefit and Unemployment Benefit Hardship",
   "Unemployment Benefit Student Hardship", "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)") then ben='ub';
else if prereform in ("Job Search Allowance and Independant Youth Benefit") then ben='iyb';
else if prereform in ("Sickness Benefit and Sickness Benefit Hardship") then ben='sb';
else if prereform in ("Orphan's and Unsupported Child's benefits") then ben='ucb';
else ben='oth';

%* TRANSLATING PREREFORM SERVF INTO POST REFORM SERVF FOR NEW TIME SEIRES*****;
length benefit_desc_new $50;
servf=msd_spel_servf_code;
additional_service_data=msd_spel_add_servf_code;
	if  servf in ('602', /* Job Search Allowance - a discontinued youth benefit */
				 '603') /* IYB then aft 2012 Youth/Young Parent Payment */	 
		and additional_service_data ne 'YPP' then benefit_desc_new='1: YP Youth Payment Related' ;/* in 2012 changes some young DPB-SP+EMA moved to YPP */

	else if servf in ('313')   /* EMA(many were young mums who moved to YPP aft 2012) */
		or additional_service_data='YPP' then benefit_desc_new='1: YPP Youth Payment Related' ;
  
	else if  (servf in (
				   '115', /* UB Hardship */
                   '610', /* UB */
                   '611', /* Emergency Benefit (UB for those that did not qualify)*/
				   '030', /* B4 2012 was MOST WB, now just WB paid overseas) */ 
				   '330', /* Widows Benefit (weekly, old payment system) */ 
				   '366', /* DPB Woman Alone (weekly, old payment system) */
				   '666'))/* DPB Woman Alone */
		or (servf in ('675') and additional_service_data in (
					'FTJS1', /* JS Work Ready */
					'FTJS2')) /* JS Work Ready Hardship */
			
		then benefit_desc_new='2: Job Seeker Work Ready Related'; 

	else if  (servf in ('607', /* UB Student Hardship (mostly over summer holidays)*/ 
				   '608')) /* UB Training */
        or (servf in ('675') and additional_service_data in (
					'FTJS3', /* JS Work Ready Training */
					'FTJS4'))/* JS Work Ready Training Hardship */
		then benefit_desc_new='2: Job Seeker Work Ready Training Related'; 


	else if (servf in('600', /* Sickness Benefit */
				  '601')) /* Sickness Benefit Hardship */ 
		or (servf in ('675') and additional_service_data in (
				'MED1',   /* JS HC&D */
				'MED2'))  /* JS HC&D Hardship */
		then benefit_desc_new='3: Job Seeker HC&D Related' ;

	else if servf in ('313',   /* Emergency Maintenance Allowance (weekly) */
				   
				   '365',   /* B4 2012 DPB-SP (weekly), now Sole Parent Support */
				   '665' )  /* DPB-SP (aft 2012 is just for those paid o'seas)*/
		then benefit_desc_new='4: Sole Parent Support Related' ;/*NB young parents in YPP since 2012*/

	else if (servf in ('370') and additional_service_data in (
						'PSMED', /* SLP */
						'')) /* SLP paid overseas(?)*/ 
		or (servf ='320')    /* Invalids Benefit */
		or (servf='020')     /* B4 2012 020 was ALL IB, now just old IB paid o'seas(?)*/
		then benefit_desc_new='5: Supported Living Payment HC&D Related' ;

	else if (servf in ('370') and additional_service_data in ('CARE')) 
		or (servf in ('367',  /* DPB - Care of Sick or Infirm */
					  '667')) /* DPB - Care of Sick or Infirm */
		then benefit_desc_new='6: Supported Living Payment Carer Related' ;

	else if servf in ('999') /* merged in later by Corrections... */
		then benefit_desc_new='7: Student Allowance';

	else if (servf = '050' ) /* Transitional Retirement Benefit - long since stopped! */
		then benefit_desc_new='Other' ;

	else if benefit_desc_new='Unknown'   /* hopefully none of these!! */;

* applying wider groupings;
if prereform in ("Domestic Purposes related benefits", "Widow's Benefit","Sole Parent Support ") then ben='DPB';
else if prereform in ("Invalid's Benefit", "Supported Living Payment related") then ben='IB';
else if prereform in ("Unemployment Benefit and Unemployment Benefit Hardship",
   "Unemployment Benefit Student Hardship", "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)") then ben='UB';
else if prereform in ("Job Search Allowance and Independant Youth Benefit") then ben='IYB';
else if prereform in ("Sickness Benefit and Sickness Benefit Hardship") then ben='SB';
else if prereform in ("Orphan's and Unsupported Child's benefits") then ben='UCB';
else ben='OTH';

if benefit_desc_new='2: Job Seeker Work Ready Training Related' then ben_new='JSWR_TR';
else if benefit_desc_new='1: YP Youth Payment Related' then ben_new='YP';
else if benefit_desc_new='1: YPP Youth Payment Related' then ben_new='YPP';
else if benefit_desc_new='2: Job Seeker Work Ready Related' then ben_new='JSWR';

else if benefit_desc_new='3: Job Seeker HC&D Related' then ben_new='JSHCD';
else if benefit_desc_new='4: Sole Parent Support Related' then ben_new='SPSR';
else if benefit_desc_new='5: Supported Living Payment HC&D Related' then ben_new='SLP_HCD';
else if benefit_desc_new='6: Supported Living Payment Carer Related' then ben_new='SLP_C';
else if benefit_desc_new='7: Student Allowance' then ben_new='SA';

else if benefit_desc_new='Other' then ben_new='OTH';
if prereform='370' and ben_new='SLP_C' then ben='DPB';
if prereform='370' and ben_new='SLP_HCD' then ben='IB';

if prereform='675' and ben_new='JSHCD' then ben='SB';
if prereform='675' and (ben_new ='JSWR' or ben_new='JSWR_TR') then ben='UB';
	spell=msd_spel_spell_nbr;
	keep snz_uid spellfrom spellto spell servf ben ben_new;
rename spellfrom=startdate;
rename spellto=enddate;

run;
 *limit the records to population of interest;
proc sql;
create table 
msd_spell as select 
a.*
from msd_spel a 
order by snz_uid, startdate;
quit;

%overlap(MSD_spell);

proc delete data=msd_spel;
proc delete data=msd_spell;
run;
%mend;

*********************************************************************************************************************************
Creates Clean and censored MSD spell dataset for given population and removes overlaping spells in the dataset
*********************************************************************************************************************************;


%macro create_MSD_SPELL_pop;

data msd_spel; set msd.msd_spell;
%* Formating dates and sensoring;
	format startdate enddate spellfrom spellto date9.;
	spellfrom=input(compress(msd_spel_spell_start_date,"-"),yymmdd10.);
	spellto=input(compress(msd_spel_spell_end_date,"-"),yymmdd10.);
	if spellfrom<"&sensor"d;
	if spellfrom<"01Jan1993"d then spellfrom="01Jan1993"d;* BDD left censor;
	if spellto>"&sensor"d then spellto="&sensor"d;
	if spellto=. then spellto="&sensor"d;
	startdate=spellfrom;
	enddate=spellto;
%* TRANSLATING POST REFORM SERVF INTO PRE REFORM FOR OLD TIME SERIES******;

	if msd_spel_prewr3_servf_code='' then prereform=put(msd_spel_servf_code, $bengp_pre2013wr.); 
	else prereform=put(msd_spel_prewr3_servf_code,$bengp_pre2013wr.);	

%* applying wider groupings;
if prereform in ("Domestic Purposes related benefits", "Widow's Benefit","Sole Parent Support ") then ben='dpb';
else if prereform in ("Invalid's Benefit", "Supported Living Payment related") then ben='ib';
else if prereform in ("Unemployment Benefit and Unemployment Benefit Hardship",
   "Unemployment Benefit Student Hardship", "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)") then ben='ub';
else if prereform in ("Job Search Allowance and Independant Youth Benefit") then ben='iyb';
else if prereform in ("Sickness Benefit and Sickness Benefit Hardship") then ben='sb';
else if prereform in ("Orphan's and Unsupported Child's benefits") then ben='ucb';
else ben='oth';

%* TRANSLATING PREREFORM SERVF INTO POST REFORM SERVF FOR NEW TIME SEIRES*****;
length benefit_desc_new $50;
servf=msd_spel_servf_code;
additional_service_data=msd_spel_add_servf_code;
	if  servf in ('602', /* Job Search Allowance - a discontinued youth benefit */
				 '603') /* IYB then aft 2012 Youth/Young Parent Payment */	 
		and additional_service_data ne 'YPP' then benefit_desc_new='1: YP Youth Payment Related' ;/* in 2012 changes some young DPB-SP+EMA moved to YPP */

	else if servf in ('313')   /* EMA(many were young mums who moved to YPP aft 2012) */
		or additional_service_data='YPP' then benefit_desc_new='1: YPP Youth Payment Related' ;
  
	else if  (servf in (
				   '115', /* UB Hardship */
                   '610', /* UB */
                   '611', /* Emergency Benefit (UB for those that did not qualify)*/
				   '030', /* B4 2012 was MOST WB, now just WB paid overseas) */ 
				   '330', /* Widows Benefit (weekly, old payment system) */ 
				   '366', /* DPB Woman Alone (weekly, old payment system) */
				   '666'))/* DPB Woman Alone */
		or (servf in ('675') and additional_service_data in (
					'FTJS1', /* JS Work Ready */
					'FTJS2')) /* JS Work Ready Hardship */
			
		then benefit_desc_new='2: Job Seeker Work Ready Related'; 

	else if  (servf in ('607', /* UB Student Hardship (mostly over summer holidays)*/ 
				   '608')) /* UB Training */
        or (servf in ('675') and additional_service_data in (
					'FTJS3', /* JS Work Ready Training */
					'FTJS4'))/* JS Work Ready Training Hardship */
		then benefit_desc_new='2: Job Seeker Work Ready Training Related'; 


	else if (servf in('600', /* Sickness Benefit */
				  '601')) /* Sickness Benefit Hardship */ 
		or (servf in ('675') and additional_service_data in (
				'MED1',   /* JS HC&D */
				'MED2'))  /* JS HC&D Hardship */
		then benefit_desc_new='3: Job Seeker HC&D Related' ;

	else if servf in ('313',   /* Emergency Maintenance Allowance (weekly) */
				   
				   '365',   /* B4 2012 DPB-SP (weekly), now Sole Parent Support */
				   '665' )  /* DPB-SP (aft 2012 is just for those paid o'seas)*/
		then benefit_desc_new='4: Sole Parent Support Related' ;/*NB young parents in YPP since 2012*/

	else if (servf in ('370') and additional_service_data in (
						'PSMED', /* SLP */
						'')) /* SLP paid overseas(?)*/ 
		or (servf ='320')    /* Invalids Benefit */
		or (servf='020')     /* B4 2012 020 was ALL IB, now just old IB paid o'seas(?)*/
		then benefit_desc_new='5: Supported Living Payment HC&D Related' ;

	else if (servf in ('370') and additional_service_data in ('CARE')) 
		or (servf in ('367',  /* DPB - Care of Sick or Infirm */
					  '667')) /* DPB - Care of Sick or Infirm */
		then benefit_desc_new='6: Supported Living Payment Carer Related' ;

	else if servf in ('999') /* merged in later by Corrections... */
		then benefit_desc_new='7: Student Allowance';

	else if (servf = '050' ) /* Transitional Retirement Benefit - long since stopped! */
		then benefit_desc_new='Other' ;

	else if benefit_desc_new='Unknown'   /* hopefully none of these!! */;

* applying wider groupings;
if prereform in ("Domestic Purposes related benefits", "Widow's Benefit","Sole Parent Support ") then ben='DPB';
else if prereform in ("Invalid's Benefit", "Supported Living Payment related") then ben='IB';
else if prereform in ("Unemployment Benefit and Unemployment Benefit Hardship",
   "Unemployment Benefit Student Hardship", "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)") then ben='UB';
else if prereform in ("Job Search Allowance and Independant Youth Benefit") then ben='IYB';
else if prereform in ("Sickness Benefit and Sickness Benefit Hardship") then ben='SB';
else if prereform in ("Orphan's and Unsupported Child's benefits") then ben='UCB';
else ben='OTH';

if benefit_desc_new='2: Job Seeker Work Ready Training Related' then ben_new='JSWR_TR';
else if benefit_desc_new='1: YP Youth Payment Related' then ben_new='YP';
else if benefit_desc_new='1: YPP Youth Payment Related' then ben_new='YPP';
else if benefit_desc_new='2: Job Seeker Work Ready Related' then ben_new='JSWR';

else if benefit_desc_new='3: Job Seeker HC&D Related' then ben_new='JSHCD';
else if benefit_desc_new='4: Sole Parent Support Related' then ben_new='SPSR';
else if benefit_desc_new='5: Supported Living Payment HC&D Related' then ben_new='SLP_HCD';
else if benefit_desc_new='6: Supported Living Payment Carer Related' then ben_new='SLP_C';
else if benefit_desc_new='7: Student Allowance' then ben_new='SA';

else if benefit_desc_new='Other' then ben_new='OTH';
if prereform='370' and ben_new='SLP_C' then ben='DPB';
if prereform='370' and ben_new='SLP_HCD' then ben='IB';

if prereform='675' and ben_new='JSHCD' then ben='SB';
if prereform='675' and (ben_new ='JSWR' or ben_new='JSWR_TR') then ben='UB';
	spell=msd_spel_spell_nbr;
	keep snz_uid spellfrom spellto spell servf ben ben_new;
rename spellfrom=startdate;
rename spellto=enddate;
run;

%* limit the records to population of interest;
proc sql;
create table 
msd_spell as select 
a.*,
b.DOB
from msd_spel a inner join &population b
on a.snz_uid=b.snz_uid
order by snz_uid, startdate;
quit;

%overlap(msd_spell);
proc delete data=msd_spel; 
proc delete data=msd_spell;
run;
%mend;

**************************************************************************************************************************
Create clean MSD child spell dataset 
**************************************************************************************************************************;

%macro create_MSD_child_spelL;

%create_MSD_SPELL;
* child spell dataset;
data ICD_BDD_chd;
	set msd.msd_child;
	format chto chfrom chdob date9.;
	spell=msd_chld_spell_nbr;
	chfrom=input(compress(msd_chld_child_from_date,"-"),yymmdd10.);
	chto=input(compress(msd_chld_child_to_date,"-"),yymmdd10.);
	chdob=mdy(msd_chld_child_birth_month_nbr,15,msd_chld_child_birth_year_nbr);

	* SENSORING;
	if chfrom>"&sensor"d then
		delete;

	if chto>"&sensor"d then
		chto="&sensor"d;

	if chto=. then
		chto="&sensor"d;
	keep snz_uid spell child_snz_uid chfrom chto chdob;

rename chfrom=startdate;
rename chto=enddate;

run;

* selecting only spells where child is included ;
proc sort data=msd_spell; by snz_uid spell; run;
proc sort data=ICD_BDD_chd; by snz_uid spell; run;

data MSD_child_spell;
	merge   ICD_BDD_chd (in = y) msd_spell (keep = snz_uid ben ben_new spell);
	by snz_uid spell;

	if y;
rename snz_uid=adult_snz_uid;
rename child_snz_uid=snz_uid;
run;
proc sort data=msd_child_spell; by snz_uid startdate; run;

%overlap(MSD_child_spell);
* deleting reduntant datasets;
proc delete data=ICD_BDD_chd;
proc delete data=msd_spell;
proc delete data=msd_child_spell; 
run;

%mend;

**************************************************************************************************************************
Create clean MSD child spell dataset for popualtion of interest
**************************************************************************************************************************;

%macro create_MSD_child_spelL_pop;
* creatign spells for adults;
%create_MSD_SPELL;

* creating child spell dataset;
data ICD_BDD_chd;
	set msd.msd_child;
	format chto chfrom chdob date9.;
	spell=msd_chld_spell_nbr;
	chfrom=input(compress(msd_chld_child_from_date,"-"),yymmdd10.);
	chto=input(compress(msd_chld_child_to_date,"-"),yymmdd10.);
	chdob=mdy(msd_chld_child_birth_month_nbr,15,msd_chld_child_birth_year_nbr);

	* SENSORING;
	if chfrom>"&sensor"d then
		delete;

	if chto>"&sensor"d then
		chto="&sensor"d;

	if chto=. then
		chto="&sensor"d;

	keep snz_uid spell child_snz_uid chfrom chto chdob;
rename chfrom=startdate;
rename chto=enddate;
run;
* limiting to population of interest;
proc sql;
create table MSD_child_spell_
as select 
a.*,
b.DOB
from ICD_BDD_chd a inner join &population b
on a.child_snz_uid=b.snz_uid
order by snz_uid, spell;
quit;

proc sort data=msd_spell_OR; by snz_uid spell; run;

data MSD_child_spell;
	merge    MSD_child_spell_ (in = y) msd_spell_OR (keep = snz_uid ben ben_new spell);
	by snz_uid spell;
	if y;
rename snz_uid=adult_snz_uid;
rename child_snz_uid=snz_uid;
run;

proc sort data=msd_child_spell; by snz_uid startdate; run;

%overlap(MSD_child_spell);
proc delete data=ICD_BDD_chd;
proc delete data=msd_spell_OR;
proc delete data=msd_child_spell_;
proc delete data=msd_child_spell; 
proc delete data=deletes; 

run;

%mend;

********************************************************************************************************************************
Two macros that help to create indicators by year and age for each benefit type
*********************************************************************************************************************************;

%macro ch_bentype_yr(bentype);
 
array supp_&bentype._[*] supp_&bentype._&msd_left_yr.-supp_&bentype._&last_anal_yr. ;
array ch_da_&bentype._[*] ch_da_&bentype._&msd_left_yr.-ch_da_&bentype._&last_anal_yr.;

	supp_&bentype._(i)=0;
	ch_da_&bentype._(i)=0;

if not((startdate > end_window) or (enddate < start_window)) then do;
					if ben="&bentype." or ben_new="&bentype." then supp_&bentype._(i)=1;

					if (startdate <= start_window) and  (enddate > end_window) then
						days=(end_window-start_window)+1;
					else if (startdate <= start_window) and  (enddate <= end_window) then
						days=(enddate-start_window)+1;
					else if (startdate > start_window) and  (enddate <= end_window) then
						days=(enddate-startdate)+1;
					else if (startdate > start_window) and  (enddate > end_window) then
						days=(end_window-startdate)+1;	

					ch_da_&bentype._[i]=days*supp_&bentype._[i];

end;
drop supp_:;
%mend;

%macro ch_bentype_age(bentype);

array supp_&bentype._at_age_[*] supp_&bentype._at_age_&firstage.-supp_&bentype._at_age_&lastage. ;
array ch_da_&bentype._at_age_[*] ch_da_&bentype._at_age_&firstage.-ch_da_&bentype._at_age_&lastage.;
	at_birth_supp_&bentype.=0;
	supp_&bentype._at_age_(age)=0;
	ch_da_&bentype._at_age_(age)=0;

if not((startdate > end_window) or (enddate < start_window)) then do;
					if ben="&bentype." or ben_new="&bentype." then supp_&bentype._at_age_(age)=1;

					if (startdate <= start_window) and  (enddate > end_window) then
						days=(end_window-start_window)+1;
					else if (startdate <= start_window) and  (enddate <= end_window) then
						days=(enddate-start_window)+1;
					else if (startdate > start_window) and  (enddate <= end_window) then
						days=(enddate-startdate)+1;
					else if (startdate > start_window) and  (enddate > end_window) then
						days=(end_window-startdate)+1;	

					ch_da_&bentype._at_age_[age]=days*supp_&bentype._at_age_[age];

end;

if not(startdate> (DOB+45) or (enddate < (DOB-45))) and (ben="&bentype." or ben_new="&bentype.") then
				do;
					at_birth_supp_&bentype.=1;
end;
drop supp_:;
%mend;

*****************************************************************************************************************************
Creates indicators of days onbenefit as a child for population of interest
*****************************************************************************************************************************;

%macro create_MSD_ind_child_pop;
%create_MSD_child_spelL_pop;
data tmp;
set MSD_child_spell_OR;
		start1=MDY(1,1,&msd_left_yr.); format start1 date9.;
array ch_total_da_onben_(*) ch_total_da_onben_&msd_left_yr.-ch_total_da_onben_&last_anal_yr;
array ch_total_da_onben_at_age_(*) ch_total_da_onben_at_age_&firstage-ch_total_da_onben_at_age_&lastage;


do ind=&msd_left_yr. to &last_anal_yr;
			i=ind-(&msd_left_yr.-1);

			start_window=intnx('YEAR',start1,i-1,'S');
			end_window=intnx('YEAR',start1,i,'S')-1;

			%ch_bentype_yr(DPB);
			%ch_bentype_yr(IB);
			%ch_bentype_yr(UB);
			%ch_bentype_yr(IYB);
			%ch_bentype_yr(SB);
			%ch_bentype_yr(UCB);
			%ch_bentype_yr(OTHBEN);

ch_total_da_onben_(i)=sum(of ch_da_DPB_(i),ch_da_IB_(i),ch_da_UB_(i),ch_da_IYB_(i),ch_da_SB_(i),ch_da_UCB_(i),ch_da_OTHBEN_(i));
			%ch_bentype_yr(YP);
			%ch_bentype_yr(YPP);
			%ch_bentype_yr(SPSR);
length total_da_: da_: 3;
run;

Data &projectlib.._IND_BEN_adult_at_age_&date; 
retain snz_uid ; 
set TEMP (keep=snz_uid

total_da_onben_at_age_:
da_DPB_at_age: 
da_IB_at_age: 
da_UB_at_age: 
da_IYB_at_age:
da_SB_at_age:
da_UCB_at_age:
da_OTHBEN_at_age: 

da_YP_at_age: 
da_YPP_at_age: 
da_SPSR_at_age: 
da_SLP_C_at_age:
da_SLP_HCD_at_age:
da_JSWR_at_age:
da_JSWR_TR_at_age: 
da_JSHCD_at_age: 
da_OTH_at_age: )
;
length total_da_: da_: 3;
run;
* lets delete unnecessary datasets from work folder;
proc delete data=tmp;
proc delete data=TEMP;
proc delete data=MSD_SPELL_OR;

%mend;
