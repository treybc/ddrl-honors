library(RSQLite)
library(sqldf)
library(data.table)

path <- 'D:/Desktop/work/ddrl_rdata/'

##Connecting to SQLite DB
con <- dbConnect(RSQLite::SQLite(), paste0(path,"dime.sqlite3"))


##list tables
dbListTables(con)

##show variables in candDB
cand.vars <- dbGetQuery(con,"select * from candDB limit 10")
print(cand.vars)


##show variables in contribDB
contrib.vars <- dbGetQuery(con,"select * from contribDB limit 10")
print(contrib.vars)


##show variables in donorDB
disb.vars <- dbGetQuery(con,"select * from donorDB limit 10")
print(disb.vars)


###############################################################################
##Example queries | recipient file
###############################################################################

##pull all california cands
ca.cands <- dbGetQuery(con,"select * from candDB where state ='CA'")

##pull all california cands running in 2014
ca.cands.2014 <- dbGetQuery(con,"select * from candDB where state ='CA' and cycle == 2014")

##pull house california cands running in 2014
ca.cands.2014.house <- dbGetQuery(con,"select * from candDB where state ='CA' and cycle == 2014 and seat == 'federal:house'")

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




