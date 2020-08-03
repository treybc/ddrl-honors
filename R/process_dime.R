library(RSQLite)
library(sqldf)
library(data.table)

path <- 'D:/Desktop/work/ddrl_rdata/'

##Connecting to SQLite DB
con <- dbConnect(RSQLite::SQLite(), paste0(path,"dime.sqlite3"))

# load(paste(path, 'dime_recipients_all_1979_2018.rdata',sep=''))
# # name of dataframe is cands.all 
# cands.2018 <- cands.all[cands.all$cycle==2018, ]
# dbWriteTable(con, 'candDB', cands.2018)

# donors.2018 <- dbGetQuery(con2, "select * from donorDB where amount_2018 > 0")

##list tables
dbListTables(con)

##show variables in candDB
cand.vars.new <- dbGetQuery(con,"select * from candDB limit 10")
print(cand.vars.new)


##show variables in contribDB
contrib.vars <- dbGetQuery(con,"select * from contribDB limit 10")
print(contrib.vars)


##show variables in donorDB
disb.vars <- dbGetQuery(con,"select * from donorDB limit 10")
print(disb.vars)


###############################################################################
##Example queries | recipient file
###############################################################################

cands <- dbGetQuery(con,"SELECT election, cycle, bonica_rid, 
    name, lname, ffname, fname, mname, nname, title, suffix, cand_gender,
    party, state, seat, district, incum_chall,
    recipient_cfscore, dwnom1, recipient_type,
    num_givers, total_disbursements, contribs_from_candidate, 
    non_party_ind_exp_for, ind_exp_for, comm_cost_for, party_coord_exp,
    total_receipts, total_indiv_contrib, total_pac_contribs,
    ran_primary, ran_general, p_elec_stat, gen_elec_stat, gen_elect_pct, winner 
    FROM candDB WHERE cycle == 2014 AND seat == 'federal:house'")


##pull all california cands
ca.cands <- dbGetQuery(con,"select * from candDB where state ='CA'")

##pull all california cands running in 2014
ca.cands.2014 <- dbGetQuery(con,"select * from candDB where state ='CA' and cycle == 2014")

##pull house california cands running in 2014
ca.cands.2014.house <- dbGetQuery(con,"select * from candDB where cycle == 2014 and seat == 'federal:house'")

##pull pelosi
pelosi.cands <- dbGetQuery(con,"select * from candDB where lname = 'pelosi'")

###############################################################################
##Example queries | contrib file
###############################################################################
by.last.name <- dbGetQuery(con,"select * from contribDB where contributor_lname = 'trump'")

by.last.and.first.name <- dbGetQuery(con,"select * from contribDB where contributor_lname = 'trump' and contributor_fname ='donald'")

by.cid <- dbGetQuery(con,"select * from contribDB where bonica_cid = 3110056714")

stanford.donors <- dbGetQuery(con,"select * from contribDB where contributor_employer like 'stanford univ%'")

by.gender <- dbGetQuery(con,"select contributor_gender, amount, bonica_cid, recipient_name from contribDB where cycle == 2014 and contributor_gender= 'F'")




